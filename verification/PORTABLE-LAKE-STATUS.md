# Portable offline Lake integration

**PASS, 2026-10-13.** All 306 guarded commands passed: dependency prechecks and builds for 152 modules (97 delivery-local and 55 official supplement modules), followed by all four aggregate library targets and the final no-build up-to-date check.

Both `FinalTargetContract` and `BoundaryAcceptance` have actual `Built` markers. Their entire previously audited emitted type/definition/axiom output is reproduced after removing Lake’s location prefixes. These two modules emit 14 unique standard-only axiom records; the earlier three-harness diagnostic run emitted 17 records because three final declarations were repeated. See the [independent audit](PORTABLE-LAKE-INDEPENDENT-AUDIT01.json), [root audit](ROOT-PORTABLE-LAKE-AUDIT01.json), and [terminal summary](portable-runs/portable-lake02-run01/summary.json).

The check used an isolated workspace with copied pinned official source/cache dependencies. The delivered four-library configuration was unchanged except for private weakLeanArgs `-j 1 -M 4096`; command-local path overrides kept dependency access offline. No delivery Lean source changed. Maximum sampled physical memory use was approximately 25.0061%. This establishes offline package integration, not a fresh online clone/download, a full dependency rebuild, or an external independent kernel verification.

The [first attempt](portable-runs/portable-lake01-run01/summary.json) failed before a Lean proof build because `--packages` expected a partial-manifest JSON object rather than a bare array. The pinned official Lake parser established the correct `schemaVersion`/`packages` shape. The corrected second attempt passed; the failure’s logs and inputs are retained.

[Input plans and configuration](portable-inputs/) and all actual run logs are included. The 12.3-MB initial copied-cache inventory is represented by its exact SHA-256, byte count and pin count in [its commitment record](portable-inputs/INITIAL-INPUT-INVENTORY-COMMITMENT.json); caches and that bulky inventory are not bundled. The full inventory remains in the original execution workspace.

The additional `--fresh` replay of the safe, non-partial imported environment of BoundaryAcceptance, including the relevant Mathlib proofs, also passes. The current complete recursive axiom audit already excludes an unproved external mathematical claim in the final theorem’s dependency chain, but that audit is distinct from rechecking every imported constant from scratch.

See [fresh replay and formalized external inputs](FRESH-REPLAY-STATUS.md) for the additional successful checkpoint, input bindings, and same-kernel/axiom limitations. Earlier immutable receipts retain their historical scope.
