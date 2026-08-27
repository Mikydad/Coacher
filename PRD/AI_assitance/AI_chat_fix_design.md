# AI Chat Fix Design — proposal

**Date:** 2026-08-27 · **Status: PROPOSAL — awaiting Miko's answers to the
open questions in §Q before any implementation.**

**Inputs:** `AUDIT.md` §8 (Claude deep audit, 2026-08-27, adversarially
verified) and `PRD/AI_assitance/Ai_converstaion_gpt5.6.md` (GPT-5.6
independent review, same date). The two audits agree on every trust-critical
finding. GPT-5.6's six genuinely new claims were each re-verified against the
code before being designed against here — **all six are real**:

| New claim | Verified |
|---|---|
| G3 — undo snapshots *every task on the affected dates* (no id filter, despite the doc comment claiming one), and `_resolveDate(null)`→today means even memory/intention actions snapshot today's whole plan; rollback re-upserts it all with bumped `updatedAtMs` (LWW wins cross-device) | ✓ `ai_action_executor.dart:312-360, 366-403` |
| G4 — rollback swallows every failure and `_undoBatch` returns `UndoSuccess` unconditionally | ✓ `:366-413, 293-303` |
| G8 — `confirmPlan` calls `markConfirmed`/`markExecuted` regardless of `result.hasFailures`/`wasRolledBack`; a rolled-back plan is recorded "Already applied (do not repeat)" | ✓ `ai_assistant_service.dart:754-767` |
| G13 — streamed voice turns never consult the client `ai_enabled` kill switch (only the agent path does) | ✓ `ai_assistant_service.dart:454-469` |
| G29 — Home "Refresh coaching" only `ref.invalidate`s recompute providers nothing reads — a no-op | ✓ `coaching_focus_card.dart:32-35` |
| Coach-route temperature is client-supplied (clamped), not server-pinned — routes define none | ✓ `ai_routing.ts:38-47`, `index.ts:438` |

**Accepted corrections to §8:** C1 (M10 downgrades — the prompt *is*
style-aware; only TTL/summary-type derivation and the no-summary badge use
style-blind framing), C2 (four endpoints), C3 (extraction maintenance *is*
wired; the other three routines aren't), C4 (warmup still warms the instance
and token cache), C5 (matches our own verifier's downgrade), C6 (Start button
opens an empty sheet), C7 (three live entry points).

