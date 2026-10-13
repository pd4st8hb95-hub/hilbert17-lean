import GeneralQueryProjection

/-!
Source-only draft; not yet elaborated or kernel-checked.
A finite original-coefficient projection controls every BKR root-pattern count
under arbitrary specializations into two real closed fields.
-/

namespace Hilbert17Transfer

open Polynomial SignType
open scoped Matrix

variable {A : Type*} [CommRing A]
variable {K : Type*} [Field K] [LinearOrder K] [IsStrictOrderedRing K] [IsRealClosed K]
variable {L : Type*} [Field L] [LinearOrder L] [IsStrictOrderedRing L] [IsRealClosed L]

section Patterns

variable {J : Type*} [Fintype J] [DecidableEq J]

/-- The finite union of projections for all BKR exponent vectors. -/
noncomputable def patternProjection (p : A[X]) (Q : J → A[X]) : Finset A := by
  classical
  exact Finset.univ.biUnion fun e : J → Fin 3 =>
    queryProjection p (∏ j, Q j ^ (e j).val)

/-- The same original coefficient signs determine every root sign-pattern count. -/
theorem signCount_map_eq_of_patternProjection_sign_agree
    (p : A[X]) (Q : J → A[X])
    (f : A →+* K) (g : A →+* L)
    (h : ∀ a ∈ patternProjection p Q, sign (f a) = sign (g a))
    (σ : J → SignType) :
    Finset.signCount (p.map f).roots.toFinset (fun j => (Q j).map f) σ =
      Finset.signCount (p.map g).roots.toFinset (fun j => (Q j).map g) σ := by
  classical
  have hquery (e : J → Fin 3) :
      (p.map f).tarskiQuery (∏ j, ((Q j).map f) ^ (e j).val) =
        (p.map g).tarskiQuery (∏ j, ((Q j).map g) ^ (e j).val) := by
    have he : ∀ a ∈ queryProjection p (∏ j, Q j ^ (e j).val),
        sign (f a) = sign (g a) := by
      intro a ha
      exact h a (Finset.mem_biUnion.mpr ⟨e, Finset.mem_univ _, ha⟩)
    have ht := tarskiQuery_map_eq_of_queryProjection_sign_agree
      p (∏ j, Q j ^ (e j).val) f g he
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

/-- Uniform root sign-pattern existence as finite-root-set membership. This remains valid for p = 0. -/
theorem exists_root_signs_map_iff_of_patternProjection_sign_agree
    (p : A[X]) (Q : J → A[X])
    (f : A →+* K) (g : A →+* L)
    (h : ∀ a ∈ patternProjection p Q, sign (f a) = sign (g a))
    (σ : J → SignType) :
    (∃ x ∈ (p.map f).roots.toFinset, ∀ j, sign (((Q j).map f).eval x) = σ j) ↔
      (∃ y ∈ (p.map g).roots.toFinset, ∀ j, sign (((Q j).map g).eval y) = σ j) := by
  have hc := signCount_map_eq_of_patternProjection_sign_agree p Q f g h σ
  have he :
      (0 < Finset.signCount (p.map f).roots.toFinset (fun j => (Q j).map f) σ) ↔
      (0 < Finset.signCount (p.map g).roots.toFinset (fun j => (Q j).map g) σ) := by
    rw [hc]
  simpa only [Finset.signCount_pos] using he

end Patterns

end Hilbert17Transfer
