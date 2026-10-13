import FiniteVariableTransfer
import TauCeti.FieldTheory.RealClosure.Basic
import ConditionalArtin

/-!
Source-only assembly; not yet elaborated or kernel-checked.

This closes the explicit NegativePointTransfer input using the proved ordered
real-closure construction and finite-variable sign transfer. It does not declare
that input as an axiom or add it as a hypothesis to the final target. The full
import dependency closure still requires compatibility work and kernel checking.
-/

namespace Hilbert17Transfer

universe u

theorem negativePointTransfer_of_isRealClosed
    (R : Type u) [Field R] [LinearOrder R] [IsStrictOrderedRing R] [IsRealClosed R] :
    Hilbert17.NegativePointTransfer R := by
  intro K _ _ _ ι n p hnegative
  obtain ⟨x, hx⟩ := hnegative
  obtain ⟨L, fieldL, orderL, orderedL, realClosedL, j, hj, _⟩ :=
    TauCeti.RealClosure.exists_realClosure K
  letI : Field L := fieldL
  letI : LinearOrder L := orderL
  letI : IsStrictOrderedRing L := orderedL
  letI : IsRealClosed L := realClosedL
  have hnegativeL :
      MvPolynomial.eval₂ (j.comp ι.toRingHom) (j ∘ x) p < 0 := by
    rw [← MvPolynomial.eval₂_comp_left, ← j.map_zero]
    exact hj hx
  exact exists_negative_eval_of_exists_negative_eval₂
    (j.comp ι.toRingHom) (ringHom_strictMono _) p ⟨j ∘ x, hnegativeL⟩

/-- Candidate unconditional real target. This declaration and its full dependency
closure are source drafts until the complete compiler/axiom audit is recorded. -/
theorem hilbert17Real_candidate : Hilbert17Target.Hilbert17Real := by
  letI : IsRealClosed ℝ := real_isRealClosed
  exact Hilbert17.hilbert17Real_of_negativePointTransfer
    (negativePointTransfer_of_isRealClosed ℝ)

theorem hilbert17RealCleared_candidate : Hilbert17Target.Hilbert17RealCleared := by
  letI : IsRealClosed ℝ := real_isRealClosed
  exact Hilbert17.hilbert17RealCleared_of_negativePointTransfer
    (negativePointTransfer_of_isRealClosed ℝ)

end Hilbert17Transfer
