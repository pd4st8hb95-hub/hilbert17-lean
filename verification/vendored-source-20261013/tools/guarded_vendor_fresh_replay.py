#!/usr/bin/env python3
"""Post-build same-kernel fresh replay; never builds or runs on import."""
import argparse
import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

CORE_SHA = "21d5de3cafe8c9387f76fc47ce490dc1f1d0b2a99c034d3ef686610079462d74"
SCHEMA = "hilbert17-vendored-fresh-replay-v1"
ARTIFACT_SUFFIXES = (".olean", ".olean.server", ".olean.private", ".ir")
ACTIVE = None
SCOPE = ("Same-Lean-kernel fresh replay of all safe, non-partial constants in BoundaryAcceptance "
         "and its entire imported environment. Declared axioms are accepted by replay and audited "
         "separately. Unsafe/partial code and an independent external checker are not covered. "
         "The installed Lean/Std/Lake runtime remains trusted, not bootstrapped from source.")


def require(ok, message):
    if not ok:
        raise RuntimeError(message)


def load_guard():
    path = Path(__file__).resolve().parent / "guarded_source_build.py"
    require(hashlib.sha256(path.read_bytes()).hexdigest() == CORE_SHA, "Reviewed guard changed")
    spec = importlib.util.spec_from_file_location("vendor_fresh_guard", path)
    guard = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(guard)
    return guard


def inventory_paths(roots):
    paths = set()
    for root in roots:
        root = Path(root)
        require(root.is_dir() and not root.is_symlink(), f"Invalid artifact root: {root}")
        for folder, dirs, files in os.walk(root, followlinks=False):
            for name in dirs + files:
                require(not (Path(folder) / name).is_symlink(), "Artifact symlink refused")
            for name in files:
                if name.endswith(ARTIFACT_SUFFIXES):
                    paths.add(str(Path(folder) / name))
    return paths


def check_inventory(g, inventory, plan):
    roots = plan["workspace_artifact_roots"] + [plan["builtin_artifact_root"]]
    require(inventory["schema"] == "hilbert17-vendored-fresh-inventory-v1", "Inventory schema mismatch")
    require(inventory["roots"] == roots, "Inventory roots differ from approved search scope")
    pins = inventory["artifact_pins"]
    expected = {p["path"] for p in pins}
    require(len(expected) == len(pins), "Duplicate artifact inventory path")
    require(inventory_paths(roots) == expected, "Replay artifact inventory membership changed")
    for record in pins + inventory["source_config_asset_pins"] + inventory["all_build_output_pins"] + inventory["toolchain_runtime_pins"]:
        g.check_pin(record)


def validate_source_completion(g, source_plan, receipt, journal):
    require(receipt["status"] == "ALL_FROM_SOURCE_OFFLINE_LAKE_BUILDS_PASS", "Full source build has not passed")
    require(receipt.get("inputs_unchanged") is True, "Source-build input verification missing")
    require(receipt["completed_modules"] == receipt["total_modules"] == 3136, "Source build incomplete")
    records = [json.loads(line) for line in Path(journal).read_text().splitlines()]
    require([r["module"] for r in records] == [j["module"] for j in source_plan["jobs"]],
            "Source journal is not the complete frozen 3136-module plan")
    expected_outputs = set()
    for job, record in zip(source_plan["jobs"], records):
        require(record["source"] == job["source"], "Compiled source pin mismatch")
        for output in record["outputs"]:
            g.check_pin(output)
            expected_outputs.add(output["path"])
        g.check_compiled_imports(job)
    require({str(p) for p in g.active_artifacts(Path(source_plan["workspace"]))} == expected_outputs,
            "Untracked or missing source-build output")
    return records


