# Tasks: Isar Local-First Architecture Migration

Based on `prd-isar-local-first-migration.md`

---

## Relevant Files

### New files to create
- `lib/core/local_db/isar_collections/isar_routine.dart` — Isar collection schema for `Routine`
- `lib/core/local_db/isar_collections/isar_block.dart` — Isar collection schema for `TaskBlock`
- `lib/core/local_db/isar_collections/isar_task.dart` — Isar collection schema for `PlannedTask`
- `lib/core/local_db/isar_collections/isar_reminder.dart` — Isar collection schema for `ReminderConfig`
- `lib/core/local_db/isar_collections/isar_goal.dart` — Isar collection schema for `UserGoal`
- `lib/features/planning/data/isar_planning_repository.dart` — Isar-backed implementation of `PlanningRepository`
- `lib/features/reminders/data/isar_reminder_repository.dart` — Isar-backed implementation of `ReminderRepository`
- `lib/features/goals/data/isar_goals_repository.dart` — Isar-backed implementation of `GoalsRepository` (reads only; writes still enqueue via `SyncService`)
- `lib/core/sync/remote_sync_service.dart` — New `syncFromRemote()` logic (pull Firestore → merge into Isar)
- `lib/app/first_launch_gate.dart` — Widget that shows a loading screen on first launch until Isar is seeded

### Files to modify
- `lib/core/offline/offline_store.dart` — Open Isar with all 5 collection schemas in `initialize()`
- `lib/core/di/providers.dart` — Swap `FirestorePlanningRepository` → `IsarPlanningRepository`; add `offlineStoreProvider` export; add `goalsRepositoryProvider` pointing to Isar impl
- `lib/core/sync/sync_service.dart` — Add `syncFromRemote()` delegation, 30s debounce field, and connectivity-restored trigger
- `lib/core/bootstrap/app_bootstrap.dart` — Call `unawaited(syncService.syncFromRemote())` after Isar init; handle first-launch seed gate
- `lib/features/planning/application/planned_task_providers.dart` — Replace `FutureProvider` → `StreamProvider` for `todayAllTasksRowsProvider` and `homeFlowSnapshotProvider`; update `openTasksOutsideTodayProvider` to read Isar
- `lib/features/planning/application/planned_task_collect.dart` — Remove Firestore `GetOptions` dependency; make helpers Isar-compatible
- `lib/features/goals/application/goals_providers.dart` — Update `goalsStreamProvider` to watch Isar instead of Firestore
- `lib/features/reminders/application/reminder_sync_service.dart` — Update `scheduleFromCache()` to read from Isar; deprecate `ReminderCacheStore` usage
- `lib/app/app_lifecycle_task_refresh.dart` — Add `syncFromRemote()` call on app foreground resume
- `lib/app/app.dart` — Wrap app in `FirstLaunchGate` widget
- `lib/features/home/presentation/home_screen.dart` — Update `ref.watch(todayAllTasksRowsProvider)` to consume `StreamProvider` (`.when` instead of `.maybeWhen` if needed)
- `lib/features/tasks_hub/presentation/tasks_hub_screen.dart` — Same provider consumption update
- `lib/features/plan_tomorrow/presentation/plan_tomorrow_screen.dart` — Same provider consumption update
- `pubspec.yaml` — Confirm `isar`, `isar_flutter_libs`, `isar_generator` versions are correct (already present at 3.1.0)

### Test files to create
- `test/core/local_db/isar_task_schema_test.dart` — Verifies `IsarTask` ↔ `PlannedTask` round-trip conversion
- `test/core/local_db/isar_routine_schema_test.dart` — Verifies `IsarRoutine` ↔ `Routine` round-trip
- `test/core/local_db/isar_reminder_schema_test.dart` — Verifies `IsarReminder` ↔ `ReminderConfig` round-trip
- `test/core/local_db/isar_goal_schema_test.dart` — Verifies `IsarGoal` ↔ `UserGoal` round-trip
- `test/features/planning/isar_planning_repository_test.dart` — Unit tests for all `IsarPlanningRepository` methods
- `test/features/reminders/isar_reminder_repository_test.dart` — Unit tests for `IsarReminderRepository`
- `test/features/goals/isar_goals_repository_test.dart` — Unit tests for `IsarGoalsRepository`
- `test/core/sync/remote_sync_service_test.dart` — Tests LWW merge, debounce, and error handling
- `test/features/planning/today_tasks_stream_provider_test.dart` — Tests reactive emission on Isar writes

