# PRD: Phase C — Attention Orchestration

## 1. Introduction / Overview

Today, `ReminderSyncService` directly schedules a long chain of pre-computed OS
notifications for every task/habit. It has no awareness of context (is the user
in a meeting?), no awareness of coaching state (is this the focus entity?), no
collision management, and no fatigue signals. The result is a system that can
fire 13+ notifications in sequence without any behavioral intelligence.

Phase C introduces the **AttentionOrchestrator** — a new central layer that
sits between reminder intent generation and OS notification scheduling. It is
the single authority on *when* and *whether* a notification is delivered.

The migration is a **full architectural shift**: away from heavy pre-scheduled
notification chains toward a reactive model where only the next meaningful
reminder is scheduled, and the system re-evaluates after every interaction or
context change.

This phase also wires in the Phase B context override system, adds coaching
focus awareness to delivery decisions, introduces intelligent collision
management, and adds notification fatigue tracking signals.

---

## 2. Goals

1. Make `AttentionOrchestrator` the single authority for all notification
   delivery decisions — no service schedules OS notifications directly.
2. Migrate from pre-scheduled notification chains to single-next-reminder
   reactive scheduling.
3. Wire Phase B `OverrideAttentionPolicy` into real notification suppression.
4. Consult `CurrentCoachingFocus` to boost delivery priority when a reminder
   aligns with the active coaching focus.
5. Manage collisions with a minimum notification gap and intelligent semantic
   batching.
6. Make extreme mode reactive and dynamic rather than pre-computed and spammy.
7. Track notification fatigue signals through the existing analytics system.
8. Preserve deterministic, explainable, offline-safe behavior throughout.

---

## 3. User Stories

- As a user in a meeting, I want reminders held back and re-evaluated when my
  meeting ends — not silently dropped and not replayed blindly.
- As a user whose current coaching focus is "workout streak at risk," I want
  that reminder to cut through context overrides that would normally suppress it.
- As a user with two habits due within minutes of each other, I want a single
  smart notification rather than two simultaneous banners.
- As a user in extreme mode, I want the app to keep following up persistently
  but only escalate based on whether I've actually ignored it, not on a fixed
  timer chain.
- As a product team, I want to know when notifications are being dismissed,
  ignored, or causing snooze spirals so we can improve the coaching experience.

---

## 4. Functional Requirements

### 4.1 ReminderIntent model

**FR-C-01** — Define a `ReminderIntent` model. This is what `ReminderSyncService`
produces instead of directly calling `LocalNotificationsService`:

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Stable UUID for this intent |
| `entityId` | `String` | Task or habit ID |
| `entityKind` | `String` | `"task"` or `"habit"` |
| `entityTitle` | `String` | Display title |
| `proposedAt` | `DateTime` | When the reminder wants to fire |
| `importance` | `int` | 0–100 importance score |
| `interruptionLevel` | `InterruptionLevel` | `low` / `medium` / `high` / `critical` (from Phase B) |
| `enforcementMode` | `String` | `"flexible"`, `"disciplined"`, or `"extreme"` |
| `escalationLevel` | `int` | Current escalation level (0 = first fire) |
| `reminderType` | `ReminderType` | `scheduled`, `followUp`, `escalation` |
| `sourceReason` | `String` | Human-readable reason (for trace/debug) |
| `createdAtMs` | `int` | Epoch ms |

**FR-C-02** — Define `ReminderType` enum:
```dart
enum ReminderType { scheduled, followUp, escalation }
```

**FR-C-03** — `InterruptionLevel` is assigned to a `ReminderIntent` based on
the entity's enforcement mode and escalation level:

| Condition | InterruptionLevel |
|-----------|-----------------|
| `flexible`, any escalation | `low` or `medium` |
| `disciplined`, escalation 0–1 | `medium` |
| `disciplined`, escalation ≥ 2 | `high` |
| `extreme`, escalation 0–1 | `high` |
| `extreme`, escalation ≥ 2 | `critical` |
| Emergency bypass active | `critical` |

### 4.2 AttentionDecision model

**FR-C-04** — Define an `AttentionDecision` model — the output of the
orchestrator:

| Field | Type | Description |
|-------|------|-------------|
| `intentId` | `String` | The `ReminderIntent.id` this decision applies to |
| `outcome` | `AttentionOutcome` | `approved`, `delayed`, `batched`, `suppressed` |
| `deliverAt` | `DateTime?` | When to actually fire (may differ from `proposedAt`) |
| `silent` | `bool` | Deliver without sound/vibration |
| `batchedWith` | `List<String>` | Intent IDs batched into this notification |
| `suppressedReason` | `String?` | Human-readable suppression reason |
| `retryAllowed` | `bool` | Whether to re-evaluate this intent after context changes |
| `priorityBoosted` | `bool` | True when boosted by coaching focus alignment |

