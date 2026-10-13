# Hilbert’s seventeenth problem in Lean

[中文说明](README.zh-CN.md)

**Hilbert’s seventeenth problem is formally proved in Lean 4.32.1. This source-vendored edition has passed a clean offline rebuild of all 3,136 selected modules, all four aggregate targets, and the final no-build up-to-date check. Its 14 acceptance type reports match the prior checked outputs; all 14 recursive axiom reports contain only the three standard classical axioms.**

This edition includes the complete external Lean source-module closure required by the 97 configured project roots: **3,039 files from eight pinned packages**, comprising **2,775 Mathlib files and 264 files from the other seven packages**. The original project proof sources are unchanged. All active package dependencies are local relative paths under `vendor/`.

**Fresh imported-environment replay against the new vendored build: PASS.** On 2026-10-13, `vendor-fresh02` completed `leanchecker --fresh -v BoundaryAcceptance` with exit code 0 in **515.567 seconds**. Its import closure contains **3,131 of the 3,136 built project/vendor modules**, plus the imported toolchain environment. All loaded safe, non-partial constants were replayed with the same Lean kernel; all pinned inputs and artifacts remained unchanged. Declared axioms are accepted by replay and audited separately.

The target is every finite-variable polynomial with arbitrary real coefficients that is weakly nonnegative at every real point. Its image in the same polynomial ring’s fraction field must be a finite sum of squares. Equivalently, `q ^ 2 * f = ∑ i, (p i) ^ 2` for a polynomial `q ≠ 0`. The denominator is nonzero as a polynomial; it may vanish at individual real points. Zero variables, the zero polynomial, and an empty finite sum are allowed.

The existing ten-module baseline and seven-module real-closure backport have their published checks. `RealClosureTransfer` now proves the unconditional theorem through uniform finite sign-condition transfer, discharging the earlier conditional theorem’s transfer premise. Its exact compiled type and recursive axiom lists have passed independent inspection. All 97 selected local module replays also pass; the portable offline Lake check also passes.

See [the proof map](PROOF-MAP.md), [coefficient-transfer details](TRANSFER-GLUE.md), [final verification status](verification/FINAL-STATUS.md), [the exact acceptance contract](checks/FinalTargetContract.lean), and [third-party attribution](THIRD_PARTY.md). The declaration names are `Hilbert17Transfer.hilbert17Real_candidate` and `Hilbert17Transfer.hilbert17RealCleared_candidate`. The `_candidate` suffixes and drafting-time source-only comments are retained historical identifiers and wording so that checked source bytes remain unchanged. Dated final receipts, rather than those old comments, determine the verified status.

This formalizes the classical theorem using attributed TauCeti and Mathlib infrastructure and project-specific connecting proofs. It makes no claim of new mathematics or first formalization.

## Verification of this source-vendored edition

The guarded `source01` run, attempt 1, completed at **2026-10-13 19:33:12 UTC** with `ALL_FROM_SOURCE_OFFLINE_LAKE_BUILDS_PASS`: 3,039 external modules plus 97 project modules were rebuilt from their pinned sources, starting without package build artifacts. Local artifact/cache reuse and network access were disabled. The four aggregate targets and a final `--no-build` check passed; all frozen source, configuration, and asset inputs remained unchanged. The installed Lean/Std/Lake toolchain was reused and is not part of the source rebuild.

The separate acceptance-log audit reports `FOURTEEN_TYPES_AND_AXIOM_FOOTPRINTS_MATCH_PRIOR`. All 14 displayed theorem types match the prior checked outputs after whitespace normalization; all 14 recursive axiom reports contain exactly `propext`, `Classical.choice`, and `Quot.sound`. This audits the outputs produced during the fresh compilation; it is not an additional Lean execution or a replacement for the separately completed imported-environment replay.

The first replay attempt stopped during environment preflight because explicitly empty search-path variables produced a trailing empty entry. It never launched the checker. After removing those two empty variables, the same strict checks passed and the newly pinned second run succeeded. [The verification report](verification/vendored-source-20261013/VERIFICATION.md) preserves both attempts and explains the correction.

Exact SHA256 pins for the new evidence:

- [Source-build plan](verification/vendored-source-20261013/source-build-plan01.json): `c7d5a8da7b42d45d2ab1c59944268ad8416b168f9b71be63f906345617e05460`
- [Source-run receipt](verification/vendored-source-20261013/source-summary.json): `437f5a86d3b5b46822f9a15672a7128109940bc17d1450309835a7e7e27b039d`
- [Acceptance audit](verification/vendored-source-20261013/vendor-acceptance-audit01.json): `dedd575f4975cd2533cb0250c436ddbbc0a3831fd1fc7b7aa0a7dd59d363ae16`
- [Fresh-replay plan](verification/vendored-source-20261013/vendor-fresh-plan02.json): `6233bed408866c19a425870588c83329fe8464d4ba99c8c2bc97ba6c4ab439b2`
- [Fresh-replay receipt](verification/vendored-source-20261013/replay-summary.json): `c1a42cc27a79908d17f0f1692c4ba0f6debee066fcc15aacee0f6d2fcb2efb75`

## Offline source reproduction

Install Lean **4.32.1** separately, including its bundled Lean/Std/Lake libraries and `leanchecker`. The root toolchain is pinned to `leanprover/lean4:v4.32.1`; the vendored Mathlib source is pinned to `520045ab14e26149ee970e2e617ca04b09bde5d6`. With that exact toolchain already available and this repository fully present, run from the repository root:

