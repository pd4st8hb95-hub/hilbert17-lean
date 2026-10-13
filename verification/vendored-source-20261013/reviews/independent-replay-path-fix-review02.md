# Independent review of replay search-path environment fix

Date: 2026-10-13 UTC

**Disposition: ACCEPT FOR NEW-PLAN PREPARATION AND REVIEWED RETRY.**
The actual corrected Lake environment must still pass the runtime probe; this
static review is not a successful replay result.

## Failure confirmed

The preserved `vendor-fresh01` probe output has a trailing `:` in both
`LEAN_PATH` and `LEAN_SRC_PATH`. The unchanged strict validator rejects these
as empty search-path entries. The run summary is terminal
`ABORTED_OR_INPUT_DRIFT`; its job list contains zero
`BoundaryAcceptance-fresh` jobs. This was an environment-validation stop before
checker launch, not a rejected mathematical proof or failed kernel replay.

## Source-based cause and fix

Installed Lean 4.32.1 sources confirm the distinction:

- `Lake/Util/NativeLib.lean`, `getSearchPath`: an absent environment variable
  yields `[]`; a present string, including an empty one, is passed to
  `SearchPath.parse`
- `Init/System/FilePath.lean`, `SearchPath.parse` and `toString` (lines 296–304):
  entries are split/joined with the platform separator; the empty string
  supplies an empty path component
- `Lake/Config/Env.lean`, `compute` (lines 186–187) records those initial
  paths; `leanPath`/`leanSrcPath` (lines 254–263) prepend installed paths
- `Lake/Config/Workspace.lean` then prepends package paths and emits the joined
  values, explaining the final empty component/trailing colon

Removing both keys from a newly constructed isolated environment therefore
supplies genuinely absent initial paths. It does not inherit the caller's
environment because the runner does not use `os.environ.copy()`.

## Independent checks

- Preserved old runner SHA256 verified:
  `d7bc29bf24bf5e9ad1d21a659e73ba414c4aa14397a1e7c39ba7100ab5f8ed43`
- Corrected runner SHA256 verified:
  `77635f04d0a0fba8506c0d655f1778b4a5882d1958821d32417a9e18fee1b786`
- Whole-file AST comparison confirms that the only semantic change is deletion
  of `LEAN_PATH` and `LEAN_SRC_PATH` from the isolated `env` dictionary.
  The extra source comment has no AST effect.
- `canonical_paths`, `verify_lake_environment`, `sampled_process_check`, and
  `run_command` are AST-identical. Strict empty/external path rejection,
  process checks, seccomp setup, and physical-memory guards are not weakened.
- The actual failed probe environment was independently passed to the current
  validator and rejected with `Empty search-path entry refused`.
- The environment predicted from the installed Lake source when those two keys
  are absent was accepted by the unchanged validator. This predicted value has
  not yet been observed from a new Lake process.

No Lean/Lake/checker was executed by this reviewer, no new replay plan was
generated, and no frozen source/build/config input was changed. The old runner
and failed run evidence remain preserved. A retry must use a newly pinned plan
for the corrected runner and retain the failed probe as a distinct attempt.

The source-build PASS, its compiled outputs, and its acceptance-log audit are
unaffected by this change to the separate post-build replay driver.
