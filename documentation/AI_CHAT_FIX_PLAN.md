# AI Chat Fix Plan — DRAFT v0.1 (2026-09-26)

Status: **v0.2 — decisions D1–D9 adopted by Miko 2026-09-26 (all nine recommendations); Phase 0 built the same day** (0.1 server fix awaiting deploy; 0.2 harness + 12 scenarios; 0.3 not started). **Phase 1 built 2026-09-26** (1.1/1.2 `AiProposal` lifecycle; 1.3 question-shape routing, `unknown` replaces the mutate default; 1.4 unknown verbs rejected — strict tool schemas DEFERRED to Phase 5.1 where the bake-off can validate them live; 1.5 by-row history marking, cancel/decline/auto-commit rows; day-prefetch moved to Phase 3.3). **Phase 2 built 2026-09-26** (2.1 deterministic batch id per proposal + `execute()` refuses a finished batch; 2.2 `AiPlanValidator` at confirm — past time today and day-drift block, date-aware dedup for today/tomorrow, named duplicates become card conflicts; 2.3 execution separated from bookkeeping, per-action outcomes persisted, final state retried, boot sweep closes finished batches instead of rolling them back; 2.4 goal deadline via date resolution, cadence/category/measurement from the model or the target text; 2.5 conflict detector compares on the action's day). Server prompt gained the createGoal cadence/category line (deploy pending). **Phase 3 built 2026-09-26** (3.1 `GoalProgressMath` shared math, progress in the goal's own units with window, days logged, behind-pace flag, steps due today, category/cadence, sorted behind-pace first, cap 8; 3.2 one busy picture per day — timed tasks with a duration, goal time blocks, calendar busy intervals for today AND tomorrow — inside per-user waking bounds from the sleep window (D3), reminder-only tasks not busy, calendar availability stated per day, up to 8 windows with a '+N more' marker; 3.3 tomorrow always sent, the tool description is now truthful; 3.4 rendering fixes; 3.5 opaque handles [t1]/[g1] with taskRef/goalRef resolution (D2)). Not done: the named-day prefetch — the get_day_schedule tool round still covers other days. Server prompt also gained the handles rule and the new planning-method line (deployed 2026-09-26). **Phase 4 built 2026-09-26** (4.1 history rows keep the assistant's text, a lossless plan summary with times, and a tool trace; cap 3000; conversation history = last 8 turns verbatim + one deterministic 'earlier in this session' line from up to 30 rows; 4.2 a session is a calendar day — closing the sheet calls `pauseSession()`, the first message on a new day rotates, relaunch adopts the same-day session id; 4.3 quote verification against User lines only with a 12-char/3-word floor, `rawUtterance` replaced by the real input before auto-commit; 4.4 `aiChat` returns `finishReason`, a cut reply carries the cut-off marker; 4.5 voice read-back of exactly what was stored plus 'undo' by voice or text). Server change in index.ts → deploy pending. Decision-log entries: `documentation/GUIDELINES.md` 2026-09-26. Source of every item:
`documentation/AI_CHAT_AUDIT_REVIEW_2026-09-26.md` (v2); references like "review §2.1 #3" point
there. Follows the repo's audit → fix-plan pattern (`AUDIT.md` → `AUDIT_FIX_PLAN.md`).

Scope: Coach chat (typed and voice), `aiChat` / `aiChatStream`, memory extraction, the goal and
task handlers the Coach uses. Out of scope (§6): anything that changes settled product stances.

---

## 1. Decisions that shape this plan

Each carried a recommendation; **all nine were adopted on 2026-09-26** and are now the plan's assumptions.

| # | Decision | Recommendation | Where it bites |
|---|---|---|---|
| D1 | Does the keyword router keep any authority over whether the model gets tools? | **No.** Every typed turn that reaches the agent path gets both tools. The router only decides whether a clear question may take the faster answer-only stream, and `unknown` replaces the `mutate` default. | Phase 1.3 |
| D2 | Opaque per-turn handles for existing items ("t3", "g2")? | **Yes.** Generated per turn, never persisted, mapped back inside the service. Keeps the "no raw ids" privacy property; removes title-matching ambiguity. | Phase 3.5 |
| D3 | Waking day: fixed 07:00–22:00 or per user? | **Per user:** derive from the configured sleep window / quiet hours when set, else 07:00–22:00; tell the model the bounds it was given. | Phase 3.2 |
| D4 | Direction: keep "context, not command" (settled) or the audit's hierarchy? | **Keep settled stance.** Build only goal↔task linkage (Phase 6), later. | Phase 6 |
| D5 | Session boundary: does closing the sheet end the session? | **No.** A session is a calendar day per account; the 48-hour purge and same-day hydration already assume this. Closing the sheet pauses, it does not reset. | Phase 4.2 |
| D6 | Model budget for `coach_agent`? | **Approve up to ~5× today's per-turn cost** if the bake-off shows a clear win; likely moot because the newest small model is cheaper than gpt-4o-mini. | Phase 5 |
| D7 | Voice auto-commit verbs (`createIntention`, `rememberFact`…) with no STT confidence? | **Read-back + spoken undo:** keep auto-commit, but the spoken reply repeats exactly what was stored and "undo" by voice reverts it. No new card. | Phase 4.5 |
| D8 | Tier-blind server cap: fail-safe now or full actionable-only counting now? | **Fail-safe now:** the daily instruction cap applies only when the user's tier is known to be free; questions never count. Full "server classifies actionable" arrives with monetization. | Phase 0.1 |
| D9 | Branch base and deploys? | **New branch `fix/ai-chat-reliability` off `main`** after `feat/onboarding-guest-first` merges (it touches the same service files). I ask before every `firebase deploy`. | §4 |

---

## 2. Principles carried over (settled, not reopened here)

- LLM proposes, engine disposes; deterministic code owns execution and timing.
- Nothing mutates without Confirm, except the four auto-commit verbs (with undo).
- Client-orchestrated loop, permanently; tools read local Isar data.
- Local-first writes (`outboxUpsert`/`outboxDelete`), watch-stream reads, client ids, `updatedAtMs`.
- AI is network-inherent: optimistic-then-honest, per-item errors with retry, never fake offline AI.
- Privacy contract: no raw ids, no calendar contents, coarse device labels only.
- Server owns the key, the prompt, the model, the quotas.

---

## 3. Phases

Sizes: S under half a day, M one to two days, L three or more. Each item names its failure story
(what the user sees when it goes wrong) because that is the project's definition of done.

### Phase 0 — Guardrails and harness (independent; first)

**0.1 Tier-blind daily cap fail-safe (server).** Review §2.1 #1. D8.
- `functions/src/index.ts`: `enforceRateLimit` applies `dailyInstructionCap` only when the caller's
  tier is known to be free (read from the same place the app's tier lives; if no tier source
  exists server-side yet, the cap is disabled and logged once). `dayTurns` increments only for
  turns that carried tools (the agent path), never for the answer-only stream. Keep the 300k
  token budget and 40/hour as they are.
- Tests: `functions/src/*.test.ts` (node --test) for the gate matrix.
- Failure story: config publishes a small cap → Pro users unaffected; free users see the existing
  "Daily AI limit reached" copy only after real instructions.
- Deploy required. Size S.

**0.2 Scenario harness (client).** Review §7. Size M.
- `test/features/ai_assistant/scenarios/`: a `ScriptedProxyClient` that feeds raw model replies
  (text and `propose_changes` tool-call JSON, one per round) under the real
  `ProxyAiOperatingLayerClient`, so the mapping, normaliser, parser, service, executor and history
  all run for real against in-memory repositories.
- A `Clock` seam where `DateTime.now()` is read on the decision path (assembler free windows,
  executor `_resolveDate`, service timestamps, deduplicator). The Time Tracker already does this
  (`ActivityReminderService` test clock); same pattern.
- Fixtures are the review's §7 scenarios; each asserts the resulting records (tasks, goals,
  batches, history rows), not just the reply text.
