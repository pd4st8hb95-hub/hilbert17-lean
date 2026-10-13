/-
Copyright (c) 2026 Xavier Roblot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Xavier Roblot

Compatibility replacement for the quadratic discriminant consequence needed by
TauCeti.FieldTheory.RealClosure.FiniteExtension. The direct proof below uses the
target mathlib pin's quadratic formula and monic-polynomial API, avoiding the
newer quadratic-algebra classification dependency. No source at a Mathlib module
path is replaced.
-/

import Mathlib.Algebra.QuadraticDiscriminant
import Mathlib.Algebra.Polynomial.Monic
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Ring

namespace TauCeti.Compat

open Polynomial

/-- Over a square-closed field of characteristic different from two, every
monic quadratic polynomial is reducible. -/
theorem not_irreducible_monic_quadratic_of_forall_isSquare
    {K : Type*} [Field K] [NeZero (2 : K)]
    (hsq : ∀ x : K, IsSquare x) {p : K[X]} (hm : p.Monic)
    (hdeg : p.natDegree = 2) : ¬ Irreducible p := by
  obtain ⟨r, hr⟩ := exists_quadratic_eq_zero
    (a := (1 : K)) (b := p.coeff 1) (c := p.coeff 0) one_ne_zero (hsq _)
  apply (hm.not_irreducible_iff_exists_add_mul_eq_coeff hdeg).mpr
  refine ⟨-r, p.coeff 1 + r, ?_, by ring⟩
  linear_combination hr

end TauCeti.Compat
