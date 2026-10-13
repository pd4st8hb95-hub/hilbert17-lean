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
