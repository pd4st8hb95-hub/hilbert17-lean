import Mathlib.FieldTheory.IsRealClosed.Basic
import Mathlib.Algebra.Order.Hom.Ring
import Mathlib.RingTheory.SimpleRing.Basic

/-!
Source-only draft against mathlib 520045ab14e26149ee970e2e617ca04b09bde5d6.
Not yet elaborated or kernel-checked. No transfer axiom is introduced here.

A field ordering on a rational-function field over a real-closed base automatically
restricts to the base's original order. This removes a frequently omitted hypothesis
from the Hilbert 17 transfer setup, but does not prove multivariate sign transfer.
-/

namespace Hilbert17Transfer

variable {R K : Type*} [Field R] [LinearOrder R] [IsStrictOrderedRing R]
  [IsRealClosed R] [Field K] [LinearOrder K] [IsStrictOrderedRing K]

theorem ringHom_nonneg (f : R →+* K) {a : R} (ha : 0 ≤ a) : 0 ≤ f a := by
  have hs : IsSquare a := IsSquare.of_nonneg ha
  exact (hs.map f).nonneg

theorem ringHom_monotone (f : R →+* K) : Monotone f := by
  intro a b hab
  have h : 0 ≤ f (b - a) := ringHom_nonneg f (sub_nonneg.mpr hab)
  simpa only [map_sub, sub_nonneg] using h

theorem ringHom_strictMono (f : R →+* K) : StrictMono f :=
  (ringHom_monotone f).strictMono_of_injective f.injective

theorem ringHom_nonneg_iff (f : R →+* K) (a : R) : 0 ≤ f a ↔ 0 ≤ a := by
  simpa only [map_zero] using (ringHom_strictMono f).le_iff_le (a := 0) (b := a)

end Hilbert17Transfer
