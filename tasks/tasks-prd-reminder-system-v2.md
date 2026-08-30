# Task list: Reminder System V2 — state-driven reminders, enforcement modes & advisory AI

Generated from [`prd-reminder-system-v2.md`](prd-reminder-system-v2.md)
(final, §12 D1–D8 settled 2026-08-30). Built on branch
`feat/reminder-system-v2`, off `feat/ux-fixes-and-stake-surrender`.

**Implementation order: R1 → R2 → R3 → R4 → R5.** Phase R1 ships alone
(PRD §11). Each phase ends with: decision-log entry in
`documentation/GUIDELINES.md`, `flutter analyze` clean, full `flutter test`
green, and an airplane-mode QA pass per FR-R-70.

---

## Phase overview

| Phase | Parent tasks | What the user can feel afterward | Ships alone |
|---|---|---|---|
| **R1** Stop the bleeding | 1.0–2.0 | Reminders stop firing when they shouldn't (no app-open misfires, no UTC drift, no lost alarm on re-sync) | **Yes** |
| **R2** State spine + heuristics | 3.0–6.0 | Nothing is silently lost — a miss becomes a visible Overdue + Recovery Card; goals re-arm without the app | No |
| **R3** Ladder engine | 7.0–10.0 | The ladder actually escalates; the three modes become real and audible | No |
| **R4** AI layer | 11.0–12.0 | Classification is smart, copy is warm, the strategist suggests | No |
| **R5** Push floor | 13.0 | Extreme tail + criticality-3 rescue survive a closed app | No |

---

## Current-state assessment

Verified against the code on this branch (2026-08-30) before writing these
tasks. Every AUDIT §10 finding the PRD cites still stands:

- **Reconciliation** (`notification_reconciliation_service.dart:59`) reads only
  `getActiveNotifications()` — the delivered tray. `pendingNotificationRequests()`
  exists at `local_notifications_service.dart:275` but is not wired in. Its
  injectable interface `ActiveNotificationsSource` (lines 10–14) exposes only
  `getActiveNotifications` + `cancel`, so **FR-R-01 is an interface change**,
  not just a body change — the test double in
  `test/core/notifications/notification_reconciliation_service_test.dart`
  moves with it.
- **`AdaptiveReminderPolicy.autoRepeatOffsets`** has zero callers in `lib/`
  (only two in its own test). The per-mode repeat plans are genuinely dead
  code — R3 is where they come alive (C2).
- **`onOverrideEnded`** (`attention_orchestrator_service.dart:222`) has zero
  production callers; the suppressed queue is in-memory and process-lifetime
  only (C5) — R3, FR-R-32.
- **`RoutineModePolicy.baseSnoozeMinutes`** has four live consumers in
  `lib/features/planning/application/routine_mode_policy_resolver.dart`, not
  in the reminders feature. **FR-R-07 ripples into planning** — bigger than
  it reads.
- **`ReminderConfig`** (`reminder_config.dart`) already carries
  `escalationLevel`, `pendingAction`, `lastTriggeredAtMs`, `nextPromptAtIso`,
  plus two decorative fields (`activeNotificationId`, `evaluationTrace` — L3,
  never written). It is a plain map-serialized model with an Isar mirror
  (`isar_reminder.dart`, registered at `isar_collections/isar_schemas.dart:51`)
  and a pull phase (`remote_isar_merge.dart:245 _pullReminders`). The V2 state
  fields extend this existing set — **no new collection is needed for task
  reminder state**; the local-first set is already in place.
- **`copyWith` cannot clear nullables** (L4) — a trap for every new nullable
  field V2 adds (`overdueSinceMs`, resolution reason). Fix it once, in R1 or
  early R2, before the new fields land on top of it.
- **Home** already hosts precedent cards for the Recovery Card slot:
  `SeizeTheMomentCard` (`home_screen.dart:199`) and `PostOverrideReviewCard`
  (line 203). Reuse that placement and the `_NeonCard` shell (line 2227).
- **Settings** has a 34-line `notification_settings_screen.dart` — the health
  row (FR-R-80) lands there with room to spare.
