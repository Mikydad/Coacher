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

- [ ] 1.0 Define Layer 1 feature contract and schema versioning
  - [ ] 1.1 Define canonical `BehaviorFeatureObject` structure with all required sections (`timeMetrics`, `streakMetrics`, `effortMetrics`, `goalMetrics`, `contextFeatures`).
  - [ ] 1.2 Define `entityKind` mapping rules (`task | habit | goal`) across existing models.
  - [ ] 1.3 Add feature schema/version constant and compatibility read strategy.
  - [ ] 1.4 Add null-safe defaults policy for sparse data cases.

- [ ] 2.0 Implement input adapters for all required data sources
  - [ ] 2.1 Build event adapter to collect entity-scoped event history (7d/30d windows + needed historical streak range).
  - [ ] 2.2 Build task adapter for priority, schedule, status, planned duration, habit-anchor context.
  - [ ] 2.3 Build goal/habit adapter for targets, expected progress, check-ins, and milestone progress.
  - [ ] 2.4 Build analytics-cache adapter (read-only helper) for any reusable precomputed values.
  - [ ] 2.5 Normalize all timestamps/date keys under one canonical timezone/day-boundary utility.

- [ ] 3.0 Implement core metric calculators (deterministic pure functions)
  - [ ] 3.1 Implement completion metrics: `completionRate7d`, `completionRate30d`.
  - [ ] 3.2 Implement lateness metrics: `lateRate`, `avgDelayMinutes` (with explicit late rule).
  - [ ] 3.3 Implement streak metrics: `currentStreak`, `longestStreak`, `missedLast2Days`, `missedCount7d`.
  - [ ] 3.4 Implement effort metrics: `avgSnoozeCount`, `avgSessionDuration`, `plannedVsActualRatio`.
  - [ ] 3.5 Implement goal metrics: `progress`, `expectedProgress`, `gap`.
  - [ ] 3.6 Implement context metrics: `bestTimeBlock`, `isHabitAnchor`, `priority`.

- [ ] 4.0 Build entity-level feature assembly pipeline
  - [ ] 4.1 Create per-entity assembler that composes all calculators into one `BehaviorFeatureObject`.
  - [ ] 4.2 Ensure assembler is deterministic for unchanged input sets.
  - [ ] 4.3 Add scoped builders for each entity category (task, habit, goal).
  - [ ] 4.4 Add validation guardrails for invalid/missing IDs and malformed timestamps.

- [ ] 5.0 Implement batch compute orchestrator
  - [ ] 5.1 Build user-level batch runner that computes features for all in-scope entities in one pass.
  - [ ] 5.2 Add date-window metadata and compute timestamp to each output.
  - [ ] 5.3 Optimize lookup strategy to avoid repeated per-entity source queries inside same batch.
  - [ ] 5.4 Add lightweight compute telemetry (count, elapsed, failures) for debug visibility.

- [ ] 6.0 Add Isar persistence for Layer 1 feature cache
  - [ ] 6.1 Create Isar collection/entity for `BehaviorFeatureObject` cache records.
  - [ ] 6.2 Add repository methods: upsert single, bulk upsert, fetch by entity, fetch by kind, fetch all.
  - [ ] 6.3 Persist schema version + compute metadata with each record.
  - [ ] 6.4 Add migration-safe behavior for schema version mismatch reads.

- [ ] 7.0 Implement hybrid recompute strategy
  - [ ] 7.1 Wire event-driven recompute for touched entities after relevant behavior mutations.
  - [ ] 7.2 Implement daily full-refresh job to recompute all entities.
  - [ ] 7.3 Add idempotent scheduling/debounce guardrails to prevent recompute storms.
  - [ ] 7.4 Ensure recompute failures degrade safely without blocking user flows.

- [ ] 8.0 Expose read APIs/providers for downstream layers
  - [ ] 8.1 Add provider/API to fetch single entity feature object.
  - [ ] 8.2 Add provider/API to fetch scoped lists by `entityKind` and date window.
  - [ ] 8.3 Add provider/API to expose compute metadata (`lastComputedAt`, version).
  - [ ] 8.4 Ensure provider invalidation/update behavior is correct for touched-entity recompute paths.

- [ ] 9.0 Testing and deterministic validation
  - [ ] 9.1 Unit tests for each metric calculator with normal and edge cases.
  - [ ] 9.2 Unit tests for day-boundary/timezone behavior (including DST-sensitive scenarios).
  - [ ] 9.3 Unit tests for sparse/empty histories and default handling.
  - [ ] 9.4 Unit tests for batch orchestrator determinism (same input -> same output).
  - [ ] 9.5 Persistence tests for Isar upsert/read/version handling.
  - [ ] 9.6 Provider tests for event-triggered recompute and daily refresh paths.
  - [ ] 9.7 Run `flutter analyze` and resolve newly introduced diagnostics.
  - [ ] 9.8 Run focused analytics tests, then full `flutter test`.

- [ ] 10.0 Manual QA and acceptance gates
  - [ ] 10.1 Verify feature cache updates immediately after task complete/defer/session events.
  - [ ] 10.2 Verify goal/habit check-ins recompute only affected entities plus daily batch correctness.
  - [ ] 10.3 Verify all required fields are populated for each in-scope entity class.
  - [ ] 10.4 Verify latency targets (touched entity median <200ms, full batch <2s on typical emulator dataset).
  - [ ] 10.5 Verify no regressions in existing Home/Progress analytics surfaces after Layer 1 integration.
