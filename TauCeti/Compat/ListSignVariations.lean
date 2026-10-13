/-
Copyright (c) 2026 Tomaz Mascarenhas. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Tomaz Mascarenhas
-/
/- Source-only compatibility adaptation of official mathlib commit
3b531c35df33d6bbe64b4e87dec056211d3a5676, Mathlib/Data/List/SignVariations.lean,
for mathlib 520045ab14e26149ee970e2e617ca04b09bde5d6 and Lean v4.32.1.
Original Git blob: 44b9e5aeb6d2c915333879fd76f9eb7a8e8f495d.
Original copyright and Apache 2.0 attribution are preserved above.
Changes: relocate module to TauCeti.Compat.ListSignVariations, remove
module/public/expose wrappers, and use Mathlib.Data.Sign.Basic.
All declaration namespaces and statements are unchanged. The two recursion
branches use the pinned names if_pos/if_neg instead of ite_eq_left/ite_eq_right.
This revision has not yet been compiled or kernel-checked. -/

import Mathlib.Data.List.Destutter
import Mathlib.Data.Sign.Basic

/-!
# Sign variations of a list

This file defines `List.signVariations`, for counting the number of changes of sign in a list
after all zeroes were removed. For example, `[1, 0, -2, 3, 3]` has two sign variations, and so
does `[1, -2, 3]`.

This is the counting device behind Descartes' rule of signs (applied to the list of coefficients
of the polynomial) and Sturm's theorem (applied to the values of a Sturm sequence at a
point, or to the signs of its leading coefficients, adjusted by degree parity at `-∞`, for the
count at infinity).

## Main definitions

* `List.signVariations l`: the number of sign variations of `l`.

## Main results

* `List.signVariations_cons_cons_of_ne_zero`: the recursion for a list starting with two nonzero
  entries: prepending `a` to `b :: l` adds one variation exactly when `sign a ≠ sign b`.
* `List.signVariations_zero_cons`, `List.signVariations_cons_zero_cons`: zero entries are ignored.
* `List.signVariations_map`: `signVariations` only depends on the signs of the entries, so it is
  invariant under any map preserving signs (for instance the cast `ℚ → ℝ`, or `SignType.sign`
  itself).
-/

open SignType

namespace List

variable {α : Type*} [Zero α] [LinearOrder α]

/-- The number of sign variations of a list: the number of adjacent pairs of opposite sign once
all zero entries have been removed. -/
def signVariations (l : List α) : ℕ :=
  (((l.map sign).filter (· ≠ 0)).destutter (· ≠ ·)).length - 1

example : signVariations [1, 0, -2, 3, 3] = 2 := by decide

@[simp]
lemma signVariations_nil : signVariations ([] : List α) = 0 := rfl

@[simp]
lemma signVariations_singleton (a : α) : signVariations [a] = 0 := by
  rcases eq_or_ne a 0 with ha | ha <;> simp [signVariations, ha]

/-- A leading zero entry does not change the sign variations. -/
@[simp]
lemma signVariations_zero_cons (l : List α) :
    signVariations (0 :: l) = signVariations l := by
  cases l <;> simp [signVariations]

/-- Zero entries do not contribute to the sign variations. -/
@[simp]
lemma signVariations_filter_ne_zero (l : List α) :
    signVariations (l.filter (fun x => !decide (x = 0))) = signVariations l := by
  simp [signVariations, filter_map, Function.comp_def, sign_eq_zero_iff]

/-- A zero entry in second position does not change the sign variations. -/
@[simp]
lemma signVariations_cons_zero_cons (a : α) (as : List α) :
    signVariations (a :: 0 :: as) = signVariations (a :: as) := by
  simp [signVariations, filter]

/-- Prepending a nonzero entry `a` to a list starting with a nonzero entry `b` adds one sign
variation exactly when `a` and `b` have opposite signs. -/
lemma signVariations_cons_cons_of_ne_zero {a b : α} (as : List α) (ha : a ≠ 0) (hb : b ≠ 0) :
    signVariations (a :: b :: as) =
      signVariations (b :: as) + (if sign a = sign b then 0 else 1) := by
  have ha' : sign a ≠ 0 := by rwa [ne_eq, sign_eq_zero_iff]
  have hb' : sign b ≠ 0 := by rwa [ne_eq, sign_eq_zero_iff]
  have hf1 :
      ((a :: b :: as).map sign).filter (· ≠ 0) =
      sign a :: sign b :: (as.map sign).filter (· ≠ 0) := by
    simp [ha', hb']
  have hf2 : ((b :: as).map sign).filter (· ≠ 0) = sign b :: (as.map sign).filter (· ≠ 0) := by
    simp [hb']
  have hne : ((sign b :: (as.map sign).filter (· ≠ 0)).destutter (· ≠ ·)).length ≠ 0 := by
    rw [ne_eq, length_eq_zero_iff, destutter_eq_nil]
    simp
  simp only [signVariations, hf1, hf2, destutter_cons_cons, ← destutter_cons']
  by_cases h : sign a = sign b
  · rw [if_neg (not_not.mpr h), if_pos h, h, add_zero]
  · rw [if_pos h, if_neg h, length_cons]
    omega

/-- `signVariations` only depends on the signs of the entries. -/
lemma signVariations_congr {β : Type*} [Zero β] [LinearOrder β] {l₁ : List α} {l₂ : List β}
    (h : l₁.map sign = l₂.map sign) : signVariations l₁ = signVariations l₂ := by
  simp only [signVariations, h]

/-- `signVariations` is invariant under any map that preserves signs (e.g. casts). -/
lemma signVariations_map {β : Type*} [Zero β] [LinearOrder β] {f : α → β}
    (hf : ∀ x, sign (f x) = sign x) (l : List α) :
    signVariations (l.map f) = signVariations l :=
  signVariations_congr (by rw [map_map]; exact map_congr_left fun x _ => hf x)

@[simp]
lemma signVariations_map_sign (l : List α) : signVariations (l.map sign) = signVariations l :=
  signVariations_map (fun x => by cases sign x <;> decide) l

/-- A run of zero entries after the head does not change the sign variations. -/
@[simp]
lemma signVariations_cons_replicate_zero_append (a : α) (n : ℕ) (l : List α) :
    signVariations (a :: (replicate n 0 ++ l)) = signVariations (a :: l) := by
  have h : ((replicate n (0 : α) ++ l).map sign).filter (· ≠ 0) = (l.map sign).filter (· ≠ 0) := by
    simp [filter_append]
  simp only [signVariations, map_cons, filter_cons, h]

/-- A list whose only nonzero entry is the head has no sign variations. -/
@[simp]
lemma signVariations_cons_replicate_zero (a : α) (n : ℕ) :
    signVariations (a :: replicate n 0) = 0 := by
  simpa using signVariations_cons_replicate_zero_append a n []

/-- `signVariations` is invariant under any map that negates signs (e.g. negation). -/
lemma signVariations_map_of_sign_eq_neg {β : Type*} [Zero β] [LinearOrder β] {f : α → β}
    (hf : ∀ x, sign (f x) = -sign x) (l : List α) :
    signVariations (l.map f) = signVariations l := by
  have h1 : (l.map f).map sign = (l.map sign).map (- ·) := by
    rw [map_map, map_map]
    exact map_congr_left fun x _ => hf x
  have h2 : ((l.map sign).map (- ·)).filter (· ≠ 0) = ((l.map sign).filter (· ≠ 0)).map (- ·) := by
    rw [filter_map]
    congr 2
    funext s
    simp
  simp only [signVariations, h1, h2, ← map_destutter_ne _ neg_injective, length_map]

end List