def validate_plan(g, plan, path, workspace_assertion=None):
    require(plan["schema"] == SCHEMA and plan["status"] == "READY_FOR_ROOT_REVIEW", "Unfrozen replay plan")
    require(plan["module"] == "BoundaryAcceptance", "Unexpected replay entry point")
    require(plan["runner"]["path"] == str(Path(__file__).resolve()), "Replay runner identity changed")
    if workspace_assertion:
        require(str(Path(workspace_assertion).resolve()) == plan["workspace"], "Workspace assertion mismatch")
    workspace = Path(plan["workspace"]).resolve(strict=True)
    toolchain = Path(plan["checker"]["path"]).parent.parent
    require(plan["shared_lock"] == str(workspace.parent / "hilbert17-20261013/verification/runtime-compile.lock"),
            "Wrong shared compilation lock")
    require(plan["guard"]["sha256"] == CORE_SHA, "Wrong reviewed guard pin")
    for name in ["runner", "generator", "guard", "lake", "checker", "libseccomp", "source_plan", "source_receipt", "source_journal", "inventory"]:
        g.check_pin(plan[name])
    require(Path(plan["lake"]["path"]).parent == Path(plan["checker"]["path"]).parent, "Different Lean/Lake installations")
    source_plan = g.read_json(plan["source_plan"]["path"])
    receipt = g.read_json(plan["source_receipt"]["path"])
    require(source_plan["workspace"] == plan["workspace"], "Source-build workspace mismatch")
    require(receipt["plan_sha256"] == plan["source_plan"]["sha256"], "Source receipt/plan mismatch")
    require(source_plan["lake"] == plan["lake"] and source_plan["libseccomp"] == plan["libseccomp"], "Changed build toolchain/filter")
    g.validate_configs(source_plan)
    records = validate_source_completion(g, source_plan, receipt, plan["source_journal"]["path"])
    roots = [str(workspace / ".lake/build/lib/lean")] + [str(workspace / "vendor" / p / ".lake/build/lib/lean") for p in source_plan["packages"]]
    require(plan["workspace_artifact_roots"] == roots, "Replay workspace roots mismatch")
    require(plan["builtin_artifact_root"] == str(toolchain / "lib/lean"), "Builtin artifact root mismatch")
    require(plan["source"] == next(j["source"] for j in source_plan["jobs"] if j["module"] == plan["module"]),
            "Entry source differs from source-build plan")
    boundary = next(r for r in records if r["module"] == plan["module"])
    require(plan["entry_olean"] in boundary["outputs"], "Entry artifact differs from successful source build")
    base = [plan["lake"]["path"], "--dir", str(workspace), "--no-cache", "--no-build", "env"]
    require(plan["environment_probe"] == base, "Probe must be read-only Lake env")
    require(plan["replay_command"] == base + [plan["checker"]["path"], "--fresh", "-v", plan["module"]],
            "Replay command differs from reviewed non-building command")
    inventory = g.read_json(plan["inventory"]["path"])
    require(inventory["source_config_asset_pins"] == source_plan["inputs"], "Inventory omitted/changed frozen source inputs")
    require(inventory["all_build_output_pins"] == [p for r in records for p in r["outputs"]], "Inventory output evidence mismatch")
    check_inventory(g, inventory, plan)
    return inventory


def canonical_paths(value, cwd):
    require(all(part for part in value.split(":")), "Empty search-path entry refused")
    return [str((Path(cwd) / part).resolve()) for part in value.split(":")]


def verify_lake_environment(environment, plan):
    workspace = Path(plan["workspace"])
    toolchain = Path(plan["checker"]["path"]).parent.parent
    paths = canonical_paths(environment.get("LEAN_PATH", ""), workspace)
    required = set(plan["workspace_artifact_roots"])
    allowed = required | {plan["builtin_artifact_root"]}
    require(required <= set(paths) <= allowed, "Lake env contains missing/external module paths: " + repr(paths))
    require(len(paths) == len(set(paths)), "Duplicated module search path")
    require(Path(environment.get("LEAN_SYSROOT", "")).resolve() == toolchain, "Unexpected Lean sysroot")
    src_paths = canonical_paths(environment.get("LEAN_SRC_PATH", ""), workspace)
    require(all(Path(p).is_relative_to(workspace) or Path(p).is_relative_to(toolchain) for p in src_paths),
            "External source-search path")
    require(environment.get("LEAN_NUM_THREADS") == "1", "Unexpected Lean thread count")
    return {"LEAN_PATH": paths, "LEAN_SRC_PATH": src_paths, "LEAN_SYSROOT": str(toolchain), "LEAN_NUM_THREADS": "1"}


def sampled_process_check(pgid, plan, allow_checker):
    checkers, environment = [], None
    for proc in Path("/proc").iterdir():
        if not proc.name.isdigit():
            continue
        try:
            pid = int(proc.name)
            if os.getpgid(pid) != pgid:
                continue
            exe = str((proc / "exe").resolve(strict=True))
            args = [x.decode() for x in (proc / "cmdline").read_bytes().split(b"\0") if x]
            if exe == plan["checker"]["path"]:
                require(allow_checker and args[1:] == ["--fresh", "-v", plan["module"]], "Unexpected checker invocation")
                entries = [x.decode().split("=", 1) for x in (proc / "environ").read_bytes().split(b"\0") if x]
                environment = verify_lake_environment(dict(entries), plan)
                checkers.append(pid)
            else:
                require(exe == plan["lake"]["path"], "Unexpected subprocess (compilers forbidden): " + exe)
        except (FileNotFoundError, ProcessLookupError):
            continue
    require(len(checkers) <= 1, "Concurrent checker processes")
    return checkers, environment


