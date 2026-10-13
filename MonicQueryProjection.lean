import UniformRootCount
import TauCeti.Geometry.RealAlgebraic.SignDetermination.Roots

/-!
Source-only draft; not yet elaborated or kernel-checked.

Uniform Tarski-query and BKR sign-count projection when the root polynomial is
monic over the coefficient ring. Specialization maps are arbitrary. A subsequent
localization-away step handles a general leading coefficient without leaving
new coefficients in either target field.
-/

namespace Hilbert17Transfer

open Polynomial SignType
open scoped Matrix

variable {A : Type*} [CommRing A]

noncomputable def monicQueryRemainder (p q : A[X]) : A[X] :=
  (p.derivative * q) %ₘ p

noncomputable def monicQueryProjection (p q : A[X]) : Finset A := by
  classical
  let r := monicQueryRemainder p q
  exact rootCountProjection r ∪
    (Finset.range (r.natDegree + 1)).biUnion fun e =>
      (Finset.range (p.natDegree + 1)).image fun j =>
        signedPsc p (r.reductum (e + 1)) p.natDegree e j

theorem remainderCoeff_mem_monicQueryProjection (p q : A[X]) {i : ℕ}
    (hi : i ≤ (monicQueryRemainder p q).natDegree) :
    (monicQueryRemainder p q).coeff i ∈ monicQueryProjection p q := by
  classical
  exact Finset.mem_union_left _ (coeff_mem_rootCountProjection _ hi)

theorem signedPsc_mem_monicQueryProjection (p q : A[X]) {e j : ℕ}
    (he : e ≤ (monicQueryRemainder p q).natDegree) (hj : j ≤ p.natDegree) :
    signedPsc p ((monicQueryRemainder p q).reductum (e + 1)) p.natDegree e j ∈
      monicQueryProjection p q := by
  classical
  apply Finset.mem_union_right
  apply Finset.mem_biUnion.mpr
  refine ⟨e, Finset.mem_range.mpr (Nat.lt_succ_of_le he), ?_⟩
  exact Finset.mem_image.mpr ⟨j, Finset.mem_range.mpr (Nat.lt_succ_of_le hj), rfl⟩

variable {K : Type*} [Field K] [LinearOrder K] [IsStrictOrderedRing K] [IsRealClosed K]

theorem monicQueryRemainder_map (p q : A[X]) (hp : p.Monic) (f : A →+* K) :
    (monicQueryRemainder p q).map f =
      (p.map f).derivative * q.map f % p.map f := by
  unfold monicQueryRemainder
  rw [map_modByMonic f hp, modByMonic_eq_mod _ (hp.map f),
    Polynomial.map_mul, ← derivative_map]

theorem tarskiQuery_map_eq_pmv_monicRemainder (p q : A[X]) (hp : p.Monic)
    (f : A →+* K) (e : ℕ) (he : ((monicQueryRemainder p q).map f).natDegree = e) :
    (p.map f).tarskiQuery (q.map f) =
      (((List.range (p.natDegree + 1)).reverse.map fun j =>
        f (signedPsc p ((monicQueryRemainder p q).reductum (e + 1))
          p.natDegree e j))).permanencesMinusVariations := by
  rw [tarskiQuery_eq_permanencesMinusVariations_signedPsc,
    ← monicQueryRemainder_map p q hp f, hp.natDegree_map f, he]
  have hr : (monicQueryRemainder p q).map f =
      ((monicQueryRemainder p q).reductum (e + 1)).map f := by
    rw [← he, map_reductum_natDegree_map_add_one]
  rw [hr]
  have hs :
      signedPsc (p.map f) (((monicQueryRemainder p q).reductum (e + 1)).map f)
        p.natDegree e =
      fun j => f (signedPsc p ((monicQueryRemainder p q).reductum (e + 1))
        p.natDegree e j) :=
    funext fun j => signedPsc_map_map f _ _ p.natDegree e j
  rw [hs]

variable {L : Type*} [Field L] [LinearOrder L] [IsStrictOrderedRing L] [IsRealClosed L]

