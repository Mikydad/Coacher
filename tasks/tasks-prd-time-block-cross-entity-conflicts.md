# Tasks: Cross-Entity Time Block Conflict Detection

**PRD:** `prd-time-block-cross-entity-conflicts.md`  
**Status:** Not started

---

## Group 1 — Engine & service extension (pure Dart, no UI)

- [ ] **1.1** Add `ConflictDetectionEngine.importanceFromGoalIntensity(int intensity)` static method to `lib/features/time_blocks/application/conflict_detection_engine.dart`
  - intensity 1–2 → 30, intensity 3 → 60, intensity 4–5 → 90
  - Same file as existing `importanceFromModeRefId`

- [ ] **1.2** Add `const kGoalBlockDefaultDurationMinutes = 30` to `lib/features/time_blocks/application/time_block_sync_service.dart`

- [ ] **1.3** Create `lib/features/goals/application/goal_block_sync_service.dart`
  - `syncBlockForGoal(UserGoal goal, DateTime today)` — converts `reminderMinutesFromMidnight` to `DateTime`, calls `TimeBlockSyncService.deriveBlock()` + `syncBlock()`; no-ops if `reminderEnabled = false` or `reminderMinutesFromMidnight == null`
  - `removeBlockForGoal(String goalId)` — calls `TimeBlockSyncService.removeBlockForEntity(goalId)`
  - Uses `kGoalBlockDefaultDurationMinutes` for duration
  - Uses `ConflictDetectionEngine.importanceFromGoalIntensity(goal.intensity)` for importance
  - `entityKind = "goal"`, `flexibilityType = FlexibilityType.flexible`

- [ ] **1.4** Add `goalBlockSyncServiceProvider` to `lib/features/goals/application/goals_providers.dart`
  - `Provider<GoalBlockSyncService>` that reads `timeBlockSyncServiceProvider`

---

## Group 2 — Title map

- [ ] **2.1** Add `goalTitleMapProvider` to `lib/features/goals/application/goals_providers.dart`
  - `Provider<Map<String, String>>` derived from `goalsStreamProvider`
  - Maps `goal.id → goal.title` for all goals regardless of status

- [ ] **2.2** Update `lib/features/add_task/presentation/add_task_screen.dart` — `_checkTimeBlockConflicts()`
  - Read `goalTitleMapProvider` and merge into the `entityTitles` map passed to `service.checkConflicts()`
  - Existing task title map logic unchanged; goal titles added on top

---

## Group 3 — GoalEditorScreen wiring

- [ ] **3.1** Add `_checkGoalTimeBlockConflicts()` to `lib/features/goals/presentation/goal_editor_screen.dart`
  - Mirror of `AddTaskScreen._checkTimeBlockConflicts()`
  - Build `proposedBlock` via `GoalBlockSyncService` (derive only, no persist yet)
  - If `proposedBlock == null` → return true (proceed)
  - Build `entityTitles` from all tasks + all other goal titles
  - Run `timeBlockSyncService.checkConflicts(proposedBlock, entityTitles: titles)`
  - **Minor** → show SnackBar, return true
  - **Moderate/Severe** → `ConflictBottomSheet.show()` → `saveAnyway` returns true, anything else returns false

- [ ] **3.2** Add `_syncGoalBlock()` to `GoalEditorScreen`
  - If `reminderEnabled = true` and `reminderMinutesFromMidnight != null` → `goalBlockSyncService.syncBlockForGoal(goal, DateTime.now())`
  - If `reminderEnabled = false` → `goalBlockSyncService.removeBlockForGoal(goal.id)`

- [ ] **3.3** Wire into `GoalEditorScreen._onSave()` (or equivalent save method)
  - Call `_checkGoalTimeBlockConflicts()` before `goalService.upsertGoal()`; abort if returns false
  - Call `_syncGoalBlock()` after `goalService.upsertGoal()`, before `goalReminderSyncService.applyForGoal()`

- [ ] **3.4** Handle goal archival and deletion → `removeBlockForGoal`
  - In `GoalEditorScreen` archive/complete action: call `goalBlockSyncService.removeBlockForGoal(goal.id)`
  - In goal deletion path (wherever `goalService.deleteGoal()` is called): call `removeBlockForGoal` after deletion

---

## Group 4 — Tests

- [ ] **4.1** Create `test/features/time_blocks/conflict_detection_engine_goal_intensity_test.dart`
  - `importanceFromGoalIntensity(1)` → 30
  - `importanceFromGoalIntensity(2)` → 30
  - `importanceFromGoalIntensity(3)` → 60
  - `importanceFromGoalIntensity(4)` → 90
  - `importanceFromGoalIntensity(5)` → 90

- [ ] **4.2** Create `test/features/goals/goal_block_sync_service_test.dart`
  - `syncBlockForGoal` with `reminderEnabled = true` → produces block with `entityKind = "goal"`, correct `startAt`, `expectedDurationMinutes = 30`, correct `importance`
  - `syncBlockForGoal` with `reminderEnabled = false` → calls `removeBlockForEntity`, does not call `syncBlock`
  - `syncBlockForGoal` with `reminderMinutesFromMidnight = null` → no-ops
  - `removeBlockForGoal` → delegates to `TimeBlockSyncService.removeBlockForEntity`
  - Correct `startAt` from `reminderMinutesFromMidnight` (e.g. 630 min = 10:30 local)
  - intensity 1 → importance 30, intensity 3 → importance 60, intensity 5 → importance 90

- [ ] **4.3** Create `test/features/goals/goal_editor_conflict_integration_test.dart`
  - Goal with `reminderEnabled = true` and overlapping existing task block → `checkConflicts` returns non-empty result
  - Goal with `reminderEnabled = false` → conflict check skipped entirely
  - Two goals at same time → second save triggers conflict result
  - Verify existing task vs task conflict tests still pass (run `test/features/time_blocks/conflict_detection_engine_test.dart`)
