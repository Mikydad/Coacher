# PRD: Phase 1-B — Notification Ledger + AI Executor Hardening

**Branch:** `platform-refactor`
**Status:** Draft
**Relates to:** `PRD/Platform_Refactor/Runtime_Consolidation_and_Platform_Stabilization.md` — Phase 1, Tasks 4–5
**Depends on:** PRD Phase 1-A (ScheduleMutationCoordinator + Domain Event System + Unified Recompute Graph) should land first

---

## 1. Introduction / Overview

### The problem

#### Notification Ledger

`AttentionOrchestratorService` holds two critical state maps in memory:

```dart
final Map<String, int>  _activeNotificationIds = {};  // entityId → OS notif ID
final Map<String, int>  _ignoredCountByEntity   = {};  // for escalation
final Map<String, List<int>> _snoozeTimestampsMs = {};  // snooze pattern detection
```

These are **in-memory only**. When the app is killed, restarted, or the OS reclaims the process:

- We have no record of which notifications are currently shown in the OS tray.
- We cannot reconcile "should I cancel this reminder?" on boot.
- Snooze counts reset, so escalation logic starts from zero every cold start.
- If the app crashes mid-delivery, no retry or deduplication is possible.
- A new device sign-in cannot recover which reminders were already delivered.


This is the **notification integrity gap** described in the Runtime Consolidation PRD.

#### AI Executor Hardening

`AiActionExecutor.execute()` processes a list of `AiAction`s in a simple for-loop:

```dart
for (final action in actions) {
  try {
    final message = await _dispatch(action);
    successes.add(message);
  } catch (e) {
    failures.add('${_humanLabel(action)}: ${e.toString()}');
  }
}
```

Problems:
- **No atomicity**: if action 3 of 5 fails, actions 1–2 are already written and there is no rollback. The schedule is left in a partial state.
- **No undo**: once the AI moves tasks, there is no way to revert.
- **No intent persistence**: the list of pending AI actions is not saved. If the app is killed while executing, the state is unknown.
- **No idempotency key**: retrying a failed batch can create duplicate tasks.
- **Post-execution refresh is too broad**: after any AI action, all task providers are invalidated regardless of what changed.

After Phase 1-A, the coordinator will handle some of this (atomic writes, recompute), but the AI executor still needs its own hardening: intent persistence, rollback capability, and partial-failure recovery.

### The solution (this PRD)

1. **`NotificationLedger`** — an Isar-backed record of every notification state: scheduled, delivered, cancelled, snoozed, ignored. Replaces the in-memory maps in `AttentionOrchestratorService`. Enables boot-time reconciliation, deduplication, and future per-device sync.
2. **AI Executor Hardening** — introduce `AiActionBatch`: a persisted Isar record representing a group of AI actions with lifecycle states (pending → executing → completed / partial_failure / rolled_back). Add rollback capability for supported mutation types. Build undo infrastructure on top of the Phase 1-A coordinator.

---

## 2. Goals

- G1: Notification state survives app restart — no phantom notifications, no missed cancellations after boot.
- G2: Boot-time reconciliation: on startup, compare OS tray (via `getActiveNotifications()`) with the ledger and cancel any stale entries.
- G3: AI batch mutations are atomic or rollback-capable: if the batch partially fails, all completed steps are either reverted or clearly flagged to the user.
- G4: Undo is available for the most recent AI batch action.
- G5: Idempotent AI action retry: re-executing the same batch does not create duplicates.
- G6: Execution history is queryable: the user (and AI) can see what the AI changed in the last N sessions.

---

## 3. User Stories

- **As a user** who dismissed an app notification and reopened the app, I do not want to see the same notification re-appear because the app forgot it was already dismissed.
- **As a user** who said "Yes, apply" to an AI that moved 5 tasks, and then realized it moved the wrong ones, I want an "Undo AI changes" action that restores my schedule.
- **As a developer** debugging a notification issue, I want to query the ledger and see every notification's full lifecycle: when it was scheduled, when the OS delivered it, when the user interacted, when it was cancelled.
- **As a user** whose phone was locked when the AI was applying changes and the app was killed mid-way, I want the app to recover gracefully on next open — either completing or reverting the partial batch, not leaving a corrupted state.

