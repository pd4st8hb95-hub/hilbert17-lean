import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.MvPolynomial.CommRing
import Mathlib.Algebra.MvPolynomial.Eval
import Mathlib.Algebra.Ring.SumsOfSquares
import Mathlib.Data.Real.Basic
import Mathlib.RingTheory.Localization.FractionRing
import Mathlib.Tactic.Ring

/-!
# Common nonzero denominators for sums of squares

Pinned source target: mathlib 520045ab14e26149ee970e2e617ca04b09bde5d6.
Source draft, not yet compiled. The root coordinator owns serialized verification.

These are algebraic equivalences and representations, not a proof of the
positivity-to-sum-of-squares direction of Hilbert seventeenth.
-/

open scoped BigOperators

namespace Hilbert17

/-- A ring homomorphism preserves finite sums of squares. -/
theorem map_isSumSq {A B : Type*} [Semiring A] [Semiring B]
    (g : A →+* B) {s : A} (hs : IsSumSq s) : IsSumSq (g s) := by
  induction hs with
  | zero => simpa only [map_zero] using (IsSumSq.zero : IsSumSq (0 : B))
  | sq_add a hs ih =>
      simpa only [map_add, map_mul] using IsSumSq.sq_add (g a) ih

/-- The inductive predicate supplies an explicitly finite list of square bases.
The empty sum is allowed, so zero has its natural certificate. -/
theorem isSumSq_iff_exists_fin_sum {A : Type*} [CommSemiring A] (s : A) :
    IsSumSq s ↔ ∃ (m : ℕ) (p : Fin m → A), s = ∑ i : Fin m, (p i) ^ 2 := by
  constructor
  · intro hs
    induction hs with
    | zero => exact ⟨0, Fin.elim0, by simp⟩
    | sq_add a hs ih =>
        obtain ⟨m, p, hp⟩ := ih
        refine ⟨m + 1, Fin.cons a p, ?_⟩
        rw [Fin.sum_univ_succ]
        simp only [Fin.cons_zero, Fin.cons_succ]
        rw [← hp]
        simp only [pow_two]
  · rintro ⟨m, p, rfl⟩
    simpa using IsSumSq.sum_sq Finset.univ p

section Fractions

variable {A F : Type*} [CommRing A] [IsDomain A] [Field F]
    [Algebra A F] [IsFractionRing A F]

/-- Clear the denominators of a finite sum of squares by induction on its certificate.
The numerator remains a sum of squares in the original integral domain. -/
theorem exists_nonzero_clear_sumSq {s : F} (hs : IsSumSq s) :
    ∃ (d p : A), d ≠ 0 ∧ IsSumSq p ∧
      algebraMap A F p = (algebraMap A F d) ^ 2 * s := by
  induction hs with
  | zero => exact ⟨1, 0, one_ne_zero, IsSumSq.zero, by simp⟩
  | @sq_add a s hs ih =>
      obtain ⟨d, p, hd, hp, hmap⟩ := ih
      obtain ⟨⟨num, b⟩, hb⟩ := IsLocalization.surj (nonZeroDivisors A) a
      change a * algebraMap A F (b : A) = algebraMap A F num at hb
      have hb0 : (b : A) ≠ 0 := nonZeroDivisors.ne_zero b.property
      refine ⟨(b : A) * d, (num * d) ^ 2 + (b : A) ^ 2 * p,
        mul_ne_zero hb0 hd, ?_, ?_⟩
      · apply IsSumSq.add
        · simpa only [pow_two] using IsSumSq.mul_self (num * d)
        · apply IsSumSq.mul _ hp
          simpa only [pow_two] using IsSumSq.mul_self (b : A)
      · simp only [map_add, map_mul, map_pow]
        rw [← hb, hmap]
        ring

