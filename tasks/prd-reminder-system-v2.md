# PRD — Reminder System V2: State-Driven Reminders, Enforcement Modes & Advisory AI

_Drafted 2026-08-30, from the notifications deep audits (AUDIT.md §9 GPT / §10
Claude, both 2026-08-30) and the design discussion that followed. Supersedes
the delivery behavior of prd-phase-c-attention-orchestration.md and the
cadence portions of prd-phase-d-mode-refactor.md; the Phase B/C machinery
(overrides, orchestrator, ledger) is retained and completed, not replaced._

---

## 1. Introduction / Overview

Today a reminder in SidePal fires **once** and then goes silent: the
escalation machine only starts if the user taps "Later" (AUDIT §10 C1), the
per-mode repeat plans are dead code (C2), one-shot reminders never roll
forward (C3/C4), and boot reconciliation fires future reminders early at app
open (T1). The three enforcement modes (Flexible / Disciplined / Extreme)
exist as tested policy math with almost no behavioral difference the user can
feel.

V2 rebuilds reminders around one principle:

> **SidePal should make you remember, without constantly interrupting what
> you're doing now. It never reminds you just because a timer says so — it
> reminds you because it's the right moment.**

Concretely, that means:

1. **Task state + time windows + priority** drive reminders — not blind
   repetition. Missing a task makes it *Overdue* (a visible state), not
   *forgotten* and not *nagged forever*.
2. **The next scheduled task is an interruption boundary.** Escalation for
   task A stops before task B begins; A comes back at a recovery moment.
3. **Modes differ primarily in what resolution an overdue task demands**
   (their accountability contract), and only secondarily in notification
   pressure.
4. **AI supplies judgment, never delivery.** Classification, pattern insight,
   copy, and triage are AI; scheduling, boundaries, and state transitions are
   deterministic local code that works in airplane mode.

### The one architecture rule (protect this in every review)

**AI and the network never sit in the delivery path.** Every notification
that fires was pre-scheduled from Isar-resident data with Isar-resident
strings. AI writes to Isar in the background (optimistic-then-honest); the
delivery engine only reads Isar. A reminder must never *wait* on an AI
response, a Firestore read, or any network call.

---

## 2. Goals

1. A reminder for an unfinished task is never silently lost: it either
   fires per its mode's ladder, expires by explicit taxonomy rule, or
   surfaces as Overdue at a recovery moment.
2. Zero spurious deliveries: no reminder fires early, at app-open, or after
   its task is completed/deleted (fixes AUDIT §10 T1).
3. The three modes produce visibly different behavior a user can describe
   after one week of use.
4. Airplane mode is indistinguishable from online for every delivery, state
   change, and mode behavior (CLAUDE.md rule 2).
5. AI features degrade silently to deterministic heuristics; total AI cost
   ≤ ~$0.15 per active user per month at expected usage.
6. Notification pressure is bounded: hard daily caps, aggregation for
   routine tasks, and the interruption boundary prevent "🔔🔔🔔🔔" under
   every mode, including Extreme.

---

## 3. Definitions

### 3.1 Task lifecycle states

Every planned task (and each goal occurrence) moves through:

```
Upcoming → Due → [Active] → Overdue → Resolved
                                        ├─ Completed
                                        ├─ Skipped        (with/without reason, per mode)
                                        ├─ Rescheduled    (rolls to a new time)
                                        └─ Expired        (time-sensitive tasks only)
```

- **Upcoming** — scheduled time in the future.
- **Due** — inside the reminder window (scheduled time reached, ladder live).
- **Active** — the user started it (timer/focus start, or explicit check-in).
  Active is an *opt-in* signal; tasks may go Due → Overdue without ever
  being Active.
- **Overdue** — the reminder window closed without resolution. Overdue is a
  first-class visible state (badge on the task row, Home recovery card),
  never a silent one.
- **Resolved** — terminal. `Expired` applies only to time-sensitive tasks
  (see 3.2) and is recorded as missed for analytics/streaks without any
  further reminding.

### 3.2 Time-sensitivity taxonomy (per task)

