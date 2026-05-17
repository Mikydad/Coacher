# PRD: Insight Engine Layer 2 - Pattern Detection Engine

## 1) Introduction/Overview

This PRD defines Layer 2 of the AI Coach Insight Engine: the **Pattern Detection Engine**.

Layer 2 consumes Layer 1 `BehaviorFeatureObject` records and transforms them into deterministic behavior pattern outputs with `severity` and `confidence` scores.

This layer answers **"What behavior pattern is happening?"** and does not generate advice, user-facing coaching text, ranking, or AI output.

The core problem this solves is separating interpretation logic from raw analytics and messaging so the system remains predictable, testable, and safe to scale into Layers 3-5.

## 2) Goals

- Detect deterministic behavior patterns from feature objects for the selected V1 groups:
  - Streak & Consistency
  - Time Behavior
  - Effort & Difficulty
- Emit pattern results at two levels:
  - per entity (`task | habit | goal`)
  - global/day aggregate summary (cross-entity)
- Attach both `severity` and `confidence` to each emitted pattern.
- Use a **hybrid scoring model**:
  - base deterministic pattern weights (table)
  - formula adjustments based on signal distance/strength.
- Ensure deterministic same-input/same-output behavior.
- Keep implementation highly unit-testable and performant.

## 3) User Stories

- As a user, I want behavior detection to be consistent so coaching feels trustworthy.
- As a user, I want weak and strong behavior signals captured with clear strength levels.
- As a developer, I want pattern logic isolated from insight text so changes are safer and easier to test.
- As a developer, I want per-entity and global outputs so downstream layers can choose the best scope for insight generation.
- As a product owner, I want a deterministic engine that can support ranking and AI explanation in later layers without changing core behavior detection rules.

## 4) Functional Requirements

1. The system must accept Layer 1 `BehaviorFeatureObject` as the only input contract for Layer 2.

2. The system must define a canonical `DetectedPattern` output schema with at least:
   - `entityId`
   - `entityKind`
   - `patternCode`
   - `patternGroup`
   - `severity` (0.0-1.0)
   - `confidence` (0.0-1.0)
   - `detectedAtMs`
   - `sourceWindowStartDateKey`
   - `sourceWindowEndDateKey`
   - `schemaVersion`

3. The system must define a canonical `GlobalPatternSnapshot` output schema for day/global aggregate output with:
   - `dateKey`
   - list of rolled-up pattern entries
   - aggregate counts and weighted severities
   - `schemaVersion`

4. The engine must implement deterministic rules for **Streak & Consistency** patterns:
   - `streak_risk`
   - `strong_streak`
   - `inconsistent_behavior`

5. The engine must implement deterministic rules for **Time Behavior** patterns:
   - `late_behavior`
   - `time_misalignment`

6. The engine must implement deterministic rules for **Effort & Difficulty** patterns:
   - `too_hard`
   - `low_engagement`

7. The engine must support rule thresholds and constants via one centralized, versioned config (no scattered magic numbers).

8. The engine must emit per-entity patterns for each eligible entity with complete metadata.

9. The engine must emit one global/day aggregate pattern snapshot from all per-entity outputs in the same run.

10. The system must compute severity using a hybrid model:
    - base pattern severity from deterministic table
    - bounded formula adjustments from distance-to-threshold and signal strength.

11. The system must compute confidence using a hybrid model that considers:
    - data completeness/sparsity
    - sample-window strength (7d vs 30d availability)
    - signal clarity (margin from threshold).

12. The system must clamp all `severity` and `confidence` values to `[0.0, 1.0]`.

13. The system must include deterministic tie/merge behavior when multiple rules in the same group trigger for the same entity (e.g., keep all, or explicit dedupe policy).

14. The system must expose read APIs/providers for:
    - per-entity detected patterns
    - global/day pattern snapshot
    - run metadata (timestamp, schema version, entity count)

15. The engine must be idempotent for unchanged feature inputs (same outputs across reruns).

16. The engine must include structured logs/telemetry for:
    - entities processed
    - patterns emitted
    - elapsed time
    - rule evaluation errors.

17. The system must fail safely:
    - invalid/missing feature fields should not crash full batch
    - entity-level failures are isolated and reported.

## 5) Non-Goals (Out of Scope)

- Generating user-facing coaching messages.
- Ranking/prioritizing insights across patterns for UI display order.
- Calling AI/LLM services.
- Implementing Goal Alignment and Behavior Stability pattern groups in this V1 scope.
- Building final recommendation actions (Layer 3+ concern).

## 6) Design Considerations

- No mandatory new user-facing UI in Layer 2.
- Prefer developer-inspectable structured output (JSON-like model objects).
- Keep naming human-readable and stable (`patternCode` constants).
- Keep schemas aligned with Layer 1 and ready for Layer 3 consumption.

## 7) Technical Considerations

- Reuse existing Layer 1 feature cache and providers as upstream source.
- Keep rule engine deterministic and pure where possible.
- Centralize thresholds and scoring constants for easy tuning and safer migrations.
- Add schema versioning for detected patterns and global snapshots.
- Ensure compatibility with local-first Isar architecture.
- Optimize for batch processing to avoid repeated expensive scans.

## 8) Success Metrics

1. Determinism:
   - 100% parity for same-input repeated runs in test scenarios.

2. Coverage:
   - All selected V1 pattern groups and codes emit correctly when trigger conditions are met.

3. Testability:
   - Unit tests for every rule trigger/non-trigger boundary.
   - Unit tests for severity/confidence clamping and hybrid adjustments.
   - Integration tests for per-entity + global output consistency.

4. Performance:
   - Pattern detection batch run overhead remains low enough for local-first flow (target to be validated during QA, e.g., under 2s on typical dataset).

5. Reliability:
   - Entity-level malformed data does not fail whole run.
   - No regression in existing analytics surfaces after Layer 2 integration paths are added.

## 9) Open Questions

- Should `strong_streak` and `inconsistent_behavior` be allowed simultaneously for different windows on the same entity, or should one suppress the other?
- For `time_misalignment`, what exact source-of-truth defines `scheduledTimeBlock` for goals with no explicit reminder time?
- Should global/day aggregate include top-N strongest patterns only or all detected patterns?
- Should pattern persistence be introduced immediately in Layer 2, or returned as computed output only in first rollout?
