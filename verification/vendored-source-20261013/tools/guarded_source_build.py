#!/usr/bin/env python3
"""Root-reviewed, fail-closed, serial offline Lake source-build driver.

This file does not run Lean merely by being imported. Use an independently
reviewed SHA256-pinned plan, and start/resume explicitly from the command line.
"""
import argparse
import ctypes
import datetime
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time
import tomllib

SCHEMA = "hilbert17-vendored-source-build-v1"
REFUSE, TERM, KILL, GRACE = 60.0, 70.0, 75.0, 5.0
MODULE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*\Z")
TARGETS = ["Hilbert17", "Hilbert17RealClosure", "Hilbert17Full", "Hilbert17Acceptance"]
NETWORK_SYSCALLS = ["socket", "socketpair", "socketcall", "connect", "bind", "listen",
                    "accept", "accept4", "sendto", "sendmsg", "sendmmsg", "recvfrom",
                    "recvmsg", "recvmmsg", "io_uring_setup", "io_uring_enter", "io_uring_register"]
ACTIVE = None


def require(test, message):
    if not test:
        raise RuntimeError(message)


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def digest(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def pin(path):
    p = Path(path).resolve(strict=True)
    return {"path": str(p), "bytes": p.stat().st_size, "sha256": digest(p)}


def check_pin(record):
    p = Path(record["path"])
    require(p.is_file() and p.stat().st_size == record["bytes"] and digest(p) == record["sha256"],
            f"Pinned file mismatch: {p}")


def write_json(path, data):
    path = Path(path)
    temp = path.with_name(path.name + ".tmp")
    with temp.open("w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
        f.flush()
        os.fsync(f.fileno())
    os.replace(temp, path)


def read_json(path):
    return json.loads(Path(path).read_text())


def within(path, root):
    p, root = Path(path), Path(root).resolve()
    require(p.resolve().is_relative_to(root), f"Path escapes boundary: {p}")
    for q in [p, *p.parents]:
        require(not q.is_symlink(), f"Symlink refused: {q}")
        if q == root:
            break
    return p


def memory():
    values = {}
    for line in Path("/proc/meminfo").read_text().splitlines():
        key, value = line.split(":", 1)
        if key in {"MemTotal", "MemAvailable"}:
            values[key] = int(value.split()[0])
    total, available = values["MemTotal"], values["MemAvailable"]
    require(0 < available <= total, "Invalid physical-memory sample")
    return {"utc": now(), "total_kib": total, "available_kib": available,
            "used_percent": 100.0 * (total - available) / total}


def group_signal(proc, sig):
    try:
        os.killpg(proc.pid, sig)
    except ProcessLookupError:
        pass


def prepare_network_filter(library):
    """Prepare ctypes symbols in parent; install only in each isolated child.

    No host settings change. The filter survives exec/fork, denies all socket
    creation/traffic and io_uring routes, and fails closed on unsupported setup.
    Popen closes all other inherited descriptors, so no network socket is passed.
    """
    lib = ctypes.CDLL(str(library), use_errno=True)
    lib.seccomp_init.argtypes = [ctypes.c_uint32]
    lib.seccomp_init.restype = ctypes.c_void_p
    lib.seccomp_release.argtypes = [ctypes.c_void_p]
    lib.seccomp_release.restype = None
    lib.seccomp_syscall_resolve_name.argtypes = [ctypes.c_char_p]
    lib.seccomp_syscall_resolve_name.restype = ctypes.c_int
    lib.seccomp_rule_add.argtypes = [ctypes.c_void_p, ctypes.c_uint32, ctypes.c_int, ctypes.c_uint]
    lib.seccomp_rule_add.restype = ctypes.c_int
    lib.seccomp_load.argtypes = [ctypes.c_void_p]
    lib.seccomp_load.restype = ctypes.c_int
    numbers = {name: lib.seccomp_syscall_resolve_name(name.encode()) for name in NETWORK_SYSCALLS}
    require(all(numbers[name] >= 0 for name in ["socket", "connect", "socketpair", "io_uring_setup"]),
            "Mandatory network syscall resolution unavailable")
    libc = ctypes.CDLL(None, use_errno=True)
    libc.prctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_ulong]
    libc.prctl.restype = ctypes.c_int

    def install():
        # ctypes objects are already loaded; this parent is strictly single-threaded.
        if libc.prctl(38, 1, 0, 0, 0) != 0:  # PR_SET_NO_NEW_PRIVS
            raise RuntimeError("PR_SET_NO_NEW_PRIVS failed")
        ctx = lib.seccomp_init(0x7FFF0000)  # SCMP_ACT_ALLOW
        if not ctx:
            raise RuntimeError("seccomp_init failed")
        try:
            for number in sorted(set(numbers.values())):
                if number >= 0 and lib.seccomp_rule_add(ctx, 0x00050000 | errno.EPERM, number, 0) != 0:
                    raise RuntimeError("seccomp_rule_add failed")
            if lib.seccomp_load(ctx) != 0:
                raise RuntimeError("seccomp_load failed")
        finally:
            lib.seccomp_release(ctx)
    return install, numbers


def last_flag(args, letter):
    found = None
    for i, arg in enumerate(args):
        if arg == "-" + letter and i + 1 < len(args):
            found = args[i + 1]
        elif arg.startswith("-" + letter) and len(arg) > 2:
            found = arg[2:].lstrip("=")
    return found


def inspect_group(pgid, lake, lean, allowed):
    """Backstop only: half-second process samples do not see every short process."""
    compilers, sources = [], []
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            pid = int(entry.name)
            if os.getpgid(pid) != pgid:
                continue
            exe = (entry / "exe").resolve(strict=True)
            args = [a.decode() for a in (entry / "cmdline").read_bytes().split(b"\0") if a]
            if exe == lean:
                files = [a for a in args[1:] if a.endswith(".lean")]
                if files:
                    cwd = (entry / "cwd").resolve(strict=True)
                    paths = {(cwd / a).resolve() for a in files}
                    sources.extend(str(p) for p in paths)
                    compilers.append(pid)
                    if len(paths) != 1 or not paths <= allowed:
                        return "UNEXPECTED_LEAN_SOURCE", compilers, sources
                    if last_flag(args, "j") != "1" or last_flag(args, "M") != "4096":
                        return "UNEXPECTED_LEAN_RESOURCE_FLAGS", compilers, sources
            elif exe != lake:
                # An occasional vanished/zombie process is handled below; no
                # compiler helper, shell, git, npm, or network program is expected.
                return "UNEXPECTED_SUBPROCESS:" + str(exe), compilers, sources
        except (FileNotFoundError, ProcessLookupError):
            continue
    return ("MULTIPLE_LEAN_COMPILERS" if len(compilers) > 1 else None), compilers, sources


def outputs(job, workspace):
    """Enumerate only the exact module stem, including Lake hash/trace sidecars."""
    result = []
    base = within(Path(job["package_root"]) / ".lake/build", workspace)
    parts = job["module"].split(".")
    for folder in ["lib/lean", "ir"]:
        stem = base / folder / Path(*parts)
        if stem.parent.is_dir():
            for p in sorted(stem.parent.glob(stem.name + ".*")):
                if p.is_file():
                    within(p, workspace)
                    result.append(pin(p))
    return result


def check_compiled_imports(job):
    p = Path(job["package_root"]) / ".lake/build/lib/lean" / Path(*job["module"].split("."))
    ilean = p.with_suffix(".ilean")
    require(p.with_suffix(".olean").is_file() and ilean.is_file(), "Missing newly built olean/ilean")
    info = read_json(ilean)
    require(info["module"] == job["module"], "Compiled module identity mismatch")
    require([x[0] for x in info["directImports"]] == job["imports"],
            "Compiled direct imports differ from frozen DAG: " + job["module"])


def run_command(label, command, allowed, plan, env, run, ordinal, install_filter):
    global ACTIVE
    prefix = run / f"{ordinal:05d}-{label.replace('.', '_').replace(':', '_')}"
    before = memory()
    record = {"label": label, "command": command, "started_utc": now(), "memory_before": before,
              "stdout": str(prefix) + ".stdout.log", "stderr": str(prefix) + ".stderr.log",
              "memory_log": str(prefix) + ".memory.jsonl", "status": "STARTING"}
    status_path = Path(str(prefix) + ".json")
    if before["used_percent"] >= REFUSE:
        record["status"] = "REFUSED_MEMORY_AT_OR_ABOVE_60_PERCENT"
        write_json(status_path, record)
        return record
    write_json(status_path, record)
    print("START", label, flush=True)
    started, term_at, reason = time.monotonic(), None, None
    peak, observed = before["used_percent"], set()
    try:
        with open(record["stdout"], "wb") as out, open(record["stderr"], "wb") as err, \
                open(record["memory_log"], "w") as samples:
            ACTIVE = subprocess.Popen(command, cwd=plan["workspace"], env=env,
                                      stdin=subprocess.DEVNULL, stdout=out, stderr=err,
                                      start_new_session=True, close_fds=True,
                                      preexec_fn=install_filter)
            record.update(pid=ACTIVE.pid, status="RUNNING")
            write_json(status_path, record)
            while ACTIVE.poll() is None:
                sample = memory()
                used = sample["used_percent"]
                peak = max(peak, used)
                violation, compilers, sources = inspect_group(
                    ACTIVE.pid, Path(plan["lake"]["path"]), Path(plan["lean"]["path"]), allowed)
                sample.update(lean_compilers=compilers, lean_source_paths=sources)
                observed.update(sources)
                samples.write(json.dumps(sample) + "\n")
                samples.flush()
                if violation:
                    reason = violation
                    group_signal(ACTIVE, signal.SIGKILL)
                elif used >= KILL:
                    reason = "KILLED_MEMORY_AT_OR_ABOVE_75_PERCENT"
                    group_signal(ACTIVE, signal.SIGKILL)
                elif term_at is None and used >= TERM:
                    reason, term_at = "TERMINATED_MEMORY_AT_OR_ABOVE_70_PERCENT", time.monotonic()
                    group_signal(ACTIVE, signal.SIGTERM)
                elif term_at is not None and time.monotonic() - term_at >= GRACE:
                    reason = "KILLED_AFTER_5_SECOND_TERM_GRACE"
                    group_signal(ACTIVE, signal.SIGKILL)
                time.sleep(0.5)
            code = ACTIVE.wait()
            group_signal(ACTIVE, signal.SIGKILL)
        record.update(status=reason or ("PASS" if code == 0 else "COMMAND_FAILED"), exit_code=code)
    except BaseException as exc:
        if ACTIVE is not None:
            group_signal(ACTIVE, signal.SIGKILL)
            ACTIVE.wait()
        record.update(status="ABORTED", error=f"{type(exc).__name__}: {exc}")
        raise
    finally:
        ACTIVE = None
        record.update(ended_utc=now(), seconds=round(time.monotonic() - started, 3),
                      peak_physical_used_percent=peak, observed_lean_sources=sorted(observed))
        write_json(status_path, record)
        print(record["status"], label, flush=True)
    return record


def validate_configs(plan):
    workspace = Path(plan["workspace"])
    packages = {"project": workspace}
    packages.update({name: workspace / "vendor" / name for name in plan["packages"]})
    for name, root in packages.items():
        require(not (root / "lakefile.lean").exists(), "Executable Lake config refused")
        config = tomllib.loads((root / "lakefile.toml").read_text())
        require(config.get("weakLeanArgs") == ["-j", "1", "-M", "4096"],
                f"Missing exact serial/4096 MiB compiler settings: {name}")
        require(config.get("enableArtifactCache") is False and config.get("preferReleaseBuild") is False,
                f"Artifact/release cache not disabled: {name}")
        require(not config.get("precompileModules", False), "Native precompilation refused")
        require(not any(k in config for k in ["extern_lib", "target", "lean_exe", "script"]),
                "Unexpected executable/custom target")
        for lib in config.get("lean_lib", []):
            require(not lib.get("precompileModules", False), "Library precompilation refused")
            require(not lib.get("extraDepTargets"), "Extra dependency targets refused")
            require(not lib.get("leanArgs") and not lib.get("weakLeanArgs"), "Library resource override refused")
        for req in config.get("require", []):
            require(set(req) <= {"name", "path", "scope"} and req.get("name") in packages and req.get("path"),
                    "Nonlocal or unexpected package requirement")
            require((root / req["path"]).resolve() == packages[req["name"]].resolve(),
                    "Package path mismatch")
    require(tomllib.loads((workspace / "lakefile.toml").read_text())["defaultTargets"] == TARGETS,
            "Wrong root target scope")
    manifest = read_json(workspace / "lake-manifest.json")
    require({p["name"] for p in manifest["packages"]} == set(plan["packages"]), "Manifest package scope changed")
    for entry in manifest["packages"]:
        require(entry["type"] == "path" and (workspace / entry["dir"]).resolve() == packages[entry["name"]],
                "Manifest refers outside local vendored package")


def validate_plan(plan, args):
    require(plan["schema"] == SCHEMA and plan["status"] == "READY_FOR_ROOT_REVIEW", "Unfrozen plan")
    require(plan["runner"]["path"] == str(Path(__file__).resolve()), "Runner identity mismatch")
    workspace = Path(plan["workspace"]).resolve(strict=True)
    require(workspace.name == "hilbert17-vendored-20261013", "Unexpected workspace")
    for item in [plan["runner"], plan["generator"], plan["lake"], plan["lean"], plan["libseccomp"]]:
        check_pin(item)
    require(Path(plan["lake"]["path"]).parent == Path(plan["lean"]["path"]).parent, "Mismatched toolchain")
    require(plan["shared_lock"] == str(workspace.parent / "hilbert17-20261013/verification/runtime-compile.lock"),
            "Different compiler serialization lock")
    for record in plan["inputs"]:
        within(record["path"], workspace)
        check_pin(record)
    # Symlinks and executable configs anywhere in the active workspace are rejected.
    for root, dirs, files in os.walk(workspace):
        for name in dirs + files:
            require(not (Path(root) / name).is_symlink(), "Workspace symlink refused")
    validate_configs(plan)
    seen = set()
    boundaries = set(plan["toolchain_import_boundaries"])
    require(all(n.split(".")[0] in {"Init", "Lean", "Std", "Lake"} for n in boundaries),
            "Non-toolchain import boundary")
    for job in plan["jobs"]:
        module = job["module"]
        require(MODULE.fullmatch(module) and module not in seen, "Duplicate/invalid module")
        expected_root = workspace if job["package"] == "project" else workspace / "vendor" / job["package"]
        require(Path(job["package_root"]) == expected_root, "Unexpected module package root")
        require(Path(job["source"]["path"]).is_relative_to(expected_root), "Source outside package")
        require(set(job["imports"]) <= seen | boundaries, "Non-topological/unknown dependency: " + module)
        check_pin(job["source"])
        seen.add(module)
    require(len(seen) == 3136 and len(plan["roots"]) == 97 and set(plan["roots"]) <= seen,
            "Unexpected closure size or root scope")
    require(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,90}", args.run_name), "Invalid run name")


def active_artifacts(workspace):
    for root, dirs, files in os.walk(workspace):
        for name in files:
            p = Path(root) / name
            if ".lake" in p.relative_to(workspace).parts and "build" in p.relative_to(workspace).parts:
                yield p
            elif name.endswith((".olean", ".olean.private", ".olean.server", ".ilean", ".ir")):
                yield p


def restore_completed(run, plan):
    completed, expected = [], set()
    journal = run / "completed.jsonl"
    if journal.exists():
        for line in journal.read_text().splitlines():
            record = json.loads(line)
            i = len(completed)
            require(record["module"] == plan["jobs"][i]["module"], "Non-prefix resume journal")
            for output in record["outputs"]:
                check_pin(output)
                expected.add(output["path"])
            check_compiled_imports(plan["jobs"][i])
            completed.append(record)
    return completed, expected


def main():
    def interrupted(number, frame):
        raise KeyboardInterrupt(f"Received signal {number}")
    signal.signal(signal.SIGINT, interrupted)
    signal.signal(signal.SIGTERM, interrupted)
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", required=True)
    parser.add_argument("--plan-sha256", required=True)
    parser.add_argument("--run-name", required=True)
    parser.add_argument("--resume", action="store_true",
                        help="Verify prior outputs, preserve/quarantine an unfinished module, then continue the same plan")
    args = parser.parse_args()
    require(digest(args.plan) == args.plan_sha256, "Plan SHA256 mismatch")
    plan = read_json(args.plan)
    workspace = Path(plan["workspace"])
    lock = Path(plan["shared_lock"]).open("a")
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    validate_plan(plan, args)
    install_filter, syscall_numbers = prepare_network_filter(plan["libseccomp"]["path"])
    run = within(Path(__file__).resolve().parent / "runs" / args.run_name, Path(__file__).resolve().parent)
    run.parent.mkdir(exist_ok=True)
    if args.resume:
        require(run.is_dir(), "Resume run does not exist")
        prior = read_json(run / "summary.json")
        require(prior["plan_sha256"] == args.plan_sha256, "Cannot resume with a changed plan")
        require(prior["status"] != "ALL_FROM_SOURCE_OFFLINE_LAKE_BUILDS_PASS", "Already complete")
        completed, known = restore_completed(run, plan)
        # Preserve, rather than delete, partial outputs of the one unfinished module.
        unfinished = plan["jobs"][len(completed)] if len(completed) < len(plan["jobs"]) else None
        partial = outputs(unfinished, workspace) if unfinished else []
        allowable = known | {p["path"] for p in partial}
        unknown = [str(p) for p in active_artifacts(workspace) if str(p) not in allowable]
        require(not unknown, "Untracked build artifacts; preserve and review before resume: " + str(unknown[:10]))
        attempt = prior["attempt"] + 1
        if partial:
            quarantine = run / f"partial-before-attempt-{attempt:03d}"
            quarantine.mkdir()
            write_json(quarantine / "manifest.json", partial)
            for record in partial:
                p = Path(record["path"])
                dest = within(quarantine / p.relative_to(workspace), quarantine)
                dest.parent.mkdir(parents=True, exist_ok=True)
                os.replace(p, dest)
    else:
        require(not run.exists(), "Run already exists; use a new name or explicit --resume")
        require(not list(active_artifacts(workspace)), "Fresh source build refuses any preexisting build artifacts")
        run.mkdir()
        completed, attempt = [], 1
    attempt_dir = run / f"attempt-{attempt:03d}"
    attempt_dir.mkdir()
    for name in ["home", "tmp", "cache", "xdg"]:
        (attempt_dir / name).mkdir()
    env = {"PATH": str(Path(plan["lake"]["path"]).parent) + ":/usr/bin:/bin",
           "HOME": str(attempt_dir / "home"), "TMPDIR": str(attempt_dir / "tmp"),
           "XDG_CACHE_HOME": str(attempt_dir / "cache"), "XDG_CONFIG_HOME": str(attempt_dir / "xdg"),
           "LC_ALL": "C.UTF-8", "LEAN_PATH": "", "LEAN_SRC_PATH": "", "LEAN_NUM_THREADS": "1",
           "LAKE_NO_CACHE": "1", "LAKE_ARTIFACT_CACHE": "false", "LAKE_CACHE_DIR": str(attempt_dir / "cache"),
           "MATHLIB_NO_CACHE_ON_UPDATE": "1", "GIT_TERMINAL_PROMPT": "0", "GIT_CONFIG_NOSYSTEM": "1"}
    summary = {"status": "RUNNING", "started_utc": now(), "plan_sha256": args.plan_sha256,
               "plan": str(Path(args.plan).resolve()), "attempt": attempt, "completed_modules": len(completed),
               "total_modules": len(plan["jobs"]), "environment": env,
               "network_filter": {"scope": "Every Lake child and its descendants; host unchanged",
                                  "action": "EPERM", "syscalls": syscall_numbers},
               "runtime_observation_scope": "0.5-second physical-memory/process samples; short-lived processes may not be observed",
               "trusted_toolchain_scope": "Installed Lean/Std/Lake toolchain artifacts are reused; all 3136 project and external-package modules are rebuilt from source"}
    summary_path = run / "summary.json"
    write_json(summary_path, summary)
    write_json(attempt_dir / "input-verification-before.json", {"utc": now(), "pins": plan["inputs"]})
    base = [plan["lake"]["path"], "--dir", str(workspace), "--no-cache"]
    ordinal = 0
    small_pins = plan["configuration_pins"] + [plan["runner"], plan["lake"], plan["lean"], plan["libseccomp"]]

    def execute(label, command, allowed, source=None):
        nonlocal ordinal
        for record in small_pins:
            check_pin(record)
        if source:
            check_pin(source)
        ordinal += 1
        result = run_command(label, command, allowed, plan, env, attempt_dir, ordinal, install_filter)
        if source:
            check_pin(source)
        summary["last_command"] = {k: result[k] for k in ["label", "status", "stdout", "stderr"]}
        write_json(summary_path, summary)
        return result

    try:
        for index in range(len(completed), len(plan["jobs"])):
            job = plan["jobs"][index]
            module = job["module"]
            summary.update(current_module=module, current_index=index)
            write_json(summary_path, summary)
            require(not outputs(job, workspace), "Unbuilt module already has artifacts: " + module)
            deps = execute(module + ":deps", base + ["--no-build", "build", "+" + module + ":deps"], set(), job["source"])
            if deps["status"] != "PASS":
                summary["status"] = "STOPPED_DEPENDENCY_CHECK_OR_RESOURCE_LIMIT"
                return 1
            built = execute(module + ":olean", base + ["build", "+" + module + ":olean"],
                            {Path(job["source"]["path"])}, job["source"])
            if built["status"] != "PASS":
                summary["status"] = "STOPPED_BUILD_FAILURE_OR_RESOURCE_LIMIT"
                return 1
            check_compiled_imports(job)
            record = {"module": module, "source": job["source"], "completed_utc": now(),
                      "attempt": attempt, "outputs": outputs(job, workspace)}
            with (run / "completed.jsonl").open("a") as journal:
                journal.write(json.dumps(record) + "\n")
                journal.flush()
                os.fsync(journal.fileno())
            summary["completed_modules"] = index + 1
            write_json(summary_path, summary)
        for label, command in [("aggregate", base + ["build"] + TARGETS),
                               ("final-up-to-date", base + ["--no-build", "build"] + TARGETS)]:
            if execute(label, command, set())["status"] != "PASS":
                summary["status"] = "STOPPED_AGGREGATE_CHECK_FAILURE"
                return 1
        # Check all final outputs once, not once per module.
        verified, expected = restore_completed(run, plan)
        require(len(verified) == len(plan["jobs"]), "Incomplete final source-build journal")
        unknown = [str(p) for p in active_artifacts(workspace) if str(p) not in expected]
        require(not unknown, "Final untracked build artifacts: " + str(unknown[:10]))
        summary["status"] = "ALL_FROM_SOURCE_OFFLINE_LAKE_BUILDS_PASS"
        return 0
    except BaseException as exc:
        summary.update(status="ABORTED", error=f"{type(exc).__name__}: {exc}")
        raise
    finally:
        try:
            for record in plan["inputs"]:
                check_pin(record)
            write_json(attempt_dir / "input-verification-after.json", {"utc": now(), "status": "ALL_INPUT_PINS_UNCHANGED", "count": len(plan["inputs"])})
            summary["inputs_unchanged"] = True
        except BaseException as exc:
            summary.update(status="INPUT_PIN_CHANGED", inputs_unchanged=False,
                           input_pin_error=f"{type(exc).__name__}: {exc}")
            raise
        finally:
            summary["ended_utc"] = now()
            write_json(summary_path, summary)
            write_json(attempt_dir / "summary.json", summary)
            print("SUMMARY", summary["status"], summary_path, flush=True)


if __name__ == "__main__":
    sys.exit(main())
