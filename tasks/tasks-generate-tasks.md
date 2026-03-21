# Task list: Persist Add Task (UI functional #1)

Generated using the structure defined in [`PRD/generate-tasks.md`](../PRD/generate-tasks.md). This document covers **only parent task 1.0**: make **Add Task** save a real `PlannedTask` to Firestore (with sync queue), aligned with the existing `Routine → TaskBlock → PlannedTask` model and `executionDayTasksProvider`.

## Relevant Files

- `lib/features/add_task/presentation/add_task_screen.dart` — Form UI and save flow; must call planning persistence and use a single stable `taskId` for reminders + task doc.
- `lib/features/planning/data/planning_repository.dart` — `upsertRoutine`, `upsertBlock`, `upsertTask`; already writes under `FirestorePaths` with offline queue on failure.
- `lib/features/planning/domain/models/task_item.dart` — `PlannedTask` fields and `toMap` / `fromMap`; extend if you add category (optional).
- `lib/features/planning/domain/models/routine.dart` — Routine entity; needed when ensuring a day plan exists.
- `lib/features/planning/domain/models/block.dart` — Block entity; parent container for tasks.
- `lib/core/firebase/firestore_paths.dart` — Path helpers for `routines`, `blocks`, `tasks`.
- `lib/core/utils/date_keys.dart` — `tomorrowKey()`; **must match** `executionDayTasksProvider` date filter so new tasks appear on Focus selection.
- `lib/core/utils/stable_id.dart` — Generate opaque ids for new entities.
- `lib/features/execution/application/execution_day_loader.dart` — `executionDayTasksProvider`; invalidate after save so Focus list refreshes.
- `lib/core/di/providers.dart` — `planningRepositoryProvider`; already registered.
- `lib/features/reminders/application/reminder_sync_service.dart` — `syncForTaskIds`; must receive the **same** `taskId` as `PlannedTask.id`.
- `documentation/firebase-rules.md` — User-scoped rules; no change needed if paths stay under `users/{uid}/...`.

### Notes

- Tasks in this app are **not** top-level documents: they live at `users/{uid}/routines/{routineId}/blocks/{blockId}/tasks/{taskId}`. Add Task must **ensure** a routine for the target `dateKey` and at least one block before `upsertTask`.
- `executionDayTasksProvider` loads routines where `dateKey == DateKeys.tomorrowKey()`. New tasks should use that same `dateKey` (or you must change the loader and document the product rule).
- Replace `task_${title.hashCode.abs()}` with `StableId.generate('task')` so titles can change without breaking reminder ↔ task linkage.
- Run analyzer: `dart analyze` or `flutter analyze`. Run tests: `flutter test` (optionally `flutter test test/path/to/file_test.dart`).
- Widget tests for Add Task can inject a fake `PlanningRepository` via `ProviderScope` overrides if you refactor save logic into a small notifier or use `planningRepositoryProvider` directly from the screen.

## Tasks

- [x] **1.0 Persist Add Task — save `PlannedTask` via `PlanningRepository` and align with Focus list**
  - [x] **1.1** Introduce a small helper (e.g. `PlanningDayBootstrap` or methods on `PlanningRepository`) that, given a `dateKey`, returns `(routineId, blockId)` after ensuring: one `Routine` with that `dateKey` (create with `StableId.generate('routine')` if none), and one default `TaskBlock` for that routine (e.g. title `"Main"`, `orderIndex: 0`) if none exists.
  - [x] **1.2** Map Add Task duration chips (`15 MIN`, `25 MIN`, etc.) to `durationMinutes` (`int`) for `PlannedTask`; default to `25` if parsing fails.
  - [x] **1.3** On **Add Task** submit: generate `taskId = StableId.generate('task')` once; build `PlannedTask` with `id: taskId`, `routineId` / `blockId` from 1.1, `title` from the text field (or `"Untitled Task"`), `durationMinutes` from 1.2, sensible defaults for `priority` (e.g. `3`) and `orderIndex` (e.g. next index or `0`), `reminderEnabled` / `reminderTimeIso` from the reminder switch and time picker, `status: TaskStatus.notStarted`, `createdAtMs` / `updatedAtMs` from `DateTime.now().millisecondsSinceEpoch`.
  - [x] **1.4** Call `planningRepository.upsertTask(plannedTask)` after (or before) reminder save; keep `_saveReminderForTask` logic but pass **`taskId`** from 1.3 into `ReminderConfig.taskId` instead of title-hash id.
  - [x] **1.5** After successful persist, call `ref.invalidate(executionDayTasksProvider)` so **Focus selection** reloads without an app restart.
  - [x] **1.6** (Optional but recommended) Make category chips selectable (`ChoiceChip`) and persist: either add optional `category` to `PlannedTask` + Firestore field with safe `fromMap` default for old docs, or defer and document under `documentation/future_todo.md`.
  - [ ] **1.7** Manual QA: add a task from Add Task → open Focus → confirm it appears with correct title and duration; enable reminder and confirm `syncForTaskIds` still runs with matching `taskId`.
  - [x] **1.8** (Optional) Add a widget or unit test that verifies `upsertTask` is called with expected fields when the user taps **Add Task** (using provider overrides).
