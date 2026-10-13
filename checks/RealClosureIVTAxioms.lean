import TauCeti.FieldTheory.RealClosure.IVT

/- Exact named types and axiom dependencies for the pinned Hilbert17 backport.
   This diagnostic adds no mathematical assumptions or declarations.
   Import compilation and independent kernel replay are separate checks. -/

set_option pp.universes true

#check Polynomial.eval_mul_pos_of_no_roots
#print axioms Polynomial.eval_mul_pos_of_no_roots

#check Polynomial.exists_root_Icc_of_mul_nonpos
#print axioms Polynomial.exists_root_Icc_of_mul_nonpos

#check Polynomial.exists_root_Icc
#print axioms Polynomial.exists_root_Icc

#check Polynomial.exists_root_Ioo
#print axioms Polynomial.exists_root_Ioo

#check Polynomial.exists_root_Ioo_of_mul_neg
#print axioms Polynomial.exists_root_Ioo_of_mul_neg

#check Polynomial.intermediate_value_Icc
#print axioms Polynomial.intermediate_value_Icc

#check Polynomial.intermediate_value_Icc'
#print axioms Polynomial.intermediate_value_Icc'