def run_command(g, plan, env, run, label, command, allow_checker, install_filter):
    global ACTIVE
    before = g.memory()
    prefix = run / label
    record = {"label": label, "command": command, "started_utc": g.now(), "memory_before": before,
              "stdout": str(prefix) + ".stdout.log", "stderr": str(prefix) + ".stderr.log", "status": "STARTING"}
    status_path = Path(str(prefix) + ".json")
    if before["used_percent"] >= g.REFUSE:
        record["status"] = "REFUSED_MEMORY_AT_OR_ABOVE_60_PERCENT"
        g.write_json(status_path, record)
        return record
    g.write_json(status_path, record)
    peak, started, term_at, reason = before["used_percent"], time.monotonic(), None, None
    observed_environment, observed_checkers = None, set()
    try:
        with open(record["stdout"], "wb") as out, open(record["stderr"], "wb") as err, \
                open(str(prefix) + ".memory.jsonl", "w") as samples:
            ACTIVE = subprocess.Popen(command, cwd=plan["workspace"], env=env,
                                      stdin=subprocess.DEVNULL, stdout=out, stderr=err,
                                      close_fds=True, start_new_session=True, preexec_fn=install_filter)
            record.update(status="RUNNING", pid=ACTIVE.pid)
            g.write_json(status_path, record)
            while ACTIVE.poll() is None:
                sample = g.memory()
                used = sample["used_percent"]
                peak = max(peak, used)
                try:
                    pids, checked_env = sampled_process_check(ACTIVE.pid, plan, allow_checker)
                    observed_checkers.update(pids)
                    if checked_env:
                        observed_environment = checked_env
                    sample["checker_pids"] = pids
                except RuntimeError as exc:
                    reason = "PROCESS_OR_SEARCH_PATH_GUARD:" + str(exc)
                    g.group_signal(ACTIVE, signal.SIGKILL)
                sample["elapsed_seconds"] = round(time.monotonic() - started, 3)
                samples.write(json.dumps(sample) + "\n")
                samples.flush()
                if used >= g.KILL:
                    reason = "KILLED_MEMORY_AT_OR_ABOVE_75_PERCENT"
                    g.group_signal(ACTIVE, signal.SIGKILL)
                elif term_at is None and used >= g.TERM:
                    reason, term_at = "TERMINATED_MEMORY_AT_OR_ABOVE_70_PERCENT", time.monotonic()
                    g.group_signal(ACTIVE, signal.SIGTERM)
                elif term_at is not None and time.monotonic() - term_at >= g.GRACE:
                    reason = "KILLED_AFTER_5_SECOND_TERM_GRACE"
                    g.group_signal(ACTIVE, signal.SIGKILL)
                time.sleep(0.5)
            code = ACTIVE.wait()
            g.group_signal(ACTIVE, signal.SIGKILL)
        record.update(status=reason or ("PASS" if code == 0 else "COMMAND_FAILED"), exit_code=code)
    except BaseException as exc:
        if ACTIVE is not None:
            g.group_signal(ACTIVE, signal.SIGKILL)
            ACTIVE.wait()
        record.update(status="ABORTED", error=f"{type(exc).__name__}: {exc}")
        raise
    finally:
        ACTIVE = None
        record.update(ended_utc=g.now(), seconds=round(time.monotonic() - started, 3),
                      peak_physical_used_percent=peak, observed_checker_pids=sorted(observed_checkers),
                      observed_checker_environment=observed_environment)
        g.write_json(status_path, record)
        print(record["status"], label, flush=True)
    return record


