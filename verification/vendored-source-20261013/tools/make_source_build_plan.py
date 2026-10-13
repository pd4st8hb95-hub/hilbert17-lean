#!/usr/bin/env python3
"""Freeze sources/configs and a topological DAG; never execute Lean or Lake."""
import argparse
import hashlib
import heapq
import json
import os
from pathlib import Path
import sys
import tomllib


def require(test, message):
    if not test:
        raise RuntimeError(message)


def pin(path):
    p = Path(path).resolve(strict=True)
    h = hashlib.sha256()
    with p.open("rb") as f:
        for b in iter(lambda: f.read(1024 * 1024), b""):
            h.update(b)
    return {"path": str(p), "bytes": p.stat().st_size, "sha256": h.hexdigest()}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace", required=True)
    parser.add_argument("--toolchain", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--libseccomp", default="/lib/x86_64-linux-gnu/libseccomp.so.2")
    args = parser.parse_args()
    workspace = Path(args.workspace).resolve(strict=True)
    toolchain = Path(args.toolchain).resolve(strict=True)
    tools = Path(__file__).resolve().parent
    output = Path(args.output).resolve()
    require(output.is_relative_to(tools), "Plan must be stored in reviewed tool directory")
    require(not output.exists(), "Refusing to overwrite frozen plan")
    manifest = json.loads((workspace / "vendor-source-manifest.json").read_text())
    config = tomllib.loads((workspace / "lakefile.toml").read_text())
    roots = [m for lib in config["lean_lib"] for m in lib["roots"]]
    require(roots == manifest["roots"] and len(roots) == 97, "Changed configured root scope")
    modules = {x["module"]: x for x in manifest["modules"]}
    require(len(modules) == len(manifest["modules"]) == 3136, "Unexpected or duplicate module count")
    boundaries = set(manifest["toolchain_import_boundaries"])
    indegree, reverse = {}, {m: [] for m in modules}
    for name, record in modules.items():
        require(set(record["imports"]) <= set(modules) | boundaries, "Unknown imported module")
        deps = set(record["imports"]) & modules.keys()
        indegree[name] = len(deps)
        for dep in deps:
            reverse[dep].append(name)
    ready = [name for name in modules if not indegree[name]]
    heapq.heapify(ready)
    order = []
    while ready:
        name = heapq.heappop(ready)
        order.append(name)
        for child in reverse[name]:
            indegree[child] -= 1
            if indegree[child] == 0:
                heapq.heappush(ready, child)
    require(len(order) == len(modules), "Import cycle in frozen closure")
    jobs = []
    for module in order:
        record = modules[module]
        root = workspace if record["package"] == "project" else workspace / "vendor" / record["package"]
        source = pin(root / record["path"])
        require(source["sha256"] == record["sha256"] and source["bytes"] == record["bytes"],
                "Vendoring manifest/source mismatch: " + module)
        jobs.append({"module": module, "package": record["package"], "package_root": str(root),
                     "source": source, "imports": record["imports"]})
    inputs, configs = [], []
    for root, dirs, files in os.walk(workspace):
        dirs[:] = sorted(d for d in dirs if d not in {".lake", ".git", "verification", "__pycache__"})
        for name in sorted(dirs + files):
            require(not (Path(root) / name).is_symlink(), "Workspace input symlink refused")
        for name in sorted(files):
            p = Path(root) / name
            require(not name.endswith((".olean", ".olean.private", ".olean.server", ".ilean", ".ir")),
                    "Precompiled artifact found among source inputs")
            record = pin(p)
            inputs.append(record)
            if name in {"lakefile.toml", "lakefile.lean", "lake-manifest.json", "lean-toolchain"}:
                configs.append(record)
    packages = sorted({record["package"] for record in modules.values()} - {"project"})
    plan = {"schema": "hilbert17-vendored-source-build-v1", "status": "READY_FOR_ROOT_REVIEW",
            "workspace": str(workspace), "runner": pin(tools / "guarded_source_build.py"),
            "generator": pin(__file__), "lake": pin(toolchain / "bin/lake"), "lean": pin(toolchain / "bin/lean"),
            "libseccomp": pin(args.libseccomp), "packages": packages, "roots": roots,
            "toolchain_import_boundaries": sorted(boundaries), "inputs": inputs,
            "configuration_pins": configs, "jobs": jobs,
            "shared_lock": str(workspace.parent / "hilbert17-20261013/verification/runtime-compile.lock"),
            "source_only_scope": "3136 modules: 2775 Mathlib + 264 other dependencies + 97 project; installed Lean/Std/Lake toolchain trusted, not rebuilt",
            "serial_strategy": "Topological order; before each +Module:olean, require +Module:deps --no-build. All packages -j 1 -M 4096. No concurrent compiler jobs.",
            "network_strategy": "Fail-closed child-only libseccomp filter denies sockets/traffic and io_uring; empty module search paths and isolated HOME/cache.",
            "memory_strategy": "Sample physical MemTotal/MemAvailable every 0.5s; refuse at60%, TERM at70%, KILL at75%, 5s TERM grace; no arbitrary wall-time cutoff",
            "resume_strategy": "Same-plan explicit --resume; rehash all source/config inputs and successful output journal, preserve partial current-module outputs in quarantine, continue at first unfinished module"}
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(plan, indent=2) + "\n")
    print(json.dumps({"plan": pin(output), "module_count": len(jobs), "input_count": len(inputs),
                      "total_input_bytes": sum(p["bytes"] for p in inputs), "status": "PREPARED_NOT_BUILT"}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
