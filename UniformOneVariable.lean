import GeneralPatternProjection
import WholeLineAlternatives

/-!
Source-only draft; not yet elaborated or kernel-checked.

A finite set of coefficients in the ORIGINAL ring controls simultaneous
one-variable sign realization in ANY two ordered real closed fields. The
coefficient maps need not be injective. The finite union over active subsets
handles input polynomials that become zero under specialization.
-/

namespace Hilbert17Transfer

open Polynomial Finset SignType
open TauCeti.SignDetermination

variable {A : Type*} [CommRing A]
variable {K : Type*} [Field K] [LinearOrder K] [IsStrictOrderedRing K] [IsRealClosed K]
variable {L : Type*} [Field L] [LinearOrder L] [IsStrictOrderedRing L] [IsRealClosed L]

variable {J : Type*} [Fintype J] [DecidableEq J]

noncomputable def subsetProduct (Q : J → A[X]) (S : Finset J) : A[X] :=
  ∏ j ∈ S, Q j

private theorem map_subsetProduct_eq_sampleProduct
    {B : Type*} [CommRing B] (Q : J → A[X]) (f : A →+* B) (S : Finset J)
    (hS : ∀ j, j ∈ S ↔ (Q j).map f ≠ 0) :
    (subsetProduct Q S).map f = sampleProduct (fun j => (Q j).map f) := by
  classical
  rw [subsetProduct, Polynomial.map_prod, sampleProduct_def]
  apply Finset.prod_congr
  · ext j
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
    exact hS j
  · intro j _
    rfl

noncomputable def wholeLineProjection (Q : J → A[X]) : Finset A := by
  classical
  exact (Finset.univ.biUnion fun j => rootCountProjection (Q j)) ∪
    (Finset.univ : Finset (Finset J)).biUnion fun S =>
      patternProjection (subsetProduct Q S) Q ∪
      patternProjection (subsetProduct Q S).derivative Q

theorem coeff_mem_wholeLineProjection (Q : J → A[X]) (j : J) {i : ℕ}
    (hi : i ≤ (Q j).natDegree) : (Q j).coeff i ∈ wholeLineProjection Q := by
  classical
  exact Finset.mem_union_left _ (Finset.mem_biUnion.mpr
    ⟨j, Finset.mem_univ _, coeff_mem_rootCountProjection (Q j) hi⟩)

theorem patternProjection_subset_wholeLineProjection (Q : J → A[X]) (S : Finset J) :
    patternProjection (subsetProduct Q S) Q ⊆ wholeLineProjection Q := by
  classical
  intro a ha
  exact Finset.mem_union_right _ (Finset.mem_biUnion.mpr
    ⟨S, Finset.mem_univ _, Finset.mem_union_left _ ha⟩)

theorem derivativePatternProjection_subset_wholeLineProjection
    (Q : J → A[X]) (S : Finset J) :
    patternProjection (subsetProduct Q S).derivative Q ⊆ wholeLineProjection Q := by
  classical
  intro a ha
  exact Finset.mem_union_right _ (Finset.mem_biUnion.mpr
    ⟨S, Finset.mem_univ _, Finset.mem_union_right _ ha⟩)

/-- Coefficient-preserving paired-model one-variable elimination.
The finite projection is selected before either target field or map is given. -/
theorem exists_signs_map_iff_of_wholeLineProjection_sign_agree
    (Q : J → A[X]) (f : A →+* K) (g : A →+* L)
    (h : ∀ a ∈ wholeLineProjection Q, sign (f a) = sign (g a))
    (σ : J → SignType) :
    (∃ x : K, ∀ j, sign (((Q j).map f).eval x) = σ j) ↔
      (∃ y : L, ∀ j, sign (((Q j).map g).eval y) = σ j) := by
  classical
  have hc (j : J) : ∀ i ≤ (Q j).natDegree,
      sign (f ((Q j).coeff i)) = sign (g ((Q j).coeff i)) :=
    fun i hi => h _ (coeff_mem_wholeLineProjection Q j hi)
  have hz (j : J) : (Q j).map f = 0 ↔ (Q j).map g = 0 :=
    map_eq_zero_iff_of_coeff_sign_agree (Q j) f g (hc j)
  let S : Finset J := Finset.univ.filter (fun j => (Q j).map f ≠ 0)
  have hS : S = Finset.univ.filter (fun j => (Q j).map g ≠ 0) := by
    ext j
    simp only [S, Finset.mem_filter, Finset.mem_univ, true_and]
    exact not_congr (hz j)
  let P : A[X] := subsetProduct Q S
  have hPf : P.map f = sampleProduct (fun j => (Q j).map f) := by
    apply map_subsetProduct_eq_sampleProduct Q f S
    intro j
    simp only [S, Finset.mem_filter, Finset.mem_univ, true_and]
  have hPg : P.map g = sampleProduct (fun j => (Q j).map g) := by
    apply map_subsetProduct_eq_sampleProduct Q g S
    intro j
    rw [hS]
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
  have hr := exists_root_signs_map_iff_of_patternProjection_sign_agree
    P Q f g (fun a ha => h a (patternProjection_subset_wholeLineProjection Q S ha)) σ
  rw [hPf, hPg] at hr
  have hd := exists_root_signs_map_iff_of_patternProjection_sign_agree
    P.derivative Q f g
    (fun a ha => h a (derivativePatternProjection_subset_wholeLineProjection Q S ha)) σ
  rw [← derivative_map, ← derivative_map, hPf, hPg] at hd
  have htop :
      (∀ j, sign ((Q j).map f).leadingCoeff = σ j) ↔
      (∀ j, sign ((Q j).map g).leadingCoeff = σ j) := by
    constructor
    · intro hs j
      exact (leadingCoeff_sign_eq_of_coeff_sign_agree (Q j) f g (hc j)).symm.trans (hs j)
    · intro hs j
      exact (leadingCoeff_sign_eq_of_coeff_sign_agree (Q j) f g (hc j)).trans (hs j)
  have hbot :
      (∀ j, sign (((Q j).map f).leadingCoeff * (-1) ^ ((Q j).map f).natDegree) = σ j) ↔
      (∀ j, sign (((Q j).map g).leadingCoeff * (-1) ^ ((Q j).map g).natDegree) = σ j) := by
    constructor
    · intro hs j
      exact (parity_leadingCoeff_sign_eq_of_coeff_sign_agree (Q j) f g (hc j)).symm.trans (hs j)
    · intro hs j
      exact (parity_leadingCoeff_sign_eq_of_coeff_sign_agree (Q j) f g (hc j)).trans (hs j)
  rw [exists_signs_iff_root_derivative_infinity, exists_signs_iff_root_derivative_infinity]
  exact or_congr hr (or_congr hd (or_congr hbot htop))

end Hilbert17Transfer
