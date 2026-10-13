# Deterministic terminal-run evidence archive

The packager is prepared for parent review and later execution. It has been
tested only on small synthetic directories. Do not package the actual runs
until both have terminal summaries and the shared compiler lock is available.

```sh
python hilbert17-vendor-tools-20261013/package_terminal_run_evidence.py \
  --source-run hilbert17-vendor-tools-20261013/runs/source01 \
  --replay-run hilbert17-vendor-tools-20261013/replay-runs/vendor-fresh01 \
  --shared-lock hilbert17-20261013/verification/runtime-compile.lock \
  --output-prefix hilbert17-vendor-tools-20261013/evidence-archives/source01-vendor-fresh01
```

Four outputs are produced:

1. `.tar.gz`: deterministic compressed archive, with an embedded `MANIFEST.json`
2. `.members.json`: identical inventory bytes to the embedded manifest, with
   every payload member's SHA256 and byte count, terminal run statuses, and all
   exclusions listed
3. `.members.sha256`: standard checksum list for every archive member, including
   the embedded manifest
4. `.verification.json`: archive/sidecar hashes, full extraction-verification
   result, unchanged-input result, packager hash, and Python/zlib version

The archive includes every recognized text evidence file from both runs:
stdout/stderr, all attempt statuses, failed attempts, physical-memory/process
samples, completion journals, before/after input receipts, and partial atomic
text-status writes. Historic interrupted status files are retained even if a
later attempt succeeded. The source run and fresh-replay receipt must refer to
the same exact source-build summary.

Excluded files are recorded explicitly: compiled artifacts and their quarantined
build sidecars, and isolated home/temp/cache/config contents. A quarantine's
outer JSON manifest is retained, so hashes of preserved failed artifacts can
remain documented without publishing the binaries. Symlinks, unknown file
types, and binary or invalid-UTF8 data masquerading as logs cause refusal for
review instead of silently dropping ambiguous evidence.

The archive uses sorted member names; fixed mode0644, uid/gid0, blank ownership,
mtime0; and gzip with empty filename, mtime0, compression level9. Identical inputs
under the recorded Python/zlib runtime produce identical archive bytes,
independent of filesystem modification times. Compression byte identity across
different zlib versions is not claimed.

Verification extracts every regular member into a temporary directory, rejects
unsafe/duplicate/unexpected paths, rehashes all extracted files, confirms the
embedded inventory matches the sidecar bytes, and removes the temporary
verification directory. Run membership and all included input bytes are checked
again after packaging. The original runs are never edited or deleted.

The default compressed-size ceiling is90,000,000 bytes. Oversize, failed, or
mutated-input attempts leave a clearly named `.partial` archive and do not
overwrite older package outputs. Use a new output prefix after reviewing a
failure. The archive is suitable for a Git blob below that ceiling; this script
does not upload or publish it.

`PACKAGE_VERIFIED` verifies archival integrity only. Proof/build/replay outcomes
remain the recorded terminal statuses. A terminal failed run may be archived
faithfully without being represented as a mathematical verification success.

Synthetic test report: `evidence-packager-synthetic-tests01.json`. Tests cover
repeat-byte determinism, full extraction, failures/samples/partial-text retention,
compiled/cache exclusions, running-state refusal, symlink/binary/path-traversal
refusal, evidence mutation detection with partial-archive preservation, and
the CLI's shared-lock/source-receipt binding.
