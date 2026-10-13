# Transfer-stage attempts

Failed runs are preserved below with source pins, logs, and resource records. Later passes do not erase these attempts. Elaboration, API, and heartbeat failures are compiler failures rather than mathematical certificates. Earlier baseline and real-closure failures remain in their existing published reports.

- [transfer-bkr01-run01](transfer-runs/transfer-bkr01-run01/summary.json): TauCeti.Data.SignType.Lagrange: COMPILE_FAILED
- [transfer-bkr02-run01](transfer-runs/transfer-bkr02-run01/summary.json): TauCeti.Data.SignType.Lagrange: COMPILE_FAILED
- [transfer-bkr03-run01](transfer-runs/transfer-bkr03-run01/summary.json): TauCeti.Data.SignType.Lagrange: COMPILE_FAILED
- [transfer-candidates01-run01](transfer-runs/transfer-candidates01-run01/summary.json): UniformRootCount: COMPILE_FAILED
- [transfer-candidates02-run01](transfer-runs/transfer-candidates02-run01/summary.json): MonicQueryProjection: COMPILE_FAILED
- [transfer-candidates03-run01](transfer-runs/transfer-candidates03-run01/summary.json): UniformOneVariable: COMPILE_FAILED
- [transfer-candidates04-run01](transfer-runs/transfer-candidates04-run01/summary.json): UniformOneVariable: COMPILE_FAILED
- [transfer-candidates05-run01](transfer-runs/transfer-candidates05-run01/summary.json): UniformOneVariable: COMPILE_FAILED
- [transfer-candidates06-run01](transfer-runs/transfer-candidates06-run01/summary.json): FiniteVariableTransfer: COMPILE_FAILED
- [transfer-compat01-run01](transfer-runs/transfer-compat01-run01/summary.json): TauCeti.Compat.ListSignVariations: COMPILE_FAILED
- [transfer-compat02-run01](transfer-runs/transfer-compat02-run01/summary.json): TauCeti.Compat.SturmSequence: COMPILE_FAILED
- [transfer-helpers01-run01](transfer-runs/transfer-helpers01-run01/summary.json): CoefficientSignPattern: COMPILE_FAILED
- [transfer-helpers02-run01](transfer-runs/transfer-helpers02-run01/summary.json): DegreeNormalization: COMPILE_FAILED
- [transfer-rcf-ivt01-run01](transfer-runs/transfer-rcf-ivt01-run01/summary.json): TauCeti.FieldTheory.RealClosure.AlgebraicClosed: COMPILE_FAILED
- [transfer-rcf-ivt02-run01](transfer-runs/transfer-rcf-ivt02-run01/summary.json): TauCeti.Algebra.Polynomial.LinearFactor: COMPILE_FAILED
- [transfer-rcf-ivt03-run01](transfer-runs/transfer-rcf-ivt03-run01/summary.json): TauCeti.Algebra.QuadraticDiscriminant: COMPILE_FAILED
- [transfer-sturm-cauchy02-run01](transfer-runs/transfer-sturm-cauchy02-run01/summary.json): TauCeti.Algebra.Polynomial.Sturm.CauchyIndex.Basic: COMPILE_FAILED
- [transfer-subresultant01-run01](transfer-runs/transfer-subresultant01-run01/summary.json): TauCeti.RingTheory.Polynomial.Subresultant.Basic: COMPILE_FAILED

The terminal run index also includes the successful final contracts and all 97 selected local kernel replays. Candidates04/05 stopped on elaboration heartbeat limits; their repair changed proof elaboration without raising the heartbeat limit.
