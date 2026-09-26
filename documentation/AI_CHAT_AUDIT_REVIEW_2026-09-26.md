# AI Chat Audit Review — 2026-09-26 (Claude) — v2

Reviewed: `~/Downloads/New_AI_chat_audit_by_GPT6Astra 2.md` (dated 2026-09-26, written against
commit `cd90962` in a different checkout).
Verified against: this checkout, branch `feat/onboarding-guest-first` at `c4b4fbc`.
All line numbers below are from THIS checkout. Read-only: no code, config, or data changed.

v2 (same day): an Opus 5.5 pass fact-checked v1. I re-verified every one of its corrections and
new bugs against the code and OpenAI's official pages; all held. They are folded in below and
marked **[v2]**. The action plan that follows from this document is
`documentation/AI_CHAT_FIX_PLAN.md`.

Method: I read the router, parser, payload assembler, operating-layer client, server callable,
routing table, server prompt, free-window/calendar code, goal-progress code, and the action
models myself. Four verification passes (service state; execution/dedup/time; memory/voice/
server + a survey of every AI caller; PRDs + decision log) checked each claim line by line.
Anything I could not verify is listed in §8.

---

## 1. Verdict on the external audit

**Overall: accurate.** All ten findings are real code behaviours on this checkout. The audit is
right that the screenshot failures are mostly application bugs (state, routing, validation),
not model weakness, and right to sequence correctness fixes before a model change. It is also
right that the pieces for the intended experience already exist but are not wired together.

Where it is imprecise, the truth is usually worse, not better. Where its recommendations touch
settled product decisions (§1.3), Miko decides.

### 1.1 Finding-by-finding