**FR-C-05** — Define `AttentionOutcome` enum:
```dart
enum AttentionOutcome { approved, delayed, batched, suppressed }
```

### 4.3 AttentionOrchestrator

**FR-C-06** — `AttentionOrchestrator` is the **sole caller** of
`LocalNotificationsService.schedule()`. No other class may schedule OS
notifications after Phase C migration.

**FR-C-07** — `AttentionOrchestrator.evaluate(ReminderIntent intent)` must
apply the following decision pipeline in order:

```
1. Check context override suppression (Phase B OverrideAttentionPolicy)
2. Check coaching focus alignment (boost or suppress)
3. Check collision with recently delivered or pending notifications
4. Compute final delivery time and outcome
5. Return AttentionDecision
```

**FR-C-08** — The orchestrator must accept the following inputs:

- `ReminderIntent` — the intent to evaluate
- `UserAttentionState` — current context override state (from Phase B)
- `CurrentCoachingFocus?` — active coaching focus (may be null)
- `List<RecentDelivery>` — timestamps of notifications delivered in the last
  30 minutes (for collision management)
- `List<ReminderIntent>` — pending intents in the queue (for batching)

**FR-C-09** — `AttentionOrchestrator` must be a pure Dart class (no I/O, no
Riverpod). A separate `AttentionOrchestratorService` wraps it with repository
access and scheduling execution.

### 4.4 Decision rule — context override suppression

**FR-C-10** — If `OverrideAttentionPolicy.shouldSuppress(intent.interruptionLevel,
attentionState.activeOverride)` returns true, the intent is suppressed:
- `outcome = suppressed`
- `suppressedReason = "Active override: [type]"`
- `retryAllowed = true` (re-evaluate when override ends)
- Intent is added to the pending suppressed queue (see FR-C-16)

**FR-C-11** — Sleep window suppression follows the same rule evaluated at
delivery time, not at scheduling time.

### 4.5 Decision rule — coaching focus alignment

**FR-C-12** — If `CurrentCoachingFocus` is active and `intent.entityId ==
focus.primaryEntityId` (or is in `focus.contextSnapshot.insightTypes`):
- Set `priorityBoosted = true`
- Upgrade `interruptionLevel` by one tier (e.g. `medium → high`)
- Reduce suppression likelihood: only suppress if `shouldSuppress()` still
  returns true after the upgraded level

**FR-C-13** — If an intent is for an entity that is explicitly NOT the coaching
focus AND the coaching focus is active with high confidence (`focusConfidence >=
0.75`), lower-importance intents (`low` level) may be silenced:
- `outcome = approved`, `silent = true`
- Delivered silently to app notification center but no sound/vibration

### 4.6 Decision rule — collision management

**FR-C-14** — A **minimum notification gap** of 3 minutes must be enforced
between any two notifications delivered by the app. If a proposed `deliverAt`
falls within 3 minutes of a `RecentDelivery`:
- Delay the lower-priority intent by enough time to clear the gap
- Higher-priority intent (by `importance` score) is delivered first

**FR-C-15** — **Semantic batching** applies when two or more intents are due
within a 5-minute window AND they share a semantic relationship. Batching
criteria:

| Condition | Batch? |
|-----------|--------|
| Both are low-importance habits with similar tags | Yes |
| One is a coaching insight + one is its related task reminder | Yes |
| One is a streak-risk alert + one is an unrelated task | No |
| One is extreme-mode escalation | No — always deliver individually |

When batched:
- A single notification is delivered summarizing both items
- `outcome = batched` for the secondary intent, `batchedWith` lists the primary
- The notification body lists both entity titles

**FR-C-16** — Semantic relationship for batching is determined by a simple
`CanBatch(intentA, intentB)` function checking:
- Both `interruptionLevel` are `low` or `medium`
- Neither is `extreme` enforcement mode
- `proposedAt` delta ≤ 5 minutes

### 4.7 Reactive scheduling migration (full migration from pre-scheduling)

**FR-C-17** — `ReminderSyncService` must be refactored to produce a single
`ReminderIntent` for the next meaningful fire time only — not a full chain of
pre-scheduled slots.

**FR-C-18** — After each notification interaction (tapped, snoozed, dismissed,
ignored timeout), `AttentionOrchestratorService` must:
1. Record the interaction signal (see FR-C-23)
2. Re-evaluate whether a follow-up intent is needed
3. If yes: produce a new `ReminderIntent` with `reminderType = followUp` or
   `escalation` and pass it back through the full orchestrator pipeline