| Class | Meaning | After the window closes |
|---|---|---|
| 🔴 `timeSensitive` | Less useful or impossible later ("Join meeting 2 PM", "Take medication") | **Expires.** No overdue nagging. Logged as missed. Criticality ≥2 may pierce boundary/shield while still Due. |
| 🟡 `flexible` | Still worth doing later ("Study 1 hr") | Becomes **Overdue**; surfaces at recovery moments. Default class. |
| 🔵 `routine` | Recurs; individual misses are low-stakes ("Drink water") | Rolls forward silently; misses **aggregate** into at most one daily digest line. Never escalates. |

Plus **`criticality` 0–3** (0 = nice-to-do … 3 = critical, e.g. medication).
Criticality 3 is the only thing allowed to pierce the interruption boundary
and Focus Shield.

### 3.3 Reminder window & ladder

Each Due task has a **reminder window**: `[scheduledAt, windowEnd)` where
`windowEnd = min(scheduledAt + windowMinutes, nextBoundary)`. Inside the
window the mode's **ladder** (a small pre-scheduled set of notifications)
runs. At `windowEnd` the task transitions per its taxonomy (Overdue /
Expired / roll-forward).

### 3.4 Interruption boundary

`nextBoundary` = start time of the user's next scheduled task/block that day,
minus a **boundary buffer** (default 20 min). No ladder slot for task A may
be scheduled at or after A's `nextBoundary` — computed **at scheduling
time** from the plan (this is what makes the whole design implementable with
pre-scheduled local notifications).

### 3.5 Focus Shield

While a task is **Active** (timer/focus running) or a context override is
active, reminders for *other* entities are withheld unless criticality 3.
Withheld ≠ deleted: the entity's state machine continues; it surfaces at the
next recovery moment. (This completes Phase B/C suppression, whose queue is
currently never flushed — AUDIT §10 C5.)

### 3.6 Recovery moments

App-alive moments where SidePal may surface unresolved work:

1. Timer/focus session completion (the strongest moment).
2. Task check-in / completion of any other task.
3. App open / foreground resume (throttled: ≥ 30 min since last surface).
4. Day rollover & Plan-Tomorrow flow (unresolved tasks demand disposition).
5. Context override end.

Recovery UI = the **Recovery Card** (Home) + the same content at timer-end.
At most **2 aggregated recovery notifications per day** may also be
scheduled into genuine free gaps (≥ 15 min before day end, no boundary
conflict) — one summary ("2 tasks need your attention"), never N
individual notifications.

---

## 4. User stories

- As a user who missed a 2 PM study block, I get a reminder at 2:00 and a
  follow-up or two — then SidePal goes quiet because my 3 PM workout is
  coming, and after the workout it says "Study from 2 PM is still open —
  do now or reschedule?" It never forgot, and it never spammed me.
- As a user on medication, my 2 PM meds reminder keeps escalating even
  through my workout — because I marked it critical — but once 3 PM passes
  it stops and is honestly logged as missed, not nagged at 9 PM.
- As an Extreme-mode user with a staked challenge, an overdue task confronts
  me at every recovery moment until I do it, reschedule it **with a reason**,
  or surrender the stake. The app doesn't scream; it refuses to look away.
- As a Flexible-mode user, "drink water" misses just quietly accumulate into
  one evening digest line.
- As a user with a bad connection, everything above works identically in
  airplane mode; the app just gets slightly less clever about wording and
  timing suggestions until I'm back online.
- As a user, when I create "Call the bank when they open," SidePal already
  knows it's time-sensitive without asking me anything.

---

## 5. System architecture — the three execution layers

Every requirement below belongs to exactly one layer. The PRD marks which.

- **[L-PRE] Pre-computed local schedule.** At every (re)plan, the engine
  compiles each Due-eligible task's ladder — slots, boundary pruning, shield
  windows, expiry — into concrete `zonedSchedule` calls with pre-written
  strings, within the iOS 64-pending budget. Interactions cancel remaining
  slots. This layer is 100% offline and is the correctness floor.
- **[L-ALIVE] App-alive recompute.** On app open, resume, timer end,
  check-in, day change, override end: advance state machines (Due→Overdue,
  expiry), re-arm next occurrences, surface recovery UI, reconcile ledger vs
  OS queues. All local reads.
