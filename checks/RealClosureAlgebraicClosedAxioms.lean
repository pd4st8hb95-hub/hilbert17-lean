import TauCeti.FieldTheory.RealClosure.AlgebraicClosed

/- Exact named types and axiom dependencies for the pinned Hilbert17 backport.
   This diagnostic adds no mathematical assumptions or declarations.
   Import compilation and independent kernel replay are separate checks. -/

set_option pp.universes true

#check TauCeti.RealClosure.finrank_eq_one_of_forall_isSquare
#print axioms TauCeti.RealClosure.finrank_eq_one_of_forall_isSquare

#check TauCeti.RealClosure.isAlgClosed_of_forall_isSquare
#print axioms TauCeti.RealClosure.isAlgClosed_of_forall_isSquare

#check TauCeti.RealClosure.isAlgClosed_quadraticAlgebra
#print axioms TauCeti.RealClosure.isAlgClosed_quadraticAlgebra

#check Polynomial.natDegree_le_two_of_irreducible
#print axioms Polynomial.natDegree_le_two_of_irreducible