def main():
    def interrupted(number, frame):
        raise KeyboardInterrupt(f"Received signal {number}")
    signal.signal(signal.SIGINT, interrupted)
    signal.signal(signal.SIGTERM, interrupted)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plan", required=True)
    parser.add_argument("--plan-sha256", required=True)
    parser.add_argument("--run-name", required=True)
    parser.add_argument("--workspace", help="Optional assertion; relocation requires a new source-build/replay plan")
    args = parser.parse_args()
    g = load_guard()
    require(g.digest(args.plan) == args.plan_sha256, "Replay plan SHA256 mismatch")
    plan = g.read_json(args.plan)
    require(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,90}", args.run_name), "Invalid run name")
    # Shared lock is acquired before full inventory reads or process launch.
    expected_lock = Path(plan["workspace"]).parent / "hilbert17-20261013/verification/runtime-compile.lock"
    require(plan["shared_lock"] == str(expected_lock), "Wrong shared compiler lock")
    lock = expected_lock.open("a")
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    inventory = validate_plan(g, plan, args.plan, args.workspace)
    run = g.within(Path(__file__).resolve().parent / "replay-runs" / args.run_name, Path(__file__).resolve().parent)
    run.mkdir(parents=True, exist_ok=False)
    for sub in ["home", "tmp", "cache", "xdg"]:
        (run / sub).mkdir()
    toolchain = Path(plan["checker"]["path"]).parent.parent
    # This is a new environment, not os.environ.copy(). Leave LEAN_PATH and
    # LEAN_SRC_PATH absent: Lake parses a present empty string as an empty path
    # component and otherwise appends a trailing colon. Keep the strict path
    # validator unchanged; it must still reject every empty search-path entry.
    env = {"PATH": str(toolchain / "bin") + ":/usr/bin:/bin", "HOME": str(run / "home"), "TMPDIR": str(run / "tmp"),
           "XDG_CACHE_HOME": str(run / "cache"), "XDG_CONFIG_HOME": str(run / "xdg"), "LC_ALL": "C.UTF-8",
           "LEAN_SYSROOT": str(toolchain), "LEAN_NUM_THREADS": "1",
           "LAKE_NO_CACHE": "1", "LAKE_ARTIFACT_CACHE": "false", "LAKE_CACHE_DIR": str(run / "cache"),
           "MATHLIB_NO_CACHE_ON_UPDATE": "1", "GIT_TERMINAL_PROMPT": "0", "GIT_CONFIG_NOSYSTEM": "1"}
    install_filter, syscalls = g.prepare_network_filter(plan["libseccomp"]["path"])
    summary = {"status": "RUNNING", "started_utc": g.now(), "plan": str(Path(args.plan).resolve()),
               "plan_sha256": args.plan_sha256, "source_build": plan["source_receipt"], "inventory": plan["inventory"],
               "scope": SCOPE, "environment": env, "jobs": [], "network_syscalls_denied": syscalls,
               "memory_policy": {"sample_seconds": 0.5, "refuse_percent": 60, "term_percent": 70, "kill_percent": 75, "term_grace_seconds": 5},
               "wall_time_limit": None, "checker_memory_cap": "No -M CLI support; physical-memory guard applies",
               "guard_scope": "Process/memory observations sampled every0.5s, not exhaustive; network denial is enforced in child kernel filter"}
    summary_path = run / "summary.json"
    g.write_json(summary_path, summary)
    fixed = [plan[n] for n in ["runner", "generator", "guard", "lake", "checker", "libseccomp", "source_plan", "source_receipt", "source_journal", "inventory"]]
    try:
        probe = run_command(g, plan, env, run, "lake-environment", plan["environment_probe"], False, install_filter)
        summary["jobs"].append(probe)
        g.write_json(summary_path, summary)
        if probe["status"] != "PASS":
            summary["status"] = "STOPPED_ENVIRONMENT_PROBE_OR_RESOURCE_LIMIT"
            return 1
        reported = dict(line.split("=", 1) for line in Path(probe["stdout"]).read_text().splitlines() if "=" in line)
        # Lake prints only augmented vars. Unchanged variables come from our fixed environment.
        summary["verified_lake_environment"] = verify_lake_environment({**env, **reported}, plan)
        for record in fixed + inventory["source_config_asset_pins"]:
            g.check_pin(record)
        replay = run_command(g, plan, env, run, "BoundaryAcceptance-fresh", plan["replay_command"], True, install_filter)
        summary["jobs"].append(replay)
        if replay["status"] == "PASS":
            output = Path(replay["stdout"]).read_text()
            require("replaying BoundaryAcceptance with --fresh" in output, "Expected fresh replay confirmation missing")
            require(replay["observed_checker_environment"] is not None, "Checker environment was never observed; cannot attest local replay")
            summary["status"] = "ALL_IMPORTED_SAFE_CONSTANTS_FRESH_REPLAY_PASS"
            return 0
        summary["status"] = "FRESH_REPLAY_INCOMPLETE_OR_FAILED"
        return 1
    except BaseException as exc:
        summary.update(status="ABORTED_OR_INPUT_DRIFT", error=f"{type(exc).__name__}: {exc}")
        raise
    finally:
        try:
            for record in fixed:
                g.check_pin(record)
            check_inventory(g, inventory, plan)
            summary["all_pinned_inputs_and_artifacts_unchanged"] = True
        except BaseException as exc:
            summary.update(status="INPUT_OR_ARTIFACT_CHANGED", all_pinned_inputs_and_artifacts_unchanged=False,
                           final_pin_error=f"{type(exc).__name__}: {exc}")
            raise
        finally:
            summary["ended_utc"] = g.now()
            g.write_json(summary_path, summary)
            print("SUMMARY", summary["status"], summary_path, flush=True)


if __name__ == "__main__":
    sys.exit(main())
