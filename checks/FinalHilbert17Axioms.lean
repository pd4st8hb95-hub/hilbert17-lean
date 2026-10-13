import RealClosureTransfer

/- Final target and dependency-axiom diagnostic. This file asserts no new theorem.
   Execute only after the complete RealClosureTransfer import closure compiles. -/
set_option pp.universes true
set_option pp.explicit true

#print Hilbert17Target.Poly
#print Hilbert17Target.RatFun
#print Hilbert17Target.NonnegativeEverywhere
#print Hilbert17Target.RationalSOS
#print Hilbert17Target.ExplicitClearedSOS
#print Hilbert17Target.Hilbert17Real
#print Hilbert17Target.Hilbert17RealCleared

#check @Hilbert17Transfer.negativePointTransfer_of_isRealClosed
#print axioms Hilbert17Transfer.negativePointTransfer_of_isRealClosed
#check @Hilbert17Transfer.hilbert17Real_candidate
#print axioms Hilbert17Transfer.hilbert17Real_candidate
#check @Hilbert17Transfer.hilbert17RealCleared_candidate
#print axioms Hilbert17Transfer.hilbert17RealCleared_candidate
