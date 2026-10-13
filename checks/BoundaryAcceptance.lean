import RealClosureTransfer
import CertificateNonnegative
import ClearDenominators

/-!
# Boundary and equivalence acceptance checks

Source-only acceptance module; the root owns compilation and axiom auditing.
The zero and zero-variable results apply the exact final candidate. The
necessity directions use the existing proof covering denominator-zero points.
No frozen candidate or prerequisite source is modified by these checks.
-/

open scoped BigOperators

namespace Hilbert17Acceptance

/-- The exact candidate includes the zero polynomial for every finite variable count. -/
theorem candidate_zero_rational (n : ℕ) :
    IsSumSq (algebraMap (MvPolynomial (Fin n) ℝ)
      (FractionRing (MvPolynomial (Fin n) ℝ)) 0) :=
  Hilbert17Transfer.hilbert17Real_candidate n 0 (by intro x; simp)

/-- The cleared candidate also includes zero, without requiring a positive number of squares. -/
theorem candidate_zero_explicit (n : ℕ) :
    ∃ (m : ℕ) (q : MvPolynomial (Fin n) ℝ)
      (p : Fin m → MvPolynomial (Fin n) ℝ),
      q ≠ 0 ∧ q ^ 2 * (0 : MvPolynomial (Fin n) ℝ) = ∑ i : Fin m, (p i) ^ 2 :=
  Hilbert17Transfer.hilbert17RealCleared_candidate n 0 (by intro x; simp)

/-- For n=0 the positivity premise is just nonnegativity of the constant coefficient. -/
theorem candidate_fin0_rational (f : MvPolynomial (Fin 0) ℝ)
    (hf : 0 ≤ f.coeff 0) :
    IsSumSq (algebraMap (MvPolynomial (Fin 0) ℝ)
      (FractionRing (MvPolynomial (Fin 0) ℝ)) f) := by
  apply Hilbert17Transfer.hilbert17Real_candidate 0 f
  intro x
  rw [MvPolynomial.eq_C_of_isEmpty f, MvPolynomial.eval_C]
  exact hf

/-- The same zero-variable boundary check for the exact explicit certificate candidate. -/
theorem candidate_fin0_explicit (f : MvPolynomial (Fin 0) ℝ)
    (hf : 0 ≤ f.coeff 0) :
    ∃ (m : ℕ) (q : MvPolynomial (Fin 0) ℝ)
      (p : Fin m → MvPolynomial (Fin 0) ℝ),
      q ≠ 0 ∧ q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2 := by
  apply Hilbert17Transfer.hilbert17RealCleared_candidate 0 f
  intro x
  rw [MvPolynomial.eq_C_of_isEmpty f, MvPolynomial.eval_C]
  exact hf

/-- Full necessity and sufficiency for every finite-variable real polynomial. -/
theorem nonnegative_iff_rationalSOS {n : ℕ} (f : MvPolynomial (Fin n) ℝ) :
    (∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f) ↔
      IsSumSq (algebraMap (MvPolynomial (Fin n) ℝ)
        (FractionRing (MvPolynomial (Fin n) ℝ)) f) := by
  constructor
  · exact Hilbert17Transfer.hilbert17Real_candidate n f
  · exact Hilbert17.real_nonnegative_of_rational_isSumSq

/-- Nonzero-polynomial denominator certificates are necessary and sufficient. -/
theorem nonnegative_iff_clearedSOS {n : ℕ} (f : MvPolynomial (Fin n) ℝ) :
    (∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f) ↔
      ∃ q : MvPolynomial (Fin n) ℝ, q ≠ 0 ∧ IsSumSq (q ^ 2 * f) :=
  (nonnegative_iff_rationalSOS f).trans
    (Hilbert17.isSumSq_fraction_iff (F := FractionRing (MvPolynomial (Fin n) ℝ)) f)

/-- Full finite-sum certificate equivalence, including points where its denominator vanishes. -/
theorem nonnegative_iff_explicitClearedSOS {n : ℕ} (f : MvPolynomial (Fin n) ℝ) :
    (∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f) ↔
      ∃ (m : ℕ) (q : MvPolynomial (Fin n) ℝ)
        (p : Fin m → MvPolynomial (Fin n) ℝ),
        q ≠ 0 ∧ q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2 :=
  (nonnegative_iff_rationalSOS f).trans (Hilbert17.real_mvPolynomial_fraction_iff f)

end Hilbert17Acceptance

#check @Hilbert17Acceptance.candidate_zero_rational
#check @Hilbert17Acceptance.candidate_zero_explicit
#check @Hilbert17Acceptance.candidate_fin0_rational
#check @Hilbert17Acceptance.candidate_fin0_explicit
#check @Hilbert17Acceptance.nonnegative_iff_rationalSOS
#check @Hilbert17Acceptance.nonnegative_iff_clearedSOS
#check @Hilbert17Acceptance.nonnegative_iff_explicitClearedSOS

#print axioms Hilbert17Acceptance.candidate_zero_rational
#print axioms Hilbert17Acceptance.candidate_zero_explicit
#print axioms Hilbert17Acceptance.candidate_fin0_rational
#print axioms Hilbert17Acceptance.candidate_fin0_explicit
#print axioms Hilbert17Acceptance.nonnegative_iff_rationalSOS
#print axioms Hilbert17Acceptance.nonnegative_iff_clearedSOS
#print axioms Hilbert17Acceptance.nonnegative_iff_explicitClearedSOS
