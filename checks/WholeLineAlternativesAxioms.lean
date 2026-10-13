import WholeLineAlternatives

/- Named types and axiom dependencies for public declarations in this module.
   Source compilation and selected same-kernel replay are separate checks. -/

set_option pp.universes true

#check Hilbert17Transfer.rootBound
#print axioms Hilbert17Transfer.rootBound

#check Hilbert17Transfer.root_lt_rootBound
#print axioms Hilbert17Transfer.root_lt_rootBound

#check Hilbert17Transfer.neg_rootBound_lt_root
#print axioms Hilbert17Transfer.neg_rootBound_lt_root

#check Hilbert17Transfer.sign_eval_rootBound
#print axioms Hilbert17Transfer.sign_eval_rootBound

#check Hilbert17Transfer.sign_eval_neg_rootBound
#print axioms Hilbert17Transfer.sign_eval_neg_rootBound

#check Hilbert17Transfer.exists_all_leading_signs
#print axioms Hilbert17Transfer.exists_all_leading_signs

#check Hilbert17Transfer.exists_all_parity_leading_signs
#print axioms Hilbert17Transfer.exists_all_parity_leading_signs

#check Hilbert17Transfer.exists_signs_iff_root_derivative_infinity
#print axioms Hilbert17Transfer.exists_signs_iff_root_derivative_infinity
