# Source attribution and paired field transfer

The project-specific transfer layer turns existing univariate real-algebraic
tools into coefficient-preserving comparison theorems for two real closed
fields, then connects those theorems to the Artin ordering argument. This is an
account of source organization and proof dependencies, not a claim of
mathematical novelty or priority.

## Adapted infrastructure

The substantial upstream infrastructure comes from
[TauCeti at commit 6b896c7c411221eb78639e4be8ead6e479a62893](https://github.com/TauCetiProject/TauCeti/tree/6b896c7c411221eb78639e4be8ead6e479a62893):

- Signed principal subresultants, their compatibility with coefficient maps,
  and the Sturm–Tarski formulas expressing root counts and Tarski queries as
  permanences minus variations
- BKR sign determination, including
  `Polynomial.fullInverse_mulVec_tarskiQuery`, which recovers root sign-pattern
  counts from a finite collection of Tarski queries
- Generic real-closed-field polynomial IVT, Rolle, sign constancy, and finite
  whole-line sampling by roots, derivative roots, and two exterior points
- The ordered real-closure construction
  `TauCeti.RealClosure.exists_realClosure`

Mathlib supplies the underlying algebra, localization, polynomial, finite-set,
and order APIs. Selected newer Mathlib support was backported under
`TauCeti.Compat`. Compatibility edits, retained subsets, and short API adapters
do not transfer authorship of the upstream proofs to this project. The retained
licenses, source manifests, and per-file records give the precise provenance.

## Project-specific coefficient projections

The central interface is
`exists_signs_map_iff_of_wholeLineProjection_sign_agree` in
`UniformOneVariable.lean`. For a finite family `Q : J → A[X]`, where `A` is any
commutative ring, `wholeLineProjection Q : Finset A` is constructed independently
of either target field. For arbitrary ring homomorphisms `f : A →+* K` and
`g : A →+* L` into ordered real closed fields, agreement on those finitely many
signs implies equivalence of simultaneous sign-pattern realization.

Neither coefficient map is required to be injective. This matters in the later
induction: partial evaluation maps from multivariate polynomial rings generally
have kernels. The finite projections use elements of the original coefficient
ring rather than parameters chosen in either target field.

The construction has four stages:

1. `CoefficientSignPattern.lean` and `UniformRootCount.lean` use coefficient
   signs to synchronize zero specialization, actual degree, leading-coefficient
   sign, and parity-dependent tail sign. A finite union over possible degrees
   includes signed subresultants of the appropriate `reductum`. Thus coefficients
   killed by specialization do not invalidate a fixed-degree calculation.
2. `MonicQueryProjection.lean` uses the remainder of `p.derivative * q` modulo a
   source-monic `p`; monic division commutes with arbitrary coefficient maps.
   Coefficient tests and a finite union over remainder degrees handle its degree
   drops. `DegreeNormalization.lean` and `GeneralQueryProjection.lean` extend
   this to general `p`: for each possible degree `d`, localize at `c = p.coeff d`
   and normalize its truncation to be monic. Both specialized values of `c` are
   proved nonzero before constructing the localization maps. Nonzero scalar
   normalization preserves the root set and Tarski query.
3. `LocalizationSignDescent.lean` returns the finite localization data to `A`.
   Each requested localized element has a chosen numerator and a denominator
   that is a power of `c`; their signs are controlled by the numerator and `c`.
   The construction accommodates trivial inactive localizations without a
   global nontriviality assumption. `GeneralPatternProjection.lean` then unions
   query projections over BKR exponent vectors `J → Fin 3` and applies the
   upstream reconstruction theorem.
4. `WholeLineAlternatives.lean` reformulates upstream sampling as root,
   derivative-root, and two tail-sign alternatives. `UniformOneVariable.lean`
   unions the needed projections over every possible subset of nonzero input
   polynomials. Coefficient tests synchronize that active subset between the
   fields. Zero inputs, constant inputs, and empty families are included.

The zero-polynomial distinction is explicit: `roots 0` is an empty multiset in
the library, although evaluation of the zero polynomial vanishes everywhere.
Root-set counting is not silently identified with unrestricted zero-set
existence in that branch.

## Multivariate transfer and the final connection

`FiniteVariableTransfer.lean`, supported by `FinSuccEvaluation.lean`, inducts on
the number of variables. `finSuccEquiv` exposes one variable over the remaining
polynomial coefficient ring. The finite one-variable projection stays in that
ring; the induction hypothesis transfers its signs before the omitted
coordinate is chosen. The resulting `exists_signs_eval₂_iff` compares finite
sign systems whenever the two base coefficient maps agree on all signs.

`RealClosureTransfer.lean` embeds an arbitrary ordered extension into its proved
ordered real closure, preserves a negative evaluation along the strict
embedding, and applies multivariate sign transfer back to the real-closed base.
This constructs `Hilbert17.NegativePointTransfer R`, which the separate
`ConditionalArtin.lean` ordering/SOS argument consumes. It is not an extra axiom
or an undischarged assumption of the final real target.

The generic transfer uses no Archimedean or order-completeness hypothesis and
does not invoke same-model quantifier elimination or CAD as a transfer
principle. Exact compiled-source hashes, axiom diagnostics, and replay scope
belong to the verification receipts; historical draft comments are not the
verification record.
