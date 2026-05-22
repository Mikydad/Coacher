## Relevant Files

- `tasks/prd-phase-a-time-block-foundation.md` — Source PRD for Phase A scope and requirements.
- `lib/features/time_blocks/domain/models/scheduled_time_block.dart` — New domain model: `ScheduledTimeBlock`, `FlexibilityType`, `AvailableTimeWindow`.
- `lib/features/time_blocks/domain/models/time_conflict.dart` — New domain models: `TimeConflict`, `ConflictCheckResult`, `ConflictSeverity`, `ConflictType`.
- `lib/features/time_blocks/application/conflict_detection_engine.dart` — Pure Dart engine: `ConflictDetectionEngine.detect()`, severity formula, threshold logic.
- `lib/features/time_blocks/application/time_block_sync_service.dart` — Service: derives `ScheduledTimeBlock` from task/habit, calls repository, runs conflict check.
- `lib/features/time_blocks/application/reclaimed_time_service.dart` — Service: detects early completion, computes `AvailableTimeWindow`, emits suggestion.
- `lib/features/time_blocks/application/time_block_providers.dart` — Riverpod providers: `timeBlockRepositoryProvider`, `conflictCheckProvider`, `reclaimedTimeProvider`.
- `lib/features/time_blocks/data/time_block_repository.dart` — Abstract repository interface + `IsarTimeBlockRepository` implementation.
- `lib/core/local_db/isar_collections/isar_scheduled_time_block.dart` — Isar collection schema for `ScheduledTimeBlock`.
- `lib/core/local_db/isar_collections/isar_scheduled_time_block.g.dart` — Isar generated file (auto-generated, do not edit).
- `lib/core/local_db/isar_collections/isar_schemas.dart` — Must be updated to include `IsarScheduledTimeBlockSchema`.
- `lib/features/analytics/domain/models/analytics_event.dart` — Must be updated to add 4 new `AnalyticsEventType` values.
- `lib/features/tasks_hub/presentation/tasks_hub_screen.dart` — Hook: trigger conflict check on task save, show conflict bottom sheet.
- `lib/features/goals/presentation/goal_detail_screen.dart` — Hook: trigger conflict check on habit/goal save, show conflict bottom sheet.
- `lib/features/execution/data/timer_runtime_cache.dart` — Hook: detect early completion, trigger reclaimed time flow.
- `test/features/time_blocks/conflict_detection_engine_test.dart` — Unit tests for pure engine logic.
- `test/features/time_blocks/time_block_sync_service_test.dart` — Unit tests for block derivation and upsert flow.
- `test/features/time_blocks/time_block_repository_test.dart` — Unit tests for Isar repository operations.
- `test/features/time_blocks/reclaimed_time_service_test.dart` — Unit tests for early completion detection and window computation.

### Notes

- `ConflictDetectionEngine` must be a pure Dart class — no Flutter, no Isar, no Riverpod. All I/O is handled by `TimeBlockSyncService`.
- Conflict threshold: overlap ≥ 5 min OR overlap ≥ 15% of shorter block duration — BOTH conditions must be checked.
- Severity is a continuous 0–1 score (`overlapRatio + hardnessMultiplier + importanceWeight`), NOT binary.
- `AvailableTimeWindow` is in-memory only (no Isar persistence in Phase A).
- `importance` on `ScheduledTimeBlock` is derived from `modeRefId`: extreme = 90, disciplined = 60, flexible = 30.
- The conflict flow is NEVER a hard block — the user can always save anyway.
- No Firestore sync of time blocks in Phase A — Isar only.
- No changes to notification scheduling, escalation, or cadences in Phase A.

---

## Tasks

- [ ] 1.0 Domain models
  - [ ] 1.1 Create `FlexibilityType` enum (`flexible`, `rigid`) in `scheduled_time_block.dart`.
  - [ ] 1.2 Create `ScheduledTimeBlock` model with all 11 fields (id, entityId, entityKind, startAt, expectedDurationMinutes, computedEndAt, flexibilityType, allowOverlapOverride, importance, createdAtMs, updatedAtMs, schemaVersion). Add `toMap()`, `fromMap()`, `validate()`, and `copyWith()`.
  - [ ] 1.3 Create `AvailableTimeWindow` model with all 5 fields (entityId, windowStartAt, windowEndAt, durationMinutes, createdAtMs). In-memory only — no Isar persistence needed.
  - [ ] 1.4 Create `ConflictSeverity` enum (`minor`, `moderate`, `severe`) in `time_conflict.dart`.
  - [ ] 1.5 Create `ConflictType` enum (`partialOverlap`, `fullOverlap`, `contained`) in `time_conflict.dart`.
  - [ ] 1.6 Create `TimeConflict` model with all 6 fields (conflictingEntityId, conflictingEntityKind, overlapMinutes, severity, severityLabel, conflictType).
  - [ ] 1.7 Create `ConflictCheckResult` model with 3 fields (hasConflicts, conflicts, worstSeverity).

