# Task list: Today’s tasks hub, plan dates, home completion (`prd-today-tasks-detail`)

Generated from [`prd-today-tasks-detail.md`](prd-today-tasks-detail.md) using [`PRD/generate-tasks.md`](../PRD/generate-tasks.md).

**Defaults applied for open questions:** Home row uses a **leading checkbox** to complete (title row opens hub); completed tasks **show with strikethrough** on Home; reorder **today-only** in hub v1; editing reminder to another day **moves** the task document; cross-day open list uses **bounded date scan** (−7 … +14 days, skip today).

## Relevant Files

- `lib/core/utils/date_keys.dart` — `todayKey`, `yyyymmdd`, calendar helpers for plan dates.
- `lib/features/planning/data/planning_repository.dart` — `getRoutinesForDate`, `getTasks`, `upsertTask`, `deleteTask`, `ensureDefaultDayPlan`.
- `lib/features/planning/domain/models/task_item.dart` — `PlannedTask`, `TaskStatus`.
- `lib/features/planning/domain/add_task_duration.dart` — duration label ↔ minutes.
- `lib/features/planning/application/planned_task_providers.dart` — `PlannedTaskRow`, loaders, `todayAllTasksRowsProvider`, `openTasksOutsideTodayProvider`, `invalidateTaskListProviders`.
- `lib/features/execution/application/execution_day_loader.dart` — `ExecutionTaskItem`, `executionDayTasksProvider` (today’s open tasks for Focus).
- `lib/features/add_task/presentation/add_task_screen.dart` — create + edit, reminder date/time, plan `dateKey`, move on day change.
- `lib/features/reminders/data/reminder_repository.dart` — `getRemindersForTasks`, `upsertReminder`.
- `lib/features/tasks_hub/presentation/tasks_hub_screen.dart` — hub UI (sections, reorder, delete, edit, %).
- `lib/features/home/presentation/home_screen.dart` — today list, checkbox complete, navigate to hub.
- `lib/app/app.dart` — routes for hub and `AddTaskScreen` arguments.
- `lib/features/scoring/application/scoring_controller.dart` — `submit` for 100% on quick complete.
- `test/widget_test.dart` — override task providers for tests.
- `test/planning/add_task_duration_test.dart` — extend for reverse duration mapping if added.

### Notes

- Run `flutter analyze` and `flutter test`. Place new unit tests under `test/` mirroring `lib/` where useful.
- After any task mutation, call `invalidateTaskListProviders(ref)` so Home, Focus, and hub stay in sync.

## Tasks

- [x] **1.0 Plan date rules & Add Task (create + edit + move)**
  - [x] **1.1** Add `durationLabelFromMinutes` (or equivalent) for edit prefill of duration chips.
  - [x] **1.2** When reminder is **off**, set plan `dateKey = todayKey`. When **on**, set plan `dateKey` to the **calendar day** of the reminder; if that day is **today**, use `todayKey`.
  - [x] **1.3** Add **reminder date** UI (`showDatePicker` + existing time picker) when reminder is enabled so “another day” is explicit.
  - [x] **1.4** Introduce `AddTaskEditArgs` (`taskId`, `routineId`, `blockId`, `dateKey`) and wire **MaterialApp** route to pass `ModalRoute.settings.arguments` into `AddTaskScreen`.
  - [x] **1.5** On edit: load `PlannedTask` + reminder via `getTasks` / `getRemindersForTasks`; prefill fields; AppBar **Edit Task**; primary button **Save**.
  - [x] **1.6** On save (edit): if computed plan `dateKey` **differs** from loaded routine day, **delete** old task doc and **upsert** under `ensureDefaultDayPlan(newKey)` with **same** `task.id`, appending **orderIndex**; else in-place `upsertTask`.
  - [x] **1.7** Reuse stable **reminder** document id on edit (`upsertReminder` merge) when one exists for `taskId`.
  - [x] **1.8** After create/save, `invalidateTaskListProviders(ref)`.

- [x] **2.0 Shared loaders & providers (today all, cross-day open, Focus)**
  - [x] **2.1** Add `PlannedTaskRow` (`dateKey`, `routineId`, `blockId`, `task`) and `_collectTasksForDateKey` traversing routines → blocks → tasks.
  - [x] **2.2** `todayAllTasksRowsProvider` — all statuses for `todayKey` (hub + Home source of truth).
  - [x] **2.3** `openTasksOutsideTodayProvider` — for offsets −7…+14 (skip 0), collect tasks with status `notStarted`, `inProgress`, or `partial`.
  - [x] **2.4** Refactor `executionDayTasksProvider` to use today’s collection and filter to open statuses; map to `ExecutionTaskItem`.
  - [x] **2.5** Export `invalidateTaskListProviders` invalidating today-all, open-outside-today, and execution providers.

- [x] **3.0 Home — Today’s Tasks card**
  - [x] **3.1** Switch Home list + progress counts to `todayAllTasksRowsProvider` (include **completed** with strikethrough / score 100%).
  - [x] **3.2** Add **header row**: tappable **“Today’s Tasks”** + **chevron** → `TasksHubScreen.routeName` (separate hit target from row).
  - [x] **3.3** Per row: **checkbox** (or equivalent) calls mark-complete: `upsertTask` with `TaskStatus.completed`, `scoringController.submit` 100%, update `scoredTaskStatusesProvider`, invalidate lists.
  - [x] **3.4** Show **completion %** on Home rows when `scores[taskId]` is set and &lt; 100 (optional subtitle).

- [x] **4.0 Tasks hub screen**
  - [x] **4.1** New route `/tasks` — scaffold, sections **Today** and **Open on other days** (date subtitle per row).
  - [x] **4.2** Rows: title, duration, category, reminder on/off, **%** from `scoredTaskStatusesProvider` or em dash.
  - [x] **4.3** **Edit** icon → `Navigator.pushNamed(..., AddTaskScreen.routeName, arguments: AddTaskEditArgs(...))`.
  - [x] **4.4** **Delete** with confirmation → `deleteTask` → invalidate.
  - [x] **4.5** **Reorder** (today section only): `ReorderableListView`; on drop, reassign `orderIndex` sequentially and `upsertTask` each affected task.

- [ ] **5.0 QA & tests**
  - [ ] **5.1** Manual: add today task → Home + hub; reminder tomorrow → task absent today on Home, appears under other-day open; after midnight simulation (change device date) verify Home.
  - [x] **5.2** Widget test overrides for `todayAllTasksRowsProvider` / `openTasksOutsideTodayProvider` if Home test flakes on Firestore.
