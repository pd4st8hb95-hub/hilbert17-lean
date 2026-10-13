# Hilbert seventeenth: proof map and provenance

**Verification status: the exact full theorem is verified in the pinned
runtime.** The end-to-end source assembly, expanded theorem types, recursive
axiom lists, and all 97 selected local module replays passed the checks recorded
below. Replay uses the same pinned Lean kernel against imported dependencies;
it is not an external independent verifier or full transitive dependency
replay. **Portable offline Lake integration also passes.** An additional fresh
transitive imported-environment replay remains pending as a separate stronger check.

## Exact target

For every natural number `n` and every
`f : MvPolynomial (Fin n) ℝ`, if `f(x) ≥ 0` for every real tuple `x`, then the
image of `f` in `FractionRing (MvPolynomial (Fin n) ℝ)` is a finite sum of
squares. Equivalently, there are a nonzero polynomial `q`, a natural number
`m`, and polynomials `p₀, …, pₘ₋₁` such that

\[
q^2 f = \sum_{i<m} p_i^2.
\]

`q ≠ 0` means that `q` is not the zero polynomial; it does **not** require
`q(x) ≠ 0` at every point. The target includes `n = 0` and allows an empty
sum. The exact propositions are `Hilbert17Target.Hilbert17Real` and
`Hilbert17Target.Hilbert17RealCleared` in
`TargetSpec.lean`.

## The argument

### 1. Clear denominators and establish semireality

`ClearDenominators.lean`
proves, for a domain `A` with fraction field `F`, that the image of `f : A`
is a sum of squares precisely when `q²f` is a sum of squares in `A` for some
`q ≠ 0`. It also converts `IsSumSq` to an explicitly indexed finite sum.

`FractionSemireal.lean`
applies this to `f = -1`. A nonzero polynomial over an ordered field has some
nonzero evaluation, since ordered fields are infinite. Evaluating a purported
sum-of-squares identity for `-q²` at that point gives a contradiction.
Consequently, the rational-function field is semireal. This argument uses
one suitable evaluation, not a globally nonvanishing denominator.

### 2. Separate sums of squares by field orderings

`OrderingSeparation.lean`
constructs extensions of proper preorderings, takes unions of chains, and
uses Zorn's lemma to obtain an ordering. It proves that, in a semireal field,
an element is a sum of squares if and only if it is nonnegative in every
compatible field order. Thus it suffices to rule out an ordering in which
the rational-function image of `f` is negative.

The coefficient embedding from a real closed ordered field preserves order:
nonnegative coefficients are squares, and a field homomorphism is injective.
`CoefficientOrder.lean` makes
this compatibility explicit rather than assuming an arbitrary ordering of
the rational-function field extends the coefficient order.

### 3. Pass to an ordered real closure

`TauCeti.RealClosure.exists_realClosure` constructs, for any ordered field
`K`, a real closed ordered extension `L` and a strictly increasing field
embedding `K → L`. The local
`TauCeti.FieldTheory.RealClosure.Basic` backport
uses maximal ordered intermediate fields, quadratic extensions, and odd-degree
extensions. The construction is a proved theorem, not a new axiom.

The negative value of `f` at the tuple of rational-function variables remains
negative in `L`. Its coefficients are carried by the same composed embedding.

### 4. Transfer finite sign conditions with their coefficients fixed

The project transfer modules build a paired-field
transfer argument over a common coefficient ring. The essential uniformity
is that each finite projection set is chosen in the **original coefficient
ring before either target field or specialization map is supplied**.

* `UniformRootCount` and `MonicQueryProjection` use signed subresultants and
  Sturm–Tarski queries to control root counts and sign sums.
* `DegreeNormalization`, `LocalizationSignDescent`, and
  `GeneralQueryProjection` handle every possible specialized degree, descend
  localization coefficients back to the original ring, and treat the zero
  specialization separately.
* `GeneralPatternProjection` uses the finite sign-determination moment
  inversion (the Ben-Or–Kozen–Reif method) to recover root sign-pattern counts.
* `WholeLineAlternatives` and `UniformOneVariable` combine roots, derivative
  roots, and the two signs at infinity. A finite union over active subsets
  handles polynomials that become zero after specialization.
* `FiniteVariableTransfer` inducts on the number of variables, applying the
  one-variable projection to a finite family over the smaller polynomial ring.

These interfaces allow noninjective coefficient specializations and arbitrary
ordered real closed target fields. They use no Archimedean or completeness
assumption. In particular, a negative value over `L` descends to a negative
value over the original real closed coefficient field.

