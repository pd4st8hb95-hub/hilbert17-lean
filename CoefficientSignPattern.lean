import Mathlib.Algebra.Polynomial.Eval.Degree
import Mathlib.Algebra.Polynomial.Degree.Lemmas
import Mathlib.Data.Sign.Basic

/-!
Source-only coefficient-sign bookkeeping, isolated for independent checking.
Arbitrary ring maps may kill coefficients. Equality of coefficient signs
controls zero specialization, degree, and both infinity sign vectors.
-/

namespace Hilbert17Transfer

open Polynomial SignType

variable {A : Type*} [CommRing A]

section ZeroPattern

variable {K L : Type*} [CommRing K] [LinearOrder K] [CommRing L] [LinearOrder L]

/-- Bounded coefficient sign agreement gives agreement of every coefficient's zero test. -/
theorem coeff_map_eq_zero_iff_of_sign_agree (p : A[X]) (f : A →+* K) (g : A →+* L)
    (h : ∀ i ≤ p.natDegree, sign (f (p.coeff i)) = sign (g (p.coeff i))) (i : ℕ) :
    (p.map f).coeff i = 0 ↔ (p.map g).coeff i = 0 := by
  simp only [coeff_map]
  by_cases hi : i ≤ p.natDegree
  · constructor
    · intro hf
      apply sign_eq_zero_iff.mp
      rw [← h i hi]
      exact sign_eq_zero_iff.mpr hf
    · intro hg
      apply sign_eq_zero_iff.mp
      rw [h i hi]
      exact sign_eq_zero_iff.mpr hg
  · simp [coeff_eq_zero_of_natDegree_lt (Nat.lt_of_not_ge hi)]

/-- Zero polynomials are distinguished from nonzero constants by the coefficient tests. -/
theorem map_eq_zero_iff_of_coeff_sign_agree (p : A[X]) (f : A →+* K) (g : A →+* L)
    (h : ∀ i ≤ p.natDegree, sign (f (p.coeff i)) = sign (g (p.coeff i))) :
    p.map f = 0 ↔ p.map g = 0 := by
  rw [Polynomial.ext_iff, Polynomial.ext_iff]
  simp only [coeff_zero]
  exact forall_congr' (coeff_map_eq_zero_iff_of_sign_agree p f g h)

/-- Degree agreement only needs the same coefficient zero pattern, even for zero. -/
theorem natDegree_map_eq_of_coeff_sign_agree (p : A[X]) (f : A →+* K) (g : A →+* L)
    (h : ∀ i ≤ p.natDegree, sign (f (p.coeff i)) = sign (g (p.coeff i))) :
    (p.map f).natDegree = (p.map g).natDegree := by
  have hz := coeff_map_eq_zero_iff_of_sign_agree p f g h
  apply le_antisymm
  · apply natDegree_le_iff_coeff_eq_zero.mpr
    intro i hi
    exact (hz i).mpr (coeff_eq_zero_of_natDegree_lt hi)
  · apply natDegree_le_iff_coeff_eq_zero.mpr
    intro i hi
    exact (hz i).mp (coeff_eq_zero_of_natDegree_lt hi)

end ZeroPattern

variable {K : Type*} [Field K] [LinearOrder K] [IsStrictOrderedRing K]
variable {L : Type*} [Field L] [LinearOrder L] [IsStrictOrderedRing L]

theorem leadingCoeff_sign_eq_of_coeff_sign_agree (p : A[X])
    (f : A →+* K) (g : A →+* L)
    (h : ∀ i ≤ p.natDegree, sign (f (p.coeff i)) = sign (g (p.coeff i))) :
    sign (p.map f).leadingCoeff = sign (p.map g).leadingCoeff := by
  have hd := natDegree_map_eq_of_coeff_sign_agree p f g h
  rw [leadingCoeff, leadingCoeff, coeff_map, coeff_map, ← hd]
  exact h _ natDegree_map_le

theorem parity_leadingCoeff_sign_eq_of_coeff_sign_agree (p : A[X])
    (f : A →+* K) (g : A →+* L)
    (h : ∀ i ≤ p.natDegree, sign (f (p.coeff i)) = sign (g (p.coeff i))) :
    sign ((p.map f).leadingCoeff * (-1) ^ (p.map f).natDegree) =
      sign ((p.map g).leadingCoeff * (-1) ^ (p.map g).natDegree) := by
  simp only [sign_mul, sign_pow, Left.sign_neg, sign_one,
    leadingCoeff_sign_eq_of_coeff_sign_agree p f g h,
    natDegree_map_eq_of_coeff_sign_agree p f g h]

end Hilbert17Transfer
