# Independent static review: terminal-run evidence packager

Date: 2026-10-13 UTC

**Result: PASS FOR TERMINAL-RUN PACKAGING. No blocking defect found.**

Reviewed `package_terminal_run_evidence.py`, SHA256
`443ed8575f92c64c06f62ed2cfc452a8ba1a45e1a72b3b96afd88923e02bbffa`,
and `test_evidence_packager.py`, SHA256
`a0785398f00ed8c80c5a2a0f7c73ce837095114fdff74eb4f446b91b2731fc1f`.
Both current hashes match `evidence-packager-synthetic-tests01.json`.

This was an independent source review. The nine reported synthetic tests and
their test implementation were inspected, not rerun. No actual run logs were
read or packaged, no frozen inputs were changed, and no Lean/Lake command was
executed. Actual archive creation and verification remain the parent's later
terminal-run operation.

## Findings

- **Terminal gates and binding:** the CLI takes the shared exclusive lock,
  checks that the source and replay summaries have recognized terminal states
  and end times, verifies the source-plan hash and expected lock path, and
  requires the replay's source-build receipt to equal the selected source
  summary's exact path/size/SHA256. A source PASS additionally requires all
  3,136 modules. Run data is never edited by the packager.
- **Retention and exclusion:** recursive sorted collection retains every
  recognized text log/status/journal/memory sample, all attempts, unfinished
  text status files, and quarantine metadata. It excludes isolated
  home/temp/cache/config contents and compiled/quarantined build products,
  recording every excluded path, size, and reason. Symlinks, unknown file
  types, NUL-containing files, and invalid UTF-8 fail closed.
- **Determinism:** names are sorted; tar modes, owner IDs/names, and timestamps
  are fixed; gzip name and timestamp are fixed, with compression level 9.
  The manifest uses sorted canonical JSON and is embedded in the archive.
  Archive content is independent of source filesystem mtimes. Cross-version
  compression identity is not assumed; Python/zlib versions are recorded.
- **Extraction safety and completeness:** archive member names reject absolute
  paths, traversal, backslashes, drive-colon names, noncanonical paths, and
  control characters. Only expected unique regular files with fixed metadata
  are manually extracted into a fresh temporary directory. Every file's
  size/SHA256 and the embedded manifest bytes are checked, and exact complete
  member coverage is required. No arbitrary tar permissions or links are
  applied.
- **Drift and failure behavior:** a second full collection compares included
  bytes and membership against the initial manifest before publishing the
  archive filename. Failed writes/checks retain evidence and a partial archive
  for review. Existing output names are never overwritten. The verified report
  pins the archive and both sidecars.
- **Tests inspected:** deterministic output despite mtime changes; preservation
  of failed-attempt/sample evidence; running-source and running-replay
  rejection; symlink/unknown-file/binary-log rejection; traversal rejection;
  concurrent included-log drift rejection with retained partial archive; and
  a synthetic successful CLI lock/receipt-binding path. The final test covers
  the valid binding path rather than every invalid lock/binding variation;
  the rejection checks were inspected in the implementation.

## Scope to retain when publishing

1. `PACKAGE_VERIFIED` certifies archival integrity. Failed terminal builds or
   replays are deliberately allowed and their statuses remain visible. It is
   not a proof-verification success marker.
2. Included logs are rehashed before and after packaging. Excluded contents are
   **not** hashed; only their membership, size, and exclusion reasons are
   compared. `inputs_unchanged_after_packaging` must be read with that scope.
3. This is a log-only archive. Source/replay plans, inventories, scripts, or
   independent reviews outside the two run directories are not silently
   included just because logs reference them. Publish those separately when
   they are part of the reproducibility evidence.
4. Cooperative locking and before/after hashes do not defend against a hostile
   writer changing and restoring data between checks. The CLI is the approved
   entry point; calling its internal `package` function directly bypasses the
   outer lock and receipt-binding gate.
5. Extraction temporarily needs space for all uncompressed included logs.
   The script enforces a compressed Git-blob size budget, not a free-disk-space
   guard. The parent should check space before running it.
6. A crash after archive rename but before sidecar/report completion can leave
   incomplete final-named outputs that require review. Do not publish based
   only on the presence of `.tar.gz`; require the final verification report
   and confirm its output hashes.