**Goal (Miko's words):** a ChatGPT-level assistant **that does what it's
supposed to do**.

---

## Design principles for this fix wave

Every phase below is derivable from these five rules; when in doubt during
implementation, apply the rule, not the letter of the spec:

1. **Never claim unperformed work.** No success copy without a verified
   write; no advertised verb without a real handler; no "restored" without a
   verified restore. A typed result object replaces every fire-and-forget.
2. **Execute by id, never by title.** Titles are for the model and the card;
   by the time anything mutates, the target is a concrete Isar id resolved
   *before* the user confirmed.
3. **Per-item honesty (the Telegram model, for real).** Independent actions
   succeed/fail independently; failures render distinctly and carry a retry;
   the retry is quota-free (the server's same-`turnId` window already
   supports it).
4. **Every await is generation-guarded.** Any state mutation or history save
   after an await re-checks the session/turn generation it started with.
5. **UI reads watch streams** (the house rule) — no cached FutureProviders
   for state that changes mid-session.

---

## Phase 0 — Stop the lying (one short batch, ship first)

Goal: after this batch, nothing in the product claims an ability or a result
it doesn't have. No new architecture.

- **De-advertise the five stub verbs + two throwing read-only kinds.** Remove
  `moveTask`/`deleteTask`/`modifyGoal`/`deleteGoal`/`removeReminder`/
  `suggestFreeTimeBlock`/`moveConflictingTasks` from `kCoachAgentTools`, from
  `AiCapabilityRegistry.supportedMutate`, and from the quick-directive map;
  make the five stubs `throw UnsupportedError` (the standard the executor
  already applies to `suggestFreeTimeBlock` "so confirm does not look
  successful"). Add an honest system-prompt line + `detectUnsupported`
  fast-path copy: "I can't move or delete things yet — here's where to do it"
  (final copy per Q1). Phase 1 re-adds each verb as it becomes real.
- **Fake undo dialog → dry-run.** `_undoBatch` first calls
  `_findCompletedSnapshotTasks` and returns a `UndoNeedsConfirmation`
  result *without* rolling back; the screen shows the existing dialog; only
  "Undo anyway" performs the rollback. Cancel now cancels. Providers
  invalidate in all branches (until Phase 2 replaces them with streams).
- **Kill-switch honesty.** (a) Release builds: `MockAiOperatingLayerClient`'s
  mutate/suggest branches return an honest "Coach is temporarily unavailable
  — your schedule and tasks all work as normal" informational reply (mock
  plans stay behind `kDebugMode`/tests). (b) `ai_enabled == false` in the
  summary provider throws `AiClientException` so the
  `DeterministicCoachingRenderer` path takes over; `MockCoachingAiClient`
  becomes test-only. (c) The Progress "Test AI coaching summary" button gates
  behind tester mode. (d) `tryStreamVoiceReply` checks the same client
  kill switch before streaming (G13) — returns null so the turn takes the
  agent path, which degrades honestly.
- **Behind-pace card tells the truth.** `_estimateGoalProgress` reads real
  progress the way `goals_providers.dart` already computes it (sum of
  check-in values / targetValue over the elapsed window). If progress data is
  unavailable for a goal, the card emits the neutral copy ("No sessions
  logged toward X recently", lower confidence) — never a fabricated
  percentage.
- **Home "Refresh coaching" actually refreshes** (G29): after invalidating,
  read the recompute futures (the Progress test path shows the exact
  pattern).

Failure story: unsupported verb → honest copy + pointer to the manual
surface. Tests: every remaining advertised action type produces the expected
Isar mutation (GPT test-gap #1); Cancel on the undo warning performs no
rollback (#6); an on-track goal never emits behind-pace (#15).

---

## Phase 1 — Real verbs: entity resolution at preview time (the keystone)

Goal: every verb the model may propose executes for real, against the right
entity, and the card shows exactly what was matched before Confirm.

**New component: `AiEntityResolver`** (application layer, pure + repo reads):

- Runs in `AiIntentParser` after normalisation, before the preview card.
- For every action that targets an existing entity (`editTask`, `moveTask`,
  `deleteTask`, `modifyGoal`, `deleteGoal`, `addReminder`-to-existing,
  `rescheduleReminder`, `removeReminder`, `completeTask` if added later):
  resolve `taskTitle`/`goalTitle` + resolved date → concrete id using
  normalized-exact match first, then `EntityNormaliser.similarityScore`
  fuzzy match (threshold per Q2).
- **Zero matches** → the plan degrades to a local follow-up question ("I
  couldn't find a task called 'dentist' on Thursday — which one did you
  mean?" listing that day's tasks). No model round-trip (Q2).
- **Multiple matches** → local disambiguation question listing candidates
  with times. No model round-trip.
- **One match** → `_resolvedTaskId`/`_resolvedGoalId` stored in the action
  params (persisted through actionsJson, fixing the coordinator's placeholder
  entity ids for free), and the preview card renders the *matched* entity:
  "Move **Gym** — today 9:00 → tomorrow", "Edit **Gym** — time → 19:00,
  duration → 45 min" (closes §8 E11's blind-edit card at the same time).

**Handlers, all by resolved id, all Isar-then-outbox:**

- `_moveTask`: load row → upsert with new `planDateKey` (and time if given) →
  `reminderSyncService.syncForTaskIds` → move/remove the derived time block.
- `_deleteTask`: reuse the 2026-08-23 deletion set — task delete +
  `ReminderSyncService.removeForDeletedTask` (cancel + config delete) +
  time-block removal + coaching-cache clear. One shared path with
  `confirmDeletePlannedTask` so AI and manual deletes cannot drift.
- `_editTask`: upsert the **same id** with only the changed fields; status,
  notes, category, orderIndex, `modeRefId` preserved. No tier-guard on true
  edits; the create-fallback path is gone.
- `_modifyGoal` / `_deleteGoal`: fetch by id, apply the field change /
  delete via the shared `confirmDeleteGoal` semantics (reminders + linked
  state handled once).
- `_removeReminder`: disable + delete the config, cancel the notification.
- `_createGoal` honors model params: `measurementKind`, `targetValue`,
  cadence when parseable — "run 20km a week" stops becoming a count-of-1
  productivity goal.
- **Date canonicalisation** in `AiActionParamNormaliser`: weekday names →
  next matching date key; validate `YYYY-MM-DD`; unparseable dates make the
  action fail loudly at parse time (follow-up question), never write to a
  phantom `planDateKey` or default a reminder to today.
- Deduplicator becomes date-aware (dedupe against the action's resolved
  date, not just today).

Tests: GPT gap #1, #2 (edit preserves id + untouched fields); move/delete
verified end-to-end in airplane mode; ambiguous/missing target produces the
local question.

---

## Phase 2 — Undo v2: the inverse-operation log

Goal: undo undoes exactly what the batch did — nothing more (G3), nothing
less (E3/G5) — and never lies about the result (G4).

**Replace the date-wide task snapshot** with a per-action inverse log,
appended at dispatch time by each handler (it knows exactly what it did):

```
{ op: 'deleteTask',   taskId }                    // inverse of a create
{ op: 'restoreTask',  row: {...} }                // inverse of edit/move/delete
{ op: 'deleteGoal',   goalId } | { op: 'restoreGoal', row }
{ op: 'restoreReminderConfig', config } | { op: 'deleteReminderConfig', id }
{ op: 'removeTimeBlock', blockId } | { op: 'restoreTimeBlock', block }
{ op: 'tombstoneIntention', id }                  // existing behavior, absorbed
{ op: 'deleteFact', id } | { op: 'restoreFact', row } // existing, absorbed
```

- Stored on the batch record (replaces `snapshotJson`; keep the field name or
  migrate — the collection is device-local, so a lazy migration is fine).
- **Rollback = apply inverses in reverse order**, each op individually
  guarded; the result is a **typed `RollbackResult`** (restored / failed op
  lists). `UndoSuccess` is returned only when every inverse applied;
  otherwise `UndoPartial(failedOps)` renders honestly. Nothing is swallowed.
- Reminder/notification hygiene is inherent: the inverse of "create task with
  reminder" includes deleting the config and cancelling the notification
  (E7); restored pre-existing tasks re-derive configs via
  `syncForTaskIds`.
- **Per-item outcomes replace all-or-nothing rollback** (E6/G16, pending Q4):
  independent failed actions no longer trigger rollback of their siblings;
  the confirm summary lists per-action results (the batch record already
  stores `succeededActionIds`/`failedActionIds`; the card gets a per-row
  ✓/✗ + retry for failed rows).
- **History marking becomes truthful (G8 + M1):** `markExecuted(sessionId,
  entryId)` targets only the entry whose plan executed, and only for the
  actions that succeeded; a fully-failed or rolled-back batch marks nothing.
  `_buildCompletedInSession` reads per-entry flags.
- **Undo providers → Isar watch StreamProviders** (`fireImmediately: true`);
  every manual `ref.invalidate` deleted; the chip appears the instant a batch
  completes and re-checks the 30-min window on each emit (fixes both stale
  directions of E5). The UI's undoable-state filter matches the executor's
  (`completed` + `partialFailure`).
- **Boot sweep:** batches stuck in `pending`/`executing` older than ~5 min
  roll back from their inverse log on executor construction (E8); the dead
  fresh-batchId idempotency check is removed, and `pruneOld()` finally gets
  its caller in the bootstrap maintenance block (with `pruneOldSummaries`;
  `purgeBefore` is deleted as dead — C3).

Tests: GPT gaps #3, #4 (undoing a memory/intention action must not change
any schedule task — the G3 regression test), #5, #7, #8.

---

## Phase 3 — Honest failure & the race guards

- **`AiChatMessage` gains `status` (`normal | sending | failed`) and
  `originatingInput`.** Failed turns render with an error treatment
  (AppColors.danger family) and a **Retry** chip; retry re-invokes
  `_parseAndRespond` with the stored input, **reusing the failed turn's
  `turnId` with `loopIndex > 0`** so it is quota-free inside the server's
  3-minute window; tapping the bubble restores the text to the composer.
  Same treatment on the auto-commit failure path.
- **`confirmPlan`**: re-entrancy guard (`if (_isLoading) return`) +
  `try/catch/finally { _setLoading(false) }` + honest failure bubble; the
  card stays confirmable. `sendMessage` gets an in-flight guard (second send
  queues — Q6).
- **Session generation guard (R1/G10):** `startNewSession` bumps a
  generation; `_parseAndRespond` and `_runStreamedVoiceTurn`'s settle capture
  it at entry and abandon all state mutation + history save on mismatch.
- **Stream completion contract (H5/G18):** server tracks `finish_reason` and
  SSE error events → emits `{"done":true,"finish":"stop"}` /
  `{"done":true,"finish":"length"}` / `{"e":"upstream"}`; the client treats
  missing-done as a stream error after partial text and marks the bubble
  truncated (voice speaks what it has, the bubble shows a quiet "cut short —
  tap to retry").
- **Error taxonomy:** `deadline-exceeded` gets its own copy ("That took too
  long — I've stopped waiting. Ask again."); errors return through a
  dedicated `responseType.error`, never `followUpQuestion` (H10), so error
  copy stops polluting the next prompt, the clarify metric, and the voice
  fast path.
- **Server-side quota honesty (H4):** compensating `increment(-1)` + clear
  `lastTurnId` on upstream fetch failure / non-200 / empty content, both
  endpoints. Oversized-input honesty (R5): client caps input at send time
  (~4k chars, honest copy), truncates `userInput` at persist, maps
  `invalid-argument` to "that message is too long".

Tests: GPT gaps #8, #9, #12, #14; retry-is-free integration test against the
turn window logic.

---

## Phase 4 — Voice reliability

- **One process-wide STT adapter** (V1/G11): a singleton
  `SharedSpeechAdapter` owns the `speech_to_text` instance and assigns the
  plugin's *public* `statusListener`/`errorListener` fields **before every
  listen**, multiplexing callbacks to the currently-registered owner (voice
  controller or dictation client). Fixes: connecting-phase stuck from session
  2, false "microphone stalled", dictation indicator, error copy — and adds
  the cross-file invariant test asserting `pauseFor > continuationGap`.
- **Lifecycle observer:** `WidgetsBindingObserver` (+ audio_session
  interruption/becoming-noisy) → `pauseToIdle()` (stop STT+TTS, honest idle
  copy, `voiceModeActive` released); optional auto-relisten on resume (Q7).
- **Interrupt ≠ failure (V2/G20):** both resilience catch blocks check the
  generation before stamping `_lastPrimaryFailureAt`; the degraded buffered
  branch uses a cancellable subscription so stop() actually stops it.
- **Transport:** one session-lifetime keep-alive `http.Client` for
  `aiChatStream`, shared with `warmVoiceEndpoints` (the TTS adapter's own
  documented lesson, applied to chat).
- Small fixes riding along: day-reference gate uses the router's focusDate
  (V7); tail clips chunk ≤2000 chars (V5); `_listenStartedAt` stamped after
  `listen()` resolves (V6); speaker route re-asserted before the first clip
  of each speak (V8); voice confirm speaks conflicts/hard blocks and hard
  blocks require an explicit second affirmation (E12, Q3).

Tests: GPT gaps #10, #11; controller suite gains a two-session
real-singleton test via a fake that reproduces the plugin's freeze behavior.

---

## Phase 5 — Server hardening (needs a functions deploy)

- **Server-owned system prompts** (S1/G12): the static system prompt (+ voice
  addenda) moves server-side, keyed by purpose and versioned (compile-time
  default + RC override slot, same pattern as `ai_purpose_routes`); client
  `system` messages are rejected for chat purposes. Context stays in the user
  message. This also creates the stable prompt prefix that turns on OpenAI
  automatic prompt caching (~half input cost on multi-turn sessions). The
  prompt-iteration workflow question is Q5.
- **Token-aware budget:** per-uid daily token budget alongside the 40/hr turn
  window, fed by `usage.total_tokens` (already received) and
  `stream_options: {include_usage: true}` on the stream; telemetry writes
  move before `res.end()`.
- **App Check:** `enforceAppCheck: true` on callables **and** manual
  `getAppCheck().verifyToken(X-Firebase-AppCheck)` on `aiChatStream` +
  `aiSpeechStream` (they are onRequest — the flag alone leaves them open).
- **Turn registry:** a small map of recent turnIds (last ~3 with timestamps)
  replaces the single `lastTurnId` slot; `aiChatStream` participates with its
  own turnId instead of clobbering with `undefined`; the over-quota marker
  gates only `loopIndex == 0`.
- **Hygiene:** purpose allow-list (unknown → `other` bucket);
  machine-readable `details` on quota errors (`{reason, retryAfterMs}`);
  temperature pinned on the coach routes (0.4–0.7, pick per Q9);
  `coaching_summary` moves to the system quota class (it already
  silent-skips to a deterministic fallback — exactly system-class
  semantics).
- **Tier instruction cap** (E16): implement the decision-logged 5/day
  actionable-instruction cap server-side next to the rate-limit transaction,
  or explicitly defer and correct `tier_limits.dart`'s claim — Q8.

Tests: GPT gap #13 (functions integration tests: quota refund, turn
interleaving, purpose allow-list, App Check).

---

## Phase 6 — Memory & context quality

- **Truthful acks:** `rememberFact` echoes the stored content in the bubble
  ("Noted: *'Prefers evening workouts'* — Undo") and runs the extraction
  pipeline's quote-check, demoting to `aiInferred` on mismatch (M2).
  `forgetFact`/`updateFact` prefer `[mem:<id>]` refs, refuse ambiguous
  containment matches with a local question, and always name the affected
  fact (M/E14).
- **Extraction robustness:** malformed/truncated JSON = failure (stays
  pending, retries; never `markExtracted`); server passes `finish_reason`;
  fence-stripping decode added (M3). The 7-day truncation fallback summarizes
  from `assistantSummary` lines instead of raw openers and carries its own
  TTL (M5). Observation titles capped at 80 chars like reflections.
- **Mention ≠ interaction (M4):** extraction stamps `lastMentionedAtMs`;
  `lastInteractionAtMs` moves only on completed intentions; the payload line
  says "mentioned today, last real interaction N days ago".
- **Scored memory selection (M6):** floor for
  `userConfirmed`/`userStated` preferences + semantic facts, then blend
  recency, `lastReferencedAtMs` (finally consumed), and person-mention match
  against the current input.
- **Route-conditioned payload (M7/P3):** greetings answered client-side (the
  capability-question fast path is the template); conversational/query turns
  skip weekOverview/behaviour-stats/patterns; memory/people trimmed for pure
  schedule queries. Session cache evicted on `startNewSession`; calendar
  day arithmetic (DST); the dead capabilities section deleted (M9).
- **Coaching-summary style (C1-corrected M10):** pass `coachingStyle` into
  the early `deriveCoachingFraming` so TTL/summary-type/badge agree with the
  style-aware prompt.
- **Circle pulse (S5/G26/G27):** event titles quoted + capped + newline-
  stripped with a data-not-instructions preamble; parsed `memberLines`
  validated against real membership (unknown uids dropped); outcome enum
  replaces null-collapse ("Nothing new yet" vs cooldown vs offline-retry vs
  save-failed); pulses cached in the already-registered `IsarAiPulseCache`
  for offline reads; superseded pulse docs deleted on save; the architecture
  guard regex extended to catch awaited writes through injected Firestore
  fields.

Tests: GPT gaps #16, #17; memory-selection unit tests (foundational fact
survives 5 chatty sessions).

---

## Phase 7 — Chat surface warmth (the ChatGPT feel)

- **Stream typed turns:** route typed query-classified turns through the
  existing `aiChatStream` seam + live bubble (the voice Level-2
  infrastructure, reused) — the single biggest perceived-latency win.
- **Cancellation + queueing:** Stop on the loading bubble (turn-generation
  discard); typed input queues instead of a dead SEND (U1).
- **Conversation continuity:** sheet dismissal keeps the last thread in
  memory; reopening within ~10 min offers "Restore conversation" (session
  boundary + memory extraction unaffected — restore re-opens the same
  sessionId); on app launch the last same-day session rehydrates as history
  rows (marked, capped) instead of a blank thread (U6/U10, Q7). The
  pending-plan banner filters to entries with real actions (H8).
- **Rebuild scope:** narrow providers (`messages`, `isLoading`,
  `pendingPlan`) via select/ListenableBuilder; the FAB watches a cheap
  derived provider; scroll-to-bottom fires only on message-count growth when
  near-bottom (U3); one thinking indicator (U4); suggestions panel + help +
  first-time card re-homed into the sheet (U2) **after** the guest auto-send
  post-frame fix (R7); snackbars → in-sheet messenger or inline banners (U5);
  RC read made synchronous-with-background-fetch so the composer renders
  instantly (R4); init error gets retry + friendly copy.
- **Detail pass:** `AppColors.danger` replaces raw reds; `SectionHeader` in
  the history sheet; timestamps on long-press + under executed bubbles;
  SelectionArea; ~260ms insertion animation; orb/chips/SEND semantics +
  liveRegion announcements; per-item accept/reject checkboxes on the plan
  card (Q4); personalized empty-state chips from real goals.

Tests: GPT gaps #14, #18; goldens for the failed-bubble and per-item card
states.

---

## Suggested batch order (maps to the established workflow)

| Batch | Contents | Size |
|---|---|---|
| 1 | Phase 0 (stop the lying) | S — ship first, immediately |
| 2 | Phase 1 (resolver + real verbs) | L — the core feature work |
| 3 | Phase 2 (undo v2) | M-L |
| 4 | Phase 3 (honest failure + races) | M |
| 5 | Phase 4 (voice) | M |
| 6 | Phase 5 (server) — **one functions deploy**, batched with the still-pending surrender/invite deploy | M |
| 7 | Phases 6–7 sliced as needed | M each |

Each batch: restate → Miko approves → implement → `flutter analyze` → full
test suite → per-item commits → decision-log entry. Definition of done per
CLAUDE.md (airplane-mode end-to-end, failure story named).

---

## §Q — Open questions (answers wanted before batch 1)

**Q1 — Interim copy for de-advertised verbs (Phase 0).** When someone asks
"move my workout" before Phase 1 lands: (a) honest "I can't move things yet —
open the task to move it" with a deep link, or (b) still show a plan card
that opens the manual edit surface pre-filled? *Recommend (a) — simplest
honest thing, and Phase 1 follows quickly.*

**Q2 — Entity resolution semantics (Phase 1).** (i) Fuzzy threshold: should
"gym" match "Gym session" (single candidate, high similarity) without
asking? *Recommend yes at ≥0.8 similarity when unique on that date;
otherwise ask.* (ii) Disambiguation and no-match questions are LOCAL (no
model call, no quota) — agree? (iii) When the user names no date for a
delete/move, search today+tomorrow+this week, or ask?

**Q3 — Hard-block confirm by voice (Phase 4/E12).** A plan inside sleep/DND:
speak the warning and require a second explicit "yes, do it anyway"? Or
refuse by voice entirely and require the visual card? *Recommend spoken
warning + second affirmation.*

**Q4 — Per-item outcomes (Phase 2).** Confirmed 5-action plan where one
fails: keep the 4 successes + offer retry on the failed one (*recommended —
the Telegram model*), or keep today's all-or-nothing rollback? And on the
card: per-item accept/reject checkboxes before confirm — wanted, or is
Confirm/Edit/Cancel enough?

**Q5 — Server-owned system prompt (Phase 5).** Moving the prompt server-side
means prompt iteration requires a functions deploy (or an RC edit) instead of
a client hot-reload. Options: (a) full move (best security + prompt-cache
win), (b) server holds a hash allow-list of known client prompts (keeps
iteration speed, weaker), (c) defer. *Recommend (a), with the RC override
slot so tweaks are a console edit, not a deploy.*

**Q6 — Send during in-flight turn (Phase 3).** Queue the second message and
send when the turn settles (*recommended, Telegram-style*), or block with a
hint?

**Q7 — Conversation continuity (Phase 7).** (i) "Restore conversation"
window after an accidental close: 10 min? (ii) Rehydrate the last same-day
session on app launch — yes/no? (iii) Voice: auto-relisten when returning
from a phone call/backgrounding, or wait for an orb tap?

**Q8 — Tier AI cap (Phase 5).** Implement the decision-logged 5/day
actionable-instruction server cap now (it's currently documented as enforced
but isn't), or defer until the paywall flips `TierLimits.enforced` and fix
the doc comment now? *Recommend: implement now behind the same
`tier_limits_v1` RC blob — it's the cost model.*

**Q9 — Coach temperature (Phase 5).** Pin server-side at what value?
*Recommend 0.6 for coach_agent/chat, 0.7 for coach_agent_voice (matches
current client behavior), 0.4 for coaching_summary/circle_pulse.*

**Q10 — Scope check.** Anything here Miko wants pulled forward, cut, or
deferred (e.g. barge-in / listen-while-speaking was deliberately left OUT of
this wave as a product feature, not a fix)?

---

*A decision-log entry in `documentation/GUIDELINES.md` will be appended once
the questions are answered and the design is settled — per house process,
nothing above is implemented until then.*
