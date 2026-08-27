# AI Chat & Live Conversation — GPT-5.6 Independent Audit

**Audit date:** 2026-08-27  
**Branch reviewed:** `feat/ux-fixes-and-stake-surrender`  
**Reference:** `AUDIT.md` §8, “AI chat & live conversation — deep audit”  
**Scope:** Coach chat, intent parsing, agent loop, confirmed actions, rollback and
undo, conversation history, memory/context, Cloud Functions, quotas, Voice Mode,
streaming STT/LLM/TTS, secondary AI surfaces, UI lifecycle, and relevant tests.

This document is an independent, read-only review. It records findings and
recommended priorities; it does not implement fixes.

## Executive verdict

The existing §8 audit is strong and its central conclusion is correct:
SidePal has a thoughtfully engineered AI pipeline, but the final execution and
failure-handling layers are not trustworthy enough for production.

The highest-risk issue remains fake success. Several advertised actions tell the
user they completed successfully even though no data changed. Undo is also more
dangerous than §8 reports: its snapshot implementation can restore unrelated
tasks, including after undoing a memory or intention action.

I found no material refutation of the existing CRITICAL/HIGH execution, race,
voice, server, or UX findings. I found several additional defects and a few
places where §8 is stale or overstates the impact.

## Trust-critical findings

### G1 — CRITICAL: Five advertised mutation verbs are no-op success stubs

The following confirmed actions return success copy without performing a write:

- `moveTask`
- `deleteTask`
- `modifyGoal`
- `deleteGoal`
- `removeReminder`

Evidence:

- `lib/features/ai_assistant/application/ai_action_executor.dart:965-1068`
- `lib/features/ai_assistant/application/ai_operating_layer_client.dart:304-323`
- `lib/features/ai_assistant/application/ai_capability_registry.dart:13-18`
- `lib/features/ai_assistant/application/quick_directives_provider.dart:20-38`

The model is allowed to propose these operations, the confirmation card presents
them as executable, and quick directives advertise them. After confirmation,
the executor reports success, persists the batch, and the chat says the work is
done.

**Impact:** Direct breach of the product’s core promise. A task remains scheduled
or a reminder remains armed after the coach says it was moved, deleted, or
removed.

### G2 — HIGH: `editTask` creates a duplicate

`_editTask` creates a new task with a new `StableId` instead of updating the
matched task:

- `lib/features/ai_assistant/application/ai_action_executor.dart:912-963`

The duplicate resets status, priority, order, metadata, and enforcement mode. It
also bypasses the normal task-tier creation guard.

**Impact:** “Move my workout from 9:00 to 10:00” can leave the 9:00 task and add
a second 10:00 task.

### G3 — HIGH, newly identified: Undo snapshots unrelated tasks

`_captureSnapshot` says it snapshots affected tasks, but it actually records
every task on every resolved source and destination date:

- `lib/features/ai_assistant/application/ai_action_executor.dart:312-359`

There is no task-id or title filter before each row is added. In addition,
`_resolveDate(null)` resolves to today:

- `lib/features/ai_assistant/application/ai_action_executor.dart:1287-1294`

This means:

- A memory, intention, context, or goal action can snapshot all of today’s tasks.
- An action for tomorrow can also snapshot today because its absent destination
  date resolves to today.
- Undo can revert unrelated task completions or edits made after the AI action.
- Undo can resurrect unrelated tasks deleted after the snapshot.
- Restored rows receive a fresh `updatedAtMs`, so the unintended reversion can
  win last-write-wins sync and propagate to other devices.

The inline Undo attached to memory/intention messages uses this same rollback
path. A user can therefore undo “remember this” and silently alter their
schedule.

### G4 — HIGH, newly identified: Rollback failures still report success

`_rollbackBatch` catches and suppresses restoration errors:

- `lib/features/ai_assistant/application/ai_action_executor.dart:366-412`

The intention and memory rollback helpers also suppress failures:

- `lib/features/ai_assistant/application/ai_action_executor.dart:418-470`

`_undoBatch` does not receive a success/failure result and returns `UndoSuccess`
after the swallowed failure:

- `lib/features/ai_assistant/application/ai_action_executor.dart:272-303`

Snapshot collection errors are also swallowed, allowing execution to continue
with an incomplete rollback record.