| # | Finding | Verdict | What I would add or correct |
|---|---|---|---|
| 1 | Applied suggestion stays the "plan being discussed" | **Confirmed** | More general than stated. Every suggest result sets `_pendingClarification` (`ai_assistant_service.dart:721`; also 663, 685). Apply (`1310–1330`) and confirm (`1240`) clear only `_pendingPlan`. The next turn consumes it (`523–527`) with no gate on wording, so it lasts exactly one turn, but that turn is framed "refine this plan, keep the times" (`ai_intent_parser.dart:146–151`) with dedup off (`305–310`). If the model re-proposes, it re-arms. Amplifier the audit missed: while it is set, the answer-only streaming path is disabled (`341–357`), so an innocent question is forced into the tool path carrying the old plan. |
| 2 | Ordinary questions classified as change requests | **Confirmed** | I re-derived the table by hand against `ai_intent_router.dart:61–97`; every row is correct. Bare "What do i have" has a query word but no schedule word and no "?", so it falls to the `mutate` default at line 96. Already logged as open item M8 in the root `AUDIT.md:568` **[v2: not the prelaunch plan's M8, which is a TTS item]**; the external audit re-discovered it. The read-only guard (`ai_intent_parser.dart:500–511`) only converts when the offline formatter recognises the question; a `suggest`-typed re-proposal is never coerced. |
| 3 | Duplicate protection cannot stop these duplicates | **Confirmed** | Today-only comparison is deliberate (`ai_plan_deduplicator.dart:58–68`, fix E10 for the opposite bug), which explains why nobody noticed. Worse than stated: idempotency is *documented* (`isar_ai_action_batch.dart:10–11`, `findByBatchId` labelled "idempotency check") but `execute()` never calls it and mints fresh ids (`ai_action_executor.dart:161`, `1269`). **[v2]** The retry hole has two shapes: (a) the `confirmPlan` catch (`ai_assistant_service.dart:1289–1301`) wraps the history writes that run *after* execution, so a history failure shows "Applying that hit a snag — nothing was lost. Tap Confirm to try again" while every action is already applied, and the retry creates permanent duplicates; (b) if `updateSnapshot`/`updateState` throws inside the loop (`ai_action_executor.dart:276–295`) the batch stays `executing`, and on a later launch `sweepStrandedBatches` (`574`, wired at `app_bootstrap.dart:137`, 5-minute threshold) silently rolls the first attempt back, including any edits made to those items since. Mitigation the audit skipped: an executed card goes inert (`planned_changes_card.dart:79–91`), so re-tapping the same card is impossible. |
| 4 | Old cards stay live; execution marks the wrong history row | **Confirmed** | `_markLatest` (`ai_interaction_history_repository.dart:101–122`) takes only a session id. Also missed: `saveAssistantSummary` (`66–78`) *overwrites* the newest row's summary with "Already applied (do not repeat): …", clobbering whatever unrelated question came last. A day-old "tomorrow" draft resolves its date at execution time (`_resolveDate`, `1960–1978`), so it lands on a different day than proposed. |
| 5 | Omitted context presented as confirmed absence | **Confirmed** | `ai_operating_layer_client.dart:778` and `789` print "(none)" for tomorrow whenever a query turn trimmed it (`ai_payload_assembler.dart:121–136`). Inconsistent with "Today's tasks", which is silently omitted when empty (`727`). Every builder returns `[]` on failure (`488–521`), so "failed to read" and "nothing planned" are the same string. **[v2]** The `get_day_schedule` tool description tells the model "context always includes today and tomorrow" (`ai_operating_layer_client.dart:385–387`), steering it away from looking tomorrow up on the very turns where tomorrow was trimmed. |
| 6 | Goal progress uses incompatible units | **Confirmed exactly** | `daysMet` = `countMetCheckIns` (`goal_period_helpers.dart:228–230`, a count of days), printed against a value target (`ai_operating_layer_client.dart:751`): "Music: 0/25 minutes". The goal UI sums check-in values over the evaluation window (`goals_providers.dart:350–364`). The same confusion is in the offline formatter (`ai_schedule_answer_formatter.dart:50`) and in the prompt's planning method ("daysMet vs target pace", `coach_prompts.ts:151`). Goals are `take(5)` in repository order (`ai_payload_assembler.dart:627`, `649`). **[v2]** Two cases: a check-in's `metCommitment` is judged against the *evaluation window's* accumulated total (`goal_card.dart:110–113`, `goal_counter_sheet.dart:122`). For daily goals the count is valid and only the label is wrong. For weekly, monthly and non-repeating goals (every AI-created goal) it reads 0 until the whole period's total reaches the target: "Gym 3 sessions/week" with 2 logged shows "0/3 sessions". Also: goal `category` and `repeatSchedule` are gathered (`ai_payload_assembler.dart:638`, `682–683`) but never written into the prompt (`ai_operating_layer_client.dart:737–756`). |
| 7 | Calendar awareness partial; scheduling validation weak | **Confirmed** | The bridge exists (`calendarBusyToScheduleMaps`, `context_snapshot_service.dart:15–41`) and feeds `freeMinutesNow` (`105–110`), but the Coach's free windows use planned tasks only (`ai_payload_assembler.dart:150–156`). Tomorrow's calendar is never fetched at all (the snapshot is today-only). Goal time blocks (`ScheduledTimeBlock`) are not in the schedule maps. Waking day is a constant (`free_window_calculator.dart:35–36`). Conflict detector: reminder proximity, override windows, quiet hours only (`ai_conflict_detector.dart:41–100`); reminder proximity discards the date (`123–127`), so reminders on different days "collide". **[v2]** The focus/override window check is date-blind too (`143–187`): it compares clock minutes against *today's* active override, so a task for tomorrow at 14:00 is blocked by today's 13:00–15:00 focus. **[v2]** Reminder-only tasks render with end time "?" (`ai_payload_assembler.dart:614–619`) and the calculator's fallback turns that into a 30-minute busy block (`free_window_calculator.dart:72`), contradicting the prompt's own rule that "reminder only" items are not busy time. No now-check anywhere in the create path. |
| 8 | Visible continuity exceeds model continuity | **Confirmed** | Mutate previews are summarised as "Plan preview: createTask: title; …" with no times (`ai_assistant_service.dart:1727–1788`); suggest and streamed turns keep more. Cancel, decline, and short confirmation replies write **no** history row (only `406`, `761`, `901` save), so the model never sees "no". Tool calls and `get_day_schedule` results are never persisted, so a day the model looked up last turn is unknown this turn. The prompt rule "if your earlier times are no longer visible… pick sensible times yourself" (`coach_prompts.ts:101–102`) plus lossy summaries is a duplicate generator by design. |
| 9 | Memory can mistake assistant text for a user fact | **Confirmed; mitigations weaker than v1 said [v2]** | Transcript is speaker-labelled (`memory_extraction_service.dart:432–446`) and the prompt asks for a quote from a "User:" line, but `quoteMatches` (`memory_extraction_parser.dart:98–102`) is a whole-transcript substring test, so an "Assistant:" sentence verifies as `userStated`. Fix is a few lines (match against User lines only). **[v2 corrections]** The 0.95 confidence is only the fallback when the model omits a value (`232–234`); the model's own number wins. The source quote is shown only in the tap-to-open fact sheet (`memory_knowledge_screen.dart:237–271`), not in the list. The chat-path `rememberFact` "anchor" check is hollow: it compares the fact against `rawUtterance`, which the model itself supplies (`ai_action_executor.dart:1091–1093`), and nothing compares that to the real user input, so the model can store its own invention as `userStated` at confidence 1.0. A three-character quote is enough to pass verification (`q.length < 3` is the only floor). Real mitigations: temp 0, two contradictions to deactivate, visible provenance badges. |
| 10 | Truncation handled inconsistently | **Confirmed** | `aiChat` never reads `finish_reason` (`functions/src/index.ts:781–833`). Stream defaults to "stop" when no finish chunk arrives (`1062`). Mitigations: tool-less purposes use `response_format: json_object` and every caller JSON-parses, so a cut body fails loudly and retries or falls back; truncated `propose_changes` arguments fail decode and get a tool-error retry. Residual gap is prose replies near the 800-token cap. Voice: no STT confidence gate anywhere; transcript goes through the same router with the same `mutate` default. |

### 1.2 Its recommendations

- Five requirements (trustworthy snapshot, explicit plan state, retrieval when needed, validated
  execution, grounded explanations): **agree** with all five. See §4 for how I would build them
  inside the settled architecture.
- Typed strict action schemas: **agree.** The current `propose_changes.parameters` is an untyped
  `object` with a prose description (`ai_operating_layer_client.dart:356–370`), and without
  `strict: true` the `actionType` enum is advisory, not enforced **[v2]**. Strict mode
  (`additionalProperties: false`, every field required, `anyOf` per verb) removes the key-drift
  class of bugs the normaliser exists to patch.
- Evaluate models after correctness fixes: **agree**, with one correction (§5): the model
  cannot be flipped to the current generation by config today at all.
- Order of work: **mostly agree**, but a minimal regression harness should come first, not last,
  because every fix in its steps 1–2 changes multi-turn behaviour that nothing currently tests.

### 1.3 Where it conflicts with settled decisions (Miko's call)

- **"Yearly direction → quarterly outcomes → monthly priorities → next actions → calendar →
  progress."** The Direction PRD (2026-09-11) settled the opposite stance: "Direction is not
  something SidePal asks the user to accomplish. It is something SidePal remembers while helping
  them," context not command, and no Coach tool writes Direction. The audit's planning layer would
  turn Direction into a hierarchy the app manages. The real gap underneath is smaller and worth
  doing regardless: `PlannedTask` has no goal field (`task_item.dart:38–66`), so no AI-created
  task can belong to a goal, and goal steps (`GoalAction`) are never shown to the model.
- **Retrieval tools.** The humanizing PRD settled "client-orchestrated, permanently" and
  "LLM proposes, engine disposes." Tools that read local Isar data are compatible with that;
  anything that moves reasoning server-side is not.

---

## 2. What the external audit missed

Ranked by how much each changes the plan.

1. **The model cannot be upgraded by config flip today (blocks the whole "model" question).**
   **[v2, corrected]** The real blocker is the allow-list: a model name outside
   `ALLOWED_MODELS` (`ai_routing.ts:100–105`) is dropped *silently* (`128–130`), so a Remote
   Config switch to `gpt-6-luna` keeps running gpt-4o-mini with no error and no log. Behind that
   sit request-shape constraints, from OpenAI's model guidance and model pages (fetched
   2026-09-26): sampling parameters (`temperature`, `top_p`) are accepted only when
   `reasoning_effort` is `"none"`; on Chat Completions, gpt-6 Sol and Luna support function
   calling **only** with `reasoning_effort: "none"`, and gpt-6 Astra has no `"none"` at all;
   the gpt-5 family rejects `max_tokens` in favour of `max_completion_tokens` (community reports;
   not stated on the gpt-6 pages, verify). The server sends `temperature` and `max_tokens` with
   no reasoning setting (`functions/src/index.ts:680–682`, `957–958`). So "chat stays gpt-4o-mini,
   upgradeable per-purpose by config flip" is true only for gpt-4o and gpt-4.1(-mini). Migration
   needs a per-model-family request builder (`reasoning_effort: "none"` only for models that
   accept it, since gpt-4o/4.1 reject the parameter; `max_completion_tokens`; drop temperature
   when effort is not none), an allow-list update, a *loud* failure on an unlisted model, and a
   deploy.
