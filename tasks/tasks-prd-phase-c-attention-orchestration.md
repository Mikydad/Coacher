# Tasks: Phase C — Attention Orchestration

PRD reference: `tasks/prd-phase-c-attention-orchestration.md`

---

## Group 1.0 — Domain models

- [ ] 1.1 Create `ReminderType` enum in `reminder_type.dart` (inside `reminders/domain/models/`)
  - Values: `scheduled`, `followUp`, `escalation`
  - Add `fromStorage(String?)` safe parser

- [ ] 1.2 Create `NotificationInteractionType` enum in `notification_interaction_type.dart` (inside `reminders/domain/models/`)
  - Values: `opened`, `snoozed`, `dismissed`, `ignored`
  - Add `fromStorage(String?)` safe parser

- [ ] 1.3 Create `ReminderIntent` model in `reminder_intent.dart` (inside `reminders/domain/models/`)
  - Fields: `id`, `entityId`, `entityKind`, `entityTitle`, `proposedAt`, `importance` (0–100), `interruptionLevel` (`InterruptionLevel` from Phase B), `enforcementMode`, `escalationLevel`, `reminderType`, `sourceReason`, `createdAtMs`
  - `toMap()` / `fromMap()`
  - `validate()` using `ModelValidators`

- [ ] 1.4 Create `AttentionOutcome` enum in `attention_outcome.dart` (inside `reminders/domain/models/`)
  - Values: `approved`, `delayed`, `batched`, `suppressed`
  - Add `fromStorage(String?)` safe parser

- [ ] 1.5 Create `AttentionDecision` model in `attention_decision.dart` (inside `reminders/domain/models/`)
  - Fields: `intentId`, `outcome`, `deliverAt`, `silent`, `batchedWith` (List<String>), `suppressedReason`, `retryAllowed`, `priorityBoosted`
  - Named constructors: `AttentionDecision.approved(...)`, `AttentionDecision.suppressed(...)`, `AttentionDecision.delayed(...)`, `AttentionDecision.batched(...)`
  - `toMap()` / `fromMap()`

- [ ] 1.6 Create `RecentDelivery` model in `recent_delivery.dart` (inside `reminders/domain/models/`)
  - Fields: `entityId`, `deliveredAtMs`, `interruptionLevel`
  - Lightweight — in-memory only (no Isar)

- [ ] 1.7 Add `interruptionLevelForIntent` pure function in `interruption_level_resolver.dart`
  - Maps `(enforcementMode, escalationLevel, emergencyBypass) → InterruptionLevel` per PRD table (FR-C-03)
  - Pure function — no state, no I/O

---

## Group 2.0 — OverrideAttentionPolicy wiring into analytics events

- [ ] 2.1 Add 6 new `AnalyticsEventType` values to `analytics_event.dart`:
  - `notificationDelivered`, `notificationOpened`, `notificationDismissed`, `notificationIgnored`, `reminderSuppressed`, `repeatedSnoozePattern`

- [ ] 2.2 Fix exhaustive switch in `kpi_engine.dart` (and any other switch on `AnalyticsEventType`) to include the 6 new values — `break` on all of them

---

## Group 3.0 — AttentionOrchestrator (pure Dart)

- [ ] 3.1 Create `attention_orchestrator.dart` with `abstract final class AttentionOrchestrator`
  - Single public method: `static AttentionDecision evaluate({required ReminderIntent intent, required UserAttentionState attentionState, CurrentCoachingFocus? focus, required List<RecentDelivery> recentDeliveries, required List<ReminderIntent> pendingIntents})`
  - No I/O, no Riverpod, no Flutter imports

- [ ] 3.2 Implement Step 1 — context override suppression
  - Call `OverrideAttentionPolicy.shouldSuppress(intent.interruptionLevel, attentionState.activeOverride)` (uses `effectiveOverride()` resolved before calling evaluate)
  - If suppressed: return `AttentionDecision.suppressed(intentId: intent.id, reason: "Active override: \${override.displayName}", retryAllowed: true)`

- [ ] 3.3 Implement Step 2 — coaching focus alignment boost
  - If `focus != null` and `focus.primaryEntityId == intent.entityId` → set `priorityBoosted = true`, upgrade `interruptionLevel` by one tier
  - Re-check suppression with upgraded level (if suppression still applies post-upgrade, suppress anyway)