### Notes
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after adding any Isar `@collection` file to generate the `.g.dart` schema file.
- Isar unit tests can use `Isar.openSync(schemas, directory: Directory.systemTemp.path)` to open an in-memory DB without Flutter binding.
- Use `flutter test` to run tests.
- `GetOptions` from `cloud_firestore` must not appear in any Isar-backed method signatures — remove it when migrating repository methods.

---

## Tasks

- [ ] 1.0 Add Isar schemas for all 5 collections and activate `OfflineStore`
  - [ ] 1.1 Verify `isar: ^3.1.0+1`, `isar_flutter_libs: ^3.1.0+1`, and `isar_generator: ^3.1.0+1` are in `pubspec.yaml` (they already exist — confirm no version conflicts with other packages by running `flutter pub get`)
  - [ ] 1.2 Create `lib/core/local_db/isar_collections/` directory and add a `isar_routine.dart` file with an `@collection IsarRoutine` class mirroring all fields of `Routine` (id auto-increment, `@Index(unique: true)` on `routineId` string, `@Index` on `dateKey`); add `fromDomain(Routine)` factory and `toDomain()` method
  - [ ] 1.3 Create `isar_block.dart` with `@collection IsarBlock` mirroring all fields of `TaskBlock` (`@Index(unique: true)` on `blockId`, `@Index` on `routineId`); add `fromDomain` / `toDomain`
  - [ ] 1.4 Create `isar_task.dart` with `@collection IsarTask` mirroring all fields of `PlannedTask` (`@Index(unique: true)` on `taskId`, `@Index` on `routineId`, `blockId`, `planDateKey`, `updatedAtMs`); add `fromDomain` / `toDomain`; store `TaskStatus` as its `.name` string
  - [ ] 1.5 Create `isar_reminder.dart` with `@collection IsarReminder` mirroring all fields of `ReminderConfig` (`@Index(unique: true)` on `reminderId`, `@Index` on `taskId` and `updatedAtMs`); add `fromDomain` / `toDomain`
  - [ ] 1.6 Create `isar_goal.dart` with `@collection IsarGoal` mirroring all fields of `UserGoal` (`@Index(unique: true)` on `goalId`, `@Index` on `updatedAtMs`); store enum fields (`GoalHorizon`, `GoalStatus`, etc.) as their `storageValue` strings; add `fromDomain` / `toDomain`
  - [ ] 1.7 Run `flutter pub run build_runner build --delete-conflicting-outputs` to generate all `.g.dart` schema files; fix any annotation errors until `build_runner` exits cleanly
  - [ ] 1.8 Update `OfflineStore.initialize()` to open Isar with all five generated schemas: `Isar.open(schemas: [IsarRoutineSchema, IsarBlockSchema, IsarTaskSchema, IsarReminderSchema, IsarGoalSchema], directory: ...)` using `getApplicationDocumentsDirectory()`; assign result to `_isar`; guard against double-init with `if (_isar != null) return`
  - [ ] 1.9 Add `offlineStoreProvider` to `lib/core/di/providers.dart` as `Provider<OfflineStore>((ref) => OfflineStore.instance)` so widgets and repositories can access it via Riverpod

