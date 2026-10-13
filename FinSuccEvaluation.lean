import Mathlib.Algebra.MvPolynomial.Equiv

/-! Source-only evaluation compatibility lemma, isolated for independent checking. -/

namespace Hilbert17Transfer

variable {A : Type*} [CommRing A]

/-- Evaluation compatibility for a coefficient map, with the first variable
viewed as the univariate indeterminate. -/
theorem eval₂_finSuccEquiv {F : Type*} [CommRing F] (f : A →+* F)
    {n : ℕ} (s : Fin n → F) (t : F) (p : MvPolynomial (Fin (n + 1)) A) :
    ((MvPolynomial.finSuccEquiv A n p).map (MvPolynomial.eval₂Hom f s)).eval t =
      MvPolynomial.eval₂ f (Fin.cons t s) p := by
  have hh :
      (Polynomial.eval₂RingHom (MvPolynomial.eval₂Hom f s) t).comp
        (MvPolynomial.finSuccEquiv A n).toRingEquiv.toRingHom =
      MvPolynomial.eval₂Hom f (Fin.cons t s) := by
    apply MvPolynomial.ringHom_ext
    · intro a
      simp [MvPolynomial.finSuccEquiv_apply, Polynomial.coe_eval₂RingHom]
    · intro i
      refine Fin.cases ?_ (fun j => ?_) i
      · simp [MvPolynomial.finSuccEquiv_X_zero, Polynomial.coe_eval₂RingHom]
      · simp [MvPolynomial.finSuccEquiv_X_succ, Polynomial.coe_eval₂RingHom]
  have he := congrArg (fun h : MvPolynomial (Fin (n + 1)) A →+* F => h p) hh
  change Polynomial.eval₂ (MvPolynomial.eval₂Hom f s) t
    (MvPolynomial.finSuccEquiv A n p) = MvPolynomial.eval₂ f (Fin.cons t s) p at he
  rwa [Polynomial.eval₂_eq_eval_map] at he

end Hilbert17Transfer