2. **Unknown verbs silently become `createTask`.** `AiAction.fromJson` uses
   `orElse: () => ActionType.createTask` (`ai_action.dart:103–106`). A drifted verb
   ("updateTask", "scheduleTask") with title/time/date becomes a new task on the card. The
   non-strict tool schema is why the enum does not stop it **[v2]**.
3. **Stale pending state disables streaming** (`ai_assistant_service.dart:351`, `825`), pushing
   read-only questions into the tool path exactly when the model is primed to re-plan. This is the
   mechanism that turns finding 1 into the screenshot sequence.
4. **History summary overwrite** (`ai_interaction_history_repository.dart:66–78`): confirmation
   rewrites the newest row regardless of which turn produced the plan.
5. **Executor retry hole** (§1.1 finding 3, both shapes); no test covers re-execution.
6. **Data-model gap, not just a handler gap:** no task↔goal relation exists; `createGoal`
   hard-codes category `productivity`, `MeasurementKind.count`, intensity 3, repeat off
   (`ai_action_executor.dart:1497–1555`), so "run 20 km a week" becomes 20 km over 30 days with
   no repeat; `modifyGoal` can change title/target/deadline/intensity only. The model is never
   told a goal's steps, cadence, or category.
7. **Tomorrow's calendar is never read.** `ContextSnapshotService.capture()` is today-only, so
   even after merging calendar into free windows, "plan tomorrow" would still be calendar-blind.