### 5. Conclude Artin's sum-of-squares statement

`ConditionalArtin.lean`
isolates precisely this negative-point descent as `NegativePointTransfer`.
Such descent contradicts the assumed pointwise nonnegativity of `f`, so `f`
is nonnegative in every ordering of its fraction field. Step 2 gives a
rational sum of squares; step 1 gives the explicit cleared identity.

`RealClosureTransfer.lean`
assembles steps 3–4 to discharge the transfer input and specializes the
argument to `ℝ`, using `RealInstance.lean`. The current final declarations are
`Hilbert17Transfer.hilbert17Real_candidate` and
`Hilbert17Transfer.hilbert17RealCleared_candidate`. These identifiers retain
their source-draft suffix; their full unconditional statements have passed
the verification checks below. `Hilbert17Full` is the import entry point.

## Attribution and adaptation boundaries

* **Pinned foundation:** Lean `4.32.1` and Mathlib
  `520045ab14e26149ee970e2e617ca04b09bde5d6`.
* **TauCeti:** the ordered-real-closure construction, generic real-closed-field
  characterization and polynomial IVT/Rolle, sampling, Sturm–Tarski,
  subresultant, and sign-determination infrastructure are adapted from
  [TauCeti commit `6b896c7c411221eb78639e4be8ead6e479a62893`](https://github.com/TauCetiProject/TauCeti/tree/6b896c7c411221eb78639e4be8ead6e479a62893).
  Original authorship and Apache-2.0 notices are retained. The exact source
  inventory is recorded in `provenance/upstream-transfer-source-manifest.json`;
  real-closure adaptations are recorded in `provenance/realclosure.json`.
* **Newer Mathlib:** compatibility modules `ListSignVariations`,
  `SturmSequence`, and `FieldDivisionExtra` adapt the corresponding official
  Mathlib sources at
  [`3b531c35df33d6bbe64b4e87dec056211d3a5676`](https://github.com/leanprover-community/mathlib4/tree/3b531c35df33d6bbe64b4e87dec056211d3a5676).
  The missing newer quadratic-algebra classification imports were instead
  replaced by local `TauCeti.Compat.QuadraticDiscriminant` and
  `QuadraticExtension` proofs using pinned quadratic and minimal-polynomial
  APIs. These replacements retain the original field/characteristic-not-two
  scope; they are not copies of those entire newer Mathlib modules.
* **Project-specific glue:** denominator clearing, fraction-field semireality,
  ordering separation, and the explicit coefficient-preserving uniform
  projection/finite-variable transfer assembly connect those ingredients to
  the exact target. Compatibility edits include old API names, legacy module
  imports, and explicit replacement proofs where the pinned library lacks a
  later lemma. This is an implementation of classical mathematics; no claim
  of new mathematics or first formalization is made.

Compilation, named type/axiom inspection, and selected same-kernel replay are
separate verification layers. Only their recorded scope should be reported;
source inspection or successful checks of a proper subset do not establish
the end-to-end result.

### Recorded scope: 2026-10-13, 14:22 UTC

* `verification/transfer-runs/transfer-candidates07-run01/summary.json`: both
  `FiniteVariableTransfer` and `RealClosureTransfer` compiled successfully,
  completing the previously compiled algebraic and one-variable dependencies.
* `verification/transfer-runs/final-hilbert17-contract01-run01/summary.json`:
  `FinalHilbert17Axioms`, `FinalTargetContract`, and `BoundaryAcceptance` all
  passed. The expanded conclusions include explicit finite rational squares
  and the common-denominator polynomial identity, with no residual transfer
  premise. Boundary checks include the zero polynomial and zero variables.
  The final theorem axiom lists contain only `propext`, `Classical.choice`,
  and `Quot.sound`.
* `verification/transfer-runs/final-entry01-run01/summary.json`: `Hilbert17Full` compiled.
* `verification/transfer-runs/final-all-local-checker01-run01/summary.json`: all 97 selected
  local module replays passed. The terminal receipt has SHA256
  `2aa36ecc2517d0b8726cff58b39d0b5ccacb1d98f12a421b5ac52a25af8dfcd0`.

The 27-name quadratic/characterization/IVT/Rolle audit is additionally
reconciled in `verification/rcf-characterization-axiom-result01.json`. These records certify
the stated mathematical result in the pinned runtime. They do not by
themselves establish a clean, portable Lake build in another environment;
the separate offline Lake check has since passed, with exact scope in
`verification/PORTABLE-LAKE-STATUS.md`. Fresh online checkout reproduction is not claimed.