---

## 4. Functional Requirements

### FR-4.1: NotificationLedger — Isar model

1. The system must define a `NotificationLedgerEntry` Isar entity with the following fields:

   | Field | Type | Description |
   |---|---|---|
   | `id` | `int` (Isar auto) | Isar row id |
   | `notifId` | `int` | OS notification ID |
   | `entityId` | `String` | Task/goal/reminder entity being tracked |
   | `entityKind` | `String` | `'task'`, `'goal'`, `'reminder'` |
   | `state` | `NotificationLedgerState` (enum) | `scheduled`, `delivered`, `cancelled`, `snoozed`, `ignored`, `expired` |
   | `scheduledForMs` | `int?` | Epoch ms when notification was scheduled to fire |
   | `deliveredAtMs` | `int?` | Epoch ms of confirmed delivery |
   | `cancelledAtMs` | `int?` | Epoch ms of cancellation |
   | `snoozedUntilMs` | `int?` | If snoozed, when to re-deliver |
   | `snoozeCount` | `int` | Total snoozes for this entity in current session |
   | `ignoredCount` | `int` | Consecutive ignores since last positive interaction |
   | `interactionType` | `String?` | Last user interaction: `'opened'`, `'dismissed'`, `'snoozed'` |
   | `interactedAtMs` | `int?` | Epoch ms of last interaction |
   | `sourceContext` | `String` | Which service scheduled this: `'attention_orchestrator'`, `'goal_reminder_sync'` |
   | `updatedAtMs` | `int` | LWW field for future sync |

2. `NotificationLedgerState` must be a Dart enum with values: `scheduled`, `delivered`, `cancelled`, `snoozed`, `ignored`, `expired`.

3. `NotificationLedgerEntry` must be indexed on: `entityId`, `notifId`, `state`, `scheduledForMs`.

### FR-4.2: NotificationLedgerRepository

4. The system must define a `NotificationLedgerRepository` with the following methods:
   - `Future<void> upsertEntry(NotificationLedgerEntry entry)` — write or update.
   - `Future<NotificationLedgerEntry?> findByNotifId(int notifId)` — used when an OS callback fires.
   - `Future<NotificationLedgerEntry?> findByEntityId(String entityId)` — used for reconciliation.
   - `Future<List<NotificationLedgerEntry>> getByState(NotificationLedgerState state)` — used for boot reconciliation.
   - `Future<void> markCancelled(String entityId)` — called when a notification is cancelled.
   - `Future<void> markDelivered(int notifId)` — called when OS confirms delivery (via callback).
   - `Future<void> markInteraction(int notifId, String interactionType)` — called in `NotificationInteractionType` handler.
   - `Future<void> pruneOlderThan(Duration age)` — routine cleanup; prune entries older than 72 hours.

### FR-4.3: AttentionOrchestratorService migration

5. `AttentionOrchestratorService` must be refactored to replace all three in-memory maps (`_activeNotificationIds`, `_snoozeTimestampsMs`, `_ignoredCountByEntity`) with reads/writes to `NotificationLedgerRepository`.
6. The migration must be backward-compatible: on first launch after the upgrade, the in-memory state may be empty (ledger is fresh). This is acceptable; the ledger will populate on first interactions.
7. The `evaluate()` method must write a `scheduled` ledger entry after scheduling an OS notification.
8. The `cancel()` method must write a `cancelled` ledger entry after cancelling an OS notification.
9. The notification interaction handler (called from `LocalNotificationsService.onDidReceiveNotification`) must write `delivered` / `snoozed` / `ignored` / `opened` states to the ledger.

### FR-4.4: Boot reconciliation

10. The system must implement a `NotificationReconciliationService` that runs once on each app cold start (called from app bootstrap, after Isar is opened).
11. `NotificationReconciliationService.reconcile()` must:
    1. Call `FlutterLocalNotificationsPlugin.getActiveNotifications()` to get OS tray state.
    2. Query the ledger for entries in state `scheduled` or `delivered`.
    3. For each ledger entry in `scheduled` / `delivered` that is NOT in the OS tray: mark the ledger entry as `cancelled` (app was killed, OS dismissed it) and call `AttentionOrchestratorService` to re-evaluate if re-delivery is appropriate.
    4. For each OS tray notification that is NOT in the ledger: cancel it (unknown phantom notification).