- [ ] 2.0 Isar schema and repository
  - [ ] 2.1 Create `isar_scheduled_time_block.dart` Isar collection schema. Map all `ScheduledTimeBlock` fields. Use `@Index` on `entityId` and `startAt` for efficient queries.
  - [ ] 2.2 Run `dart run build_runner build` to generate `isar_scheduled_time_block.g.dart`.
  - [ ] 2.3 Add `IsarScheduledTimeBlockSchema` to `isarSchemaList` in `isar_schemas.dart`.
  - [ ] 2.4 Define abstract `TimeBlockRepository` interface with 5 operations: `upsertBlock`, `deleteBlock`, `deleteBlockForEntity`, `listBlocksForDateRange`, `listOverlappingBlocks`.
  - [ ] 2.5 Implement `IsarTimeBlockRepository`. For `listOverlappingBlocks`: query blocks where `startAt < proposed.computedEndAt AND computedEndAt > proposed.startAt` to get candidates, then apply the overlap threshold filter in Dart (≥ 5 min OR ≥ 15% of shorter block).
  - [ ] 2.6 Add `timeBlockRepositoryProvider` to `time_block_providers.dart` wired to `IsarTimeBlockRepository`.

- [ ] 3.0 Conflict detection engine
  - [ ] 3.1 Create `ConflictDetectionEngine` as a pure static Dart class in `conflict_detection_engine.dart`.
  - [ ] 3.2 Implement `_computeOverlapMinutes(ScheduledTimeBlock a, ScheduledTimeBlock b) → int`. Returns 0 if no overlap.
  - [ ] 3.3 Implement `_meetsThreshold(int overlapMinutes, int shorterDurationMinutes) → bool`. Conflict exists if `overlapMinutes >= 5` OR `overlapMinutes / shorterDurationMinutes >= 0.15`.
  - [ ] 3.4 Implement `_computeSeverity(ScheduledTimeBlock proposed, ScheduledTimeBlock existing, int overlapMinutes) → double`. Apply formula: `overlapRatio + hardnessMultiplier + importanceWeight`, clamped to 1.0.
  - [ ] 3.5 Implement `_classifySeverity(double score) → ConflictSeverity`. Ranges: 0.0–0.35 = minor, 0.36–0.65 = moderate, 0.66–1.0 = severe.
  - [ ] 3.6 Implement `_classifyConflictType(ScheduledTimeBlock proposed, ScheduledTimeBlock existing) → ConflictType`. Logic: `contained` if one fully inside other, `fullOverlap` if start and end match closely, else `partialOverlap`.
  - [ ] 3.7 Implement `ConflictDetectionEngine.detect({required ScheduledTimeBlock proposed, required List<ScheduledTimeBlock> existing}) → List<TimeConflict>`. Iterates existing, applies threshold, builds `TimeConflict` for each hit. Excludes the proposed entity's own existing block (same `entityId`).
  - [ ] 3.8 Implement helper `_importanceFromModeRefId(String? modeRefId) → int`: extreme → 90, disciplined → 60, else → 30.

- [ ] 4.0 TimeBlockSyncService
  - [ ] 4.1 Create `TimeBlockSyncService` in `time_block_sync_service.dart`. Constructor takes `TimeBlockRepository` and `DateTime Function() now`.
  - [ ] 4.2 Implement `deriveBlock({required String entityId, required String entityKind, required DateTime startAt, required int durationMinutes, required String? modeRefId, bool isRigid = false}) → ScheduledTimeBlock`. Derives `computedEndAt`, `importance` from `modeRefId`, sets `schemaVersion = 1`.
  - [ ] 4.3 Implement `syncBlock(ScheduledTimeBlock block) → Future<void>`. Calls `repository.upsertBlock(block)`.
  - [ ] 4.4 Implement `removeBlockForEntity(String entityId) → Future<void>`. Calls `repository.deleteBlockForEntity(entityId)`.
  - [ ] 4.5 Implement `checkConflicts(ScheduledTimeBlock proposed) → Future<ConflictCheckResult>`. Fetches overlapping blocks, runs `ConflictDetectionEngine.detect()`, returns `ConflictCheckResult`.
  - [ ] 4.6 Add `timeBlockSyncServiceProvider` to `time_block_providers.dart`.

- [ ] 5.0 Riverpod conflict check provider
  - [ ] 5.1 Add `conflictCheckProvider` as a `FutureProvider.family<ConflictCheckResult, ScheduledTimeBlock>` in `time_block_providers.dart`. Calls `timeBlockSyncServiceProvider.checkConflicts(proposed)`.
  - [ ] 5.2 Ensure the provider is invalidated after a save so stale conflict state doesn't persist.