- Failure story: none (tests).

**0.3 Live-model runner (optional, feeds Phase 5).** Size S–M.
- `tool/ai_eval/` Dart script: runs the same scenarios against `aiChat` with a real account and
  a hard budget, records replies as fixtures for 0.2, reports tool-call validity, no-card-on-
  question rate, latency, tokens. Behind an environment flag; never in CI.

### Phase 1 — Plan state and routing (client)

**1.1 One proposal record.** Review §4 #2.
- `AiProposal { id, version, status, actions, resolvedDateKeys, historyEntryId, messageId,
  followUpQuestion, createdAt }`, status ∈ proposed | awaitingAnswer | applied | cancelled |
  superseded | expired | failed. One field in `AiAssistantService` replaces `_pendingPlan`,
  `_pendingClarification`, `_refiningPendingPlan`; message cards carry `proposalId`.
- Transitions are the only place state changes; a table in the class doc lists them.
- Older cards: Apply on a card whose proposal is superseded or older than its date basis
  re-runs validation (Phase 2.2) and either re-proposes with fresh dates or refuses honestly.
- Failure story: a card can never execute a proposal that is not `proposed`/`awaitingAnswer`.

**1.2 Stale-state fixes.** Review §1.1 #1, §2 #3, §2.1 #3, #8.
- Apply/confirm/cancel/decline move the proposal to a terminal status; parse-throw and
  error-result paths move it to `failed` and keep the clarification question for the Retry chip.
