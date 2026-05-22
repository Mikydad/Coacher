# PRD: Cross-Entity Time Block Conflict Detection

**Status:** Draft  
**Scope:** Goal vs Goal · Task vs Goal · Goal vs Task  
**Prerequisite:** Existing Task vs Task conflict system (Phase A time blocks) — fully implemented and tested.

---

## 1. Background

The app already detects scheduling conflicts between two **tasks** using a three-layer pipeline:

1. `TimeBlockSyncService.deriveBlock()` — converts entity fields into a `ScheduledTimeBlock`
2. `TimeBlockRepository.listOverlappingBlocks()` — geometric Isar query
3. `ConflictDetectionEngine.detect()` — threshold + severity scoring → `ConflictCheckResult`
4. `ConflictBottomSheet` / SnackBar — user resolution UI

**What is missing:** Goals are never written to `IsarScheduledTimeBlock`, so the Isar geometric query cannot see them. This means:

- A **goal** set at 10:30 for 25 min does not block a task at 10:00 for 60 min (and vice versa).
- Two **goals** can be set at the exact same time without any warning.

This PRD defines the minimum changes needed to extend the existing system to cover all three missing conflict pairs, **without rewriting any existing logic**.

---

## 2. Goals

- Goal vs Goal conflicts detected and surfaced with the same UX as Task vs Task.
- Task vs Goal and Goal vs Task conflicts detected and surfaced with the same UX.
- Zero changes to `ConflictDetectionEngine` — it already handles `entityKind` agnostically.
- Zero changes to `TimeBlockRepository` or `IsarScheduledTimeBlock` — the schema already stores `entityKind`.
- Zero changes to `ConflictBottomSheet` — it already renders any `ConflictCheckResult`.
- The 30-minute default duration used in the habit-anchor path (`goalHabitAnchorDefaultMinutes`) becomes the **canonical goal block duration** when a goal has `reminderEnabled = true` but no explicit `durationMinutes` field.

---

## 3. Non-Goals

- Adding a `durationMinutes` field to `UserGoal` (deferred — V2).
- Real-time live conflict indicators on a calendar view.
- Conflict detection for goals without `reminderEnabled = true` (no scheduled time → no block → nothing to conflict).
- Changing the `ConflictBottomSheet` copy (keep it generic: "Scheduling Conflict").

---

## 4. Key Design Decision: Goal Duration

`UserGoal` has no `durationMinutes` field. The goal reminder is a **point-in-time** daily notification, not a time window. However, to participate in conflict detection, a goal must occupy a window.

**Resolution:** Use a constant **`kGoalBlockDefaultDurationMinutes = 30`** when deriving a goal's time block. This matches the value already used by `habit_anchor_aggregator.dart` (`goalHabitAnchorDefaultMinutes`). A future release may add an explicit duration picker to `GoalEditorScreen`.

---

## 5. How Goals Get a Start Time

`UserGoal.reminderMinutesFromMidnight` is minutes since midnight (0–1439), local time, date-agnostic. To produce an absolute `DateTime` for `deriveBlock`:

```
startAt = DateTime(
  today.year, today.month, today.day,
  minutes ~/ 60,
  minutes % 60,
)
```

The `planDateKey` context (the date the goal editor was opened on) provides the calendar day. For conflict checking, use **today's local date** (same convention as tasks in `AddTaskScreen`).

---

## 6. Functional Requirements

### FR-CB-01 — Goal block written on save
When a `UserGoal` is saved (create or edit) with `reminderEnabled = true` and `reminderMinutesFromMidnight != null`, write a `ScheduledTimeBlock` to Isar via `TimeBlockSyncService.syncBlock()`. Use:
- `entityKind = "goal"`
- `startAt` derived from `reminderMinutesFromMidnight` + today's local date
- `expectedDurationMinutes = kGoalBlockDefaultDurationMinutes` (30)
- `flexibilityType = FlexibilityType.flexible` (goals are not rigid by default)
- `importance` derived from goal `intensity` (see §7)
- `allowOverlapOverride = false` (overridden after user chooses "Save anyway")

### FR-CB-02 — Goal block deleted on reminder disabled
When a goal is saved with `reminderEnabled = false`, delete its block via `TimeBlockSyncService.removeBlockForEntity(goal.id)`.

### FR-CB-03 — Goal block deleted on goal archival / deletion
When a goal's status changes to `archived` or `completed`, or the goal is deleted, delete its block.

### FR-CB-04 — Goal vs Goal conflict check in GoalEditorScreen
Before saving a goal with a reminder, call `TimeBlockSyncService.checkConflicts(proposedBlock)`. Handle the result with the same three-tier logic as `AddTaskScreen._checkTimeBlockConflicts`:
- **Minor** → SnackBar auto-save (no blocking dialog)
- **Moderate / Severe** → `ConflictBottomSheet.show()` → Save anyway / Adjust time / Shorten duration

### FR-CB-05 — Task vs Goal conflict check (task saving)
`AddTaskScreen._checkTimeBlockConflicts` already queries `listOverlappingBlocks` against all `ScheduledTimeBlock` rows. Once goal blocks are written to Isar (FR-CB-01), tasks will automatically detect goal conflicts — **no code change needed in AddTaskScreen** provided entity titles are populated for goals (see FR-CB-07).

### FR-CB-06 — Goal vs Task conflict check (goal saving)
`GoalEditorScreen` calls `checkConflicts` (FR-CB-04). Since task blocks already exist in Isar, a goal proposed at 10:30 will find the task block at 10:00–11:00 in the geometric query — **no special-casing needed**.

