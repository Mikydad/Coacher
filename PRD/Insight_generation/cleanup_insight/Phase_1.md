PHASE 1 TASK — FINALIZE CANONICAL METRICS

Goal:
Stabilize Layer 1 feature computation so all downstream layers operate on deterministic behavioral truth.

Requirements:

1. Audit all BehaviorFeatureObject metrics:
- streak metrics
- completion rates
- lateness
- overdue counts
- effort metrics
- goal progress metrics

2. Ensure:
- same input always produces same output
- timezone handling is deterministic
- rolling windows are consistent
- partial completion rules are explicit
- missing/null events do not corrupt calculations

3. Add metric definition documentation:
For every computed metric define:
- formula
- source events
- window scope
- edge cases

4. Add unit tests:
- repeated runs parity
- timezone boundary tests
- streak continuity tests
- overdue logic tests
- partial completion tests

5. Add schema version validation:
BehaviorFeatureObject.schemaVersion must be validated during reads/writes.