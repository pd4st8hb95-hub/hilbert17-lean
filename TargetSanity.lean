import ClearDenominators
import Mathlib.Analysis.Real.Sqrt

/-!
# Sanity checks for the full Hilbert-seventeenth target

Source-only draft against the pinned environment. No compiler run is claimed.
These results establish the zero-variable case and already-polynomial-SOS cases;
they do not restrict or prove the full arbitrary-variable positivity implication.
-/

namespace Hilbert17

open scoped BigOperators

/-- An existing polynomial SOS certificate maps to the rational-function field. -/
theorem real_rational_of_polynomial_isSumSq {n : ℕ}
    {f : MvPolynomial (Fin n) ℝ} (hf : IsSumSq f) :
    IsSumSq (algebraMap (MvPolynomial (Fin n) ℝ)
      (FractionRing (MvPolynomial (Fin n) ℝ)) f) :=
  map_isSumSq (algebraMap _ _) hf

/-- Already-polynomial sums of squares have common denominator one. -/
theorem real_cleared_of_polynomial_isSumSq {n : ℕ}
    {f : MvPolynomial (Fin n) ℝ} (hf : IsSumSq f) :
    ∃ q : MvPolynomial (Fin n) ℝ, q ≠ 0 ∧ IsSumSq (q ^ 2 * f) := by
  exact ⟨1, one_ne_zero, by simpa using hf⟩

/-- Explicit finite numerators, with denominator one, for a polynomial SOS. -/
theorem real_explicit_of_polynomial_isSumSq {n : ℕ}
    {f : MvPolynomial (Fin n) ℝ} (hf : IsSumSq f) :
    ∃ (m : ℕ) (q : MvPolynomial (Fin n) ℝ)
      (p : Fin m → MvPolynomial (Fin n) ℝ),
      q ≠ 0 ∧ q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2 := by
  obtain ⟨m, p, hp⟩ := (isSumSq_iff_exists_fin_sum f).mp hf
  exact ⟨m, 1, p, one_ne_zero, by simpa using hp⟩

/-- A nonnegative real polynomial in no variables is itself a square. -/
theorem real_fin0_isSquare_of_nonnegative (f : MvPolynomial (Fin 0) ℝ)
    (hf : ∀ x : Fin 0 → ℝ, 0 ≤ MvPolynomial.eval x f) : IsSquare f := by
  have hc : 0 ≤ f.coeff 0 := by
    have h := hf (fun i => Fin.elim0 i)
    rw [f.eq_C_of_isEmpty, MvPolynomial.eval_C] at h
    exact h
  rw [f.eq_C_of_isEmpty]
  exact IsSquare.map (MvPolynomial.C : ℝ →+* MvPolynomial (Fin 0) ℝ)
    (Real.isSquare_iff.mpr hc)

/-- The complete requested implication in the edge case n=0. -/
theorem hilbert17_real_fin0 (f : MvPolynomial (Fin 0) ℝ)
    (hf : ∀ x : Fin 0 → ℝ, 0 ≤ MvPolynomial.eval x f) :
    IsSumSq (algebraMap (MvPolynomial (Fin 0) ℝ)
      (FractionRing (MvPolynomial (Fin 0) ℝ)) f) :=
  real_rational_of_polynomial_isSumSq (real_fin0_isSquare_of_nonnegative f hf).isSumSq

/-- The explicit denominator-cleared target in the edge case n=0. -/
theorem hilbert17_real_fin0_explicit (f : MvPolynomial (Fin 0) ℝ)
    (hf : ∀ x : Fin 0 → ℝ, 0 ≤ MvPolynomial.eval x f) :
    ∃ (m : ℕ) (q : MvPolynomial (Fin 0) ℝ)
      (p : Fin m → MvPolynomial (Fin 0) ℝ),
      q ≠ 0 ∧ q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2 :=
  real_explicit_of_polynomial_isSumSq (real_fin0_isSquare_of_nonnegative f hf).isSumSq

end Hilbert17