### FR-CB-07 — Entity title resolution
`ConflictDetectionEngine.detect` accepts `Map<String, String> entityTitles`. Populate this map so conflicts show the conflicting entity's title (not its ID):
- When checking a **task**: pass titles from `allTasks` + **all active goal titles** keyed by goal ID.
- When checking a **goal**: pass titles from **all tasks** + all other goal titles.

A lightweight helper `_buildEntityTitleMap(tasks, goals)` in each screen handles this.

### FR-CB-08 — "Shorten duration" for goals
Goals have no user-editable duration yet. If the user taps "Shorten duration" from the goal conflict sheet, treat it the same as "Adjust time" (abort save, return user to the editor). Do not attempt to auto-shorten.

---

## 7. Importance Mapping for Goals

Goals use `intensity` (1–5) instead of `modeRefId`. Map to the same 0–100 importance scale:

| Intensity | Importance |
|-----------|-----------|
| 1–2       | 30        |
| 3         | 60        |
| 4–5       | 90        |

Add a helper `ConflictDetectionEngine.importanceFromGoalIntensity(int intensity)` alongside the existing `importanceFromModeRefId`.

---

## 8. Save Flow Changes

### Current task save flow (unchanged)
```
AddTaskScreen._onSave()
  → _confirmOverlapIfNeeded()    // habit anchors (existing)
  → _checkTimeBlockConflicts()   // reads ALL ScheduledTimeBlock rows
  → upsertTask()
  → _syncTimeBlock()             // writes task block
  → _persistReminder()
```

### New goal save flow (GoalEditorScreen)
```
GoalEditorScreen._onSave()
  → _checkGoalTimeBlockConflicts()   // NEW: same pattern as task version
      IF proposedBlock == null → proceed
      result = service.checkConflicts(block, entityTitles: titleMap)
      IF minor → SnackBar → proceed
      IF moderate/severe → ConflictBottomSheet → save anyway OR abort
  → goalService.upsertGoal(goal)     // existing
  → _syncGoalBlock()                 // NEW: deriveBlock + syncBlock / removeBlock
  → goalReminderSyncService.applyForGoal(goal)  // existing
```

---

## 9. New / Modified Files

| File | Change |
|---|---|
| `lib/features/time_blocks/application/conflict_detection_engine.dart` | ADD `importanceFromGoalIntensity(int intensity)` static method |
| `lib/features/time_blocks/application/time_block_sync_service.dart` | ADD `kGoalBlockDefaultDurationMinutes = 30` constant |
| `lib/features/goals/presentation/goal_editor_screen.dart` | ADD `_checkGoalTimeBlockConflicts()` + `_syncGoalBlock()` methods; ADD import of `TimeBlockSyncService`, `ConflictBottomSheet`, `timeBlockSyncServiceProvider` |
| `lib/features/goals/application/goals_providers.dart` | ADD `goalTitleMapProvider` — async map of `goalId → title` for all active goals (used by AddTaskScreen title resolution) |
| `lib/features/add_task/presentation/add_task_screen.dart` | MODIFY `_checkTimeBlockConflicts` to also include goal titles in `entityTitles` map (read from `goalTitleMapProvider`) |
| `lib/features/goals/application/goal_block_sync_service.dart` | NEW — thin wrapper calling `TimeBlockSyncService` methods for goals; handles `reminderMinutesFromMidnight → DateTime` conversion and intensity → importance mapping |

---

## 10. Implementation Groups

### Group 1 — Engine & service extension (pure Dart, no UI)
1.1 Add `ConflictDetectionEngine.importanceFromGoalIntensity(int)`  
1.2 Add `kGoalBlockDefaultDurationMinutes` constant to `time_block_sync_service.dart`  
1.3 Create `GoalBlockSyncService` — `syncBlockForGoal(UserGoal, DateTime today)`, `removeBlockForGoal(String goalId)`  
1.4 Add `goalBlockSyncServiceProvider` to `goals_providers.dart`  

### Group 2 — Title map
2.1 Add `goalTitleMapProvider` to `goals_providers.dart`  
2.2 Update `AddTaskScreen._checkTimeBlockConflicts` to merge goal titles into `entityTitles`  

### Group 3 — GoalEditorScreen wiring
3.1 Add `_checkGoalTimeBlockConflicts()` method  
3.2 Add `_syncGoalBlock()` method  
3.3 Wire both into `_onSave()` flow  
3.4 Handle archival/deletion → `removeBlockForGoal`  

### Group 4 — Tests
4.1 `conflict_detection_engine_goal_intensity_test.dart` — `importanceFromGoalIntensity` mapping  
4.2 `goal_block_sync_service_test.dart` — `syncBlockForGoal` produces correct block fields; `removeBlockForGoal` delegates correctly; disabled reminder → remove  
4.3 `goal_editor_conflict_integration_test.dart` — goal saved at same time as existing task block triggers conflict result; goal with no reminder skips check  

---

## 11. Acceptance Criteria

- [ ] Two goals with the same `reminderMinutesFromMidnight` → conflict sheet shown on second save.
- [ ] Task 10:00–11:00 already saved; goal set at 10:30 → conflict sheet shown in goal editor.
- [ ] Goal 10:30 already saved; task set at 10:00–11:00 → conflict sheet shown in add-task screen (no code change to add-task needed beyond title map).
- [ ] Goal with `reminderEnabled = false` → no block written, no conflict check run.
- [ ] Goal archived/deleted → block removed from Isar.
- [ ] Conflict title shows the human-readable name, not the entity ID.
- [ ] All Group 4 tests pass.
- [ ] Existing task vs task conflict tests continue to pass unchanged.