12. Reconciliation must run asynchronously — it must not block the app launch.

### FR-4.5: AiActionBatch — Isar model

13. The system must define an `AiActionBatch` Isar entity:

   | Field | Type | Description |
   |---|---|---|
   | `id` | `int` (Isar auto) | |
   | `batchId` | `String` | UUID, idempotency key |
   | `state` | `AiActionBatchState` (enum) | `pending`, `executing`, `completed`, `partial_failure`, `rolled_back` |
   | `actionsJson` | `String` | JSON serialisation of the full `List<AiAction>` |
   | `snapshotJson` | `String` | JSON snapshot of affected entities *before* mutations (rollback payload) |
   | `succeededActionIds` | `List<String>` | Action IDs that succeeded |
   | `failedActionIds` | `List<String>` | Action IDs that failed |
   | `undoneAtMs` | `int?` | Epoch ms if rolled back |
   | `createdAtMs` | `int` | |
   | `updatedAtMs` | `int` | LWW |

14. `AiActionBatchState` enum: `pending`, `executing`, `completed`, `partial_failure`, `rolled_back`.

### FR-4.6: AiActionExecutor hardening

15. Before executing, `AiActionExecutor` must:
    1. Generate a `batchId` UUID for the batch.
    2. Persist an `AiActionBatch` with state `pending` and a snapshot of all entities that will be affected.
    3. Transition state to `executing`.

16. After executing, `AiActionExecutor` must:
    1. Record which action IDs succeeded and which failed.
    2. Transition batch state to `completed` if all succeeded, or `partial_failure` if any failed.

17. If `partial_failure` is detected:
    1. The executor must call `rollbackBatch(batchId)` which restores all succeeded entities from the snapshot.
    2. The batch state transitions to `rolled_back`.
    3. The user must be shown a clear error message in the AI chat: "I couldn't complete all steps — I've restored your schedule to its previous state."

18. `AiActionExecutor` must reject a batch whose `batchId` already exists in state `completed` (idempotency guard).

19. The snapshot must include a minimal diff — the pre-mutation state of each affected `PlannedTask`, `ScheduledTimeBlock`, and `Reminder` entity. It does not need to snapshot analytics or coaching data.

### FR-4.7: Undo API

20. The system must expose an `undoLastAiBatch()` method (callable from the AI chat screen) that:
    1. Finds the most recent `AiActionBatch` in state `completed` or `partial_failure`.
    2. Restores all entities from `snapshotJson`.
    3. Calls `ScheduleMutationCoordinator` (from Phase 1-A) to trigger appropriate recomputes after restoration.
    4. Transitions the batch state to `rolled_back`.
21. Undo must only be available for the **most recent** batch (no multi-level undo in this phase).
22. Undo is not available if the batch is older than **30 minutes** (staleness guard — schedule has likely evolved).

### FR-4.8: AI action history

23. The AI assistant screen must surface a "Recent AI changes" entry point (a small chip below the last AI message or a dedicated section) that shows the last 5 `AiActionBatch` records with: timestamp, number of actions, batch state.
24. Each batch in history must show an "Undo" button if the batch is the most recent and within 30 minutes.

---

## 5. Non-Goals (Out of Scope for this PRD)

- Multi-device notification sync (ledger is device-local in this phase; `updatedAtMs` field prepares for future sync).
- Rich OS notification grouping / summary notifications — current delivery model unchanged.
- Multi-level undo (only most-recent batch undo in this phase).
- Undo for AI read-only actions (`suggestFreeTimeBlock`, `moveConflictingTasks`).
- AI batch analytics / learning from past actions.

---

## 6. Design Considerations

### Module layout

```
lib/core/runtime/
  (Phase 1-A files)

lib/core/notifications/
  notification_ledger_entry.dart      ← new Isar entity
  notification_ledger_repository.dart ← new
  notification_reconciliation_service.dart ← new

lib/features/ai_assistant/
  application/
    ai_action_batch.dart              ← new Isar entity
    ai_action_batch_repository.dart   ← new
    ai_action_executor.dart           ← modified (hardening)
```

### Design principles

