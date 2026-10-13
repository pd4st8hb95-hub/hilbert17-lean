#!/usr/bin/env python3
"""Replay explicitly pinned local Lean modules serially, without --fresh."""
import argparse
import fcntl
import hashlib
import importlib.util
import json
from pathlib import Path
import signal
import subprocess
import sys
import time

WORK = Path(__file__).resolve().parent
CORE_HASH = "390d24bf21a2e13874c631965503c69d7d2bc62c0f2298c63fb776e93bd4a9ee"


def check_one(g, item, checker, env, run, ordinal):
    for pin in [item["source"], *item["artifacts"]]:
        g.check_pin(pin)
    prefix = run / f"{ordinal:02d}-{item['module']}"
    status_path = prefix.with_suffix(".json")
    before = g.memory()
    row = {"module": item["module"], "start_utc": g.now(), "memory_before": before,
           "command": [checker, "-v", item["module"]], "status": "PREPARING",
           "source": item["source"], "artifacts": item["artifacts"]}
    if before["used_percent"] >= g.REFUSE:
        row["status"] = "REFUSED_MEMORY_AT_OR_ABOVE_60_PERCENT"
        g.write_json(status_path, row)
        return row
    row.update(status="RUNNING", stdout=str(prefix.with_suffix(".stdout.log")),
               stderr=str(prefix.with_suffix(".stderr.log")))
    g.write_json(status_path, row)
    print(f"START CHECKER {item['module']}", flush=True)
    proc, term_at, reason, warned = None, None, None, False
    started, peak = time.monotonic(), before["used_percent"]
    with open(row["stdout"], "wb") as out, open(row["stderr"], "wb") as err, \
            prefix.with_suffix(".memory.jsonl").open("w") as samples:
        try:
            proc = subprocess.Popen(row["command"], cwd=WORK, env=env, stdin=subprocess.DEVNULL,
                                    stdout=out, stderr=err, start_new_session=True)
            row["pid"] = proc.pid
            g.write_json(status_path, row)
            while proc.poll() is None:
                sample = g.memory()
                used = sample["used_percent"]
                peak = max(peak, used)
                samples.write(json.dumps(sample) + "\n")
                samples.flush()
                if used >= g.WARN and not warned:
                    print(f"MEMORY WARNING {used:.2f}% during {item['module']}", flush=True)
                    warned = True
                if used >= g.KILL:
                    reason = "KILLED_MEMORY_AT_OR_ABOVE_75_PERCENT"
                    g.group_signal(proc, signal.SIGKILL)
                elif term_at is None and used >= g.TERM:
                    reason, term_at = "TERMINATED_MEMORY_AT_OR_ABOVE_70_PERCENT", time.monotonic()
                    g.group_signal(proc, signal.SIGTERM)
                elif term_at is not None and time.monotonic() - term_at >= g.GRACE:
                    reason = "KILLED_AFTER_5_SECOND_TERM_GRACE"
                    g.group_signal(proc, signal.SIGKILL)
                time.sleep(0.5)
            exit_code = proc.wait()
        except BaseException:
            if proc is not None:
                g.group_signal(proc, signal.SIGKILL)
                proc.wait()
            row.update(status="ABORTED", end_utc=g.now())
            g.write_json(status_path, row)
            raise
    for pin in [item["source"], *item["artifacts"]]:
        g.check_pin(pin)
    row.update(status=reason or ("PASS" if exit_code == 0 else "CHECKER_FAILED"),
               exit_code=exit_code, seconds=round(time.monotonic() - started, 3), end_utc=g.now(),
               peak_physical_used_percent=peak, memory_after=g.memory())
    g.write_json(status_path, row)
    print(f"{row['status']} CHECKER {item['module']} ({row['seconds']} s)", flush=True)
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plan", required=True)
    parser.add_argument("--plan-sha256", required=True)
    parser.add_argument("--run-name", required=True)
    args = parser.parse_args()
    plan_path = Path(args.plan).resolve()
    if not plan_path.is_relative_to(WORK) or hashlib.sha256(plan_path.read_bytes()).hexdigest() != args.plan_sha256:
        parser.error("Frozen workspace plan mismatch")
    if Path(args.run_name).name != args.run_name or args.run_name in ("", ".", ".."):
        parser.error("Run name must be a fresh single directory name")
    core = WORK / "guarded_compile03.py"
    if hashlib.sha256(core.read_bytes()).hexdigest() != CORE_HASH:
        parser.error("Reviewed guard-helper source mismatch")
    spec = importlib.util.spec_from_file_location("hilbert17_checker_guard", core)
    g = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(g)
    signal.signal(signal.SIGTERM, lambda signum, frame: (_ for _ in ()).throw(KeyboardInterrupt("SIGTERM")))
    plan = json.loads(plan_path.read_text())
    if plan["schema"] != "hilbert17-local-checker-plan-v1":
        raise RuntimeError("Unsupported checker plan")
    g.check_pin(plan["config"])
    config = json.loads(Path(plan["config"]["path"]).read_text())
    g.check_pin(config["checker"])
    project = WORK / ".lake/build/lib/lean"
    for item in plan["modules"]:
        module = item["module"]
        if not all(part.isidentifier() for part in module.split(".")) or module.split(".")[0] in ("Mathlib", "Lean", "Init", "Std"):
            raise RuntimeError("Only an explicit local module basename is allowed")
        relative_module = Path(*module.split("."))
        main_olean = project / relative_module.with_suffix(".olean")
        if str(main_olean) not in [p["path"] for p in item["artifacts"]]:
            raise RuntimeError("Missing pinned local main .olean")
        for pin in item["artifacts"]:
            p = Path(pin["path"])
            if p.parent != main_olean.parent or p.name not in [relative_module.name + s for s in (".olean", ".olean.private", ".olean.server", ".ir", ".ilean")]:
                raise RuntimeError("Unexpected local artifact path")
            g.check_pin(pin)
        if (project / relative_module).exists():
            raise RuntimeError("Refusing a module with descendants because checker uses prefix matching")
        g.check_pin(item["source"])
    run = WORK / "verification" / args.run_name
    g.validate_write_path(run, WORK)
    g.validate_write_path(WORK / "verification/runtime-compile.lock", WORK)
    run.mkdir(parents=True, exist_ok=False)
    lock = (WORK / "verification/runtime-compile.lock").open("a")
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    for sub in ("home", "tmp"):
        (run / sub).mkdir()
    env = {"PATH": str(Path(config["checker"]["path"]).parent) + ":/usr/bin:/bin",
           "HOME": str(run / "home"), "TMPDIR": str(run / "tmp"), "LC_ALL": "C.UTF-8",
           "LEAN_PATH": ":".join(config["lean_path_roots"])}
    summary = {"status": "RUNNING", "started_utc": g.now(), "driver_sha256": g.digest(__file__),
               "plan_sha256": args.plan_sha256, "guard_core_sha256": CORE_HASH,
               "memory_policy": plan["memory_policy"], "environment": env, "jobs": [],
               "scope": "Same-kernel replay of selected local modules against imported dependencies; no full transitive replay, no independent external verifier, and no theorem-strength or axiom-list acceptance."}
    summary_path = run / "summary.json"
    g.write_json(summary_path, summary)
    try:
        for ordinal, item in enumerate(plan["modules"], 1):
            result = check_one(g, item, config["checker"]["path"], env, run, ordinal)
            summary["jobs"].append(result)
            g.write_json(summary_path, summary)
            if result["status"] != "PASS":
                summary["status"] = "STOPPED_ON_FIRST_FAILURE_OR_MEMORY_LIMIT"
                return 1
        summary["status"] = "ALL_SELECTED_LOCAL_REPLAYS_PASS"
        return 0
    except BaseException as exc:
        summary.update(status="ABORTED", error=f"{type(exc).__name__}: {exc}")
        raise
    finally:
        summary["ended_utc"] = g.now()
        g.write_json(summary_path, summary)
        print(f"SUMMARY {summary['status']} {summary_path}", flush=True)


if __name__ == "__main__":
    sys.exit(main())
