# Tasks — AI Conversational Intelligence (Read · Suggest · Act)

**Goal:** Evolve Coach AI from a mutation-only “order taker” into a planning partner that can **answer questions**, **suggest plans**, and **execute changes** — with honest limits when data or features are unavailable.

**Depends on:** AI Operating Layer Phases 1–3 (already largely in codebase).  
**PRD references:** `tasks/prd-ai-operating-layer.md`, `PRD/AI_ Assistance/ai_ assistance.md`

---

## 0. Current state (codebase audit)

### What works today

| Layer | File(s) | Behavior |
|-------|---------|----------|
| Entry + session | `ai_assistant_service.dart` | `sendMessage` → parse → 3 outcomes only |
| Parse pipeline | `ai_intent_parser.dart` | assemble → LLM → assumptions → dedupe → conflicts |
| Context payload | `ai_payload_assembler.dart` | **Today** tasks/schedule, goals (5), patterns (14d), focus, prefs |
| LLM contract | `ai_operating_layer_client.dart` | Schema A (`actions[]`) or Schema B (`followUpQuestion`) only |
| Execute | `ai_action_executor.dart` | Confirm → mutate via coordinator |
| Proactive (Home/Coach) | `proactive_suggestion_engine.dart` | Rule-based cards → pre-fill input only |
| History | `ai_interaction_history_repository.dart` | Saves user input + actions; `assistantSummary` only after **execute** |

### Gaps (why “What’s the plan for tomorrow?” fails)

1. **No informational response type** — empty `actions` → `"I couldn't build a plan from that"` (`ai_assistant_service.dart` L128–136).
2. **Prompt is mutation-only** — system prompt (`ai_operating_layer_client.dart` L40–118) never allows a plain answer.
3. **Tomorrow not in payload** — `AiOperatingLayerPayload` has `activeTasks` / `todaySchedule` only; no `tomorrowSchedule` or date-scoped fetch.
4. **Goal progress not in payload** — goals show title/target/deadline, not check-ins or pace.
5. **No capability boundary** — model can hallucinate features (circles, billing, etc.) with no registry.
6. **Informational turns not persisted** — `saveAssistantSummary` runs only after `confirmPlan`; Q&A turns don’t feed `conversationHistory`.

### Existing assets to reuse

- `collectTasksForDateKey()` — already used in payload assembler for patterns (`ai_payload_assembler.dart` L237).
- `ProactiveSuggestionEngine` — gap/recurring/goal-behind rules; can feed **suggest** mode.
- `ScheduleOptimisationService` — order/gap logic for proactive cards.
- `GoalsRepository.getCheckInsForGoal()` — for goal progress answers.
- `GoalPeriodHelpers` — period summaries for goals.

---

## 1. Target architecture

### Response modes (single LLM call, explicit `responseType`)

```
User message
     ↓
AiPayloadAssembler (+ date-scoped data)
     ↓
AiOperatingLayerClient (extended JSON schema)
     ↓
AiPlannedChanges (extended)
     ↓
AiAssistantService branch:
  · informational  → text bubble (+ optional suggestion chips)
  · suggest        → text bubble + optional preview card (user confirms)
  · mutate         → existing preview → confirm → execute
  · unsupported    → fixed “coming later” message (capability registry)
```

### Core principle (unchanged for mutations)

```
Understand → Validate → Preview → Confirm → Execute   (mutate only)
Understand → Read data → Answer                      (informational)
Understand → Read data → Propose → Preview → Confirm (suggest)
```

---

## 2. Implementation phases

### Phase A — Informational responses (MVP: “read my schedule”)

**Outcome:** Questions like “What’s my plan for tomorrow?” get a text answer, not an error.

#### A.1 Domain model

- [ ] **A.1.1** Add `AiResponseType` enum: `informational`, `suggest`, `mutate`, `unsupported`.
- [ ] **A.1.2** Extend `AiPlannedChanges`:
  - `responseType` (default `mutate` for backwards compat)
  - `informationalMessage` (String?)
  - `suggestedPrompts` (List<String>?) — tappable chips that pre-fill input
  - `unsupportedReason` (String?) — when capability missing
- [ ] **A.1.3** Update `copyWith`, equality helpers, and any serialization tests.

#### A.2 LLM contract

- [ ] **A.2.1** Extend `_kSystemPrompt` with Schema C (informational) and Schema D (unsupported):
  ```json
  { "responseType": "informational", "message": "...", "suggestedPrompts": ["..."] }
  { "responseType": "unsupported", "message": "I can't access X yet — coming later." }
  ```