- [ ] 2.0 Implement `IsarPlanningRepository` (Routine, Block, Task) with write-to-Isar-first + sync enqueue
  - [ ] 2.1 Create `lib/features/planning/data/isar_planning_repository.dart`; have it `implement PlanningRepository`; inject `Isar` (via `OfflineStore.instance.isar!`) and keep a reference to `SyncService.instance` for enqueue calls
  - [ ] 2.2 Implement `getRoutinesForDate(String dateKey)` — query `isar.isarRoutines.filter().dateKeyEqualTo(dateKey).findAll()` and map each `IsarRoutine` to `Routine` via `toDomain()`; remove the `GetOptions?` parameter (Isar does not use it)
  - [ ] 2.3 Implement `upsertRoutine(Routine routine)` — `isar.writeTxn(() => isar.isarRoutines.putByIndex('routineId', IsarRoutine.fromDomain(routine)))` then `SyncService.instance.enqueueUpsert(entityType: 'routine', documentPath: FirestorePaths.routines + '/' + routine.id, payload: routine.toMap())`
  - [ ] 2.4 Implement `deleteRoutine(String routineId)` — find by index and delete from Isar, then `SyncService.instance.enqueueDelete(...)`
  - [ ] 2.5 Implement `getBlocks(String routineId)` — query by `routineId` index; map to `TaskBlock`; sort by `orderIndex`
  - [ ] 2.6 Implement `upsertBlock(TaskBlock block)` — write to Isar then enqueue; follow same pattern as `upsertRoutine`
  - [ ] 2.7 Implement `deleteBlock({routineId, blockId})` — delete from Isar then enqueue delete
  - [ ] 2.8 Implement `getTasks({routineId, blockId})` — query by `routineId` + `blockId` compound filter; map to `PlannedTask`; remove `GetOptions?` parameter
  - [ ] 2.9 Implement `upsertTask(PlannedTask task)` — write to Isar then enqueue upsert with correct Firestore path `FirestorePaths.tasks(task.routineId, task.blockId) + '/' + task.id`
  - [ ] 2.10 Implement `deleteTask({routineId, blockId, taskId})` — delete from Isar then enqueue delete
  - [ ] 2.11 Implement `ensureDefaultDayPlan(String dateKey)` — check Isar for existing routine + block first; if not found, create them in Isar (and enqueue to Firestore); return the `({routineId, blockId})` record
  - [ ] 2.12 Keep `logFlowTransitionEvent`, `logAccountability`, `getAccountabilityLogs`, `deleteAccountabilityLog`, `deleteAccountabilityLogsInRange`, `pruneOldAccountabilityLogs`, `exportAccountabilityLogs`, and `getRoutineModeConfigs`/`upsertRoutineModeConfig` delegating to Firestore unchanged (they are out of scope for this phase)
  - [ ] 2.13 Update `planningRepositoryProvider` in `lib/core/di/providers.dart` to return `IsarPlanningRepository(OfflineStore.instance)` instead of `FirestorePlanningRepository`
  - [ ] 2.14 Update `planned_task_collect.dart` — remove `GetOptions?` parameters from `collectTasksForDateKey` and `collectTasksForDateKeyPreferServer`; delete the Firestore-specific try/catch server fallback in `collectTasksForDateKeyPreferServer` (replace with a simple call to `collectTasksForDateKey`)
  - [ ] 2.15 Run `flutter analyze` and fix any errors introduced by removing `GetOptions` parameters

- [ ] 3.0 Replace `todayAllTasksRowsProvider` and `homeFlowSnapshotProvider` with Isar-backed `StreamProvider`s and update all call sites
  - [ ] 3.1 In `planned_task_providers.dart`, replace `todayAllTasksRowsProvider` (`FutureProvider`) with a `StreamProvider<List<PlannedTaskRow>>` that: (a) gets `isar` from `ref.read(offlineStoreProvider).isar!`, (b) builds a query for `IsarTask` filtered by today's `planDateKey`, (c) calls `.watch(fireImmediately: true)` on that query, (d) uses `.asyncMap` to convert each emission into `List<PlannedTaskRow>` by loading the corresponding `IsarRoutine` and `IsarBlock` from Isar
  - [ ] 3.2 Replace `homeFlowSnapshotProvider` (`FutureProvider`) with a `StreamProvider<HomeFlowSnapshot>` that derives its value from the new `todayAllTasksRowsProvider` stream — watch task rows, compute current block label from `TaskBlock` time windows (via a separate Isar query for blocks), count open tasks, pick next task with `NextTaskRanker.chooseNext()`
  - [ ] 3.3 Update `openTasksOutsideTodayProvider` — change from calling `collectTasksForDateKeyPreferServer` (which had Firestore server reads) to calling the plain `collectTasksForDateKey` backed by Isar; it can remain a `FutureProvider` for now
  - [ ] 3.4 Fix `homeFlowSnapshotProvider`'s "active block" label: add a 1-minute `Timer` in `HomeScreen`'s widget state (or use a `StreamProvider` that merges the task stream with a `Stream.periodic(Duration(minutes: 1))` tick) so the block label updates without waiting for a data change
  - [ ] 3.5 Update `HomeScreen` (`home_screen.dart`) — change `ref.watch(todayAllTasksRowsProvider)` to `ref.watch(todayAllTasksRowsProvider)` (the name stays the same; the type changes from `AsyncValue<List>` via `FutureProvider` to `AsyncValue<List>` via `StreamProvider` — the `.when()` call stays identical; no change needed beyond verifying it compiles)
  - [ ] 3.6 Check all other files that use `todayAllTasksRowsProvider` or `homeFlowSnapshotProvider` (`tasks_hub_screen.dart`, `plan_tomorrow_screen.dart`, `notification_response_handler.dart`) and update any `.read(...future)` calls to `.watch(...)` or use the stream's `.future` property appropriately
  - [ ] 3.7 Remove or simplify `invalidateTaskListProviders()` — the stream auto-updates on Isar writes; keep the function but have it only invalidate `openTasksOutsideTodayProvider` and `executionDayTasksProvider` (which are still `FutureProvider`s); remove invalidation of `todayAllTasksRowsProvider` and `homeFlowSnapshotProvider`
  - [ ] 3.8 Run `flutter analyze` and `flutter test` — confirm all existing tests still pass

