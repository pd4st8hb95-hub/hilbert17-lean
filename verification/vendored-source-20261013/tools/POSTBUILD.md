# Post-build verification tools

These files are outside the frozen build workspace. They do not run Lean/Lake
on import. Do not generate a replay plan or run replay concurrently with
`source01`. Both plan freezing and replay require the same exclusive compiler
lock and a terminal `ALL_FROM_SOURCE_OFFLINE_LAKE_BUILDS_PASS` source receipt.

## 1. Freeze the completed source build for replay

After all 3,136 modules and aggregate checks pass, run:

```sh
python hilbert17-vendor-tools-20261013/make_vendor_fresh_replay_plan.py \
  --source-plan hilbert17-vendor-tools-20261013/source-build-plan01.json \
  --source-plan-sha256 c7d5a8da7b42d45d2ab1c59944268ad8416b168f9b71be63f906345617e05460 \
  --source-run hilbert17-vendor-tools-20261013/runs/source01 \
  --output hilbert17-vendor-tools-20261013/vendor-fresh-plan01.json
```

This performs no Lean execution. It checks the successful source journal,
source/config/asset pins, every generated build output, and exact module import
lists. The separate full inventory additionally pins all Lean/Std/Lake
olean/private/server/IR artifacts under the installed toolchain, its shared Lean
libraries, and the installed LeanChecker/Replay source files. These remain
trusted prebuilt runtime artifacts. No artifact is copied.

The generator prints the replay plan's SHA256. Independently review the plan and
inventory before launch. Keep the original workspace unchanged until replay
finishes; even existing documentation was pinned by the source-build plan.

## 2. Run fresh replay

```sh
python hilbert17-vendor-tools-20261013/guarded_vendor_fresh_replay.py \
  --plan hilbert17-vendor-tools-20261013/vendor-fresh-plan01.json \
  --plan-sha256 REPLACE_WITH_GENERATED_PLAN_SHA256 \
  --run-name vendor-fresh01
```

The only Lake operations are `lake --no-cache --no-build env` and the same
environment command followed by the pinned
`leanchecker --fresh -v BoundaryAcceptance`. No build facet or update command is
called. The probe validates that the module search path contains only this
workspace's root/eight vendor output directories and the installed toolchain.
The running checker environment is sampled and validated again. Compiler or
other unexpected child processes are forbidden by the sampled process guard.

The inherited child-only libseccomp filter and physical-memory policy match the
source driver: 0.5-second samples, refuse at60%, TERM at70%, KILL at75%, five
seconds of TERM grace. There is no arbitrary wall-time cutoff. LeanChecker has
no compiler-style `-M` memory option; only the physical-memory guard applies.

All pinned sources, assets, configs, full output inventory, and trusted builtin
inventory are rechecked afterward. Full inventories stay in this tools folder;
the replay run summary is compact enough for a publication evidence bundle.

Scope: same-Lean-kernel replay of every safe, non-partial constant in
BoundaryAcceptance's whole imported environment. It is not a separately
implemented verifier. Declared axioms remain accepted by replay, so use the
separate recursive axiom audit below. It does not replay unsafe/partial code or
bootstrap Lean itself. BoundaryAcceptance's closure is the replay scope, not an
assertion that every unrelated module in the full build was replayed.

## 3. Extract fresh theorem-type and recursive axiom reports

```sh
python hilbert17-vendor-tools-20261013/extract_vendor_acceptance_audit.py \
  --source-run hilbert17-vendor-tools-20261013/runs/source01 \
  --source-plan hilbert17-vendor-tools-20261013/source-build-plan01.json \
  --source-plan-sha256 c7d5a8da7b42d45d2ab1c59944268ad8416b168f9b71be63f906345617e05460 \
  --prior-final-log hilbert17-20261013/verification/portable-lake02-run01/296-FinalTargetContract_olean.stdout.log \
  --prior-boundary-log hilbert17-20261013/verification/portable-lake02-run01/298-BoundaryAcceptance_olean.stdout.log \
  --output hilbert17-vendor-tools-20261013/vendor-acceptance-audit01.json
```

This executes no Lean. It uses the new source run's successful compile logs,
verifies source/output pins, extracts seven #check and seven #print axioms
results from each acceptance module, and compares normalized type text and
recursive axiom sets to prior portable logs. All fourteen axiom reports must
contain precisely propext, Classical.choice, and Quot.sound, ignoring printed
universe parameters. Differences produce a review-required result rather than a
success claim. The full extracted theorem types remain in the audit artifact.

## Portable serial-build draft

`portable-draft/scripts/build_serial.py` is a separately deliverable,
cross-platform Python3.11 convenience script. Once placed at `scripts/` in the
repository, users can run `python scripts/build_serial.py`; `--check-plan`
performs only read-only source/config/asset/DAG checks. The latter's 3,136-module
order and first/last/aggregate commands were checked against source01's frozen
plan. No actual portable-script Lean build has been run here.

It resolves an already installed concrete Lean toolchain without executing an
elan shim, checks the installed version, and runs serial deps/olean commands.
It does not implement the Linux audit driver's kernel network blockade,
physical-memory guard, shared audit lock, fresh-artifact requirement, or detailed
output audit. Existing artifacts may be reused; restarting after a failure uses
Lake's normal up-to-date checks. Do not equate its static plan validation with a
fresh build or replay pass.
