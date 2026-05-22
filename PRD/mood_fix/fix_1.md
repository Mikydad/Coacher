We are evolving from simple reminder scheduling into a unified behavioral time + attention orchestration system.

Current problems:

1. Tasks/habits can overlap unrealistically in occupied time.
2. Reminder notifications escalate independently with no attention coordination.
3. Extreme mode currently means “more notifications” instead of “smarter persistence.”
4. Context (meeting/focus/sleep) cannot suppress or adapt delivery.
5. ReminderSyncService currently mixes:

   * cadence generation,
   * escalation policy,
   * scheduling execution,
   * and delivery behavior.

We should migrate incrementally without breaking the current architecture.

Implementation goals:

* Add real time occupancy awareness.
* Add overlap/conflict detection.
* Add centralized attention orchestration.
* Preserve deterministic behavior.
* Preserve local-first/offline scheduling.
* Avoid aggressive auto-rescheduling.
* Move from notification spam → intelligent persistence.

PHASE A — TIME BLOCK FOUNDATION
Goal:
Treat tasks/habits as occupied time windows, not floating reminders.

Implement:

1. New ScheduledTimeBlock model
   Fields:

* entityId
* entityKind
* startAt
* expectedDurationMinutes
* computedEndAt
* flexibilityType
* allowOverlapOverride
* importance
* createdAtMs
* schemaVersion

2. TimeBlockRepository
   Responsibilities:

* upsertBlock()
* deleteBlock()
* listBlocksForDateRange()
* listOverlappingBlocks()

Use Isar first (local-first architecture).

3. ConflictDetectionEngine
   Input:

* proposed ScheduledTimeBlock
* existing blocks in overlap window

Output:

* List<TimeConflict>

TimeConflict fields:

* conflictingEntityId
* overlapMinutes
* severity
* conflictType

Severity rules:

* small overlap < medium < hard/full overlap
* extreme-mode entity conflicts escalate severity
* hard blocks (meetings/fixed tasks) escalate severity

4. Scheduling validation flow
   Before saving/editing a task:

* compute proposed block
* run ConflictDetectionEngine
* if conflicts exist:
  return structured conflict payload
  NOT hard rejection.

UI will later decide:

* reschedule
* shorten duration
* allow overlap
* replace existing block

5. Early completion support
   When task completes before expectedDuration:

* compute reclaimed time window
* emit AvailableTimeWindow event/object
* DO NOT auto-reschedule future tasks yet
* only expose suggestion hooks

6. Add analytics signals
   Track:

* overlapCreated
* overlapOverridden
* reclaimedTimeGenerated
* reclaimedTimeUsed

PHASE B — CONTEXT OVERRIDE SYSTEM
Goal:
Separate interruption permission from behavioral importance.

Implement:

1. ContextOverride enum

* none
* meeting
* focus
* sleep
* vacation
* doNotDisturb

2. UserAttentionState model
   Fields:

* activeOverride
* overrideExpiresAt
* manuallyMuted
* lastAttentionResetAt

3. ContextOverrideRepository
   Local-first Isar persistence.

4. Auto-expiry support
   Meeting/focus overrides expire automatically.

5. Vacation behavior
   Vacation suppresses reminders AND freezes streak penalties.

PHASE C — ATTENTION ORCHESTRATION
Goal:
Centralize interruption decisions.

IMPORTANT:
Do NOT remove ReminderSyncService yet.
Migrate incrementally.

Current architecture:
ReminderSyncService
→ directly schedules OS notifications

Target architecture:
ReminderSyncService
→ produces ReminderIntent

AttentionOrchestrator
→ evaluates delivery

LocalNotificationsService
→ executes approved deliveries

Implement:

1. ReminderIntent model
   Fields:

* entityId
* proposedAt
* importance
* enforcementMode
* escalationLevel
* reminderType
* sourceReason

2. AttentionOrchestrator
   Input:

* ReminderIntent
* ContextOverride
* CurrentCoachingFocus
* recent notification history
* overlapping reminder intents

Output:
AttentionDecision:

* approved
* deliverAt
* silent
* batched
* suppressedReason
* retryAllowed

3. Initial orchestration rules
   V1 deterministic only:

* suppress during meeting/focus/sleep
* delay lower-priority collisions
* prevent simultaneous notification storms
* allow batching hooks
* preserve extreme-mode persistence WITHOUT spam

4. Progressive scheduling migration
   Current system pre-schedules many notifications.
   We should migrate toward:

* scheduling next meaningful reminder only
* reevaluating after context/user interaction changes

Do NOT fully rewrite this yet.
Add abstraction points first.

5. Notification fatigue signals
   Add analytics events:

* notificationDelivered
* notificationOpened
* notificationDismissed
* notificationIgnored
* reminderSuppressed
* repeatedSnoozePattern

PHASE D — MODE REFACTOR
Goal:
Clarify behavioral responsibilities.

Global:
CoachingStyle:

* supportive
* balanced
* disciplined
* intense

Controls:

* AI tone
* accountability framing
* persistence philosophy

Per entity:
EnforcementMode:

* flexible
* disciplined
* extreme

Controls:

* escalation persistence
* streak sensitivity
* follow-up pressure
* recovery tolerance

IMPORTANT:
Extreme mode should NOT simply mean “more notifications.”
It should mean:
higher behavioral persistence with smarter delivery.

ARCHITECTURAL REQUIREMENTS

* deterministic outputs
* offline-safe
* local-first
* explainable suppression decisions
* no aggressive auto-rescheduling
* no AI-controlled interruption decisions
* preserve existing cadence engine until orchestration stabilizes

Before coding:
please map:

* which current services should remain unchanged,
* which should become adapters,
* and where abstraction seams should be introduced first to minimize migration risk.