- [ ] 4.0 Extend `SyncService` with `syncFromRemote()` (LWW merge, 30s debounce) and wire auto-trigger points
  - [ ] 4.1 Create `lib/core/sync/remote_sync_service.dart` with a class `RemoteSyncService` (or add the method directly to `SyncService` if preferred) with a `DateTime? _lastRemoteSyncAt` field and the 30s debounce guard
  - [ ] 4.2 Implement `syncFromRemote()` — fetch Routines for a reasonable date window (e.g. today ±30 days) from Firestore, then for each routine fetch its Blocks, then its Tasks; for each record, compare `updatedAtMs` against the Isar version and write to Isar only if the Firestore record is newer (LWW)
  - [ ] 4.3 Implement the same LWW merge for Reminders — fetch all reminder documents for the current user from `FirestorePaths.reminders` and merge into `IsarReminder`
  - [ ] 4.4 Implement the same LWW merge for Goals — fetch from `FirestorePaths.goals` and merge into `IsarGoal`
  - [ ] 4.5 Add a `ValueNotifier<bool> isSyncingFromRemote = ValueNotifier(false)` to `SyncService` so the UI can observe sync status for the "Sync Now" button
  - [ ] 4.6 In `SyncService.initialize()`, add a call to `unawaited(syncFromRemote())` after loading the offline queue so a non-blocking pull happens at every startup
  - [ ] 4.7 In `SyncService._connectivitySubscription` listener (already exists), add `unawaited(syncFromRemote())` alongside the existing `processQueue()` call so remote pull also triggers when connectivity is restored
  - [ ] 4.8 In `AppLifecycleTaskRefresh.didChangeAppLifecycleState` (on `resumed`), add `SyncService.instance.syncFromRemote()` call after `invalidateTaskListProviders(ref)`

- [ ] 5.0 Implement first-launch Isar seeding with a blocking splash until seeded
  - [ ] 5.1 Create `lib/app/first_launch_gate.dart` — a `ConsumerStatefulWidget` that: (a) checks `shared_preferences` for the `isar_seeded_v1` key in `initState`, (b) if the key is absent/false, shows a full-screen loading indicator while awaiting `SyncService.instance.syncFromRemote()`, then sets the key to `true` and shows `child`, (c) if the key is already `true`, renders `child` immediately
  - [ ] 5.2 Handle the failure case in `FirstLaunchGate` — if `syncFromRemote()` throws (e.g. no network on a brand-new install), log the error, do NOT set the `isar_seeded_v1` flag, and proceed to show `child` anyway so the user is not stuck on a loading screen forever
  - [ ] 5.3 Wrap `CoachForLifeApp` with `FirstLaunchGate` in `lib/app/app.dart` (or in `main.dart` inside `UncontrolledProviderScope`); ensure `OfflineStore` is already initialized before `FirstLaunchGate` runs (it is, because `AppBootstrap.initialize` runs before `runApp`)
  - [ ] 5.4 Add a `shared_preferences` import to `pubspec.yaml` if not already present (it is — check); add the `isar_seeded_v1` key constant to a constants file or directly in `FirstLaunchGate`

