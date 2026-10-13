#!/usr/bin/env python3
"""Deterministic, verified log-only archive of terminal source/replay runs.

This script never executes Lean/Lake or changes run evidence. It requires both
run summaries to be terminal and holds the build/replay shared lock throughout.
"""
import argparse
import codecs
import datetime
import fcntl
import gzip
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import sys
import tarfile
import tempfile
import zlib

EPHEMERAL_PARTS = {"home", "tmp", "cache", "xdg", "__pycache__"}
TEXT_SUFFIXES = {".json", ".jsonl", ".log", ".txt", ".md", ".csv", ".sha256"}
COMPILED_SUFFIXES = (".olean", ".olean.private", ".olean.server", ".ilean", ".ir",
                     ".o", ".obj", ".a", ".so", ".dll", ".dylib", ".exe", ".bc", ".c", ".cpp")
SOURCE_TERMINAL = {"ALL_FROM_SOURCE_OFFLINE_LAKE_BUILDS_PASS", "STOPPED_DEPENDENCY_CHECK_OR_RESOURCE_LIMIT",
                   "STOPPED_BUILD_FAILURE_OR_RESOURCE_LIMIT", "STOPPED_AGGREGATE_CHECK_FAILURE", "ABORTED", "INPUT_PIN_CHANGED"}
REPLAY_TERMINAL = {"ALL_IMPORTED_SAFE_CONSTANTS_FRESH_REPLAY_PASS", "STOPPED_ENVIRONMENT_PROBE_OR_RESOURCE_LIMIT",
                   "FRESH_REPLAY_INCOMPLETE_OR_FAILED", "ABORTED_OR_INPUT_DRIFT", "INPUT_OR_ARTIFACT_CHANGED"}


def require(ok, message):
    if not ok:
        raise RuntimeError(message)


