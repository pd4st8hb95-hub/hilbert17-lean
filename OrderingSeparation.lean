import Mathlib.Algebra.Order.Ring.Ordering.Basic
import Mathlib.Algebra.Order.Ring.Cone
import Mathlib.Algebra.Ring.Semireal.Defs
import Mathlib.Order.Zorn

/-!
# Orderings and separation for sums of squares in a field

Development target: mathlib commit 520045ab14e26149ee970e2e617ca04b09bde5d6.
This is a source draft until the parent schedules an explicit Lean verification run.
No theorem here is intended to assert Hilbert's seventeenth problem itself.
-/

namespace Hilbert17
namespace RingPreordering

variable {F : Type*} [Field F]

/-- Adjoin a nonnegative generator to a field preordering, provided its negative
is not already nonnegative. -/
def adjoin (P : _root_.RingPreordering F) (a : F) (ha : -a ∉ P) :
    _root_.RingPreordering F where
  carrier := {x | ∃ p ∈ P, ∃ q ∈ P, x = p + a * q}
  zero_mem' := ⟨0, zero_mem P, 0, zero_mem P, by simp⟩
  one_mem' := ⟨1, one_mem P, 0, zero_mem P, by simp⟩
  add_mem' := by
    rintro x y ⟨p, hp, q, hq, rfl⟩ ⟨r, hr, s, hs, rfl⟩
    exact ⟨p + r, add_mem hp hr, q + s, add_mem hq hs, by ring⟩
  mul_mem' := by
    rintro x y ⟨p, hp, q, hq, rfl⟩ ⟨r, hr, s, hs, rfl⟩
    exact ⟨p * r + a ^ 2 * (q * s),
      add_mem (mul_mem hp hr) (mul_mem (P.pow_two_mem a) (mul_mem hq hs)),
      p * s + q * r, add_mem (mul_mem hp hs) (mul_mem hq hr), by ring⟩
  mem_of_isSquare' := by
    intro x hx
    exact ⟨x, P.mem_of_isSquare hx, 0, zero_mem P, by simp⟩
  neg_one_notMem' := by
    rintro ⟨p, hp, q, hq, heq⟩
    have hq0 : q ≠ 0 := by
      intro hq0
      have hpneg : p = -1 := by simpa [hq0] using heq.symm
      exact P.neg_one_notMem (hpneg ▸ hp)
    apply ha
    have hmul : -a * q = p + 1 := by
      linear_combination heq
    have hdiv : -a = (p + 1) * q⁻¹ := by
      rw [← hmul]
      simp [mul_assoc, hq0]
    rw [hdiv]
    exact mul_mem (add_mem hp (one_mem P)) (_root_.RingPreordering.inv_mem hq)

@[simp] theorem mem_adjoin {P : _root_.RingPreordering F} {a x : F} {ha : -a ∉ P} :
    x ∈ adjoin P a ha ↔ ∃ p ∈ P, ∃ q ∈ P, x = p + a * q := Iff.rfl

theorem le_adjoin (P : _root_.RingPreordering F) (a : F) (ha : -a ∉ P) :
    P ≤ adjoin P a ha := by
  intro x hx
  exact ⟨x, hx, 0, zero_mem P, by simp⟩

theorem self_mem_adjoin (P : _root_.RingPreordering F) (a : F) (ha : -a ∉ P) :
    a ∈ adjoin P a ha :=
  ⟨0, zero_mem P, 1, one_mem P, by simp⟩