- [ ] 6.0 Analytics event types
  - [ ] 6.1 Add `overlapCreated` to `AnalyticsEventType` enum in `analytics_event.dart`.
  - [ ] 6.2 Add `overlapOverridden` to `AnalyticsEventType` enum.
  - [ ] 6.3 Add `reclaimedTimeGenerated` to `AnalyticsEventType` enum.
  - [ ] 6.4 Add `reclaimedTimeUsed` to `AnalyticsEventType` enum.

- [ ] 7.0 Task/habit save hook — conflict check and bottom sheet
  - [ ] 7.1 In the task save flow (`tasks_hub_screen.dart` or relevant save handler), after the user taps save, derive the proposed `ScheduledTimeBlock` and call `timeBlockSyncServiceProvider.checkConflicts()`.
  - [ ] 7.2 If `hasConflicts == true` and `worstSeverity` is `moderate` or `severe`: show the conflict bottom sheet (FR-A-15). For `minor` only: show an inline warning banner instead.
  - [ ] 7.3 Implement the conflict bottom sheet widget with three action buttons: "Save anyway", "Adjust time", "Shorten duration". List each `TimeConflict` with its severity color chip (yellow/orange/red) and conflicting entity title.
  - [ ] 7.4 "Save anyway" path: set `allowOverlapOverride = true` on the block, call `syncBlock()`, log `overlapCreated` AND `overlapOverridden` analytics events.
  - [ ] 7.5 "Adjust time" path: close sheet, return user to time picker field.
  - [ ] 7.6 "Shorten duration" path: close sheet, focus the duration input field.
  - [ ] 7.7 If no conflict: proceed to save normally, call `syncBlock()`. If a block was saved WITH an overlap (override), log `overlapCreated`.
  - [ ] 7.8 Mirror the same hook in the goal/habit save flow (`goal_detail_screen.dart`).

- [ ] 8.0 FlexibilityType UI toggle
  - [ ] 8.1 Add a `FlexibilityType` toggle to the task edit screen: "Flexible time" (flexible) vs "Fixed time" (rigid). Default: `flexible`.
  - [ ] 8.2 Pass `isRigid` to `deriveBlock()` based on the toggle value.
  - [ ] 8.3 Mirror the same toggle on the habit/goal edit screen.

- [ ] 9.0 Early completion — reclaimed time flow
  - [ ] 9.1 Create `ReclaimedTimeService` in `reclaimed_time_service.dart`. Constructor takes `TimeBlockRepository`.
  - [ ] 9.2 Implement `checkEarlyCompletion({required String entityId, required DateTime completedAt}) → Future<AvailableTimeWindow?>`. Looks up the entity's `ScheduledTimeBlock`, compares `completedAt` vs `computedEndAt`. Returns `AvailableTimeWindow` if `reclaimedMinutes >= 1`, else null.
  - [ ] 9.3 In the task completion flow (timer finish / manual complete), call `checkEarlyCompletion()`.
  - [ ] 9.4 If `AvailableTimeWindow.durationMinutes >= 10`: show a dismissible snackbar: "You freed up X minutes. Want to tackle something from your list?" with a "View tasks" action button.
  - [ ] 9.5 "View tasks" tap: navigate to task list, log `reclaimedTimeUsed` analytics event.
  - [ ] 9.6 On `AvailableTimeWindow` computed (any duration ≥ 1 min): log `reclaimedTimeGenerated` analytics event.
  - [ ] 9.7 Add `reclaimedTimeServiceProvider` to `time_block_providers.dart`.

- [ ] 10.0 Block lifecycle — deletion and update
  - [ ] 10.1 When a task is deleted, call `removeBlockForEntity(taskId)`.
  - [ ] 10.2 When a task's scheduled time or duration is cleared, call `removeBlockForEntity(taskId)`.
  - [ ] 10.3 When a task is edited (time or duration changed), call `syncBlock()` with the updated derived block — upsert handles the update in-place (same `entityId`, new values).
  - [ ] 10.4 Mirror all three lifecycle operations for habits/goals.

- [ ] 11.0 Tests
  - [ ] 11.1 `conflict_detection_engine_test.dart` — no conflict (2 min overlap on 60 min tasks), threshold boundary (exactly 5 min), minor/moderate/severe severity, rigid block escalation, contained block, same-entity exclusion, empty existing list.
  - [ ] 11.2 `time_block_sync_service_test.dart` — `deriveBlock` produces correct `computedEndAt` and `importance`, `checkConflicts` returns empty result when no overlap, returns conflicts when overlap threshold met.
  - [ ] 11.3 `time_block_repository_test.dart` — upsert, delete by id, delete by entity, `listBlocksForDateRange` returns correct blocks, `listOverlappingBlocks` applies threshold correctly.
  - [ ] 11.4 `reclaimed_time_service_test.dart` — returns null when completed on time, returns window when early, returns null when under 1 min reclaimed, correct `durationMinutes` calculation.
