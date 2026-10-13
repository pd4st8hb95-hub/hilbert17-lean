# Final theorem-strength review

**Status: theorem-strength, final compilation, recursive-axiom inspection, and all 97 selected local same-kernel replays PASS.** Actual evidence is `final-hilbert17-contract01-run01`, independently reconciled in `FINAL-INDEPENDENT-AUDIT01.json`. All eight requirements below pass against the compiled exact contracts and unchanged baseline target. Portable offline Lake integration also passes: all 306 commands, four aggregate libraries, up-to-date check, and the actual emitted type/axiom output of both acceptance modules were verified. An additional fresh transitive imported-environment replay is pending separately.

Contract source: `FinalTargetContract.lean`, SHA256 `def53d25cc169ff2e08cf4979c86f05da5555d83d47fb021ea1f2044de69d140`.

## Required conclusions and premises

1. **PASS. Unrestricted variable count.** The complete explicit binder list is `(n : ℕ)`, with no positivity, fixed dimension, degree bound, finite enumeration cutoff, or other premise on n. `n = 0` is included. The evaluation tuple is exactly `Fin n → ℝ`
2. **PASS. Real coefficients.** The input is exactly `MvPolynomial (Fin n) ℝ`, not a rational-coefficient subring, an algebraic-coefficient restriction, a univariate polynomial, or a polynomial with an extra variable
3. **PASS. Weak nonnegativity.** The sole mathematical hypothesis on f is `∀ x : Fin n → ℝ, 0 ≤ MvPolynomial.eval x f`. No strict positivity, nonzero-f, compact-domain, generic-point, or off-denominator-zero restriction is allowed. In particular, the zero polynomial is included
4. **PASS. Correct rational-function field.** The rational-square conclusion uses `FractionRing (MvPolynomial (Fin n) ℝ)` and the canonical `algebraMap` image of f. The explicit rational-square contract produces some natural m and `Fin m`-indexed rational functions, with equality in that same field. No extra indeterminate is introduced through `RatFunc`
5. **PASS. Nonzero polynomial denominator.** The cleared conclusion explicitly produces `q : MvPolynomial (Fin n) ℝ`, `q ≠ 0`, a natural m and polynomial numerators p, satisfying `q ^ 2 * f = ∑ i : Fin m, (p i) ^ 2` as a polynomial identity. This requires q to be nonzero as a polynomial, and does not require q to be nowhere zero as a function
6. **PASS. No residual transfer premise.** `#check @` for the candidate and all real contract theorems must expose no `NegativePointTransfer`, model-completeness, quantifier-elimination, arbitrary-real-closure-existence, Archimedean, or completeness input. The separate `real_negativePointTransfer` contract must be a closed proof of `Hilbert17.NegativePointTransfer ℝ`, without a transfer hypothesis
7. **PASS. No substituted specification.** The actual definitions of `Hilbert17Target.Hilbert17Real`, `Hilbert17Target.Hilbert17RealCleared` and `Hilbert17.NegativePointTransfer` must be printed and compared with the explicit contracts. The baseline target source and final imported artifact hashes must be reconciled; the presence of a familiar theorem name alone is insufficient
8. **PASS. Complete proof dependencies.** Every final candidate and contract theorem's complete, possibly multiline, recursive axiom list must contain only `propext`, `Classical.choice`, and `Quot.sound`. Universe annotations on these names are harmless. `sorryAx`, new assumed mathematical statements, and alternate admitted transfer inputs fail acceptance

## Actual evidence required

- Successful compilation of the frozen final import closure, candidate source, and exact contract source
- Full printed types from the `@` diagnostics, including implicit binders
- Complete recursive axiom output for the three candidate/generic-transfer names and four acceptance contract names
- Successful selected-module replay of the final and newly adapted local modules against the intended imported artifacts
- Source and artifact hashes tying all these records to one final candidate revision

The review distinguishes compilation, selected same-kernel replay, and recursive axiom/type inspection. The actual final candidate and explicit contracts now establish the stated full-target types at the compiler/axiom-audit layer. It does not claim external independent verification or a fresh replay of every official Mathlib dependency. The separate selected all-local replay gate has passed for exactly the 97 modules listed in FINAL-REPLAY-INDEPENDENT-AUDIT01.json.

## Recorded result

All 17 complete recursive axiom records (14 distinct declarations) were parsed independently, including multiline lists and universe annotations, and exactly match the root receipt. Only `propext`, `Classical.choice`, and `Quot.sound` occur. All three diagnostic sources and artifacts match their recorded hashes. All 75 new delta proof sources also match successful compiler records and current output artifact hashes. The target source is byte-for-byte unchanged from the published baseline. The boundary harness verifies zero polynomials, the zero-variable case, and three necessity/sufficiency equivalences.