**Impact:** The UI can say “AI changes have been undone” after a partial or
completely failed rollback.

### G5 — HIGH: Task and goal creations cannot be undone

IDs are pre-assigned for intentions and memory facts, but not for task or goal
creations:

- `lib/features/ai_assistant/application/ai_action_executor.dart:147-172`
- `lib/features/ai_assistant/application/ai_action_executor.dart:853-1018`

Rollback restores existing task snapshots but never deletes tasks or goals
created by the batch.

**Impact:** Undo and partial-failure recovery claim restoration while created
tasks, goals, reminder configurations, time blocks, and notifications survive.

### G6 — HIGH: The Undo warning’s Cancel action is false

Rollback runs before `UndoWarningTasksCompleted` is returned:

- `lib/features/ai_assistant/application/ai_action_executor.dart:293-303`

The dialog is displayed only after the rollback:

- `lib/features/ai_assistant/presentation/ai_assistant_screen.dart:1706-1747`

Cancel cannot cancel anything. The user’s task completion may already have been
reverted and synced.

### G7 — HIGH: Undo availability is stale and inconsistent

Undo providers are cached `FutureProvider`s rather than Isar watch streams:

- `lib/features/ai_assistant/application/ai_assistant_providers.dart:157-184`

They are not invalidated after a plan completes. The main Undo entry point can
remain hidden until another lifecycle event occurs. The UI also permits only
`completed` batches, while the executor considers `partialFailure` undoable.

### G8 — HIGH: Failed or rolled-back execution still poisons history

`confirmPlan` calls `markConfirmed` and `markExecuted` regardless of
`result.hasFailures`:

- `lib/features/ai_assistant/application/ai_assistant_service.dart:752-767`

Both repository methods update every interaction in the session:

- `lib/features/ai_assistant/data/ai_interaction_history_repository.dart:91-117`

Consequences:

- A rolled-back plan is recorded as already applied.
- Earlier informational, declined, or clarification turns are marked executed.
- Future prompts receive “Already applied this session (do NOT repeat)” for
  actions that were declined, failed, or never happened.

### G9 — HIGH: Goal-behind-pace coaching fabricates progress

The proactive engine hardcodes goal progress to zero:

- `lib/features/ai_assistant/application/proactive_suggestion_engine.dart:285-313`
- `lib/features/ai_assistant/application/proactive_suggestion_engine.dart:428-437`

Elapsed time is therefore presented as the percentage the user is behind. A
fully on-track goal near its deadline can be accused of being approximately 90%
behind with confidence 0.80.

### G10 — HIGH: Closing Coach can move a late reply into a new session

Closing the sheet unconditionally starts a new session:

- `lib/features/ai_assistant/presentation/ai_assistant_screen.dart:105-113`

Pending chat and streamed replies do not capture or validate a session
generation before mutating state or saving history:

- `lib/features/ai_assistant/application/ai_assistant_service.dart:198-427`
- `lib/features/ai_assistant/application/ai_assistant_service.dart:511-528`

**Impact:** A late reply can become the first message of the next session,
persist under the wrong session id, restore a plan without its context, and
pollute memory extraction.

### G11 — HIGH: Voice STT callbacks belong to the first initializer

`SpeechToText` is a process singleton. Once initialization succeeds, later
`initialize()` calls return without replacing error/status listeners:

- `speech_to_text` 7.4.0, `speech_to_text.dart:160-214`
- `speech_to_text` 7.4.0, `speech_to_text.dart:307-326`

The app creates a fresh voice adapter for each Voice Mode entry:

- `lib/features/ai_assistant/application/voice_mode_adapters.dart:15-38`
- `lib/features/ai_assistant/presentation/ai_assistant_screen.dart:566-567`

The dictation button uses the same singleton.

**Impact:** After the first initializer, later sessions can miss listening,
done, and error callbacks. Connecting can remain stuck, silent listens can end
as false microphone-stall errors, and dictation’s listening indicator can fail
to reset.

### G12 — HIGH: AI backend authority and abuse boundaries are incomplete

The callable accepts client-provided system messages and tool definitions and
forwards them to OpenAI:

- `functions/src/index.ts:82-154`
- `functions/src/index.ts:412-459`

