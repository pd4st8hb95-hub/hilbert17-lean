# Attribution and license scope

`RealInstance.lean` adapts `TauCeti/FieldTheory/IsRealClosed/Real.lean` by Kim Morrison, copyright (c) 2026 Lean FRO, LLC, from TauCeti commit `6b896c7c411221eb78639e4be8ead6e479a62893`.

- [Pinned original source](https://github.com/TauCetiProject/TauCeti/blob/6b896c7c411221eb78639e4be8ead6e479a62893/TauCeti/FieldTheory/IsRealClosed/Real.lean)
- [Exact archived original](upstream/TauCeti-Real.lean)
- [Exact upstream Apache 2.0 license](LICENSE)
- [Machine-readable provenance and hashes](PROVENANCE.json)

The adaptation changes imports for the older pinned Mathlib, places the results in `Hilbert17Transfer`, and exposes a theorem for explicit local instance installation. Its source retains the original copyright and authorship header. No upstream `NOTICE` file was found at the pinned repository root.

Mathlib is a pinned external dependency rather than vendored source. Its [Apache 2.0 license](licenses/mathlib-Apache-2.0.txt) is preserved for reference; dependency authorship and licenses remain with their respective upstream projects.

The included Apache license is preserved for the attributed upstream material. This packaging step does not assign a new project-wide license to the original local contributions.

## Ordered real-closure backport

The seven TauCeti source modules are adapted from the same pinned TauCeti revision, with original Kim Morrison / Lean FRO attribution retained. See [real-closure provenance](provenance/realclosure.json) for exact upstream paths, hashes and all compatibility changes. The [exact Apache 2.0 license](licenses/TauCeti-realclosure-Apache-2.0.txt) is included. These sources implement the classical Artin–Schreier real-closure construction.

## Transfer, real-closed-field characterization, and sign determination

The TauCeti transfer dependency backports retain original per-file authorship and Apache-2.0 headers from commit `6b896c7c411221eb78639e4be8ead6e479a62893`. Exact fetched originals and their Git blob/SHA-256 pins are preserved in [the upstream manifest](provenance/upstream-transfer-source-manifest.json) and `upstream/transfer/`. The one ordering-extension entry in that fetched manifest is explicitly a previously checked local adapter rather than an exact upstream blob. The [upstream Apache license](licenses/TauCeti-transfer-Apache-2.0.txt) is included.

`TauCeti.Compat.ListSignVariations`, `SturmSequence`, and `FieldDivisionExtra` adapt official Mathlib source at `3b531c35df33d6bbe64b4e87dec056211d3a5676`; original source snapshots appear in `upstream/mathlib-newer/`. `QuadraticDiscriminant` and `QuadraticExtension` replace newer classification-based arguments with local proofs using the pinned library's quadratic formula and minimal-polynomial APIs. The original Xavier Roblot attribution is retained; the direct replacement proof bodies are local compatibility work. No Mathlib source file or namespace is overridden.

The additional real-closed-field chain is generic: the concrete real/complex comparison portion was omitted from `Complexification`, and a direct generic square proof takes its place. Galois helpers replace missing newer group-index APIs. The remaining adaptations include legacy module syntax, import-path/API renames, and elaboration repairs. Final source hashes and module-specific origins are recorded in `final-source-manifest.json` and `provenance/transfer-adaptations.json`. The proof map describes mathematical provenance without a novelty or first-formalization claim.