- `NotificationLedgerRepository` must be **plain Dart with an Isar dependency only** — no Riverpod, no Flutter imports. Testable in plain Dart.
- `NotificationReconciliationService` is called from the app bootstrap (same site as `SyncService.init()`), not from a widget.
- `AiActionBatch.snapshotJson` stores a minimal JSON blob — just enough to restore entities; not a full serialisation of every field.
- The rollback implementation must go through `ScheduleMutationCoordinator` (from Phase 1-A) so that restored entities trigger full recompute — not raw Isar writes.

---

## 7. Technical Considerations

- **Isar schema change**: Adding `NotificationLedgerEntry` and `AiActionBatch` requires a schema migration (increment Isar schema version by 1, add both new collections).
- **`FlutterLocalNotificationsPlugin.getActiveNotifications()`**: Returns a `List<ActiveNotification>` — available on iOS 10+ and Android 6+. Should be guarded with a platform check on older targets.
- **Snapshot JSON size**: For typical AI batches (2–10 tasks), the snapshot will be < 10 KB. No concern for Isar storage limits.
- **Rollback timing**: Rollback must call the existing repository `upsert` methods (same as `AiActionExecutor` create/edit paths) but pass the snapshot values. This ensures Firestore LWW sync works correctly (snapshot entity has `updatedAtMs = now()` which wins over stale remote state).
- **Idempotency key generation**: Use `Uuid().v4()` from the `uuid` package (already a dependency).
- **`AttentionOrchestratorService` still lives in Riverpod land** — accessed via provider. The ledger repository is a dependency injected into it, the same way `reminderRepository` is already injected.

---

## 8. Success Metrics

| Priority | Metric |
|----------|--------|
| 1 (highest) | After app cold-start, no phantom notifications appear from a previous session — verified by QA test scenario |
| 1 | After AI moves 3 tasks and user taps "Undo AI changes", all 3 tasks are back in their original positions |
| 2 | `AttentionOrchestratorService` has no in-memory maps (`_activeNotificationIds`, `_snoozeTimestampsMs`, `_ignoredCountByEntity`) — verified by grep |
| 3 | AI batch idempotency: sending the same `batchId` twice does not create duplicate tasks |
| 4 | Partial AI failure triggers rollback automatically — no half-applied schedule state visible to user |

---

## 9. Open Questions

1. **Notification delivery confirmation**: `getActiveNotifications()` shows what is currently in the tray, not what was delivered and dismissed. Should we also track tap/dismiss callbacks from the plugin to confirm delivery? *Recommendation: yes — wire `onDidReceiveNotification` to mark `delivered` in the ledger immediately.*
2. **Undo time window**: Is 30 minutes the right staleness guard for undo? If the user acts on an AI change (completes one of the moved tasks), undo would revert that completion too — is that acceptable? *Recommendation: show a warning if any tasks in the batch have been completed since the AI change.*
3. **Snapshot scope**: Should the snapshot include `ContextOverride` changes made by the AI? Currently FR-4.5 only mentions tasks, time blocks, and reminders. *Recommendation: include context override snapshot for completeness.*
4. **`AiActionBatch` pruning**: How long should batch history be retained in Isar? *Recommendation: keep last 20 batches or last 7 days, whichever is smaller.*

---

## 10. Implementation Tasks

### T1 — NotificationLedger Isar model + repository

**Goal:** Introduce the ledger data layer. No behaviour changes yet — just the schema, repository, and tests.

- [ ] **T1.1** Create `lib/core/notifications/notification_ledger_state.dart`
  - Dart enum `NotificationLedgerState` with values: `scheduled`, `delivered`, `cancelled`, `snoozed`, `ignored`, `expired`

- [ ] **T1.2** Create `lib/core/local_db/isar_collections/isar_notification_ledger_entry.dart`
  - `@collection` class `IsarNotificationLedgerEntry` matching the field spec in FR-4.1
  - `Id id = Isar.autoIncrement`
  - `@Index(unique: true) late int notifId`
  - `@Index() late String entityId`
  - `@Index() late String state` (store enum name as string for Isar compatibility)
  - `@Index() int? scheduledForMs`
  - All remaining fields as specified in FR-4.1
  - `part 'isar_notification_ledger_entry.g.dart'` — run `build_runner` after creation

