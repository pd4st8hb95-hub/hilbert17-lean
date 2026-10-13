# Formal proofs of the external mathematical ingredients

## Conclusion and verification scope

The final real-coefficient Hilbert 17 theorem does not take a bibliographic
theorem, a real-closure existence principle, a Rolle principle, a matrix
invertibility claim, or a transfer principle as an unproved parameter or axiom.
The ingredients below have Lean proof terms. Reusable intermediate theorems
sometimes expose mathematical hypotheses; their uses in the final argument
supply proofs of those hypotheses.

The existing `final-all-local-checker01-run01/summary.json` records **97 selected
local module replays, all PASS**. On 2026-10-13 the source hashes recorded in all
97 entries were rechecked against the current files and all matched. The
recursive axiom lists for
`Hilbert17Transfer.negativePointTransfer_of_isRealClosed`,
`Hilbert17Transfer.hilbert17Real_candidate`, and
`Hilbert17Transfer.hilbert17RealCleared_candidate` contain exactly `propext`,
`Classical.choice`, and `Quot.sound`. The wider final diagnostic audit records
17 standard-only lists. This is classical Lean mathematics, not an axiom-free
claim. Same-kernel local replay uses the imported pinned library; it is not a
fresh replay of every transitive Mathlib declaration or an independent proof
checker.

The companion `EXTERNAL-INGREDIENT-MAP.json` gives exact source paths, module
names, declarations, provenance, current source hashes, and local replay status.
It is a source-level map of the substantial ingredients, not a minimal
declaration-level dependency graph.

## Provenance categories

