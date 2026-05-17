## Relevant Files

- `tasks/prd-insight-engine-layer-1-feature-builder.md` - Source PRD for Layer 1 scope and acceptance criteria.
- `lib/features/analytics/domain/models/` - Existing analytics model patterns to follow for new feature object contract.
- `lib/features/analytics/application/` - Home for feature computation services, aggregators, and providers.
- `lib/features/analytics/data/` - Repository and persistence adapters for Isar-backed storage.
- `lib/core/local_db/isar_collections/` - Isar entities/schemas and generated adapters.
- `lib/features/planning/application/planned_task_providers.dart` - Task streams and day-scoped task sources.
- `lib/features/goals/application/goals_providers.dart` - Goal/habit streams and check-in access points.
- `lib/features/analytics/application/daily_analytics_providers.dart` - Existing daily rollup patterns that Layer 1 should integrate with safely.
- `lib/features/timer/presentation/timer_session_screen.dart` - Session events that feed effort metrics.
- `lib/features/goals/presentation/goal_detail_screen.dart` - Habit/goal completion event sources.
- `test/features/analytics/` - Unit and provider test home for deterministic metric validation.
- `test/core/` - Shared test utilities and potential date/time fixture helpers.

### Notes

- Layer 1 must stay deterministic and numeric-only; no insight generation/ranking/text.
- V1 cache target is Isar only.
- Recompute strategy is hybrid: on-event touched entity + daily full refresh batch.
- Include all scoped entities: tasks, habit-anchor tasks, goals/habits, goal entities, non-habit goals.
- Keep schema versioned for safe future upgrades in Layers 2-5.

## Tasks

- [x] 1.0 Define Layer 1 feature contract and schema versioning
  - [x] 1.1 Define canonical `BehaviorFeatureObject` structure with all required sections (`timeMetrics`, `streakMetrics`, `effortMetrics`, `goalMetrics`, `contextFeatures`).
  - [x] 1.2 Define `entityKind` mapping rules (`task | habit | goal`) across existing models.
  - [x] 1.3 Add feature schema/version constant and compatibility read strategy.
  - [x] 1.4 Add null-safe defaults policy for sparse data cases.

- [x] 2.0 Implement input adapters for all required data sources
  - [x] 2.1 Build event adapter to collect entity-scoped event history (7d/30d windows + needed historical streak range).
  - [x] 2.2 Build task adapter for priority, schedule, status, planned duration, habit-anchor context.
  - [x] 2.3 Build goal/habit adapter for targets, expected progress, check-ins, and milestone progress.
  - [x] 2.4 Build analytics-cache adapter (read-only helper) for any reusable precomputed values.
  - [x] 2.5 Normalize all timestamps/date keys under one canonical timezone/day-boundary utility.

- [x] 3.0 Implement core metric calculators (deterministic pure functions)
  - [x] 3.1 Implement completion metrics: `completionRate7d`, `completionRate30d`.
  - [x] 3.2 Implement lateness metrics: `lateRate`, `avgDelayMinutes` (with explicit late rule).
  - [x] 3.3 Implement streak metrics: `currentStreak`, `longestStreak`, `missedLast2Days`, `missedCount7d`.
  - [x] 3.4 Implement effort metrics: `avgSnoozeCount`, `avgSessionDuration`, `plannedVsActualRatio`.
  - [x] 3.5 Implement goal metrics: `progress`, `expectedProgress`, `gap`.
  - [x] 3.6 Implement context metrics: `bestTimeBlock`, `isHabitAnchor`, `priority`.

- [x] 4.0 Build entity-level feature assembly pipeline
  - [x] 4.1 Create per-entity assembler that composes all calculators into one `BehaviorFeatureObject`.
  - [x] 4.2 Ensure assembler is deterministic for unchanged input sets.
  - [x] 4.3 Add scoped builders for each entity category (task, habit, goal).
  - [x] 4.4 Add validation guardrails for invalid/missing IDs and malformed timestamps.

- [x] 5.0 Implement batch compute orchestrator
  - [x] 5.1 Build user-level batch runner that computes features for all in-scope entities in one pass.
  - [x] 5.2 Add date-window metadata and compute timestamp to each output.
  - [x] 5.3 Optimize lookup strategy to avoid repeated per-entity source queries inside same batch.
  - [x] 5.4 Add lightweight compute telemetry (count, elapsed, failures) for debug visibility.

- [x] 6.0 Add Isar persistence for Layer 1 feature cache
  - [x] 6.1 Create Isar collection/entity for `BehaviorFeatureObject` cache records.
  - [x] 6.2 Add repository methods: upsert single, bulk upsert, fetch by entity, fetch by kind, fetch all.
  - [x] 6.3 Persist schema version + compute metadata with each record.
  - [x] 6.4 Add migration-safe behavior for schema version mismatch reads.

- [x] 7.0 Implement hybrid recompute strategy
  - [x] 7.1 Wire event-driven recompute for touched entities after relevant behavior mutations.
  - [x] 7.2 Implement daily full-refresh job to recompute all entities.
  - [x] 7.3 Add idempotent scheduling/debounce guardrails to prevent recompute storms.
  - [x] 7.4 Ensure recompute failures degrade safely without blocking user flows.

- [x] 8.0 Expose read APIs/providers for downstream layers
  - [x] 8.1 Add provider/API to fetch single entity feature object.
  - [x] 8.2 Add provider/API to fetch scoped lists by `entityKind` and date window.
  - [x] 8.3 Add provider/API to expose compute metadata (`lastComputedAt`, version).
  - [x] 8.4 Ensure provider invalidation/update behavior is correct for touched-entity recompute paths.

- [x] 9.0 Testing and deterministic validation
  - [x] 9.1 Unit tests for each metric calculator with normal and edge cases.
  - [x] 9.2 Unit tests for day-boundary/timezone behavior (including DST-sensitive scenarios).
  - [x] 9.3 Unit tests for sparse/empty histories and default handling.
  - [x] 9.4 Unit tests for batch orchestrator determinism (same input -> same output).
  - [x] 9.5 Persistence tests for Isar upsert/read/version handling.
  - [x] 9.6 Provider tests for event-triggered recompute and daily refresh paths.
  - [x] 9.7 Run `flutter analyze` and resolve newly introduced diagnostics.
  - [x] 9.8 Run focused analytics tests, then full `flutter test`.

- [ ] 10.0 Manual QA and acceptance gates
  - [ ] 10.1 Verify feature cache updates immediately after task complete/defer/session events.
  - [ ] 10.2 Verify goal/habit check-ins recompute only affected entities plus daily batch correctness.
  - [ ] 10.3 Verify all required fields are populated for each in-scope entity class.
  - [ ] 10.4 Verify latency targets (touched entity median <200ms, full batch <2s on typical emulator dataset).
  - [ ] 10.5 Verify no regressions in existing Home/Progress analytics surfaces after Layer 1 integration.
