## Relevant Files

- `tasks/prd-insight-engine-layer-3-insight-generation.md` - Source PRD for Layer 3 insight generation scope and requirements.
- `lib/features/analytics/domain/models/detected_pattern.dart` - Layer 2 input contract consumed by Layer 3.
- `lib/features/analytics/application/pattern_detection_providers.dart` - Upstream Layer 2 providers for per-entity and global/day patterns.
- `lib/features/analytics/application/` - Home for Layer 3 mapping engine, merge/ranking logic, and orchestration.
- `lib/features/analytics/domain/models/` - Place for new Layer 3 domain contracts (`GeneratedInsight`, enums, metadata).
- `lib/features/analytics/data/` - Repository adapter for Layer 3 persistence and reads.
- `lib/core/local_db/isar_collections/` - Dedicated Isar entities/schemas for Layer 3 insight storage.
- `lib/core/di/providers.dart` - Dependency wiring for Layer 3 repositories/services/providers.
- `lib/features/home/presentation/home_screen.dart` - V1 insight surface target (Home only).
- `test/features/analytics/` - Unit/integration coverage for deterministic mapping, merge, ranking, persistence, and providers.
- `test/support/` - Shared fixtures and no-op repositories for deterministic test setup.

### Notes

- Layer 3 must consume Layer 2 outputs and small approved context only (no raw event/task/goal interpretation).
- V1 insight taxonomy includes 3 buckets: `risk`, `neutral`, `reinforcement`.
- Output contract must include both `messageKey` and deterministic fallback `message`.
- Output caps must be enforced: max 1-3 per entity, max 3 global/day.
- Layer 3 must remain deterministic and must not call AI.
- V1 UI integration target is Home only (Progress remains out of scope).

## Tasks

- [x] 1.0 Define Layer 3 contracts and schema versioning
  - [x] 1.1 Define `GeneratedInsight` model with required metadata (`insightId`, scope fields, type, bucket, priority, message fields, action, linked patterns, confidence, window keys, schema version).
  - [x] 1.2 Define Layer 3 enums/constants for `insightBucket`, `insightType`, `priority`, and `action`.
  - [x] 1.3 Add Layer 3 schema version constants and compatibility parsing defaults.
  - [x] 1.4 Add deterministic validation/clamping for confidence and required fields.

- [x] 2.0 Implement centralized mapping and policy config
  - [x] 2.1 Create one centralized config for V1 insight mappings (no scattered magic values).
  - [x] 2.2 Define deterministic mapping rules from pattern code combinations to insight types.
  - [x] 2.3 Define deterministic priority policy (high/medium/low) and tie-break strategy.
  - [x] 2.4 Define output cap policy per scope (entity/global) with strict V1 limits.
  - [x] 2.5 Define merge/deduplicate policy for related overlapping pattern signals.

- [x] 3.0 Implement deterministic insight mapping engine
  - [x] 3.1 Add Risk insight mappings (`streak_risk_warning`, `habit_too_hard`, `timing_misalignment`, `goal_at_risk`).
  - [x] 3.2 Add Neutral insight mappings (`late_pattern`, `inconsistency_notice`, `low_engagement_notice`).
  - [x] 3.3 Add Reinforcement insight mappings (`strong_streak_praise`, `consistent_behavior_praise`, `goal_progress_success`).
  - [x] 3.4 Ensure mapping rules can combine multi-pattern inputs into one higher-meaning insight when configured.
  - [x] 3.5 Ensure every emitted insight is fully formed with message key, fallback message, action, and confidence.

- [x] 4.0 Build merge, rank, and cap pipeline
  - [x] 4.1 Implement deterministic merge/dedupe across same-scope overlapping insights.
  - [x] 4.2 Implement deterministic sorting by priority and stable tie-break keys.
  - [x] 4.3 Enforce entity-scope cap (1-3 max) and global/day cap (3 max).
  - [x] 4.4 Add diagnostics for merged, suppressed, and capped-out insights.

- [x] 5.0 Build per-entity and global/day insight orchestration
  - [x] 5.1 Build per-entity entrypoint that consumes Layer 2 entity patterns and context subset.
  - [x] 5.2 Build global/day entrypoint that consumes Layer 2 global/day patterns and context subset.
  - [x] 5.3 Implement safe handling for malformed/sparse upstream payloads without full-run crashes.
  - [x] 5.4 Add batch run result metadata (processed count, emitted count, elapsed, schema version).

- [x] 6.0 Implement dedicated Isar persistence for Layer 3 outputs
  - [x] 6.1 Add dedicated Isar collection(s) for stored generated insights.
  - [x] 6.2 Register Layer 3 Isar schemas in central schema registry.
  - [x] 6.3 Implement Layer 3 repository for upsert/read by entity scope and global/day scope.
  - [x] 6.4 Add migration-safe read behavior for schema-version mismatches.

- [x] 7.0 Expose Layer 3 providers/APIs
  - [x] 7.1 Add provider/API for per-entity insights.
  - [x] 7.2 Add provider/API for global/day insights.
  - [x] 7.3 Add provider/API for run metadata (last run, counts, schema version).
  - [x] 7.4 Ensure provider updates are reactive to Layer 2 reruns and Layer 3 recompute.

- [x] 8.0 Integrate Layer 3 into Home surface (V1 only)
  - [x] 8.1 Add Home-facing provider(s) that read top prioritized Layer 3 insight(s).
  - [x] 8.2 Wire Home UI to display insight text/action from Layer 3 contract.
  - [x] 8.3 Ensure deterministic fallback behavior when no insights are available.
  - [x] 8.4 Keep Progress and other surfaces untouched for this PRD scope.

- [x] 9.0 Testing and deterministic validation
  - [x] 9.1 Unit tests for all V1 mapping rules (trigger + non-trigger + boundary conditions).
  - [x] 9.2 Unit tests for merge/dedupe policy and deterministic stable ordering.
  - [x] 9.3 Unit tests for caps and priority tie-break behavior.
  - [x] 9.4 Integration tests for per-entity and global/day outputs from shared fixtures.
  - [x] 9.5 Persistence tests for dedicated Isar upsert/read/version compatibility.
  - [x] 9.6 Provider/orchestration tests for update propagation from Layer 2 to Layer 3 to Home providers.
  - [x] 9.7 Run `flutter analyze` and resolve newly introduced diagnostics.
  - [x] 9.8 Run focused Layer 3 tests, then full `flutter test`.

- [x] 10.0 Manual QA and acceptance gates
  - [x] 10.1 Verify same input set produces identical insight outputs across repeated runs.
  - [x] 10.2 Verify all V1 risk/neutral/reinforcement insight types emit correctly in realistic scenarios.
  - [x] 10.3 Verify merge/dedupe reduces redundant insight spam while preserving highest-value insight.
  - [x] 10.4 Verify Home shows correct top-priority Layer 3 insight and action hint.
  - [x] 10.5 Verify no regressions in existing analytics and Layer 2 surfaces after Layer 3 wiring.
