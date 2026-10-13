# Verification status

Date: 2026-10-13. **Full Hilbert 17 remains unproved.**

1. **Ten module compilations: PASS.** Byte-identical source hashes and the individual successful receipts are linked by [source-manifest.json](../source-manifest.json). Several earlier batches stopped on another module; use each module's own job status, not the batch status alone.
2. **Ten selected-module replays: PASS.** [Nine-module receipt](proof-checker01-run01/summary.json) and [ConditionalArtin receipt](proof-checker02-conditional-run01/summary.json). This is same-kernel replay against imported dependencies, without a fresh transitive replay.
3. **57 selected declaration axiom audits: PASS.** [Exact root audit receipt](ROOT-AXIOM-AUDIT01.json), SHA256 `04daff555f02e9b7f6043b6572e1d79015b35993fd42ad25790c931994cd3494`, and [ten diagnostic compilations](proof-axioms02-run01/summary.json). The reported dependencies are limited to `propext`, `Classical.choice`, and `Quot.sound`. Diagnostic sources are in [checks](../checks).
4. **Portable import entry point: PASS.** [Successful receipt](delivery-entry02-run01/summary.json), source SHA256 `e9106e6e8c285b757837dee59235076db13ff35959bb74afee7d63205bcca497`. It was compiled against the checked imported module artifacts. Its first attempt failed because a module-doc command preceded imports; the ordinary-comment correction left the ten baseline modules unchanged. The failure is preserved in [delivery-entry01-run01](delivery-entry01-run01/summary.json).
5. **Fresh portable Lake checkout/build: not run.** Git pins and package structure are staged for reproduction. Existing compile receipts came from the pinned isolated environment.

`ConditionalArtin` explicitly requires `NegativePointTransfer`; the audit includes that definition and the printed conditional theorem types. No evidence here proves the premise.

## Evidence exports

[evidence-manifest.json](evidence-manifest.json) records original and exported SHA256 hashes. In ordinary exported logs and summaries, the original build-workspace prefix is replaced by `<build-workspace>`; outcomes and remaining text are unchanged. These historical command paths are not runnable package instructions. The root axiom receipt is copied byte-for-byte and retains historical log references; the corresponding logs are under `proof-axioms02-run01/` here.

No compiled artifacts, cache, credentials, execution drivers, or private research notes are included. The artifact hashes in the source manifest identify the checked originals but do not distribute them.

## Later verified real-closure prerequisite

Seven additional modules have passed compilation, selected same-kernel replay, and a 47-declaration axiom audit. See [REALCLOSURE-STATUS.md](REALCLOSURE-STATUS.md). The initial ten-module facts above remain unchanged; full Hilbert 17 still requires unverified polynomial-sign transfer.
