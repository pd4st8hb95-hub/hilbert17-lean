# Verification of the source-vendored Hilbert 17 package

Date: 2026-10-13 UTC

## Current result

- **Clean offline source rebuild: PASS.** All 3,136 selected modules, all four
  aggregate targets, and the final `--no-build` up-to-date check passed.
- **Acceptance outputs: PASS.** Fourteen theorem-type reports and fourteen
  recursive-axiom reports match the prior checked outputs. Each axiom report
  contains exactly `propext`, `Classical.choice`, and `Quot.sound`.
- **Fresh imported-environment replay on these new artifacts: PASS.** The
  `vendor-fresh02` checker exited 0 after 515.567 seconds. It replayed the safe,
  non-partial loaded environment of `BoundaryAcceptance`, whose import closure
  contains 3,131 built project/vendor modules plus its imported toolchain
  environment. All pinned inputs and artifacts remained unchanged.
- **Combined source/replay log archive: VERIFIED.** The package contains
  25,110 evidence files plus its manifest; every member passed full safe
  extraction and SHA256 verification. The first replay preflight failure is
  preserved separately as raw evidence.

The mathematical target is the unrestricted arbitrary-finite-variable,
real-coefficient statement in
[FinalTargetContract.lean](../../checks/FinalTargetContract.lean), together with
the zero/zero-variable and necessity/sufficiency checks in
[BoundaryAcceptance.lean](../../checks/BoundaryAcceptance.lean). No transfer
premise remains in the final theorem. This is a formalization of classical
mathematics, with no novelty or first-formalization claim.

## Source build: exact scope and result

The `source01` run used the separately installed Lean 4.32.1 toolchain and the
pinned source plan. It started with no package build artifacts, with local
artifact cache and release reuse disabled. The reviewed child-only seccomp
filter denied socket creation/traffic and io_uring networking routes throughout
each Lake process and its descendants.

The 3,136 modules consist of:

- 97 configured project modules
- 2,775 Mathlib modules
- 78 Batteries, 14 Qq, 132 Aesop, 13 ProofWidgets, 10 ImportGraph,
  4 LeanSearchClient, and 13 Plausible modules

Thus all 3,039 external Lean modules in the transitive whole-file source closure
were built from the vendored sources. Each external Lean file matches its
pinned upstream Git blob. This includes required tactic and lint infrastructure;
it is neither the full upstream repositories nor a declaration-minimal slice.
The installed Lean/Std/Lake library and runtime artifacts remain trusted
prebuilt toolchain inputs and were not rebuilt.

One topologically ready module was built at a time, with a preceding
`+Module:deps` check under `--no-build`, followed by `+Module:olean` and exact
compiled-import comparison. The `.olean` facet builds the full Lean-artifact
bundle, including `.ilean` and module-system artifacts where applicable.

All **6,274** command status records report `PASS` with exit code 0:

- 3,136 dependency checks
- 3,136 module builds
- One build of `Hilbert17`, `Hilbert17RealClosure`, `Hilbert17Full`, and
  `Hilbert17Acceptance`
- One final `--no-build` check of the same four targets

The complete output journal contains 43,322 file records. Final checks rehashed
the recorded outputs, rejected untracked active build artifacts, and confirmed
that all **3,374 frozen inputs** were unchanged.

The separate [independent terminal/preflight audit](reviews/INDEPENDENT-SOURCE01-AND-REPLAY-PREFLIGHT.md)
rehashed those inputs/outputs and all 21,979 prepared replay artifacts, checked
all 6,274 command receipts and compiled import lists, and approved the original
replay plan for launch. The later, narrowly corrected plan02 and its successful
terminal result are documented separately below.

Run timing and resources:

- Attempt: 1, with no failed command or retry in this run
- Start: 2026-10-13 15:52:36.442970 UTC
- End: 2026-10-13 19:33:12.689340 UTC
- End-to-end elapsed time: 13,236.246370 seconds, approximately 3 h 40 min 36 s
- Highest recorded physical-memory usage: 23.196572226269748 percent, during
  `Mathlib.Analysis.Normed.Operator.LinearIsometry:olean`