- [ ] **A.2.2** Update `_parseResponse` in `ai_operating_layer_client.dart` to parse `responseType` + `message`.
- [ ] **A.2.3** Keep Schema A/B working: if `responseType` absent and `actions` non-empty → `mutate`; if `followUpQuestion` → follow-up (unchanged).

#### A.3 Service + UI

- [ ] **A.3.1** `AiAssistantService.sendMessage`: branch on `responseType`:
  - `informational` → assistant bubble with `informationalMessage`; no preview card
  - `unsupported` → assistant bubble with registry-safe message
  - `mutate` → existing preview flow
  - empty actions + no message → improved fallback (see A.3.4)
- [ ] **A.3.2** Persist informational `message` via new `historyRepository.saveAssistantSummary` call on **every** assistant turn (not only execute).
- [ ] **A.3.3** Optional UI: render `suggestedPrompts` as chips under the bubble (reuse `SuggestedPromptsSection` pattern).
- [ ] **A.3.4** Replace generic “couldn’t build a plan” with mode-aware copy when parser returns empty mutate with no follow-up.

#### A.4 Tests

- [ ] **A.4.1** Unit: `_parseResponse` for each schema (mock JSON fixtures).
- [ ] **A.4.2** Unit: `AiAssistantService` with fake parser — informational path shows text, no `hasPendingPlan`.
- [ ] **A.4.3** Widget: assistant bubble renders informational content.

**Acceptance criteria**

- “What’s on my schedule today?” returns a text summary when `todaySchedule` is non-empty.
- No Confirm/Cancel card for pure informational replies.
- Assistant answer appears in next turn’s `conversationHistory`.

---

### Phase B — Richer read payload (tomorrow + goals + week)

**Outcome:** AI answers are grounded in real data, not guesses.

#### B.1 Extend payload model

- [ ] **B.1.1** Add to `AiOperatingLayerPayload`:
  - `tomorrowSchedule` — same shape as `todaySchedule`
  - `tomorrowTasks` — same shape as `activeTasks`
  - `weekOverview` — optional `{ date, taskCount, scheduledCount }[]` for next 7 days
  - `goalProgress` — `{ title, target, progress, periodSummary }[]`
  - `capabilities` — list of supported read/mutate scopes (see Phase D)
- [ ] **B.1.2** Update `toJson()` and `_buildUserPrompt()` to include new sections.

#### B.2 Payload assembler builders

- [ ] **B.2.1** `_buildTomorrowSchedule()` / `_buildTomorrowTasks()` using `DateKeys.tomorrowKey()` + `collectTasksForDateKey`.
- [ ] **B.2.2** `_buildWeekOverview()` — lightweight counts per day (7 parallel fetches, best-effort).
- [ ] **B.2.3** `_buildGoalProgress()` — active goals + `getCheckInsForGoal` + `GoalPeriodHelpers.daysElapsedInPeriodThrough` / `countMetCheckIns`.
- [ ] **B.2.4** Date-aware assembly (optional optimization): regex/keyword detect “tomorrow”, “next week” in `userInput` to skip unused builders later; **Phase B v1 can always include tomorrow** (cheap enough).

#### B.3 Prompt instructions

- [ ] **B.3.1** System prompt: for informational queries, **summarize only from payload fields**; if section empty, say so explicitly (“Nothing scheduled for tomorrow yet.”).
- [ ] **B.3.2** Add example few-shot in prompt for tomorrow/today/goal progress answer format.

#### B.4 Tests

- [ ] **B.4.1** Unit: payload assembler with mocked `PlanningRepository` — tomorrow section populated.
- [ ] **B.4.2** Unit: goal progress builder with mock check-ins.
- [ ] **B.4.3** Integration-style: fake client returns informational; end-to-end message contains task titles from fixture data.

**Acceptance criteria**

- “What’s the plan for tomorrow?” lists tomorrow’s tasks or states empty schedule.
- “How am I doing on [goal]?” uses check-in data when available.

---

### Phase C — Intent routing (query vs suggest vs mutate)

**Outcome:** Less misfire; “Plan my tomorrow” proposes, “Add gym at 6” mutates.

#### C.1 Router (hybrid: rules + model)

- [ ] **C.1.1** Add `AiIntentRouter` with fast path:
  - **Query keywords:** what, show, tell, how many, when, list, plan for (without imperatives)
  - **Mutate keywords:** add, create, delete, move, schedule, enable, remove, set
  - **Suggest keywords:** plan, help me, suggest, recommend, optimize, fill
- [ ] **C.1.2** Router output: `AiIntentKind` + optional `focusDate` (today/tomorrow/week).
- [ ] **C.1.3** Pass `intentHint` into payload + system prompt (“user intent is QUERY; do not return actions unless they explicitly ask to change something”).