- [ ] 3.4 Implement Step 2b — coaching focus silence for non-focus entities
  - If `focus != null` and `focus.focusConfidence >= 0.75` and `intent.interruptionLevel == low` and `intent.entityId != focus.primaryEntityId` → return `AttentionDecision.approved(..., silent: true)`

- [ ] 3.5 Implement Step 3 — collision management (minimum 3-min gap)
  - Define `const kMinNotificationGapMinutes = 3`
  - Check each `RecentDelivery` delivered within last 30 min
  - If `intent.proposedAt` is within `kMinNotificationGapMinutes` of a recent delivery → delay `deliverAt = recentDelivery.deliveredAt + 3 minutes`, return `AttentionDecision.delayed(...)`

- [ ] 3.6 Implement Step 3b — semantic batching
  - Define `canBatch(ReminderIntent a, ReminderIntent b) → bool`:
    - Both `interruptionLevel` are `low` or `medium`
    - Neither `enforcementMode` is `"extreme"`
    - `proposedAt` delta ≤ 5 minutes
  - If any `pendingIntent` satisfies `canBatch(intent, pending)` → return `AttentionDecision.batched(intentId: intent.id, batchedWith: [pending.id], deliverAt: ...)`

- [ ] 3.7 Implement Step 4 — default approval path
  - If no suppression, no delay, no batch → return `AttentionDecision.approved(intentId: intent.id, deliverAt: intent.proposedAt, silent: false, priorityBoosted: priorityBoosted)`

---

## Group 4.0 — AttentionOrchestratorService (Riverpod-wired execution layer)

- [ ] 4.1 Create `attention_orchestrator_service.dart` with class `AttentionOrchestratorService`
  - Constructor takes: `ContextOverrideRepository`, `FocusRepository`, `AnalyticsEventLogger`, `LocalNotificationsService`, `DateTime Function() now`
  - Maintains in-memory `List<RecentDelivery> _recentDeliveries` (trimmed to last 30 min on each call)
  - Maintains in-memory `Map<String, int> _activeNotificationIds` (entityId → OS notification ID)

- [ ] 4.2 Implement `evaluate(ReminderIntent intent) → Future<AttentionDecision>`
  - Fetch `UserAttentionState` from `ContextOverrideRepository.getAttentionState()`
  - Compute `effective = effectiveOverride(state, DateTime.now())` 
  - Fetch `CurrentCoachingFocus?` from `FocusRepository.getActiveFocus()`
  - Trim `_recentDeliveries` to last 30 min
  - Call `AttentionOrchestrator.evaluate(...)` 
  - Execute decision (see 4.3)
  - Return decision

- [ ] 4.3 Implement decision execution:
  - `approved` or `batched` → cancel existing active notification for entity → call `LocalNotificationsService.schedule(...)` → store new ID in `_activeNotificationIds` → add to `_recentDeliveries` → log `notificationDelivered`
  - `suppressed` → log `reminderSuppressed` → add intent to `SuppressedIntentQueue` (Riverpod state) if `retryAllowed`
  - `delayed` → re-schedule at `decision.deliverAt` (call schedule with the delayed time)

- [ ] 4.4 Implement `onInteractionReceived(String entityId, NotificationInteractionType type)`
  - `opened` → log `notificationOpened` → cancel follow-ups → resolve reminder in `ReminderSyncService`
  - `snoozed` → log nothing (snooze logged by ReminderSyncService already) → check snooze count for `repeatedSnoozePattern`
  - `dismissed` → log `notificationDismissed`
  - `ignored` → log `notificationIgnored` → produce follow-up `ReminderIntent` and pass through `evaluate()`

- [ ] 4.5 Implement `onOverrideEnded()` — suppressed queue re-evaluation
  - Retrieve all `SuppressedIntentQueue` entries
  - For each: check if entity is still incomplete (from `ReminderConfig`) AND `intent.proposedAt` is ≤ 2 hours past
  - If relevant → produce new `ReminderIntent` with `reminderType = followUp`, call `evaluate()`
  - If stale → add to Phase B `PostOverrideReview` suppressed items list
  - Clear the queue