/-- A single explicitly finite sign projection controls a Tarski query in all target RCFs.
The monicity assumption is on the coefficient-ring polynomial, not on each target separately. -/
theorem tarskiQuery_map_eq_of_monicProjection_sign_agree (p q : A[X]) (hp : p.Monic)
    (f : A →+* K) (g : A →+* L)
    (h : ∀ a ∈ monicQueryProjection p q, sign (f a) = sign (g a)) :
    (p.map f).tarskiQuery (q.map f) = (p.map g).tarskiQuery (q.map g) := by
  let r := monicQueryRemainder p q
  have hc : ∀ i ≤ r.natDegree, sign (f (r.coeff i)) = sign (g (r.coeff i)) :=
    fun i hi => h _ (remainderCoeff_mem_monicQueryProjection p q hi)
  have hdeg := natDegree_map_eq_of_coeff_sign_agree r f g hc
  let e := (r.map f).natDegree
  have hef : (r.map f).natDegree = e := rfl
  have heg : (r.map g).natDegree = e := hdeg.symm
  have he : e ≤ r.natDegree := natDegree_map_le
  rw [tarskiQuery_map_eq_pmv_monicRemainder p q hp f e hef,
    tarskiQuery_map_eq_pmv_monicRemainder p q hp g e heg]
  apply List.permanencesMinusVariations_congr
  simp only [List.map_map]
  apply List.map_congr_left
  intro j hj
  have hjd : j ≤ p.natDegree := by
    simpa only [List.mem_reverse, List.mem_range, Nat.lt_succ_iff] using hj
  exact h _ (signedPsc_mem_monicQueryProjection p q he hjd)

section Patterns

variable {J : Type*} [Fintype J] [DecidableEq J]

/-- The finite union of projections for all BKR exponent vectors. -/
noncomputable def monicPatternProjection (p : A[X]) (Q : J → A[X]) : Finset A := by
  classical
  exact Finset.univ.biUnion fun e : J → Fin 3 =>
    monicQueryProjection p (∏ j, Q j ^ (e j).val)

/-- The same original coefficient signs determine every root sign-pattern count. -/
theorem signCount_map_eq_of_monicPatternProjection_sign_agree
    (p : A[X]) (hp : p.Monic) (Q : J → A[X])
    (f : A →+* K) (g : A →+* L)
    (h : ∀ a ∈ monicPatternProjection p Q, sign (f a) = sign (g a))
    (σ : J → SignType) :
    Finset.signCount (p.map f).roots.toFinset (fun j => (Q j).map f) σ =
      Finset.signCount (p.map g).roots.toFinset (fun j => (Q j).map g) σ := by
  classical
  have hquery (e : J → Fin 3) :
      (p.map f).tarskiQuery (∏ j, ((Q j).map f) ^ (e j).val) =
        (p.map g).tarskiQuery (∏ j, ((Q j).map g) ^ (e j).val) := by
    have he : ∀ a ∈ monicQueryProjection p (∏ j, Q j ^ (e j).val),
        sign (f a) = sign (g a) := by
      intro a ha
      exact h a (Finset.mem_biUnion.mpr ⟨e, Finset.mem_univ _, ha⟩)
    have ht := tarskiQuery_map_eq_of_monicProjection_sign_agree
      p (∏ j, Q j ^ (e j).val) hp f g he
    simpa only [Polynomial.map_prod, Polynomial.map_pow] using ht
  have hmom :
      (fun e : J → Fin 3 =>
        ((p.map f).tarskiQuery (∏ j, ((Q j).map f) ^ (e j).val) : ℚ)) =
      (fun e : J → Fin 3 =>
        ((p.map g).tarskiQuery (∏ j, ((Q j).map g) ^ (e j).val) : ℚ)) := by
    funext e
    rw [hquery e]
  have hf := congrFun
    (Polynomial.fullInverse_mulVec_tarskiQuery (p.map f) (fun j => (Q j).map f)) σ
  have hg := congrFun
    (Polynomial.fullInverse_mulVec_tarskiQuery (p.map g) (fun j => (Q j).map g)) σ
  rw [hmom] at hf
  exact_mod_cast hf.symm.trans hg

/-- Uniform root sign-pattern existence for a monic root polynomial. -/
theorem exists_root_signs_map_iff_of_monicPatternProjection_sign_agree
    (p : A[X]) (hp : p.Monic) (Q : J → A[X])
    (f : A →+* K) (g : A →+* L)
    (h : ∀ a ∈ monicPatternProjection p Q, sign (f a) = sign (g a))
    (σ : J → SignType) :
    (∃ x : K, (p.map f).eval x = 0 ∧ ∀ j, sign (((Q j).map f).eval x) = σ j) ↔
      (∃ y : L, (p.map g).eval y = 0 ∧ ∀ j, sign (((Q j).map g).eval y) = σ j) := by
  have hc := signCount_map_eq_of_monicPatternProjection_sign_agree p hp Q f g h σ
  have he :
      (0 < Finset.signCount (p.map f).roots.toFinset (fun j => (Q j).map f) σ) ↔
      (0 < Finset.signCount (p.map g).roots.toFinset (fun j => (Q j).map g) σ) := by
    rw [hc]
  simpa only [Finset.signCount_pos, Multiset.mem_toFinset,
    mem_roots (hp.map f).ne_zero, mem_roots (hp.map g).ne_zero, IsRoot.def] using he

end Patterns

end Hilbert17Transfer
