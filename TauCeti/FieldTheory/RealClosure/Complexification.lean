/-
Copyright (c) 2026 Lean FRO, LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison
-/

import Mathlib.FieldTheory.IsRealClosed.Basic
import TauCeti.Algebra.QuadraticAlgebra.Square
import TauCeti.Algebra.Ring.Semireal
import TauCeti.Algebra.Order.Ring.Ordering.Semireal
import TauCeti.FieldTheory.RealClosure.OrderExtension

/-!
Minimal generic backport from TauCeti 6b896c7c411221eb78639e4be8ead6e479a62893.
Only QuadraticAlgebra.isSquare is used by the algebraic-closedness/IVT/Rolle
dependency chain. Its proof uses the upstream algebraic square-existence lemma
directly instead of constructing a chosen sqrt. The concrete real/complex
comparison results, chosen sqrt API, and their analytic imports are omitted.
The already verified OrderExtension import supplies the older quadratic-field
instance compatibility condition; no new field or square-root axiom is added.
Source-only until compilation and kernel replay are recorded.
-/

namespace QuadraticAlgebra

variable {R : Type*} [Field R] [IsRealClosed R]

/-- Every element of R[i] is a square over a real closed field, without an
ordering assumption in the statement. -/
theorem isSquare (z : QuadraticAlgebra R (-1) 0) : IsSquare z := by
  obtain ⟨o, ho⟩ := IsSemireal.exists_linearOrder (K := R)
  letI : LinearOrder R := o
  letI : IsStrictOrderedRing R := ho
  exact isSquare_of_forall_nonneg_isSquare z (fun ha => IsSquare.of_nonneg ha)

end QuadraticAlgebra
