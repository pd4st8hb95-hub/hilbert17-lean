# Attribution and license scope

`RealInstance.lean` adapts `TauCeti/FieldTheory/IsRealClosed/Real.lean` by Kim Morrison, copyright (c) 2026 Lean FRO, LLC, from TauCeti commit `6b896c7c411221eb78639e4be8ead6e479a62893`.

- [Pinned original source](https://github.com/TauCetiProject/TauCeti/blob/6b896c7c411221eb78639e4be8ead6e479a62893/TauCeti/FieldTheory/IsRealClosed/Real.lean)
- [Exact archived original](upstream/TauCeti-Real.lean)
- [Exact upstream Apache 2.0 license](LICENSE)
- [Machine-readable provenance and hashes](PROVENANCE.json)

The adaptation changes imports for the older pinned Mathlib, places the results in `Hilbert17Transfer`, and exposes a theorem for explicit local instance installation. Its source retains the original copyright and authorship header. No upstream `NOTICE` file was found at the pinned repository root.

Mathlib and its required package source slices are now vendored under `vendor/`, with local relative-path build configurations. The exact pinned sources, licenses, source headers, and original upstream configuration/provenance are retained as described below. The earlier [Mathlib Apache 2.0 license copy](licenses/mathlib-Apache-2.0.txt) is also preserved. Dependency authorship and licenses remain with their respective upstream projects.

The included Apache license is preserved for the attributed upstream material. This packaging step does not assign a new project-wide license to the original local contributions.

## Ordered real-closure backport

The seven TauCeti source modules are adapted from the same pinned TauCeti revision, with original Kim Morrison / Lean FRO attribution retained. See [real-closure provenance](provenance/realclosure.json) for exact upstream paths, hashes and all compatibility changes. The [exact Apache 2.0 license](licenses/TauCeti-realclosure-Apache-2.0.txt) is included. These sources implement the classical Artin–Schreier real-closure construction.

## Transfer, real-closed-field characterization, and sign determination

The TauCeti transfer dependency backports retain original per-file authorship and Apache-2.0 headers from commit `6b896c7c411221eb78639e4be8ead6e479a62893`. Exact fetched originals and their Git blob/SHA-256 pins are preserved in [the upstream manifest](provenance/upstream-transfer-source-manifest.json) and `upstream/transfer/`. The one ordering-extension entry in that fetched manifest is explicitly a previously checked local adapter rather than an exact upstream blob. The [upstream Apache license](licenses/TauCeti-transfer-Apache-2.0.txt) is included.

`TauCeti.Compat.ListSignVariations`, `SturmSequence`, and `FieldDivisionExtra` adapt official Mathlib source at `3b531c35df33d6bbe64b4e87dec056211d3a5676`; original source snapshots appear in `upstream/mathlib-newer/`. `QuadraticDiscriminant` and `QuadraticExtension` replace newer classification-based arguments with local proofs using the pinned library's quadratic formula and minimal-polynomial APIs. The original Xavier Roblot attribution is retained; the direct replacement proof bodies are local compatibility work. No Mathlib source file or namespace is overridden.

The additional real-closed-field chain is generic: the concrete real/complex comparison portion was omitted from `Complexification`, and a direct generic square proof takes its place. Galois helpers replace missing newer group-index APIs. The remaining adaptations include legacy module syntax, import-path/API renames, and elaboration repairs. Final source hashes and module-specific origins are recorded in `final-source-manifest.json` and `provenance/transfer-adaptations.json`. The proof map describes mathematical provenance without a novelty or first-formalization claim.

## Vendored external Lean source closure

The 97 configured project roots require 3,039 external Lean source files: 2,775
Mathlib files and 264 files from seven other packages. Every selected dependency
Lean file is byte-identical to the Git blob at its pinned upstream revision.
This packaging does not alter the project's previously checked mathematical
Lean source files. The selection is a transitive whole-file import closure,
including tactic and lint infrastructure, not a full upstream mirror or a
minimal declaration-level proof slice.

The package revisions and retained licenses are:

- **Mathlib**, 2,775 files: [`520045ab14e26149ee970e2e617ca04b09bde5d6`](https://github.com/leanprover-community/mathlib4/tree/520045ab14e26149ee970e2e617ca04b09bde5d6); [Apache 2.0 license](vendor/mathlib/LICENSE), [upstream citation file](vendor/mathlib/CITATION.md)
- **Batteries**, 78 files: [`023ce7d62a0531e22a5331e20b587817a80d49ff`](https://github.com/leanprover-community/batteries/tree/023ce7d62a0531e22a5331e20b587817a80d49ff); [Apache 2.0 license](vendor/batteries/LICENSE)
- **Qq / quote4**, 14 files: [`38d591e778f100aec9762bb582f9c7f55f50e9dc`](https://github.com/leanprover-community/quote4/tree/38d591e778f100aec9762bb582f9c7f55f50e9dc); [Apache 2.0 license](vendor/Qq/LICENSE)
- **Aesop**, 132 files: [`a7dbf0c63b694e47f425f3dcddbc0e178bb432d3`](https://github.com/leanprover-community/aesop/tree/a7dbf0c63b694e47f425f3dcddbc0e178bb432d3); [Apache 2.0 license](vendor/aesop/LICENSE)
- **ProofWidgets4**, 13 files: [`6e311e2a844da9b2cc3971187df2fe0066947b93`](https://github.com/leanprover-community/ProofWidgets4/tree/6e311e2a844da9b2cc3971187df2fe0066947b93); [Apache 2.0 license](vendor/proofwidgets/LICENSE)
- **ImportGraph / import-graph**, 10 files: [`7e9612bf0b9ee66db3cb5b9988a35afc706f5a12`](https://github.com/leanprover-community/import-graph/tree/7e9612bf0b9ee66db3cb5b9988a35afc706f5a12); [Apache 2.0 license](vendor/importGraph/LICENSE)
- **LeanSearchClient**, 4 files: [`c5d5b8fe6e5158def25cd28eb94e4141ad97c843`](https://github.com/leanprover-community/LeanSearchClient/tree/c5d5b8fe6e5158def25cd28eb94e4141ad97c843); [Apache 2.0 license](vendor/LeanSearchClient/LICENSE)
- **Plausible**, 13 files: [`e12c1910fe855cbfc38803cd4e55543906d5fa62`](https://github.com/leanprover-community/plausible/tree/e12c1910fe855cbfc38803cd4e55543906d5fa62); [Apache 2.0 license](vendor/plausible/LICENSE)

See [the machine-readable source manifest](vendor-source-manifest.json) for
per-module paths, imports, SHA256 values, and upstream Git blob identities.
Each `vendor/<package>/UPSTREAM/provenance.json` retains the package origin;
the same directory retains original upstream configs/manifests and toolchain
metadata. Per-file author and copyright notices are unchanged. Cli is outside
this source closure; no selected Lean module imports it.

The active declarative TOML configurations are local adaptations. They replace
remote requirements with relative paths, omit unneeded aggregate/test/executable
targets, disable cache/release downloads, and remove Mathlib's cache-update hook
and ProofWidgets' npm targets. Mathlib's semantic compiler options and weak
linters are preserved. These build adaptations are enumerated in
[VENDORED-BUILD-CONFIG.md](VENDORED-BUILD-CONFIG.md); original configurations in
`UPSTREAM/` remain attribution and reproducibility evidence, not active hooks.

## Compile-time widget assets and the headless Penrose adaptation

The [asset manifest](vendor-asset-manifest.json) records 15 files used by Lean
`include_str`: six Mathlib Penrose text files and nine ProofWidgets JavaScript
files. The six text files and eight JavaScript files are exact pinned upstream
Git blobs. Original TypeScript sources and widget build metadata are retained
under `vendor/proofwidgets/UPSTREAM/widget/` for attribution and provenance;
the archive does not run their npm build.

One JavaScript file, `vendor/proofwidgets/widget/js/penroseDisplay.js`, is an
original Apache-2.0 headless adapter. It replaces the optional bundled Penrose
renderer with a default component that displays an explanatory message. This
disables that editor diagram-rendering feature, not any mathematical theorem.
No Lean proof source or theorem statement is edited, and no proof axiom is
introduced by the adapter. The included string does change. This package has
therefore undergone its own clean source rebuild and fresh imported-environment
replay using the resulting new artifacts; both passed. The exact scope and
receipts are recorded in [the vendored verification report](verification/vendored-source-20261013/VERIFICATION.md).

The replaced 2,663,470-byte renderer is a **tracked upstream file**, verified
against Git blob `59d753a6508b643aad8636e4afdc3df9d5d52596` at the pinned
ProofWidgets revision. It is omitted because complete notice coverage for its
bundled third-party components was not independently verified. Its original
identity and the replacement hash are both recorded in the asset manifest.
Tracked status alone does not establish that separate notice audit. The
excluded renderer is not redistributed by this source package.

`ofRpcMethod.js` includes **react-fast-compare 3.2.2**. Its [MIT license](vendor/proofwidgets/UPSTREAM/react-fast-compare-v3.2.2.LICENSE)
is retained from upstream commit
[`c306521de14d24169077ae1859be373ff21a8818`](https://github.com/FormidableLabs/react-fast-compare/tree/c306521de14d24169077ae1859be373ff21a8818),
with the source URL, Git blob, and SHA256 recorded in the asset manifest.
The smaller widget files retain React and Lean Infoview as external editor
imports; an offline proof build does not rebuild an editor frontend.

This is a recorded source-and-notice preservation effort, not a legal
certification. It does not assign a new project-wide license to original local
contributions or claim new mathematics or a first formalization.
