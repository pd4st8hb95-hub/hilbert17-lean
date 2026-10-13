/-
Copyright (c) 2026 Lean FRO, LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison
-/

import Mathlib.Data.Sign.Defs
import Mathlib.Algebra.Field.Rat
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum

/- Local adaptation, 2026-10-13: legacy import mode and known pinned
import/conditional-rewrite renames. Definitions and mathematical arguments
are retained from TauCeti 6b896c7c411221eb78639e4be8ead6e479a62893.
The finite indicator proof supplies the six concrete Fin 3 inequalities
before rational normalization, avoiding reduction through conditional deciders.
Source-only until compilation and kernel replay are recorded. -/

/-! # Lagrange indicators for signs

`SignType.lagrangeCoeff` gives the coefficients of the three indicator polynomials
`1 - x²`, `(x² - x) / 2`, and `(x² + x) / 2` on `{-1,0,1}`.
`SignType.sum_lagrangeCoeff_mul_pow` evaluates these indicators on signs,
supplying the one-coordinate inverse in finite sign determination.

## References

S. Basu, R. Pollack, and M.-F. Roy,
[Algorithms in Real Algebraic Geometry](https://doi.org/10.1007/3-540-33099-2),
second edition, Chapter 10, for the ternary sign-moment inverse.
-/


namespace SignType

/-- Coefficients of the three Lagrange indicator polynomials on `{-1,0,1}`. -/
def lagrangeCoeff (s : SignType) (e : Fin 3) : ℚ :=
  match s with
  | .zero => if e = 0 then 1 else if e = 2 then -1 else 0
  | .neg => if e = 1 then -1/2 else if e = 2 then 1/2 else 0
  | .pos => if e = 1 then 1/2 else if e = 2 then 1/2 else 0

@[grind =]
theorem lagrangeCoeff_zero (e : Fin 3) :
    lagrangeCoeff 0 e = if e = 0 then 1 else if e = 2 then -1 else 0 := (rfl)

@[grind =]
theorem lagrangeCoeff_neg_one (e : Fin 3) :
    lagrangeCoeff (-1) e = if e = 1 then -1/2 else if e = 2 then 1/2 else 0 := (rfl)

@[grind =]
theorem lagrangeCoeff_one (e : Fin 3) :
    lagrangeCoeff 1 e = if e = 1 then 1/2 else if e = 2 then 1/2 else 0 := (rfl)

/-- Each Lagrange indicator evaluates to one at its own sign and zero at the other signs. -/
@[simp]
theorem sum_lagrangeCoeff_mul_pow (s t : SignType) :
    ∑ e : Fin 3, lagrangeCoeff s e * (t : ℚ) ^ e.val = if s = t then 1 else 0 := by
  have h01 : (0 : Fin 3) ≠ 1 := by decide
  have h02 : (0 : Fin 3) ≠ 2 := by decide
  have h12 : (1 : Fin 3) ≠ 2 := by decide
  have h10 : (1 : Fin 3) ≠ 0 := h01.symm
  have h20 : (2 : Fin 3) ≠ 0 := h02.symm
  have h21 : (2 : Fin 3) ≠ 1 := h12.symm
  have hzero_neg : (0 : SignType) ≠ -1 := by decide
  cases s <;> cases t <;>
    norm_num [Fin.sum_univ_three, lagrangeCoeff, h01, h02, h12, h10, h20, h21,
      hzero_neg, hzero_neg.symm]

end SignType
