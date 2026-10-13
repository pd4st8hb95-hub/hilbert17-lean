#!/usr/bin/env python3
"""Root-reviewed, single-module fresh replay; staging this file executes nothing.

The checker is Lean's own kernel. The whole imported environment is replayed,
not merely the target module's new constants. Unsafe/partial constants are
skipped by Lean.Environment.replay, and axiom admissibility is audited separately.
"""
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
import time

WORK = Path(__file__).resolve().parent
PORTABLE = WORK.parent / "hilbert17-portable-check"
CORE_HASH = "390d24bf21a2e13874c631965503c69d7d2bc62c0f2298c63fb776e93bd4a9ee"
PACKAGES = ("mathlib", "plausible", "LeanSearchClient", "importGraph",
            "proofwidgets", "aesop", "Qq", "batteries")
ARTIFACT_SUFFIXES = (".olean", ".olean.server", ".olean.private", ".ir")
ACTIVE = None


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def read_json(path):
    return json.loads(Path(path).read_text())


def inventory_paths(roots):
    """Include optional private/server/IR files so their appearance cannot escape pins."""
    paths = set()
    for root in roots:
        root = Path(root)
        require(root.is_dir() and not root.is_symlink(), f"Invalid artifact root: {root}")
        for folder, dirs, files in os.walk(root, followlinks=False):
            for name in dirs:
                require(not (Path(folder) / name).is_symlink(), "Artifact directory symlink")
            for name in files:
                if name.endswith(ARTIFACT_SUFFIXES):
                    p = Path(folder) / name
                    require(not p.is_symlink(), f"Artifact file symlink: {p}")
                    paths.add(str(p))
    return paths


def check_inventory(g, inventory, roots):
    require(inventory["schema"] == "hilbert17-fresh-artifact-inventory-v1", "Wrong inventory schema")
    require(inventory["roots"] == roots, "Artifact inventory roots differ from search path")
    pins = inventory["pins"]
    expected = {p["path"] for p in pins}
    require(len(expected) == len(pins), "Duplicate artifact pins")
    require(inventory_paths(roots) == expected, "Artifact inventory membership changed")
    for pin in pins:
        g.check_pin(pin)
    for pin in inventory["source_pins"] + inventory["configuration_pins"]:
        require(Path(pin["path"]).resolve().is_relative_to(PORTABLE), "Portable input escapes tree")
        g.check_pin(pin)


