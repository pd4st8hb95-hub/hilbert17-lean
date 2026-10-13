import RealClosureTransfer
import CertificateNonnegative
import ClearDenominators

/-!
# Final target acceptance contract

Staged diagnostic and theorem-type contract only. This file has not been compiled.
Its import closure contains the still-unverified full-transfer candidate.
Do not report its declarations as established until the root records successful
compilation, selected replay, and the complete recursive axiom audit.

These declarations deliberately spell out the requested conclusion rather than
accepting a weakened specification or a transfer premise. The only mathematical
input to each real-polynomial theorem is pointwise nonnegativity of that polynomial.
-/

open scoped BigOperators

namespace Hilbert17Acceptance

/-- Exact arbitrary-finite-variable, real-coefficient rational-SOS target. -/
theorem real_rationalSOS (n : ℕ) (f : MvPolynomial (Fin n) ℝ)
    (hf : ∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f) :
    IsSumSq (algebraMap (MvPolynomial (Fin n) ℝ)
      (FractionRing (MvPolynomial (Fin n) ℝ)) f) :=
  Hilbert17Transfer.hilbert17Real_candidate n f hf

/-- Explicit finite rational functions; there is no extra rational-function variable. -/
theorem real_finite_rational_squares (n : ℕ) (f : MvPolynomial (Fin n) ℝ)
    (hf : ∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f) :
    ∃ (m : ℕ) (g : Fin m → FractionRing (MvPolynomial (Fin n) ℝ)),
      algebraMap (MvPolynomial (Fin n) ℝ)
        (FractionRing (MvPolynomial (Fin n) ℝ)) f =
          ∑ i : Fin m, (g i) ^ 2 :=
  (Hilbert17.isSumSq_iff_exists_fin_sum _).mp (real_rationalSOS n f hf)

/-- Exact common-denominator target, with the denominator nonzero as a polynomial. -/
theorem real_clearedSOS (n : ℕ) (f : MvPolynomial (Fin n) ℝ)
    (hf : ∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f) :
    ∃ (m : ℕ) (q : MvPolynomial (Fin n) ℝ)
      (p : Fin m → MvPolynomial (Fin n) ℝ),
      q ≠ 0 ∧ q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2 :=
  Hilbert17Transfer.hilbert17RealCleared_candidate n f hf

/-- Check that the candidate supplies the previously unresolved premise unconditionally. -/
theorem real_negativePointTransfer : Hilbert17.NegativePointTransfer ℝ := by
  letI : IsRealClosed ℝ := Hilbert17Transfer.real_isRealClosed
  exact Hilbert17Transfer.negativePointTransfer_of_isRealClosed ℝ

end Hilbert17Acceptance

set_option pp.universes true
set_option pp.fullNames true
set_option pp.explicit true

#check @Hilbert17Acceptance.real_rationalSOS
#check @Hilbert17Acceptance.real_finite_rational_squares
#check @Hilbert17Acceptance.real_clearedSOS
#check @Hilbert17Acceptance.real_negativePointTransfer
#check @Hilbert17Transfer.negativePointTransfer_of_isRealClosed
#check @Hilbert17Transfer.hilbert17Real_candidate
#check @Hilbert17Transfer.hilbert17RealCleared_candidate

#print Hilbert17.NegativePointTransfer
#print Hilbert17Target.Hilbert17Real
#print Hilbert17Target.Hilbert17RealCleared

#print axioms Hilbert17Acceptance.real_rationalSOS
#print axioms Hilbert17Acceptance.real_finite_rational_squares
#print axioms Hilbert17Acceptance.real_clearedSOS
#print axioms Hilbert17Acceptance.real_negativePointTransfer
#print axioms Hilbert17Transfer.negativePointTransfer_of_isRealClosed
#print axioms Hilbert17Transfer.hilbert17Real_candidate
#print axioms Hilbert17Transfer.hilbert17RealCleared_candidate