#### C.2 Suggest mode

- [ ] **C.2.1** Schema E — suggest:
  ```json
  {
    "responseType": "suggest",
    "message": "Tomorrow morning is free. I'd add study at 9 and workout at 6.",
    "actions": [ ... optional draft actions ... ]
  }
  ```
- [ ] **C.2.2** UI: show message + **“Apply this plan”** button that opens existing preview card (reuse `PlannedChangesCard`).
- [ ] **C.2.3** User can edit via normal Edit flow before confirm.

#### C.3 Parser pipeline guardrails

- [ ] **C.3.1** If router says QUERY and model returns `actions` only → coerce to informational using payload (server-side formatter fallback).
- [ ] **C.3.2** If router says MUTATE and model returns informational only → one retry with stricter prompt OR ask clarifying follow-up.

#### C.4 Tests

- [ ] **C.4.1** Unit: router classification table (20+ utterances).
- [ ] **C.4.2** Unit: suggest mode renders preview after “Apply”.

**Acceptance criteria**

- Query utterances never show Confirm card unless user asked to apply changes.
- “Help me plan tomorrow” shows narrative + optional one-tap plan.

---

### Phase D — Capability registry (“I can’t do that yet”)

**Outcome:** Trustworthy boundaries; no hallucinated features.

#### D.1 Registry

- [ ] **D.1.1** Create `ai_capability_registry.dart`:
  - **Read:** today schedule, tomorrow schedule, goals summary, goal progress, focus state, patterns
  - **Mutate:** tasks, goals, reminders, context overrides (maps to existing `ActionType`s)
  - **Unsupported (v1):** community/circles, billing, account settings, other users’ data, cross-device sync status
- [ ] **D.1.2** Inject `capabilities` into every payload.
- [ ] **D.1.3** System prompt rule: if request needs unsupported capability → Schema D only; never invent.

#### D.2 Fallback messages

- [ ] **D.2.1** Templated copy per unsupported domain:
  - “Community features aren’t available in Coach AI yet — coming later.”
  - “I can’t change account or subscription settings from here.”
- [ ] **D.2.2** Optional: link chip to relevant screen (“Open Circles in app”) without executing.

#### D.3 Tests

- [ ] **D.3.1** Unit: registry lists match prompt injection.
- [ ] **D.3.2** Fixture: “What did my circle post?” → unsupported response.

---

### Phase E — Conversation memory for all turn types

**Outcome:** Multi-turn works: “Move the first one to 8am” after a schedule summary.

#### E.1 History persistence

- [ ] **E.1.1** On every assistant turn, call `saveAssistantSummary` with:
  - informational message, OR
  - follow-up question, OR
  - “Plan preview: …” summary, OR
  - execution summary (existing)
- [ ] **E.1.2** Store `responseType` on `IsarAiInteractionHistory` (optional field) for analytics.
- [ ] **E.1.3** Ensure `buildConversationHistory` includes informational assistant turns (already supported if summary saved).

#### E.2 Context window hygiene

- [ ] **E.2.1** Cap conversationHistory at 10 turns (existing).
- [ ] **E.2.2** For long informational answers, truncate stored summary to ~500 chars with ellipsis.

#### E.3 Tests

- [ ] **E.3.1** Repository: save + reload conversation with informational summary.
- [ ] **E.3.2** Parser receives prior informational turn in `conversationHistory`.

---

### Phase F — Proactive + conversational merge

**Outcome:** Proactive engine and chat share one “plan with user” story.

#### F.1 Bridge proactive → chat

- [ ] **F.1.1** When user taps proactive card, pre-fill input (existing) **and** pass `proactiveSuggestionId` into session context.
- [ ] **F.1.2** Optional: proactive tap sends auto-message “Help me with: [suggestion]” to trigger suggest mode.

#### F.2 Chat-native suggestions

- [ ] **F.2.1** After informational answer with gaps (empty tomorrow AM), call `ProactiveSuggestionEngine.generateForToday()` server-side and attach top 1–2 as `suggestedPrompts`.
- [ ] **F.2.2** Deduplicate against dismissed types (`DismissedSuggestionRepository`).

#### F.3 Suggested prompts expansion

- [ ] **F.3.1** Update `suggested_prompts_provider.dart` with read-style prompts:
  - “What’s my plan for tomorrow?”
  - “How am I doing on my goals this week?”
- [ ] **F.3.2** Keep action prompts for balance.

#### F.4 Analytics

- [ ] **F.4.1** Events: `aiInformationalAnswer`, `aiSuggestPlanShown`, `aiSuggestPlanApplied`, `aiUnsupportedRequest`.
- [ ] **F.4.2** Extend `proactive_suggestion_analytics_summary` with chat conversion.

