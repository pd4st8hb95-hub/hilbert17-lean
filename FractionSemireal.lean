import ClearDenominators
import Mathlib.Algebra.CharZero.Infinite
import Mathlib.Algebra.MvPolynomial.Funext
import Mathlib.Algebra.Ring.Semireal.Defs
import Mathlib.Data.Real.Basic

/-!
# Semireality of multivariate rational-function fields

Development target: Lean 4.32.1, mathlib
520045ab14e26149ee970e2e617ca04b09bde5d6.

This file is an uncompiled source draft until an explicit compiler run is recorded.
The proof uses a single point off a nonzero denominator's zero locus. It makes
no assertion that this denominator is nonzero at every real point.
-/

namespace Hilbert17

/-- A nonzero multivariate polynomial over an infinite integral domain has a
nonzero evaluation. The variable type need not be finite. -/
theorem exists_eval_ne_zero {R σ : Type*} [CommRing R] [IsDomain R] [Infinite R]
    {q : MvPolynomial σ R} (hq : q ≠ 0) :
    ∃ x : σ → R, MvPolynomial.eval x q ≠ 0 := by
  by_contra! h
  apply hq
  apply MvPolynomial.funext
  intro x
  simpa only [map_zero] using h x

/-- The fraction field of a polynomial ring over an ordered field is semireal.
Clearing denominators reduces a hypothetical sum of squares equal to `-1` to
a contradiction at a point where the common denominator is nonzero. -/
theorem isSemireal_mvPolynomial_fraction
    {R σ F : Type*} [Field R] [LinearOrder R] [IsStrictOrderedRing R]
    [Field F] [Algebra (MvPolynomial σ R) F]
    [IsFractionRing (MvPolynomial σ R) F] : IsSemireal F := by
  apply IsSemireal.of_not_isSumSq_neg_one
  intro hneg
  have hmap : IsSumSq (algebraMap (MvPolynomial σ R) F (-1)) := by
    simpa only [map_neg, map_one] using hneg
  obtain ⟨q, hq, hsq⟩ :=
    (isSumSq_fraction_iff (A := MvPolynomial σ R) (F := F) (-1)).mp hmap
  obtain ⟨x, hx⟩ := exists_eval_ne_zero hq
  have heval : IsSumSq (MvPolynomial.eval x (q ^ 2 * (-1))) := by
    exact map_isSumSq (MvPolynomial.eval x) hsq
  have hnonneg : 0 ≤ -(MvPolynomial.eval x q) ^ 2 := by
    simpa only [map_mul, map_pow, map_neg, map_one, mul_neg_one] using heval.nonneg
  exact (sq_pos_of_ne_zero hx).not_ge (neg_nonneg.mp hnonneg)

/-- In particular, the fraction field in the real-coefficient Hilbert-seventeenth
statement is semireal. -/
theorem isSemireal_real_ratFun (n : ℕ) :
    IsSemireal (FractionRing (MvPolynomial (Fin n) ℝ)) :=
  isSemireal_mvPolynomial_fraction (R := ℝ) (σ := Fin n)
    (F := FractionRing (MvPolynomial (Fin n) ℝ))

end Hilbert17