```sh
lake build Hilbert17 Hilbert17RealClosure Hilbert17Full Hilbert17Acceptance
lake env lean checks/FinalTargetContract.lean
lake env lean checks/BoundaryAcceptance.lean
lake env leanchecker --fresh -v BoundaryAcceptance
```

No dependency fetch, Mathlib cache download, npm install, or JavaScript build is needed. No compiled package caches are included. A clean build compiles the selected project and external-package Lean modules from the included sources; the installed Lean/Std/Lake toolchain is the explicit boundary and is not rebuilt. Always invoke the installed 4.32.1 tools from the repository root: preserved upstream package toolchain files may name older versions.

These commands are reproduction instructions. The new build's reviewed result is identified separately above. Normal aggregate `lake build` may schedule several modules at once even though each Lean process uses `-j 1 -M 4096`. The serial option below reduces concurrent compiler work; `--fresh` also needs additional time and memory. Build outputs are created locally under `.lake/` and `vendor/*/.lake/`. Active dependency paths are portable and relative; historical receipts retain original machine paths for traceability.

### Portable serial build option

The [serial helper](scripts/build_serial.py) requires **Python 3.11 or later**. Run it from the repository root, using the command for your installed Python version. The first command checks source/asset hashes, local configurations, and the 3,136-module dependency order, then prints a JSON plan without invoking Lean or Lake:

```sh
python3.11 scripts/build_serial.py --check-plan
python3.11 scripts/build_serial.py
```

The second command builds one topologically ready module at a time, then checks all four aggregate targets. It looks for a directly installed toolchain and verifies its Lean version; it does not install a toolchain. To select the installed executable explicitly:

```sh
python3.11 scripts/build_serial.py --lake "/absolute/path/to/lean-4.32.1/bin/lake"
```

On Windows, use your Python 3.11+ launcher, for example `py -3.11`, and the installed toolchain's `lake.exe` path. After the serial build, run the two acceptance-source checks and the `--fresh` command shown above with the same installed Lean 4.32.1 toolchain.

The helper may reuse existing local build outputs. It has no Linux seccomp network filter, host-wide memory guard, or full compiled-artifact audit, and its success message only establishes that the configured targets are up to date. Its plan and command order have been statically compared with the guarded 3,136-module plan; the helper itself has not been separately run end-to-end. The complete-from-source evidence belongs to the separate clean, guarded build and its reviewed receipt, whose status is stated above. Do not equate a convenience-helper run with that stronger audit.

## Included dependency sources and UI assets

The eight packages are Mathlib, Batteries, Qq, Aesop, ProofWidgets, ImportGraph, LeanSearchClient, and Plausible. They are the transitive whole-file import closure, including required tactic and lint infrastructure, rather than complete upstream repositories or a smallest declaration-level slice. See [the source manifest](vendor-source-manifest.json), [vendor notes](vendor/README.md), [build adaptations](VENDORED-BUILD-CONFIG.md), and [third-party attribution](THIRD_PARTY.md). Each selected dependency Lean file matches its pinned upstream Git blob; package licenses, source headers, original configs, and provenance are retained.

Fifteen compile-time text/JavaScript assets are included. Fourteen match pinned upstream bytes. The optional Penrose diagram display uses a small documented headless adapter instead of the upstream bundled renderer: editor diagram rendering is disabled and an explanatory message is shown. The Lean mathematical proof sources and theorem statements are unchanged; the adaptation introduces no proof axiom. Both the successful source rebuild and fresh imported-environment replay include the resulting new artifacts. This is not a full upstream widget UI build. See [the asset manifest](vendor-asset-manifest.json).

## Historical evidence and trust scope

The pre-vendoring [baseline failure log](verification/FAILED-ATTEMPTS.md), [real-closure status](verification/REALCLOSURE-STATUS.md), and [transfer failure receipts](verification/TRANSFER-FAILED-ATTEMPTS.md) remain available with their original scope. They are not relabeled as new vendored-build evidence. Sources retain their exact proof headers even where those headers describe an earlier source-only drafting stage. Receipts identify the actual revision checked. The standard classical axioms `propext`, `Classical.choice`, and `Quot.sound` are permitted; a source scan alone does not certify a theorem. Selected replay uses the pinned Lean kernel with imported dependencies, and is not an external independent checker or a claim to replay all transitive Mathlib declarations.

See [portable Lake verification](verification/PORTABLE-LAKE-STATUS.md) for its historical offline/cached scope, both attempts, and actual acceptance-output comparison. The separate historical fresh imported-environment replay also passed. It extended beyond the 97 local-module check to the loaded safe/non-partial imported constants used by the final acceptance entry, including the relevant Mathlib proofs. It used the same Lean kernel and accepted declared axioms, which were audited separately. These scopes remain unchanged by adding dependency source files to this repository.

## Formalized external ingredients

The [external-ingredient proof map](EXTERNAL-INGREDIENT-PROOFS.md) identifies the Lean proof terms behind the substantial cited mathematical inputs. The final theorem has no unproved bibliographic or transfer premise. See [fresh imported-environment verification](verification/FRESH-REPLAY-STATUS.md) for the exact command, successful receipt, source-based replay semantics, and limits.

The `--fresh` command is the stronger imported-environment check and can use more time and memory than a normal module check. Run it after building the acceptance library. It remains distinct from the theorem-type and recursive-axiom audits; it replays the loaded safe/non-partial environment with the same Lean kernel and accepts declared axioms separately.
