# Task creation: from tap to local database and sync

This is a guided trace of what happens when a user creates a task. It follows
the normal **Add task** path, then shows how the task reappears in the UI.

> Core idea: **Isar is the on-device source of truth.** The task is saved to
> Isar first, the UI observes Isar, and Firestore is updated later through the
> durable sync outbox. Creating a task must work in airplane mode.

## The picture first

```text
User taps “Add task”
  ↓
showAddTaskSheet → AddTaskScreen
  ↓
form State holds draft values; user taps “Add task”
  ↓
_onSave builds a PlannedTask and asks the repository to save it
  ↓
planningRepositoryProvider → IsarPlanningRepository
  ↓
validate → Isar write transaction → IsarTask row
  ↓                         ↓
Isar watchers notify UI           outboxUpsert stores a pending Firestore write
  ↓                         ↓
Home / Tasks Hub redraw          background SyncService flushes when possible
                                  ↓
                           Firestore document
                                  ↓
                         another device pulls it into Isar (LWW)
```

The only part that must finish before the save action completes is local work:
the Isar write and durable outbox enqueue. Network acknowledgement is never
awaited on this path.

## 1. UI entry point: opening the form

The shared entry point is
[`showAddTaskSheet`](../lib/features/add_task/presentation/add_task_sheet.dart).
It opens `AddTaskScreen` as a modal bottom sheet. Create, edit, and the
Plan-Tomorrow slot flow all use this same form:

- `editArgs == null` means a new task.
- `editArgs` loads and changes an existing task.
- `slotArgs` places a new task directly in a selected routine/block instead of
  choosing the default day plan.

`AddTaskScreen` is intentionally a stateful form. Its fields (title,
duration, reminder time, category, notes, and more) are plain State fields.
Its overridden `setState` marks the form draft as dirty, which drives draft
autosave. Section widgets are presentational: they receive values and send
changes back through callbacks, rather than writing form state themselves.

Useful starting files:

1. `lib/features/add_task/presentation/add_task_sheet.dart`
2. `lib/features/add_task/presentation/add_task_screen.dart`
3. `lib/features/add_task/presentation/sections/`

## 2. Save orchestration in the screen

The save button calls `AddTaskScreen._onSave` in
[`add_task_screen.dart`](../lib/features/add_task/presentation/add_task_screen.dart).
This method is the best breakpoint for following one real task creation.

In order, it:

1. Prevents double saves (`_saving`) and prevents saving an edit before it has
   loaded.
2. Normalizes the title. An empty title becomes `"Untitled Task"`.
3. Checks free-tier limits in `checkAddTaskTierGates`. These checks are
   currently harmless when enforcement is disabled or the user is Pro.
4. Calls `resolveAddTaskSaveTarget` to decide identity and placement.
5. Resolves the effective routine mode.
6. Marshals the form fields into a `PlannedTask`.
7. Performs pre-save overlap/conflict checks.
8. Saves the `PlannedTask` through `planningRepositoryProvider`.
9. Writes related schedule data (a derived time block and, when enabled, a
   reminder), then invokes the schedule mutation coordinator.
10. Deletes the saved form draft and closes the sheet. Errors show
    `"Could not save task: …"` and leave the form open.

### Placement and identity

[`resolveAddTaskSaveTarget`](../lib/features/add_task/application/add_task_save_target.dart)
handles the branches before a task is constructed:

| Situation | Result |
|---|---|
| New task from the normal Add Task sheet | Creates a client-generated `task_*` id and ensures the day has a `Daily plan` routine and `Main` block. |
| New task from a Plan Tomorrow slot | Creates a client-generated id and uses that slot's routine/block. |
| Edit without moving days | Keeps the task id, creation timestamp, routine/block, and order. |
| Edit moved to another day | Deletes the old task, ensures the target day's default plan, then saves it in the new location. |

The model hierarchy is:

```text
Routine (a day)
  └─ TaskBlock (a section within the routine)
      └─ PlannedTask
```

`PlannedTask.planDateKey`, rather than the parent routine alone, is the
authoritative “which day is this task planned for?” value.

## 3. The domain model: `PlannedTask`

