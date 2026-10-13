#!/usr/bin/env python3
"""Build the vendored source closure one Lean module at a time (Python >=3.11).

Use --check-plan for read-only validation and a JSON command plan, without
executing Lean/Lake. This portable convenience script is not the Linux audit
runner: it has no seccomp network filter, host-memory guard, or artifact audit.
"""
import argparse
import hashlib
import heapq
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tomllib

TARGETS = ["Hilbert17", "Hilbert17RealClosure", "Hilbert17Full", "Hilbert17Acceptance"]
MODULE_NAME = re.compile(r"[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*\Z")


def require(ok, message):
    if not ok:
        raise RuntimeError(message)


def digest(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def inside(path, workspace):
    path = Path(path).resolve(strict=True)
    require(path.is_relative_to(workspace), "Vendored path escapes repository: " + str(path))
    return path


def prepare_plan(workspace):
    manifest_path = workspace / "vendor-source-manifest.json"
    manifest = read_json(manifest_path)
    configs = []
    packages = {"project": workspace}
    packages.update({row["package"]: workspace / "vendor" / row["package"] for row in manifest["packages"]})
    for name, root in packages.items():
        inside(root, workspace)
        require(not (root / "lakefile.lean").exists(), "Executable Lake configuration is not supported")
        config_path = root / "lakefile.toml"
        config = tomllib.loads(config_path.read_text(encoding="utf-8"))
        require(config.get("weakLeanArgs") == ["-j", "1", "-M", "4096"], "Expected serial/4096MiB Lean flags: " + name)
        require(config.get("enableArtifactCache") is False and config.get("preferReleaseBuild") is False,
                "Artifact/release cache must be disabled: " + name)
        require(not config.get("precompileModules", False), "Native precompilation is outside this serial plan")
        require(not any(config.get(key) for key in ["lean_exe", "extern_lib", "target", "script", "needs", "extraDepTargets"]),
                "Unexpected executable/custom dependency target")
        for library in config.get("lean_lib", []):
            require(not any(library.get(key) for key in ["precompileModules", "needs", "extraDepTargets", "leanArgs", "weakLeanArgs"]),
                    "Unexpected library compilation/dependency override")
        for dependency in config.get("require", []):
            require(set(dependency) <= {"name", "scope", "path"} and dependency.get("path"), "Nonlocal dependency declaration")
            require(dependency["name"] in packages, "Unknown local package")
            require(inside(root / dependency["path"], workspace) == packages[dependency["name"]].resolve(), "Wrong dependency path")
        package_manifest_path = root / "lake-manifest.json"
        package_manifest = read_json(package_manifest_path)
        for dependency in package_manifest["packages"]:
            require(dependency["type"] == "path" and dependency["name"] in packages, "Nonlocal package manifest")
            require(inside(root / dependency["dir"], workspace) == packages[dependency["name"]].resolve(), "Wrong manifest package path")
        configs.extend([config_path, package_manifest_path])
    root_config = tomllib.loads((workspace / "lakefile.toml").read_text(encoding="utf-8"))
    require(root_config["defaultTargets"] == TARGETS, "Unexpected aggregate target scope")
    roots = [module for lib in root_config["lean_lib"] for module in lib["roots"]]
    require(roots == manifest["roots"] and len(roots) == 97, "Unexpected root module scope")
    modules = {record["module"]: record for record in manifest["modules"]}
    require(len(modules) == len(manifest["modules"]) == 3136, "Unexpected source-closure size")
    boundaries = set(manifest["toolchain_import_boundaries"])
    require(all(name.split(".")[0] in {"Init", "Lean", "Std", "Lake"} for name in boundaries), "Unknown toolchain boundary")
    degrees, reverse, sources = {}, {module: [] for module in modules}, []
    names = set(modules)
    for module, record in modules.items():
        require(MODULE_NAME.fullmatch(module), "Invalid module name")
        require(set(record["imports"]) <= names | boundaries, "Unknown import: " + module)
        dependencies = set(record["imports"]) & names
        degrees[module] = len(dependencies)
        for dependency in dependencies:
            reverse[dependency].append(module)
        source = inside(packages[record["package"]] / record["path"], workspace)
        require(source.stat().st_size == record["bytes"] and digest(source) == record["sha256"],
                "Source differs from vendoring manifest: " + module)
        sources.append((source, record["sha256"]))
    ready = [module for module, degree in degrees.items() if degree == 0]
    heapq.heapify(ready)
    order = []
    while ready:
        module = heapq.heappop(ready)
        order.append(module)
        for child in reverse[module]:
            degrees[child] -= 1
            if degrees[child] == 0:
                heapq.heappush(ready, child)
    require(len(order) == len(modules), "Import cycle")
    # Include all fifteen compile-time include_str assets in before/after checks.
    asset_manifest_path = workspace / "vendor-asset-manifest.json"
    asset_manifest = read_json(asset_manifest_path)
    require(len(asset_manifest["assets"]) == 15, "Unexpected compile-time asset count")
    for record in asset_manifest["assets"]:
        asset = inside(packages[record["package"]] / record["path"], workspace)
        require(asset.stat().st_size == record["bytes"] and digest(asset) == record["sha256"],
                "Compile-time asset differs from vendoring manifest: " + str(asset))
    # No JavaScript/npm tool is invoked. Vendor non-Lean metadata is pinned once.
    assets = []
    for package, root in packages.items():
        if package != "project":
            for path in root.rglob("*"):
                if path.is_file() and ".lake" not in path.relative_to(root).parts and path.suffix != ".lean":
                    assets.append((inside(path, workspace), digest(path)))
    fixed = [(path, digest(path)) for path in configs + [manifest_path, asset_manifest_path, workspace / "lean-toolchain"]]
    return order, sources + assets, fixed


def resolve_installed_lake(workspace, requested):
    suffix = ".exe" if os.name == "nt" else ""
    candidates = []
    if requested:
        candidates.append(Path(requested).expanduser())
    else:
        found = shutil.which("lake")
        if found:
            candidates.append(Path(found))
        # Avoid executing an elan shim, which can auto-download a missing toolchain.
        version = (workspace / "lean-toolchain").read_text(encoding="utf-8").strip()
        require(re.fullmatch(r"[A-Za-z0-9_./:+-]+", version), "Invalid toolchain identifier")
        elan_home = Path(os.environ.get("ELAN_HOME", str(Path.home() / ".elan")))
        directory = version.replace("/", "--").replace(":", "---")
        candidates.append(elan_home / "toolchains" / directory / "bin" / ("lake" + suffix))
    for candidate in candidates:
        if not candidate.is_file():
            continue
        lake = candidate.resolve()
        toolchain = lake.parent.parent
        if (lake.parent / ("lean" + suffix)).is_file() and (toolchain / "lib/lean/Init.olean").is_file():
            return lake
    raise RuntimeError("No direct installed Lean toolchain found. Install the version in lean-toolchain separately, "
                       "or pass --lake PATH_TO_INSTALLED_TOOLCHAIN/bin/lake. This script will not download it.")


def assert_unchanged(records):
    for path, expected in records:
        require(digest(path) == expected, "Input changed during build: " + str(path))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", default=str(Path(__file__).resolve().parents[1]))
    parser.add_argument("--lake", help="Direct installed toolchain Lake executable; elan shims are not accepted")
    parser.add_argument("--check-plan", action="store_true", help="Validate inputs and emit order/commands only; execute nothing")
    args = parser.parse_args()
    workspace = Path(args.workspace).resolve(strict=True)
    order, sources_assets, fixed = prepare_plan(workspace)
    if args.check_plan:
        base = [args.lake or "lake", "--dir", str(workspace), "--no-cache"]
        print(json.dumps({"status": "STATIC_PLAN_VALIDATED_NO_EXECUTION", "module_count": len(order), "order": order,
                          "first_module_commands": [base + ["--no-build", "build", "+" + order[0] + ":deps"], base + ["build", "+" + order[0] + ":olean"]],
                          "last_module_commands": [base + ["--no-build", "build", "+" + order[-1] + ":deps"], base + ["build", "+" + order[-1] + ":olean"]],
                          "aggregate_commands": [base + ["build"] + TARGETS, base + ["--no-build", "build"] + TARGETS]}, indent=2))
        return 0
    lake = resolve_installed_lake(workspace, args.lake)
    base = [str(lake), "--dir", str(workspace), "--no-cache"]
    env = os.environ.copy()
    for key in ["LEAN_PATH", "LEAN_SRC_PATH", "ELAN_TOOLCHAIN", "LAKE_PACKAGE_URL_MAP", "LAKE_OVERRIDE_LEAN"]:
        env.pop(key, None)
    env.update(LEAN_PATH="", LEAN_SRC_PATH="", LEAN_SYSROOT=str(lake.parent.parent), LEAN_NUM_THREADS="1",
               LAKE_NO_CACHE="1", LAKE_ARTIFACT_CACHE="false", MATHLIB_NO_CACHE_ON_UPDATE="1", GIT_TERMINAL_PROMPT="0")
    lean = lake.parent / ("lean.exe" if os.name == "nt" else "lean")
    version_result = subprocess.run([str(lean), "--version"], cwd=workspace, env=env,
                                    check=True, capture_output=True, text=True)
    expected_version = (workspace / "lean-toolchain").read_text(encoding="utf-8").strip().split(":")[-1].removeprefix("v")
    actual_version = re.search(r"Lean \(version ([^,\s]+)", version_result.stdout)
    require(actual_version is not None and actual_version.group(1) == expected_version,
            "Installed Lean version differs from lean-toolchain")
    try:
        for index, module in enumerate(order, 1):
            assert_unchanged(fixed)
            print(f"[{index}/{len(order)}] {module}", flush=True)
            subprocess.run(base + ["--no-build", "build", "+" + module + ":deps"], cwd=workspace, env=env, check=True)
            subprocess.run(base + ["build", "+" + module + ":olean"], cwd=workspace, env=env, check=True)
        for command in [base + ["build"] + TARGETS, base + ["--no-build", "build"] + TARGETS]:
            assert_unchanged(fixed)
            subprocess.run(command, cwd=workspace, env=env, check=True)
    finally:
        assert_unchanged(fixed + sources_assets)
    print("All 3136 modules and four aggregate targets are up to date. Existing build outputs may have been reused.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, OSError, subprocess.CalledProcessError) as error:
        print("Serial build stopped:", error, file=sys.stderr)
        sys.exit(1)