- [ ] **T1.3** Register the new collection in `lib/core/local_db/isar_collections/isar_schemas.dart`
  - Add `IsarNotificationLedgerEntrySchema` to the `isarSchemaList` constant
  - This triggers an Isar schema version bump — verify `OfflineStore.initialize()` reopens cleanly (Isar auto-migrates new collections)

- [ ] **T1.4** Run `flutter pub run build_runner build --delete-conflicting-outputs`
  - Confirm `isar_notification_ledger_entry.g.dart` is generated with no errors

- [ ] **T1.5** Create `lib/core/notifications/notification_ledger_repository.dart`
  - Plain Dart class, no Riverpod imports; takes `Isar isar` in constructor
  - Implement all 8 methods from FR-4.2:
    - `upsertEntry(IsarNotificationLedgerEntry entry)`
    - `findByNotifId(int notifId)`
    - `findByEntityId(String entityId)`
    - `getByState(NotificationLedgerState state)` — filter on `state` index
    - `markCancelled(String entityId)` — fetch by entityId, set state + `cancelledAtMs`, upsert
    - `markDelivered(int notifId)` — fetch by notifId, set state + `deliveredAtMs`, upsert
    - `markInteraction(int notifId, String interactionType)` — set `interactionType` + `interactedAtMs`, upsert
    - `pruneOlderThan(Duration age)` — delete entries where `scheduledForMs < cutoff`

- [ ] **T1.6** Write unit tests `test/core/notifications/notification_ledger_repository_test.dart`
  - Use `OfflineStore.debugIsarOverride` pattern (same as existing Isar tests in this project)
  - Test: `upsertEntry` then `findByNotifId` returns same entry
  - Test: `markCancelled` transitions state correctly
  - Test: `markDelivered` sets `deliveredAtMs`
  - Test: `getByState(scheduled)` returns only scheduled entries
  - Test: `pruneOlderThan(72h)` deletes old entries, leaves fresh ones

---

### T2 — Wire NotificationLedger into AttentionOrchestratorService

**Goal:** Replace the three in-memory maps with ledger reads/writes. This is the core migration.

- [ ] **T2.1** Add `NotificationLedgerRepository` as a constructor parameter to `AttentionOrchestratorService`
  - `required NotificationLedgerRepository ledger`
  - Follow the same injection pattern used for `reminderRepository` (already constructor-injected)

- [ ] **T2.2** Update `lib/features/reminders/application/attention_orchestrator_providers.dart`
  - Inject `NotificationLedgerRepository` into the `AttentionOrchestratorService` provider
  - Source the repository from `OfflineStore.instance.isar!`

- [ ] **T2.3** In `_executeDecision()` — replace `_activeNotificationIds[intent.entityId] = notifId` with:
  ```dart
  await ledger.upsertEntry(IsarNotificationLedgerEntry(
    notifId: notifId,
    entityId: intent.entityId,
    entityKind: intent.entityKind,
    state: NotificationLedgerState.scheduled.name,
    scheduledForMs: deliverAt.millisecondsSinceEpoch,
    sourceContext: kAttentionOrchestratorSurface,
    updatedAtMs: _now().millisecondsSinceEpoch,
  ));
  ```

- [ ] **T2.4** In `_cancelActiveNotification(entityId)` — replace `_activeNotificationIds.remove(entityId)` with a ledger lookup:
  ```dart
  final entry = await ledger.findByEntityId(entityId);
  if (entry != null) {
    await _notifications.cancel(entry.notifId);
    await ledger.markCancelled(entityId);
  }
  ```

- [ ] **T2.5** In `onInteractionReceived()` — replace each `_ignoredCountByEntity` read/write with ledger calls:
  - `opened` / `snoozed` / `dismissed` → `ledger.markInteraction(notifId, type.name)` and reset ignored count in ledger entry (`ignoredCount = 0`)
  - `ignored` → fetch entry, increment `entry.ignoredCount`, upsert
  - Replace `_ignoredCountByEntity[intent.entityId] ?? 0` read in `evaluate()` with `await ledger.findByEntityId(entityId)?.ignoredCount ?? 0`

