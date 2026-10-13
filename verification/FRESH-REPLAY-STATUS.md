# Fresh imported-environment replay and external mathematical inputs

**PASS, 2026-10-13.** The exact command `leanchecker --fresh -v BoundaryAcceptance` exited 0 in 526.513 seconds. Standard output was exactly `replaying BoundaryAcceptance with --fresh`; standard error was empty. The sampled peak physical-memory use was approximately 26.1235%. The one-hour bound and existing memory thresholds were not reached.

See the [terminal summary](fresh-replay01-run01/summary.json), [stdout](fresh-replay01-run01/BoundaryAcceptance.stdout.log), [stderr](fresh-replay01-run01/BoundaryAcceptance.stderr.log), [memory samples](fresh-replay01-run01/BoundaryAcceptance.memory.jsonl), [frozen plan](fresh-inputs/fresh-replay-plan01.json), [runner](fresh-inputs/run_bounded_fresh_checker01.py), and [independent reconciliation](FRESH-REPLAY-INDEPENDENT-AUDIT01.json).

## What this checks

The pinned Lean 4.32.1 source implements `LeanChecker.replayFromFresh` by passing the loaded imported constant environment to `mkEmptyEnvironment.replay`. This rechecks the safe, non-partial declarations in `BoundaryAcceptance` and its imported environment, including the final Hilbert17 proof chain and the Mathlib results it uses. Constructors and recursors are compared with those generated from checked inductives. Duplicate theorem declarations with identical name, type, universe parameters and mutual-block list may reuse the already checked declaration. Unsafe/partial implementation code is skipped.

This uses Lean’s own pinned kernel. It is not an external independent proof checker, a claim to check every installed Mathlib module, a new online checkout, or an axiom-free construction. Declared axioms are accepted by the replay mechanism; the separate complete recursive axiom audits establish that the final theorem depends only on `propext`, `Classical.choice`, and `Quot.sound`. No bibliographic, transfer, real-closure-existence, Rolle, or matrix-invertibility assumption remains unproved in the real target.

## Exact input binding

The fresh entry artifact is the one built in the verified offline Lake package. Its source, compiled artifact, command, toolchain and successful Lake receipt are pinned by the plan. The driver checked the full artifact inventory before and after replay. The independent reviewer additionally rehashed all 24,091 available search-path artifact files (4,863,176,336 bytes), all 97 pinned local sources, and all 12 pinned configuration files, and checked exact inventory membership. These counts describe available files, including unused ones; they are not counts of replayed declarations or imported modules.

The full 6,553,117-byte inventory is retained in the original execution workspace, rather than bundled here. Its exact SHA-256 `d3874f0120dd7da2cad2141a3850dedc4556ec04bf8280131d59e502795f4539`, file/byte counts, source pins and configuration pins are preserved in the [inventory commitment](fresh-inputs/ARTIFACT-INVENTORY-COMMITMENT.json). Compiled caches are not shipped. The source-based checker semantics and their file hashes are recorded in the independent audit.

## External ingredients already have formal proofs

The [ingredient explanation](../EXTERNAL-INGREDIENT-PROOFS.md) and [machine-readable map](../EXTERNAL-INGREDIENT-MAP.json) identify 49 substantial source-level ingredients and 83 declarations. This is not advertised as a minimal declaration dependency graph. The [delivery-path index](../EXTERNAL-INGREDIENT-DELIVERY-INDEX.json) resolves original workspace paths to repository files or exact pinned Mathlib source URLs.

The mapping independently matches all declaration line locations and source hashes, 36 local entries against successful replay records, and 13 Mathlib source files against both their recorded Git blobs and the actual pinned Git tree. Upstream references give attribution and mathematical background; the Lean proof bodies supply the used conclusions. Generic intermediate hypotheses are discharged by the final formal assembly. The earlier 97-module selected replay, 306-command offline Lake verification and exact theorem/axiom contracts remain valid; this fresh check adds the imported-environment replay layer.

## Reproduce after the normal build

```sh
lake build Hilbert17Full Hilbert17Acceptance
lake env leanchecker --fresh -v BoundaryAcceptance
```

This stronger replay can be more resource-intensive than a normal module check. The command uses the package’s ordinary Lake environment; no machine-local cache path is part of the delivered build configuration. The historical bounded runner and exact resource measurements describe the recorded run, not a universal resource guarantee.