The quota counts requests rather than tokens. The server permits large payloads,
App Check is not enforced, and stream endpoints validate only Firebase bearer
tokens.

Evidence:

- `functions/src/index.ts:50-80`
- `functions/src/index.ts:313-380`
- `functions/src/index.ts:390-401`
- `functions/src/index.ts:580-632`

**Impact:** A modified registered client can use the app account as a
general-purpose OpenAI proxy and increase cost under the project key.

### G13 — HIGH, newly identified: Voice streaming bypasses the global AI kill switch

The normal agent client checks `ai_enabled` and switches to a mock. The streamed
voice route does not consult that client-side switch before calling
`aiChatStream`:

- `lib/features/ai_assistant/application/ai_assistant_service.dart:454-469`
- `lib/features/ai_assistant/application/voice_reply_stream.dart:21-96`

The per-purpose server route can independently disable the endpoint, but the
global incident switch is asymmetric.

**Impact:** Conversational Voice Mode can continue spending quota and calling
OpenAI while operators believe AI is globally disabled.

## Important medium-severity findings

### G14 — Failed chat turns have no retryable error state

`AiChatMessage` has no error status or original-input retry metadata. The
composer clears before the request. Network and quota failures are rendered as
ordinary assistant follow-up bubbles.

Evidence:

- `lib/features/ai_assistant/domain/models/ai_chat_message.dart`
- `lib/features/ai_assistant/presentation/ai_assistant_screen.dart:1019-1023`
- `lib/features/ai_assistant/application/ai_intent_parser.dart:184-198`

This does not satisfy the project’s optimistic-then-honest, per-item retry
principle.

### G15 — `confirmPlan` can leave the chat permanently loading

Execution and history writes are not inside `try/catch/finally`:

- `lib/features/ai_assistant/application/ai_assistant_service.dart:719-809`

An exception can leave `_isLoading` true and the confirmation card disabled.

### G16 — One unsupported action poisons a whole plan

`suggestFreeTimeBlock` and `moveConflictingTasks` are offered to the model but
throw during dispatch:

- `lib/features/ai_assistant/application/ai_action_executor.dart:641-646`

One such action causes an otherwise valid multi-action plan to enter rollback.
Per-action successes are then discarded.

### G17 — Confirm and send paths are re-entrant

Neither `confirmPlan` nor `sendMessage` has an in-flight guard. Two taps before a
rebuild, or an auto-send racing a manual send, can create duplicate batches,
interleave messages, and replace pending-plan state.

- `lib/features/ai_assistant/application/ai_assistant_service.dart:117-192`
- `lib/features/ai_assistant/application/ai_assistant_service.dart:719-754`

### G18 — Stream completion does not prove a complete answer

The server ignores `finish_reason`, writes `done:true` after any clean upstream
end, and emits no error record on an interrupted upstream stream:

- `functions/src/index.ts:715-748`

The Dart client also treats socket completion without `done:true` as success:

- `lib/features/ai_assistant/application/voice_reply_stream.dart:51-87`

Partial replies are spoken and persisted as complete.

### G19 — Voice lifecycle and interruption handling is absent

The voice path has no app lifecycle observer, audio interruption listener, or
becoming-noisy handling. Backgrounding, phone calls, or route changes can strand
the controller in listening/speaking and leave `SyncService.voiceModeActive`
enabled.

### G20 — User interruption can falsely degrade TTS for 60 seconds

Stopping primary streaming TTS closes the active client. The resulting exception
records a primary failure before checking whether the generation was cancelled:

- `lib/features/ai_assistant/application/voice_tts_resilience.dart:61-75`
- `lib/features/ai_assistant/application/voice_tts_resilience.dart:116-125`

The user’s intentional interruption can therefore put the preferred voice on
cooldown.

### G21 — Coach open can wait on Remote Config

The first provider resolution can await a Remote Config fetch for up to 10
seconds before the composer is available:

- `lib/core/ai/ai_remote_config_service.dart:26-49`
- `lib/features/ai_assistant/application/ai_assistant_providers.dart:45-49`

The error state displays a raw exception with no retry.

### G22 — Memory extraction can silently close a failed extraction

Malformed or truncated JSON parses as an empty extraction, after which the
session is still marked extracted:

