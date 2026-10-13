# Verified real-closure prerequisite

Date: 2026-10-13. **Full Hilbert 17 remains unproved; polynomial-sign transfer is still unverified.**

- Seven real-closure modules: [compilation PASS](realclosure-compile02-run01/summary.json) and [selected-module replay PASS](realclosure-checker01-run01/summary.json)
- Forty-seven named declarations: [diagnostic compilations PASS](realclosure-axioms01-run01/summary.json), [root axiom-list audit](ROOT-REALCLOSURE-AXIOM-AUDIT01.json), and [independent receipt/hash audit](REALCLOSURE-INDEPENDENT-VERIFICATION.json). The complete printed recursive axiom lists contain only `propext`, `Classical.choice`, and `Quot.sound`
- Combined import entry: [Hilbert17RealClosure PASS](realclosure-entry/Hilbert17RealClosure.json). Only this entry's individual job and logs are included from its mixed execution batch; no claim about unrelated jobs is part of this delta
- Preserved earlier attempt: [realclosure-compile01-run01](realclosure-compile01-run01/summary.json). The two official quadratic-algebra dependencies passed; the first backport module failed because a `module` file imported legacy `OrderingSeparation`. The seven backports were switched to legacy import mode before the successful run

## Exact theorem scope

`TauCeti.RealClosure.exists_realClosure` assumes only `K : Type u`, `Field K`, `LinearOrder K`, and `IsStrictOrderedRing K`. It produces an ordered real-closed field `R : Type u`, a strictly monotone ring homomorphism from K to R, and algebraicity for the induced algebra. Real-closedness of K and a transfer principle are not assumptions.

This establishes an ordered-real-closure prerequisite. It does not establish the remaining negative-point transfer hypothesis in `ConditionalArtin`, and therefore is not an unconditional Hilbert-seventeenth proof.

## Reproducibility and trust boundary

The [source manifest](../realclosure-source-manifest.json) identifies the exact seven compiled source files. The [evidence manifest](realclosure-evidence-manifest.json) records original and exported hashes; ordinary logs replace only the original build-workspace prefix. Root and independent axiom receipts are copied byte-for-byte and retain their historical log references.

Replay uses the same Lean kernel against imported declarations. It is neither an external independent verifier nor fresh replay of every transitive official-library declaration. The portable entry was compiled against the verified module artifacts; a fresh checkout Lake build has not been run. No compiled artifacts or caches are delivered.

This is a delta on the frozen ten-module baseline. The ten baseline Lean files are unchanged, and no uncompiled transfer source is included.