- [ ] **T2.6** Remove the now-unused fields from `AttentionOrchestratorService`:
  - `final Map<String, int> _activeNotificationIds = {}`
  - `final Map<String, int> _ignoredCountByEntity = {}`
  - `final Map<String, List<int>> _snoozeTimestampsMs = {}`
  - Keep `_recentDeliveries` (in-memory, 30-min window — this is intentionally ephemeral)
  - Keep `_suppressedQueue` (in-memory — addressed in a future phase)

- [ ] **T2.7** Update all existing `AttentionOrchestratorService` unit tests
  - Inject a fake/in-memory `NotificationLedgerRepository` (or use `OfflineStore.debugIsarOverride`)
  - Verify: after `evaluate()`, a `scheduled` ledger entry exists
  - Verify: after `onInteractionReceived(dismissed)`, ledger entry has `interactionType = 'dismissed'`

---

### T3 — Boot reconciliation service

**Goal:** On cold start, sync the OS tray state with the ledger. No phantom notifications after restart.

- [ ] **T3.1** Create `lib/core/notifications/notification_reconciliation_service.dart`
  - Constructor: `NotificationReconciliationService({required NotificationLedgerRepository ledger, required LocalNotificationsService notifications, required AttentionOrchestratorService orchestrator})`
  - `Future<void> reconcile()` method implementing FR-4.4 §11:
    1. `final active = await notifications.getActiveNotifications()` — wrap in platform guard (`defaultTargetPlatform == TargetPlatform.iOS || android`)
    2. `final pending = await ledger.getByState(NotificationLedgerState.scheduled) + getByState(delivered)`
    3. For each pending ledger entry whose `notifId` is NOT in `active`: `markCancelled`, then call `orchestrator.reEvaluateIfAppropriate(entityId)` (a new thin method on the orchestrator — see T3.2)
    4. For each `active` OS notification whose `notifId` is NOT in the ledger: `await notifications.cancel(notifId)` (phantom)

- [ ] **T3.2** Add `reEvaluateIfAppropriate(String entityId)` to `AttentionOrchestratorService`
  - Fetches the reminder config for `entityId` from `_reminderRepo`
  - If config exists and is enabled, builds a `ReminderIntent` and calls `evaluate()` with `reminderType: ReminderType.followUp`
  - Returns silently if config not found (task was deleted)

- [ ] **T3.3** Add `getActiveNotifications()` to `LocalNotificationsService`
  - Thin wrapper around `_plugin.getActiveNotifications()`
  - Returns `List<ActiveNotification>` (from `flutter_local_notifications`)
  - Guard: returns `[]` on platforms where unsupported

- [ ] **T3.4** Wire into `lib/core/bootstrap/app_bootstrap.dart`
  - After `OfflineStore.instance.initialize()` and before `SyncService.instance.initialize()`, add:
    ```dart
    unawaited(
      NotificationReconciliationService(
        ledger: NotificationLedgerRepository(OfflineStore.instance.isar!),
        notifications: LocalNotificationsService.instance,
        orchestrator: container.read(attentionOrchestratorServiceProvider),
      ).reconcile(),
    );
    ```
  - `unawaited` — reconciliation must not block app launch (FR-4.4 §12)

- [ ] **T3.5** Add ledger pruning to bootstrap (after reconciliation)
  - `unawaited(NotificationLedgerRepository(...).pruneOlderThan(const Duration(hours: 72)))`

- [ ] **T3.6** Write unit tests `test/core/notifications/notification_reconciliation_service_test.dart`
  - Test: ledger entry in `scheduled` state, NOT in OS tray → marked `cancelled` after reconcile
  - Test: OS tray notification NOT in ledger → cancelled via `notifications.cancel()`
  - Test: ledger entry in `scheduled` state IS in OS tray → unchanged after reconcile

---

### T4 — AiActionBatch Isar model + repository

**Goal:** Data layer for AI batch persistence. Parallel to T1, no executor changes yet.

- [ ] **T4.1** Create `lib/features/ai_assistant/application/ai_action_batch_state.dart`
  - Dart enum `AiActionBatchState`: `pending`, `executing`, `completed`, `partialFailure`, `rolledBack`