- The streaming gate blocks only on `awaitingAnswer`.
- Failure story: after any error, "yes" does nothing unless a live card exists.

**1.3 Router without a mutate default.** Review §1.1 #2, §2 #11. D1.
- `AiIntentRouter.classify` returns `query | suggest | mutate | unknown`; `unknown` and `mutate`
  both take the agent path with tools and no "return structured actions" hint; the hint for
  `mutate` becomes advisory ("the user may be asking for a change").
- Streaming only for `query` with question shape; "this week" joins the other-day pattern or the
  week detail is sent (choose the cheaper: send the week's titles for the next 7 days, capped).
- Prefetch: when the text names a day (`_otherDayPattern`), load that day's tasks into the
  payload so `get_day_schedule` rounds become rare.
- Failure story: a misread turn costs one tool round, never a card the user did not ask for.

**1.4 Strict schemas; unknown verbs rejected.** Review §2 #2, §1.2.
- `kCoachAgentTools`: `strict: true`, per-verb `anyOf` parameter objects, `additionalProperties:
  false`, optional fields nullable. `AiAction.fromJson` returns null for an unknown verb; the
  mapper drops it and logs. Normaliser keeps only time/date canonicalisation.
- Failure story: a drifted verb produces a tool-error round, not a task.

**1.5 History rows that tell the truth.** Review §1.1 #4, #8, §2 #4, §2.1 #2.
- `save()` returns the entry id; `markExecuted(entryId)` and `saveAssistantSummary(entryId, …)`
  target the proposal's own row. New rows for cancel, decline, apply-error, and auto-commit
  (`executed: true` with the executor's summary). `completedInSession` reads those rows.
- Failure story: the model is told "no" when the user said no.

Tests: review §7 scenarios 1, 2, 7, 8, 15. Size L.

### Phase 2 — Execution correctness (client)

**2.1 Idempotent batches.** Review §1.1 #3, §2 #5.
- `batchId = 'ai_batch_${proposal.id}_v${proposal.version}'`. `execute()` calls `findByBatchId`
  first: `completed` → return the stored result; `executing` and fresh → refuse with "still
  applying"; stranded → the existing sweep.
- Failure story: tapping Confirm twice, or retrying after a crash, can never create a second set.

**2.2 Validation at confirm (`AiPlanValidator`).** Review §1.1 #7, §4 #3.
- Re-resolve every date against the clock; if a `today`/`tomorrow` literal now lands on a
  different day than the proposal recorded, re-present the card with the new date.
- Past time today → block with "that time has already passed" and offer the next free slot.
- Existing same-title task on the target day → soft conflict ("already on tomorrow at 18:00").
- Overlap with tasks, goal time blocks, and calendar busy (Phase 3.2 snapshot) → soft conflict;
  active sleep/DND → hard block (existing behaviour).
- Version check: the card's proposal version must equal the live one.
- Failure story: the card shows exactly why an item is blocked; nothing silent.

**2.3 Execution separated from bookkeeping.** Review §1.1 #3 (both shapes).
- `execute()` writes `completed`/`partialFailure` before returning; a failed state write is
  retried once, then recorded in the batch's snapshot for the sweep to read.
- In `confirmPlan`, history/analytics writes run in their own try; the "nothing was lost" message
  appears only when `execute()` itself threw before any action ran. Partial results render per
  item (settled Q4).
- `sweepStrandedBatches` skips a batch whose succeeded ids are all present.
- Failure story: "Applied 2 of 3; Workout failed: <reason>", card marked executed.

**2.4 Goals created correctly.** Review §2 #6, §2.1 #4, #5.
- `_createGoal` resolves the deadline with `_resolveDate`; schema gains optional `cadence`
  (`daily | weekly | monthly | none`) and `category`; cadence maps to `repeatCadence` and the
  period; category maps through `GoalCategories` with `productivity` as the fallback.
- Failure story: "read 20 pages a day by tomorrow" is a daily goal ending tomorrow, not a
  30-day count goal that expired on creation.

**2.5 Date-aware conflict detector.** Review §1.1 #7, §2 #8.
- Reminder proximity and override windows compare only on the action's date; sleep window stays
  advisory on any date.
- Failure story: tomorrow's 14:00 task is not blocked by today's focus session.

Tests: review §7 scenarios 3, 4, 5, 6, 14. Size M–L.

### Phase 3 — The planning snapshot (client)

**3.1 Goal progress in the goal's own units.** Review §1.1 #6.
- One shared `GoalProgressMath` used by `goalTodayProgressProvider` and the assembler. Payload
  per goal: `logged`, `target`, `unit`, `window` (day/week/month/period), `daysLogged`,
  `daysInWindow`, `cadence`, `category`, `stepsDueToday`. Prompt line: "Music: 10/25 minutes
  today · 2 of 5 planned days logged this week". Offline formatter and the prompt's planning
  method updated to match. Goals sorted by behind-pace then deadline, cap 8.
- Failure story: never "0/25 minutes" for a goal with logged minutes.

**3.2 Free windows from one snapshot.** Review §1.1 #7, §2 #7, §2 #9.
- `PlanningSnapshotBuilder(day)` for today and the target day: planned tasks with duration ≥ 1,
  goal `ScheduledTimeBlock`s, calendar busy via `calendarBusyForDay(day)`, waking bounds per D3.
  Reminder-only tasks are not busy. No four-window cap (or "+N more").
- Each section carries `availability` (loaded | empty | notRequested | unavailable); the renderer
  prints "(calendar unavailable)" or "(not loaded for this turn)" instead of "(none)".
- Failure story: with calendar permission denied the prompt says so, and the model asks rather
  than assumes.

**3.3 Tomorrow always present.** Review §1.1 #5.
- Send tomorrow's tasks, blocks and windows on every agent-path turn (the slice is cached
  anyway); trim only week counts and patterns on query turns. Fix the tool description.

**3.4 Rendering fixes.** Review §2 #9: "min min", raw map dumps, consistent empty handling,
device-label vs windows consistency (both from the same snapshot).

**3.5 Handles (D2).** Per-turn `t1…tn` / `g1…gn` in the assembler; edit/move/delete accept
`taskRef`/`goalRef`; resolver uses the handle first, title fallback. Never persisted.

Tests: review §7 scenarios 9–13. Size M–L.

### Phase 4 — Continuity and memory

**4.1 History that carries the turn.** Review §1.1 #8.
- Rows store the assistant's actual text (cap raised to fit a plan), a compact tool trace
  (calls + results), and events. `buildConversationHistory` = last 8 turns verbatim + one
  deterministic rolling summary of older turns, within a token budget. Auto-commit rows carry
  `executed: true`.
- Failure story: the model can quote the times it proposed two turns ago.

**4.2 Session boundary (D5).** Sheet close pauses the session; the day key ends it. Restore window
logic simplifies accordingly; the 48-hour purge unchanged.

**4.3 Memory attribution.** Review §1.1 #9.
- `quoteMatches` checks only `User:` lines; minimum quote 12 characters or 3 words.
- `rememberFact`: the service passes the real user input to the executor; the anchor check uses
  it, never the model's `rawUtterance`; unanchored → `aiInferred`.
- Source quote shown as a one-line italic under the fact in the list (optional polish).
- Failure story: an invented "fact" is always labelled as a guess.

**4.4 Truncation on the non-streaming path.** Review §1.1 #10 (server + client).
- `aiChat` returns `finishReason`; `AiProxyChatResult.truncated`; typed replies get the existing
  cut-off marker; a truncated tool call gets one repair round.
- Deploy required.

**4.5 Voice auto-commit read-back (D7).** The spoken reply repeats exactly what was stored;
"undo" / "no, forget that" within the turn reverts via the existing batch undo.

Tests: review §7 scenarios 16–19. Size M.

### Phase 5 — Model

**5.1 Server request builder and allow-list.** Review §2 #1, #16.
- `buildOpenAiRequest(route, messages, tools, stream)` with a per-family table:
  gpt-4o / gpt-4.1 → `max_tokens` + `temperature`; gpt-5.x / gpt-6 → `max_completion_tokens`,
  `reasoning_effort: "none"` (required for tool calling on Chat Completions with gpt-6 Sol/Luna),
  `temperature` only when effort is none. Allow-list widened to the candidates; an unlisted model
  in Remote Config logs an error and a metric and falls back to the default (never silent).
  `KNOWN_PURPOSES` gains `classify_task`, `recovery_triage`. Hard ceiling on RC `maxTokens`.
- Tests: `ai_routing.test.ts`, new `ai_request.test.ts`.
- Deploy required. Size S–M.

**5.2 Bake-off.** Live runner (0.3) over the §7 scenarios plus ~30 realistic prompts. Candidates:
`gpt-4.1-mini` (drop-in), `gpt-6-luna` (or `gpt-5.6-luna`), `gpt-6-sol` (or `gpt-5.4-mini`).
Metrics: valid tool calls, correct verb + params, no card on questions, plan quality on a rubric,
p50/p95 latency, cost per turn. Decision recorded in the decision log.

**5.3 Tiering** via `ai_purpose_routes`: cheapest passing model for system purposes, the winner
for `coach_agent`, optionally a `coach_agent_plan` purpose for suggest turns.

Size M overall.

### Phase 6 — Goal↔task linkage (D4)

- `PlannedTask.goalId` (nullable): Isar field + build_runner, outbox field, merge unchanged (LWW
  on `updatedAtMs`), Firestore field; goal detail lists linked tasks.
- AI: `createTask.goalTitle` optional → resolver → `goalId`; suggest prompts may name the goal a
  task serves; planning method prefers behind-pace goals.
- Failure story: an unresolved goal title leaves the task unlinked, never blocks creation.
- Size L; its own branch after Phases 1–3 ship.

### Phase 7 — Hygiene

- Delete the client `_kSystemPrompt` and addenda (stream messages send a one-line placeholder the
  server replaces); update the test that pins it.
- `CODEBASE_GUIDE.md` §7/§10 rewritten to the real pipeline; decision-log entries for D1–D9;
  `CONTENT_IDEAS.md` story beat ("the audit that audited the audit").
- Size S.

---

## 4. Sequencing, branches, releases

| Step | Contents | Ships as |
|---|---|---|
| A | Phase 0.1 | Functions deploy (ask first) |
| B | Phase 0.2, 1, 2 | One TestFlight build: multi-turn behaviour changes together |
| C | Phase 3, 4 (+ 4.4 deploy) | Next TestFlight build |
| D | Phase 5 | Functions deploy + Remote Config flip after the bake-off |
| E | Phase 6 | Own feature branch |
| F | Phase 7 | Rides with C or D |

Branch: `fix/ai-chat-reliability` (D9). Two sessions share this checkout: stage only own files,
check `git status` first. No commits or pushes without explicit permission.

---

## 5. Definition of done (per `CLAUDE.md`)

- Every item names its failure story above; AI paths follow optimistic-then-honest.
- `flutter analyze` clean; full Flutter suite green; `npm test` in `functions/` green.
- The §7 scenario fixtures pass in the harness; the manual device pass covers the same list
  before each TestFlight build.
- Decision-log entries appended in `documentation/GUIDELINES.md` for D1–D9 and for the model
  choice; story beat in `CONTENT_IDEAS.md`.

---

## 6. Explicitly not doing

Server-side agent loop; Direction as a managed hierarchy; OpenAI-hosted conversation state;
vector retrieval over memory; persona work; barge-in; L3 realtime voice; a confirm card for
intention capture (settled 2026-07-23).

---

## 7. Size summary

| Phase | Size | Deploy |
|---|---|---|
| 0 | S + M (+S optional) | 0.1 yes |
| 1 | L | no |
| 2 | M–L | no |
| 3 | M–L | no |
| 4 | M | 4.4 yes |
| 5 | M | yes |
| 6 | L | no |
| 7 | S | no |