[`task_item.dart`](../lib/features/planning/domain/models/task_item.dart)
defines the domain object. It is plain Dart: it knows nothing about Flutter,
Riverpod, Isar, or Firestore.

Important fields to notice:

- `id`: generated on the client, so creation works offline.
- `routineId` and `blockId`: placement in the planning hierarchy.
- `planDateKey`: the task's intended calendar date.
- `createdAtMs` and `updatedAtMs`: timestamps used for creation history and
  sync conflict resolution.
- `orderIndex`: display ordering inside the block.
- `status`: initially `TaskStatus.notStarted`.
- `reminderEnabled` and `reminderTimeIso`: user-facing reminder configuration.

Before persistence, `validate()` rejects missing ids/placement/title, a
duration outside 0–1,440 minutes, invalid priority (must be 1–5), and a
negative sequence index. Validation failure becomes the save screen's error
snackbar because `_onSave` catches it.

## 4. Pre-save guards and related schedule writes

Task saving has a few checks beyond model validation:

- [`add_task_conflict_flow.dart`](../lib/features/add_task/application/add_task_conflict_flow.dart)
  checks whether a scheduled task overlaps habit anchors. The user can change
  the time or explicitly save anyway.
- The same file derives a proposed `ScheduledTimeBlock` for tasks that have a
  focus duration and a valid start time. Minor time conflicts only show a
  notice; more serious conflicts open the resolution sheet.
- After the task itself succeeds, `syncAddTaskTimeBlock` creates, updates, or
  removes that derived time block through `TimeBlockRepository`.
- `persistAddTaskReminder` creates or updates a separate reminder entity if
  the reminder switch is on.
- Finally, `ScheduleMutationCoordinator.run(TaskCreatedMutation(...))`
  triggers the schedule side-effect pipeline: recomputation, notification
  reconciliation, and a schedule-domain event. Its `commitOverride` is empty
  here because the task and its supporting records were already committed.

These related writes follow the same local-first pattern; for example,
`IsarTimeBlockRepository.upsertBlock` writes an Isar row and then queues its
own outbox operation.

## 5. Riverpod: choosing the implementation

The screen does this:

```dart
final planning = ref.read(planningRepositoryProvider);
await planning.upsertTask(task);
```

The provider lives in
[`core/di/providers.dart`](../lib/core/di/providers.dart). It returns an
`IsarPlanningRepository`, typed as the `PlanningRepository` interface:

```text
AddTaskScreen
  → planningRepositoryProvider
      → IsarPlanningRepository(FirestorePlanningRepository(...))
```

This is dependency injection, not a network fetch. The provider uses
`ref.watch(firestoreClientProvider)` so it rebuilds if the signed-in account
changes; that prevents a repository from retaining a Firestore client for the
previous user.

The interface is in
[`planning_repository.dart`](../lib/features/planning/data/planning_repository.dart).
The main implementation is
[`isar_planning_repository.dart`](../lib/features/planning/data/isar_planning_repository.dart).
The wrapped `FirestorePlanningRepository` still exists as the remote-path
implementation, but normal task creation goes through the Isar wrapper.

## 6. Repository write: validate → Isar → outbox

`IsarPlanningRepository.upsertTask` is the central persistence method:

1. Calls `task.validate()`.
2. Uses the supplied id (or creates one defensively).
3. Stamps a fresh `updatedAtMs`.
4. Copies the domain model into an `IsarTask`.
5. Runs `isar.writeTxn`, then `isar.isarTasks.putByTaskId(...)`.
6. Builds the Firestore payload and calls `outboxUpsert`.

The order matters:

```text
Isar transaction succeeds
  → outbox entry is durably saved
  → a background sync attempt starts
```

There is no direct `FirebaseFirestore.set()` in this interaction path. The
outbox helper persists the operation locally, starts
`SyncService.processQueue()` without awaiting it, and retries when connectivity
returns. If sync remains stuck, the app exposes the quiet amber stuck-writes
indicator rather than claiming the task was never saved.

The queued document path is:

```text
users/{uid}/routines/{routineId}/blocks/{blockId}/tasks/{taskId}
```

`updatedAtMs` is essential: the remote merge only accepts a newer remote
version, using whole-document last-write-wins.

## 7. Isar representation