def canonical_json(value):
    return (json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n").encode("utf-8")


def sha256_file(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def file_record(path):
    path = Path(path)
    return {"bytes": path.stat().st_size, "sha256": sha256_file(path)}


def safe_member(name):
    path = PurePosixPath(name)
    require(not any(ord(character) < 32 for character in name), "Control character in archive member")
    require(not path.is_absolute() and path.parts and ".." not in path.parts and "." not in path.parts,
            "Unsafe archive member: " + name)
    require("\\" not in name and ":" not in name and str(path) == name, "Nonportable archive member: " + name)
    return path


def verify_utf8(path):
    decoder = codecs.getincrementaldecoder("utf-8")("strict")
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            require(b"\0" not in block, "Binary/NUL content in evidence log: " + str(path))
            decoder.decode(block)
    decoder.decode(b"", final=True)


def terminal_summary(root, role):
    require(root.is_dir() and not root.is_symlink(), "Run directory missing or symlinked")
    path = root / "summary.json"
    summary = json.loads(path.read_text(encoding="utf-8"))
    allowed = SOURCE_TERMINAL if role == "source" else REPLAY_TERMINAL
    require(summary.get("status") in allowed and summary.get("ended_utc"),
            f"{role} run is not terminal; packaging refused")
    if role == "source" and summary["status"] == "ALL_FROM_SOURCE_OFFLINE_LAKE_BUILDS_PASS":
        require(summary.get("completed_modules") == summary.get("total_modules") == 3136,
                "Source PASS receipt lacks complete module count")
    return summary


def collect_run(root, label, role):
    require(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,90}", label), "Invalid run label")
    summary = terminal_summary(root, role)
    included, excluded = [], []
    for folder, dirs, files in os.walk(root, followlinks=False):
        dirs.sort()
        files.sort()
        for name in dirs + files:
            p = Path(folder) / name
            require(not p.is_symlink(), "Symlink in run evidence: " + str(p))
        for name in files:
            p = Path(folder) / name
            require(p.is_file(), "Non-regular run evidence file: " + str(p))
            rel = p.relative_to(root)
            member = label + "/" + rel.as_posix()
            safe_member(member)
            reason = None
            if any(part in EPHEMERAL_PARTS for part in rel.parts[:-1]):
                reason = "isolated home/temp/cache/config contents; not command logs"
            elif ".lake" in rel.parts and "build" in rel.parts:
                reason = "quarantined build artifact or artifact sidecar"
            elif name.endswith(COMPILED_SUFFIXES):
                reason = "compiled artifact, excluded from log-only archive"
            if reason:
                excluded.append({"path": member, "bytes": p.stat().st_size, "reason": reason})
                continue
            recognized = p.suffix in TEXT_SUFFIXES or any(name.endswith(suffix + ".tmp") for suffix in TEXT_SUFFIXES)
            require(recognized, "Unrecognized evidence file; review before packaging: " + str(p))
            verify_utf8(p)
            included.append({"path": member, **file_record(p), "source_path": p})
    require(any(row["path"] == label + "/summary.json" for row in included), "Run summary not included")
    return included, excluded, {"label": label, "role": role, "status": summary["status"],
                               "summary": {"path": label + "/summary.json", **file_record(root / "summary.json")}}


def collect(source, replay, source_label, replay_label):
    require(source_label != replay_label, "Run labels must differ")
    a, ax, ar = collect_run(source, source_label, "source")
    b, bx, br = collect_run(replay, replay_label, "replay")
    files = sorted(a + b, key=lambda row: row["path"])
    require(len({row["path"] for row in files}) == len(files), "Duplicate member names")
    inventory = {"schema": "hilbert17-terminal-run-log-inventory-v1",
                 "scope": "Complete preserved source/replay command logs, statuses, failure attempts, memory samples, journals, and input-verification receipts. No compiled artifacts or isolated home/temp/cache/config contents.",
                 "determinism": "Sorted POSIX member names; tar regular-file mode0644, uid/gid0, empty owner names, mtime0; gzip filename empty, mtime0, compression9",
                 "runs": [ar, br], "member_count": len(files), "uncompressed_payload_bytes": sum(row["bytes"] for row in files),
                 "members": [{key: row[key] for key in ["path", "bytes", "sha256"]} for row in files],
                 "excluded": sorted(ax + bx, key=lambda row: row["path"])}
    return files, inventory


def tar_info(name, size):
    info = tarfile.TarInfo(name)
    info.size = size
    info.mode = 0o644
    info.uid = info.gid = 0
    info.uname = info.gname = ""
    info.mtime = 0
    info.pax_headers = {}
    return info


def write_archive(path, files, inventory_bytes):
    all_members = [(row["path"], row) for row in files] + [("MANIFEST.json", None)]
    with Path(path).open("xb") as raw:
        with gzip.GzipFile(filename="", mode="wb", compresslevel=9, fileobj=raw, mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w", format=tarfile.PAX_FORMAT) as archive:
                for name, row in sorted(all_members):
                    if row is None:
                        archive.addfile(tar_info(name, len(inventory_bytes)), io.BytesIO(inventory_bytes))
                    else:
                        with row["source_path"].open("rb") as stream:
                            archive.addfile(tar_info(name, row["bytes"]), stream)
        raw.flush()
        os.fsync(raw.fileno())


def verify_extraction(archive_path, inventory_bytes, output_parent):
    inventory = json.loads(inventory_bytes)
    expected = {row["path"]: row for row in inventory["members"]}
    expected["MANIFEST.json"] = {"path": "MANIFEST.json", "bytes": len(inventory_bytes),
                                 "sha256": hashlib.sha256(inventory_bytes).hexdigest()}
    seen = set()
    total = 0
    # Manual safe extraction avoids applying arbitrary tar metadata or symlinks.
    with tempfile.TemporaryDirectory(prefix="evidence-extract-verify-", dir=output_parent) as temp:
        root = Path(temp)
        with tarfile.open(archive_path, "r:gz") as archive:
            for member in archive:
                rel = safe_member(member.name)
                require(member.name in expected and member.name not in seen, "Unexpected/duplicate tar member")
                require(member.isfile() and not member.issym() and not member.islnk(), "Non-regular tar member")
                require(member.mode == 0o644 and member.uid == member.gid == 0 and member.mtime == 0
                        and member.uname == member.gname == "", "Nondeterministic tar metadata")
                record = expected[member.name]
                require(member.size == record["bytes"], "Member size mismatch")
                destination = root.joinpath(*rel.parts)
                destination.parent.mkdir(parents=True, exist_ok=True)
                stream = archive.extractfile(member)
                require(stream is not None, "Missing member content")
                with stream, destination.open("xb") as output:
                    shutil.copyfileobj(stream, output, length=1024 * 1024)
                require(file_record(destination) == {"bytes": record["bytes"], "sha256": record["sha256"]},
                        "Extracted member hash mismatch: " + member.name)
                total += member.size
                seen.add(member.name)
        require(seen == set(expected), "Archive omitted an inventoried member")
        require((root / "MANIFEST.json").read_bytes() == inventory_bytes, "Embedded and sidecar inventories differ")
    return {"status": "ALL_MEMBERS_EXTRACTED_AND_SHA256_VERIFIED", "verified_members_including_manifest": len(seen),
            "verified_uncompressed_bytes_including_manifest": total, "verification_directory_removed": True}


def package(source, replay, source_label, replay_label, output_prefix, max_bytes):
    prefix = Path(output_prefix).resolve()
    source, replay = source.resolve(strict=True), replay.resolve(strict=True)
    require(not prefix.is_relative_to(source) and not prefix.is_relative_to(replay), "Output must not be inside run evidence")
    outputs = {"archive": Path(str(prefix) + ".tar.gz"), "inventory": Path(str(prefix) + ".members.json"),
               "sha256_inventory": Path(str(prefix) + ".members.sha256"), "verification": Path(str(prefix) + ".verification.json")}
    require(all(not path.exists() for path in outputs.values()), "Refusing to overwrite evidence-package outputs")
    prefix.parent.mkdir(parents=True, exist_ok=True)
    files, inventory = collect(source, replay, source_label, replay_label)
    inventory_bytes = canonical_json(inventory)
    # Failed packaging leaves partial output clearly named and never deletes logs.
    pending = Path(str(outputs["archive"]) + ".partial")
    require(not pending.exists(), "Prior partial archive exists; preserve/review it before retry")
    write_archive(pending, files, inventory_bytes)
    require(pending.stat().st_size <= max_bytes, "Compressed evidence exceeds configured Git-blob size budget")
    extraction = verify_extraction(pending, inventory_bytes, prefix.parent)
    # Re-read run terminal summaries, file membership and every included byte hash.
    after_files, after_inventory = collect(source, replay, source_label, replay_label)
    require(canonical_json(after_inventory) == inventory_bytes, "Run evidence changed during packaging")
    os.replace(pending, outputs["archive"])
    outputs["inventory"].write_bytes(inventory_bytes)
    manifest_hash = hashlib.sha256(inventory_bytes).hexdigest()
    checksums = [("MANIFEST.json", manifest_hash)] + [(row["path"], row["sha256"]) for row in inventory["members"]]
    outputs["sha256_inventory"].write_text("".join(digest + "  " + name + "\n" for name, digest in sorted(checksums)), encoding="utf-8")
    report = {"schema": "hilbert17-terminal-run-evidence-package-verification-v1", "status": "PACKAGE_VERIFIED",
              "scope": inventory["scope"], "runs": inventory["runs"], "payload_members": inventory["member_count"],
              "excluded_file_count": len(inventory["excluded"]), "extraction_verification": extraction,
              "inputs_unchanged_after_packaging": True, "compiled_artifacts_included": False,
              "outputs": {key: {"path": str(path), **file_record(path)} for key, path in outputs.items() if key != "verification"},
              "packager": {"path": str(Path(__file__).resolve()), **file_record(__file__)},
              "reproducibility_runtime": {"python": sys.version, "zlib_compile": zlib.ZLIB_VERSION, "zlib_runtime": zlib.ZLIB_RUNTIME_VERSION},
              "max_archive_bytes": max_bytes, "verified_utc": datetime.datetime.now(datetime.timezone.utc).isoformat()}
    outputs["verification"].write_bytes(canonical_json(report))
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-run", required=True)
    parser.add_argument("--replay-run", required=True)
    parser.add_argument("--source-label", default="source01")
    parser.add_argument("--replay-label", default="vendor-fresh01")
    parser.add_argument("--shared-lock", required=True)
    parser.add_argument("--output-prefix", required=True)
    parser.add_argument("--max-archive-bytes", type=int, default=90_000_000)
    args = parser.parse_args()
    require(0 < args.max_archive_bytes <= 100_000_000, "Git evidence-file budget must be between1 and100000000 bytes")
    source, replay = Path(args.source_run).resolve(strict=True), Path(args.replay_run).resolve(strict=True)
    lock = Path(args.shared_lock).open("a")
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    source_summary = terminal_summary(source, "source")
    replay_summary = terminal_summary(replay, "replay")
    source_plan = json.loads(Path(source_summary["plan"]).read_text(encoding="utf-8"))
    require(sha256_file(source_summary["plan"]) == source_summary["plan_sha256"], "Source plan pin mismatch")
    require(Path(args.shared_lock).resolve() == Path(source_plan["shared_lock"]).resolve(), "Wrong shared compiler lock")
    # The replay receipt must identify this exact completed source receipt.
    require(replay_summary["source_build"] == {"path": str(source / "summary.json"), **file_record(source / "summary.json")},
            "Replay log is not bound to the selected source run")
    report = package(source, replay, args.source_label, args.replay_label,
                     args.output_prefix, args.max_archive_bytes)
    print(json.dumps({"status": report["status"], "outputs": report["outputs"],
                      "verification": str(Path(str(Path(args.output_prefix).resolve()) + ".verification.json")),
                      "payload_members": report["payload_members"],
                      "extraction_verification": report["extraction_verification"]}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
