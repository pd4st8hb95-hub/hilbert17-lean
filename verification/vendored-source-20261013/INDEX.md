# Vendored-source verification evidence, 2026-10-13

This directory preserves the completed source build and subsequent fresh replay,
including the failed environment probe that preceded the corrected replay.

## Results

- `source-summary.json`: all 3,136 project/external-package modules built from
  source; four aggregate targets and the final up-to-date check passed
- `replay-summary.json`: `BoundaryAcceptance` fresh replay passed in 515.567
  seconds; all pinned inputs and artifacts remained unchanged
- `vendor-acceptance-audit01.json`: fourteen theorem-type outputs and fourteen
  recursive axiom reports match the prior checked outputs; reported axioms are
  `propext`, `Classical.choice`, and `Quot.sound`
- `reviews/`: independent static, source-build, environment-fix, and terminal
  replay reviews, with their stated scopes and limitations

Lean/Std/Lake remain trusted prebuilt toolchain components. Fresh replay uses the
same Lean kernel, checks safe/non-partial constants in BoundaryAcceptance's
imported environment, and is not a separately implemented proof checker. The
source-build module count and replay import scope are distinct claims.

## Complete logs and inventories

`source01-vendor-fresh02.tar.gz` contains 25,110 log/evidence payload members plus
its embedded manifest, with source01 and vendor-fresh02 member prefixes. It
contains no compiled artifacts. The accompanying `.members.json`,
`.members.sha256`, and `.verification.json` record every payload hash, the full
extract-and-rehash check, and the archive SHA256. Archive integrity verification
does not replace the build/replay result checks.

`source-build-plan01.json` and `vendor-fresh-plan02.json` preserve the executed
plans. The latter's full 18,470,801-byte JSON input/output inventory is stored as
`vendor-fresh-plan02-inventory.json.gz`. Its predecessor is retained at
`tools/historical/vendor-fresh-plan01-inventory.json.gz`.
`compressed-replay-inventories-audit.json` records deterministic compression and
full decompression/byte-hash verification for both files.

## Failed attempt and exact historical tools

`failed-vendor-fresh01/` preserves all five files from the initial replay
attempt. Its Lake environment probe succeeded, but a strict path check rejected
trailing empty search-path components before any checker process launched.
The corrected runner leaves initial LEAN_PATH and LEAN_SRC_PATH unset and keeps
strict path validation unchanged.

`tools/historical/guarded_vendor_fresh_replay.py` is the exact old driver;
`tools/historical/vendor-fresh-plan01.json` is the old plan. The guard module
needed by that driver is preserved alongside it. The preservation receipt
records original hashes. Prior acceptance logs are retained under
`tools/historical/prior-acceptance/` for the documented comparison.

An initial log archive used the wrong replay member-prefix label while storing
the correct successful-run bytes. Its verification report is retained in
`tools/historical/`, together with a label-correction record confirming all
25,110 payload hashes are identical after prefix renaming. The superseded
archive itself is not duplicated here; the corrected archive is authoritative.

## Reproduction tools

`tools/` contains the exact build/replay/plan-generation/audit/packaging programs
and their local Python dependencies, plus static tests and operational notes.
These are historical audit tools: their pinned plans intentionally retain the
original execution machine's absolute paths. Copies in this repository preserve
bytes and provenance; relocation does not automatically make an old pinned
plan executable. For a fresh checkout's serial build, use the separately
provided repository helper `../../scripts/build_serial.py`.

The portable helper's 3,136-module order was statically checked against the
executed source plan. That static comparison is not a claim that this portable
helper itself performed the original fresh build or provides its Linux-specific
resource/network guards.
