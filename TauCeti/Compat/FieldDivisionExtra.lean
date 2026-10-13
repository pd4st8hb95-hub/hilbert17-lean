/-
Copyright (c) 2018 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes, Johannes Hölzl, Kim Morrison, Jens Wagemaker
-/

import Mathlib.Algebra.Polynomial.FieldDivision
import Mathlib.Tactic.Ring

/-!
Minimal source backport from Mathlib.Algebra.Polynomial.FieldDivision at
3b531c35df33d6bbe64b4e87dec056211d3a5676, preserving the proof body.
The target pin already has mod_eq_of_dvd_sub but lacks neg_mod and mul_mod_mul_left.
This file is source-only until compilation and kernel replay are recorded.
-/

namespace Polynomial

variable {R : Type*} [Field R]

theorem neg_mod {p q : R[X]} : (-p) % q = -(p % q) := by
  rw [mod_def, mod_def, neg_modByMonic]

theorem mul_mod_mul_left {p₁ p₂ q : R[X]} : (q * p₁) % (q * p₂) = q * (p₁ % p₂) := by
  by_cases hq: q = 0
  · simp [hq]
  rcases eq_or_ne p₂ 0 with rfl | hp₂
  · simp
  · have h1 : (q * p₁) % (q * p₂) = (q * (p₁ % p₂)) % (q * p₂) :=
      mod_eq_of_dvd_sub ⟨p₁ / p₂, by rw [← mul_sub, EuclideanDomain.mod_eq_sub_mul_div]; ring⟩
    rw [h1, mod_eq_self_iff (mul_ne_zero hq hp₂), degree_mul, degree_mul]
    exact WithBot.add_lt_add_left (degree_ne_bot.mpr hq) (degree_mod_lt p₁ hp₂)

end Polynomial