/-- A polynomial/domain element is a sum of rational squares exactly when a
nonzero square multiple is a sum of squares in the domain. No order or
real-closedness hypothesis is needed for this algebraic equivalence. -/
theorem isSumSq_fraction_iff (f : A) :
    IsSumSq (algebraMap A F f) ↔
      ∃ q : A, q ≠ 0 ∧ IsSumSq (q ^ 2 * f) := by
  constructor
  · intro hs
    obtain ⟨d, p, hd, hp, hmap⟩ := exists_nonzero_clear_sumSq (A := A) hs
    refine ⟨d, hd, ?_⟩
    have heq : d ^ 2 * f = p := IsFractionRing.injective A F (by
      simpa only [map_mul, map_pow] using hmap.symm)
    rw [heq]
    exact hp
  · rintro ⟨d, hd, hs⟩
    have hdF : algebraMap A F d ≠ 0 := by
      intro h
      apply hd
      apply IsFractionRing.injective A F
      simpa using h
    have hnum : IsSumSq (algebraMap A F (d ^ 2 * f)) :=
      map_isSumSq (algebraMap A F) hs
    have hinv : IsSumSq ((algebraMap A F d)⁻¹ ^ 2) := by
      simpa only [pow_two] using IsSumSq.mul_self ((algebraMap A F d)⁻¹)
    have hprod := hnum.mul hinv
    have hcancel : algebraMap A F (d ^ 2 * f) * (algebraMap A F d)⁻¹ ^ 2 =
        algebraMap A F f := by
      calc
        algebraMap A F (d ^ 2 * f) * (algebraMap A F d)⁻¹ ^ 2 =
            (algebraMap A F d * (algebraMap A F d)⁻¹) ^ 2 * algebraMap A F f := by
              simp only [map_mul, map_pow]
              ring
        _ = algebraMap A F f := by simp [hdF]
    rwa [hcancel] at hprod

/-- Fully explicit finite numerator certificate with a shared nonzero denominator. -/
theorem isSumSq_fraction_iff_explicit (f : A) :
    IsSumSq (algebraMap A F f) ↔
      ∃ (m : ℕ) (q : A) (p : Fin m → A),
        q ≠ 0 ∧ q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2 := by
  rw [isSumSq_fraction_iff (F := F)]
  constructor
  · rintro ⟨q, hq, hs⟩
    obtain ⟨m, p, hp⟩ := (isSumSq_iff_exists_fin_sum _).mp hs
    exact ⟨m, q, p, hq, hp⟩
  · rintro ⟨m, q, p, hq, hp⟩
    exact ⟨q, hq, (isSumSq_iff_exists_fin_sum _).mpr ⟨m, p, hp⟩⟩

end Fractions

/-- The common-denominator equivalence for the full finite-variable real target. -/
theorem real_mvPolynomial_fraction_iff {n : ℕ} (f : MvPolynomial (Fin n) ℝ) :
    IsSumSq (algebraMap (MvPolynomial (Fin n) ℝ)
      (FractionRing (MvPolynomial (Fin n) ℝ)) f) ↔
      ∃ (m : ℕ) (q : MvPolynomial (Fin n) ℝ)
        (p : Fin m → MvPolynomial (Fin n) ℝ),
        q ≠ 0 ∧ q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2 :=
  isSumSq_fraction_iff_explicit (F := FractionRing (MvPolynomial (Fin n) ℝ)) f

/-- Equivalence of two formulations of the complete requested theorem.
This proves the change of formulation only, not either positivity implication. -/
theorem hilbert17_real_target_iff :
    (∀ (n : ℕ) (f : MvPolynomial (Fin n) ℝ),
      (∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f) →
      IsSumSq (algebraMap (MvPolynomial (Fin n) ℝ)
        (FractionRing (MvPolynomial (Fin n) ℝ)) f)) ↔
    (∀ (n : ℕ) (f : MvPolynomial (Fin n) ℝ),
      (∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f) →
      ∃ (m : ℕ) (q : MvPolynomial (Fin n) ℝ)
        (p : Fin m → MvPolynomial (Fin n) ℝ),
        q ≠ 0 ∧ q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2) := by
  constructor
  · intro h n f hf
    exact (real_mvPolynomial_fraction_iff f).mp (h n f hf)
  · intro h n f hf
    exact (real_mvPolynomial_fraction_iff f).mpr (h n f hf)

end Hilbert17
