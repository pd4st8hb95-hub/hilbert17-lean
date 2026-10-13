/-
Copyright (c) 2026 Lean FRO, LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison
-/

import TauCeti.FieldTheory.RealClosure.FiniteExtension
import Mathlib.FieldTheory.Galois.Basic
import Mathlib.GroupTheory.Sylow

/- Local adaptation, 2026-10-13: legacy import mode and known pinned
import/conditional-rewrite renames. Definitions and mathematical arguments
are retained from TauCeti 6b896c7c411221eb78639e4be8ead6e479a62893.
Source-only until compilation and kernel replay are recorded. -/

/-! # The Galois-theoretic reduction for real closed fields

A finite Galois extension of a real closed field has a 2-group of automorphisms.
Over a square-closed intermediate extension it is trivial. These degree reductions
are used to prove algebraic closedness in `AlgebraicClosed.lean`.

## References

The Sylow 2-subgroup and index-two subgroup steps of the Artin–Schreier argument; see
Salma Kuhlmann,
[Real Algebraic Geometry, Lecture 5](https://www.math.uni-konstanz.de/algebra/WS0910/Notes05.pdf),
Theorem 2.2.
-/


namespace TauCeti.RealClosure

open Module IntermediateField

/-- The finite fixed-field degree/index identity, avoiding an import of the
infinite-Galois/Krull-topology version in the target mathlib pin. -/
private theorem finrank_fixedField_eq_index
    {K L : Type*} [Field K] [Field L] [Algebra K L]
    [FiniteDimensional K L] [IsGalois K L]
    (H : Subgroup (L ≃ₐ[K] L)) : finrank K (fixedField H) = H.index := by
  apply Nat.eq_of_mul_eq_mul_right (Nat.card_pos (α := H))
  calc
    finrank K (fixedField H) * Nat.card H =
        finrank K (fixedField H) * finrank (fixedField H) L := by
      rw [IntermediateField.finrank_fixedField_eq_card]
    _ = finrank K L := finrank_mul_finrank K (fixedField H) L
    _ = Nat.card (L ≃ₐ[K] L) := (IsGalois.card_aut_eq_finrank K L).symm
    _ = H.index * Nat.card H := H.index_mul_card.symm

/-- A nontrivial finite 2-group has a subgroup of index two. Normality is not
needed for the subsequent fixed-field degree calculation. -/
private theorem exists_subgroup_index_two
    {G : Type*} [Group G] [Finite G] (hG : IsPGroup 2 G)
    (hdvd : 2 ∣ Nat.card G) : ∃ H : Subgroup G, H.index = 2 := by
  letI : Fact (Nat.Prime 2) := ⟨Nat.prime_two⟩
  obtain ⟨n, hn⟩ := hG.exists_card_eq
  cases n with
  | zero => simp [hn] at hdvd
  | succ n =>
    have hd : 2 ^ n ∣ Nat.card G := by
      rw [hn, pow_succ]
      exact dvd_mul_right _ _
    obtain ⟨H, hH⟩ := Sylow.exists_subgroup_card_pow_prime 2 hd
    refine ⟨H, ?_⟩
    apply Nat.eq_of_mul_eq_mul_right (pow_pos (by decide : 0 < 2) n)
    calc
      H.index * 2 ^ n = H.index * Nat.card H := by rw [hH]
      _ = Nat.card G := H.index_mul_card
      _ = 2 * 2 ^ n := by rw [hn, pow_succ']

variable {R E : Type*} [Field R] [IsRealClosed R] [Field E] [Algebra R E]
    [FiniteDimensional R E] [IsGalois R E]

/-- A finite Galois extension of a real closed field has a 2-group as Galois group. -/
theorem isPGroup_two_algEquiv : IsPGroup 2 (E ≃ₐ[R] E) := by
  let P : Sylow 2 (E ≃ₐ[R] E) := Classical.choice inferInstance
  have hindex : finrank R (fixedField (P : Subgroup (E ≃ₐ[R] E))) = P.index := by
    exact finrank_fixedField_eq_index _
  have hodd : Odd (finrank R (fixedField (P : Subgroup (E ≃ₐ[R] E)))) := by
    rw [hindex]
    exact Nat.odd_iff.mpr (by have := P.not_dvd_index; omega)
  have htop : (P : Subgroup (E ≃ₐ[R] E)) = ⊤ := by
    apply Subgroup.index_eq_one.mp
    rw [← hindex]
    exact finrank_eq_one_of_odd hodd
  have hP := P.isPGroup'
  rw [htop] at hP
  exact hP.of_equiv Subgroup.topEquiv

/-- A square-closed field of characteristic different from two has no nontrivial finite
Galois extension whose Galois group is a 2-group. -/
theorem finrank_eq_one_of_isPGroup {K L : Type*} [Field K] [NeZero (2 : K)]
    [Field L] [Algebra K L] [FiniteDimensional K L] [IsGalois K L]
    (hsq : ∀ x : K, IsSquare x) (hG : IsPGroup 2 (L ≃ₐ[K] L)) :
    finrank K L = 1 := by
  rcases hG.card_eq_or_dvd with hcard | hdvd
  · rwa [IsGalois.card_aut_eq_finrank] at hcard
  · obtain ⟨H, hH⟩ := exists_subgroup_index_two hG hdvd
    have hdim : finrank K (fixedField H) = 2 := by
      exact (finrank_fixedField_eq_index H).trans hH
    exact (finrank_ne_two_of_forall_isSquare hsq hdim).elim

/-- Over a square-closed intermediate extension of a real closed field, every
finite Galois extension of the base becomes trivial. -/
theorem finrank_eq_one_of_isGalois_of_forall_isSquare {C : Type*} [Field C] [Algebra R C]
    [Algebra C E] [IsScalarTower R C E] (hsq : ∀ x : C, IsSquare x) :
    finrank C E = 1 := by
  have : CharZero C := charZero_of_injective_algebraMap (algebraMap R C).injective
  have : FiniteDimensional C E := FiniteDimensional.right R C E
  have : IsGalois C E := IsGalois.tower_top_of_isGalois R C E
  exact finrank_eq_one_of_isPGroup hsq
    ((isPGroup_two_algEquiv (R := R) (E := E)).of_injective
      (AlgEquiv.restrictScalarsHom R) (AlgEquiv.restrictScalarsHom_injective R))

end TauCeti.RealClosure
