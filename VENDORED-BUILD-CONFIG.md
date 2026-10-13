# Offline build configuration and verification scope

This is the declarative build configuration for the exact imported source slice
in `vendor/`. It is not a copy of the complete Mathlib repository. It retains all
97 configured project roots and uses the package and module names of the pinned
upstreams. Source hashes, upstream commits, licenses, asset hashes, and the import
closure are recorded in `vendor-source-manifest.json` and the package provenance
files. No mathematical Lean source is changed by this configuration overlay.

## Installed prerequisite

Lean **4.32.1**, including its bundled Lean/Std/Lake libraries, must already be
installed. Invoke that installation's Lake from the repository root. The root
`lean-toolchain` remains `leanprover/lean4:v4.32.1`. Toolchain installation itself
is outside this offline build. The upstream dependency toolchain files are kept
as provenance; some request older versions, so do not start Elan in a vendored
package directory when performing this build.

## Active local graph

- `hilbert17` requires `vendor/mathlib`
- `mathlib` requires sibling directories `batteries`, `Qq`, `aesop`,
  `proofwidgets`, `importGraph`, `LeanSearchClient`, and `plausible`
- `aesop` requires sibling `batteries`
- All other active packages have no package dependencies

Every dependency declaration and every active manifest entry is a relative
filesystem path. No active config declares a Git URL, registry dependency,
post-update hook, cache executable, JavaScript build, release download, custom
target, or executable. Package artifact-cache reuse is explicitly disabled, as
is preference for prebuilt releases. The upstream configs and manifests under
`vendor/*/UPSTREAM/` are inert evidence and must not replace the active files.

`Cli` is not needed by this slice: its upstream dependency was for excluded
import-graph command-line executables, and no selected Lean module imports Cli.

## Recorded build adaptations

1. Root: preserve name, version, all four libraries and the original 97 roots;
   replace the pinned Git dependency with `vendor/mathlib`; add weak compiler
   limits `-j 1 -M 4096`; disable local artifact cache and release preference.
   Preserve the original published root configs separately as provenance.
2. Mathlib: translate the original Lean DSL to declarative TOML; preserve
   `fixedToolchain`, `platformIndependent`, `restoreAllArtifacts`,
   `pp.unicode.fun = true`, `autoImplicit = false`,
   `maxSynthPendingDepth = 3`, and the exact six original weak linter options.
   Remove the post-update cache-fetch hook, cache tooling, test/archive/docs
   targets, maintenance executables, and the ProofWidgets `errorOnBuild` option
   associated with the omitted JavaScript build target.
3. ProofWidgets: retain the Lean library only. Remove `widgetJsAll` and all npm
   targets. Required `include_str` JavaScript files are provided as hashed input
   assets. The asset manifest separately identifies a headless Penrose rendering
   adapter approved for this build; do not describe that one asset as an exact
   upstream JavaScript copy. The Lean source build compiles the Lean wrappers,
   not the TypeScript origin of the supplied UI assets. It verifies the proof
   modules with this explicitly recorded UI-asset adaptation, without adding
   proof axioms. This headless package is not a full upstream widget UI build.
4. Aesop: preserve `precompileModules = false` and `platformIndependent = true`;
   change its Batteries dependency to a relative path; omit the test target.
5. Batteries: preserve `linter.missingDocs = true`; omit tests and executables.
6. Qq, LeanSearchClient, Plausible: retain their library only, retaining package
   version where present; omit tests. ImportGraph: retain its library and license
   metadata, omit graph executables, tests, and the now-unneeded Cli dependency.
7. All vendored packages: disable artifact-cache reuse and release preference;
   add the same weak single-thread/per-process memory compiler arguments.
8. For `Mathlib`, `Batteries`, `ProofWidgets`, and `ImportGraph`, use submodule
   globs (`Prefix.+`) because the upstream all-modules aggregate is outside the
   import slice. The other four retain their present aggregate and use
   `Prefix.*`. Library names/root namespaces are unchanged.

## Source build and resource limits

Use the accompanying guarded, topologically ordered serial build procedure from
the repository root. It must compile all selected dependencies and all 97
project modules with the installed Lean 4.32.1, with no preexisting `.lake`
artifacts, no copied `.olean` files, and no cache restoration. Its network-denial
guard provides the runtime check that no downloader or network request succeeds.

The `-j 1` argument limits each Lean process; by itself it is not a promise that
an unrestricted aggregate `lake build` will launch only one compiler process.
The serial driver must build one topologically ready module at a time and apply
the physical-memory threshold of 75 percent. Per-process `-M 4096` is not a
substitute for that host-wide guard. It must also check free disk before and
during the build and stop before exhausting it. Do not delete historical build
evidence to create space without approval.

The historical Mathlib build directory was about 2.9 GiB when inspected, with
about 17 GiB free on this machine. This is a feasibility observation, not a
guarantee or a measurement of this fresh build. The final report must record the
new build's actual resource usage and every failure/retry.

## Verification status

The configuration author inspected Lean 4.32.1's installed Lake source for TOML
dependency decoding, library glob semantics, artifact-cache controls, and
manifest 1.2.0 path semantics. No build or script was executed by that author.
Configuration design and source provenance are not compilation evidence. A
complete-from-source verification claim is justified only after the separate
fresh guarded build succeeds and its logs are reviewed. Historical theorem
replays remain distinct evidence and are not relabeled as this fresh build.

Bundled compiler/runtime libraries are the trusted installed toolchain boundary;
this procedure does not rebuild Lean itself or validate its C++ runtime from
source. A fresh compile and Lean-kernel replay are not an independent verifier.