def run_fresh(g, checker, module, env, run, max_seconds):
    global ACTIVE
    before = g.memory()
    prefix = run / module
    row = {"module": module, "command": [checker, "--fresh", "-v", module],
           "start_utc": g.now(), "memory_before": before,
           "max_wall_seconds": max_seconds, "status": "PREPARING"}
    status_path = Path(str(prefix) + ".json")
    if before["used_percent"] >= g.REFUSE:
        row["status"] = "REFUSED_MEMORY_AT_OR_ABOVE_60_PERCENT"
        g.write_json(status_path, row)
        return row
    row.update(stdout=str(prefix) + ".stdout.log", stderr=str(prefix) + ".stderr.log")
    started, term_at, reason, warned = time.monotonic(), None, None, False
    peak = before["used_percent"]
    with open(row["stdout"], "wb") as out, open(row["stderr"], "wb") as err, \
            open(str(prefix) + ".memory.jsonl", "w") as samples:
        try:
            ACTIVE = subprocess.Popen(row["command"], cwd=PORTABLE, env=env,
                stdin=subprocess.DEVNULL, stdout=out, stderr=err, start_new_session=True)
            row.update(pid=ACTIVE.pid, status="RUNNING")
            g.write_json(status_path, row)
            while ACTIVE.poll() is None:
                sample = g.memory()
                used = sample["used_percent"]
                elapsed = time.monotonic() - started
                peak = max(peak, used)
                sample["elapsed_seconds"] = round(elapsed, 3)
                samples.write(json.dumps(sample) + "\n")
                samples.flush()
                if used >= g.WARN and not warned:
                    print(f"MEMORY WARNING {used:.2f}% during fresh replay", flush=True)
                    warned = True
                if used >= g.KILL:
                    reason = "KILLED_MEMORY_AT_OR_ABOVE_75_PERCENT"
                    g.group_signal(ACTIVE, signal.SIGKILL)
                elif term_at is None and used >= g.TERM:
                    reason, term_at = "TERMINATED_MEMORY_AT_OR_ABOVE_70_PERCENT", time.monotonic()
                    g.group_signal(ACTIVE, signal.SIGTERM)
                elif term_at is None and elapsed >= max_seconds:
                    reason, term_at = "TERMINATED_WALL_TIME_LIMIT", time.monotonic()
                    g.group_signal(ACTIVE, signal.SIGTERM)
                elif term_at is not None and time.monotonic() - term_at >= g.GRACE:
                    row["termination_trigger"] = reason
                    reason = "KILLED_AFTER_5_SECOND_TERM_GRACE"
                    g.group_signal(ACTIVE, signal.SIGKILL)
                time.sleep(0.5)
            code = ACTIVE.wait()
            g.group_signal(ACTIVE, signal.SIGKILL)
        except BaseException:
            if ACTIVE is not None:
                g.group_signal(ACTIVE, signal.SIGKILL)
                ACTIVE.wait()
            row.update(status="ABORTED", end_utc=g.now())
            g.write_json(status_path, row)
            raise
        finally:
            ACTIVE = None
    row.update(status=reason or ("PASS" if code == 0 else "CHECKER_FAILED"),
               exit_code=code, end_utc=g.now(), seconds=round(time.monotonic() - started, 3),
               peak_physical_used_percent=peak, memory_after=g.memory())
    g.write_json(status_path, row)
    return row