4. Schedule only that single next notification

**FR-C-19** — "Ignored timeout" is defined as: a notification was delivered but
no interaction was recorded within a configurable window (default: 15 minutes).
The app must check this on foreground resume and schedule a follow-up intent if
the timeout has passed.

**FR-C-20** — The cancellation of up-to-64 pre-scheduled slots
(`_cancelReminderSlots` loop in the current `ReminderSyncService`) must be
replaced by cancelling only the single active slot per entity.

### 4.8 Extreme mode — reactive escalation

**FR-C-21** — For `extreme` enforcement mode, the escalation schedule must be
reactive, not pre-computed:

| Trigger | Next action |
|---------|------------|
| First fire, no interaction within 15 min | Follow-up at `initialSnooze` minutes |
| Follow-up ignored (15 min timeout again) | Escalate: `escalationLevel++`, shorter interval |
| User snoozed | Re-evaluate: escalate or maintain based on total snooze count |
| User opened/tapped | Resolve: cancel follow-ups |
| `escalationLevel >= maxEscalationLevel` | Enter tail phase: follow-up every 60 min, max 3 more times |

**FR-C-22** — The tail phase for extreme mode (after `maxEscalationLevel` is
reached) must be capped at **3 additional follow-ups** regardless of
pre-computed plan. This replaces the current `tailRepeatCount: 5` pre-schedule.

**FR-C-23** — Escalation decisions must be logged to `evaluationTrace` on the
`ReminderConfig` record for explainability and debugging.

### 4.9 Suppressed intent queue

**FR-C-24** — When an intent is suppressed with `retryAllowed = true`, it must
be stored in a `SuppressedIntentQueue` (in-memory Riverpod state is sufficient
for Phase C; Isar persistence optional).

**FR-C-25** — When a context override ends (Phase B expiry flow):
- Retrieve all intents in `SuppressedIntentQueue` for the expired override
- Re-evaluate each: is the entity still incomplete? Is the scheduled time still
  in the future or recently past (≤ 2 hours ago)?
- If still relevant → produce a new `ReminderIntent` with `reminderType =
  followUp` and pass through the orchestrator pipeline
- If stale (completed, or scheduled time > 2 hours past) → mark suppressed/stale
  and include in the Phase B post-override recovery review card
- Clear the queue entries after re-evaluation

### 4.10 Notification fatigue signals

**FR-C-26** — Add the following new values to the existing `AnalyticsEventType`
enum:

| Event | When logged |
|-------|------------|
| `notificationDelivered` | OS notification successfully scheduled and past its fire time |
| `notificationOpened` | User tapped the notification body |
| `notificationDismissed` | User explicitly dismissed the notification |
| `notificationIgnored` | Ignored timeout elapsed with no interaction |
| `reminderSuppressed` | Intent suppressed by `AttentionOrchestrator` |
| `repeatedSnoozePattern` | Same entity snoozed 3+ times within a 24h window |

**FR-C-27** — All fatigue events use the same `AnalyticsEvent` model. The
`sourceSurface` field is set to `"attention_orchestrator"` for these events.

**FR-C-28** — `notificationDismissed` and `notificationIgnored` require OS-level
callback support. On Android this is available via notification action buttons
and foreground detection. On iOS, dismissed detection is limited — log
`notificationIgnored` on foreground resume if no interaction recorded within the
timeout window.

### 4.11 AttentionOrchestratorService (execution wrapper)

**FR-C-29** — `AttentionOrchestratorService` is the Riverpod-wired service that:
1. Reads `UserAttentionState` from `ContextOverrideRepository`
2. Reads `CurrentCoachingFocus` from `FocusRepository`
3. Tracks `RecentDelivery` list (in-memory, last 30 min)
4. Calls `AttentionOrchestrator.evaluate(intent)`
5. Executes the `AttentionDecision`: calls `LocalNotificationsService.schedule()`
   for `approved`/`batched` outcomes, skips for `suppressed`/`delayed`
6. Logs the appropriate analytics event via `logAnalyticsEvent()`

**FR-C-30** — `AttentionOrchestratorService` must expose:
- `evaluate(ReminderIntent intent) → Future<AttentionDecision>`
- `onInteractionReceived(String entityId, NotificationInteractionType type)`
- `onOverrideEnded()` — triggers suppressed queue re-evaluation

**FR-C-31** — Define `NotificationInteractionType` enum:
```dart
enum NotificationInteractionType { opened, snoozed, dismissed, ignored }
```

### 4.12 Migration path — ReminderSyncService adapter

