#!/usr/bin/env python3
"""Compile an explicitly hashed Hilbert17 source plan using the reviewed serial guard."""
import argparse
import fcntl
import hashlib
import importlib.util
import json
from pathlib import Path
import signal
import sys

WORK = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plan", required=True)
    parser.add_argument("--plan-sha256", required=True)
    parser.add_argument("--run-name", required=True)
    args = parser.parse_args()
    plan_path = Path(args.plan).resolve()
    if not plan_path.is_relative_to(WORK):
        parser.error("Plan must be inside this workspace")
    if hashlib.sha256(plan_path.read_bytes()).hexdigest() != args.plan_sha256:
        parser.error("Frozen plan SHA256 mismatch")
    if Path(args.run_name).name != args.run_name or args.run_name in ("", ".", ".."):
        parser.error("Run name must be one new directory name")
    plan = json.loads(plan_path.read_text())
    if plan["schema"] != "hilbert17-frozen-compile-plan-v1" or plan["lean_memory_limit_mib"] != 4096:
        parser.error("Unsupported plan schema or Lean memory cap")
    core = WORK / "guarded_compile03.py"
    if str(core) != plan["guard_core"]["path"] or hashlib.sha256(core.read_bytes()).hexdigest() != plan["guard_core"]["sha256"]:
        parser.error("Reviewed guard core mismatch")
    spec = importlib.util.spec_from_file_location("hilbert17_guarded_compile03", core)
    guard = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(guard)
    signal.signal(signal.SIGTERM, lambda signum, frame: (_ for _ in ()).throw(KeyboardInterrupt("SIGTERM")))
    config_path = WORK / "local-runtime.json"
    if str(config_path) != plan["config"]["path"]:
        raise RuntimeError("Unexpected runtime config path")
    guard.check_pin(plan["config"])
    config = json.loads(config_path.read_text())
    for pin in [config["compiler"], *config["version_controls"]]:
        guard.check_pin(pin)
    if plan.get("require_prerequisite12_pass"):
        evidence = json.loads(Path(plan["prerequisite_evidence"]).read_text())
        base = json.loads((WORK / "runtime-plan02.json").read_text())
        needed = [r["module"] for r in base["missing_modules_in_compile_order"]]
        if [r["label"] for r in evidence["jobs"][:12]] != needed or any(r["status"] != "PASS" for r in evidence["jobs"][:12]):
            raise RuntimeError("Prerequisite evidence does not show all twelve official modules passing")
    overlay = WORK / "runtime-overlay"
    project_output = WORK / ".lake/build/lib/lean"
    mathlib = Path(config["immutable_reuse_root"]) / "mathlib"
    for job in plan["jobs"]:
        module = Path(*job["module"].split("."))
        root = Path(job["source_root"])
        source = Path(job["source"]["path"])
        if not source.is_relative_to(WORK.parent) or source != root / module.with_suffix(".lean"):
            raise RuntimeError(f"Source-root/module mismatch: {source}")
        if job["kind"] == "official":
            if root != mathlib:
                raise RuntimeError("Official source must use pinned mathlib root")
            expected = overlay / "lib/lean" / module.with_suffix(".olean")
        elif job["kind"] == "project":
            if not root.is_relative_to(WORK.parent) or not root.parts[len(WORK.parent.parts)].startswith("hilbert17"):
                raise RuntimeError("Project source root is not a Hilbert17 workspace")
            expected = project_output / module.with_suffix(".olean")
        elif job["kind"] == "smoke":
            if root != WORK / "checks":
                raise RuntimeError("Smoke source must use workspace checks root")
            expected = overlay / "smoke" / module.with_suffix(".olean")
        else:
            raise RuntimeError("Unsupported job kind")
        if Path(job["olean_output"]) != expected:
            raise RuntimeError("Output destination does not match module and job kind")
        guard.validate_write_path(expected, WORK)
        guard.check_pin(job["source"])
    run = WORK / "verification" / args.run_name
    guard.validate_write_path(run, WORK)
    guard.validate_write_path(WORK / "verification/runtime-compile.lock", WORK)
    run.mkdir(parents=True, exist_ok=False)
    lock = (WORK / "verification/runtime-compile.lock").open("a")
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    for sub in ("home", "tmp"):
        (run / sub).mkdir()
    project_output.mkdir(parents=True, exist_ok=True)
    env = {"PATH": str(Path(config["compiler"]["path"]).parent) + ":/usr/bin:/bin",
           "HOME": str(run / "home"), "TMPDIR": str(run / "tmp"), "LC_ALL": "C.UTF-8",
           "LEAN_PATH": ":".join(config["lean_path_roots"]), "MATHLIB_NO_CACHE_ON_UPDATE": "1"}
    summary = {"status": "RUNNING", "started_utc": guard.now(), "driver_sha256": guard.digest(__file__),
               "plan": str(plan_path), "plan_sha256": args.plan_sha256, "guard_core": plan["guard_core"],
               "lean_memory_limit_mib": 4096, "memory_policy": plan["memory_policy"],
               "environment": env, "scope": plan["scope"], "jobs": []}
    status_path = run / "summary.json"
    guard.write_json(status_path, summary)
    try:
        for ordinal, job in enumerate(plan["jobs"], 1):
            # The frozen official dependencies must not resolve project-created namespaces.
            job_env = dict(env)
            if job["kind"] == "official":
                job_env["LEAN_PATH"] = ":".join(config["lean_path_roots"][1:])
            result = guard.run_job(job["module"], job["source"], Path(job["source_root"]),
                                   job["olean_output"], config["compiler"]["path"], job_env,
                                   run, ordinal, WORK)
            summary["jobs"].append(result)
            guard.write_json(status_path, summary)
            if result["status"] != "PASS":
                summary["status"] = "STOPPED_ON_FIRST_FAILURE_OR_MEMORY_LIMIT"
                return 1
        summary["status"] = "ALL_PLANNED_COMPILES_PASS"
        return 0
    except BaseException as exc:
        summary.update(status="ABORTED", error=f"{type(exc).__name__}: {exc}")
        raise
    finally:
        summary["ended_utc"] = guard.now()
        guard.write_json(status_path, summary)
        print(f"SUMMARY {summary['status']} {status_path}", flush=True)


if __name__ == "__main__":
    sys.exit(main())