[`isar_task.dart`](../lib/core/local_db/isar_collections/isar_task.dart)
defines the persisted collection row:

```text
PlannedTask (domain object)
  ⇄ IsarTask (database row)
```

`IsarTask.taskId` is a unique indexed business id. Isar also indexes
`routineId`, `blockId`, `planDateKey`, and `updatedAtMs`, which makes the
planning queries and sync merge practical. `IsarTask.id` is merely Isar's
auto-incremented internal primary key; app code identifies a task by
`taskId`.

The collection is registered in
[`isar_schemas.dart`](../lib/core/local_db/isar_collections/isar_schemas.dart).
The generated `isar_task.g.dart` provides Isar's query and collection
extensions. Do not edit that generated file; changing the collection model
requires running `dart run build_runner build`.

## 8. Why the UI updates without refetching

The UI does not wait for Firestore to show the new task. Its reactive read
path begins at the local write:

```text
IsarTask write transaction
  → isarTasks.watchLazy emits
  → _todayRowsWatchStream re-collects task/routine/block rows
  → todayAllTasksRowsProvider emits a new list
  → Home and Tasks Hub rebuild
```

[`planned_task_providers.dart`](../lib/features/planning/application/planned_task_providers.dart)
contains this stream. It watches the task, routine, and block collections,
then calls the repository to collect and prioritize rows. It also re-emits
once per minute so time-dependent ordering (such as “overdue”) can change
without a database write.

This is why there is no “invalidate and refetch after save” step: the local
write itself is the UI update.

## 9. What happens after network sync

The outbox is a push path. The matching pull path is
[`RemoteIsarMerge`](../lib/core/sync/remote_isar_merge.dart):

1. `SyncService` flushes queued writes when it can connect.
2. It also pulls remote planning data in the background.
3. For each task document, it creates `PlannedTask.fromMap`.
4. `_mergeTask` delegates to last-write-wins merge logic.
5. A newer remote task is written into `IsarTask`.
6. The same Isar watchers notify the UI.

So a task created on another device arrives through the exact same UI read
path as a task created on this device. Firestore is never a second rendering
source for user-owned planning data.

## 10. A practical debugger walkthrough

To see the whole flow on a running app:

1. Set a breakpoint in `_onSave` in `add_task_screen.dart`.
2. Add a task with a title, duration, and reminder time.
3. Step into `resolveAddTaskSaveTarget` and inspect the generated task id,
   routine id, block id, and `planDateKey`.
4. Step into `IsarPlanningRepository.upsertTask`. Inspect `stored` and stop
   after `putByTaskId`; this is the moment Isar has the authoritative row.
5. Inspect the queued payload passed to `_enqueueUpsert` / `outboxUpsert`.
   It should use the task path above and include the fresh `updatedAtMs`.
6. Place a breakpoint in `_todayRowsWatchStream`'s `emit` function to see the
   UI read the new local data.
7. With network available, later inspect `SyncService.processQueue` for the
   push and `RemoteIsarMerge._pullRoutinesBlocksTasks` for a pull.

For an offline proof, turn on airplane mode, create a task, close and reopen
the task sheet, and confirm the task remains visible. It should appear
immediately. Restore connectivity afterward; synchronization should occur
silently.

## Suggested reading order

Read these in this sequence and keep the diagram above in mind:

1. `lib/features/add_task/presentation/add_task_sheet.dart`
2. `lib/features/add_task/presentation/add_task_screen.dart` — especially
   `_buildPlannedTask` and `_onSave`
3. `lib/features/add_task/application/add_task_save_target.dart`
4. `lib/features/planning/domain/models/task_item.dart`
5. `lib/core/di/providers.dart`
6. `lib/features/planning/data/planning_repository.dart`
7. `lib/features/planning/data/isar_planning_repository.dart`
8. `lib/core/local_db/isar_collections/isar_task.dart`
9. `lib/core/sync/outbox_writer.dart`
10. `lib/features/planning/application/planned_task_providers.dart`
11. `lib/core/sync/sync_service.dart` and `lib/core/sync/remote_isar_merge.dart`

After that, trace task completion through
`lib/features/planning/application/planned_task_actions.dart`. It reuses the
same repository → Isar → outbox → watcher pattern, but changes a task's
status instead of creating it.
