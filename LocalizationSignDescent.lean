import Mathlib.RingTheory.Localization.Away.Basic
import Mathlib.Data.Sign.Basic

/-!
Source-only draft against pinned Mathlib. Not yet elaborated or kernel-checked.

Uniform denominator clearing for sign conditions: a finite set of coefficients
in A[c⁻¹] is controlled by a finite set in A. This lemma is valid for arbitrary
coefficient specializations into ordered fields, without injectivity and without
real-closedness. It is the denominator step for uniform Tarski-query projection.
-/

namespace Hilbert17Transfer

open SignType

variable {A B : Type*} [CommRing A] [CommRing B] [Algebra A B]
variable (c : A) [IsLocalization.Away c B]

/-- Include the inverted element and one numerator for every requested coefficient.
`Away.sec_spec` certifies its chosen denominator is a power of c. -/
noncomputable def awaySignProjection (T : Finset B) : Finset A := by
  classical
  exact insert c (T.image fun b => (IsLocalization.Away.sec c b).1)

theorem self_mem_awaySignProjection (T : Finset B) : c ∈ awaySignProjection c T := by
  classical
  exact Finset.mem_insert_self _ _

theorem numerator_mem_awaySignProjection (T : Finset B) {b : B} (hb : b ∈ T) :
    (IsLocalization.Away.sec c b).1 ∈ awaySignProjection c T := by
  classical
  apply Finset.mem_insert_of_mem
  exact Finset.mem_image.mpr ⟨b, hb, rfl⟩

variable {K L : Type*} [Field K] [LinearOrder K] [IsStrictOrderedRing K]
  [Field L] [LinearOrder L] [IsStrictOrderedRing L]

/-- Equality of a finite collection of signs in A implies the requested sign
equalities in A[c⁻¹]. Maps out of the localization automatically send c to a unit. -/
theorem sign_eq_on_localization_of_sign_eq_on_projection (T : Finset B)
    (F : B →+* K) (G : B →+* L)
    (h : ∀ a ∈ awaySignProjection c T,
      sign (F (algebraMap A B a)) = sign (G (algebraMap A B a))) :
    ∀ b ∈ T, sign (F b) = sign (G b) := by
  intro b hb
  have hc := h c (self_mem_awaySignProjection c T)
  have hn := h _ (numerator_mem_awaySignProjection c T hb)
  have hF := congrArg F (IsLocalization.Away.sec_spec c b)
  have hG := congrArg G (IsLocalization.Away.sec_spec c b)
  simp only [map_mul, map_pow] at hF hG
  rw [← hF, ← hG, sign_mul, sign_mul, sign_pow, sign_pow, hc] at hn
  have hcG : G (algebraMap A B c) ≠ 0 :=
    ((IsLocalization.Away.algebraMap_isUnit c).map G).ne_zero
  exact mul_right_cancel₀
    (pow_ne_zero _ (sign_ne_zero.mpr hcG)) hn

end Hilbert17Transfer