The physical-memory/process guard sampled every 0.5 seconds, refused new
commands at 60 percent usage, requested termination at 70 percent, and killed
at 75 percent or after a five-second TERM grace. These are sampled observations
and interventions, not a hard guarantee about instantaneous peaks. The source
driver has no automatic free-disk guard; its receipt does not certify one.

Source evidence:

- [Source summary](source-summary.json), 2,664 bytes, SHA256
  `437f5a86d3b5b46822f9a15672a7128109940bc17d1450309835a7e7e27b039d`
- [Source plan](source-build-plan01.json), 2,853,563 bytes, SHA256
  `c7d5a8da7b42d45d2ab1c59944268ad8416b168f9b71be63f906345617e05460`
- The source journal is preserved as `source01/completed.jsonl` within
  the combined run archive: 11,687,255 bytes, SHA256
  `70fa1437db8b60f875adc618275625f6372018d0e14093fce147c4ce592fa52b`

## Acceptance type and axiom audit

[The acceptance audit](vendor-acceptance-audit01.json) reports
`FOURTEEN_TYPES_AND_AXIOM_FOOTPRINTS_MATCH_PRIOR`. It checks the actual messages
from the successful compilation of the two acceptance modules, binds them to
the completed source journal and source/output hashes, and compares them with
the preserved prior logs.

All 14 `#check` type outputs match after whitespace normalization. All 14
`#print axioms` outputs contain exactly the standard classical axioms
`propext`, `Classical.choice`, and `Quot.sound`; no additional external
mathematical axiom or unresolved transfer assumption is reported.

This is extraction and comparison of fresh compilation outputs, not a separate
execution of Lean. It does not compare every printed definition body or replace
the additional fresh imported-environment replay.

Audit file: 66,226 bytes, SHA256
`dedd575f4975cd2533cb0250c436ddbbc0a3831fd1fc7b7aa0a7dd59d363ae16`.

## Fresh imported-environment replay: PASS

The `vendor-fresh02` summary reports
`ALL_IMPORTED_SAFE_CONSTANTS_FRESH_REPLAY_PASS`. The Lake environment probe and
checker command both passed with exit code 0; stderr was empty. The checker
command took **515.567 seconds**.

- Runner start: 2026-10-13 19:43:38.091815 UTC
- Checker start: 2026-10-13 19:43:38.741545 UTC
- Checker exit: 2026-10-13 19:52:14.308849 UTC
- Final unchanged-inventory checks completed: 2026-10-13 19:52:25.342991 UTC
- Highest sampled physical-memory usage: 25.603546286349847 percent
- Checker memory/process samples: 1,027, at the configured 0.5-second interval

The actual command used Lake `--no-cache --no-build env` and the absolute
installed Lean 4.32.1 `leanchecker` executable with
`--fresh -v BoundaryAcceptance`. Both the successful environment probe and the
observed checker process used only the project/vendor artifact roots plus the
installed toolchain's builtin root, with no empty search-path entries.

The replay procedure held the same exclusive lock as the source builder,
inherited the child network-denial filter, applied the physical-memory guard,
and rechecked the complete artifact/input inventory before and after replay.
The terminal receipt confirms all pinned inputs and artifacts were unchanged.
The checker does not support a `-M` CLI limit; the sampled physical-memory guard
provided the recorded resource protection.

The [independent terminal review](reviews/INDEPENDENT-VENDOR-FRESH02-TERMINAL-REVIEW.md)
rehashed all 3,374 frozen inputs, 43,322 build outputs, and 21,979 replay
artifacts, and checked all 1,027 memory/process samples. It reports
`PASS_TERMINAL_FRESH_REPLAY_EVIDENCE`. This was a separate evidence/identity
review; it did not rerun the compiler or checker.

The entry's transitive import closure contains **3,131 of the 3,136 built
project/vendor modules**, plus its imported toolchain environment. The five
built modules outside this replay entry are `FinalTargetContract`, `Hilbert17`,
`Hilbert17Full`, `Hilbert17RealClosure`, and `TargetSanity`. They passed the
source build; `FinalTargetContract` additionally contributes seven of the
audited type/axiom reports. Do not describe the entry replay as replaying all
3,136 built modules.

The pinned replay inventory records:

- 12,253 project/vendor replay artifacts, totaling 2,376,344,408 bytes
- 9,726 trusted builtin replay artifacts, totaling 2,077,329,080 bytes
- All 43,322 source-build output records and 3,374 source/config/asset inputs
- Installed top-level toolchain shared libraries and the inspected checker/
  replay source files

The replay-artifact subset includes public/private/server oleans and IR. It is
an inventory and hash record, not a copied compiled-artifact cache.

Evidence pins:

- [Fresh replay plan](vendor-fresh-plan02.json), 5,545 bytes, SHA256
  `6233bed408866c19a425870588c83329fe8464d4ba99c8c2bc97ba6c4ab439b2`
- [Compressed fresh inventory](vendor-fresh-plan02-inventory.json.gz),
  3,328,886 bytes, SHA256
  `a09e6add1efafd1b43c2a76c1b44342bb6d97c51847e1bb99f9b31ffd84d32eb`.
  The original JSON is 18,470,801 bytes, SHA256
  `d7098596b683564cb823f9371ae520c5869a5da11f1140bc7d9933554f2a5dbd`.
  After decompression, verify that original JSON hash. Deterministic compression
  and decompression were checked in the [compression audit](compressed-replay-inventories-audit.json).
- [Replay summary](replay-summary.json), 10,260 bytes, SHA256
  `c1a42cc27a79908d17f0f1692c4ba0f6debee066fcc15aacee0f6d2fcb2efb75`
- [Replay driver](tools/guarded_vendor_fresh_replay.py), 18,571 bytes, SHA256
  `77635f04d0a0fba8506c0d655f1778b4a5882d1958821d32417a9e18fee1b786`
- Checker stdout in the archive: 42 bytes, SHA256
  `1f18cd70358f4e1959a8f5e0923c39abe003d84b76283e33dac17c129bc7526a`
- Checker stderr in the archive: empty, SHA256
  `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`

`--fresh` imports the final acceptance entry and replays its loaded safe,
non-partial constants into an empty environment using the same Lean kernel.
Constructors/recursors are checked against the reconstructed inductives.
Declared axioms are accepted, so the recursive axiom audit remains separately
necessary. Unsafe/partial executable code, rebuilding Lean, and an external
independent kernel are outside this claim.

### Preserved first replay attempt and narrow correction

The [first-run summary](failed-vendor-fresh01/summary.json) records
`ABORTED_OR_INPUT_DRIFT` with `Empty search-path entry refused`. That run
started at 19:37:31 UTC and stopped during environment preflight, before any
checker was launched. Its list contains only the Lake environment probe. This
was a search-path validation failure, not a mathematical proof or kernel-replay
failure; the successful source build and acceptance outputs were unaffected.

The first driver explicitly set `LEAN_PATH` and `LEAN_SRC_PATH` to empty
strings. Installed Lake sources distinguish an absent variable from an empty
one: the latter parses as an empty path component and produces a trailing `:`
after paths are prepended. The strict validator correctly refused it.
The corrected driver omits those two keys from its freshly constructed
isolated environment; it does not inherit the caller's environment. The
[independent fix review](reviews/independent-replay-path-fix-review02.md)
confirmed that only those two dictionary entries changed semantically and
that the path, process, seccomp, and memory guards were unchanged. A newly
pinned plan02 was then used for the passing second run.

All five first-run files are retained under `failed-vendor-fresh01/`. The
[exact historical driver](tools/historical/guarded_vendor_fresh_replay.py),
[plan01](tools/historical/vendor-fresh-plan01.json), and
[compressed inventory01](tools/historical/vendor-fresh-plan01-inventory.json.gz)
are preserved separately. Key historical pins are:

- Failed-run summary: 4,277 bytes, SHA256
  `c17ba95601763e46288ff67236b334b3c05f5e9a41f72be0282909a21af56a43`
- Historical driver: 18,297 bytes, SHA256
  `d7bc29bf24bf5e9ad1d21a659e73ba414c4aa14397a1e7c39ba7100ab5f8ed43`
- Plan01: 5,545 bytes, SHA256
  `db331c954583a5886a4b108b48d30e8f244df2e9e1180afe980b60a3a6475bb3`
- Compressed inventory01: 3,328,890 bytes, SHA256
  `0f0fa6d57889d6a098fda0ef705e7ec2f5fc9bf6b938056367817de9ef7266ad`