/-- A nonempty increasing chain of proper preorderings has a proper union. -/
def chainUnion (c : Set (_root_.RingPreordering F)) (hc : IsChain (· ≤ ·) c)
    (hne : c.Nonempty) : _root_.RingPreordering F where
  carrier := {x | ∃ P ∈ c, x ∈ P}
  zero_mem' := by
    obtain ⟨P, hP⟩ := hne
    exact ⟨P, hP, zero_mem P⟩
  one_mem' := by
    obtain ⟨P, hP⟩ := hne
    exact ⟨P, hP, one_mem P⟩
  add_mem' := by
    rintro x y ⟨P, hP, hx⟩ ⟨Q, hQ, hy⟩
    rcases hc.total hP hQ with hPQ | hQP
    · exact ⟨Q, hQ, add_mem (hPQ hx) hy⟩
    · exact ⟨P, hP, add_mem hx (hQP hy)⟩
  mul_mem' := by
    rintro x y ⟨P, hP, hx⟩ ⟨Q, hQ, hy⟩
    rcases hc.total hP hQ with hPQ | hQP
    · exact ⟨Q, hQ, mul_mem (hPQ hx) hy⟩
    · exact ⟨P, hP, mul_mem hx (hQP hy)⟩
  mem_of_isSquare' := by
    intro x hx
    obtain ⟨P, hP⟩ := hne
    exact ⟨P, hP, P.mem_of_isSquare hx⟩
  neg_one_notMem' := by
    rintro ⟨P, _, hP⟩
    exact P.neg_one_notMem hP

theorem le_chainUnion {c : Set (_root_.RingPreordering F)}
    {hc : IsChain (· ≤ ·) c} {hne : c.Nonempty}
    {P : _root_.RingPreordering F} (hP : P ∈ c) : P ≤ chainUnion c hc hne :=
  fun _ hx => ⟨P, hP, hx⟩

/-- Every field preordering is contained in a maximal field preordering. -/
theorem exists_maximal (P : _root_.RingPreordering F) :
    ∃ Q : _root_.RingPreordering F, P ≤ Q ∧ IsMax Q := by
  apply zorn_le_nonempty_Ici₀ P ?_ P le_rfl
  intro c _ hc Q hQ
  exact ⟨chainUnion c hc ⟨Q, hQ⟩, fun _ hR => le_chainUnion hR⟩

/-- A maximal preordering on a field decides the sign of every element. -/
theorem isOrdering_of_isMax {P : _root_.RingPreordering F} (hP : IsMax P) :
    P.IsOrdering := by
  haveI : HasMemOrNegMem P := ⟨by
    intro a
    by_cases ha : a ∈ P
    · exact Or.inl ha
    · have hna : -(-a) ∉ P := by simpa using ha
      exact Or.inr ((hP (le_adjoin P (-a) hna)) (self_mem_adjoin P (-a) hna))⟩
  exact {}

/-- Every field preordering extends to an ordering. -/
theorem exists_ordering_extension (P : _root_.RingPreordering F) :
    ∃ Q : _root_.RingPreordering F, P ≤ Q ∧ Q.IsOrdering := by
  obtain ⟨Q, hPQ, hQ⟩ := exists_maximal P
  exact ⟨Q, hPQ, isOrdering_of_isMax hQ⟩

/-- A field preordering can be separated from every element outside it by an ordering. -/
theorem exists_ordering_not_mem {P : _root_.RingPreordering F} {a : F} (ha : a ∉ P) :
    ∃ Q : _root_.RingPreordering F, P ≤ Q ∧ Q.IsOrdering ∧ a ∉ Q := by
  have hna : -(-a) ∉ P := by simpa using ha
  obtain ⟨Q, hPQ, hQ⟩ := exists_ordering_extension (adjoin P (-a) hna)
  refine ⟨Q, (le_adjoin P (-a) hna).trans hPQ, hQ, ?_⟩
  intro haQ
  have hneg : -a ∈ Q := hPQ (self_mem_adjoin P (-a) hna)
  have ha0 : a = 0 := Q.eq_zero_of_mem_of_neg_mem haQ hneg
  exact ha (by simpa [ha0] using zero_mem P)

