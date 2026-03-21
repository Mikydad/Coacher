## Relevant Files

### New files to create
- `lib/features/plan_tomorrow/presentation/plan_tomorrow_screen.dart` — Main Plan Tomorrow screen (slots, tasks, slot management, carry-forward, done button).
- `lib/features/plan_tomorrow/application/plan_tomorrow_providers.dart` — `tomorrowRoutineSlotsProvider`, `tomorrowTasksForRoutineProvider`, `invalidateTomorrowProviders`.

### Existing files to modify
- `lib/features/planning/domain/models/task_item.dart` — Add `notes` field to `PlannedTask`.
- `lib/features/add_task/presentation/add_task_screen.dart` — Add Notes text field; extend `AddTaskEditArgs` to accept an optional pre-set slot context (`routineId`, `blockId`, `dateKey`) so saves land in the correct slot without calling `ensureDefaultDayPlan`.
- `lib/features/home/presentation/home_screen.dart` — Rewire "PLAN TOMORROW" action circle and bottom nav index 1 to `/plan-tomorrow`.
- `lib/features/tasks_hub/presentation/tasks_hub_screen.dart` — Pass `notes` through `_hubTaskWithOrderIndex` copy helper.
- `lib/app/app.dart` — Register `/plan-tomorrow` route; update route builder to pass `AddTaskSlotArgs`.

### Notes
- This project uses Flutter + Riverpod. Run `dart analyze lib` after each task to catch errors early.
- No test framework is set up yet — manual testing on device/simulator is the verification method.
- All Firestore writes must go through `PlanningRepository` so the offline sync queue handles failures.
- Use `Source.server` with a cache fallback (via `collectTasksForDateKeyPreferServer`) for tomorrow reads, same pattern as Focus and Home today.

---

## Tasks

- [ ] 1.0 Add `notes` field to `PlannedTask` model and `AddTaskScreen` UI
  - [ ] 1.1 In `task_item.dart`: add `this.notes` (`String?`) to the `PlannedTask` constructor (after `planDateKey`), add `if (notes != null) 'notes': notes` to `toMap`, and add `notes: map['notes'] as String?` to `fromMap`. Old docs without the field are safe — `as String?` returns `null`.
  - [ ] 1.2 Propagate `notes` in every place that copies a `PlannedTask` by value: `_hubTaskWithOrderIndex` in `tasks_hub_screen.dart`, `_completeTaskFromHome` and `_uncompleteTaskFromHome` in `home_screen.dart`.
  - [ ] 1.3 Add a `notes` state variable to `_AddTaskScreenState`; add a multi-line `TextField` (max 4 lines) below the title field with hint text "Notes (optional)"; pre-fill from `_loadedTask?.notes` in `_loadEdit`; pass `notes: _notes` in `_buildPlannedTask`.

- [ ] 2.0 Create providers and repository helpers for tomorrow's routine slots
  - [ ] 2.1 Create `lib/features/plan_tomorrow/application/plan_tomorrow_providers.dart`. Add `tomorrowRoutineSlotsProvider` as a `FutureProvider<List<Routine>>` that: (a) reads `planningRepositoryProvider`; (b) tries to load routines for `DateKeys.tomorrowKey()` with `GetOptions(source: Source.server)`, falls back to default if offline; (c) if the result is empty, creates three default `Routine` documents (Morning `orderIndex 0`, Afternoon `1`, Night `2`) with `dateKey = tomorrowKey()` using `upsertRoutine` for each, plus a default `TaskBlock` ("Main") for each via `upsertBlock`; (d) returns the sorted list by `orderIndex`.
  - [ ] 2.2 Add `tomorrowTasksForRoutineProvider` as a `FutureProvider.family<List<PlannedTaskRow>, String>` that takes a `routineId` and loads all `PlannedTaskRow` for that routine's blocks+tasks (server-preferred). Use the existing `getBlocks` + `getTasks` pattern from `collectTasksForDateKey`.
  - [ ] 2.3 Add `void invalidateTomorrowProviders(WidgetRef ref)` that calls `ref.invalidate(tomorrowRoutineSlotsProvider)` and `ref.invalidate(tomorrowTasksForRoutineProvider)`.

- [ ] 3.0 Extend `AddTaskScreen` to accept a pre-set slot context
  - [ ] 3.1 Add an optional `slotContext` field to `AddTaskEditArgs`: `final String? presetRoutineId`, `final String? presetBlockId`, `final String? presetDateKey`. These are separate from the edit-mode fields and default to `null`.
  - [ ] 3.2 In `_onSave` (the new-task branch), check if `widget.editArgs?.presetRoutineId != null`. If yes, skip `ensureDefaultDayPlan` and use `presetRoutineId` / `presetBlockId` directly; still compute `orderIndex` by loading existing tasks for that block. If no, keep the current `ensureDefaultDayPlan` logic.
  - [ ] 3.3 In `_planDateKey()`, if `widget.editArgs?.presetDateKey != null`, return that value when the reminder toggle is off (so the task stays on the pre-set day rather than defaulting to today).
  - [ ] 3.4 Update the route builder in `app.dart` so it still works: `AddTaskEditArgs` already passes through; no route change needed.

