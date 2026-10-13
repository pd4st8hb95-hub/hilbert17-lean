/-
Copyright (c) 2026 Xavier Roblot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Xavier Roblot

Minimal compatibility replacement for the field case consumed by TauCeti's
finite-extension argument. Instead of importing newer quadratic-algebra
classification, the proof uses minimal polynomials of degree at most two.
The original field and characteristic-not-two hypotheses are preserved; no
perfectness, separability, or characteristic-zero assumption is added.
-/

import TauCeti.Compat.QuadraticDiscriminant
import Mathlib.FieldTheory.Minpoly.Finite
import Mathlib.FieldTheory.Minpoly.Field
import Mathlib.LinearAlgebra.Dimension.Free
import Mathlib.RingTheory.SimpleRing.Basic

namespace TauCeti.Compat

/-- A square-closed field of characteristic different from two admits no
quadratic field extension, without a separate separability assumption. -/
theorem finrank_ne_two_of_forall_isSquare
    {K L : Type*} [Field K] [NeZero (2 : K)] [Field L] [Algebra K L]
    (hsq : ∀ x : K, IsSquare x) : Module.finrank K L ≠ 2 := by
  intro htwo
  letI : Module.Finite K L := Module.finite_of_finrank_pos (by omega)
  have honto : Function.Surjective (algebraMap K L) := by
    intro x
    have hint : IsIntegral K x := IsIntegral.of_finite K x
    have hpos := minpoly.natDegree_pos hint
    have hle : (minpoly K x).natDegree ≤ 2 := by
      simpa only [htwo] using minpoly.natDegree_le (A := K) x
    have hdegree : (minpoly K x).natDegree = 1 := by
      by_contra hne
      have hdeg2 : (minpoly K x).natDegree = 2 := by omega
      exact not_irreducible_monic_quadratic_of_forall_isSquare hsq
        (minpoly.monic hint) hdeg2 (minpoly.irreducible hint)
    exact minpoly.natDegree_eq_one_iff.mp hdegree
  have hone : Module.finrank K L = 1 :=
    Module.finrank_of_bijective_algebraMap ⟨(algebraMap K L).injective, honto⟩
  omega

end TauCeti.Compat
