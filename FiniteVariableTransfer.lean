import UniformOneVariable
import FinSuccEvaluation
import Mathlib.Data.Fintype.EquivFin

/-!
Source-only draft; not yet elaborated or kernel-checked.

Finite-variable sign transfer by induction. At each step the one-variable
projection is a finite family of polynomials over the original coefficient
ring. Reindexing that finite family by Fin keeps the induction universe-safe.
No same-model quantifier-elimination theorem is used as an extension principle.
-/

namespace Hilbert17Transfer

open SignType

variable {A : Type*} [CommRing A]

variable {K : Type*} [Field K] [LinearOrder K] [IsStrictOrderedRing K] [IsRealClosed K]
variable {L : Type*} [Field L] [LinearOrder L] [IsStrictOrderedRing L] [IsRealClosed L]

/-- Any finite polynomial sign pattern transfers between two real closed fields
whose maps from the coefficient ring agree on all coefficient signs. -/
theorem exists_matching_signs_eval₂ (f : A →+* K) (g : A →+* L)
    (hfg : ∀ a : A, sign (f a) = sign (g a))
    (n m : ℕ) (Q : Fin m → MvPolynomial (Fin n) A) (x : Fin n → K) :
    ∃ y : Fin n → L, ∀ j,
      sign (MvPolynomial.eval₂ g y (Q j)) = sign (MvPolynomial.eval₂ f x (Q j)) := by
  classical
  induction n generalizing m with
  | zero =>
      refine ⟨Fin.elim0, fun j => ?_⟩
      rw [MvPolynomial.eq_C_of_isEmpty (Q j)]
      simpa only [MvPolynomial.eval₂_C] using (hfg ((Q j).coeff 0)).symm
  | succ n ih =>
      let U : Fin m → Polynomial (MvPolynomial (Fin n) A) :=
        fun j => MvPolynomial.finSuccEquiv A n (Q j)
      let S : Finset (MvPolynomial (Fin n) A) := wholeLineProjection U
      let E : Fin S.card → MvPolynomial (Fin n) A :=
        fun i => ((S.equivFin).symm i).val
      let xs : Fin n → K := fun i => x i.succ
      obtain ⟨ys, hys⟩ := ih S.card E xs
      let F : MvPolynomial (Fin n) A →+* K := MvPolynomial.eval₂Hom f xs
      let G : MvPolynomial (Fin n) A →+* L := MvPolynomial.eval₂Hom g ys
      have hS : ∀ a ∈ wholeLineProjection U, sign (F a) = sign (G a) := by
        intro a ha
        change sign (MvPolynomial.eval₂ f xs a) = sign (MvPolynomial.eval₂ g ys a)
        have hs := hys (S.equivFin ⟨a, ha⟩)
        simpa only [E, Equiv.symm_apply_apply] using hs.symm
      let σ : Fin m → SignType := fun j => sign (MvPolynomial.eval₂ f x (Q j))
      have hx : ∃ t : K, ∀ j, sign (((U j).map F).eval t) = σ j := by
        refine ⟨x 0, fun j => ?_⟩
        change sign (((MvPolynomial.finSuccEquiv A n (Q j)).map
          (MvPolynomial.eval₂Hom f xs)).eval (x 0)) = _
        rw [eval₂_finSuccEquiv]
        have hcons : Fin.cons (x 0) xs = x := by
          funext i
          exact Fin.cases rfl (fun j => rfl) i
        rw [hcons]
      obtain ⟨t, ht⟩ :=
        (exists_signs_map_iff_of_wholeLineProjection_sign_agree U F G hS σ).mp hx
      refine ⟨Fin.cons t ys, fun j => ?_⟩
      have h := ht j
      change sign (((MvPolynomial.finSuccEquiv A n (Q j)).map
        (MvPolynomial.eval₂Hom g ys)).eval t) = σ j at h
      rw [eval₂_finSuccEquiv] at h
      exact h

/-- Existential finite sign systems transfer in both directions. -/
theorem exists_signs_eval₂_iff (f : A →+* K) (g : A →+* L)
    (hfg : ∀ a : A, sign (f a) = sign (g a))
    (n m : ℕ) (Q : Fin m → MvPolynomial (Fin n) A) (σ : Fin m → SignType) :
    (∃ x : Fin n → K, ∀ j, sign (MvPolynomial.eval₂ f x (Q j)) = σ j) ↔
      (∃ y : Fin n → L, ∀ j, sign (MvPolynomial.eval₂ g y (Q j)) = σ j) := by
  constructor
  · rintro ⟨x, hx⟩
    obtain ⟨y, hy⟩ := exists_matching_signs_eval₂ f g hfg n m Q x
    exact ⟨y, fun j => (hy j).trans (hx j)⟩
  · rintro ⟨y, hy⟩
    obtain ⟨x, hx⟩ := exists_matching_signs_eval₂ g f (fun a => (hfg a).symm) n m Q y
    exact ⟨x, fun j => (hx j).trans (hy j)⟩

/-- Descent along a sign-preserving coefficient embedding into a real closed field. -/
theorem exists_negative_eval_of_exists_negative_eval₂
    {R : Type*} [Field R] [LinearOrder R] [IsStrictOrderedRing R] [IsRealClosed R]
    (ι : R →+* K) (hι : StrictMono ι) {n : ℕ} (p : MvPolynomial (Fin n) R)
    (h : ∃ x : Fin n → K, MvPolynomial.eval₂ ι x p < 0) :
    ∃ y : Fin n → R, MvPolynomial.eval y p < 0 := by
  obtain ⟨x, hx⟩ := h
  obtain ⟨y, hy⟩ := exists_matching_signs_eval₂ ι (RingHom.id R)
    (fun a => hι.sign_comp a) n 1 (fun _ => p) x
  refine ⟨y, ?_⟩
  apply sign_eq_neg_one_iff.mp
  have hh := (hy 0).trans (sign_neg hx)
  simpa only [MvPolynomial.eval₂_id] using hh

end Hilbert17Transfer