- [ ] 4.0 Build `PlanTomorrowScreen` — header, collapsible slot list, task rows, drag-to-reorder
  - [ ] 4.1 Create `lib/features/plan_tomorrow/presentation/plan_tomorrow_screen.dart` with `PlanTomorrowScreen` as a `ConsumerStatefulWidget`. Add `static const routeName = '/plan-tomorrow'`. Keep a `Set<String>` of expanded slot ids in local state (all expanded by default when slots first load).
  - [ ] 4.2 Build the screen scaffold: `AppBar` with title "Plan Tomorrow" and subtitle showing tomorrow's full date (e.g. `DateFormat('EEEE, MMM d').format(tomorrow)`); a motivational label below the header ("Design your tomorrow.") in cyan `#00E6FF`; fixed `FilledButton` "Done — See Summary" pinned to the bottom using a `Column` with `Expanded(child: ListView(...))` + the button below.
  - [ ] 4.3 In the `ListView`, watch `tomorrowRoutineSlotsProvider`. Show a `CircularProgressIndicator` while loading. On data, render a `_SlotSection` widget for each slot.
  - [ ] 4.4 Build `_SlotSection` as a `StatelessWidget` receiving `Routine routine`, `bool expanded`, `VoidCallback onToggle`, and children. The header row shows: slot title in large bold text, task count badge (e.g. "3 tasks" in white54), a right-pointing `Icons.expand_more` / `Icons.expand_less` chevron that animates, and a `⋮` `PopupMenuButton` with Rename / Delete actions. The body (shown only when expanded) is the task list + "+ Add Task" button.
  - [ ] 4.5 Watch `tomorrowTasksForRoutineProvider(routine.id)` inside each `_SlotSection` (use a `Consumer` or pass the slot tasks from the parent). Render a `_TomorrowTaskTile` per task. Wrap the list in `ReorderableListView` (shrinkWrap, NeverScrollableScrollPhysics). On `onReorder`: recompute `orderIndex` for changed items, call `planning.upsertTask` for each changed row, then call `invalidateTomorrowProviders(ref)`.
  - [ ] 4.6 Build `_TomorrowTaskTile` as a card showing: title (large, bold), a row with duration chip, priority badge (`High` / `Medium` / `Low` based on `priority` 1–2 / 3 / 4–5), category chip (if set), reminder bell icon (if `reminderEnabled`). Trailing `⋮` `PopupMenuButton` with Edit and Delete actions. Notes preview (first line, white54, fontSize 12) if `task.notes` is non-null.
  - [ ] 4.7 Wire Edit action: `Navigator.pushNamed(context, AddTaskScreen.routeName, arguments: AddTaskEditArgs(taskId: ..., routineId: ..., blockId: ..., dateKey: row.dateKey))`. On return (use `then` or `pop` result), call `invalidateTomorrowProviders(ref)`.
  - [ ] 4.8 Wire Delete action: show `AlertDialog` "Delete task?" with task title. On confirm: call `planning.deleteTask(...)`, then `invalidateTomorrowProviders(ref)`.

- [ ] 5.0 Slot management — add, rename, reorder, delete
  - [ ] 5.1 Wire "+ Add Task" button inside each expanded slot: `Navigator.pushNamed(context, AddTaskScreen.routeName, arguments: AddTaskEditArgs(presetRoutineId: routine.id, presetBlockId: block.id, presetDateKey: DateKeys.tomorrowKey()))`. You need the `blockId` — fetch it from `getBlocks(routine.id)` once when the slot loads (store in provider or pass down).
  - [ ] 5.2 Implement Rename slot: tapping "Rename" in the slot's `⋮` menu shows an `AlertDialog` with a `TextField` pre-filled with the current title. On confirm: call `planning.upsertRoutine(routine.copyWith(title: newTitle))`. Since `Routine` is immutable, create a helper `Routine copyWith({String? title})` on the model, or construct manually. Then call `invalidateTomorrowProviders(ref)`.
  - [ ] 5.3 Implement Delete slot: tapping "Delete" in the slot's `⋮` menu first counts the tasks in the slot. If >0, show `AlertDialog` "This will also delete N tasks." If 0, show simple "Delete slot?" dialog. Guard: if there is only 1 slot left, show a `SnackBar` "Can't delete the last slot" and return. On confirm: load all blocks for the routine → for each block, load all tasks and call `deleteTask` for each → call `deleteBlock` for each block → call `deleteRoutine(routine.id)`. Then `invalidateTomorrowProviders(ref)`.
  - [ ] 5.4 Implement slot reorder via drag: wrap the slot list in `ReorderableListView` with `buildDefaultDragHandles: false`; add a `ReorderableDragStartListener` drag handle (e.g. `Icons.drag_handle`) on each slot header. On `onReorder`: recompute `orderIndex` for all slots, call `planning.upsertRoutine` for each changed one, then `invalidateTomorrowProviders(ref)`.
  - [ ] 5.5 Add "+ Add Slot" `OutlinedButton` below all slots (but above the "Unfinished from Today" section). Tapping it shows an `AlertDialog` with a `TextField` "Slot name". On confirm: call `planning.ensureDefaultDayPlan`-style logic manually — `upsertRoutine` with the new title and `orderIndex = slots.length`, then `upsertBlock` for a default "Main" block. Then `invalidateTomorrowProviders(ref)`.

