import OrderingSeparation
import FractionSemireal
import CoefficientOrder
import RealInstance
import TargetSpec

/-!
# Conditional assembly of the Artin argument

Pinned target: Lean 4.32.1, mathlib
520045ab14e26149ee970e2e617ca04b09bde5d6.
This file is a source draft until its explicit compiler run is recorded.

The proposition `NegativePointTransfer` is an explicit, unproved input. It asks
only for descent of one strict polynomial inequality along an ordered field
embedding. It does not assume a sum-of-squares conclusion. For a real-closed
base, one mathematical way to establish this input is to construct an ordered
real-closed extension of the target field and then prove real-closed existential
transfer. Neither of those missing results is asserted or axiomatized here.

The theorems below prove a conditional reduction. They are not an unconditional
proof of Hilbert's seventeenth problem.
-/

namespace Hilbert17

universe u

/-- Descent of a negative value of one polynomial from any ordered extension.
The same coefficient homomorphism is used throughout the evaluation. -/
def NegativePointTransfer (R : Type u) [Field R] [LinearOrder R]
    [IsStrictOrderedRing R] : Prop :=
  ∀ (K : Type u) [Field K] [LinearOrder K] [IsStrictOrderedRing K]
    (ι : R →+*o K) (n : ℕ) (f : MvPolynomial (Fin n) R),
    (∃ y : Fin n → K, MvPolynomial.eval₂ ι.toRingHom y f < 0) →
      ∃ x : Fin n → R, MvPolynomial.eval x f < 0

/-- Conditional Artin reduction over a real-closed ordered field.
The unresolved negative-point descent principle is a visible hypothesis. -/
theorem rationalSOS_of_negativePointTransfer
    {R : Type u} [Field R] [LinearOrder R] [IsStrictOrderedRing R]
    [IsRealClosed R] (htransfer : NegativePointTransfer R)
    {n : ℕ} (f : MvPolynomial (Fin n) R)
    (hf : ∀ x : Fin n → R, 0 ≤ MvPolynomial.eval x f) :
    IsSumSq (algebraMap (MvPolynomial (Fin n) R)
      (FractionRing (MvPolynomial (Fin n) R)) f) := by
  let A := MvPolynomial (Fin n) R
  let K := FractionRing A
  letI : IsSemireal K := isSemireal_mvPolynomial_fraction (R := R) (σ := Fin n)
  apply (RingPreordering.isSumSq_iff_nonneg_all_orders
    (algebraMap A K f)).mpr
  intro o ho
  letI : LinearOrder K := o
  letI : IsStrictOrderedRing K := ho
  let coefficientMap : R →+* K := (algebraMap A K).comp MvPolynomial.C
  let orderedCoefficientMap : R →+*o K :=
    ⟨coefficientMap, Hilbert17Transfer.ringHom_monotone coefficientMap⟩
  have heval :
      MvPolynomial.eval₂ coefficientMap
        (fun i : Fin n => algebraMap A K (MvPolynomial.X i)) f =
        algebraMap A K f := by
    calc
      _ = algebraMap A K (MvPolynomial.eval₂ MvPolynomial.C MvPolynomial.X f) :=
        (MvPolynomial.eval₂_comp_left (algebraMap A K)
          MvPolynomial.C MvPolynomial.X f).symm
      _ = algebraMap A K f :=
        congrArg (algebraMap A K) (MvPolynomial.eval₂_eta f)
  by_contra hnonneg
  have hnegative :
      MvPolynomial.eval₂ orderedCoefficientMap.toRingHom
        (fun i : Fin n => algebraMap A K (MvPolynomial.X i)) f < 0 := by
    change MvPolynomial.eval₂ coefficientMap _ f < 0
    rw [heval]
    exact lt_of_not_ge hnonneg
  obtain ⟨x, hx⟩ := htransfer K orderedCoefficientMap n f ⟨_, hnegative⟩
  exact (hf x).not_gt hx

/-- The exact real-coefficient target, still conditional on negative-point transfer. -/
theorem hilbert17Real_of_negativePointTransfer
    (htransfer : NegativePointTransfer ℝ) : Hilbert17Target.Hilbert17Real := by
  letI : IsRealClosed ℝ := Hilbert17Transfer.real_isRealClosed
  intro n f hf
  exact rationalSOS_of_negativePointTransfer htransfer f hf

/-- The exact denominator-cleared real target under the same unresolved input. -/
theorem hilbert17RealCleared_of_negativePointTransfer
    (htransfer : NegativePointTransfer ℝ) : Hilbert17Target.Hilbert17RealCleared := by
  intro n f hf
  exact (real_mvPolynomial_fraction_iff f).mp
    (hilbert17Real_of_negativePointTransfer htransfer n f hf)

end Hilbert17
