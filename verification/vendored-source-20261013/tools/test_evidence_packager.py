#!/usr/bin/env python3
"""Synthetic-only tests. Does not read or package real source/replay runs."""
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("evidence_packager_under_test", ROOT / "package_terminal_run_evidence.py")
P = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(P)


def fixture(base):
    source, replay = base / "source", base / "replay"
    source.mkdir(parents=True)
    replay.mkdir()
    source_summary = {"status": "ALL_FROM_SOURCE_OFFLINE_LAKE_BUILDS_PASS", "ended_utc": "2000-01-01T00:00:00Z",
                      "completed_modules": 3136, "total_modules": 3136}
    replay_summary = {"status": "ALL_IMPORTED_SAFE_CONSTANTS_FRESH_REPLAY_PASS", "ended_utc": "2000-01-01T00:01:00Z"}
    (source / "summary.json").write_bytes(P.canonical_json(source_summary))
    (replay / "summary.json").write_bytes(P.canonical_json(replay_summary))
    for name, content in {
        "completed.jsonl": '{"synthetic":true}\n',
        "attempt-001/failed.stderr.log": "synthetic failed attempt preserved\n",
        "attempt-001/failed.json": '{"status":"COMMAND_FAILED"}\n',
        "attempt-001/interrupted.json.tmp": '{"partial_status":',
        "attempt-001/job.memory.jsonl": '{"used_percent":12.5}\n',
        "attempt-002/passed.stdout.log": "synthetic later pass\n",
        "attempt-002/job.memory.jsonl": '{"used_percent":14.5}\n',
        "partial-before-attempt-002/manifest.json": '[{"synthetic":"artifact metadata only"}]\n',
    }.items():
        path = source / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    compiled = source / "partial-before-attempt-002/vendor/mathlib/.lake/build/lib/lean/Test.olean"
    compiled.parent.mkdir(parents=True)
    compiled.write_bytes(b"\0synthetic compiled data\xff")
    cache = source / "attempt-002/cache/object.bin"
    cache.parent.mkdir()
    cache.write_bytes(b"\0cache")
    (replay / "BoundaryAcceptance-fresh.stdout.log").write_text("synthetic replay\n")
    (replay / "BoundaryAcceptance-fresh.memory.jsonl").write_text('{"used_percent":15.5}\n')
    return source, replay


def reject(call, fragment=None):
    try:
        call()
    except (RuntimeError, UnicodeError) as exc:
        if fragment:
            assert fragment in str(exc), (fragment, str(exc))
        return
    raise AssertionError("Expected rejection did not occur")


