# Independent review of the frozen offline source-build driver

Review date: 2026-10-13 UTC

## Conclusion

**PASS WITH DOCUMENTED OPERATIONAL LIMITATIONS.** No defect was found that
requires stopping the current `source01` build. This is a static driver review,
not a claim that the 3,136-module build has finished or passed.

Reviewed frozen plan SHA256:
`c7d5a8da7b42d45d2ab1c59944268ad8416b168f9b71be63f906345617e05460`.

Reviewed runner SHA256:
`21d5de3cafe8c9387f76fc47ce490dc1f1d0b2a99c034d3ef686610079462d74`.

Reviewed generator SHA256:
`6c93be2d62b3f9c7cb9b55df884b44413059da1a4fb253654e7cff91a88b4093`.

The reviewer did not author this driver or plan generator. The reviewer did
author the separate configuration overlay and therefore does not claim
independence from that configuration design. No frozen input, config, driver,
plan, or existing evidence was modified in this review. No Lean/Lake command,
compiler, network request, or build job was launched. Static Python tests used
temporary synthetic fixtures only; results are in
`independent-driver-static-checks01.json`.

## Verified design points

1. **Actual Lake facets match the driver.** In the installed Lean 4.32.1
   `Lake/Build/Module.lean`, `Module.depsFacetConfig` fetches module setup
   (lines 592–594), and `Module.oleanFacetConfig` extracts `.olean` from
   `mod.leanArts.fetch` (lines 1039–1058). The latter builds the whole Lean
   artifact bundle, including `.ilean`, `.c`, and module-system private/server
   artifacts where applicable; it does not merely write a public `.olean`.
   `Lake/Build/Library.lean` lines 65–74 implement the library Lean-artifact
   target by fetching these same module bundles. The four final aggregate
   libraries therefore require no additional native-object compilation.
2. **The frozen graph is topologically consistent.** Independent parsing
   confirms 3,136 distinct jobs: 2,775 Mathlib, 264 other dependencies, and 97
   project modules. Every non-toolchain dependency precedes its importer.
   The runner restricts toolchain boundaries to Init/Lean/Std/Lake and checks
   the compiled `.ilean` module identity and exact direct-import list.
3. **Source-only setup is coherent.** The initial run rejects existing active
   build artifacts; the plan pins all enumerated source/config/asset inputs;
   the current source is checked before and after each command. Artifact
   caching and release preference are disabled in all nine active TOML
   configurations, the command includes `--no-cache`, and environment search
   paths/caches are isolated. There is no executable Lake config, npm target,
   native precompilation flag, or custom build target in these actual configs.
   Current plan, generator, compiler launcher, Lake launcher, and libseccomp
   hashes match their frozen records.
4. **Serialization is structural, with a sampled backstop.** One shared
   compiler lock is held. For each topologically ready module, the driver first
   requires `+Module:deps` under `--no-build`, then completes that single
   `+Module:olean` command before moving on. There are no native/custom targets
   in this frozen configuration. Process samples additionally reject an
   unexpected source/compiler/helper or resource-flag override. Compiler
   arguments remain `-j 1 -M 4096`.
5. **Network denial is inherited and fail-closed.** The child pre-exec hook
   installs no-new-privileges plus a socket/traffic/io_uring denial filter.
   Failure to load that filter aborts the child launch. Other inherited file
   descriptors are closed, and standard streams are files or `/dev/null`.
   The existing preflight records EPERM for socket/socketpair in a child and
   socket creation in its grandchild. This review inspected that evidence;
   it did not rerun the networking test.
6. **Resume preserves evidence and rejects ambiguity.** Completed records must
   be a prefix of the plan. Their output hashes and compiled direct imports
   are rechecked. Only the first unfinished module's exact-stem artifacts may
   be quarantined before retry. Untracked artifacts, changed output hashes,
   or malformed/torn journal entries stop recovery for review. Synthetic tests
   confirmed exact-stem capture, valid-prefix acceptance, changed-output
   rejection, and torn-journal rejection. Interrupted quarantine/setup itself
   can require manual recovery; it cannot silently produce a success status.
7. **Final acceptance is appropriately stronger than progress.** All four
   aggregate targets must pass, the subsequent `--no-build` aggregate check
   must pass, all 3,136 recorded outputs are rehashed, untracked artifacts are
   rejected, and all frozen inputs are rechecked in the finalizer. A changed
   input overrides the tentative success status. The final aggregate creates
   no additional library artifact in the standard leanArts facet.

## Limitations to retain in the final report

- **No automatic free-disk guard is implemented.** The parent and driver author
  were notified; the author confirmed that the parent intentionally accepted
  this omission for the frozen run. Disk must be monitored externally. A
  read-only sample during this review found 17,293,017,088 bytes available.
  The earlier configuration note asking the driver to check disk should not
  be represented as an implemented feature.
- **The memory/process guard is sampled, not a hard host-wide memory limit or
  exhaustive execution trace.** It refuses new commands at 60 percent observed
  physical usage, requests termination at 70 percent, and kills at 75 percent
  or after the TERM grace period. A short spike/process between 0.5-second
  samples may go unobserved. Report observed peak usage, not an impossible
  guarantee that usage never briefly exceeded a threshold.
- **Resume is fail-closed rather than automatic crash repair.** A torn journal,
  partial quarantine, or unexplained additional artifact requires separate
  review. This is documented and does not invalidate a clean uninterrupted run.
- **The verifier assumes frozen inputs remain controlled.** Hash checks are
  before/after checks, not an immutable filesystem or a defense against a
  hostile concurrent writer that changes and restores files between checks.
  The shared lock coordinates compliant build processes, not arbitrary
  external programs.
- **The installed toolchain is trusted.** The plan pins Lean/Lake launcher
  files and libseccomp, not every linked toolchain library/runtime artifact.
  Lean/Std/Lake are not rebuilt by this procedure. This source build and its
  Lean-kernel checks are not an independent proof checker.
- **Generic validator completeness is not claimed.** The review inspected the
  actual pinned TOML files. `validate_configs` is not a complete schema-level
  prohibition of every future executable/native field; for example, it checks
  legacy `extraDepTargets` rather than all possible future `needs` uses. The
  actual reviewed configs contain neither, so this does not affect this run.

## Observed build state

The running summary was inspected read-only during review. It showed progress
from 221 to 312 completed modules, with the most recent dependency check passing.
Those are snapshots, not final build results. The parent retains responsibility
for following the run through its terminal state and reviewing final evidence.
