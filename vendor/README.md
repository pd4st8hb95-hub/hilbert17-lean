# Vendored Lean dependency slice

This directory contains the complete transitive whole-module dependency slice for all 97 configured Hilbert17 project roots, based on the previously compiled modules' recorded `directImports`.

- Mathlib: 2,775 Lean files, 901,274 physical lines
- Other dependencies: 264 Lean files, 39,203 physical lines
- Eight dependency packages in total; Lean's own Init/Std/Lean/Lake modules remain part of the separately installed `leanprover/lean4:v4.32.1` toolchain
- `Cli` is not in this source import closure and is not needed when the unrelated ImportGraph command-line targets are omitted

Every vendored dependency `.lean` source is byte-identical to its pinned upstream Git blob. The exact repositories, commits, modules, import edges, counts, and SHA-256 hashes are in `../vendor-source-manifest.json`. Each package retains its original license. `UPSTREAM/` contains inert historical upstream configuration, manifests, and supporting attribution; these are not the active build configuration.

## Offline packaging adaptations

Active package configurations are local-path-only and omit the original Mathlib cache-download hook and ProofWidgets npm build hooks. They build the included source slice, rather than nonexistent aggregate roots or unrelated executable/test targets.

The 15 files loaded by `include_str` are recorded in `../vendor-asset-manifest.json`. Fourteen match tracked upstream Git blobs: six Mathlib diagram-language files and eight small ProofWidgets JavaScript files.

The remaining file, `proofwidgets/widget/js/penroseDisplay.js`, is an original headless adapter. It exports the same default component interface but displays an explanatory message instead of rendering Penrose diagrams. This avoids redistributing the original 2.66 MB Penrose/MathJax bundle before all third-party license notices have been independently established. The replaced original is tracked upstream, and its exact Git blob and SHA-256 are recorded. No Lean source was changed; the embedded JavaScript string and resulting widget hash do change, so a fresh build and final target replay are required.

Small widgets retain external imports of React and Lean Infoview rather than bundling those libraries. `ofRpcMethod.js` also bundles `react-fast-compare` 3.2.2; its pinned upstream MIT license is retained under `proofwidgets/UPSTREAM/`, together with original widget TypeScript sources and their attribution headers. The license inventory is a targeted provenance/notice audit, not a legal certification.

## Validation boundary

The dependency-copy step verified file hashes, upstream Git blob identity, the recorded import closure, auxiliary-file availability, and absence of copied Lean build artifacts. This static check alone is not a successful compilation. See the repository's new from-source build receipts and final fresh replay for the actual validation result; historical replay receipts do not establish the adapted build environment.
