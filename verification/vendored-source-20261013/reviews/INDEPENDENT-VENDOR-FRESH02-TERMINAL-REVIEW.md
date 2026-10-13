# Independent review of terminal vendored fresh replay

Verdict: **PASS_TERMINAL_FRESH_REPLAY_EVIDENCE**

Reviewed: 2026-10-13T19:55:56.696736+00:00

## Verified result

- Source01 compiled all **3,136 project/vendor modules**, including the aggregate and final no-build up-to-date checks
- Vendor-fresh02 completed **BoundaryAcceptance fresh replay**, exit code **0**, in **515.567 seconds**
- The checker emitted exactly `replaying BoundaryAcceptance with --fresh`; stderr is empty
- Rehashed **3,374 frozen source/config/asset inputs**, **43,322 generated build outputs**, and **21,979 replay artifacts**, plus pinned runtime/evidence files. All identities and artifact membership checks pass
- Inspected all **1,027** replay memory/process samples. **1,026** sampled the same checker PID; the initial sample preceded checker appearance. Maximum sample spacing was **0.526 seconds**, and peak physical memory use was **25.6035%**
- Parsed Lake probe paths and the sampled checker environment agree: only the nine intended project/vendor artifact roots plus the installed toolchain. No empty or external module-search entry was accepted

## Honest verification scope

The full source build covers 3,136 selected modules. The fresh replay entry reaches **3,131** selected project/vendor modules, plus its imported installed-toolchain environment. The five built modules outside that entry closure are FinalTargetContract, Hilbert17, Hilbert17Full, Hilbert17RealClosure and TargetSanity.

Fresh replay checks safe, non-partial constants using the **same Lean kernel implementation**. It is not a separately implemented verifier, does not bootstrap Lean, and does not verify unsafe/partial code. Declared axioms remain accepted. The separately bound acceptance audit supplies fourteen theorem-type and fourteen recursive-axiom reports, limited to propext, Classical.choice and Quot.sound.

## Preserved earlier stop

Vendor-fresh01 stopped during environment validation before checker launch because initially empty path variables yielded trailing search-path separators. Its five original run files and its original driver are preserved with exact hashes. The corrected driver’s AST differs only by omitting those two initial empty variables; strict path checks, sampled process checks, network filter and memory guard are unchanged. A new plan and separate run preserve this distinction.

## Principal SHA-256 bindings

- `vendor-fresh-plan02.json`: `6233bed408866c19a425870588c83329fe8464d4ba99c8c2bc97ba6c4ab439b2`
- `vendor-fresh-plan02-inventory.json`: `d7098596b683564cb823f9371ae520c5869a5da11f1140bc7d9933554f2a5dbd`
- `guarded_vendor_fresh_replay.py`: `77635f04d0a0fba8506c0d655f1778b4a5882d1958821d32417a9e18fee1b786`
- `replay-runs/vendor-fresh02/summary.json`: `c1a42cc27a79908d17f0f1692c4ba0f6debee066fcc15aacee0f6d2fcb2efb75`
- `replay-runs/vendor-fresh02/BoundaryAcceptance-fresh.json`: `d01fa8b7ad9bad18de08067e3e0eb3d6a673eccc87011365dae44990816c21bc`
- `replay-runs/vendor-fresh02/BoundaryAcceptance-fresh.stdout.log`: `1f18cd70358f4e1959a8f5e0923c39abe003d84b76283e33dac17c129bc7526a`
- `replay-runs/vendor-fresh02/BoundaryAcceptance-fresh.memory.jsonl`: `3c21168adfd8d5e4932e0f787dbe0b81cee2bf73e7b54a9c3bee125f3d6f81b3`
- `runs/source01/summary.json`: `437f5a86d3b5b46822f9a15672a7128109940bc17d1450309835a7e7e27b039d`
- `source-build-plan01.json`: `c7d5a8da7b42d45d2ab1c59944268ad8416b168f9b71be63f906345617e05460`
- `vendor-acceptance-audit01.json`: `dedd575f4975cd2533cb0250c436ddbbc0a3831fd1fc7b7aa0a7dd59d363ae16`
- `replay-runs/vendor-fresh01/summary.json`: `c17ba95601763e46288ff67236b334b3c05f5e9a41f72be0282909a21af56a43`
- `historical-drivers/vendor-fresh01/guarded_vendor_fresh_replay.py`: `d7bc29bf24bf5e9ad1d21a659e73ba414c4aa14397a1e7c39ba7100ab5f8ed43`

The companion JSON binds every top-level file from both replay attempts, both plans/inventories, source-build evidence, the acceptance audit and historical driver preservation.

## Review limits

- This is an independent read-only evidence/identity review; no compiler or checker was rerun by this reviewer.
- Fresh replay uses the same Lean kernel implementation. It is not an independently implemented verifier and does not rebuild the compiler/runtime.
- Replay covers safe, non-partial constants in BoundaryAcceptance and its entire imported environment. It does not cover unsafe/partial code or the five built modules outside that entry closure.
- The replay accepts declared axioms. The separately bound acceptance audit reports fourteen theorem types and fourteen recursive axiom footprints, all limited to propext, Classical.choice and Quot.sound.
- Process identity and memory checks are sampled every approximately 0.5 seconds. Sampled checker PID/environment evidence and the unchanged guard do not prove absence of all unobserved short-lived processes.
- Receipt/log hashes bind the exact preserved evidence. They do not provide an independent OS/kernel or cryptographic-attestation trust root.
- The network-denial statement is grounded in the reviewed child-only libseccomp guard and its run receipt, not an independent network-traffic measurement.
- Documentation or publication packaging may be added later; source/config/assets and compiled outputs verified here must remain bound to the frozen input/output inventories.

No compilation or checker execution was performed by this reviewer.
