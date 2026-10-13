# Hilbert’s seventeenth problem in Lean

[中文说明](README.zh-CN.md)

**Hilbert’s seventeenth problem is formally proved in the pinned Lean runtime. Exact theorem contracts, standard-only recursive axiom checks, and all 97 selected local kernel replays pass. Portable offline Lake integration also passes; an additional fresh transitive imported-environment replay is pending separately.**

The target is every finite-variable polynomial with arbitrary real coefficients that is weakly nonnegative at every real point. Its image in the same polynomial ring’s fraction field must be a finite sum of squares. Equivalently, `q ^ 2 * f = ∑ i, (p i) ^ 2` for a polynomial `q ≠ 0`. The denominator is nonzero as a polynomial; it may vanish at individual real points. Zero variables, the zero polynomial, and an empty finite sum are allowed.

The existing ten-module baseline and seven-module real-closure backport have their published checks. `RealClosureTransfer` now proves the unconditional theorem through uniform finite sign-condition transfer, discharging the earlier conditional theorem’s transfer premise. Its exact compiled type and recursive axiom lists have passed independent inspection. All 97 selected local module replays also pass; the portable offline Lake check also passes.

See [the proof map](PROOF-MAP.md), [coefficient-transfer details](TRANSFER-GLUE.md), [final verification status](verification/FINAL-STATUS.md), [the exact acceptance contract](checks/FinalTargetContract.lean), and [third-party attribution](THIRD_PARTY.md). The declaration names are `Hilbert17Transfer.hilbert17Real_candidate` and `Hilbert17Transfer.hilbert17RealCleared_candidate`. The `_candidate` suffixes and drafting-time source-only comments are retained historical identifiers and wording so that checked source bytes remain unchanged. Dated final receipts, rather than those old comments, determine the verified status.

This formalizes the classical theorem using attributed TauCeti and Mathlib infrastructure and project-specific connecting proofs. It makes no claim of new mathematics or first formalization.

## Reproduction

Lean is pinned to `leanprover/lean4:v4.32.1`; Mathlib is pinned to `520045ab14e26149ee970e2e617ca04b09bde5d6`. With that toolchain available, run from the repository root:

```sh
lake exe cache get
lake build Hilbert17 Hilbert17RealClosure Hilbert17Full Hilbert17Acceptance
lake env lean checks/FinalTargetContract.lean
```

The cache step uses Mathlib’s tooling and network access and is optional when building dependencies from source. These are reproduction instructions, not a claim that a fresh online checkout build was executed. No compiled caches are included. The build configuration uses no machine-local dependency paths; historical verification receipts retain their original runtime paths for traceability.

## Evidence and trust scope

The [baseline failure log](verification/FAILED-ATTEMPTS.md), [real-closure status](verification/REALCLOSURE-STATUS.md), and [transfer failure receipts](verification/TRANSFER-FAILED-ATTEMPTS.md) remain available. Sources retain their exact proof headers even where those headers describe an earlier source-only drafting stage. Receipts identify the actual revision checked. The standard classical axioms `propext`, `Classical.choice`, and `Quot.sound` are permitted; a source scan alone does not certify a theorem. Selected replay uses the pinned Lean kernel with imported dependencies, and is not an external independent checker or a claim to replay all transitive Mathlib declarations.

See [portable Lake verification](verification/PORTABLE-LAKE-STATUS.md) for its offline/cached scope, both attempts, and actual acceptance-output comparison. An additional fresh transitive imported-environment replay is pending as a separate stronger check; it is not included in the current 97-module replay claim.