- `lib/features/memory/application/memory_extraction_parser.dart:104-111`
- `lib/features/memory/application/memory_extraction_service.dart:208-211`

The original turns may later be purged even though no durable memory was saved.

### G23 — Chat memory writes overstate certainty

`rememberFact` stores model-paraphrased content as `userStated` at confidence
1.0 without the quote-verification used by the extraction pipeline:

- `lib/features/ai_assistant/application/ai_action_executor.dart:736-776`

The acknowledgement does not echo what was stored.

### G24 — Mentioning a person records a real interaction

Memory extraction calls `recordInteraction` merely because a person was
mentioned:

- `lib/features/memory/application/memory_extraction_service.dart:221-242`

This can suppress relationship-gap coaching and make the next prompt claim that
the user interacted with the person today.

### G25 — Foundational memories fall out of context

Memory injection takes the newest 20 facts. `lastReferencedAtMs` is written but
does not influence selection:

- `lib/features/ai_assistant/application/ai_payload_assembler.dart:168-210`

Important older facts can be displaced by recent low-value details.

### G26 — Circle pulse is not local-first and collapses failures

The pulse repository reads and writes Firestore directly:

- `lib/features/community/data/ai_pulse_repository.dart:18-65`

The registered `IsarAiPulseCache` is unused. Cooldown, empty input, AI failure,
parse failure, and save failure all become `null` and display the same “Nothing
new yet” message:

- `lib/features/community/application/circle_ai_pulse_service.dart:36-171`

The architecture guard misses this write because it only matches
`await FirebaseFirestore.instance`, not writes through an injected Firestore
field:

- `test/architecture/local_first_guard_test.dart:40-69`

### G27 — Circle content can inject or spoof AI pulse output

Member-authored event titles enter the prompt verbatim. Returned member ids and
display names are not validated against actual circle membership:

- `lib/features/community/application/circle_ai_pulse_service.dart:147-171`
- `lib/features/community/application/circle_ai_pulse_service.dart:176-231`

The resulting lines are shown to other circle members as attributed coaching.

### G28 — Proactive suggestions UI is unreachable

The only production Coach presentation is sheet mode, while the suggestions
panel, first-time card, and Coach help are gated behind non-sheet mode:

- `lib/features/ai_assistant/presentation/ai_assistant_screen.dart:243-244`
- `lib/features/ai_assistant/presentation/ai_assistant_screen.dart:903-916`

Three live entry points still advertise or request the suggestions panel: the
Coach FAB, Home morning brief, and push response.

### G29 — Home “Refresh coaching” does not initiate recomputation

The button invalidates recompute providers but does not read or watch their
futures:

- `lib/features/analytics/presentation/coaching_focus_card.dart:22-35`

The Progress test path explicitly invalidates and then reads the future, showing
the missing step:

- `lib/features/analytics/presentation/analytics_progress_screen.dart:200-215`

### G30 — Input and rendering lifecycle issues reduce chat usability

Confirmed UI problems include:

- Composer locked for the whole agent loop, up to four 20-second rounds.
- No stop action or typed-input queue.
- Forced scroll-to-bottom on every rebuild.
- Two thinking indicators during typed turns.
- Snackbars rendered behind the modal sheet.
- A downward fling irreversibly clears the visible thread.
- No timestamps, selectable message text, insertion animation, or adequate
  voice-orb accessibility semantics.

Primary evidence:

- `lib/features/ai_assistant/presentation/ai_assistant_screen.dart`
- `lib/features/ai_assistant/presentation/widgets/ai_input_card.dart`
- `lib/features/ai_assistant/presentation/widgets/chat_bubbles.dart`
- `lib/features/ai_assistant/presentation/widgets/voice_mode_card.dart`

## Server, quota, and cost findings

### Request-count quota can charge failed work

Quota enforcement runs concurrently with the OpenAI request. Upstream transport
failure, non-200 response, rate limiting, and empty responses do not refund the
charged turn:

- `functions/src/index.ts:477-546`
- `functions/src/index.ts:652-700`

Repeated outage retries can exhaust the user’s quota without delivering an
answer.

### Interleaved turns can be charged multiple times

The server stores one `lastTurnId`. Voice streaming calls the quota function
with no turn id, replacing that slot. A second device or a voice request during
an agent loop can make follow-up rounds look like new charged turns:

