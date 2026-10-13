# Preserved failed attempts

These attempts were superseded where stated; their original diagnostics remain available. A failed earlier source snapshot is not represented as checked by a later success.

1. [runtime-compile02-run01](runtime-compile02-run01/summary.json): the incomplete overlay prevented Mathlib namespace lookup. Resolved by populating the isolated overlay; the next run compiled all twelve selected official prerequisites.
2. [runtime-compile02-run02](runtime-compile02-run02/summary.json): all twelve official modules passed; the import smoke hit Lean's 2,048 MiB internal memory cap. The next compiler configuration used 4,096 MiB while retaining the physical-memory guard.
3. [proof-compile03-run01](proof-compile03-run01/summary.json): the smoke source referred to nonexistent `RingOrdering`. Replaced with the actual `RingPreordering.IsOrdering` API in the subsequent successful smoke.
4. [proof-compile04-run01](proof-compile04-run01/summary.json): `TargetSpec` and `ClearDenominators` passed; `FractionSemireal` lacked an infinite-field instance import and explicit type arguments. Its corrected source passed in [proof-compile06-run01](proof-compile06-run01/summary.json).
5. [proof-compile05-run01](proof-compile05-run01/summary.json): `OrderingSeparation` and `RealInstance` passed; `CoefficientOrder` lacked the import exporting ring-hom injectivity. The corrected source passed in [proof-compile07-run01](proof-compile07-run01/summary.json).
6. [proof-compile07-run01](proof-compile07-run01/summary.json): `CoefficientOrder` and `LocalizationSignDescent` passed; a simplification did not close the generic polynomial evaluation identity in `ConditionalArtin`. An explicit calculation replaced that step and passed in [proof-compile08-run01](proof-compile08-run01/summary.json).
7. [delivery-entry01-run01](delivery-entry01-run01/summary.json): the newly packaged import entry point had a module-doc command before its imports. The header was corrected to an ordinary comment; the entry point then passed in [delivery-entry02-run01](delivery-entry02-run01/summary.json).

Each linked run directory contains the exported stdout/stderr diagnostics, including empty logs where applicable. No failed attempt was discarded to present a clean build history.
