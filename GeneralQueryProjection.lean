import MonicQueryProjection
import LocalizationSignDescent
import DegreeNormalization

/-!
Source-only draft. No elaboration/kernel verification has been performed.

Uniform Tarski-query projection for arbitrary source polynomials. Each possible
specialized degree d selects c = coeff p d, localizes the ORIGINAL coefficient
ring away from c, and normalizes the corresponding reductum to a monic polynomial.
The finite localization coefficients are then descended to numerators in A.
Zero specialization is a separate branch. No injectivity of coefficient maps,
Archimedean hypothesis, or transfer axiom is used.
-/

namespace Hilbert17Transfer

open Polynomial SignType

variable {A : Type*} [CommRing A]

variable {K : Type*} [Field K]

noncomputable def queryDegreeBranchProjection (p q : A[X]) (d : ℕ) : Finset A :=
  awaySignProjection (p.coeff d)
    (monicQueryProjection (normalizedAtDegree p d)
      (q.map (algebraMap A (Localization.Away (p.coeff d)))))

noncomputable def queryProjection (p q : A[X]) : Finset A := by
  classical
  exact rootCountProjection p ∪
    (Finset.range (p.natDegree + 1)).biUnion (queryDegreeBranchProjection p q)

theorem rootCountProjection_subset_queryProjection (p q : A[X]) :
    rootCountProjection p ⊆ queryProjection p q := by
  classical
  exact Finset.subset_union_left

theorem queryDegreeBranchProjection_subset (p q : A[X]) {d : ℕ} (hd : d ≤ p.natDegree) :
    queryDegreeBranchProjection p q d ⊆ queryProjection p q := by
  classical
  intro a ha
  exact Finset.mem_union_right _ (Finset.mem_biUnion.mpr
    ⟨d, Finset.mem_range.mpr (Nat.lt_succ_of_le hd), ha⟩)

variable [LinearOrder K] [IsStrictOrderedRing K] [IsRealClosed K]

theorem tarskiQuery_C_mul_left (p q : K[X]) {c : K} (hc : c ≠ 0) :
    (C c * p).tarskiQuery q = p.tarskiQuery q := by
  rw [tarskiQuery_eq_signSum, tarskiQuery_eq_signSum, roots_C_mul p hc]

variable {L : Type*} [Field L] [LinearOrder L] [IsStrictOrderedRing L] [IsRealClosed L]

/-- A source-ring finite sign projection controls a Tarski query across arbitrary RCFs.
This includes the case when either specialization of p is zero or constant. -/
theorem tarskiQuery_map_eq_of_queryProjection_sign_agree (p q : A[X])
    (f : A →+* K) (g : A →+* L)
    (h : ∀ a ∈ queryProjection p q, sign (f a) = sign (g a)) :
    (p.map f).tarskiQuery (q.map f) = (p.map g).tarskiQuery (q.map g) := by
  have hc : ∀ i ≤ p.natDegree, sign (f (p.coeff i)) = sign (g (p.coeff i)) :=
    fun i hi => h _ (rootCountProjection_subset_queryProjection p q
      (coeff_mem_rootCountProjection p hi))
  have hz := map_eq_zero_iff_of_coeff_sign_agree p f g hc
  by_cases hf : p.map f = 0
  · have hg := hz.mp hf
    simp [hf, hg]
  have hg : p.map g ≠ 0 := fun hg => hf (hz.mpr hg)
  let d := (p.map f).natDegree
  have hdf : (p.map f).natDegree = d := rfl
  have hdg : (p.map g).natDegree = d :=
    (natDegree_map_eq_of_coeff_sign_agree p f g hc).symm
  have hd : d ≤ p.natDegree := natDegree_map_le
  have hfc : f (p.coeff d) ≠ 0 := by
    rw [← coeff_map, ← hdf, coeff_natDegree]
    exact leadingCoeff_ne_zero.mpr hf
  have hgc : g (p.coeff d) ≠ 0 := by
    rw [← coeff_map, ← hdg, coeff_natDegree]
    exact leadingCoeff_ne_zero.mpr hg
  let B := Localization.Away (p.coeff d)
  let F : B →+* K := Localization.awayLift f (p.coeff d) (isUnit_iff_ne_zero.mpr hfc)
  let G : B →+* L := Localization.awayLift g (p.coeff d) (isUnit_iff_ne_zero.mpr hgc)
  let P : B[X] := normalizedAtDegree p d
  let Q : B[X] := q.map (algebraMap A B)
  have hloc : ∀ b ∈ monicQueryProjection P Q, sign (F b) = sign (G b) := by
    apply sign_eq_on_localization_of_sign_eq_on_projection (p.coeff d)
    intro a ha
    have hh := h a (queryDegreeBranchProjection_subset p q hd ha)
    simpa only [F, G, IsLocalization.Away.lift_eq] using hh
  have ht := tarskiQuery_map_eq_of_monicProjection_sign_agree
    P Q (normalizedAtDegree_monic p d) F G hloc
  have hPf : P.map F = C ((f (p.coeff d))⁻¹) * p.map f :=
    normalizedAtDegree_map p d f hdf hfc
  have hPg : P.map G = C ((g (p.coeff d))⁻¹) * p.map g :=
    normalizedAtDegree_map p d g hdg hgc
  have hQf : Q.map F = q.map f := by
    simp only [Q, Polynomial.map_map, F, IsLocalization.Away.lift_comp]
  have hQg : Q.map G = q.map g := by
    simp only [Q, Polynomial.map_map, G, IsLocalization.Away.lift_comp]
  rw [hPf, hPg, hQf, hQg,
    tarskiQuery_C_mul_left _ _ (inv_ne_zero hfc),
    tarskiQuery_C_mul_left _ _ (inv_ne_zero hgc)] at ht
  exact ht

end Hilbert17Transfer
