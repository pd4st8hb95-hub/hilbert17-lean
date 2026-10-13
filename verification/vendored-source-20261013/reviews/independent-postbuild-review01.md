# Independent static review of post-build verification tools

Date: 2026-10-13 UTC

## Result

**PASS FOR POST-BUILD PLAN PREPARATION, WITH THE LIMITS BELOW.** No blocking
defect was found in the three reviewed scripts. The source build was still
running during review. No fresh-replay plan existed, so this review does not
certify a particular generated inventory, replay run, or final result.

Reviewed scripts and SHA256 values:

- `guarded_vendor_fresh_replay.py`:
  `d7bc29bf24bf5e9ad1d21a659e73ba414c4aa14397a1e7c39ba7100ab5f8ed43`
- `make_vendor_fresh_replay_plan.py`:
  `ea4d50ef7fa65103c576e7d332d46d5eca5995fd3eaa219fbc484f6a52059a1d`
- `extract_vendor_acceptance_audit.py`:
  `daa0d60f27d77c289ecef1f9d12d4162e6b4577f648fefeaffedfc48f6f31f23`

The reviewer did not author these tools. No frozen source, config, driver, or
plan was changed. No generator main, Lean, Lake, leanchecker, or build subprocess
was invoked. Read-only source inspection and synthetic Python unit checks are
recorded in `independent-postbuild-static-checks01.json`.

## Verified properties

### Completion gate and inventories

The generator acquires the same exclusive compiler lock as the source builder,
requires the source-plan hash to match, and requires a completed 3,136-module
PASS receipt with unchanged inputs. It checks exact journal order, source pins,
every recorded output hash, compiled direct imports, and absence of untracked
active build artifacts before creating the inventory.

The inventory covers public/server/private oleans and IR in the project and
eight vendored build roots, plus the installed toolchain's `lib/lean` tree.
It also preserves all source/config/asset pins and all source-build output pins,
including `.ilean`, C output, setup files, hashes, and traces through the build
journal. Top-level toolchain shared libraries and the inspected LeanChecker and
Replay sources are pinned separately. Symlinks and duplicate inventory paths
are rejected. The replay runner rechecks inventory membership and all pins
before and after execution.

No inventory file or compiled artifact is copied into an alternate import
cache. The generator writes evidence outside the frozen source workspace.

### Read-only Lake environment and import search paths

The pinned command is exactly Lake `--no-cache --no-build env`, with the
absolute installed checker path followed by `--fresh -v BoundaryAcceptance`
for the replay. Installed Lake 4.32.1 source at
`Lake/CLI/Main.lean` lines 1139–1152 confirms that `env` loads the workspace,
prints augmented environment variables when no command is supplied, or spawns
the specified command. It does not request a build target. All actual active
configs are already reviewed declarative TOML files.

The probe's `KEY=value` format matches the parser. Fixed unchanged environment
variables are merged with the augmented variables Lake prints. The required
module paths must include all nine workspace artifact roots and may include
only the installed builtin root in addition. Empty, duplicate, or external
entries are rejected. Source paths must remain within the workspace/toolchain;
the sysroot and thread count must match. A sampled checker process must have
the exact invocation and a validated environment. A success result requires
that its environment was actually observed, avoiding a silent assertion based
only on a separate probe.

Static tests accepted the expected local/builtin environment and rejected
external module paths, duplicate paths, empty entries, a wrong sysroot,
external source paths, and a changed thread count.

### Replay semantics and guards

Installed `LeanChecker.lean` implements fresh replay by importing the named
module and replaying its environment's constant map into an empty environment.
`Lean/Replay.lean` lines 176–188 selects safe, non-partial constants. Inductive
constructors and recursors are compared with the reconstructed ones, and
declared axioms are accepted. The tool's documented same-kernel, safe/non-partial
scope and separate axiom audit are therefore accurate.

The runner uses the previously reviewed SHA256-pinned network guard. The
child-only filter is inherited by Lake/checker descendants and fails closed.
It retains the physical-memory refusal/TERM/KILL thresholds of 60/70/75 percent
and five-second TERM grace. A sampled unexpected compiler or helper process is
rejected. The checker does not receive an unsupported `-M` flag. Final pin or
inventory drift overrides a tentative replay PASS. No arbitrary wall-time
timeout is introduced.

### Fourteen theorem-type and recursive-axiom reports

The extractor requires full source-build PASS, correct plan hash, and the exact
completed journal. It identifies each acceptance module's unique successful
`:olean` command from its recorded attempt, verifies source and compiled-output
pins, then parses messages by exact source file and command line number.

Both actual acceptance sources contain seven `#check` and seven `#print axioms`
commands. Independent extraction from the historical logs yielded 14 type
reports and 14 axiom reports. Normalized type texts are compared to the prior
logs, while axiom lists must contain exactly `propext`, `Classical.choice`, and
`Quot.sound`. Synthetic replacements with `sorryAx` or the wrong printed
declaration name were rejected in both modules. Missing or malformed messages
fail closed; a genuine output difference returns a review-required status.

The extractor records its own hash and source/status/log hashes and correctly
describes its result as log extraction, not a new Lean execution or substitute
for fresh replay.

## Remaining conditions and limits

- Generate and review the actual replay plan only after the source builder
  reaches terminal PASS and releases its lock. Runtime probe, inventory checks,
  fresh replay, and extraction of the new acceptance logs are still pending.
- Memory/process observation is sampled every 0.5 seconds. It is not an
  exhaustive execution trace or a hard host-wide peak-memory limit. Network
  denial is enforced separately by the kernel filter. A too-short checker
  process that is never sampled would fail closed rather than certify success.
- The installed toolchain, system dynamic libraries, OS, and kernel remain
  trusted. Inventory hashes bind the installed proof/runtime inputs for this
  replay; they do not bootstrap Lean or create an independent verifier.
- Source/artifact pinning is before/after validation under a cooperative shared
  lock, not an immutable filesystem or protection against hostile concurrent
  changes that are reverted between checks.
- The acceptance extractor compares the 14 selected type and axiom reports;
  it does not compare the three additional `#print` definition bodies in
  `FinalTargetContract.lean`, rerun every historical diagnostic, or itself replay
  proof terms. The unchanged pinned sources, completed source build, and
  separate fresh replay supply those distinct parts of the evidence chain.
- The extractor reads final logs without taking the compiler lock. Its inputs
  must therefore be the completed, preserved source-build run, with no external
  writer changing its receipt/journal/logs during extraction. The fresh-replay
  runner itself holds the shared lock throughout its validation and run.
- The final user-facing report must use the new run's actual exit status,
  observed resources, and reviewed audit output. Historical passing logs and
  this static review do not establish the new replay's completion.