- Original inventory01 JSON: 18,470,801 bytes, SHA256
  `828859744d1a5a9f8b8b1abbe0bea613fc61a3d6b50e9f6ef50f42c9c2500adb`

## Source and UI adaptation boundaries

The project Lean proof sources and statements remain unchanged. The eight
vendored package slices retain source headers, licenses, original configurations,
and exact upstream pins. See the [source manifest](../../vendor-source-manifest.json),
[build-adaptation notes](../../VENDORED-BUILD-CONFIG.md), and
[third-party attribution](../../THIRD_PARTY.md).

The 15 compile-time assets include 14 exact upstream files and one explicitly
documented headless Penrose display adapter. That adapter disables an optional
editor diagram renderer and shows an explanatory message; it changes no Lean
proof source and adds no proof axiom. The successful source build includes the
changed string asset, and the successful fresh replay uses the resulting
new compiled artifacts. The original bundled renderer is not distributed, and
the remaining widget notices include the bundled react-fast-compare MIT license.
See the [asset manifest](../../vendor-asset-manifest.json).

Plans and receipts retain their actual original absolute runtime paths. They
are historical audit evidence, not relocatable launch plans. Publication-only
documentation, evidence files, and the portable convenience helper are added
after the frozen build; they are not represented as original frozen inputs.
Final publication must preserve the verified Lean/config/compile-asset bytes.
The portable helper's plan was statically matched to the guarded plan; that
helper may reuse existing artifacts and is not the clean guarded audit runner.

## Evidence archive and historical records

The [log archive](source01-vendor-fresh02.tar.gz) is **5,102,001 bytes**, SHA256
`e84222c0e5668edcc08732a0c8fbed44ba3c878fdf2a0355d8d818cfb43a902d`.
The [packaging receipt](source01-vendor-fresh02.verification.json) reports
`PACKAGE_VERIFIED` and `ALL_MEMBERS_EXTRACTED_AND_SHA256_VERIFIED`:
25,110 evidence files plus the embedded manifest were safely extracted and
rehashed, totaling 33,733,034 uncompressed bytes including the manifest. The
input evidence bytes were unchanged after packaging. Archive members use the
correct `source01/` and `vendor-fresh02/` prefixes.

Sidecar pins:

- [Member inventory](source01-vendor-fresh02.members.json): 5,256,048 bytes,
  SHA256 `f1c1c88ce730e62ce42485402221dde4db72eb1f46c4ee9b77e3db51f22c0f5d`
- [SHA256 inventory](source01-vendor-fresh02.members.sha256): 3,581,180 bytes,
  SHA256 `6d1a32f0ccdf3d15947137066922e8c7daeaa8bd7f8b76cc9a8f358d0492b9de`
- [Packaging receipt](source01-vendor-fresh02.verification.json): 2,689 bytes,
  SHA256 `7b81b58494b00905813e1ddc5564a01d6e78d44bfa0d34e893ab4a27e0a9845b`

The archive retains all commands, statuses, attempts/failures, memory samples,
journals, and input-verification receipts from `source01` and `vendor-fresh02`.
The first replay preflight failure is retained separately in the raw files
above. Compiled artifacts and isolated home/temp/cache/config contents are
outside the archive's allowed payload; this run recorded zero excluded files.
Archive verification attests included-log integrity; proof-check outcomes are
established by the individual terminal summaries and their supporting records.
The packaging receipt preserves its original staging filenames ending in
`-corrected`; publication renames these four files without changing their
bytes. A [label-correction record](tools/historical/archive-label-correction.json)
preserves the superseded packaging receipt: the earlier package used the wrong
replay member prefix, and all 25,110 evidence payload files were byte-identical
after that prefix was corrected. Scripts are under `tools/` and independent
reviews under `reviews/`.

Earlier [97-module and final-target checks](../FINAL-STATUS.md),
[portable cached/offline Lake verification](../PORTABLE-LAKE-STATUS.md), and
[fresh imported-environment replay](../FRESH-REPLAY-STATUS.md) retain their
original revisions, hashes, and scopes. They are not relabeled as this clean
dependency-source build or its successful new replay.
