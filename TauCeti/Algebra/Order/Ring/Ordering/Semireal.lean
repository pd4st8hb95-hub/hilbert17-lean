/-
Copyright (c) 2026 Lean FRO, LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison
-/

import TauCeti.Algebra.Order.Ring.Ordering.Extension
import Mathlib.Algebra.Ring.Semireal.Defs

/- Local adaptation, 2026-10-13: legacy import mode and known pinned
import/conditional-rewrite renames. Definitions and mathematical arguments
are retained from TauCeti 6b896c7c411221eb78639e4be8ead6e479a62893.
Source-only until compilation and kernel replay are recorded. -/

/-! # Ordering formally real fields

The sums of squares in a formally real field form a preordering, which extends to an ordering.
This supplies an order when deriving polynomial intermediate value from `IsRealClosed`.

## References

Salma Kuhlmann,
[Real Algebraic Geometry, Lecture 3](https://www.math.uni-konstanz.de/algebra/WS0910/Notes03.pdf),
Corollary 3.4.
-/


namespace RingPreordering

variable {K : Type*} [CommRing K]

/-- The sums of squares form a proper preordering in a formally real commutative ring. -/
def sumSq [IsSemireal K] : RingPreordering K where
  __ := Subsemiring.sumSq K
  mem_of_isSquare' hx := by simpa using hx.isSumSq
  neg_one_notMem' := by simpa using IsSemireal.not_isSumSq_neg_one K

@[simp] theorem mem_sumSq [IsSemireal K] (x : K) :
    x ∈ sumSq (K := K) ↔ IsSumSq x := Subsemiring.mem_sumSq

end RingPreordering

/-- A formally real field admits a compatible linear order. -/
theorem IsSemireal.exists_linearOrder {K : Type*} [Field K] [IsSemireal K] :
    ∃ o : LinearOrder K, letI := o
      IsStrictOrderedRing K := by
  obtain ⟨o, ho, _⟩ := RingPreordering.exists_linearOrder (RingPreordering.sumSq (K := K))
  exact ⟨o, ho⟩