8. **Conflict detector date bugs** (`ai_conflict_detector.dart:123–127`, `143–187`): reminder
   proximity and the focus/override window are both compared on clock minutes regardless of day.
9. **Prompt rendering bugs.** "Today's tasks" prints "30 min min" / "reminder only min"
   (`ai_operating_layer_client.dart:731` on a value already labelled at
   `ai_payload_assembler.dart:590–592`). Preferences and proactive context are dumped as raw Dart
   map `toString()` (`822`, `840`). Free windows are cut to four with no "more" marker
   (`free_window_calculator.dart:141`). The device-context label `free_25m` is calendar-aware
   (`context_snapshot.dart:71–89`) while the free-windows line beside it is task-only, so the two
   can contradict each other in one prompt **[v2]**.
10. **Vestigial client prompt still shipped every turn** (`ai_operating_layer_client.dart:126–263`,
    temperature 0.45 at `458`) and now diverged from the server copy (it lacks "Their time",
    "Their direction", and planning step 0). Server wins (`index.ts:313–325`), so no runtime
    effect, but one test pins this dead prompt, and Phase 5 said to delete it.
11. **Streamed query turns have no tools and no week detail.** Week overview is counts only
    (`ai_payload_assembler.dart:526–570`) and, with the 14-day patterns, is sent only on planning
    turns or a "week" focus (`125–127`) **[v2]**. "What do I have later this week?" streams and can
    only answer with counts; without the question mark it is not even a query ("week" is not in
    the router's schedule words, `ai_intent_router.dart:141–149`) and falls to the `mutate`
    default, another instance of finding 2 **[v2]**.
12. **Telemetry buckets** `classify_task` and `recovery_triage` under "other"
    (`index.ts:361–373` vs `ai_routing.ts:81–89`). Cosmetic, but it hides two real purposes.
13. **Auto-commit verbs bypass the card on voice.** `createIntention`, `rememberFact`, `updateFact`,
    `forgetFact` write immediately (`ai_assistant_service.dart:632–646`, product decision
    2026-07-23). With no STT confidence gate, a misheard "remember…" writes before undo. Accepted
    by design; worth a confirmation or read-back when the utterance is short.
14. **No evaluation harness.** **[v2, corrected]** Four test files pin prompt text
    (`ai_education_grounding_test`, `voice_reply_streaming_service_test`,
    `direction_ai_seams_test`, `time_tracker_v1_1_test`; one of them pins the vestigial client
    prompt), and `ai_clarification_carryforward_test` does run the real service and parser across
    several turns with a fake client. What is true: nothing covers suggest → apply → question,
    nothing runs the same actions through the executor twice, and nothing measures the live model.
15. **Stale docs.** `CODEBASE_GUIDE.md` §7 and §10 describe an older pipeline (one function,
    snapshot undo, mock on kill switch). Anyone new, human or model, will be misled.
16. **Remote Config can raise a purpose's token cap without ceiling [v2].** `parseRouteOverrides`
    accepts any `maxTokens >= 1` (`ai_routing.ts:131–137`) and `clampMaxTokens` caps the client
    value at the *route's* number (`index.ts:188–191`, `668`), so `MAX_TOKENS_CAP` is only a
    default.

### 2.1 Found by the Opus 5.5 pass, validated by me [v2]

1. **The server's daily instruction cap ignores the user's plan** (`index.ts:241–250` reads
   `freeAiInstructionsPerDay` from `tier_limits_v1`; `512–519` enforces it for every uid; there is
   no tier lookup anywhere in `aiChat`). If `tier_limits_v1` is ever published with the free limit
   of 5, Pro users are capped at 5 too. Worse: it counts every charged turn (`dayTurns`), including
   questions, which contradicts the 2026-07-20 decision that only actionable instructions count.
   Today the client's 5 is display-only and the server default is 1000, so nothing is broken yet.
   This is independent of the AI work and must land before that config goes live.
2. **Auto-committed actions are logged as unapplied previews.** The auto-commit path
   (`_autoCommitIntentionActions`, `1037`) executes, but the turn's history row is saved at `761`
   with `_planPreviewSummary` and `executed` false; only `confirmPlan` ever calls `markExecuted`
   (`1212`). The model therefore sees "Plan preview: rememberFact: …" as something not yet done.
   Partial mitigation: intentions and facts still reach the model through the open-promises and
   memory sections, so re-creation is unlikely; re-proposal is not.
3. **A stale plan survives its card.** A new turn calls `_demoteCurrentPlan()` (`517`) before
   parsing, which removes the card's buttons. If the parse then throws (`540–573`) or returns an
   error result (`586–617`), `_pendingPlan` is never cleared, so a later "yes" hits the short-reply
   gate (`304`) and executes a plan whose card shows no buttons.
4. **An AI goal with deadline "today" or "tomorrow" is born expired.** The normaliser keeps those
   as literals (`ai_action_param_normaliser.dart:226–230`, and `deadline` is a date key at `78`);
   `_createGoal` parses with `DateKeys.parseLocalDateKey` (`ai_action_executor.dart:1507–1516`),
   which throws on "tomorrow", and the catch sets the period end to *now*. `modifyGoal` uses
   `_resolveDate` (`1609–1611`) and handles the same words correctly.
5. **Goal cadence is lost** (see §2 #6): "a week" never becomes a weekly repeat.
6. **Reminder-only tasks block 30 minutes of free time** (see §1.1 #7).
7. **Focus-window conflict check ignores dates** (see §1.1 #7).
8. **The pending clarification is lost before a retry.** It is consumed at `527` before the model
   call; neither the throw path nor the error-result path restores it, so the Retry chip re-sends
   the text without the question it was answering.

---

## 3. Are we giving the model the data it needs?

What the tool path sends (`ai_payload_assembler.dart:129–165`,
`ai_operating_layer_client.dart:667–929`): today's tasks (title, time, duration, status); five
active goals (title, target, deadline; category is gathered but not rendered); five goal-progress
rows (repeat schedule gathered but not rendered); today's schedule blocks; tomorrow's tasks and
blocks, week counts and 14-day patterns on planning turns only **[v2]**; free windows (tasks only,
07:00–22:00, max four); focus/override state; preferences with 7-day stats; today's Time Tracker
timeline; up to 20 scored memory facts; 10 people; 3 episodic summaries; 15 open promises; coarse
device labels; Direction lines; "already applied this session"; the previous plan when refining;
and the last 10 turns as user text plus assistant summaries. The privacy contract (no raw ids, no
calendar contents, coarse labels only) is well built and worth keeping.

**Verdict: enough to answer "what's on today," not enough to plan well or to stay consistent
across turns.**

| Need | Status | Gap |
|---|---|---|
| Today's commitments | Good | Rendering bug ("min min"); reminder-only tasks wrongly count as 30 busy minutes; unscheduled tasks are invisible to free windows (correct) but the model is not told they exist as work to place |
| Tomorrow / week | Partial | Trimmed on query turns and then declared "(none)" while the tool description says tomorrow is always present; week is counts only; other days need a tool round the streaming path cannot make |
| Free time | Wrong for planning | Calendar busy intervals not merged (and never fetched for tomorrow); goal time blocks absent; fixed 07:00–22:00; no per-user wake/sleep; four-window cap; contradicts the calendar-aware `free_Nm` label beside it |
| Goal progress | Wrong | Days-met vs value target (zero for any non-daily goal until the period target is hit); no logged-value sum; no steps; category and cadence gathered but not sent; first five goals only |
| Existing items as targets | Weak | No handles, so edit/move/delete match by title; two same-title tasks force a question; the model cannot say "the 18:00 Workout that already exists" precisely |
| Conversation state | Lossy | Times dropped from mutate summaries; no cancel/decline/apply events; auto-commits recorded as unapplied; tool results not carried; session ends when the sheet closes (10-min restore) |
| Availability of each section | Missing | "not requested", "unavailable", "empty", "stale" all render the same |
| Memory, people, promises, Direction, timeline | Good | Attribution bugs (§1.1 #9) are the correctness issues |
| Time and date | Good | Weekday, date, local time given; timezone name not given (harmless today) |

The "no raw ids" rule is the one place I would push back on the founding PRD: an opaque
per-turn handle ("t3") is not a database id, keeps the privacy property, and removes an entire
class of title-resolution ambiguity. Miko's call.

---

## 4. Is the architecture right?

**Keep (these are strengths and several are settled):** Isar-local data with a thin server proxy;
server-held key, server-owned prompt, per-purpose routing and quotas; the confirm gate with a
real executor and inverse-op undo; memory with provenance and visible source quotes; client
orchestration of the loop (settled: tools read local data, so the loop must run where the data
is); the honest kill switch.

**Change (the five requirements from the audit, placed inside this architecture):**

1. **Routing.** The keyword router should never decide whether the model gets tools. Give the
   model both tools on every typed turn that reaches the agent path; a question simply produces
   no `propose_changes`. Keep the keyword classifier only as a latency optimisation for the
   streaming path, and make the `mutate` default impossible (unknown → tools available, no
   "return structured actions" hint). Prefetch instead of tool rounds: the service already
   detects day references (`_otherDayPattern`); load that day's schedule into the payload so the
   round trip is rare.
2. **Plan state as an entity.** One record per proposal: id, version, status
   (proposed / applied / cancelled / superseded / expired / failed), the exact actions, the dates
   they resolve to, and the history row id. "Do it" resolves against the current proposal only;
   applying an older card requires re-validation; superseding is explicit; cancel and error write
   events. Replace the five interacting fields (`_pendingPlan`, `_pendingClarification`,
   `_refiningPendingPlan`, per-message `draftPlan`, history flags) with that record.
3. **Idempotent, validated execution.** Persist the batch (keyed by plan id + version) before
   executing; `execute()` checks `findByBatchId` and refuses a completed batch. At confirm, re-run:
   date resolution against *now*, past-time rejection, existing-record check on the target day,
   task/calendar/time-block overlap, and the plan version. Separate execution from bookkeeping so
   a history failure can never say "nothing was lost" after actions applied.
4. **Typed schemas.** Strict per-verb parameter schemas; delete the alias normaliser paths they
   make unnecessary; make `fromJson` reject unknown verbs.
5. **Continuity.** Store real assistant text and tool results per turn (the 48-hour purge already
   bounds it); record cancel/decline/apply/auto-commit as events; send the last N turns verbatim
   plus one rolling summary. Decide whether closing the sheet should end a session at all.
6. **One planning snapshot** with per-section availability, built once per turn from tasks,
   goal blocks, calendar busy intervals (today and the target day), preferences, and correct goal
   progress. Render "not loaded for this turn" and "unavailable" as such.

**Considered and not recommended:** a server-side agent (settled no, and the tools are local);
OpenAI-hosted conversation state (moves user data to a third party and cuts across the
purge rules); vector retrieval over memory (the data is a few thousand tokens per user; scored
selection is the right tool at this size). A read tool for goals and older sessions is fine, but
prefetch first.

---

## 5. Is the model good enough?

**Evidence.** Every screenshot failure the audit traced has an application-side cause that
would defeat any model: poisoned "refine this plan" context, a `mutate` hint on a question,
tomorrow declared empty, wrong progress units, no idempotency. Fix those first or a model
change will look like it helped for a week.

**But the model is also the weakest choice available.** `gpt-4o-mini` (July 2024) is the oldest
small model still on OpenAI's price list, running a 1,541-word rule prompt
(`coach_prompts.ts`) that leans hard on instruction following. The lineup on the OpenAI pricing
page as of today (fetched 2026-09-26; verify in the console):

| Model | Input / cached / output per 1M tokens |
|---|---|
| gpt-4o-mini (current) | $0.15 / $0.075 / $0.60 |
| gpt-4.1-mini (allow-listed, drop-in) | $0.40 / $0.10 / $1.60 |
| gpt-4.1-nano | $0.10 / $0.025 / $0.40 |
| gpt-5-mini | $0.25 / $0.025 / $2.00 |
| gpt-5.4-mini | $0.75 / $0.075 / $4.50 |
| gpt-5.6-luna | $0.20 / $0.02 / $1.20 |
| gpt-6-luna | $0.10 / $0.01 / $0.50 |
| gpt-6-sol | $2.00 / $0.20 / $10.00 |
| gpt-5.5 | $5.00 / $0.50 / $30.00 |

Rough cost of one Coach turn (about 8k input tokens across 1–2 rounds, 400 output):

| Model | Per turn | Per user per month at 20 turns/day |
|---|---|---|
| gpt-4o-mini | ~$0.0015 | ~$0.90 |
| gpt-4.1-mini | ~$0.004 | ~$2.30 |
| gpt-5.4-mini | ~$0.008 | ~$4.80 |
| gpt-6-luna | ~$0.001 | ~$0.60 |
| gpt-6-sol | ~$0.02 | ~$12 |

Cost is therefore not what keeps this on gpt-4o-mini. **[v2]** Note that `gpt-6-luna` is cheaper
per turn than today's model, so if it passes the bake-off, cost stops being a factor at all.
**[v2, corrected]** Spend is bounded today by the 40 turns/hour and 300k tokens/day server
limits only; the free tier's "5 instructions/day" is a client display default locked behind the
paywall flag and is not enforced (the server default is 1000, tier-blind; see §2.1 #1).
Reasoning-class models bill reasoning tokens as output and add latency; for a chat coach use
`reasoning_effort: "none"` where the model supports it (required for tool calling on Chat
Completions with gpt-6 Sol/Luna anyway) or a non-reasoning model.

**What I cannot say:** which of these is best for this prompt. Models released after my
training data (gpt-5.4 onward, gpt-6) I cannot assess. The honest path is a bake-off on the
scenarios in §7, measuring tool-call correctness, resulting records, latency, and cost.

**Recommendation.**
1. Fix the server request builder and allow-list (§2 #1), with a loud failure on an unlisted
   model, so the flip is possible.
2. Run the bake-off on the eval set with three candidates: `gpt-4.1-mini` (drop-in today),
   the newest small model (`gpt-6-luna` or `gpt-5.6-luna`), and one mid tier (`gpt-6-sol` or
   `gpt-5.4-mini`).
3. Tier by purpose, which the routing table already supports: cheapest model that passes for
   system purposes (classify, triage, extract, reflect); the winner for `coach_agent`; consider a
   separate `coach_agent_plan` purpose for suggest turns if the mid tier wins only there.
4. Keep the prompt server-owned and cacheable; move the per-turn context block after the stable
   history if cache hit rate matters once the model is pricier.

---

## 6. Recommended order (mine, v2)

The worked-out plan is `documentation/AI_CHAT_FIX_PLAN.md`. Summary:

0. **Two independent fixes first:** the tier-blind server cap (§2.1 #1, before `tier_limits_v1`
   ever publishes a small number) and a small **regression harness** that replays fixtures
   through the real pipeline with a fake clock and recorded model outputs. Scenarios in §7.
1. **State and routing:** plan entity with status; no `mutate` default; tools on every agent-path
   turn; stale state can no longer disable streaming or survive an error turn; unknown verbs
   rejected; strict schemas; correct history row marking; cancel/decline/auto-commit recorded.
2. **Execution:** idempotent batches; validation at confirm (now, date, overlap, existing);
   execution separated from bookkeeping so "nothing was lost" is only ever true; boot sweep
   cannot roll back a batch whose actions completed; goal deadline and cadence; date-aware
   conflict detector.
3. **Data correctness:** goal progress in the goal's own units with logged sum; category, cadence
   and steps in the payload; calendar (today and target day) and goal blocks merged into free
   windows; reminder-only tasks not busy; availability states; rendering fixes; always send
   tomorrow.
4. **Continuity and memory:** real assistant turns and events in history; User-line-only quote
   verification with a sane minimum length; `rememberFact` anchored to the real input;
   `finish_reason` surfaced on the non-streaming path.
5. **Model:** per-model-family request builder, allow-list with loud failure, bake-off,
   per-purpose tiering.
6. **Goal↔task linkage** in the data model (a goal field on tasks, AI verbs that set it), which
   is the part of the audit's "planning chain" that fits the settled Direction stance.
7. Delete the vestigial client prompt; refresh `CODEBASE_GUIDE.md` §7/§10; telemetry keys; a
   hard ceiling on Remote Config token overrides.

---

## 7. Regression scenarios to build (from the screenshots plus the findings)

- Suggest → apply → confirm → "What do I have" → expect an answer, no card, no re-proposal.
- Suggest → ignore → "Should I work out?" → expect advice, no card.
- Tomorrow already has Workout 18:00 → "add workout tomorrow at 6pm" → expect "already there".
- Confirm a plan; history write fails after the actions applied → no "nothing was lost", card
  marked executed, retry creates nothing new.
- Confirm a plan; batch-state write fails mid-loop → next launch's sweep must not undo completed
  actions.
- Apply a two-day-old "tomorrow" draft → expect re-validation, not silent date drift.
- Older card applied while a newer question exists → history rows marked correctly.
- Plan pending → unrelated question → model error → "yes" → nothing executes.
- Query turn at 21:45 → free windows and "free until" claims match calendar plus tasks.
- Calendar busy 09:00–12:00, tasks none → plan must not place items before 12:00.
- Reminder-only task at 14:00 → 14:00–14:30 still reported free.
- Goal "Music 25 minutes/day", 10 minutes logged → progress reads 10/25 minutes.
- Goal "Gym 3 sessions/week", 2 logged → progress reads 2/3 this week.
- "Create a goal to read 20 pages a day by tomorrow" → goal not born expired; cadence daily.
- Model emits an unknown verb → rejected, not created.
- Voice transcript "How fast can Answer" → clarifying question, never a card.
- Memory extraction with an assistant-invented claim → stored as inferred, never stated.
- `rememberFact` whose `rawUtterance` does not match the real input → stored as inferred.
- Reply cut at the token cap on the non-streaming path → marked as cut off.
- Midnight rollover mid-session → "today" resolves consistently between proposal and execution.
- Remote Config names an unlisted model → loud log/metric, request still served by the default.

---

## 8. What I could not verify

- Production Remote Config values (`ai_purpose_routes`, `ai_system_prompts`, `tier_limits_v1`)
  and the deployed function versions; compile-time defaults are what I reviewed.
- The exact screenshot session; the causal links are inferred from code, same as the audit.
- Capabilities of models released after my training data; prices and parameter rules are from
  today's public pages. The `max_completion_tokens` requirement for gpt-6 is inferred from the
  gpt-5 family's documented behaviour, not stated on the gpt-6 pages.
- I did not run the Flutter or functions test suites (no code changed); the last commit reports
  a green suite.

---

## 9. Decisions only Miko can make

1. Drop the keyword router's authority over tools, or keep it as a hint only?
2. Allow opaque per-turn handles for existing items, or keep the strict "no ids" rule?
3. Per-user waking day (from Sleep mode / quiet hours) or the fixed 07:00–22:00?
4. Direction: keep "context, not command" (settled) or adopt the audit's planning hierarchy?
5. Should closing the Coach sheet end the session, or should a session be a day?
6. Model budget: is roughly 3–5× today's per-turn cost acceptable for the coach purpose if the
   bake-off shows a clear quality win? (Possibly moot: the newest small model is cheaper.)
7. Voice: add a confirmation or read-back for auto-commit verbs on short transcripts?
8. **[v2]** Tier cap: fail-safe now (cap applies only when the user's tier is known to be free)
   and full actionable-only counting later with monetization, or build the full rule now?