- [ ] 6.0 Implement "Unfinished from Today" carry-forward section
  - [ ] 6.1 In `PlanTomorrowScreen`, also watch `todayAllTasksRowsProvider`. Filter the rows to only those with status `notStarted`, `inProgress`, or `partial`. If empty, render nothing. If non-empty, render a collapsible "Unfinished from Today" section (use the same `_SlotSection`-style header but with `Colors.white38` text to visually distinguish it).
  - [ ] 6.2 Each carry-forward row shows the task title, status badge, and a `TextButton` "Move to Tomorrow →" aligned to the trailing edge.
  - [ ] 6.3 Tapping "Move to Tomorrow →" shows a `showModalBottomSheet` listing tomorrow's slot names (from `tomorrowRoutineSlotsProvider`) as selectable `ListTile`s.
  - [ ] 6.4 On slot selection: (a) delete the task from today using `planning.deleteTask(routineId: row.routineId, blockId: row.blockId, taskId: row.task.id)`; (b) look up the chosen slot's default block id (load once from `getBlocks`); (c) compute the next `orderIndex` for that block; (d) call `planning.upsertTask` with the task copied with new `routineId`, `blockId`, `planDateKey = tomorrowKey()`, and `status = notStarted`; (e) call `invalidateTaskListProviders(ref)` and `invalidateTomorrowProviders(ref)`; (f) close the bottom sheet.

- [ ] 7.0 Implement Done / Plan Summary bottom sheet
  - [ ] 7.1 Wire the "Done — See Summary" button to call `_showPlanSummary(context, ref)`.
  - [ ] 7.2 Implement `_showPlanSummary`: call `showModalBottomSheet(isScrollControlled: true, ...)`. Inside, build a `_PlanSummarySheet` widget that receives the current list of slots and their loaded tasks (pass them in from the parent state / read from providers).
  - [ ] 7.3 `_PlanSummarySheet` shows: tomorrow's date as a large header; for each slot, a row with slot name, task count, and total duration in minutes (summed from `durationMinutes`); a "Reminders set" subsection listing every task where `reminderEnabled == true` with its `reminderTimeIso` formatted as a human-readable time. Style using the `_NeonCard` pattern (dark card, cyan accent for section labels).
  - [ ] 7.4 Add a "Close" `FilledButton` at the bottom of the sheet that calls `Navigator.pop(context)` (closes the sheet), then `Navigator.pop(context)` again (returns to Home). Alternatively, `Navigator.popUntil(context, ModalRoute.withName(HomeScreen.routeName))` in one call.

- [ ] 8.0 Wire routing — new `/plan-tomorrow` route, rewire Home
  - [ ] 8.1 In `plan_tomorrow_screen.dart`, declare `static const routeName = '/plan-tomorrow'`.
  - [ ] 8.2 In `app.dart`: add `import` for `PlanTomorrowScreen`; add `PlanTomorrowScreen.routeName: (_) => const PlanTomorrowScreen()` to the `routes` map.
  - [ ] 8.3 In `home_screen.dart`: replace `GoalSelectionScreen.routeName` with `PlanTomorrowScreen.routeName` on the "PLAN TOMORROW" `_ActionCircle` tap. Update the import.
  - [ ] 8.4 In `home_screen.dart`: find the bottom nav `onTap` handler for index 1 and replace `GoalSelectionScreen.routeName` with `PlanTomorrowScreen.routeName`.
  - [ ] 8.5 Run `dart analyze lib` and fix any issues. Hot-restart and verify the "PLAN TOMORROW" button opens the new screen.