**FR-C-32** — `ReminderSyncService` must be updated to an **adapter** role:
- It continues to own `ReminderConfig` persistence and cadence policy
- It no longer calls `LocalNotificationsService` directly
- It produces `ReminderIntent` objects and passes them to
  `AttentionOrchestratorService.evaluate()`

**FR-C-33** — The existing `AdaptiveReminderPolicy` (cadence definitions) must
NOT be removed. It is retained as the source of cadence parameters
(`initialSnoozeMinutes`, `minSnoozeMinutes`, `maxEscalationLevel`) used by the
reactive escalation logic.

**FR-C-34** — The `_cancelReminderSlots` 64-slot loop must be replaced. The
system now tracks a single active notification ID per entity stored in
`ReminderConfig.activeNotificationId` (new field).

---

## 5. Non-Goals (Out of Scope for Phase C)

- **No changes to the mode system** (flexible/disciplined/extreme definitions)
  — that is Phase D.
- **No server-side notification scheduling** — remains fully device-local.
- **No ML/AI-driven delivery decisions** — all orchestration rules are
  deterministic.
- **No calendar integration** — context overrides remain user-initiated only.
- **No changes to goal reminder scheduling** (`scheduleDailyAtLocalTime`) —
  goal reminders are already single-fire and not part of the escalation system.
- **No UI redesign** beyond what is needed to surface `AttentionDecision`
  explainability in debug/settings views.

---

## 6. Design Considerations

- The `AttentionOrchestrator` evaluation pipeline must be traceable:
  `AttentionDecision.suppressedReason` and `priorityBoosted` should be
  human-readable enough to show in a debug panel.
- Batched notifications should use a clear format: "Time to start: Workout +
  Stretch" rather than generic "2 reminders pending."
- The ignored timeout (15 min default) should eventually be configurable per
  enforcement mode, but a single global default is fine for Phase C V1.
- `RecentDelivery` list (last 30 min) should be lightweight — just `(entityId,
  deliveredAt, interruptionLevel)` tuples in memory.

---

## 7. Technical Considerations

- `AttentionOrchestrator` (pure Dart) and `AttentionOrchestratorService`
  (Riverpod-wired) follow the same pattern used by `FocusScoringEngine` /
  `FocusSelector`.
- `ReminderConfig` needs one new field: `activeNotificationId: int?` — the
  current scheduled OS notification ID for this entity. Replacing the 64-slot
  cancel loop.
- `SuppressedIntentQueue` can be Riverpod `StateProvider<List<ReminderIntent>>`
  for Phase C. If the app is killed during an override, intents are reconstructed
  from `ReminderConfig` records where `enabled == true` and `pendingAction ==
  true`.
- `RecentDelivery` tracking: use a `StateProvider<List<RecentDelivery>>` with a
  trim operation on every update to keep only entries within the last 30 minutes.
- The ignored timeout check must hook into `AppLifecycleTaskRefresh` (or
  equivalent) so it runs on every foreground resume.
- `isar_schemas.dart` does not need updates — no new Isar collections in Phase C.
- All new unit tests should follow the pattern of existing orchestration tests:
  pure inputs → deterministic outputs, no mocking of OS scheduler.

---

## 8. Success Metrics

- Zero pre-scheduled notification chains after migration — every entity has at
  most 1 active OS notification slot at any time.
- Context overrides correctly suppress notifications with `retryAllowed = true`
  in the queue.
- Suppressed intents are re-evaluated on override end and only delivered if
  still relevant (not completed, not > 2h stale).
- Coaching focus alignment boosts correct entity's delivery priority.
- Extreme mode fires maximum 3 tail follow-ups after `maxEscalationLevel` is
  reached (down from pre-scheduled 5).
- All 6 fatigue event types are logged correctly in the analytics pipeline.
- `AttentionOrchestrator` unit tests cover: approval, suppression (all 6
  override types), focus boost, focus silence, collision delay, semantic batch,
  extreme reactive escalation.

---

## 9. Open Questions

- Should `activeNotificationId` be added to the existing Isar `ReminderConfig`
  schema (requiring a migration) or stored in a lightweight in-memory map keyed
  by `taskId`? (Recommendation: in-memory map in `AttentionOrchestratorService`
  for Phase C; migrate to Isar in Phase D if needed for persistence across
  restarts.)
- Should the minimum notification gap (3 min) be configurable per mode in Phase
  C, or a fixed global constant? (Recommendation: fixed constant for now, make
  it a `kMinNotificationGapMinutes` named constant so it is easy to tune later.)
- When two intents are batched, which entity's `taskId` is used in the
  notification payload for tap routing? (Recommendation: the higher-priority
  entity's ID; the notification body lists both.)
