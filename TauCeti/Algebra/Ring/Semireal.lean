/-
Copyright (c) 2026 Lean FRO, LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison
-/

import Mathlib.Algebra.Ring.Semireal.Defs

/- Local adaptation, 2026-10-13: legacy import mode and known pinned
import/conditional-rewrite renames. Definitions and mathematical arguments
are retained from TauCeti 6b896c7c411221eb78639e4be8ead6e479a62893.
Source-only until compilation and kernel replay are recorded. -/

/-! # Square obstructions in semireal rings

Semireality excludes `-1` from the squares. The `Fact` instance supplies this obstruction
when constructing a field by adjoining a square root of `-1`.
-/


namespace TauCeti

/-- In a semireal additive group with multiplication and a distinguished `1`, `-1` is not a square.
This supplies the square obstruction used by quadratic-algebra field instances. -/
instance {R : Type*} [AddGroup R] [One R] [Mul R] [IsSemireal R] :
    Fact (¬ IsSquare (-1 : R)) :=
  ⟨fun h => IsSemireal.not_isSumSq_neg_one R h.isSumSq⟩

end TauCeti