def main():
    def interrupted(signum, _frame):
        raise KeyboardInterrupt(f"Received signal {signum}")
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--plan", required=True)
    ap.add_argument("--plan-sha256", required=True)
    ap.add_argument("--run-name", required=True)
    args = ap.parse_args()
    path = Path(args.plan).resolve()
    require(path.is_relative_to(WORK), "Plan must be inside verification workspace")
    require(hashlib.sha256(path.read_bytes()).hexdigest() == args.plan_sha256, "Plan hash mismatch")
    require(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,90}", args.run_name), "Invalid run name")
    plan = read_json(path)
    require(plan["schema"] == "hilbert17-bounded-fresh-checker-plan-v1", "Wrong plan schema")
    require(plan["status"] == "READY_FOR_ROOT_REVIEW", "Plan has pending inputs")
    require(plan["module"] == "BoundaryAcceptance", "Only the reviewed acceptance entry is allowed")
    require(plan["max_wall_seconds"] == 3600, "Changed reviewed one-hour wall bound")
    core = WORK / "guarded_compile03.py"
    require(hashlib.sha256(core.read_bytes()).hexdigest() == CORE_HASH, "Guard core mismatch")
    spec = importlib.util.spec_from_file_location("fresh_checker_guard", core)
    g = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(g)
    require(plan["memory_policy"] == {"sample_seconds": 0.5, "warn_percent": 60,
        "refuse_new_job_at_percent": 60, "term_active_group_at_percent": 70,
        "kill_active_group_at_percent": 75, "term_grace_seconds": 5}, "Memory policy changed")
    require(Path(plan["runner"]["path"]).resolve() == Path(__file__).resolve(), "Runner mismatch")
    # Acquire the same lock before pin validation: a concurrent Lake/Lean job must block launch.
    lock_path = g.validate_write_path(WORK / "verification/runtime-compile.lock", WORK)
    lock = lock_path.open("a")
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    fixed = [plan[k] for k in ("runner", "runtime_config", "checker", "portable_receipt",
                               "artifact_inventory", "source", "main_olean")]
    for pin in fixed:
        g.check_pin(pin)
    runtime = read_json(plan["runtime_config"]["path"])
    require(plan["checker"] == runtime["checker"], "Checker differs from pinned runtime")
    checker = Path(plan["checker"]["path"])
    sysroot = checker.parent.parent
    roots = [str(PORTABLE / ".lake/build/lib/lean")] + [
        str(PORTABLE / ".lake/packages" / package / ".lake/build/lib/lean") for package in PACKAGES]
    builtin = str(sysroot / "lib/lean")
    require(plan["lean_path_roots"] == roots, "Unexpected module search path")
    require(runtime["lean_path_roots"] == roots, "Search roots differ from portable runtime config")
    require(plan["implicit_builtin_root"] == builtin, "Unexpected builtin root")
    require(runtime["implicit_builtin_root"] == builtin, "Builtin root differs from runtime config")
    omitted = PORTABLE / ".lake/packages/Cli/.lake/build/lib/lean"
    require(runtime["omitted_absent_root"] == str(omitted) and not omitted.exists(), "Cli omission changed")
    require(plan["source"]["path"] == str(PORTABLE / "checks/BoundaryAcceptance.lean"), "Unexpected source")
    require(plan["main_olean"]["path"] == str(Path(roots[0]) / "BoundaryAcceptance.olean"), "Unexpected entry artifact")
    receipt = read_json(plan["portable_receipt"]["path"])
    require(receipt["status"] == "ALL_BOUNDED_OFFLINE_LAKE_BUILDS_PASS", "Portable Lake has not passed")
    jobs = [j for j in receipt["jobs"] if j["label"] == "BoundaryAcceptance:olean"]
    require(len(jobs) == 1 and jobs[0]["status"] == "PASS", "Missing portable entry compile")
    require(plan["main_olean"] in jobs[0]["outputs"], "Entry artifact differs from portable receipt")
    inventory = read_json(plan["artifact_inventory"]["path"])
    require(inventory["runtime_config"] == plan["runtime_config"], "Inventory config mismatch")
    require(inventory["build_receipt"] == plan["portable_receipt"], "Inventory build receipt mismatch")
    check_inventory(g, inventory, roots + [builtin])
    run = g.validate_write_path(WORK / "verification" / args.run_name, WORK)
    run.mkdir(parents=True, exist_ok=False)
    for sub in ("home", "tmp"):
        (run / sub).mkdir()
    env = {"PATH": str(checker.parent) + ":/usr/bin:/bin", "HOME": str(run / "home"),
        "TMPDIR": str(run / "tmp"), "LC_ALL": "C.UTF-8", "LEAN_PATH": ":".join(roots),
        "LEAN_SYSROOT": str(sysroot)}
    summary = {"status": "RUNNING", "started_utc": g.now(), "plan": str(path),
        "plan_sha256": args.plan_sha256, "driver_sha256": g.digest(__file__),
        "portable_receipt": plan["portable_receipt"], "artifact_inventory": plan["artifact_inventory"],
        "environment": env, "memory_policy": plan["memory_policy"], "max_wall_seconds": 3600,
        "scope": "Same-kernel fresh replay of all safe, non-partial constants in BoundaryAcceptance and its full imported environment; declared axioms are accepted and audited separately. No external independent verifier or replay of unsafe/partial code is claimed.",
        "jobs": []}
    out = run / "summary.json"
    g.write_json(out, summary)
    try:
        row = run_fresh(g, str(checker), plan["module"], env, run, 3600)
        summary["jobs"].append(row)
        for pin in fixed:
            g.check_pin(pin)
        check_inventory(g, inventory, roots + [builtin])
        summary["status"] = "ALL_IMPORTED_SAFE_CONSTANTS_FRESH_REPLAY_PASS" if row["status"] == "PASS" \
            else "FRESH_REPLAY_INCOMPLETE_OR_FAILED"
        return 0 if row["status"] == "PASS" else 1
    except BaseException as exc:
        summary.update(status="ABORTED_OR_INPUT_DRIFT", error=f"{type(exc).__name__}: {exc}")
        raise
    finally:
        summary["ended_utc"] = g.now()
        g.write_json(out, summary)
        print("SUMMARY", summary["status"], str(out), flush=True)


if __name__ == "__main__":
    raise SystemExit(main())
