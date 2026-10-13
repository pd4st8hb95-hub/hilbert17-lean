/- Source-only adaptation of TauCeti commit
6b896c7c411221eb78639e4be8ead6e479a62893,
TauCeti/FieldTheory/IsRealClosed/Real.lean.
Adapted imports for mathlib 520045ab14e26149ee970e2e617ca04b09bde5d6.
Not yet elaborated or kernel-checked. Original attribution and license retained below. -/

/-
Copyright (c) 2026 Lean FRO, LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison
-/

import Mathlib.Analysis.Polynomial.Order
import Mathlib.Analysis.Real.Sqrt
import Mathlib.FieldTheory.IsRealClosed.Basic
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum

/-! # The real numbers form a real closed field

This file proves `IsRealClosed ℝ`. Introduce the final theorem as a local instance
when applying abstract real-closed-field results. Nonnegative reals are squares,
and every odd-degree real polynomial has a real root.
-/


namespace Hilbert17Transfer

/-- Odd-degree real polynomials have real roots. -/
theorem real_exists_isRoot_of_odd_natDegree {p : Polynomial ℝ}
    (hp : Odd p.natDegree) : ∃ x, p.IsRoot x := by
  by_contra h
  have hleft : ∀ y, p.IsRoot y → y < 0 := fun y hy => (h ⟨y, hy⟩).elim
  have hright : ∀ y, p.IsRoot y → 0 < y := fun y hy => (h ⟨y, hy⟩).elim
  have hsign : Int.negOnePow (p.natDegree : ℤ) = -1 :=
    Int.negOnePow_odd _ ((Int.odd_coe_nat _).mpr hp)
  rcases le_total 0 p.leadingCoeff with hlc | hlc
  · have hpos := Polynomial.zero_lt_eval_of_roots_lt_of_leadingCoeff_nonneg hleft hlc
    have hneg := Polynomial.zero_lt_negOnePow_mul_eval_of_lt_roots_of_leadingCoeff_nonneg
      hright hlc
    rw [hsign] at hneg
    norm_num at hneg
    linarith
  · have hneg := Polynomial.eval_lt_zero_of_roots_lt_of_leadingCoeff_nonpos hleft hlc
    have hpos := Polynomial.negOnePow_mul_eval_lt_zero_of_lt_roots_of_leadingCoeff_nonpos
      hright hlc
    rw [hsign] at hpos
    norm_num at hpos
    linarith

/-- The real numbers form a real closed field. -/
theorem real_isRealClosed : IsRealClosed ℝ :=
  IsRealClosed.of_linearOrderedField (fun hx => Real.isSquare_iff.mpr hx)
    real_exists_isRoot_of_odd_natDegree

end Hilbert17Transfer

