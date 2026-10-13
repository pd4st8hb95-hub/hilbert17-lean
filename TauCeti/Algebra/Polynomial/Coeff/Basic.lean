/-
Copyright (c) 2026 The Tau Ceti contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: The Tau Ceti contributors
-/

import Mathlib.Algebra.Polynomial.Degree.Operations

/- Local adaptation, 2026-10-13: legacy import mode and known pinned
import/conditional-rewrite renames. Definitions and mathematical arguments
are retained from TauCeti 6b896c7c411221eb78639e4be8ead6e479a62893.
Source-only until compilation and kernel replay are recorded. -/

/-!
# Coefficients of shifted polynomials with a degree bound

Multiplication by `X ^ l` shifts a polynomial's coefficients by `l`. When its degree is
bounded by `n`, the shifted coefficients vanish outside the window from `l` to `l + n`.
This identity identifies bounded coefficient rows with coefficients of shifted polynomials.
-/


namespace TauCeti

open Polynomial

/-- The coefficients of `X ^ l * p` vanish outside the window from `l` to `l + n`
when `p.natDegree ≤ n`. -/
theorem _root_.Polynomial.coeff_X_pow_mul_of_natDegree_le {R : Type*} [Semiring R]
    {p : R[X]} {n : ℕ} (hp : p.natDegree ≤ n) (l d : ℕ) :
    (X ^ l * p).coeff d = if l ≤ d ∧ d ≤ l + n then p.coeff (d - l) else 0 := by
  rw [coeff_X_pow_mul']
  by_cases h : l ≤ d
  · by_cases h' : d ≤ l + n
    · simp [h, h']
    · have hz : p.coeff (d - l) = 0 := coeff_eq_zero_of_natDegree_lt (by omega)
      simp [h, h', hz]
  · simp [h]

end TauCeti
