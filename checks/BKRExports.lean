import TauCeti.Geometry.RealAlgebraic.SignDetermination.Roots

/- Signature and axiom-audit harness for the seven compiled BKR foundation modules.
This file changes no theorem and adds no axiom. Run only through the root’s serialized audit.
The @ form exposes the full binder list; universe printing keeps universes visible. -/

set_option pp.universes true

-- TauCeti.Data.Fintype.Fiber
#check @Function.occCount
#print axioms Function.occCount
#check @Function.occCount_def
#print axioms Function.occCount_def
#check @Function.occCount_eq_card_filter
#print axioms Function.occCount_eq_card_filter
#check @Function.occCount_eq_sum
#print axioms Function.occCount_eq_sum
#check @Function.occCount_le_of_comp
#print axioms Function.occCount_le_of_comp
#check @Function.occCount_lt_of_comp
#print axioms Function.occCount_lt_of_comp
#check @Function.occCount_pos
#print axioms Function.occCount_pos
#check @Function.occCount_eq_card_preimage
#print axioms Function.occCount_eq_card_preimage
#check @Function.occCount_of_notMem_range
#print axioms Function.occCount_of_notMem_range
#check @Function.occCount_of_injective
#print axioms Function.occCount_of_injective
#check @Function.occCount_apply_of_injective
#print axioms Function.occCount_apply_of_injective
#check @Function.prod_occCount_pow
#print axioms Function.prod_occCount_pow
#check @Function.sum_occCount_eq_card
#print axioms Function.sum_occCount_eq_card
#check @Function.occCount_castSucc
#print axioms Function.occCount_castSucc
#check @Function.occCount_succ
#print axioms Function.occCount_succ
#check @Function.exists_perm_of_occCount_eq
#print axioms Function.exists_perm_of_occCount_eq
#check @Function.sum_occCount_nsmul
#print axioms Function.sum_occCount_nsmul

-- TauCeti.Data.Matrix.OccCount
#check @Function.mulVec_occCount
#print axioms Function.mulVec_occCount
#check @Function.eq_occCount
#print axioms Function.eq_occCount

-- TauCeti.Data.SignType.Lagrange
#check @SignType.lagrangeCoeff
#print axioms SignType.lagrangeCoeff
#check @SignType.lagrangeCoeff_zero
#print axioms SignType.lagrangeCoeff_zero
#check @SignType.lagrangeCoeff_neg_one
#print axioms SignType.lagrangeCoeff_neg_one
#check @SignType.lagrangeCoeff_one
#print axioms SignType.lagrangeCoeff_one
#check @SignType.sum_lagrangeCoeff_mul_pow
#print axioms SignType.sum_lagrangeCoeff_mul_pow

-- TauCeti.Geometry.RealAlgebraic.SignDetermination.Moments
#check @TauCeti.SignDetermination.fullMatrix
#print axioms TauCeti.SignDetermination.fullMatrix
#check @TauCeti.SignDetermination.fullMatrix_def
#print axioms TauCeti.SignDetermination.fullMatrix_def
#check @TauCeti.SignDetermination.fullInverse
#print axioms TauCeti.SignDetermination.fullInverse
#check @TauCeti.SignDetermination.fullMatrix_apply
#print axioms TauCeti.SignDetermination.fullMatrix_apply
#check @TauCeti.SignDetermination.fullInverse_apply
#print axioms TauCeti.SignDetermination.fullInverse_apply
#check @TauCeti.SignDetermination.fullInverse_mul_fullMatrix
#print axioms TauCeti.SignDetermination.fullInverse_mul_fullMatrix
#check @TauCeti.SignDetermination.fullMatrix_mul_fullInverse
#print axioms TauCeti.SignDetermination.fullMatrix_mul_fullInverse
#check @TauCeti.SignDetermination.fullMatrix_mulVec_occCount
#print axioms TauCeti.SignDetermination.fullMatrix_mulVec_occCount
#check @TauCeti.SignDetermination.fullInverse_mulVec
#print axioms TauCeti.SignDetermination.fullInverse_mulVec

-- TauCeti.Geometry.RealAlgebraic.SignDetermination.Defs
#check @Finset.signCount
#print axioms Finset.signCount
#check @Finset.signCount_eq_occCount
#print axioms Finset.signCount_eq_occCount
#check @Finset.signCount_eq_card_filter
#print axioms Finset.signCount_eq_card_filter
#check @Finset.signCount_empty
#print axioms Finset.signCount_empty
#check @Finset.sum_signCount
#print axioms Finset.sum_signCount
#check @Finset.signCount_pos
#print axioms Finset.signCount_pos
#check @Finset.signSum
#print axioms Finset.signSum
#check @Finset.signSum_eq_sum_subtype
#print axioms Finset.signSum_eq_sum_subtype
#check @Finset.signSum_eq_sum
#print axioms Finset.signSum_eq_sum
#check @Finset.signSum_empty
#print axioms Finset.signSum_empty
#check @Finset.signSum_zero
#print axioms Finset.signSum_zero
#check @Finset.signSum_one
#print axioms Finset.signSum_one
#check @Finset.signSum_eq_card_sub_card
#print axioms Finset.signSum_eq_card_sub_card
#check @Polynomial.tarskiQuery
#print axioms Polynomial.tarskiQuery
#check @Polynomial.tarskiQuery_eq_signSum
#print axioms Polynomial.tarskiQuery_eq_signSum
#check @Polynomial.tarskiQuery_eq_sum
#print axioms Polynomial.tarskiQuery_eq_sum
#check @Polynomial.tarskiQuery_eq_card_sub_card
#print axioms Polynomial.tarskiQuery_eq_card_sub_card
#check @Polynomial.tarskiQuery_zero_left
#print axioms Polynomial.tarskiQuery_zero_left
#check @Polynomial.tarskiQuery_zero_right
#print axioms Polynomial.tarskiQuery_zero_right
#check @Polynomial.tarskiQuery_one_right
#print axioms Polynomial.tarskiQuery_one_right
#check @Polynomial.signCount_roots_eq_natCard
#print axioms Polynomial.signCount_roots_eq_natCard
#check @Polynomial.tarskiQuery_eq_sub
#print axioms Polynomial.tarskiQuery_eq_sub
#check @Polynomial.signCount_roots_pos
#print axioms Polynomial.signCount_roots_pos

-- TauCeti.Geometry.RealAlgebraic.SignDetermination.Polynomial
#check @Finset.signSum_prod_pow
#print axioms Finset.signSum_prod_pow
#check @Finset.mulVec_signCount
#print axioms Finset.mulVec_signCount
#check @Finset.eq_signCount
#print axioms Finset.eq_signCount
#check @Finset.signCount_solution_pos_iff
#print axioms Finset.signCount_solution_pos_iff
#check @Finset.fullInverse_mulVec_signSum
#print axioms Finset.fullInverse_mulVec_signSum
#check @Finset.signSum_eq_sum_signCount
#print axioms Finset.signSum_eq_sum_signCount

-- TauCeti.Geometry.RealAlgebraic.SignDetermination.Roots
#check @Polynomial.tarskiQuery_eq_sum_signCount
#print axioms Polynomial.tarskiQuery_eq_sum_signCount
#check @Polynomial.fullInverse_mulVec_tarskiQuery
#print axioms Polynomial.fullInverse_mulVec_tarskiQuery
