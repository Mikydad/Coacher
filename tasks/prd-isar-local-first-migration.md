# PRD: Isar Local-First Architecture Migration

**Feature:** Local-first data layer using Isar as primary storage  
**Status:** Draft  
**Date:** 2026-04-01  
**Target Reader:** Junior/Mid Flutter Developer

---

## 1. Introduction / Overview

### Problem

The app currently reads all data directly from Firestore before rendering anything on screen. This means:

- The Home screen, task list, and reminder flow all **block on a network request** before showing data.
- On slow or no connectivity, screens appear empty or show loading spinners.
- Every app resume triggers a full Firestore re-fetch, which wastes bandwidth and slows the UI.

### Goal

Migrate the app to a **local-first architecture** where:

1. **Isar** (an embedded NoSQL database) is the **single source of truth** for reads.
2. **Firestore** is used only as a background sync layer — no UI code reads from it directly.
3. All writes go to Isar first (instant), then are queued for Firestore sync.
4. The UI updates reactively via Isar's stream/watch API — no manual `invalidate()` or re-fetch needed.

This means the app works seamlessly offline and **feels instant** on every screen load.

---

## 2. Goals

1. **Instant UI rendering** — task list, home snapshot, and reminder state load from Isar with zero network dependency.
2. **Reactive updates** — changing a task (e.g., marking complete) immediately updates every screen that shows it, via Isar's reactive streams.
3. **Correct multi-device sync** — Firestore remains the source of truth for cross-device consistency; Isar is a local cache that is kept in sync.
4. **First-launch data migration** — on first open of the migrated app, all existing Firestore data is pulled into Isar.
5. **No regressions** — notification tap flow, reminder scheduling, timer sessions, and scoring continue to work correctly.
6. **Full test coverage** — all migrated repositories and key providers are covered by unit and integration tests.

---

## 3. User Stories

| # | As a… | I want… | So that… |
|---|---|---|---|
| 1 | User | the task list to appear instantly when I open the app | I don't have to wait for network data |
| 2 | User | changes I make (add task, mark done) to appear immediately in the UI | the app feels responsive even on slow internet |
| 3 | User | my data to sync across my devices automatically | my phone and tablet always show the same plan |
| 4 | User | a "Sync Now" button when I want to force-pull the latest data | I can manually refresh if something looks out of date |
| 5 | User | my app to work offline | I can still view and edit tasks without internet |
| 6 | Developer | all reads to come from Isar | no screen needs to know about Firestore |
| 7 | Developer | the sync layer to handle conflicts automatically | I don't need to write merge logic in every feature |

---

## 4. Functional Requirements

### 4.1 Isar Collections

The following domain models must have corresponding Isar collection schemas (annotated with `@collection`):

| Domain Model | Isar Collection Name | Key Indexed Fields |
|---|---|---|
| `Routine` | `IsarRoutine` | `id`, `dateKey` |
| `TaskBlock` | `IsarBlock` | `id`, `routineId` |
| `PlannedTask` | `IsarTask` | `id`, `routineId`, `blockId`, `planDateKey`, `updatedAtMs` |
| `ReminderConfig` | `IsarReminder` | `id`, `taskId`, `updatedAtMs` |
| `UserGoal` | `IsarGoal` | `id`, `updatedAtMs` |

**Requirements:**
- FR-1: Each Isar collection must mirror all fields of its corresponding domain model.
- FR-2: Isar uses `int` auto-increment as its internal primary key; the app's string `id` field must be stored as a separate indexed string field and used for all lookups.
- FR-3: `OfflineStore` must be updated to open Isar with all five collection schemas on first `initialize()` call.
- FR-4: Isar collection classes must be generated via `build_runner` (`isar_generator`).

> **Out of scope this phase:** `TimerSession`, `TaskScore`, `AccountabilityLog` — these remain Firestore-only.

---

### 4.2 Repository Refactoring — Write Path

For every **write** in the five in-scope collections:

- FR-5: Write to Isar first (synchronous from the caller's perspective — no waiting for Firestore).
- FR-6: After the Isar write, call `SyncService.enqueueUpsert(...)` with the same payload to queue the Firestore sync.
- FR-7: The UI **must not** wait for the Firestore sync to complete before updating.
- FR-8: No UI code or provider may call `FirebaseFirestore` directly for reads or writes on these five collections.

**Example write flow (task creation):**

```
AddTaskScreen.save()
  → IsarPlanningRepository.upsertTask(task)
      → isar.writeTxn(() => isarTasks.put(IsarTask.fromDomain(task)))  ← instant
      → SyncService.enqueueUpsert(entityType: 'task', path: ..., payload: task.toMap())
  → Isar stream emits change
  → todayTasksStreamProvider rebuilds automatically
```

---

### 4.3 Repository Refactoring — Read Path

- FR-9: All reads for Routine, Block, Task, Reminder, and Goal must come from Isar, not Firestore.
- FR-10: `PlanningRepository.getTasks()`, `getBlocks()`, and `getRoutinesForDate()` must return data from Isar.
- FR-11: `ReminderRepository.getRemindersForTasks()` must return data from Isar.
- FR-12: `GoalsRepository.fetchGoalsOnce()` must return data from Isar (with a background Firestore pull happening in parallel on first launch).

---

### 4.4 Reactive Providers — StreamProvider Migration

The following `FutureProvider`s must be replaced with `StreamProvider`s backed by Isar's watch streams:

| Current Provider | New Provider Type | Source |
|---|---|---|
| `todayAllTasksRowsProvider` | `StreamProvider<List<PlannedTaskRow>>` | Isar watch on `IsarTask` filtered by today's `planDateKey` |
| `homeFlowSnapshotProvider` | `StreamProvider<HomeFlowSnapshot>` | Derived from the task stream above |

- FR-13: The stream must emit a new list whenever any task in today's plan is added, updated, or deleted in Isar.
- FR-14: `invalidateTaskListProviders()` should be removed or reduced — the stream auto-updates so manual invalidation is no longer needed for normal flows. Manual invalidation is still acceptable as a fallback for the force-sync path.
- FR-15: `openTasksOutsideTodayProvider` may remain a `FutureProvider` for now (outside scope) but must read from Isar, not Firestore.

---

### 4.5 Background Sync — Pull from Firestore

#### 4.5.1 Automatic Pull Triggers

The `SyncService` must be extended with a `syncFromRemote()` method that:

- FR-16: Fetches all Routines, Blocks, Tasks, Reminders, and Goals from Firestore for the authenticated user.
- FR-17: Merges each record into Isar using **last-write-wins**: if the incoming Firestore record has a higher `updatedAtMs` than the local Isar record, overwrite it. Otherwise, keep the local version.
- FR-18: Does **not** delete local Isar records that are missing from Firestore (they may be pending sync).
- FR-19: `syncFromRemote()` must be called:
  - Non-blocking at **app startup** (after Isar is initialized, before `runApp` returns, but not awaited in the main thread — use `unawaited()`).
  - When **connectivity is restored** (reuse the existing `onConnectivityChanged` listener in `SyncService`).
  - When the **app comes to foreground** (in `AppLifecycleTaskRefresh.didChangeAppLifecycleState` on `resumed`).

#### 4.5.2 Manual Force Sync

- FR-20: A "Sync Now" button (or similar UI affordance — the exact location is a design decision for the implementing developer) must trigger `syncFromRemote()`.
- FR-21: While `syncFromRemote()` is running, the button must show a loading indicator and be disabled.
- FR-22: `syncFromRemote()` must be debounced — calling it again within 30 seconds of the previous call should be a no-op (returns immediately) to prevent Firestore spam.

---

### 4.6 First-Launch Data Migration

- FR-23: On the **first launch** of the migrated app (detected via a flag stored in `shared_preferences`, e.g., `isar_seeded_v1`), the app must call `syncFromRemote()` and await its completion before showing the main UI (a simple full-screen loading state is acceptable).
- FR-24: After the seed completes successfully, set the `isar_seeded_v1` flag to `true` so subsequent launches skip the blocking seed.
- FR-25: If the seed fails (network error), the app should show the main UI with whatever is in Isar (which may be empty on a clean install) and retry the seed in the background.

---

### 4.7 Existing Feature Compatibility

The following flows must continue to work after the migration:

- FR-26: **Notification tap flow** — `handleNotificationResponse` looks up the task by ID. This lookup must now read from Isar (via `todayAllTasksRowsProvider` or a direct Isar query).
- FR-27: **Reminder scheduling** — `ReminderSyncService.scheduleFromCache()` reads from `ReminderCacheStore` (shared_preferences). This should be updated to read from Isar instead, making `ReminderCacheStore` a thin compatibility shim or removing it entirely.
- FR-28: **Timer session persistence** — `ExecutionController.stopAndPersist()` writes to `FirestoreExecutionRepository`. This remains unchanged (sessions are out of scope).
- FR-29: **Scoring flow** — `ScoringController.submit()` writes to `FirestoreScoringRepository`. Remains unchanged (scores are out of scope).
- FR-30: **`AppLifecycleTaskRefresh`** — the `invalidateTaskListProviders()` call on `resumed` can remain for now but should also trigger `syncFromRemote()` (which handles the Firestore pull).

---

### 4.8 Write Consistency Rules

- FR-31: No code in `lib/features/` or `lib/app/` may import `cloud_firestore` directly for the five in-scope collections. All Firestore access must go through the `SyncService` queue.
- FR-32: Every `upsertTask`, `upsertRoutine`, `upsertBlock`, `upsertReminder`, `upsertGoal` must follow the pattern: **Isar first, then enqueue**.
- FR-33: All domain model string IDs must be preserved identically in both Isar and Firestore. IDs are generated once (via `StableId.generate(...)`) and never changed.

---

## 5. Non-Goals (Out of Scope)

- **TimerSession, TaskScore, AccountabilityLog** — these will not be migrated to Isar in this phase and will continue to read/write Firestore directly.
- **Isar encryption** — data at rest will not be encrypted in this phase.
- **Sync conflict UI** — users will not be prompted to resolve conflicts. Last-write-wins is sufficient for V1.
- **Full offline Firestore replacement** — Firestore remains the long-term persistence and cross-device sync layer; Isar is purely a local cache/read store.
- **push notifications from Firestore** (e.g., FCM) — not part of this migration.
- **Pagination** — all data is fetched in full for now; no cursor-based pagination for Isar queries.

---

## 6. Design Considerations

### UI Changes

- The task list and home screen will no longer show a loading spinner on subsequent launches (data is already in Isar). A skeleton/shimmer may be shown only on the very first cold launch.
- The "Sync Now" button placement is left to the developer's discretion. Suggested locations: Settings screen, or a subtle sync status icon in the AppBar.
- While `syncFromRemote()` runs, a non-intrusive progress indicator (e.g., a thin linear progress bar at the top) is preferred over a full-screen loading overlay (except during first-launch seeding).

### Stream vs Future

- `StreamProvider` requires `ref.watch()`, not `ref.read()`, to listen to updates. Any screen currently using `.read(todayAllTasksRowsProvider.future)` must be updated to `.watch(todayAllTasksStreamProvider)`.
- Isar's `watchLazy()` returns a `Stream<void>` (triggers on any collection change). Combine with a query to produce `Stream<List<T>>`.

---

## 7. Technical Considerations

### Isar Setup

- `isar`, `isar_flutter_libs`, and `isar_generator` must be added to `pubspec.yaml` (if not already present — `isar` is already imported in `offline_store.dart` but not yet initialized with schemas).
- Run `flutter pub run build_runner build --delete-conflicting-outputs` to generate `.g.dart` files.
- `OfflineStore.initialize()` must open Isar with a list of all five schemas: `[IsarRoutineSchema, IsarBlockSchema, IsarTaskSchema, IsarReminderSchema, IsarGoalSchema]`.

### Isar Collection Design Pattern

Each Isar collection class should:
1. Use `@collection` annotation.
2. Have an `int id = Isar.autoIncrement` field as the internal Isar primary key.
3. Have a `@Index(unique: true)` on the domain `String id` field.
4. Provide `fromDomain(DomainModel m)` factory and `toDomain()` method for conversion.

Example skeleton:
```dart
@collection
class IsarTask {
  int id = Isar.autoIncrement;

  @Index(unique: true)
  late String taskId;  // = PlannedTask.id

  late String routineId;
  late String blockId;
  late String title;
  // ... all other fields
  late int updatedAtMs;

  static IsarTask fromDomain(PlannedTask t) => IsarTask()
    ..taskId = t.id
    ..routineId = t.routineId
    // ...
    ..updatedAtMs = t.updatedAtMs;

  PlannedTask toDomain() => PlannedTask(id: taskId, routineId: routineId, /* ... */);
}
```

### Repository Pattern

Keep the existing abstract `PlanningRepository` interface unchanged. Create a new `IsarPlanningRepository` that implements it. Update the DI provider in `providers.dart` to wire `IsarPlanningRepository` instead of `FirestorePlanningRepository`. The `FirestorePlanningRepository` can remain for write-through via `SyncService`.

### Stream Provider Pattern

```dart
final todayTasksStreamProvider = StreamProvider<List<PlannedTaskRow>>((ref) {
  final isar = ref.read(offlineStoreProvider).isar!;
  final dateKey = DateKeys.todayKey();
  return isar.isarTasks
    .filter()
    .planDateKeyEqualTo(dateKey)
    .build()
    .watch(fireImmediately: true)
    .asyncMap((tasks) async {
      // group tasks into PlannedTaskRows by looking up routines/blocks from Isar
      return _buildRows(tasks, isar);
    });
});
```

### Conflict Resolution (Last-Write-Wins)

```dart
if (firestoreRecord.updatedAtMs > localRecord.updatedAtMs) {
  await isar.writeTxn(() => collection.put(IsarX.fromMap(firestoreRecord)));
}
// else: local is newer, keep it; Firestore will be updated by SyncService queue
```

### SyncService Debounce

```dart
DateTime? _lastRemoteSyncAt;

Future<void> syncFromRemote() async {
  final now = DateTime.now();
  if (_lastRemoteSyncAt != null &&
      now.difference(_lastRemoteSyncAt!).inSeconds < 30) return;
  _lastRemoteSyncAt = now;
  // ... pull from Firestore and merge into Isar
}
```

---

## 8. Implementation Sequence

The migration must be implemented in this order to minimise breakage:

| Phase | Deliverable |
|---|---|
| **Phase 1** | Add Isar dependencies and generate schemas for all 5 collections. Update `OfflineStore.initialize()` to open Isar. |
| **Phase 2** | Implement `IsarPlanningRepository` (write to Isar + enqueue sync). Wire it in DI. Verify existing tests still pass. |
| **Phase 3** | Replace `todayAllTasksRowsProvider` and `homeFlowSnapshotProvider` with `StreamProvider`s backed by Isar. Update all call sites from `.read(...future)` → `.watch(...)`. |
| **Phase 4** | Implement `SyncService.syncFromRemote()` with LWW merge and 30s debounce. Wire up app-startup, foreground, and connectivity triggers. |
| **Phase 5** | Implement first-launch seeding (check `isar_seeded_v1` flag, block on seed, then show UI). |
| **Phase 6** | Migrate `ReminderRepository` and `GoalsRepository` to Isar. Update `ReminderSyncService` to read from Isar instead of `ReminderCacheStore`. |
| **Phase 7** | Add "Sync Now" UI affordance with loading state. |
| **Phase 8** | Write unit + integration tests for all migrated repositories, the stream providers, and the sync service. |

> Start with **Phase 1 → 2 → 3** as the first working milestone (one complete end-to-end flow: task creation → instant UI update → background Firestore enqueue).

---

## 9. Success Metrics

| Metric | Target |
|---|---|
| Home screen time-to-content on warm launch (Isar populated) | < 200ms (no loading spinner) |
| Task list visible after airplane mode toggle | Yes — loads from Isar |
| Write → UI update latency | < 50ms (Isar write + stream emit) |
| No Firestore reads in widget build methods | 0 (verified by code review) |
| All migrated repository methods covered by tests | 100% |
| Multi-device sync (edit on device A, view on device B) | Visible within ~30s of connectivity |
| Force sync debounce prevents Firestore spam | ≥ 30s between remote sync calls |

---

## 10. Open Questions

| # | Question | Owner |
|---|---|---|
| OQ-1 | Should `ReminderCacheStore` (shared_preferences) be removed once Isar is the source of truth for reminders, or kept as a fast-access index? | Tech lead |
| OQ-2 | `openTasksOutsideTodayProvider` fetches tasks for ±7–14 days from Firestore. Should this also read from Isar after the migration (requiring seeding all days), or remain Firestore-backed for now? | Tech lead |
| OQ-3 | `homeFlowSnapshotProvider` currently computes `currentBlockLabel` from real-time clock. Isar streams fire on data change, not on time tick. How should the "active block" label refresh every minute? (Suggest: keep a 1-minute `Timer` in the widget that re-queries Isar or just re-derives the label from the cached data without a full re-fetch.) | Developer |
| OQ-4 | Are `GoalAction`, `GoalMilestone`, and `GoalCheckIn` also in scope for Isar migration, or just the top-level `UserGoal`? | Product |
| OQ-5 | Should `IsarPlanningRepository` and `FirestorePlanningRepository` be merged into a single `HybridPlanningRepository`, or kept as two distinct classes? | Developer preference |
