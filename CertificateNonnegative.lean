import ClearDenominators
import Mathlib.Algebra.MvPolynomial.Funext
import Mathlib.Order.Interval.Set.Infinite
import Mathlib.Topology.Algebra.MvPolynomial
import Mathlib.Topology.Algebra.Ring.Real
import Mathlib.Topology.Order.Basic

/-!
# Nonnegative evaluation from a common nonzero denominator certificate

Source-only draft. The root coordinator owns compilation and axiom checks.
The proof includes points where the denominator vanishes: a negative value
would give an open box on which the denominator vanishes identically.
This is the reverse implication, not Artin's positivity-to-SOS theorem.
-/

namespace Hilbert17

/-- A square-denominator SOS certificate forces nonnegativity at every real point,
including denominator zeros. -/
theorem real_nonnegative_of_cleared_isSumSq {n : ℕ}
    {f q : MvPolynomial (Fin n) ℝ} (hq : q ≠ 0) (hs : IsSumSq (q ^ 2 * f)) :
    ∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f := by
  intro x
  by_contra! hx
  have hU : IsOpen {y : Fin n → ℝ | MvPolynomial.eval y f < 0} :=
    isOpen_lt f.continuous_eval continuous_const
  obtain ⟨u, hu, hsub⟩ := isOpen_pi_iff'.mp hU x hx
  have huinf : ∀ i : Fin n, (u i).Infinite := by
    intro i
    obtain ⟨a, b, hab, hI⟩ := (hu i).1.exists_Ioo_subset ⟨x i, (hu i).2⟩
    exact (Set.Ioo_infinite hab).mono hI
  apply hq
  apply MvPolynomial.funext_set u huinf
  intro y hy
  have hfy : MvPolynomial.eval y f < 0 := hsub hy
  have heval : 0 ≤ (MvPolynomial.eval y q) ^ 2 * MvPolynomial.eval y f := by
    simpa only [map_mul, map_pow] using
      (map_isSumSq (MvPolynomial.eval y) hs).nonneg
  have hqy : MvPolynomial.eval y q = 0 := by
    by_contra hqy
    exact (mul_neg_of_pos_of_neg (sq_pos_of_ne_zero hqy) hfy).not_ge heval
  simpa only [map_zero] using hqy

/-- A rational SOS polynomial is nonnegative everywhere, not only off its poles. -/
theorem real_nonnegative_of_rational_isSumSq {n : ℕ}
    {f : MvPolynomial (Fin n) ℝ}
    (hf : IsSumSq (algebraMap (MvPolynomial (Fin n) ℝ)
      (FractionRing (MvPolynomial (Fin n) ℝ)) f)) :
    ∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f := by
  obtain ⟨q, hq, hs⟩ :=
    (isSumSq_fraction_iff (F := FractionRing (MvPolynomial (Fin n) ℝ)) f).mp hf
  exact real_nonnegative_of_cleared_isSumSq hq hs

end Hilbert17