- **Notification copy today** lives in two disconnected places:
  `ReminderSyncService.bodyForReminder` (the mode/escalation copy, no caller
  on the delivery path — M2) and
  `AttentionOrchestratorService._buildNotificationBody` (always "Time to
  start: X"). The template bank consolidates both.
- **Cloud Functions** (`functions/src/`) already has the AI proxy pattern
  (`ai_routing.ts`, `coach_prompts.ts`) and the sweep-cron pattern
  (`intentions/`) that R4 and R5 extend. Note the **pending
  `firebase deploy --only functions`** carried over from the previous branch —
  R4/R5 stack on top of an undeployed functions tree.

- **`RoutineModePolicy.baseSnoozeMinutes` is never actually read to produce a
  delay.** All 15 references are the model's own definition/serialization, the
  resolver's four tightening branches, and two test assertions — no code path
  consumes it to snooze anything. `requestSnooze` (the only live snooze path,
  called solely from the notification "Later" action) reads
  `AdaptiveReminderPolicy` alone. **FR-R-07 is therefore a deletion, not a
  migration:** the second table is dead, and the risk it names is a *future*
  in-app defer surface picking the wrong one.

### Two sequencing notes that differ from PRD §11

1. **The deterministic half of FR-R-63 (the template bank) must land in R3,
   not R4.** FR-R-34 requires every compiled slot to carry a pre-written
   string, and §11 puts FR-R-34 in R3 but FR-R-63 in R4. R3 therefore builds
   the template bank (the permanent offline fallback); R4 adds only the AI
   variants on top. Flagged rather than silently reordered.
2. **`copyWith` (L4) is R1-adjacent debt.** It is not in FR-R-01…08, but
   every V2 nullable added in R2 inherits the bug. Proposed as a sub-task of
   1.0 so the state spine builds on a sound `copyWith`.

---

## Tasks

### Phase R1 — Stop the bleeding *(ships alone)*

- [x] **1.0 Delivery correctness: reconciliation, ordering and races**
      *(FR-R-01, 02, 03, 08; AUDIT T1, C6, L2, L4)*
  - [x] 1.1 Add `pendingNotificationRequests()` to the `ActiveNotificationsSource`
        interface. `LocalNotificationsService` already implements the method
        (`local_notifications_service.dart:275`) and already declares the
        interface (line 25), so the real adapter needs no new logic; update the
        fake in `notification_reconciliation_service_test.dart` to model both
        queues independently.
  - [x] 1.2 Rewrite `_reconcile()` step 3 against `armed = pending ∪ tray`. A
        `scheduled`/`delivered` ledger row present in **either** queue is
        healthy — leave it alone. Only a row missing from **both** is acted on.
  - [x] 1.3 Split that action by time: a row whose `scheduledForMs` is still in
        the **future** re-arms at its **original** time; a row whose time has
        **passed** is marked cancelled and left for the state machine, with an
        explicit `// R2:` seam comment. Neither path may reach `showNow`.
  - [x] 1.4 Use `markCancelledByNotifId(entry.notifId)` instead of the
        entity-scoped `markCancelled(entry.entityId)` so reconciling one slot of
        a multi-slot entity (intention ladders) cannot cancel its siblings.
  - [x] 1.5 Widen the phantom pass's ledger id set to every non-`cancelled`
        state (not just `scheduled`/`delivered`), so a row a snooze race left in
        `snoozed` state no longer gets its live tray notification deleted
        (T1 step 4 / L2's downstream damage).
  - [x] 1.6 Rewrite `reEvaluateIfAppropriate` to `(entityId, {DateTime?
        scheduledFor})`: return early when the config is missing or
        `enabled == false`; resolve the time from `scheduledFor ??
        config.scheduledAtIso`; return early when that time is not in the
        future. It may never build an intent with `proposedAt: _now()`.
  - [x] 1.7 Move `_applyReminders`' unconditional `cancelForEntity` so it fires
        **only** on the paths that will not evaluate (disabled reminder, null
        next time, null intent). When an intent is evaluated, the orchestrator's
        own post-budget cancel performs the swap — matching
        `goal_reminder_sync_service.dart:95-99`. (C6)
  - [x] 1.8 Await `onInteractionReceived(snoozed)` before `requestSnooze` in
        `notification_response_handler.dart:461-471` so the ledger write cannot
        stamp the newly scheduled row. (L2)
  - [x] 1.9 Give `ReminderConfig.copyWith` sentinel-based clearing for its
        nullables (`scheduledAtIso`, `nextPromptAtIso`, `lastTriggeredAtMs`,
        `activeNotificationId`), so `_resolveReminder`'s `nextPromptAtIso: null`
        actually clears. Pre-work for every nullable R2 adds. (L4)
  - [x] 1.10 Tests: reconciliation against both queues (future row re-arms at
        original time / past row does not deliver / row in pending is untouched
        / phantom pass spares snoozed rows), `reEvaluateIfAppropriate` respects
        `enabled` and never fires early, `_applyReminders` keeps the armed slot
        when evaluation is suppressed, and `copyWith` can clear.

- [x] **2.0 Escalation, ignore and cadence integrity**
      *(FR-R-04, 05, 06, 07; AUDIT M2, C7, T3, T5)*
  - [x] 2.1 Persist the incremented `escalationLevel` back to the config in
        `_scheduleFollowUp` before evaluating the follow-up intent, so the
        ladder climbs on ignores and not only on snoozes. (M2)
  - [x] 2.2 Stamp `lastTriggeredAtMs` (and clear/advance the pending marker)
        when the ignored path records an ignore, so one missed notification is
        counted once rather than once per app-open. (C7)
  - [x] 2.3 Surface timezone-resolution failure: keep a resolved/unresolved flag
        on the notifications service, retry `_configureLocalTimeZone` on
        foreground resume, and expose the state for the FR-R-80 health row
        instead of silently scheduling every reminder in UTC. (T3)
  - [x] 2.4 Delete `RoutineModePolicy.baseSnoozeMinutes` (model field,
        serialization, the four resolver tightening branches, the two test
        assertions), leaving `AdaptiveReminderPolicy` as the sole documented
        cadence source with a comment saying so. (T5)
  - [x] 2.5 Tests: escalation persists across an ignore; a second resume inside
        the window does not re-count the same ignore; timezone failure sets the
        unresolved flag and a later resume clears it.

### Phase R2 — State spine + heuristics

- [x] **3.0 Task reminder state machine** *(FR-R-10…14)*
      **Settled 2026-08-30:** occurrence state lives in a NEW
      `ReminderOccurrence` entity keyed `entityKind|entityId|dateKey` (the
      `IsarGoalCheckIn` pattern), shared by tasks and goals — not on
      `ReminderConfig`, which stays the user's long-lived *config*. Recurring
      task roll-forward (C3) is folded in here alongside the goal double-arm
      (C4) — but see the C3 note: there is no task recurrence model, so C3's
      real subject is the carry-forward flow.
  - [x] 3.1 Extend `ReminderConfig` + `IsarReminder` with `state`, `taxonomy`,
        `criticality`, `windowMinutes`, `ladderPosition`, `overdueSinceMs`,
        `resolutionKind`, `resolutionReason`, `classificationSource`,
        `classifierVersion`; regenerate with build_runner.
  - [x] 3.2 Extend `toMap`/`fromMap` and the merge phase so the new fields
        replicate LWW on `updatedAtMs`; migrate existing rows to
        `{flexible, criticality 1, source: migration}` (PRD §9).
        *Backfill is horizon-bounded: configs scheduled before the start of
        today are NOT resurrected, so upgrading does not greet the user with
        a wall of months-old misses.*
  - [x] 3.3 Write the pure transition module (`reminder_state_machine.dart`):
        `advance(config, now, plan, interactions) → ReminderState` with an
        injected clock and zero I/O.
  - [x] 3.4 Make Due→Overdue/Expired retroactive — evaluated from
        `windowEnd` vs `now`, never requiring the app to have been alive.
  - [x] 3.5 Call the machine from every [L-ALIVE] trigger (app open, resume,
        timer end, check-in, day change, override end) via the recompute graph.
  - [x] 3.6 Cancel remaining slots + write state in the same gesture on
        complete / start / delete / reschedule.
  - [x] 3.7 Arm the **next** goal occurrence at the same time as the current one
        (two armed max) so a missed app-open cannot silence a daily goal. (C4)
        *Slot-aware `idFromGoalId(id, slot:)` mirrored in the route resolver;
        slot 0 keeps its historic derivation so an upgrade cannot orphan an
        armed notification. Goals joined the multi-slot cancel path.*
  - [x] 3.8 Tests: retroactive transition with a fake clock; goal double-arm;
        resolution cancels slots; migration defaults.

- [x] **4.0 Heuristic classifier + user override** *(FR-R-20, 21, 23)*
  - [x] 4.1 One pure `classify(title, hasReminderTime, duration, category,
        isHabitAnchor) → {taxonomy, criticality, rule}` implementing FR-R-20,
        adapted to this app's real vocabulary (settled 2026-08-30: habit
        anchor is the routine signal; heuristic caps criticality at 2).
  - [x] 4.2 Golden-set test: ≥ 30 titles → expected class, run in CI.
  - [x] 4.3 Call it synchronously at task creation and on material edit; write
        `classificationSource: heuristic`.
  - [x] 4.4 Task-editor row: three-way class chip + a `critical` toggle shown
        only for `timeSensitive`; a user change sets `classificationSource:
        user` and is never overwritten.
  - [x] 4.5 Guard: classification may never flip `enabled` off. (FR-R-23)

- [x] **5.0 Recovery & overdue surfacing** *(FR-R-50…54)*
  - [x] 5.1 `Recovery Card` widget — top of Home when non-empty, alongside
        `SeizeTheMomentCard`/`PostOverrideReviewCard`; `SectionHeader`, tokens
        only, ordered criticality desc → overdue-since asc, one primary action
        per row.
  - [x] 5.2 Per-mode affordances on each row (Flexible dismissible /
        Disciplined persistent / Extreme non-dismissible) reading
        `EffectiveTaskMode`.
  - [x] 5.3 Same content as a post-session prompt at timer/focus completion.
  - [x] 5.4 Routine-class misses collapse to one digest line — never a row per
        miss, never a push. *The PRD's "Water: 3 of 6 today" assumes intra-day
        recurrence, which this app does not have (one occurrence per entity per
        day); the digest names the routines missed instead.*
  - [x] 5.5 Aggregated recovery notification — built in R3 once FR-R-31's
        boundary math existed. ONE summary for everything open, ≤2/day capped
        against the ledger, placed by the pure `RecoveryGapFinder`.
  - [x] 5.6 Day rollover carries unresolved items into Plan-Tomorrow with their
        overdue history attached.
  - [x] 5.7 Task-row Overdue badge in the task list.

- [x] **6.0 Observability & health** *(FR-R-80…82)*
  - [x] 6.1 "Reminder health" row in `notification_settings_screen.dart`:
        permission state, pending-queue usage vs budget, timezone state, last
        reconciliation result, [L-PUSH] registration.
  - [x] 6.2 One quiet dismissible Home hint on any red condition (sync-line
        pattern).
  - [x] 6.3 Full slot lifecycle in the ledger (scheduled → fired-detected →
        interacted/ignored → cancelled/expired).
  - [x] 6.4 Fired-detection pass at [L-ALIVE] via tray + pending diff, so
        `delivered` finally means delivered. (L1)
  - [x] 6.5 Tester-gated debug screen listing every armed OS notification with
        its ladder slot, entity and scheduled time.

### Phase R3 — Ladder engine

- [x] **7.0 Ladder compiler: slots, boundary, shield, budget** *(FR-R-30…33)*
  - [x] 7.1 Move the per-mode ladder shapes + window defaults (D2: 30/45/60)
        into `AdaptiveReminderPolicy` as the single source.
  - [x] 7.2 Pure `compileSlots(config, plan, shields, now) → List<SlotSpec>`.
  - [x] 7.3 Boundary pruning: drop slots ≥ `nextBoundary` (next scheduled item
        − 20 min, D1), computed at scheduling time from the plan.
  - [x] 7.4 Shield pruning for known windows (scheduled focus blocks, sleep
        window); criticality 3 pierces boundary **and** sleep (D5) but still
        stops hard at `windowEnd`.
  - [x] 7.5 Budget policy under the 64-cap: full ladders today only, T+0 for
        tomorrow+, ≤ 2 goal occurrences, intentions keep 3; drop order
        criticality desc → soonest first → deepest slot first; every drop
        ledger-logged.
  - [x] 7.6 Property test: no compiled slot violates boundary, shield, budget
        or window rules.
  - [x] 7.7 Android gate (D8): ladders scheduled `inexactAllowWhileIdle`, with
        the health row stating reminders may arrive late.

- [x] **8.0 Template bank + pre-written slot strings** *(FR-R-63 deterministic
      half, FR-R-34 — see sequencing note 1)*
  - [x] 8.1 One bank keyed by (mode, escalation step, taxonomy, entity kind),
        absorbing today's orphaned `ReminderSyncService.bodyForReminder` and
        the generic `_buildNotificationBody`.
  - [x] 8.2 Every `SlotSpec` carries its final title/body + payload; delivery
        composes nothing.
  - [x] 8.3 Fix the batched-body path so it renders titles, not raw `ri_…`
        intent ids. (M4)
  - [x] 8.4 Coverage test: every (mode × step × taxonomy) combination resolves
        to a non-empty string.

- [x] **9.0 Modes as resolution contracts + OS interruption levels**
      *(FR-R-35, 40…44)*
  - [x] 9.1 Per-slot interaction contract: Done / Later (single unified snooze)
        / Wrong time (closes window now) / plain tap; any interaction cancels
        remaining slots.
  - [x] 9.2 Flexible: dismissible card entry, rolls into Plan-Tomorrow as a
        suggestion, no reason required.
  - [x] 9.3 Disciplined: persistent entry demanding Do now / Reschedule / Skip;
        one inline Plan-Tomorrow prompt, carry forward if unanswered — soft nag,
        never a hard gate (D3).
  - [x] 9.4 Extreme: non-dismissible entry; reschedule requires a non-empty
        reason logged to the accountability log (D4's UNSTAKED contract).
        *D4's staked branch has no subject for a task: stakes attach to GOALS
        in this codebase (`goal_actions.dart` owns liveStake + the surrender
        callable), so a staked goal keeps its existing surrender flow and a
        task gets Do / Reschedule-with-reason only.*
  - [x] 9.5 Demote-or-drop coach suggestion after 3 consecutive reschedules of
        the same task — suggestion only, user decides (D4).
  - [x] 9.6 Unknown/custom `modeRefId` degrades to Flexible **with a ledger
        note** instead of silently. (M3)
  - [x] 9.7 Map `InterruptionLevel` to the OS: Android channels per level
        (low/default/high), iOS `interruptionLevel` passive/active/timeSensitive
        where entitled; `AttentionDecision.silent` delivers passive. (M1)

- [x] **10.0 Offline & failure hardening** *(FR-R-70…72)*
  - [x] 10.1 Integration test walking the real service layer with a fake clock
        and fake OS queues: scheduled → fired → ignored → overdue → recovery.
        *Covered by `airplane_mode_acceptance_test.dart`, which walks the same
        chain with no network seam at all; the per-mode differences are pinned
        by the compiler, copy-bank and recovery-view suites.*
  - [x] 10.2 Airplane-mode acceptance test: create → classify → compile →
        deliver → boundary → Overdue → Recovery Card → resolve, zero network.
  - [x] 10.3 Drop `hydrateFromRemoteForTasks` from the awaited save path; arm
        from local state first, hydrate in the background merge. (C8)
  - [x] 10.4 Wire `onOverrideEnded` from `ContextOverrideService._doEnd` and
        the expiry poller, and persist the suppressed queue so a kill doesn't
        lose it. (C5)
  - [x] 10.5 Each named failure story from FR-R-71 wired to its outcome, with a
        test per story.

### Phase R4 — AI layer *(tier-gated; advisory only)*

- [ ] **11.0 `classifyTask` endpoint + background upgrade path**
      *(FR-R-22, 60, 64, 65)*
  - [ ] 11.1 Cloud Function beside `ai_routing.ts`: owned prompt, App Check,
        strict JSON schema, Haiku-class model, per-user token budget.
  - [ ] 11.2 Fire-and-forget client call after the local save; result lands as a
        normal Isar write → reminder recompile.
  - [ ] 11.3 Batch variant for Plan-Tomorrow (N tasks, 1 call).
  - [ ] 11.4 `classifierVersion` gating — re-classify only on material
        title/time change; never overwrite `classificationSource: user`.
  - [ ] 11.5 Guardrails in code: AI cannot disable/delete a reminder, exceed
        ladder bounds, or soften Extreme; invalid output is discarded silently.
  - [ ] 11.6 Tier gate: heuristics free, AI classification Pro.

- [ ] **12.0 Strategist, triage and AI copy variants** *(FR-R-61, 62, 63 AI half)*
  - [ ] 12.1 Locally pre-computed aggregates into the Thinking Loop bundle
        (delivered/opened/ignored/snoozed/wrong-time counts, engagement-by-hour,
        overdue history, mode) — raw ledger rows never leave the device.
  - [ ] 12.2 Strict-schema proposals (`rescheduleSuggestion`, `ladderTuning`
        clamped to mode bounds, `aggregateSuggestion`, `dropSuggestion`).
  - [ ] 12.3 Surface in morning brief / coach with one-tap apply, `source:
        ai_strategist` provenance and undo. **No auto-apply** (D7).
  - [ ] 12.4 Recovery triage: ≥ 3 unresolved + connectivity → one bounded call
        rendered as a suggestion header; the card renders immediately and
        enhances only if the response arrives.
  - [ ] 12.5 AI copy variants stored on the config row, used verbatim by
        [L-PRE]; template bank stays the fallback.
  - [ ] 12.6 Cost ceiling per FR-R-64, with silent degradation on exhaustion.

### Phase R5 — Push floor

- [ ] **13.0 Server rescue net for Extreme tails and criticality 3**
  - [ ] 13.1 Device heartbeat written on each [L-ALIVE] pass.
  - [ ] 13.2 Extend the `functions/src/intentions/sweep.ts` cron: for
        Extreme-mode and criticality-3 items unseen past their heartbeat,
        deliver the ladder tail and overdue-recovery push.
  - [ ] 13.3 Idempotency against locally delivered slots (no double-fire).
  - [ ] 13.4 Health-row registration state, and UX copy that promises nothing
        depending on push when it is unavailable.

---

## Relevant Files

### Phase R1
- `lib/core/notifications/notification_reconciliation_service.dart` — pending ∪ tray reconciliation; the `ActiveNotificationsSource` interface change (1.1–1.5).
- `lib/core/notifications/local_notifications_service.dart` — already implements `pendingNotificationRequests`; timezone retry + resolved flag (2.3).
- `lib/features/reminders/application/attention_orchestrator_service.dart` — `reEvaluateIfAppropriate` rewrite (1.6), escalation persistence (2.1), ignore stamping (2.2).
- `lib/features/reminders/application/reminder_sync_service.dart` — cancel-after-approval in `_applyReminders` (1.7).
- `lib/app/notification_response_handler.dart` — snooze sequencing (1.8).
- `lib/features/reminders/domain/models/reminder_config.dart` — `copyWith` sentinels (1.9).
- `lib/features/planning/domain/models/routine_mode.dart` + `lib/features/planning/application/routine_mode_policy_resolver.dart` — `baseSnoozeMinutes` deletion (2.4).
- `test/core/notifications/notification_reconciliation_service_test.dart` — two-queue fake + the new cases (1.10).
- `test/features/reminders/attention_orchestrator_test.dart`, `test/features/reminders/reminder_sync_service_test.dart`, `test/features/planning/routine_mode_policy_resolver_test.dart` — updated assertions.

### Phase R2
- `lib/features/reminders/domain/models/reminder_config.dart`, `lib/core/local_db/isar_collections/isar_reminder.dart` (+ `.g.dart`) — new state fields (3.1).
- `lib/core/sync/remote_isar_merge.dart` (`_pullReminders`, line 245) — merge the new fields (3.2).
- `lib/features/reminders/application/reminder_state_machine.dart` — **new**, pure transitions (3.3–3.4).
- `lib/core/runtime/unified_recompute_graph.dart` — [L-ALIVE] trigger wiring (3.5).
- `lib/features/goals/application/goal_reminder_sync_service.dart` — two armed occurrences (3.7).
- `lib/features/reminders/application/reminder_classifier.dart` — **new**, heuristic rules (4.1).
- `lib/features/add_task/presentation/sections/add_task_reminder_section.dart` — class chip + critical toggle (4.4).
- `lib/features/home/presentation/widgets/recovery_card.dart` — **new** (5.1–5.2).
- `lib/features/home/presentation/home_screen.dart` — card placement beside `SeizeTheMomentCard` (5.1).
- `lib/features/plan_tomorrow/presentation/plan_tomorrow_screen.dart` — overdue carry-in (5.6).
- `lib/features/settings/presentation/notification_settings_screen.dart` — health row (6.1).
- `lib/core/notifications/notification_ledger_repository.dart` — lifecycle states + fired detection (6.3–6.4).
- Tests: `test/features/reminders/reminder_state_machine_test.dart`, `reminder_classifier_golden_test.dart`, `test/features/home/recovery_card_test.dart`.

### Phase R3
- `lib/features/reminders/application/adaptive_reminder_policy.dart` — single cadence source, ladder shapes (7.1).
- `lib/features/reminders/application/ladder_compiler.dart` — **new**, `compileSlots` (7.2–7.5).
- `lib/features/reminders/domain/models/slot_spec.dart` — **new** (7.2).
- `lib/core/notifications/notification_budget.dart` — drop order + logging (7.5).
- `lib/features/reminders/application/reminder_copy_bank.dart` — **new** template bank (8.1–8.3).
- `lib/features/reminders/application/interruption_level_resolver.dart` + `local_notifications_service.dart` — OS level mapping, Android channels (9.7).
- `lib/features/context_override/application/context_override_service.dart` — `onOverrideEnded` wiring (10.4).
- Tests: `test/features/reminders/ladder_compiler_test.dart` (+ property test), `reminder_copy_bank_test.dart`, `test/integration/reminder_lifecycle_test.dart`.

### Phase R4
- `functions/src/reminders/classify_task.ts` — **new** (11.1).
- `functions/src/ai_routing.ts`, `functions/src/coach_prompts.ts` — registry + prompt (11.1).
- `lib/features/thinking/application/thinking_loop_service.dart`, `reflection_payload.dart` — strategist aggregates + proposals (12.1–12.2).
- `lib/features/reminders/application/reminder_strategist_proposals.dart` — **new** apply/undo (12.3).

### Phase R5
- `functions/src/intentions/sweep.ts` — the cron pattern to extend (13.2).
- `functions/src/reminders/sweep.ts` — **new** (13.2–13.3).

### Notes

- Run `flutter analyze` and the full `flutter test` after each parent task;
  `test/` carries a known ~97-issue analyze baseline.
- `test/architecture/local_first_guard_test.dart` enforces the no-awaited-
  Firestore rule — 10.3 must keep it green.
- Any new synced field ships the full set per CLAUDE.md: Isar collection +
  outbox write path + watch provider + `remote_isar_merge` pull phase.
- Decision-log entry in `documentation/GUIDELINES.md` at the end of every
  phase, not every task.
