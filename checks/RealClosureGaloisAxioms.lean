import TauCeti.FieldTheory.RealClosure.Galois

/- Exact named types and axiom dependencies for the pinned Hilbert17 backport.
   This diagnostic adds no mathematical assumptions or declarations.
   Import compilation and independent kernel replay are separate checks. -/

set_option pp.universes true

#check TauCeti.RealClosure.isPGroup_two_algEquiv
#print axioms TauCeti.RealClosure.isPGroup_two_algEquiv

#check TauCeti.RealClosure.finrank_eq_one_of_isPGroup
#print axioms TauCeti.RealClosure.finrank_eq_one_of_isPGroup

#check TauCeti.RealClosure.finrank_eq_one_of_isGalois_of_forall_isSquare
#print axioms TauCeti.RealClosure.finrank_eq_one_of_isGalois_of_forall_isSquare