- [ ] 4.6 Add `repeatedSnoozePattern` detection
  - Track per-entity snooze timestamps in-memory
  - If same entity snoozed 3+ times within a rolling 24h window → log `repeatedSnoozePattern`

---

## Group 5.0 — Riverpod providers for orchestration

- [ ] 5.1 Create `attention_orchestrator_providers.dart`
  - `suppressedIntentQueueProvider` → `StateProvider<List<ReminderIntent>>([])`
  - `recentDeliveriesProvider` → `StateProvider<List<RecentDelivery>>([])`
  - `attentionOrchestratorServiceProvider` → `Provider<AttentionOrchestratorService>` — wires in repositories, analytics logger, `LocalNotificationsService`

---

## Group 6.0 — ReminderSyncService refactor (adapter role)

- [ ] 6.1 Remove direct calls to `_notifications.schedule(...)` from `_applyReminders`
  - Replace with: produce a single `ReminderIntent` for the next fire time only
  - Pass intent to `AttentionOrchestratorService.evaluate(intent)` instead

- [ ] 6.2 Replace the `_cancelReminderSlots` 64-slot loop
  - Replace with: `_attentionOrchestratorService.cancelForEntity(entityId)` which calls `_notifications.cancel(_activeNotificationIds[entityId])` — single cancel per entity

- [ ] 6.3 Update `requestSnooze` to produce a `ReminderIntent` with `reminderType = followUp` instead of directly scheduling
  - Pass through `AttentionOrchestratorService.evaluate()`

- [ ] 6.4 Update `_nextReminderTimes` to return a single `DateTime?` (not a `List<DateTime>`)
  - The first valid future time only — one slot per entity
  - Rename to `_nextReminderTime(ReminderConfig) → DateTime?`

- [ ] 6.5 Add `AttentionOrchestratorService` as a constructor parameter to `ReminderSyncService`
  - Inject via Riverpod in `providers.dart`

---

## Group 7.0 — ReminderConfig: activeNotificationId tracking

- [ ] 7.1 Add `activeNotificationId: int?` field to `ReminderConfig` model
  - Optional (null = no active notification scheduled)
  - Add to `toMap()` / `fromMap()` / `copyWith()`
  - Note: per PRD recommendation, use in-memory map in `AttentionOrchestratorService._activeNotificationIds` as the primary source; `ReminderConfig.activeNotificationId` is an optional fallback persistence

---

## Group 8.0 — Ignored timeout check on foreground resume

- [ ] 8.1 Add `const kIgnoredTimeoutMinutes = 15` constant in `attention_orchestrator.dart`

- [ ] 8.2 Create `checkIgnoredTimeouts(WidgetRef ref)` function in `attention_orchestrator_service.dart`
  - For each `ReminderConfig` where `pendingAction == true` and `lastTriggeredAtMs` is set:
    - If `now - lastTriggeredAtMs > kIgnoredTimeoutMinutes * 60 * 1000`
    - And no interaction was recorded since then
    - → call `onInteractionReceived(entityId, NotificationInteractionType.ignored)`

- [ ] 8.3 Hook `checkIgnoredTimeouts` into `AppLifecycleTaskRefresh.didChangeAppLifecycleState(resumed)`
  - Add call alongside the existing expiry poller check

---

## Group 9.0 — Extreme mode reactive escalation

- [ ] 9.1 Refactor `_nextReminderTime` to use reactive escalation for extreme mode
  - For `extreme` mode: do NOT pre-compute a chain; instead compute only the next fire time based on `escalationLevel` and `lastTriggeredAtMs`
  - Use `AdaptiveReminderPolicy.nextStep(cadence, escalationLevel)` to get `snoozeMinutes`

- [ ] 9.2 Cap extreme tail phase at 3 follow-ups (down from `tailRepeatCount: 5`)
  - Add constant `const kExtremeMaxTailFollowUps = 3`
  - In `_nextReminderTime`: if `escalationLevel >= cadence.maxEscalationLevel`, count how many tail follow-ups have been produced and stop at 3

