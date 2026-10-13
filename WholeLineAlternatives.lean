import TauCeti.Geometry.RealAlgebraic.SignDetermination.WholeLine
import TauCeti.Algebra.Polynomial.Eval.Infinity

/-!
Source-only draft; not yet elaborated or kernel-checked.

Whole-line sign realization is a disjunction of two finite-root-set problems and
two explicit signs-at-infinity conditions. This formulation is uniform in the
ordered real closed field and includes zero polynomials and the empty family.
-/

namespace Hilbert17Transfer

open Polynomial Finset SignType
open TauCeti.SignDetermination

variable {K : Type*} [Field K] [LinearOrder K] [IsStrictOrderedRing K] [IsRealClosed K]

noncomputable def rootBound (p : K[X]) : K :=
  (∑ z ∈ p.roots.toFinset, |z|) + 1

theorem root_lt_rootBound (p : K[X]) {z : K} (hz : z ∈ p.roots.toFinset) :
    z < rootBound p := by
  have hs : |z| ≤ ∑ w ∈ p.roots.toFinset, |w| :=
    single_le_sum (fun w _ => abs_nonneg w) hz
  have h := le_abs_self z
  dsimp [rootBound]
  linarith

theorem neg_rootBound_lt_root (p : K[X]) {z : K} (hz : z ∈ p.roots.toFinset) :
    -rootBound p < z := by
  have hs : |z| ≤ ∑ w ∈ p.roots.toFinset, |w| :=
    single_le_sum (fun w _ => abs_nonneg w) hz
  have h := neg_abs_le z
  dsimp [rootBound]
  linarith

/-- Beyond all roots of p, each divisor q has its positive-infinity sign.
Zero q is allowed separately; the divisibility guard is required only otherwise. -/
theorem sign_eval_rootBound (p q : K[X]) (hp : p ≠ 0) (hq : q ≠ 0 → q ∣ p) :
    sign (q.eval (rootBound p)) = sign q.leadingCoeff := by
  by_cases hq0 : q = 0
  · simp [hq0]
  obtain ⟨B, hB⟩ := q.exists_sign_atTop
  let t := max (rootBound p) B + 1
  have hbt : rootBound p ≤ t :=
    (le_max_left _ _).trans (le_of_lt (lt_add_one _))
  have hBt : B < t := (le_max_right _ _).trans_lt (lt_add_one _)
  have hfree : ∀ z ∈ Set.Icc (rootBound p) t, q.eval z ≠ 0 := by
    intro z hz hz0
    have hpz : p.eval z = 0 := eval_eq_zero_of_dvd_of_eval_eq_zero (hq hq0) hz0
    have hzroot : z ∈ p.roots.toFinset := by
      simpa only [Multiset.mem_toFinset, mem_roots hp, IsRoot.def] using hpz
    exact (root_lt_rootBound p hzroot).not_ge hz.1
  exact (q.sign_eval_const hbt hfree).trans (hB t hBt)

theorem sign_eval_neg_rootBound (p q : K[X]) (hp : p ≠ 0) (hq : q ≠ 0 → q ∣ p) :
    sign (q.eval (-rootBound p)) = sign (q.leadingCoeff * (-1) ^ q.natDegree) := by
  by_cases hq0 : q = 0
  · simp [hq0]
  obtain ⟨B, hB⟩ := q.exists_sign_atBot
  let t := min (-rootBound p) B - 1
  have htb : t ≤ -rootBound p :=
    (le_of_lt (sub_one_lt _)).trans (min_le_left _ _)
  have htB : t < B := (sub_one_lt _).trans_le (min_le_right _ _)
  have hfree : ∀ z ∈ Set.Icc t (-rootBound p), q.eval z ≠ 0 := by
    intro z hz hz0
    have hpz : p.eval z = 0 := eval_eq_zero_of_dvd_of_eval_eq_zero (hq hq0) hz0
    have hzroot : z ∈ p.roots.toFinset := by
      simpa only [Multiset.mem_toFinset, mem_roots hp, IsRoot.def] using hpz
    exact (neg_rootBound_lt_root p hzroot).not_ge hz.2
  exact (q.sign_eval_const htb hfree).symm.trans (hB t htB)

variable {J : Type*} [Fintype J]

theorem exists_all_leading_signs (Q : J → K[X]) :
    ∃ x : K, ∀ j, sign ((Q j).eval x) = sign (Q j).leadingCoeff := by
  classical
  obtain ⟨B, hB⟩ := List.exists_signs_atTop (Finset.univ.toList.map Q)
  exact ⟨B + 1, fun j => hB (Q j) (by simp) (B + 1) (lt_add_one B)⟩

theorem exists_all_parity_leading_signs (Q : J → K[X]) :
    ∃ x : K, ∀ j,
      sign ((Q j).eval x) = sign ((Q j).leadingCoeff * (-1) ^ (Q j).natDegree) := by
  classical
  obtain ⟨B, hB⟩ := List.exists_signs_atBot (Finset.univ.toList.map Q)
  exact ⟨B - 1, fun j => hB (Q j) (by simp) (B - 1) (sub_one_lt B)⟩

/-- No topological completeness or Archimedean assumption enters this alternative. -/
theorem exists_signs_iff_root_derivative_infinity (Q : J → K[X]) (σ : J → SignType) :
    (∃ x : K, ∀ j, sign ((Q j).eval x) = σ j) ↔
      (∃ x ∈ (sampleProduct Q).roots.toFinset,
        ∀ j, sign ((Q j).eval x) = σ j) ∨
      (∃ x ∈ (sampleProduct Q).derivative.roots.toFinset,
        ∀ j, sign ((Q j).eval x) = σ j) ∨
      (∀ j, sign ((Q j).leadingCoeff * (-1) ^ (Q j).natDegree) = σ j) ∨
      (∀ j, sign (Q j).leadingCoeff = σ j) := by
  constructor
  · rintro ⟨x, hx⟩
    obtain ⟨y, hy, hxy⟩ := exists_mem_signSamples_sign_eq Q x
    have hyσ : ∀ j, sign ((Q j).eval y) = σ j :=
      fun j => (hxy j).trans (hx j)
    rcases (Polynomial.mem_signSamples _ _).mp hy with hy | hy | hy | hy
    · exact Or.inl ⟨y, hy, hyσ⟩
    · exact Or.inr (Or.inl ⟨y, hy, hyσ⟩)
    · refine Or.inr (Or.inr (Or.inl ?_))
      intro j
      have hs := sign_eval_neg_rootBound (sampleProduct Q) (Q j)
        (sampleProduct_ne_zero Q) (dvd_sampleProduct Q)
      rw [show y = -rootBound (sampleProduct Q) from hy] at hyσ
      exact hs.symm.trans (hyσ j)
    · refine Or.inr (Or.inr (Or.inr ?_))
      intro j
      have hs := sign_eval_rootBound (sampleProduct Q) (Q j)
        (sampleProduct_ne_zero Q) (dvd_sampleProduct Q)
      rw [show y = rootBound (sampleProduct Q) from hy] at hyσ
      exact hs.symm.trans (hyσ j)
  · rintro (⟨x, _, hx⟩ | ⟨x, _, hx⟩ | h | h)
    · exact ⟨x, hx⟩
    · exact ⟨x, hx⟩
    · obtain ⟨x, hx⟩ := exists_all_parity_leading_signs Q
      exact ⟨x, fun j => (hx j).trans (h j)⟩
    · obtain ⟨x, hx⟩ := exists_all_leading_signs Q
      exact ⟨x, fun j => (hx j).trans (h j)⟩

end Hilbert17Transfer