/-- A field preordering is the intersection of all orderings containing it. -/
theorem mem_iff_mem_all_ordering_extensions (P : _root_.RingPreordering F) (a : F) :
    a ∈ P ↔ ∀ Q : _root_.RingPreordering F, P ≤ Q → Q.IsOrdering → a ∈ Q := by
  refine ⟨fun ha Q hPQ _ => hPQ ha, ?_⟩
  intro h
  by_contra ha
  obtain ⟨Q, hPQ, hQ, haQ⟩ := exists_ordering_not_mem ha
  exact haQ (h Q hPQ hQ)

/-- The sums of squares form a preordering in a semireal field. -/
def sumSq [IsSemireal F] : _root_.RingPreordering F where
  __ := Subsemiring.sumSq F
  mem_of_isSquare' hx := Subsemiring.mem_sumSq.mpr hx.isSumSq
  neg_one_notMem' h := IsSemireal.not_isSumSq_neg_one F (Subsemiring.mem_sumSq.mp h)

@[simp] theorem mem_sumSq [IsSemireal F] {a : F} : a ∈ sumSq (F := F) ↔ IsSumSq a :=
  Subsemiring.mem_sumSq

/-- Artin–Schreier separation in cone form. -/
theorem isSumSq_iff_mem_all_orderings [IsSemireal F] (a : F) :
    IsSumSq a ↔ ∀ Q : _root_.RingPreordering F, Q.IsOrdering → a ∈ Q := by
  refine ⟨fun ha _ _ => _root_.RingPreordering.mem_of_isSumSq ha, ?_⟩
  intro h
  apply mem_sumSq.mp
  apply (mem_iff_mem_all_ordering_extensions (sumSq (F := F)) a).mpr
  intro Q _ hQ
  exact h Q hQ

/-- Regard a field preordering as a positive cone with trivial support. -/
def toRingCone (P : _root_.RingPreordering F) : RingCone F where
  __ := P.toSubsemiring
  eq_zero_of_mem_of_neg_mem' := P.eq_zero_of_mem_of_neg_mem

instance (P : _root_.RingPreordering F) [P.IsOrdering] :
    HasMemOrNegMem (toRingCone P) := ⟨fun a => mem_or_neg_mem P a⟩

/-- The linear order induced by a field ordering. -/
noncomputable def toLinearOrder (P : _root_.RingPreordering F) [P.IsOrdering] :
    LinearOrder F := by
  classical
  exact LinearOrder.mkOfAddGroupCone (toRingCone P)

theorem toLinearOrder_isStrictOrderedRing (P : _root_.RingPreordering F) [P.IsOrdering] :
    letI : LinearOrder F := toLinearOrder P
    IsStrictOrderedRing F := by
  letI : LinearOrder F := toLinearOrder P
  haveI : IsOrderedRing F := IsOrderedRing.mkOfCone (toRingCone P)
  infer_instance

@[simp] theorem toLinearOrder_nonneg_iff (P : _root_.RingPreordering F) [P.IsOrdering]
    (a : F) : @LE.le F (toLinearOrder P).toLE 0 a ↔ a ∈ P := by
  change a - 0 ∈ P ↔ a ∈ P
  simp

/-- Artin–Schreier separation using ordinary Lean linear orders. -/
theorem isSumSq_iff_nonneg_all_orders [IsSemireal F] (a : F) :
    IsSumSq a ↔ ∀ (o : LinearOrder F), @IsStrictOrderedRing F _ o.toPartialOrder →
      @LE.le F o.toLE 0 a := by
  refine ⟨?_, ?_⟩
  · intro ha o ho
    letI : LinearOrder F := o
    letI : IsStrictOrderedRing F := ho
    exact ha.nonneg
  · intro ha
    apply (isSumSq_iff_mem_all_orderings a).mpr
    intro P hP
    letI := hP
    exact (toLinearOrder_nonneg_iff P a).mp
      (ha (toLinearOrder P) (toLinearOrder_isStrictOrderedRing P))

end RingPreordering
end Hilbert17