- `functions/src/index.ts:313-380`
- `functions/src/index.ts:643-655`

The in-memory over-quota marker is checked before the free-follow-up logic and
can reject follow-ups belonging to an already charged turn.

### Purpose values are not allow-listed

Arbitrary client purpose strings become permanent keys under
`aiUsage.byPurpose`:

- `functions/src/index.ts:252-280`
- `functions/src/index.ts:414-415`

Cycling purpose values can grow the shared document toward Firestore’s document
size limit.

### Error categories are indistinguishable

User quota, background-system budget, and upstream OpenAI rate limiting all map
to `resource-exhausted`. The client cannot distinguish a wait-until-reset
condition from an immediately retryable service failure.

### Main Coach temperature is not fully server-pinned

The primary Coach routes do not define a server temperature:

- `functions/src/ai_routing.ts:38-47`

The callable falls back to the client-provided value:

- `functions/src/index.ts:430-439`

This narrows the “server-pinned temperature” claim in §8.8.

## Corrections and refinements to `AUDIT.md` §8

### C1 — M10 is overstated

Actual AI summary generation passes coaching style into
`CoachingAiPayload.fromFocus`, which derives style-aware framing:

- `lib/features/analytics/domain/models/coaching_ai_payload.dart:317-353`

The real residual defects are:

- Cache TTL and preliminary summary type are computed before coaching style is
  read (`ai_summary_providers.dart:120-154`).
- The no-summary UI badge derives framing without style
  (`coaching_focus_card.dart:129-137`).

The generated prompt and response validator are style-aware. M10 should be
downgraded from a prompt-persona contradiction to a lower-severity cache/UI
inconsistency.

### C2 — The AI backend has four endpoints, not two

The active AI surfaces are:

- `aiChat`
- `aiChatStream`
- `aiSpeech`
- `aiSpeechStream`

The §8.0 orientation sentence mentioning two Cloud Functions is incomplete.

### C3 — Memory maintenance is partially wired

`MemoryExtractionService.runMaintenance()` is called during bootstrap. The
following maintenance remains unwired:

- interaction history `purgeBefore`
- summary `pruneOldSummaries`
- action batch `pruneOld`
- `IsarAiPulseCache`

The R9 wording should distinguish the wired extraction maintenance sweep from
these unused routines.

### C4 — Voice warmup has some value

Warmup does not preserve a reusable chat HTTP socket because it creates and
closes a separate client. It can still warm the Cloud Run instance and reduce
cold-start latency. The claim that it is completely void is too broad.

### C5 — H6 coaching-summary exposure is narrow

The production path that definitely executes `recomputeAiSummaryProvider` is
the Progress screen’s test button. Home refresh only invalidates the provider
and does not read it. The summary mock is therefore narrower than a general
kill-switch path, while the chat mock remains trust-critical.

### C6 — The circle challenge Start button does not auto-create AI text

The AI-provided challenge suggestion receives a Start button, but that button
opens an empty challenge-creation sheet. Prompt injection can still spoof pulse
content and attribution, but it does not directly execute the hostile challenge.

### C7 — Three live suggestions entry points, not four

The live callers are the FAB, Home morning brief, and notification response. A
fourth “See all suggestions” widget exists but is itself unreachable dead code.

## Verified strengths

The audit should not obscure the engineering that is already sound:

- Model selection is server controlled and restricted to an allow-list.
- Agent loops are bounded on both client and server.
- Tool-output repair and malformed-response handling are extensive.
- The confirm gate structurally protects ordinary schedule mutations in typed
  and voice paths.
- Unrequested-delete protection is real.
- Clarification carry-forward and local merge behavior are well tested.
- Intention and memory auto-commit actions now have pre-assigned ids and
  targeted inverse handling, although the shared task snapshot makes their Undo
  unsafe.
- Memory extraction retries transport failures rather than purging immediately.
- Reflection grounding, caps, re-fetch-before-write, and tombstone-aware dedupe
  are strong.
- Voice endpointing and generation-counter handling are carefully designed and
  have substantial unit coverage.
- Stream interruption closes the HTTP request and aborts upstream OpenAI work.
- Guest handling is honest and avoids sending anonymous users to paid AI
  endpoints.

