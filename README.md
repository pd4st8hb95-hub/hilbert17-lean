# Hilbert's seventeenth problem in Lean: partial development

**The complete Hilbert-seventeenth theorem is not proved in this repository.**

This baseline contains ten compiled project modules, selected-module Lean kernel replays, and an axiom audit of 57 named declarations. The final Artin assembly still requires the explicit, unproved hypothesis `Hilbert17.NegativePointTransfer ℝ`. A clean axiom audit of that conditional theorem does not discharge its hypothesis.

## Full target

For every natural number `n` and every real-coefficient polynomial `f : MvPolynomial (Fin n) ℝ`, if `f` is nonnegative at every real point, its image in `FractionRing (MvPolynomial (Fin n) ℝ)` should be a finite sum of squares.

Equivalently, there should exist a nonzero polynomial `q`, a natural number `m`, and polynomials `p : Fin m → MvPolynomial (Fin n) ℝ` such that

```lean
q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2
```

The specification includes all finite numbers of variables, including zero, arbitrary real coefficients, and nonnegative rather than only strictly positive polynomials. It requires the denominator to be nonzero as a polynomial; it need not be nonzero at every point. See [TargetSpec.lean](TargetSpec.lean).

## What is established

- [ClearDenominators.lean](ClearDenominators.lean): equivalence between rational-function SOS and a common nonzero square-denominator certificate, including an explicit finite list of numerators
- [FractionSemireal.lean](FractionSemireal.lean): the fraction field of a polynomial ring over an ordered field is semireal
- [OrderingSeparation.lean](OrderingSeparation.lean): extension of preorderings and the characterization of field sums of squares by nonnegativity in every ordering
- [RealInstance.lean](RealInstance.lean): the real numbers are real closed
- [CoefficientOrder.lean](CoefficientOrder.lean): coefficient embeddings from an ordered real-closed field preserve its order
- [LocalizationSignDescent.lean](LocalizationSignDescent.lean): a finite denominator-clearing lemma for signs under coefficient specialization
- [TargetSanity.lean](TargetSanity.lean): the complete zero-variable case and already-polynomial-SOS cases
- [CertificateNonnegative.lean](CertificateNonnegative.lean): rational SOS certificates imply nonnegativity everywhere, including denominator zeros
- [ConditionalArtin.lean](ConditionalArtin.lean): the full requested implication **conditional on negative-point transfer**

The remaining hypothesis says: if a polynomial over the base ordered field has a negative value in an ordered extension, it has a negative value in the base field. The package does not provide a proof of this hypothesis. In particular, the principal exported result has the shape

```lean
Hilbert17.hilbert17Real_of_negativePointTransfer
  (htransfer : Hilbert17.NegativePointTransfer ℝ) :
  Hilbert17Target.Hilbert17Real
```

An ordered real-closure construction and uniform real-closed-field transfer are further work. They are not included as established results in this baseline.

## Pinned build

- Lean: `leanprover/lean4:v4.32.1`
- Mathlib: [`520045ab14e26149ee970e2e617ca04b09bde5d6`](https://github.com/leanprover-community/mathlib4/tree/520045ab14e26149ee970e2e617ca04b09bde5d6)
- Entry point: [Hilbert17.lean](Hilbert17.lean)

The Lake configuration uses a Git dependency pinned to that exact revision. The lockfile also records the inherited package revisions. There are no machine-local dependency paths or bundled caches.

With the pinned toolchain available, run from the repository root:

```sh
lake exe cache get
lake build Hilbert17
lake env lean checks/ConditionalArtinAxioms.lean
```

The cache step uses Mathlib's cache tooling and network access; it is optional if building dependencies from source. These are reproduction instructions, not a claim that a fresh checkout build has already been run. See the current [verification status](verification/STATUS.md).

## Verification limits

The ten included module files are byte-for-byte copies of the successfully compiled sources. Their hashes and receipts are in [source-manifest.json](source-manifest.json). Selected-module replay uses the same Lean kernel with imported dependencies, not an independent verifier or fresh replay of every transitive Mathlib declaration. The 57 selected declarations use only `propext`, `Classical.choice`, and `Quot.sound` in their printed recursive axiom lists; no `sorryAx` or new project axiom occurs in those audited lists.

Some source headers retain their original drafting-time “source-only” comments to preserve exact source hashes. The dated verification receipts document subsequent checks. They do not upgrade any conditional theorem to an unconditional one.

See [failed attempts](verification/FAILED-ATTEMPTS.md) for preserved diagnostics and [third-party attribution](THIRD_PARTY.md) for licensing and provenance.
