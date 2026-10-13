/-
Hilbert seventeenth: statement-only interface proposal.

Verification scope: NOT compiled in this audit. No theorem of Hilbert seventeenth
is claimed here. The declarations below define propositions to be proved.
There are no admitted proof bodies or extra mathematical axioms.
-/
import Mathlib.Algebra.MvPolynomial.CommRing
import Mathlib.Algebra.MvPolynomial.Eval
import Mathlib.Algebra.Ring.SumsOfSquares
import Mathlib.Data.Real.Basic
import Mathlib.FieldTheory.IsRealClosed.Basic
import Mathlib.RingTheory.Localization.FractionRing

open scoped BigOperators

namespace Hilbert17Target

abbrev Poly (R : Type*) [CommSemiring R] (n : ℕ) := MvPolynomial (Fin n) R

abbrev RatFun (R : Type*) [CommRing R] (n : ℕ) := FractionRing (Poly R n)

def NonnegativeEverywhere {R : Type*} [CommSemiring R] [Preorder R]
    {n : ℕ} (f : Poly R n) : Prop :=
  ∀ x : Fin n → R, 0 ≤ MvPolynomial.eval x f

def RationalSOS {R : Type*} [CommRing R] {n : ℕ} (f : Poly R n) : Prop :=
  IsSumSq (algebraMap (Poly R n) (RatFun R n) f)

def ClearedSOS {R : Type*} [CommRing R] {n : ℕ} (f : Poly R n) : Prop :=
  ∃ q : Poly R n, q ≠ 0 ∧ IsSumSq (q ^ 2 * f)

def ExplicitClearedSOS {R : Type*} [CommRing R] {n : ℕ}
    (f : Poly R n) : Prop :=
  ∃ (m : ℕ) (q : Poly R n) (p : Fin m → Poly R n),
    q ≠ 0 ∧ q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2

/-- The full requested real-coefficient, arbitrary-finite-variable goal. -/
def Hilbert17Real : Prop :=
  ∀ (n : ℕ) (f : Poly ℝ n), NonnegativeEverywhere f → RationalSOS f

/-- The denominator-cleared presentation of the same requested goal. -/
def Hilbert17RealCleared : Prop :=
  ∀ (n : ℕ) (f : Poly ℝ n), NonnegativeEverywhere f → ExplicitClearedSOS f

/-- Optional stronger theorem, with a real-closed-field hypothesis. -/
def Hilbert17RealClosed (R : Type*) [Field R] [LinearOrder R]
    [IsStrictOrderedRing R] [IsRealClosed R] : Prop :=
  ∀ (n : ℕ) (f : Poly R n), NonnegativeEverywhere f → RationalSOS f

end Hilbert17Target