- [ ] 9.3 Add `evaluationTrace` field to `ReminderConfig`
  - Type: `List<String>` — list of human-readable trace entries
  - Serialized as JSON string in `toMap()` / `fromMap()`
  - `AttentionOrchestratorService` appends to this trace when escalation decisions are made

---

## Group 10.0 — Notification response handler wiring

- [ ] 10.1 Update `notification_response_handler.dart`
  - When a notification tap is received, call `attentionOrchestratorService.onInteractionReceived(entityId, NotificationInteractionType.opened)`
  - When a snooze action is received, call `onInteractionReceived(entityId, NotificationInteractionType.snoozed)`

- [ ] 10.2 Update `notification_response_handler.dart` for dismiss detection
  - On foreground resume without a tap interaction within `kIgnoredTimeoutMinutes` → infer `dismissed` or `ignored` based on notification state

---

## Group 11.0 — Tests

- [ ] 11.1 `attention_orchestrator_test.dart` — pure orchestrator unit tests
  - Approval: no override, no collision → `approved`
  - Suppression: all 6 override types at varying levels (use PRD FR-B-04 table)
  - Focus boost: `entityId == focus.primaryEntityId` → `priorityBoosted = true`, `interruptionLevel` upgraded
  - Focus silence: non-focus entity, `focusConfidence >= 0.75`, `low` level → `approved, silent = true`
  - Collision delay: recent delivery within 3 min → `delayed` with adjusted `deliverAt`
  - Semantic batch: two `low` intents within 5 min, neither extreme → `batched`
  - No batch: one extreme intent → delivered individually
  - Coaching focus overrides suppression: focus-aligned entity at `medium` level in `meeting` override → upgraded to `high` → not suppressed

- [ ] 11.2 `interruption_level_resolver_test.dart`
  - All combinations from PRD FR-C-03 table: flexible/disciplined/extreme × escalation levels

- [ ] 11.3 `reminder_sync_service_refactor_test.dart`
  - After refactor: `_applyReminders` produces exactly 1 scheduled notification per enabled entity (not N slots)
  - `requestSnooze` produces a `followUp` ReminderIntent and passes it through the orchestrator

---

## Summary

| Group | What it covers | Tasks |
|-------|---------------|-------|
| 1.0 Domain models | `ReminderIntent`, `AttentionDecision`, `AttentionOutcome`, `RecentDelivery`, `NotificationInteractionType`, `ReminderType`, interruption resolver | 7 |
| 2.0 Analytics events | 6 new fatigue event types + exhaustive switch fixes | 2 |
| 3.0 AttentionOrchestrator | Pure Dart engine — suppression, focus boost, focus silence, collision, batching, approval | 7 |
| 4.0 AttentionOrchestratorService | Riverpod-wired execution — evaluate, execute decision, interaction handler, override-end queue flush, snooze pattern detection | 6 |
| 5.0 Riverpod providers | Suppressed queue, recent deliveries, service provider | 1 |
| 6.0 ReminderSyncService refactor | Remove pre-scheduling chain, replace cancel loop, single-next-intent, inject orchestrator | 5 |
| 7.0 ReminderConfig field | `activeNotificationId`, `evaluationTrace` | 1 |
| 8.0 Ignored timeout | Constant, check function, lifecycle hook | 3 |
| 9.0 Extreme reactive escalation | Single-next-time, 3-tail cap, `evaluationTrace` | 3 |
| 10.0 Notification response handler | Tap/snooze/dismiss interaction wiring | 2 |
| 11.0 Tests | Orchestrator (8 cases), interruption resolver, sync service refactor | 3 |
| **Total** | | **40 tasks** |

---

## Key architectural invariants to preserve

1. `AttentionOrchestrator` must remain a pure static class — no I/O, fully unit-testable.
2. `AdaptiveReminderPolicy` is **not removed** — still the source of cadence parameters.
3. `ReminderSyncService` becomes an adapter: owns config + cadence, produces intents, no longer calls `LocalNotificationsService` directly.
4. Every entity has **at most 1 active OS notification slot** at any time after this migration.
5. All decisions are deterministic and explainable via `AttentionDecision.suppressedReason` and `evaluationTrace`.
6. No Isar schema changes needed for Phase C — `SuppressedIntentQueue` and `RecentDelivery` live in Riverpod `StateProvider`.