def main():
    checks = []
    with tempfile.TemporaryDirectory(prefix="synthetic-evidence-test-", dir=ROOT) as raw:
        base = Path(raw)
        source, replay = fixture(base / "valid")
        one = P.package(source, replay, "source01", "vendor-fresh01", base / "one", 1_000_000)
        # Content is identical; mtime changes must not affect archive bytes.
        for path in source.rglob("*"):
            if path.is_file():
                os.utime(path, (123456789, 123456789))
        two = P.package(source, replay, "source01", "vendor-fresh01", base / "two", 1_000_000)
        assert P.sha256_file(base / "one.tar.gz") == P.sha256_file(base / "two.tar.gz")
        assert (base / "one.members.json").read_bytes() == (base / "two.members.json").read_bytes()
        inventory = json.loads((base / "one.members.json").read_text())
        names = [row["path"] for row in inventory["members"]]
        assert any("failed.stderr.log" in name for name in names)
        assert sum(name.endswith(".memory.jsonl") for name in names) == 3
        assert len(inventory["excluded"]) == 2
        assert not any(name.endswith(".olean") for name in names)
        assert one["extraction_verification"]["status"] == "ALL_MEMBERS_EXTRACTED_AND_SHA256_VERIFIED"
        checks.append({"name": "deterministic_archive_full_extraction_failure_and_sample_preservation", "status": "PASS",
                       "archive_sha256": P.sha256_file(base / "one.tar.gz"), "payload_members": len(names)})

        a, b = fixture(base / "running-source")
        summary = json.loads((a / "summary.json").read_text()); summary["status"] = "RUNNING"
        (a / "summary.json").write_bytes(P.canonical_json(summary))
        reject(lambda: P.collect(a, b, "source01", "vendor-fresh01"), "not terminal")
        checks.append({"name": "running_source_rejected", "status": "PASS"})

        a, b = fixture(base / "running-replay")
        summary = json.loads((b / "summary.json").read_text()); summary["status"] = "RUNNING"
        (b / "summary.json").write_bytes(P.canonical_json(summary))
        reject(lambda: P.collect(a, b, "source01", "vendor-fresh01"), "not terminal")
        checks.append({"name": "running_replay_rejected", "status": "PASS"})

        a, b = fixture(base / "symlink")
        (a / "link.log").symlink_to(a / "summary.json")
        reject(lambda: P.collect(a, b, "source01", "vendor-fresh01"), "Symlink")
        checks.append({"name": "symlink_rejected", "status": "PASS"})

        a, b = fixture(base / "unknown")
        (a / "unknown.bin").write_bytes(b"binary")
        reject(lambda: P.collect(a, b, "source01", "vendor-fresh01"), "Unrecognized")
        checks.append({"name": "unclassified_file_rejected", "status": "PASS"})

        a, b = fixture(base / "binary-log")
        (a / "pretend.log").write_bytes(b"not text\0")
        reject(lambda: P.collect(a, b, "source01", "vendor-fresh01"), "Binary/NUL")
        checks.append({"name": "binary_disguised_as_log_rejected", "status": "PASS"})

        bad_archive = base / "unsafe.tar.gz"
        with tarfile.open(bad_archive, "w:gz") as archive:
            info = P.tar_info("../escape.txt", 1)
            archive.addfile(info, io.BytesIO(b"x"))
        reject(lambda: P.verify_extraction(bad_archive, (base / "one.members.json").read_bytes(), base), "Unsafe")
        checks.append({"name": "unsafe_archive_member_rejected", "status": "PASS"})

        a, b = fixture(base / "drift")
        original = P.write_archive
        def drift(path, files, inventory_bytes):
            original(path, files, inventory_bytes)
            with (a / "attempt-001/failed.stderr.log").open("a") as stream:
                stream.write("post-read synthetic drift\n")
        P.write_archive = drift
        try:
            reject(lambda: P.package(a, b, "source01", "vendor-fresh01", base / "drift-pack", 1_000_000), "changed during packaging")
        finally:
            P.write_archive = original
        assert (base / "drift-pack.tar.gz.partial").exists()
        assert not (base / "drift-pack.tar.gz").exists()
        checks.append({"name": "concurrent_evidence_drift_rejected_partial_preserved", "status": "PASS"})

        a, b = fixture(base / "cli")
        shared_lock = base / "synthetic-shared.lock"
        shared_lock.touch()
        source_plan = base / "synthetic-source-plan.json"
        source_plan.write_bytes(P.canonical_json({"shared_lock": str(shared_lock)}))
        summary = json.loads((a / "summary.json").read_text())
        summary.update(plan=str(source_plan), plan_sha256=P.sha256_file(source_plan))
        (a / "summary.json").write_bytes(P.canonical_json(summary))
        replay_summary = json.loads((b / "summary.json").read_text())
        replay_summary["source_build"] = {"path": str(a / "summary.json"), **P.file_record(a / "summary.json")}
        (b / "summary.json").write_bytes(P.canonical_json(replay_summary))
        command = [sys.executable, str(ROOT / "package_terminal_run_evidence.py"), "--source-run", str(a),
                   "--replay-run", str(b), "--shared-lock", str(shared_lock), "--output-prefix", str(base / "cli-pack")]
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        assert json.loads(result.stdout)["status"] == "PACKAGE_VERIFIED"
        checks.append({"name": "synthetic_cli_lock_and_receipt_binding", "status": "PASS"})

    report = {"schema": "hilbert17-evidence-packager-synthetic-tests-v1", "status": "ALL_SYNTHETIC_TESTS_PASS",
              "checks": checks, "real_run_logs_packaged": False, "lean_lake_execution": "NONE",
              "packager": {"path": str(ROOT / "package_terminal_run_evidence.py"), **P.file_record(ROOT / "package_terminal_run_evidence.py")},
              "test_script": {"path": str(Path(__file__).resolve()), **P.file_record(__file__)}}
    output = ROOT / "evidence-packager-synthetic-tests01.json"
    output.write_bytes(P.canonical_json(report))
    print(json.dumps({"status": report["status"], "checks": len(checks), "report": str(output)}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
