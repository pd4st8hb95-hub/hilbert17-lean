import TauCeti.RingTheory.Polynomial.Subresultant.CauchyIndex
import TauCeti.RingTheory.Polynomial.Reductum
import CoefficientSignPattern

/-!
Source-only proof draft; not elaborated or kernel-checked.
Requires audited TauCeti dependencies at 6b896c7c411221eb78639e4be8ead6e479a62893.

This file gives a two-model, coefficient-preserving projection lemma for the
number of distinct roots of a univariate polynomial. Coefficient maps need not
be injective, and their target real-closed fields need not be Archimedean.
Zero specialization and degree drops are included. The projection is a finite
set in the ORIGINAL coefficient ring, chosen before either target field.

This is a partial bridge, not full quantifier elimination or Hilbert 17.
-/

namespace Hilbert17Transfer

open Polynomial SignType

variable {A : Type*} [CommRing A]

/-- All coefficient signs and all degree-branch root-count subresultant signs.
The actual degree after specialization selects one of the finitely many branches. -/
noncomputable def rootCountProjection (p : A[X]) : Finset A := by
  classical
  exact (Finset.range (p.natDegree + 1)).image p.coeff ∪
    (Finset.range (p.natDegree + 1)).biUnion fun d =>
      (Finset.range (d + 1)).image fun j =>
        signedPsc (p.reductum (d + 1)) (p.reductum (d + 1)).derivative d (d - 1) j

theorem coeff_mem_rootCountProjection (p : A[X]) {i : ℕ} (hi : i ≤ p.natDegree) :
    p.coeff i ∈ rootCountProjection p := by
  classical
  apply Finset.mem_union_left
  exact Finset.mem_image.mpr ⟨i, Finset.mem_range.mpr (Nat.lt_succ_of_le hi), rfl⟩

theorem signedPsc_mem_rootCountProjection (p : A[X]) {d j : ℕ}
    (hd : d ≤ p.natDegree) (hj : j ≤ d) :
    signedPsc (p.reductum (d + 1)) (p.reductum (d + 1)).derivative d (d - 1) j ∈
      rootCountProjection p := by
  classical
  apply Finset.mem_union_right
  apply Finset.mem_biUnion.mpr
  refine ⟨d, Finset.mem_range.mpr (Nat.lt_succ_of_le hd), ?_⟩
  exact Finset.mem_image.mpr ⟨j, Finset.mem_range.mpr (Nat.lt_succ_of_le hj), rfl⟩



/-- A separately universe-polymorphic helper, usable for two unrelated target universes. -/
theorem exists_eval_eq_zero_iff_roots_card_pos
    {F : Type*} [Field F] [DecidableEq F] (q : F[X]) (hq : q ≠ 0) :
    (∃ x : F, q.eval x = 0) ↔ 0 < q.roots.toFinset.card := by
  rw [Finset.card_pos]
  simp only [Finset.Nonempty, Multiset.mem_toFinset, mem_roots hq, IsRoot.def]

section Count

variable {K : Type*} [Field K] [LinearOrder K] [IsStrictOrderedRing K] [IsRealClosed K]

/-- Fixed degree-branch formula, with every signed coefficient in the original ring A. -/
theorem rootCount_map_eq_pmv_reductum (p : A[X]) (f : A →+* K) (d : ℕ)
    (hd : (p.map f).natDegree = d) :
    ((p.map f).roots.toFinset.card : ℤ) =
      (((List.range (d + 1)).reverse.map fun j =>
        f (signedPsc (p.reductum (d + 1))
          (p.reductum (d + 1)).derivative d (d - 1) j))).permanencesMinusVariations := by
  rw [card_roots_toFinset_eq_permanencesMinusVariations_signedPsc,
    natDegree_derivative, hd]
  have hp : p.map f = (p.reductum (d + 1)).map f := by
    rw [← hd, map_reductum_natDegree_map_add_one]
  rw [hp, derivative_map]
  have hs :
      signedPsc ((p.reductum (d + 1)).map f)
        ((p.reductum (d + 1)).derivative.map f) d (d - 1) =
      fun j => f (signedPsc (p.reductum (d + 1))
        (p.reductum (d + 1)).derivative d (d - 1) j) :=
    funext fun j => signedPsc_map_map f _ _ d (d - 1) j
  rw [hs]

variable {L : Type*} [Field L] [LinearOrder L] [IsStrictOrderedRing L] [IsRealClosed L]

/-- Uniform two-model root-count transfer from an explicitly finite coefficient projection.
Both specialization maps may kill coefficients; the coefficient ring is unchanged. -/
theorem rootCount_map_eq_of_projection_sign_agree (p : A[X])
    (f : A →+* K) (g : A →+* L)
    (h : ∀ a ∈ rootCountProjection p, sign (f a) = sign (g a)) :
    (p.map f).roots.toFinset.card = (p.map g).roots.toFinset.card := by
  have hcoeff : ∀ i ≤ p.natDegree, sign (f (p.coeff i)) = sign (g (p.coeff i)) :=
    fun i hi => h _ (coeff_mem_rootCountProjection p hi)
  have hdeg := natDegree_map_eq_of_coeff_sign_agree p f g hcoeff
  let d := (p.map f).natDegree
  have hdf : (p.map f).natDegree = d := rfl
  have hdg : (p.map g).natDegree = d := hdeg.symm
  have hd : d ≤ p.natDegree := natDegree_map_le
  apply Int.natCast_inj.mp
  rw [rootCount_map_eq_pmv_reductum p f d hdf, rootCount_map_eq_pmv_reductum p g d hdg]
  apply List.permanencesMinusVariations_congr
  simp only [List.map_map]
  apply List.map_congr_left
  intro j hj
  have hjd : j ≤ d := by
    simpa only [List.mem_reverse, List.mem_range, Nat.lt_succ_iff] using hj
  exact h _ (signedPsc_mem_rootCountProjection p hd hjd)

/-- Existence of a zero transfers too, including the zero-polynomial branch.
Do not infer this from a positive roots-card alone, since `roots 0` is empty. -/
theorem exists_root_map_iff_of_projection_sign_agree (p : A[X])
    (f : A →+* K) (g : A →+* L)
    (h : ∀ a ∈ rootCountProjection p, sign (f a) = sign (g a)) :
    (∃ x : K, (p.map f).eval x = 0) ↔ (∃ y : L, (p.map g).eval y = 0) := by
  classical
  have hcoeff : ∀ i ≤ p.natDegree, sign (f (p.coeff i)) = sign (g (p.coeff i)) :=
    fun i hi => h _ (coeff_mem_rootCountProjection p hi)
  have hz := map_eq_zero_iff_of_coeff_sign_agree p f g hcoeff
  by_cases hf : p.map f = 0
  · have hg := hz.mp hf
    simp [hf, hg]
  have hg : p.map g ≠ 0 := fun hg => hf (hz.mpr hg)
  have hcard := rootCount_map_eq_of_projection_sign_agree p f g h
  rw [exists_eval_eq_zero_iff_roots_card_pos _ hf,
    exists_eval_eq_zero_iff_roots_card_pos _ hg, hcard]

end Count

end Hilbert17Transfer
