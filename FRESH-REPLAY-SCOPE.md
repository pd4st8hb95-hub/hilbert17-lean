# Additional imported-proof replay: scope and bounded plan

**Status: fresh imported-proof replay passed on 2026-10-13.** The single
bounded job completed with exit code zero, empty stderr, and the expected
`replaying BoundaryAcceptance with --fresh` stdout. It took 526.513 seconds
and peaked at 26.1235% sampled physical-memory usage. All inventoried inputs
matched before and after execution.

This extends the earlier source compilation, recursive theorem-axiom audit,
97 selected local replays, and successful isolated offline Lake build to the
stored imported proof bodies. It is not a new requirement for ordinary Lean
theorem acceptance. This evidence delta changes no Lean source or theorem.

## What the pinned checker actually does

The primary sources are the installed Lean 4.32.1 sources:

* `src/lean/LeanChecker.lean`, SHA256
  `eb5dee411837629f09c5c18d63cc833d30335a46048bc586642742e90aa65d5f`:
  lines 36–38 implement fresh replay; lines 56–68 document its scope;
  lines 74–104 implement the CLI and exact single-module selection.
* `src/lean/Lean/Replay.lean`, SHA256
  `3e1ea55d20db328f6d9d5321fa2946ca3011efc9ceb2c25ff19162842809a4a2`:
  replay recursively orders constants by the names in their types and values,
  submits theorem and definition bodies to `addDeclCore`, and regenerates
  inductives before checking their constructor/recursor data.
* `Lean/Environment.lean` and `Lean/Util/FoldConsts.lean` specify private-level
  import loading and dependency traversal, including opaque values.

`leanchecker --fresh -v BoundaryAcceptance` imports the named module and
replays the resulting environment's constants into `mkEmptyEnvironment` at
trust level zero. This includes imported Mathlib and Lean declarations, not
only the newly compiled local module. The CLI targets modules, not individual
theorem names; this run therefore covers a superset of the final theorem's
actual proof dependencies.

The import path loads private module data. In Lean's module system, an exported
theorem interface may be represented axiom-like while its actual proof body
resides in `.olean.private`; the richer theorem information is loaded for this
replay. A `thmInfo` is submitted as a `thmDecl`, including its proof value.

Important limits remain:

* This is the **same pinned Lean kernel**, not an external independent verifier.
* `Environment.replay` explicitly skips unsafe and partial implementation
  constants. This qualification belongs in the resulting claim.
* Axiom declarations are accepted as declarations. Fresh replay alone does not
  enforce an axiom allowlist. The separate recursive axiom audit of each final
  theorem remains necessary and has reported only `propext`, `Classical.choice`,
  and `Quot.sound`.
* Duplicate theorem interfaces can be merged when their names, types, universe
  parameters, and mutual-block metadata agree, as in the pinned import/replay
  implementation. The tool is not a bytewise comparison of every duplicate
  proof representation.

## Entry and inputs

The executed entry was the already Lake-built `BoundaryAcceptance` module. It imports
`RealClosureTransfer`, `CertificateNonnegative`, and `ClearDenominators`, so its
imported environment contains both full final candidate proofs and the
necessity, equivalence, and boundary checks. `FinalTargetContract` adds explicit
aliases but no further mathematical input. No new Lean entry or Lake
configuration change is needed.

The search path is fixed to the portable project build root, followed by its
copied Mathlib and auxiliary package build roots; the pinned Lean builtin root
is appended by the runtime. The plan records every actual `.olean`,
`.olean.server`, `.olean.private`, and `.ir` file in those roots. Membership,
sizes, and SHA256 hashes are checked before and after execution. Private-level
imports may load IR data even though this is a proof-replay task.

`LEAN_SYSROOT` is set explicitly to the pinned installation, avoiding the
checker's otherwise implicit `lean --print-prefix` subprocess. No inherited
search path, network operation, dependency update, or source rebuild is used.

## Serial resource envelope

The reviewed runner is `run_bounded_fresh_checker01.py`. Its frozen plan must
include the successful terminal portable Lake receipt and the exact compiled
`BoundaryAcceptance.olean` recorded by that receipt. It acquires the same
`verification/runtime-compile.lock` used by Lean/Lake jobs before input checks.
Only one checker process is launched; the fresh replay loop is internally
sequential.

The existing physical-memory guard is unchanged: sample every 0.5 seconds,
refuse a new job at 60% usage, warn at 60%, send SIGTERM at 70%, and SIGKILL at
75% or after the existing five-second termination grace. A separate finite
wall bound sends SIGTERM after 3,600 seconds, followed by that same grace.
Process-group cleanup and a terminal receipt are required on interruption.

The pinned checker CLI does not implement Lean compiler `-M`/`-j` resource
options, so these must not be presented as limits on this run. A preliminary
source graph for `RealClosureTransfer` contained 4,475 modules; whole-environment
replay can therefore use substantially more time and memory than 97 local
replays. That count is an earlier static estimate, not a measured current
constant count or runtime prediction.

The recorded launch order was: finish portable Lake, freeze the artifact
inventory and plan, review their hashes, then run this one bounded checker job. A timeout,
memory stop, interruption, or checker failure is recorded as incomplete or
failed extra replay, never as success. It does not retroactively erase the
already-recorded ordinary compilation/axiom evidence. Any retry or narrower
fallback requires an explicit new plan and an accurately stated scope.

## Terminal evidence

* Fresh replay summary:
  `verification/fresh-replay01-run01/summary.json`, SHA256
  `a3bada02b3c9de6f1ba8c7874a6cceb6255f8d0333826cf9bd88110e337d1472`.
  Status: `ALL_IMPORTED_SAFE_CONSTANTS_FRESH_REPLAY_PASS`.
* Reviewed runner SHA256:
  `94fb6a03e4665c7e79edb22bfd0d06553e2b91b0d8ed9dc1b55e8a56a17ea6b5`.
* Frozen plan SHA256:
  `ce975bf5bb954b89403a64aba2c56d30071f9e69b744a59616b47f6f71b1e056`.
* Artifact inventory SHA256:
  `d3874f0120dd7da2cad2141a3850dedc4556ec04bf8280131d59e502795f4539`.
  It pins 24,091 importer files totaling 4,863,176,336 bytes, all 97 local
  sources, and the private package configurations. The absent Cli cache root
  is explicitly omitted; all actual portable search roots and builtins are
  covered.
* Prerequisite isolated portable Lake summary SHA256:
  `6b8c32a971ca10061fafd40bf30dbb363ad95a36c79766ecedb95c13a1216213`.
  All 306 recorded commands passed, including aggregate and up-to-date checks.

The recorded success covers the entire imported safe/non-partial environment
of `BoundaryAcceptance`, including the full final target proof dependencies.
It does not claim that unsafe/partial code was replayed, that axioms were
proved, that every imported declaration is actually needed by Hilbert
seventeenth, or that an external independent kernel was used. The previously
recorded final-theorem axiom allowlist remains the separate evidence that no
nonstandard unproved mathematical theorem was assumed.

The large artifact inventory is preserved locally, with its exact hash/bytes/counts and source/config pins in `verification/fresh-inputs/ARTIFACT-INVENTORY-COMMITMENT.json`; its full 6,553,117-byte list and compiled caches are not bundled. The independent post-run reconciliation is `verification/FRESH-REPLAY-INDEPENDENT-AUDIT01.json`.