- **T**: locally verified adaptation of
  [TauCeti commit 6b896c7c411221eb78639e4be8ead6e479a62893](https://github.com/TauCetiProject/TauCeti/tree/6b896c7c411221eb78639e4be8ead6e479a62893)
- **P**: project proof or project compatibility proof, locally compiled and
  replayed; upstream attribution is retained where an API was adapted
- **M**: proved theorem imported from
  [Mathlib commit 520045ab14e26149ee970e2e617ca04b09bde5d6](https://github.com/leanprover-community/mathlib4/tree/520045ab14e26149ee970e2e617ca04b09bde5d6)
- **B**: locally compiled and replayed backport of selected proved support from
  [Mathlib commit 3b531c35df33d6bbe64b4e87dec056211d3a5676](https://github.com/leanprover-community/mathlib4/tree/3b531c35df33d6bbe64b4e87dec056211d3a5676)

## Ordered real closure and Artin–Schreier separation

1. **Separation by field orderings — P.** In `OrderingSeparation`,
   `Hilbert17.RingPreordering.exists_ordering_extension` and
   `exists_ordering_not_mem` are proved by adjoining a generator to a proper
   preordering, taking chain unions, and applying Zorn. The resulting
   `isSumSq_iff_nonneg_all_orders` is the precise Artin–Schreier separation
   statement used by `Hilbert17.rationalSOS_of_negativePointTransfer`.
   Its foundational maximality result is the proved
   `zorn_le_nonempty_Ici₀` in `Mathlib.Order.Zorn` (**M**).
   `TauCeti.Algebra.Order.Ring.Ordering.Extension` is a **P** adapter to these
   proofs, including `RingPreordering.exists_linearOrder`.

2. **Existence of an ordered algebraic real closure — T.**
   `TauCeti.RealClosure.exists_realClosure` in
   `TauCeti.FieldTheory.RealClosure.Basic` constructs an ordered real closed
   field in the base universe with a strictly monotone embedding. Its proof
   uses `OrderedIntermediateField.exists_isMax`,
   `OrderedIntermediateField.isSquare_of_isMax`, and
   `OrderedIntermediateField.exists_isRoot_of_isMax`. Order-preserving extension
   steps are proved as `QuadraticAlgebra.exists_linearOrder` in `OrderExtension`
   and `AdjoinRoot.exists_linearOrder` in `OddExtension`. These are genuine
   proof bodies, not invocations of the Kuhlmann lecture references in comments.

3. **Algebraic closure supporting that construction — M.**
   `AlgebraicClosure.isAlgClosed` and `AlgebraicClosure.isAlgebraic` are proved
   instances in `Mathlib.FieldTheory.IsAlgClosed.AlgebraicClosure`.
   `IsAlgClosed.lift`, in `Mathlib.FieldTheory.IsAlgClosed.Basic`, constructs the
   algebraic embeddings used by the maximality argument. Thus the ambient
   algebraically closed field is also supplied formally.

4. **Semireality of the rational-function field — P.**
   `Hilbert17.isSemireal_mvPolynomial_fraction` in `FractionSemireal` clears a
   hypothetical sum of squares equal to `-1`, then evaluates away from a
   nonzero common denominator. The nonzero-evaluation step uses the proved
   `MvPolynomial.funext` in `Mathlib.Algebra.MvPolynomial.Funext` (**M**).
   Semireality is not left as a hypothesis of the real Hilbert 17 target.

## Real closed field polynomial IVT and Rolle

5. **Irreducible polynomials have degree at most two — T with P compatibility.**
   `Polynomial.natDegree_le_two_of_irreducible` in
   `TauCeti.FieldTheory.RealClosure.AlgebraicClosed` is proved via
   `TauCeti.RealClosure.isAlgClosed_of_forall_isSquare` and the proved scoped
   instance `isAlgClosed_quadraticAlgebra`. The square-closedness argument is
   supplied by `QuadraticAlgebra.isSquare` in `Complexification`, a **P** minimal
   adapter using the **T** proof
   `QuadraticAlgebra.isSquare_of_forall_nonneg_isSquare` in
   `TauCeti.Algebra.QuadraticAlgebra.Square`.

6. **The finite-extension and Sylow argument behind that degree bound — T/P/M.**
   `TauCeti.RealClosure.finrank_eq_one_of_odd` in `FiniteExtension` and
   `isPGroup_two_algEquiv`, `finrank_eq_one_of_isPGroup`, and
   `finrank_eq_one_of_isGalois_of_forall_isSquare` in `Galois` have local proofs.
   Their **M** ingredients include `Field.exists_primitive_element`,
   `Field.primitive_element_iff_minpoly_natDegree_eq`,
   `IsGalois.card_aut_eq_finrank`,
   `IntermediateField.finrank_fixedField_eq_card`, `Sylow.not_dvd_index`, and
   `Sylow.exists_subgroup_card_pow_prime`.
   The **P** compatibility theorem
   `TauCeti.Compat.finrank_ne_two_of_forall_isSquare` is proved using minimal
   polynomials and the pinned quadratic formula `exists_quadratic_eq_zero`;
   no quadratic-extension classification is postulated.

7. **Polynomial IVT — T.** In `TauCeti.FieldTheory.RealClosure.IVT`,
   `Polynomial.eval_mul_pos_of_no_roots` is proved by irreducible factorization
   and the degree-one/degree-two cases. It yields
   `Polynomial.exists_root_Ioo_of_mul_neg` and the other IVT formulations.
   The assumptions are an ordered real closed field, without order completeness
   or an Archimedean hypothesis.

8. **Polynomial Rolle — T.** In
   `TauCeti.FieldTheory.RealClosure.AbstractRolle`,
   `Polynomial.exists_derivative_root_of_isRoot` removes endpoint root
   multiplicities and applies the proved polynomial IVT to a derivative factor.
   `TauCeti.RealClosure.polynomialRolle_of_isRealClosed` then proves the
   `TauCeti.PolynomialRolle` predicate. Consequently the general lemmas in
   `TauCeti.Algebra.Polynomial.Rolle` do not leave a Rolle premise unresolved in
   the final proof.

9. **Sign constancy and finite sampling — T.**
   `Polynomial.sign_eval_const` in
   `TauCeti.Algebra.Polynomial.RealClosed.Sign`,
   `Polynomial.exists_mem_signSamples` in `RealClosed.Sampling`, and
   `TauCeti.SignDetermination.exists_mem_signSamples_sign_eq` in
   `TauCeti.Geometry.RealAlgebraic.SignDetermination.WholeLine` formally prove
   that roots, derivative roots, and exterior points capture every finite
   whole-line sign pattern. The local `WholeLineAlternatives` reformulates this
   proved sampling result for paired-field comparison.

## Sturm–Tarski subresultants and BKR

10. **Sturm–Tarski identity — T.**
    `Polynomial.cauchyIndex_derivative_mul_univ` in
    `TauCeti.Algebra.Polynomial.Sturm.CauchyIndex.Basic` proves the link between
    a Tarski query and the Cauchy index of `p' * q / p`.
    `Polynomial.cauchyIndex_eq_sub_signVariations_univ` in `CauchyIndex.Sequence`
    proves the Sturm variation formula. The signed remainder sequence and list
    sign-variation support are **B** modules `TauCeti.Compat.SturmSequence` and
    `TauCeti.Compat.ListSignVariations`; they contain proofs, not externally
    evaluated certificates.

11. **Subresultant computation of the query — T.**
    `Polynomial.tarskiQuery_eq_permanencesMinusVariations_signedPsc` in
    `TauCeti.RingTheory.Polynomial.Subresultant.CauchyIndex` is the exact query
    theorem used by `MonicQueryProjection`. Its proof uses
    `cauchyIndex_univ_eq_permanencesMinusVariations_signedPsc_mod`, whose
    Euclidean reduction is proved from the determinant/subresultant identities
    in `Subresultant.Euclidean`, including
    `Polynomial.signedPsc_eq_mul_signedPsc_neg_mod`.
    Subresultants themselves are defined by explicit coefficient matrices and
    determinants; the cited BPR material is not an oracle.

12. **Specialization and degree drops — T plus P assembly.**
    `Polynomial.psc_map_map` in `Subresultant.Basic` and
    `Polynomial.signedPsc_map_map` in `Subresultant.Signed` prove naturality at
    fixed degree bounds under arbitrary ring homomorphisms, including
    noninjective maps. `Subresultant.DegreeDrop.Basic` and
    `Subresultant.Euclidean` prove the degree-drop and remainder identities.
    The **P** projection layer tests source coefficients, branches over all
    possible specialized degrees, and treats zero specialization separately.
    Its denominator step uses the proved `IsLocalization.Away.sec_spec` in
    `Mathlib.RingTheory.Localization.Away.Basic` and monic specialization uses
    `Polynomial.map_modByMonic` in `Mathlib.Algebra.Polynomial.Div` (**M**).

13. **BKR sign determination — T.** The exact theorem consumed is
    `Polynomial.fullInverse_mulVec_tarskiQuery` in
    `TauCeti.Geometry.RealAlgebraic.SignDetermination.Roots`. The inverse is
    explicitly defined over `ℚ`; `TauCeti.SignDetermination.fullInverse_mul_fullMatrix`
    in `SignDetermination.Moments` proves it is an inverse by finite products
    of `SignType.sum_lagrangeCoeff_mul_pow` in `TauCeti.Data.SignType.Lagrange`.
    Thus neither an inverse matrix nor a coverage/correctness theorem from a
    BKR paper is assumed. Generic matrix lemmas with such premises are backed
    here by these explicit finite proofs.

## Ordered coefficients and closing every transfer hypothesis

14. **Compatibility with the original coefficient order — P/M.**
    `Hilbert17Transfer.ringHom_monotone` and `ringHom_strictMono` in
    `CoefficientOrder` prove that any ring map from an ordered real closed field
    to an ordered field preserves its order. They use the proved
    `IsRealClosed.nonneg_iff_isSquare` / `IsSquare.of_nonneg` in
    `Mathlib.FieldTheory.IsRealClosed.Basic` and injectivity of field maps.

15. **The actual real field is real closed — T adaptation using M.**
    `Hilbert17Transfer.real_isRealClosed` in `RealInstance` supplies the final
    real-closedness instance. It proves the odd-degree root property and uses
    `Real.isSquare_iff` from `Mathlib.Analysis.Real.Sqrt`, the proved real
    polynomial sign results in `Mathlib.Analysis.Polynomial.Order`, and
    `IsRealClosed.of_linearOrderedField`. Analytic facts are used for the
    particular field `ℝ`, not imposed on the arbitrary target fields.

16. **Paired-field transfer and final assembly — P.**
    `Hilbert17Transfer.exists_signs_map_iff_of_wholeLineProjection_sign_agree`
    (`UniformOneVariable`) and `exists_matching_signs_eval₂`
    (`FiniteVariableTransfer`) prove coefficient-preserving sign transfer.
    `negativePointTransfer_of_isRealClosed` (`RealClosureTransfer`) combines
    that proof with `TauCeti.RealClosure.exists_realClosure`.
    Finally `hilbert17Real_candidate` and `hilbert17RealCleared_candidate`
    supply this proved value to the conditional Artin reduction. Their types
    are the original unconditional targets. The intermediate
    `NegativePointTransfer` definition is neither an axiom nor a remaining
    premise, and no same-model QE theorem or CAD transfer claim is used.

Bibliographic citations in the source identify mathematical background and
attribution. They occur in comments and do not substitute for any proof term
in this chain. The final recursive axiom diagnostics and explicit final types
are the checks that no additional mathematical axiom or undisclosed theorem
parameter survives the assembly.