- [ ] **T4.2** Create `lib/core/local_db/isar_collections/isar_ai_action_batch.dart`
  - `@collection` class `IsarAiActionBatch` with all fields from FR-4.5
  - `@Index(unique: true) late String batchId`
  - `@Index() late String state`
  - `@Index() late int createdAtMs`
  - `List<String>` fields for `succeededActionIds`, `failedActionIds`
  - `part 'isar_ai_action_batch.g.dart'`

- [ ] **T4.3** Register `IsarAiActionBatchSchema` in `isar_schemas.dart`

- [ ] **T4.4** Run `build_runner` — confirm `isar_ai_action_batch.g.dart` generated cleanly

- [ ] **T4.5** Create `lib/features/ai_assistant/application/ai_action_batch_repository.dart`
  - Constructor takes `Isar isar`
  - Methods:
    - `Future<void> createBatch(IsarAiActionBatch batch)`
    - `Future<IsarAiActionBatch?> findByBatchId(String batchId)`
    - `Future<IsarAiActionBatch?> findMostRecent()` — ordered by `createdAtMs` desc, limit 1
    - `Future<List<IsarAiActionBatch>> listRecent({int limit = 5})` — for history UI
    - `Future<void> updateState(String batchId, AiActionBatchState state, {List<String>? succeeded, List<String>? failed, int? undoneAtMs})`
    - `Future<void> pruneOld()` — delete batches older than 7 days or where count > 20

- [ ] **T4.6** Write unit tests `test/features/ai_assistant/ai_action_batch_repository_test.dart`
  - Test: create, find by id, find most recent
  - Test: `updateState` transitions correctly
  - Test: `pruneOld` respects 7-day / 20-batch limits

---

### T5 — AiActionExecutor hardening (pre/post-execution + idempotency)

**Goal:** Wire `AiActionBatch` lifecycle into `execute()`. Adds persistence, idempotency guard, and partial failure handling.

- [ ] **T5.1** Add `AiActionBatchRepository` as a dependency of `AiActionExecutor`
  - Constructor parameter: `required AiActionBatchRepository batchRepository`
  - Update the `aiActionExecutorProvider` Riverpod provider to inject this

- [ ] **T5.2** Add snapshot helper `_captureSnapshot(List<AiAction> actions)` to `AiActionExecutor`
  - For each action that affects a `PlannedTask`, fetch the current task from `planningRepository` and serialize to JSON
  - For each action that affects a `ScheduledTimeBlock`, fetch from `timeBlockSyncService`
  - For each action that affects a `Reminder`, fetch from `reminderRepository`
  - Include `ContextOverride` state snapshot (from `contextOverrideService.getActive()`)
  - Return a JSON string of the combined snapshot

- [ ] **T5.3** Update `execute(List<AiAction> actions)` — pre-execution block:
  ```dart
  // 1. Generate batchId
  final batchId = const Uuid().v4();
  // 2. Idempotency check (not needed on first call, but future retry safety)
  final existing = await batchRepository.findByBatchId(batchId);
  if (existing?.state == AiActionBatchState.completed.name) {
    return ExecutionResult.alreadyCompleted(batchId);
  }
  // 3. Snapshot
  final snapshot = await _captureSnapshot(actions);
  // 4. Persist batch as pending
  await batchRepository.createBatch(IsarAiActionBatch(
    batchId: batchId, state: 'pending', actionsJson: jsonEncode(...), snapshotJson: snapshot, createdAtMs: now, updatedAtMs: now,
  ));
  // 5. Transition to executing
  await batchRepository.updateState(batchId, AiActionBatchState.executing);
  ```

- [ ] **T5.4** Update `execute()` — post-execution block:
  - On all success: `updateState(batchId, completed, succeeded: [...])`
  - On any failure: `updateState(batchId, partialFailure, succeeded: [...], failed: [...])`
  - If `partial_failure`: call `_rollbackBatch(batchId, snapshot)` (see T5.5)

- [ ] **T5.5** Implement `_rollbackBatch(String batchId, String snapshotJson)` in `AiActionExecutor`
  - Parse `snapshotJson` back to entity objects
  - For each snapshotted `PlannedTask`: call `planningRepository.upsertTask(restoredTask)` with `updatedAtMs = now()` (LWW wins)
  - For each snapshotted `ScheduledTimeBlock`: call `timeBlockSyncService.upsert(restoredBlock)`
  - For each snapshotted `Reminder`: call `reminderRepository.upsertReminder(restoredReminder)`
  - Restore `ContextOverride` if snapshotted
  - After all restores: call `ScheduleMutationCoordinator.instance.run(TaskUpdatedMutation(...))` for each restored task to trigger recompute
  - `await batchRepository.updateState(batchId, AiActionBatchState.rolledBack)`

