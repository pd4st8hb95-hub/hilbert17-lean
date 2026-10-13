#!/usr/bin/env python3
"""Reviewed serial guard functions; 4096 MiB Lean cap authorized by root after smoke run02.
Derived from compile_runtime02.py SHA256 9e57184bd28de12bbce0098af16ec6b77cfc1fef3829f788bbecccd008b0e871.
Only the per-process Lean cap changes; physical-memory policy and cleanup are unchanged.
This module has no command-line launch code.
"""
import argparse
import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

WORK = Path(__file__).resolve().parent
PLAN_HASH = "e8dc68dd00bf2d3140539030c2cb70c8d33dcd19866e2c308ef3a398d0d72bd5"
CONFIG_HASH = "3bde5c1383cb89247df7fdc91421add93df0869f37fa5886d539caf964905c3b"
WARN, REFUSE, TERM, KILL, GRACE = 60.0, 60.0, 70.0, 75.0, 5.0
ACTIVE = None


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_pin(pin):
    p = Path(pin["path"])
    if p.stat().st_size != pin["bytes"] or digest(p) != pin["sha256"]:
        raise RuntimeError(f"Pinned input mismatch: {p}")


def write_json(path, value):
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(value, indent=2) + "\n")
    os.replace(tmp, path)


def memory():
    values = {}
    for line in Path("/proc/meminfo").read_text().splitlines():
        key, value = line.split(":", 1)
        if key in ("MemTotal", "MemAvailable"):
            values[key] = int(value.split()[0])
    total, available = values["MemTotal"], values["MemAvailable"]
    if not 0 < available <= total:
        raise RuntimeError("Invalid physical-memory sample")
    return {"utc": now(), "total_kib": total, "available_kib": available,
            "used_percent": 100.0 * (total - available) / total}


def group_signal(proc, sig):
    try:
        os.killpg(proc.pid, sig)
    except ProcessLookupError:
        pass


def validate_write_path(path, boundary):
    path = Path(path)
    if not path.resolve().is_relative_to(boundary.resolve()):
        raise RuntimeError(f"Write escapes isolated boundary: {path}")
    for p in (path, *path.parents):
        if p == WORK:
            break
        if p.is_symlink():
            raise RuntimeError(f"Output symlink refused: {p}")
    return path


def safe_output(path, overlay):
    path = validate_write_path(path, overlay)
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def run_job(label, pin, root, output, compiler, env, run, ordinal, overlay):
    global ACTIVE
    check_pin(pin)
    before = memory()
    prefix = run / f"{ordinal:02d}-{label.replace('.', '_')}"
    row = {"label": label, "source": pin, "start_utc": now(),
           "memory_before": before, "status": "PREPARING"}
    status_path = prefix.with_suffix(".json")
    if before["used_percent"] >= REFUSE:
        row["status"] = "REFUSED_MEMORY_AT_OR_ABOVE_60_PERCENT"
        write_json(status_path, row)
        print(json.dumps(row), flush=True)
        return row
    output = safe_output(output, overlay)
    ilean = safe_output(output.with_suffix(".ilean"), overlay)
    for suffix in (".olean.private", ".olean.server", ".ir"):
        validate_write_path(output.with_suffix(suffix), overlay)
    command = [compiler, "-j", "1", "-M", "4096", "-R", str(root),
               "-o", str(output), "-i", str(ilean), pin["path"]]
    row.update(command=command, status="RUNNING", stdout=str(prefix.with_suffix(".stdout.log")),
               stderr=str(prefix.with_suffix(".stderr.log")))
    write_json(status_path, row)
    print(f"START {ordinal:02d} {label}", flush=True)
    started, term_at, reason, warned = time.monotonic(), None, None, False
    peak = before["used_percent"]
    with open(row["stdout"], "wb") as out, open(row["stderr"], "wb") as err, \
            prefix.with_suffix(".memory.jsonl").open("w") as samples:
        try:
            ACTIVE = subprocess.Popen(command, cwd=WORK, env=env, stdin=subprocess.DEVNULL,
                                      stdout=out, stderr=err, start_new_session=True)
            row["pid"] = ACTIVE.pid
            write_json(status_path, row)
            while ACTIVE.poll() is None:
                sample = memory()
                used = sample["used_percent"]
                peak = max(peak, used)
                samples.write(json.dumps(sample) + "\n")
                samples.flush()
                if used >= WARN and not warned:
                    print(f"MEMORY WARNING {used:.2f}% during {label}", flush=True)
                    warned = True
                if used >= KILL:
                    reason = "KILLED_MEMORY_AT_OR_ABOVE_75_PERCENT"
                    group_signal(ACTIVE, signal.SIGKILL)
                elif term_at is None and used >= TERM:
                    reason, term_at = "TERMINATED_MEMORY_AT_OR_ABOVE_70_PERCENT", time.monotonic()
                    group_signal(ACTIVE, signal.SIGTERM)
                elif term_at is not None and time.monotonic() - term_at >= GRACE:
                    reason = "KILLED_AFTER_5_SECOND_TERM_GRACE"
                    group_signal(ACTIVE, signal.SIGKILL)
                time.sleep(0.5)
            exit_code = ACTIVE.wait()
        except BaseException:
            if ACTIVE is not None:
                group_signal(ACTIVE, signal.SIGKILL)
                ACTIVE.wait()
            row.update(status="ABORTED", end_utc=now())
            write_json(status_path, row)
            raise
        finally:
            ACTIVE = None
    row.update(exit_code=exit_code, seconds=round(time.monotonic() - started, 3),
               end_utc=now(), peak_physical_used_percent=peak, memory_after=memory())
    check_pin(pin)
    row["status"] = reason or ("PASS" if exit_code == 0 and output.is_file() else "COMPILE_FAILED")
    row["outputs"] = []
    for suffix in (".olean", ".olean.private", ".olean.server", ".ilean", ".ir"):
        p = output.with_suffix(suffix)
        if p.is_file():
            row["outputs"].append({"path": str(p), "bytes": p.stat().st_size, "sha256": digest(p)})
    write_json(status_path, row)
    print(f"{row['status']} {ordinal:02d} {label} ({row['seconds']} s)", flush=True)
    return row


