import TauCeti.RingTheory.Polynomial.Reductum
import Mathlib.RingTheory.Localization.Away.Basic
import Mathlib.Algebra.Polynomial.FieldDivision

/-!
Source-only degree-branch normalization, isolated for independent checking.
This algebraic component needs no real-closed-field or BKR imports.
-/

namespace Hilbert17Transfer

open Polynomial

variable {A : Type*} [CommRing A]

noncomputable def normalizedAtDegree (p : A[X]) (d : ℕ) :
    (Localization.Away (p.coeff d))[X] :=
  C (IsLocalization.Away.invSelf (p.coeff d)) *
    (p.reductum (d + 1)).map (algebraMap A (Localization.Away (p.coeff d)))

/-- The normalized polynomial is monic even in inactive branches.
When the localization is trivial, monicity is the trivial equality 0 = 1. -/
theorem normalizedAtDegree_monic (p : A[X]) (d : ℕ) :
    (normalizedAtDegree p d).Monic := by
  let B := Localization.Away (p.coeff d)
  let c := p.coeff d
  let q : B[X] := (p.reductum (d + 1)).map (algebraMap A B)
  change (C (IsLocalization.Away.invSelf c) * q).Monic
  rcases subsingleton_or_nontrivial B with hB | hB
  · letI := hB
    change (C (IsLocalization.Away.invSelf c) * q).leadingCoeff = 1
    exact Subsingleton.elim _ _
  · letI := hB
    have hc : algebraMap A B c ≠ 0 :=
      (IsLocalization.Away.algebraMap_isUnit c).ne_zero
    have hqd : q.natDegree = d := by
      apply natDegree_eq_of_le_of_coeff_ne_zero
      · exact natDegree_map_le.trans (Nat.lt_succ_iff.mp (p.natDegree_reductum_lt d))
      · simpa only [q, coeff_map, coeff_reductum, Nat.lt_succ_self, if_true] using hc
    have hlc : q.leadingCoeff = algebraMap A B c := by
      rw [leadingCoeff, hqd]
      simp [q, c]
    apply monic_C_mul_of_mul_leadingCoeff_eq_one
    rw [hlc, mul_comm]
    exact IsLocalization.Away.mul_invSelf c

variable {K : Type*} [Field K]

theorem awayLift_invSelf (c : A) (f : A →+* K) (hc : f c ≠ 0) :
    Localization.awayLift f c (isUnit_iff_ne_zero.mpr hc)
      (IsLocalization.Away.invSelf c) = (f c)⁻¹ := by
  apply eq_inv_of_mul_eq_one_right
  have h := congrArg (Localization.awayLift f c (isUnit_iff_ne_zero.mpr hc))
    (IsLocalization.Away.mul_invSelf c (S := Localization.Away c))
  simpa only [map_mul, map_one, IsLocalization.Away.lift_eq] using h

theorem normalizedAtDegree_map (p : A[X]) (d : ℕ) (f : A →+* K)
    (hd : (p.map f).natDegree = d) (hc : f (p.coeff d) ≠ 0) :
    (normalizedAtDegree p d).map
      (Localization.awayLift f (p.coeff d) (isUnit_iff_ne_zero.mpr hc)) =
        C ((f (p.coeff d))⁻¹) * p.map f := by
  have htrunc : (p.reductum (d + 1)).map f = p.map f := by
    simpa only [hd] using map_reductum_natDegree_map_add_one f p
  unfold normalizedAtDegree
  simp only [Polynomial.map_mul, Polynomial.map_C, Polynomial.map_map,
    IsLocalization.Away.lift_comp]
  rw [awayLift_invSelf (p.coeff d) f hc, htrunc]

end Hilbert17Transfer