- [ ] **T5.6** Update the error message returned to the AI chat on `partial_failure`
  - Return `ExecutionResult(failures: ["I couldn't complete all steps — I've restored your schedule to its previous state."])`

---

### T6 — Undo API + AI chat integration

**Goal:** Surface the undo button in the AI assistant screen.

- [ ] **T6.1** Add `Future<UndoResult> undoLastAiBatch()` to `AiActionExecutor`
  - Find most recent batch via `batchRepository.findMostRecent()`
  - Return `UndoResult.notAvailable` if:
    - No batch found
    - Batch state is not `completed` or `partialFailure`
    - Batch `createdAtMs` is older than 30 minutes
  - Check if any tasks in the batch have been completed since the AI change (compare `snapshotJson` task completion state with current state) — if so, return `UndoResult.warningTasksCompleted(completedTitles)`
  - Call `_rollbackBatch(batch.batchId, batch.snapshotJson)`
  - Return `UndoResult.success`

- [ ] **T6.2** Define `UndoResult` value class with variants:
  - `UndoResult.success()`
  - `UndoResult.notAvailable(String reason)`
  - `UndoResult.warningTasksCompleted(List<String> completedTitles)` — undo still proceeds, but warning is shown

- [ ] **T6.3** Add `undoLastBatchProvider` Riverpod provider (returns the most recent `AiActionBatch` for UI state)
  - `FutureProvider<IsarAiActionBatch?>` — watches `batchRepository.findMostRecent()`
  - Used by the UI to decide whether to show the Undo button

- [ ] **T6.4** Update `lib/features/ai_assistant/presentation/ai_assistant_screen.dart`
  - After an AI action batch is confirmed and executed, show an "Undo AI changes" chip/button below the AI response message
  - Button is only visible if:
    - Most recent batch is in state `completed`
    - Batch is < 30 minutes old
  - Tapping the button calls `ref.read(aiActionExecutorProvider).undoLastAiBatch()`, shows a snackbar with result
  - If `warningTasksCompleted`, show a confirmation dialog before undoing: "Some tasks the AI added have been completed. Undoing will revert those completions. Continue?"

- [ ] **T6.5** Add "Recent AI changes" history chip to the AI assistant screen
  - Small text link below the chat area: "View recent AI changes (N)"
  - Tapping opens a bottom sheet listing the last 5 batches from `batchRepository.listRecent()`
  - Each row: timestamp, action count, state chip (Completed / Partial failure / Undone)
  - Undo button on the most recent row if within 30-minute window

---

### T7 — Verification & success metric checks

- [ ] **T7.1** Run `flutter analyze` — zero errors in new files
- [ ] **T7.2** Run `flutter test test/core/notifications/` and `test/features/ai_assistant/` — all green
- [ ] **T7.3** Grep audit: `rg "_activeNotificationIds\|_ignoredCountByEntity\|_snoozeTimestampsMs" lib/` → zero results
- [ ] **T7.4** Manual QA — Notification phantom test:
  1. Schedule a reminder for a task
  2. Force-kill the app while notification is pending
  3. Reopen app
  4. Verify: notification is NOT re-shown if it was already dismissed by OS; verify ledger entry is `cancelled`
- [ ] **T7.5** Manual QA — AI undo test:
  1. Tell the AI to move 3 tasks to tomorrow
  2. Confirm AI actions
  3. Tap "Undo AI changes"
  4. Verify: all 3 tasks are back to their original dates
  5. Verify: coaching focus and suggestions reflect restored schedule immediately (Phase 1-A recompute firing)
- [ ] **T7.6** Manual QA — AI partial failure test (dev-only, inject a deliberate error on action 2 of 3):
  1. Verify: actions 1 is rolled back automatically
  2. Verify: user sees the "restored your schedule" error message
  3. Verify: batch state in ledger is `rolled_back`
