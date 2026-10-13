# Reviewed serial source-build tools

`make_source_build_plan.py` only reads inputs and writes a frozen JSON plan. It
does not run Lean or Lake. `guarded_source_build.py` runs the plan only when
explicitly launched with the plan SHA256.

## Scope

The plan covers all 3,136 non-toolchain modules: 2,775 Mathlib, 264 other package,
and 97 project modules. Lean, Std, and Lake from the installed Lean 4.32.1
toolchain remain trusted binary dependencies. A successful run therefore means
a fresh build of this complete project/external-package source slice, not a
bootstrap of the Lean compiler itself and not a declaration-minimal proof slice.

The frozen plan pins 3,374 input files (42,337,137 bytes), including vendor
JavaScript inputs. Non-executable historical evidence in `verification/` is not
a build input and is excluded. Build outputs are never imported from the old
portable workspace.

## Launch, after independent review

```sh
python hilbert17-vendor-tools-20261013/guarded_source_build.py \
  --plan hilbert17-vendor-tools-20261013/source-build-plan01.json \
  --plan-sha256 c7d5a8da7b42d45d2ab1c59944268ad8416b168f9b71be63f906345617e05460 \
  --run-name source01
```

The run refuses any preexisting build artifact. It acquires the preexisting
shared `runtime-compile.lock`, validates all input pins, and performs each module
in topological order:

1. `lake --no-cache --no-build build +Module:deps`
2. `lake --no-cache build +Module:olean`
3. Verify fresh `.olean`/`.ilean`, module identity, and direct imports
4. Hash outputs and append a durable completion-journal record

All active package configs are TOML, with no executable configuration or custom
targets/hooks. Each Lean compiler is configured with `-j 1 -M 4096`. The driver
also checks sampled compiler processes for unexpected source paths, parallel
Lean compilers, other executables, or changed resource arguments. This sampled
process check is a backstop, not exhaustive process tracing.

## Resource and network controls

Actual host physical memory (`MemTotal`/`MemAvailable`) is sampled every 0.5
seconds. A command is refused at 60% used, receives SIGTERM at 70%, and receives
SIGKILL at 75% or after five seconds of TERM grace. There is no arbitrary build
wall-time cutoff. Child process groups are killed when the command exits or the
driver is interrupted.

Every Lake child gets an inherited, fail-closed libseccomp network filter. Socket
creation/traffic and io_uring networking routes are denied with EPERM. No host
system/network settings are changed. Popen closes unneeded inherited file
descriptors. HOME, temporary files, and caches are isolated; LEAN_PATH and
LEAN_SRC_PATH are empty. Cache downloads and release reuse are disabled.

The filter was tested using locally authored Python only: socket/socketpair in
the child and socket in its grandchild all returned EPERM. See
`preflight-self-test01.json`. This preflight is not a Lean compilation result.

## Failure preservation and explicit resume

Each attempt retains stdout, stderr, physical-memory samples, per-command status,
and a summary. Successful module output pins are durably appended to
`runs/source01/completed.jsonl`. Failed or interrupted output is left in place.

To resume the same reviewed plan, repeat the launch command with `--resume`.
This revalidates source/config pins and all completed module outputs, preserves
the one unfinished module's partial outputs in a separately indexed quarantine,
and continues at that module. Unknown artifacts or changed completed outputs
stop the resume for review. No failed-attempt evidence is deleted.

If an input, runner, or configuration changes, the old frozen plan is invalid;
review the change and generate a new plan. Do not claim the new inputs were
verified by the old run. A torn completion-journal record or unexplained artifact
requires a separately reviewed recovery; the driver does not silently discard it.

All inputs are hashed at the beginning and end of each attempt; only the current
source and small fixed configurations/tools are rehashed per command. Final
checks require aggregate builds to be up-to-date, revalidate every recorded
output, and reject untracked artifacts before reporting success.
