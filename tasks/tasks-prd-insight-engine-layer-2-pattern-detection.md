## Relevant Files

- `tasks/prd-insight-engine-layer-2-pattern-detection.md` - Source PRD for Layer 2 pattern detection scope and requirements.
- `lib/features/analytics/domain/models/behavior_feature_object.dart` - Layer 1 input contract consumed by Layer 2.
- `lib/features/analytics/application/feature_cache_providers.dart` - Upstream feature-cache providers for entity and scoped reads.
- `lib/features/analytics/application/feature_builder_orchestrator.dart` - Existing Layer 1 orchestration patterns for deterministic batch flow.
- `lib/features/analytics/application/` - Home for Layer 2 rule engine, scoring logic, and aggregate builders.
- `lib/features/analytics/domain/models/` - Place for new Layer 2 domain contracts (`DetectedPattern`, aggregate snapshot, enums).
- `lib/features/analytics/data/` - Optional persistence adapters if Layer 2 pattern caching is enabled.
- `lib/core/local_db/isar_collections/` - Isar entities/schemas if Layer 2 outputs are persisted locally.
- `lib/core/di/providers.dart` - Dependency wiring for repositories/services/providers.
- `test/features/analytics/` - Unit/integration test coverage for deterministic rules and scoring behavior.
- `test/support/` - Shared fixtures and no-op repositories for predictable test setup.

### Notes

- Layer 2 must consume Layer 1 outputs only (no raw task/goal/event interpretation in rule logic).
- V1 scope includes only 3 pattern groups: Streak & Consistency, Time Behavior, Effort & Difficulty.
- Outputs must be emitted at 2 levels: per entity + one global/day aggregate snapshot.
- Severity/confidence must use hybrid scoring (base table + formula adjustments), clamped to `[0.0, 1.0]`.
- Layer 2 must remain deterministic and must not generate advice text, ranking, or AI calls.

## Tasks

- [x] 1.0 Define Layer 2 contracts and schema versioning
  - [x] 1.1 Define `DetectedPattern` model with required metadata (`entityId`, `entityKind`, `patternCode`, `patternGroup`, `severity`, `confidence`, `detectedAtMs`, source window keys, schema version).
  - [x] 1.2 Define `GlobalPatternSnapshot` model for day-level aggregate outputs (date key, entries, counts, weighted stats, schema version).
  - [x] 1.3 Define pattern enums/constants for V1 scope groups and codes (streak/consistency, time behavior, effort/difficulty).
  - [x] 1.4 Add schema version constants + compatibility parsing defaults for future Layer 2 upgrades.

- [x] 2.0 Implement rule threshold config and deterministic scoring primitives
  - [x] 2.1 Create centralized threshold/config object for all Layer 2 rules (no scattered magic numbers).
  - [x] 2.2 Implement base severity lookup table per pattern code.
  - [x] 2.3 Implement formula-based severity adjustment by threshold distance and signal strength.
  - [x] 2.4 Implement confidence computation from completeness, sample size quality, and signal margin.
  - [x] 2.5 Add utility clamps and normalization helpers for scoring outputs.

- [x] 3.0 Implement deterministic rule engine for selected V1 pattern groups
  - [x] 3.1 Add Streak & Consistency rules: `streak_risk`, `strong_streak`, `inconsistent_behavior`.
  - [x] 3.2 Add Time Behavior rules: `late_behavior`, `time_misalignment`.
  - [x] 3.3 Add Effort & Difficulty rules: `too_hard`, `low_engagement`.
  - [x] 3.4 Ensure each rule emits fully-formed `DetectedPattern` with hybrid severity/confidence.
  - [x] 3.5 Add deterministic tie/merge policy for same-entity multi-rule emissions.

- [x] 4.0 Build per-entity pattern detection pipeline
  - [x] 4.1 Build engine entrypoint that accepts `BehaviorFeatureObject` and returns entity pattern list.
  - [x] 4.2 Handle malformed/sparse feature input safely without crashing the full run.
  - [x] 4.3 Add deterministic ordering of emitted patterns (stable output ordering for same inputs).
  - [x] 4.4 Include evaluation diagnostics for failed/skipped rules per entity.

- [x] 5.0 Build global/day aggregate pattern snapshot pipeline
  - [x] 5.1 Aggregate all emitted entity patterns into one `GlobalPatternSnapshot` per run/day.
  - [x] 5.2 Compute aggregate counters (pattern frequency, group-level counts, weighted severity summaries).
  - [x] 5.3 Define deterministic aggregation semantics (how duplicates/repeats are merged).
  - [x] 5.4 Include run metadata (entity count, emitted count, elapsed, schema version).

- [x] 6.0 Implement Layer 2 orchestration and optional local persistence
  - [x] 6.1 Build Layer 2 orchestrator that reads scoped Layer 1 features and executes detection in batch.
  - [x] 6.2 Add event-triggered and daily-refresh integration points aligned with Layer 1 recompute flow.
  - [x] 6.3 If enabled, add Isar persistence models/repository for `DetectedPattern` and `GlobalPatternSnapshot`.
  - [x] 6.4 Add migration-safe read behavior for future schema mismatches.

- [x] 7.0 Expose read APIs/providers for downstream layers
  - [x] 7.1 Add provider/API to fetch per-entity patterns by entity ID and kind.
  - [x] 7.2 Add provider/API to fetch global/day aggregate snapshot.
  - [x] 7.3 Add provider/API for run metadata (last run time, schema version, processed entities, emitted patterns).
  - [x] 7.4 Ensure provider updates are reactive to Layer 1 feature updates and Layer 2 reruns.

- [x] 8.0 Add telemetry and reliability guardrails
  - [x] 8.1 Add structured telemetry for processed entities, emitted patterns, rule exceptions, and elapsed time.
  - [x] 8.2 Add failure isolation so one entity/rule failure does not break full detection batch.
  - [x] 8.3 Add debounce/idempotency protections to avoid duplicate reruns for unchanged inputs.
  - [x] 8.4 Add debug hooks/log views for validating rule decisions during development.

- [x] 9.0 Testing and deterministic validation
  - [x] 9.1 Unit tests for all V1 rules (trigger + non-trigger + boundary conditions).
  - [x] 9.2 Unit tests for hybrid severity/confidence calculations and clamping.
  - [x] 9.3 Unit tests for tie/merge behavior and deterministic stable ordering.
  - [x] 9.4 Integration tests for per-entity and global/day outputs from shared input fixtures.
  - [x] 9.5 Persistence tests (if enabled) for upsert/read/version compatibility.
  - [x] 9.6 Provider/orchestration tests for update propagation after Layer 1 changes.
  - [x] 9.7 Run `flutter analyze` and resolve newly introduced diagnostics.
  - [x] 9.8 Run focused Layer 2 tests, then full `flutter test`.

- [x] 10.0 Manual QA and acceptance gates
  - [x] 10.1 Verify same input set produces identical pattern outputs across repeated runs.
  - [x] 10.2 Verify all selected V1 pattern groups emit expected patterns in realistic scenarios.
  - [x] 10.3 Verify global/day aggregate matches per-entity emissions (counts + weighted summaries).
  - [x] 10.4 Verify performance remains within acceptable local-first budget on emulator test dataset.
  - [x] 10.5 Verify no regressions in existing analytics surfaces after Layer 2 integration wiring.