---

### Phase G — Polish & hardening

#### G.1 UX copy

- [x] **G.1.1** Coach screen placeholder: “Ask about your schedule or tell me what to plan…”
- [x] **G.1.2** Empty-state examples mixing read + write.

#### G.2 Performance

- [x] **G.2.1** Parallel payload builders (already mostly parallel); add tomorrow to existing `Future.wait`.
- [x] **G.2.2** Consider caching today/tomorrow payload for 30s within a session to reduce Isar reads.

#### G.3 Safety

- [x] **G.3.1** Informational answers must not include raw IDs or internal field names (PRD §4.12 — already a rule; add test).
- [x] **G.3.2** Mutate path unchanged: still requires Confirm for all writes.

#### G.4 Documentation

- [x] **G.4.1** Update `tasks/prd-ai-operating-layer.md` §Phases with “Phase 5 — Conversational Intelligence”.
- [x] **G.4.2** Add developer note in `ai_operating_layer_client.dart` documenting all response schemas.

---

## 3. Recommended delivery order

| Sprint | Phases | Shippable increment |
|--------|--------|---------------------|
| **S1** | A + B (tomorrow only) | Tomorrow/today Q&A works |
| **S2** | E + D | Multi-turn + honest limits |
| **S3** | C (suggest mode) | “Plan with me” + Apply plan |
| **S4** | B (goals/week) + F | Smarter suggestions + proactive bridge |
| **S5** | G | Polish, analytics, docs |

**Minimum lovable product after S1+S2:** User can ask about today/tomorrow and get real answers; unsupported requests fail gracefully; follow-up turns remember context.

---

## 4. Files to touch (by phase)

| Phase | Primary files |
|-------|----------------|
| A | `ai_planned_changes.dart`, `ai_operating_layer_client.dart`, `ai_assistant_service.dart`, `ai_assistant_screen.dart`, `chat_bubbles.dart` |
| B | `ai_operating_layer_payload.dart`, `ai_payload_assembler.dart`, `ai_operating_layer_client.dart` |
| C | `ai_intent_router.dart` (new), `ai_intent_parser.dart`, `planned_changes_card.dart` |
| D | `ai_capability_registry.dart` (new), `ai_payload_assembler.dart`, `ai_operating_layer_client.dart` |
| E | `ai_interaction_history_repository.dart`, `isar_ai_interaction_history.dart`, `ai_assistant_service.dart` |
| F | `proactive_suggestion_engine.dart`, `suggested_prompts_provider.dart`, `proactive_suggestion_card.dart` |
| G | `ai_assistant_screen.dart`, PRD/tasks docs |

---

## 5. Test plan summary

| Area | New tests |
|------|-----------|
| JSON parsing | `ai_operating_layer_client_test.dart` (new) — all response schemas |
| Payload | `ai_payload_assembler_test.dart` (new) — tomorrow + goal progress |
| Router | `ai_intent_router_test.dart` (new) |
| Service | `ai_assistant_service_test.dart` (new) — informational / suggest / mutate branches |
| Regression | Existing `ai_intent_parser_assumption_test.dart`, `ai_plan_deduplicator_test.dart` must pass |

---

## 6. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Model returns actions for queries | Router hint + server-side coercion + empty-action fallback formatter |
| Token cost ↑ (more payload) | Start with tomorrow only; lazy-load week/goals progress |
| Hallucinated schedule | Prompt: “only cite payload sections”; unit tests with empty payload |
| Breaking existing mutate flow | Default `responseType: mutate`; Schema A/B unchanged |
| Stale conversation after edits | Invalidate payload on confirm; timestamp in session |

---

## 7. Open product decisions (resolve before S3)

1. **Suggest mode:** Should draft actions auto-open preview, or require “Apply this plan” tap? *(Recommend: require tap.)*
2. **Goal progress:** Show numeric progress only, or also coaching tone from `coachingStyle`? *(Recommend: both.)*
3. **Week view:** Summary counts vs full task list in prompt? *(Recommend: counts + tomorrow detail; full week on request.)*
4. **Offline:** Informational reads work offline (Isar); LLM call still needs network — reuse existing offline send-button behavior?

---

## 8. Success metrics

- **Informational success rate:** ≥ 80% of schedule/goal questions get non-error text (no “couldn’t build a plan”).
- **Mutation regression:** Confirm rate for write commands unchanged (±5%).
- **Suggest conversion:** ≥ 30% of suggest-mode plans tapped “Apply”.
- **Unsupported accuracy:** Zero user reports of AI claiming to change unsupported domains.
