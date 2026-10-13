-- Diagnostic source only. Run after the imported project module has compiled successfully.
import TargetSpec

set_option pp.universes true
set_option pp.fullNames true
set_option pp.explicit true

#check Hilbert17Target.Poly
#print axioms Hilbert17Target.Poly

#check Hilbert17Target.RatFun
#print axioms Hilbert17Target.RatFun

#check Hilbert17Target.NonnegativeEverywhere
#print axioms Hilbert17Target.NonnegativeEverywhere

#check Hilbert17Target.RationalSOS
#print axioms Hilbert17Target.RationalSOS

#check Hilbert17Target.ClearedSOS
#print axioms Hilbert17Target.ClearedSOS

#check Hilbert17Target.ExplicitClearedSOS
#print axioms Hilbert17Target.ExplicitClearedSOS

#check Hilbert17Target.Hilbert17Real
#print axioms Hilbert17Target.Hilbert17Real

#check Hilbert17Target.Hilbert17RealCleared
#print axioms Hilbert17Target.Hilbert17RealCleared

#check Hilbert17Target.Hilbert17RealClosed
#print axioms Hilbert17Target.Hilbert17RealClosed

#print Hilbert17Target.Hilbert17Real
#print Hilbert17Target.Hilbert17RealCleared
#print Hilbert17Target.Hilbert17RealClosed