- **[L-PUSH] Server push floor.** The existing intention sweep-cron pattern
  (functions/src/intentions/sweep.ts), extended: for Extreme-mode tasks and
  criticality-3 items, a server cron can deliver the ladder tail and
  overdue-recovery push when the device hasn't been seen (heartbeat) —
  closed-app persistence. This layer is an enhancement, never a dependency.

---

## 6. Functional requirements

### FR-R-0x — Prerequisite repairs (before any new behavior)

These fix AUDIT §10 findings that would poison V2 if inherited.

- **FR-R-01.** Boot reconciliation must compare ledger `scheduled` rows
  against `pendingNotificationRequests() ∪ getActiveNotifications()`, and
  must never re-deliver a future-scheduled reminder as immediate. A ledger
  row missing from *both* OS queues re-arms at its **original** time (if
  future) or enters the state machine (if past) — never `showNow`. (T1)
- **FR-R-02.** `reEvaluateIfAppropriate` (or its successor) must respect
  `enabled` and the stored scheduled time. (T1)
- **FR-R-03.** The task re-sync path must cancel an armed notification only
  **after** its replacement is approved and scheduled (matching the goal
  path's ordering). (C6)
- **FR-R-04.** Escalation/ladder position must be persisted on every
  follow-up, not only on snooze. (M2)
- **FR-R-05.** The ignored-detector must stamp the reminder
  (`lastTriggeredAtMs`/ladder position) when recording an ignore so one
  missed notification cannot be counted once per app-open. (C7)
- **FR-R-06.** Timezone-resolution failure must not silently fall back to
  UTC scheduling: retry on next resume, and surface a one-line health notice
  (see FR-R-8x) while unresolved. (T3)
- **FR-R-07.** One snooze-duration table. `RoutineModePolicy.baseSnoozeMinutes`
  is removed or delegated to `AdaptiveReminderPolicy`; every surface
  ("Later" action, in-app defer) reads the same cadence source. (T5)
- **FR-R-08.** The snooze response path must be sequenced (no unawaited
  ledger write racing the reschedule). (L2)

### FR-R-1x — Task & reminder state machine [L-ALIVE]

- **FR-R-10.** The system must persist, per task-with-reminder, the state
  from §3.1 plus: taxonomy class, criticality, `windowMinutes`, ladder
  position, `overdueSinceMs`, and resolution (kind + optional reason).
  Stored in Isar, replicated via outbox, LWW on `updatedAtMs` (a synced
  entity per CLAUDE.md — Isar collection + outbox + watch provider + merge
  phase).
- **FR-R-11.** State transitions are computed by pure functions of
  (config, now, plan, interactions) — unit-testable with an injected clock;
  no I/O in the transition logic.
- **FR-R-12.** Due → Overdue/Expired transitions are evaluated at every
  [L-ALIVE] trigger and at ladder-slot delivery handling. They must never
  require the app to have been alive at `windowEnd` — evaluation is
  retroactive ("windowEnd was 3:10 PM, it is now 6 PM, therefore Overdue
  since 3:10").
- **FR-R-13.** Completing / starting / deleting / rescheduling a task
  cancels its remaining ladder slots and updates state in the same user
  gesture (local write + cancel; no network).
- **FR-R-14.** Goal occurrences use the same machine: each armed occurrence
  is a Due-eligible item; a fired-but-unresolved occurrence becomes Overdue
  (flexible-class) or rolls forward (routine-class goals), and — unlike
  today (C4) — the **next** occurrence is armed at the same time the current
  one is scheduled, so one missed app-open cannot silence a daily goal.
  (Two armed occurrences per goal max, within budget.)

### FR-R-2x — Classification [L-ALIVE + AI]

- **FR-R-20 (heuristic floor, ships first).** A local, rule-based classifier
  assigns `{class, criticality}` at creation, synchronously, offline:
  - explicit clock time + duration ≤ 30 min + category work/meeting →
    `timeSensitive`;
  - title matches med/meeting/call/appointment keyword list →
    `timeSensitive`, criticality 2 (meds: 3);
  - recurring + category health/hydration/chore → `routine`;
  - everything else → `flexible`, criticality 1.
  The rules live in one pure function with a golden-set test (≥ 30 titles →
  expected class) run in CI.
- **FR-R-21.** The user can always see and override the classification in
  the task editor (a small three-way chip + a "critical" toggle shown only
  for timeSensitive). A user override sets `classificationSource: user` and
  is never overwritten by AI.
- **FR-R-22 (AI upgrade, background).** After local save, a fire-and-forget
  call to a `classifyTask` Cloud Function (owned prompt, App Check,
  per-user token budget, strict JSON schema, Haiku-class model) may upgrade
  `heuristic` classifications. Result lands as a normal Isar write →
  reminder recompile. Batch variant for Plan-Tomorrow (N tasks, 1 call).
  Invalid/failed/slow response → heuristic stands, silently, retry only on
  material edit. `classifierVersion` stored; re-classify only when
  title/time materially change.
- **FR-R-23.** Classification (from any source) can never disable a reminder
  the user explicitly configured; it only selects taxonomy/ladder shape.

### FR-R-3x — Ladders, boundary, shield [L-PRE]

- **FR-R-30.** Per-mode ladder shapes (offsets from scheduled time, before
  boundary pruning):

  | Mode | Slots | Notes |
  |---|---|---|
  | 🟢 Flexible | T+0, T+15 | 1 gentle follow-up, then window closes |
  | 🟡 Disciplined | T+0, T+10, T+25 | window default 45 min |
  | 🔴 Extreme | T+0, T+5, T+15, T+30 | window default 60 min; [L-PUSH] may extend the tail hourly ×3 while unresolved |

  Exact numbers live in `AdaptiveReminderPolicy` as the single source; a
  goal's intensity (1–5) maps to mode as today.
- **FR-R-31.** Boundary pruning: slots ≥ `nextBoundary` are not scheduled.
  If pruning leaves only slot T+0, that's correct — the recovery system owns
  the rest. Criticality 3 ignores pruning and every shield **including the
  configured sleep window** (D5: meds beat sleep) but still stops hard at
  `windowEnd`.
- **FR-R-32.** Shield pruning: slots falling inside a *known* shield window
  (scheduled focus block, configured sleep window) are pruned at compile
  time; a shield that starts dynamically (user starts a timer) cancels
  other entities' pending slots for its duration and recompiles on end
  [L-ALIVE].
- **FR-R-33.** Budget policy under the iOS 64-pending cap (existing
  `NotificationBudget`): full ladders only for **today's** tasks; tomorrow+
  gets slot T+0 only until it becomes today; goals get ≤ 2 occurrence slots;
  intentions keep their 3-slot ladder. Deterministic priority order when
  over budget: criticality desc → soonest first → drop deepest ladder slots
  first. Every drop is ledger-logged (no silent truncation).
- **FR-R-34.** Every slot carries its pre-written title/body string (from
  the copy system, FR-R-63) and full payload; delivery-time code paths do
  zero composition.
- **FR-R-35.** Interaction contract per slot: Done → complete flow (modes
  keep the strict/extreme fall-through to focus); Later → single unified
  snooze (FR-R-07) re-plans remaining ladder; Wrong time → closes the window
  now, task goes straight to Overdue (flexible) or Expired (timeSensitive),
  signal recorded for the strategist; plain tap → opens task context.
  Any interaction cancels remaining slots.

### FR-R-4x — Modes as resolution contracts [L-ALIVE]

What Overdue *demands* is the modes' real difference:

- **FR-R-40. Flexible:** Overdue appears on the Recovery Card and task list
  badge; dismissible; auto-rolls into Plan-Tomorrow as a suggestion; no
  reason required for anything.
- **FR-R-41. Disciplined:** Overdue asks to be explicitly dispositioned
  (Do now / Reschedule / Skip); the Recovery Card entry is persistent
  (re-appears each recovery moment) but not blocking. Plan-Tomorrow **nags
  but allows** (D3): un-dispositioned Disciplined tasks get one inline
  prompt in the flow; if still unanswered they carry into tomorrow's plan
  as Overdue-flagged suggestions — never silently dropped, never a hard
  gate.
- **FR-R-42. Extreme:** Overdue demands resolution at every recovery
  moment. The Recovery Card entry is non-dismissible; reschedule requires a
  non-empty reason (logged to the accountability log); no AI output may
  soften this contract (guardrail, FR-R-65). Options depend on staking (D4):
  - **Staked:** Do now / Reschedule with reason / **Surrender** (existing
    stake flow).
  - **Unstaked:** Do now / Reschedule with reason only — no one-tap
    give-up. The honest escape valves are deliberate-friction ones the
    user already has: edit the task's mode, or delete the task (both
    logged). After **3 consecutive reschedules** of the same task, the
    coach/strategist surfaces one suggestion ("this keeps slipping —
    lower it to Disciplined, or drop it?") so the contract can't become a
    reschedule-forever treadmill, but the *user* makes that call.
- **FR-R-43.** Mode resolution stays per-task (`modeRefId` via
  `EffectiveTaskMode` precedence: task → routine → default), unknown ids
  degrade to Flexible **with a ledger note** (M3: no more silent degrade).
- **FR-R-44.** Interruption levels finally reach the OS (M1): Android
  channels per level (low/default/high importance), iOS
  `interruptionLevel` (passive / active / timeSensitive where entitled).
  Extreme escalation is *audibly* different; `silent` decisions deliver as
  passive/minimal presentation, not loud.

### FR-R-5x — Recovery & overdue surfacing [L-ALIVE]

- **FR-R-50.** The Recovery Card (Home, top position when non-empty) lists
  unresolved Overdue items with per-mode affordances (FR-R-40..42), ordered
  criticality desc → overdue-since asc. One primary action per row
  (Do now); secondary in overflow. Design system: `SectionHeader`, tokens
  only, no new visual language.
- **FR-R-51.** Timer/focus completion shows the same content as a
  post-session prompt when non-empty ("You still have 1 unfinished task").
- **FR-R-52.** Routine-class misses render as a single digest line ("Water:
  3 of 6 today"), never as rows per miss and never as push notifications.
- **FR-R-53.** Aggregated recovery notification: at each [L-ALIVE]
  recompile, if unresolved Overdue items exist and a qualifying free gap is
  found (§3.6), schedule ONE summary notification into it (≤ 2/day,
  ledger-capped). Tap opens Home at the Recovery Card.
- **FR-R-54.** Day rollover: unresolved items flow into Plan-Tomorrow with
  their overdue history attached; Extreme items keep demanding resolution
  there (FR-R-42).

### FR-R-6x — AI layer (advisory only)

- **FR-R-60.** All AI calls go through the existing Cloud Functions proxy
  (owned prompts, token budgets, turn registry, App Check). The client-side
  key path is never used. AI reminder features are tier-gated (heuristics
  free; AI classification, strategist, personalized copy = Pro).
- **FR-R-61 (strategist).** The daily Thinking Loop's input bundle gains
  **locally pre-computed aggregates**: per-task delivered/opened/ignored/
  snoozed/wrong-time counts, engagement-by-hour histogram, overdue history,
  mode. Raw ledger rows are never sent. Its output is a strict-schema list
  of proposals: `rescheduleSuggestion`, `ladderTuning` (clamped to mode
  bounds), `aggregateSuggestion`, `dropSuggestion` — surfaced in the
  morning brief / coach with one-tap apply. **No auto-apply in V2** (D7):
  every strategist output is a suggestion the user accepts explicitly,
  applied with `source: ai_strategist` provenance and undo. Revisit
  auto-apply for timing micro-adjustments only after acceptance-rate data
  earns it — via a new decision-log entry, not a flag flip.
- **FR-R-62 (triage).** At a recovery moment with ≥ 3 unresolved items and
  connectivity, one bounded call may rank them ("do Study; move the rest")
  rendered as a suggestion header on the Recovery Card. Offline or over
  budget → deterministic order (FR-R-50) stands; the card never waits on
  the call (render immediately, enhance if the response arrives).
- **FR-R-63 (copy).** A complete template bank covers every
  notification/card string per mode, escalation step, and taxonomy —
  including the escalation copy that exists today but is unreachable
  (AUDIT §10 M2). AI may pre-generate warmer per-task variants at
  classification time and during the daily pass; variants are stored on the
  config row and used verbatim by [L-PRE]. Template bank is the permanent
  offline fallback.
- **FR-R-64 (cost).** Budget targets: classification ≤ 1 call/task-create
  (batched in flows), strategist rides the existing daily budgeted pass,
  triage ≤ 2 calls/day, copy piggybacks classification/daily passes.
  Server-side per-user token budgets enforce the ceiling; on exhaustion
  everything degrades to heuristics/templates silently.
- **FR-R-65 (guardrails, enforced in code not prompts).** AI can never:
  disable/delete a user-configured reminder; exceed mode ladder bounds;
  soften Extreme's resolution contract; write anything without provenance
  (`classificationSource`/`source` fields) and reversibility. Invalid AI
  output → discarded, heuristic stands, no user-visible error.

### FR-R-7x — Offline & failure stories

- **FR-R-70.** Definition of done for every feature in this PRD includes:
  demonstrated in airplane mode — create task (heuristic classifies, ladder
  compiles), receive ladder, hit boundary, go Overdue, see Recovery Card,
  resolve — all with zero network.
- **FR-R-71.** Named failure stories: AI endpoint down → heuristic/template
  stands silently; token budget exhausted → same; timezone unresolved →
  health notice + retry (FR-R-06); OS notification permission revoked →
  persistent Settings health row + Home hint (FR-R-80); budget cap hit →
  deterministic drop order + ledger log (FR-R-33); [L-PUSH] unavailable
  (functions not deployed, no APNs) → [L-PRE]/[L-ALIVE] are the guaranteed
  floor and the UX makes no promises that depend on push.
- **FR-R-72.** The save path never awaits a remote read before arming
  (fixes C8): schedule from local state first; `hydrateFromRemoteForTasks`
  moves to the background merge path.

### FR-R-8x — Observability & health

- **FR-R-80.** A "Reminder health" row in Settings → Notifications:
  permission state, pending-queue usage vs budget, timezone state, last
  reconciliation result, [L-PUSH] registration state. Any red condition also
  surfaces one quiet Home hint (thin, dismissible — sync-line pattern).
- **FR-R-81.** The ledger records the full slot lifecycle (scheduled →
  fired-detected → interacted/ignored → cancelled/expired) with a
  fired-detection pass at [L-ALIVE] (tray + pending diff) so "delivered"
  finally means delivered (fixes L1).
- **FR-R-82.** A debug screen (tester-mode gated) lists every armed OS
  notification with its ladder slot, entity, and scheduled time — the tool
  every "why didn't it fire" report needs.

---

## 7. Non-goals (out of scope for V2)

1. No LLM call per notification, ever.
2. No server-side scheduling as a *requirement* — [L-PUSH] is additive.
3. No custom user-defined modes (schema stays ready via `RoutineModeConfig`;
   UI not built).
4. No cross-device reminder handoff semantics beyond existing LWW sync.
5. No calendar (EventKit/Google) integration in this phase.
6. No changes to intention-nudge planning (it already follows this
   architecture); it only adopts the shared budget policy (FR-R-33).
7. No OS-level DND/Focus integration beyond honoring our own shield.

---

## 8. Design considerations

- Recovery Card and health row use existing tokens/components (`AppColors`,
  `SectionHeader`, micro-labels); overdue accents use the existing danger/
  amber tokens — no new reds.
- Chrome recedes: the Recovery Card leads with the task, not with alarm
  iconography; Extreme's non-dismissible state is conveyed by persistent
  presence and copy, not by aggressive color.
- Classification chip in the task editor is one row, defaulted, never a
  required decision (the heuristic/AI answers; the user can correct).
- Notification copy follows the coach voice (warm, specific, short); the
  escalation tone per mode comes from the template bank, reviewed as
  content, not improvised in code.

## 9. Technical considerations

- **Platform truths this design is built around:** iOS local notifications
  are fire-and-forget with a 64-pending cap and no delivery callback.
  **Android is parked in this wave (D8, iOS-first):** ladders on Android
  are explicitly gated to `inexactAllowWhileIdle` scheduling (no
  exact-alarm permission flow, no boot-receiver work now), the reminder
  health row states reminders may arrive a few minutes late on Android,
  and the AUDIT §4 exact-alarm/boot work becomes its own later phase —
  gating, not silence, so Android behavior is degraded-but-honest.
- Reuse, don't rebuild: `AttentionOrchestrator` (decision pipeline),
  notification ledger, `NotificationBudget`, context overrides,
  `EffectiveTaskMode`, `AdaptiveReminderPolicy` (becomes the single cadence
  source), intention sweep-cron (becomes [L-PUSH] pattern).
- The ladder compiler is a pure function
  `compileSlots(config, plan, shields, now) → List<SlotSpec>` — the unit
  test surface for boundary/shield/budget/expiry logic. Property test:
  no compiled slot violates boundary, shield (unless crit 3), budget, or
  window rules.
- Integration test that walks the real service layer with fake clock + fake
  OS queues: scheduled → fired → ignored → overdue → recovery, per mode —
  the test the current suite lacks (AUDIT §10 C2 note).
- Migration: existing `ReminderConfig` rows get
  `{class: flexible, criticality: 1, classificationSource: migration}`;
  first [L-ALIVE] pass recompiles ladders; the old
  reconciliation/re-evaluate path is deleted, not gated.

## 10. Success metrics

1. **Delivery correctness:** 0 spurious at-app-open deliveries (ledger:
   deliveries with `firedAt` ≪ `scheduledFor`); today this is ~every cold
   start with a future reminder.
2. **Persistence:** % of missed Due tasks that reach a Resolved state within
   24 h (target: > 80%, from ~0 today since misses vanish).
3. **Mode differentiation:** ignored-rate and resolution-rate differ
   measurably by mode; Extreme overdue tasks reach explicit resolution
   > 95%.
4. **Respect:** ≤ 6 task notifications per day per user at p90; "Wrong
   time" rate declining week-over-week (strategist feedback loop).
5. **Cost:** AI spend per active user ≤ $0.15/month at p90.
6. **Health:** reminder-health row green for > 95% of sessions.

## 11. Phased implementation plan

- **Phase R1 — Stop the bleeding** (FR-R-01…08). Small surgical fixes on
  the current system. Suite green, airplane-mode QA pass. *Ship alone.*
- **Phase R2 — State spine + heuristics** (FR-R-10…14, 20…21, 50…54,
  80…82). The app *knows* and *shows* what's overdue; classification is
  heuristic; no ladder changes yet. This alone kills "SidePal forgot."
- **Phase R3 — Ladder engine** (FR-R-30…35, 40…44, 70…72). Pre-compiled
  per-mode ladders, boundary, shield, modes-as-contracts, OS interruption
  mapping. The audit's C1/C2 die here.
- **Phase R4 — AI layer** (FR-R-22, 60…65). Classifier endpoint, strategist
  in the Thinking Loop, copy variants, triage. Tier-gated.
- **Phase R5 — Push floor** (extend sweep-cron; Extreme tail + crit-3
  rescue). Requires the pending functions deploy.

Each phase ends with: decision-log entry, `flutter analyze` clean, full
suite green, airplane-mode QA per FR-R-70.

## 12. Resolved decisions (answered by Miko, 2026-08-30)

All eight open questions are settled; the FRs above already reflect them.

- **D1 · Boundary buffer = 20 min** (§3.4, FR-R-31). Same for all modes.
- **D2 · Reminder windows: Flexible 30 / Disciplined 45 / Extreme 60 min**
  (§3.3, FR-R-30), always capped by the boundary.
- **D3 · Disciplined day-close: soft nag, never a hard gate** (FR-R-41).
  One inline Plan-Tomorrow prompt; unanswered tasks carry forward as
  Overdue-flagged suggestions.
- **D4 · Unstaked Extreme has no Surrender** (FR-R-42). Do now /
  Reschedule-with-reason only; escape valves are deliberate-friction
  (edit mode / delete task, both logged). After 3 consecutive reschedules
  the coach suggests demote-or-drop — suggestion only, user decides.
- **D5 · Criticality 3 pierces the sleep window** (FR-R-31). Meds beat
  sleep; hard stop at `windowEnd` still applies.
- **D6 · Aggregated recovery notifications: max 2/day** (FR-R-53).
- **D7 · No strategist auto-apply in V2** (FR-R-61). Suggestions only;
  auto-apply may return later via a new decision-log entry backed by
  acceptance-rate data.
- **D8 · Android parked this wave** (§9). Ladders gated to inexact
  scheduling on Android with an honest health-row note; the exact-alarm /
  boot-receiver work (AUDIT §4) becomes its own later phase.

The PRD is final and ready for task generation (`generate-tasks.md` flow)
on a dedicated branch.
