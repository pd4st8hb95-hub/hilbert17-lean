/-
Copyright (c) 2026 Lean FRO, LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison

Minimal compatibility adapters for the TauCeti real-closure backport.
The underlying ordering construction is the separately checked
Hilbert17.RingPreordering development, rather than a duplicated proof.
-/

import OrderingSeparation
import Mathlib.RingTheory.SimpleRing.Basic


namespace RingPreordering

variable {K : Type*} [Field K]

/-- Compatibility name for the linear order induced by an ordering. -/
@[instance_reducible] noncomputable def linearOrder (P : RingPreordering K)
    [P.IsOrdering] : LinearOrder K :=
  Hilbert17.RingPreordering.toLinearOrder P

theorem isStrictOrderedRing (P : RingPreordering K) [P.IsOrdering] :
    letI := linearOrder P
    IsStrictOrderedRing K :=
  Hilbert17.RingPreordering.toLinearOrder_isStrictOrderedRing P

theorem nonneg_iff (P : RingPreordering K) [P.IsOrdering] (x : K) :
    letI := linearOrder P
    0 ≤ x ↔ x ∈ P :=
  Hilbert17.RingPreordering.toLinearOrder_nonneg_iff P x

/-- Extend a preordering while retaining all of its prescribed signs. -/
theorem exists_linearOrder (P : RingPreordering K) :
    ∃ o : LinearOrder K, letI := o
      IsStrictOrderedRing K ∧ ∀ x ∈ P, 0 ≤ x := by
  obtain ⟨Q, hPQ, hQ⟩ := Hilbert17.RingPreordering.exists_ordering_extension P
  letI := hQ
  exact ⟨linearOrder Q, isStrictOrderedRing Q,
    fun x hx => (nonneg_iff Q x).mpr (hPQ hx)⟩

end RingPreordering
