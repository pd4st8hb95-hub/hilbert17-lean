# Independent static build-input audit

Verdict: **PASS_STATIC_BUILD_INPUT_PREFLIGHT**

Target: `hilbert17-vendored-20261013`  
Preflight completed: 2026-10-13 15:53:58 UTC

## Verified findings

- 3,039 dependency source files (2,775 Mathlib and 264 other dependencies) match their SHA-256 records and exact pinned upstream Git tree blobs
- 97 local Lean roots match `hilbert17-portable-check` byte for byte
- 3,136 total sources form the complete reachable, topologically sortable selected graph; there are no missing non-toolchain imports, recorded dependency-import mismatches, unused selected sources, or cycles
- All nine active TOML configurations and JSON manifests use contained relative dependency paths; no active executable dependency configuration, download hook or npm build is selected
- All 15 required compile-time assets exist and match hashes; 14 are unchanged upstream assets and one is the explicitly documented Penrose headless adapter
- Package licenses and preserved package metadata match upstream pins; widget metadata and the supplementary MIT notice match their recorded hashes
- No copied compiled artifacts or symlinks were found before the fresh build began

No source/configuration/asset changes were required before launching the separately reviewed guarded driver.

## Exact principal hashes

- `lakefile.toml`: `d2497b72829a856e7c2453ac1531463623e861e1c58f8e0ce379d844fe078da8`
- `lake-manifest.json`: `8ddff59e6c833c5df73269b7abc87e246092bfac9dc5fde859ba71665b7f3fab`
- `vendor-source-manifest.json`: `cfcc0720302f30b3c2796812600ec5c1363952eba437350890cb227ca69eaccf`
- `vendor-asset-manifest.json`: `259019017037f265bd3f091acb7c751f575c565b8f0ecfb3457db6c2e1addfe3`

All nine active configuration/manifest pairs, package license/toolchain files, documentation, and the 97 local sources have exact hashes in the companion JSON.

## Method

1. Read active lakefile.toml and lake-manifest.json in the root and all eight vendor package directories, parsed TOML/JSON, checked contained existing relative paths and active configuration selection.
2. Read all 3039 dependency source files. Recomputed SHA-256, byte counts, Git blob SHA-1 and compared blob identifiers to git ls-tree at each exact manifest commit in previously available local upstream repositories.
3. Independently parsed Lean import headers with nested-comment removal and public/meta/import-all syntax support; compared every dependency import set to the manifest. Traversed closure from all 97 local roots and computed a full topological ordering.
4. Located source include_str/include_bytes paths, resolved all 15 assets, and checked their exact bytes against the asset manifest. Independently checked all 14 unchanged asset blobs against their exact pinned upstream Git trees. Read the original headless adapter and its documented scope.
5. Compared all 97 local root bytes against hilbert17-portable-check; recomputed their SHA-256 hashes.
6. Checked package license/toolchain metadata against pinned upstream trees. Checked preserved widget metadata and supplementary notice hashes, and inspected root upstream legal-metadata names.
7. Before source01 began, searched the archive for copied Lean/object/library build artifacts and symlinks; none were found.

## Verification boundaries

- Static PASS is input readiness, not successful compilation or theorem verification. Final evidence must come from the separate fresh serial source build and final target replay.
- This reviewer did not execute or approve the serial driver, test its network-denial guard, or measure runtime resource use.
- The trusted installed Lean 4.32.1 toolchain and bundled Init/Std/Lean/Lake are outside the vendored-source reconstruction boundary; this review did not rebuild or independently verify that compiler/runtime.
- Import parsing is a static header audit, not a Lean compiler run. It exactly matched the recorded imports for all selected dependency modules.
- The Penrose JavaScript adapter is original replacement code. Diagram rendering is intentionally unavailable; unchanged Lean proof-source bytes do not imply unchanged widget hashes or compiled artifacts.
- The provenance/notice check is targeted and is not a legal certification. The supplementary react-fast-compare notice was hash-checked against the supplied manifest, not independently refetched in this review.
- Original executable dependency configurations under UPSTREAM and historical verification receipts are inert evidence, not active configuration or evidence of the new adapted build.
- The no-artifact finding describes the pre-build inspection, not the directory after source01 starts producing fresh outputs.
- Initial broad regex import scan reported only false positives from import-all keywords and embedded JavaScript; the subsequent header-only parser resolved these with zero import mismatches.

This report preserves a static preflight result. It must not be presented as the result of the new from-source build.