## Test gaps

The most important missing tests are:

1. Every advertised action type must produce the expected Isar mutation.
2. `editTask` must preserve the original task id and untouched fields.
3. Undo of task/goal creation must delete the created entities and derivative
   reminder/time-block state.
4. Undo of a memory/intention action must not change any schedule task.
5. Rollback failure must return a failure result, never `UndoSuccess`.
6. Cancel on the completed-task warning must perform no rollback.
7. Confirming a failed/rolled-back batch must not mark session history executed.
8. Confirm double-tap must produce one batch.
9. Sheet close during parse/stream must not mutate the next session.
10. A second real `SpeechToText` session must receive fresh status/error
    callbacks; dictation and Voice Mode ownership must be tested together.
11. Voice lifecycle tests must cover backgrounding, calls, and audio-route
    changes.
12. Stream completion must require an explicit successful done marker and must
    reject token-limit truncation.
13. App Check, purpose allow-listing, turn-id interleaving, quota refunds, and
    upstream failure behavior need server integration tests.
14. Informational turns must not generate the pending-plan banner.
15. An on-track goal must never emit a fabricated behind-pace suggestion.
16. Malformed memory extraction must remain pending and block purge.
17. Circle pulse needs prompt-boundary, member-validation, offline-cache, and
    save-failure tests.
18. Home refresh must prove that focus and AI-summary recomputation actually
    executes.

## Recommended remediation order

### P0 — Stop incorrect claims and unsafe rollback

1. Remove every unimplemented verb from model tools, capability copy, preview
   cards, and directive chips until implemented.
2. Replace date-wide snapshots with an explicit inverse-operation log scoped to
   concrete entity ids.
3. Make rollback return a typed result and never suppress a failed restore.
4. Split undo into dry-run validation, user confirmation, then mutation.
5. Prevent failed or rolled-back plans from marking history executed.

### P1 — Restore execution and failure trust

1. Implement true edit/move/delete behavior with entity resolution before
   preview.
2. Add retryable message error state and preserve original input.
3. Guard `confirmPlan` with re-entrancy protection and `try/catch/finally`.
4. Report per-action outcomes rather than treating independent actions as one
   all-or-nothing unit.
5. Add a session generation guard to every post-await mutation and history save.
6. Replace fabricated goal progress with real check-in progress or remove the
   percentage claim.

### P2 — Stabilize live conversation

1. Use one process-wide STT adapter that routes callbacks to the active owner,
   or explicitly reassign the plugin’s public listeners before each listen.
2. Add app/audio lifecycle handling that returns Voice Mode safely to idle.
3. Do not record user cancellation as a TTS failure.
4. Reuse a session-lifetime HTTP client for warmup and streamed chat.
5. Require explicit stream completion and expose truncation/error state.
6. Apply the global AI kill switch consistently to streamed voice.

### P3 — Harden server boundaries

1. Own system prompts and permitted tools on the server.
2. Enforce App Check on callables and manually verify it on `onRequest`
   streaming endpoints.
3. Add token-aware daily cost limits.
4. Refund or compensate quota when upstream work fails before delivering a
   response.
5. Use a recent-turn registry instead of one `lastTurnId`.
6. Allow-list purpose values and return machine-readable error categories.

### P4 — Repair memory, secondary surfaces, and product UX

1. Mark only the specific interaction whose actions executed.
2. Treat malformed extraction as failure.
3. Rank foundational memory instead of newest-only selection.
4. Distinguish mentions from real person interactions.
5. Make circle pulse local-first and validate all member attribution.
6. Restore the suggestions/help experience inside the production sheet.
7. Make Home refresh execute the providers it claims to refresh.
8. Add cancellation, queueing, timestamps, selectable messages, accessible
   voice semantics, and in-sheet feedback.

## Final assessment

The model-facing and context-engineering layers are substantially better than
the execution layer. The product should not be described as a reliable
action-taking coach until:

1. every advertised mutation is real,
2. undo cannot alter unrelated data,
3. failures are visibly retryable,
4. session and voice lifecycle races are closed, and
5. the server owns the authority and cost boundaries.

Until then, the safest production posture is to expose only verified executable
verbs and present unsupported operations as advice rather than completed work.