- [ ] 6.0 Migrate `ReminderRepository` and `GoalsRepository` to Isar; retire `ReminderCacheStore`
  - [ ] 6.1 Create `lib/features/reminders/data/isar_reminder_repository.dart` implementing `ReminderRepository`; `getRemindersForTasks(List<String> taskIds)` queries `isar.isarReminders.filter()` with a `taskIdIn(taskIds)` filter; `upsertReminder(ReminderConfig r)` writes to Isar then enqueues to `SyncService`
  - [ ] 6.2 Update `reminderRepositoryProvider` in `providers.dart` to return `IsarReminderRepository(OfflineStore.instance)` instead of `FirestoreReminderRepository`
  - [ ] 6.3 Update `ReminderSyncService.scheduleFromCache()` — replace `_cacheStore.load()` with a direct Isar query for all enabled reminders (`isar.isarReminders.filter().enabledEqualTo(true).findAll()`); the method signature stays the same
  - [ ] 6.4 Update `ReminderSyncService.syncForTaskIds()` — after the Firestore fetch, write results to Isar (via `upsertReminder`) and remove the separate `_cacheStore.save()` call; `ReminderCacheStore` is now only used as a fallback shim during the transition
  - [ ] 6.5 Update `ReminderSyncService._resolveReminder()` and `requestSnooze()` — after updating the in-memory list, call `IsarReminderRepository.upsertReminder()` instead of (or in addition to) `_cacheStore.save()` to keep Isar authoritative
  - [ ] 6.6 Create `lib/features/goals/data/isar_goals_repository.dart` implementing `GoalsRepository`; `watchGoals()` returns an Isar watch stream on `IsarGoal` ordered by `updatedAtMs` descending; `fetchGoalsOnce()` queries Isar directly; all write methods (`upsertGoal`, `deleteGoal`, etc.) still enqueue to Firestore via `SyncService` AND write to Isar first
  - [ ] 6.7 Update `goalsRepositoryProvider` in `goals_providers.dart` to return `IsarGoalsRepository(OfflineStore.instance)` instead of `FirestoreGoalsRepository`
  - [ ] 6.8 Since `goalsStreamProvider` already uses `StreamProvider` backed by `watchGoals()`, it will automatically become Isar-backed once `goalsRepositoryProvider` is updated — verify it works by confirming the goals screen shows data without a network request
  - [ ] 6.9 Mark `ReminderCacheStore` as deprecated with a `@Deprecated` annotation and a comment explaining it is kept only for transition safety; do not delete it yet

- [ ] 7.0 Add "Sync Now" UI affordance with loading state
  - [ ] 7.1 Add a sync status indicator to `HomeScreen`'s `AppBar` — use a `ValueListenableBuilder` watching `SyncService.instance.isSyncingFromRemote` to show either a small `CircularProgressIndicator` (while syncing) or a tappable `Icon(Icons.sync)` button (when idle)
  - [ ] 7.2 When the sync icon is tapped, call `SyncService.instance.syncFromRemote()` (the 30s debounce inside the method ensures it won't spam Firestore); use `unawaited()` since the `ValueNotifier` drives the UI state
  - [ ] 7.3 Show a brief `SnackBar` when `isSyncingFromRemote` transitions from `true` → `false` to confirm sync completion (optional but improves user confidence)

- [ ] 8.0 Write unit and integration tests for all migrated repositories, stream providers, and sync service
  - [ ] 8.1 Create `test/core/local_db/isar_task_schema_test.dart` — test that `IsarTask.fromDomain(task).toDomain()` round-trips all fields correctly including `TaskStatus`, nullable fields (`planDateKey`, `modeRefId`), and boundary values
  - [ ] 8.2 Create similar round-trip tests for `IsarRoutine`, `IsarBlock`, `IsarReminder`, and `IsarGoal` in their respective test files; pay special attention to enum storage (e.g. `GoalHorizon`, `RoutineMode`)
  - [ ] 8.3 Create `test/features/planning/isar_planning_repository_test.dart` — open an in-memory Isar instance in `setUp`; test `upsertTask` writes to Isar and calls `SyncService.enqueueUpsert`; test `getTasks` returns correct rows; test `deleteTask` removes from Isar and enqueues delete; use a fake `SyncService` to capture enqueue calls
  - [ ] 8.4 Create `test/features/reminders/isar_reminder_repository_test.dart` — test `getRemindersForTasks` filters by `taskId`; test `upsertReminder` writes to Isar and enqueues
  - [ ] 8.5 Create `test/features/goals/isar_goals_repository_test.dart` — test `watchGoals()` emits a new list when a goal is upserted; test `fetchGoalsOnce()` returns correct data; test `upsertGoal` writes to Isar and enqueues to Firestore
  - [ ] 8.6 Create `test/core/sync/remote_sync_service_test.dart` — use a fake Firestore stub and a real in-memory Isar; test that `syncFromRemote()` writes Firestore records into Isar; test LWW: a record with older `updatedAtMs` from Firestore must NOT overwrite the newer Isar record; test the 30s debounce (call `syncFromRemote()` twice within 30s, verify Firestore is only hit once)
  - [ ] 8.7 Create `test/features/planning/today_tasks_stream_provider_test.dart` — use `ProviderContainer` with overridden `offlineStoreProvider` pointing to in-memory Isar; verify that `todayAllTasksRowsProvider` emits an updated list when a task is upserted into Isar
  - [ ] 8.8 Run `flutter analyze` on the full project — fix any remaining warnings or errors
  - [ ] 8.9 Run `flutter test` — all 23 existing tests plus the new tests must pass
