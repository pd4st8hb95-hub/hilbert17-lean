import TauCeti.FieldTheory.RealClosure.AbstractRolle

/- Exact named types and axiom dependencies for the pinned Hilbert17 backport.
   This diagnostic adds no mathematical assumptions or declarations.
   Import compilation and independent kernel replay are separate checks. -/

set_option pp.universes true

#check Polynomial.exists_derivative_root_of_isRoot
#print axioms Polynomial.exists_derivative_root_of_isRoot

#check TauCeti.RealClosure.polynomialRolle_of_isRealClosed
#print axioms TauCeti.RealClosure.polynomialRolle_of_isRealClosed

#check Polynomial.exists_derivative_root
#print axioms Polynomial.exists_derivative_root

#check Polynomial.exists_eval_sub_eq_derivative_eval_mul
#print axioms Polynomial.exists_eval_sub_eq_derivative_eval_mul

#check Polynomial.monotoneOn_of_derivative_nonneg
#print axioms Polynomial.monotoneOn_of_derivative_nonneg

#check Polynomial.antitoneOn_of_derivative_nonpos
#print axioms Polynomial.antitoneOn_of_derivative_nonpos

#check Polynomial.strictMonoOn_of_derivative_pos
#print axioms Polynomial.strictMonoOn_of_derivative_pos

#check Polynomial.strictAntiOn_of_derivative_neg
#print axioms Polynomial.strictAntiOn_of_derivative_neg
