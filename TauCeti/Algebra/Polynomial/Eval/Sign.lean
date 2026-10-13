/-
Copyright (c) 2026 The Tau Ceti contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: The Tau Ceti contributors
-/

import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Data.Sign.Defs

/- Local adaptation, 2026-10-13: legacy import mode and known pinned
import/conditional-rewrite renames. Definitions and mathematical arguments
are retained from TauCeti 6b896c7c411221eb78639e4be8ead6e479a62893.
Source-only until compilation and kernel replay are recorded. -/

/-! # Polynomial evaluation signs under ordered embeddings

Mapping coefficients and the evaluation point through a strictly monotone ring homomorphism
preserves the sign of the value. This applies to embeddings into ordered real closures.
-/


namespace Polynomial

/-- Mapping a polynomial and its evaluation point through a strictly monotone ring homomorphism
preserves its sign. -/
theorem sign_eval_map {R S : Type*} [Semiring R] [LinearOrder R]
    [Semiring S] [Preorder S] [DecidableLT S] (p : R[X]) (f : R →+* S)
    (hf : StrictMono f) (x : R) :
    SignType.sign ((p.map f).eval (f x)) = SignType.sign (p.eval x) := by
  rw [eval_map_apply]
  exact hf.sign_comp _

end Polynomial
