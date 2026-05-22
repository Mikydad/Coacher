# Tasks — AI Operating Layer · Phase 2: Smart Suggestions

**PRD reference:** `tasks/prd-ai-operating-layer.md`  
**Depends on:** Phase 1 complete and merged.  
**Goal:** Make the AI feel intelligent by reusing the user's own history. When a user says "schedule a workout", the system looks at past workout tasks, infers time/duration/mode with ≥80% confidence, pre-fills the plan, and shows a reason label — no need to ask every time.

---

## Epic 1 — Entity Normalisation

### Task 1.1 — Create `EntityNormaliser`
- Create `lib/features/ai_assistant/application/entity_normaliser.dart`.
- Responsibility: map raw user-provided entity names to canonical category keys.
- Implement a hardcoded V2 dictionary as a starting point:
  ```
  fitness    → workout, gym, exercise, run, push day, pull day, leg day, cardio, swim, bike
  study      → study, reading, review, homework, revision, research, learn
  work       → meeting, standup, sync, call, interview, presentation, deep work
  sleep      → sleep, nap, rest, bedtime
  meal       → breakfast, lunch, dinner, meal prep, cook
  mindfulness → meditation, yoga, breathwork, journaling
  ```
- Method `String normalise(String rawEntity)`:
  - Lowercase + strip punctuation.
  - Check dictionary; return category key if matched.
  - If no match, return the raw entity lowercased (pass-through).
- Method `double similarityScore(String rawEntity, String candidateTitle)`:
  - Used by the Assumption Engine to score history matches.
  - Combine: exact category match (1.0), same category (0.9), partial string match (0.7), no match (0.0).
- Unit tests: cover each category, edge cases (mixed case, partial match, unknown entity).

### Task 1.2 — Persist entity normalisation decisions
- Add `resolvedCategory` (String?) field to `AiInteractionHistory` Isar model.
- When `AiAssistantService.sendMessage` successfully executes a plan, store `resolvedCategory` for the primary action's entity.
- This seeds the history for the Assumption Engine to query.

---

## Epic 2 — Assumption Engine

### Task 2.1 — Define `AssumptionResult` model
- Create `lib/features/ai_assistant/domain/models/assumption_result.dart`.
- Fields:
  - `confidence` (double)
  - `suggestedParameters` (Map\<String, dynamic\>) — pre-filled values.
  - `reasonLabel` (String) — human-readable explanation shown under the action in the preview card.
  - `source` (enum: taskHistory / goalHistory / noMatch).

### Task 2.2 — Implement `AiAssumptionEngine`
- Create `lib/features/ai_assistant/application/ai_assumption_engine.dart`.
- Inject: `PlanningRepository`, `GoalsRepository`, `AiInteractionHistoryRepository`, `EntityNormaliser`.
- Core method `Future<AssumptionResult> infer(AiAction incompleteAction)`:

  **Step 1 — Normalise entity**
  - Extract entity name from `incompleteAction.parameters['title']`.
  - Call `EntityNormaliser.normalise(entityName)` → `category`.

  **Step 2 — Search task history**
  - Query `PlanningRepository` for the most recent completed/confirmed task where the title normalises to the same `category`.
  - Limit: last 30 days.

  **Step 3 — Score confidence**
  - Exact category match + task completed successfully → 0.95.
  - Category match + task exists but not completed → 0.80.
  - Partial string match only → 0.65.
  - No match → 0.0.

  **Step 4 — Reuse configuration if confidence ≥ 0.80**
  - Reusable fields: `time` (from task `startTime`), `duration`, `reminderOffset`, `modeRefId` (enforcement mode), `category`.
  - Copy only fields that are still `null` in `incompleteAction.parameters` — never overwrite user-provided values.
  - Set `reasonLabel` to: *"Based on your latest [category] setup"* (e.g. "Based on your latest fitness setup").

  **Step 5 — Fall through**
  - If confidence < 0.80, return `AssumptionResult` with `source: noMatch` and empty `suggestedParameters`.
  - Caller (Missing Field Detector / Intent Parser) will ask a follow-up question instead.

- Additional method `Future<List<AssumptionResult>> inferAll(List<AiAction> actions)`:
  - Runs `infer` in parallel for all actions.
  - Returns one result per action (preserves order).

### Task 2.3 — Register `aiAssumptionEngineProvider`
- Add to `lib/features/ai_assistant/application/ai_assistant_providers.dart`.

### Task 2.4 — Integrate Assumption Engine into the parse pipeline
- In `AiIntentParser.parse`, after the initial OpenAI call:
  1. Run `AiMissingFieldDetector.checkAll(actions)`.
  2. For each incomplete action, call `AiAssumptionEngine.infer(action)`.
  3. If `assumptionResult.confidence >= 0.80`:
     - Merge `suggestedParameters` into `action.parameters` (only null fields).
     - Attach `reasonLabel` to the action (add `reasonLabel` field to `AiAction` or carry it in `AiPlannedChanges`).
     - Re-run `AiMissingFieldDetector.check(action)` — if now complete, no follow-up needed.
  4. If still incomplete after inference → post follow-up question (existing Phase 1 behaviour).
- Update unit tests for `AiIntentParser` to cover the assumption path.

---

## Epic 3 — Reason Label in Preview Card

### Task 3.1 — Add `reasonLabel` to `AiAction`
- Add nullable `reasonLabel` (String?) field to `AiAction`.
- Update `fromJson` / `toJson`.

### Task 3.2 — Render reason label in `PlannedChangesCard`
- In `PlannedChangesCard` action row widget:
  - If `action.reasonLabel != null`, render it as a small subtitle below the action description.
  - Style: `Label-SM` (0.6875rem equivalent), `on-surface-variant` (#adaaaa), italic.
  - Example: *"Based on your latest fitness setup"*.

### Task 3.3 — Analytics for suggestions
- In `AiAssistantService.confirmPlan`: for each action with a non-null `reasonLabel`, log `aiSuggestionAccepted { category, confidence }`.
- In `AiAssistantService.editPlan` (user edits after seeing suggestion): check if any pending action had a `reasonLabel`; if so, log `aiSuggestionRejected { category }`.

---

## Epic 4 — Dynamic Quick Directives

### Task 4.1 — Compute usage-based Quick Directives
- Create `lib/features/ai_assistant/application/quick_directives_provider.dart`.
- `quickDirectivesProvider` (FutureProvider\<List\<QuickDirective\>\>):
  - Reads last 30 days of `AiInteractionHistory`.
  - Counts `actionType` occurrences.
  - Returns top 3 most-used action types mapped to human-readable chip labels:
    - `createTask` → "Add task"
    - `createGoal` → "Create goal"
    - `moveTask` → "Move schedule"
    - `activateContextOverride` → "Focus mode"
    - `deleteTask` → "Remove task"
  - If fewer than 5 history entries exist, fall back to the V1 static list.
- `QuickDirective` model: `{ label: String, startingText: String }`.

### Task 4.2 — Update `QuickDirectivesRow` to consume dynamic provider
- Replace the hardcoded list with `ref.watch(quickDirectivesProvider)`.
- Show a loading shimmer while the provider is loading.
- If the provider errors, silently fall back to the static list.

---

## Epic 5 — Dynamic Suggested Prompts

### Task 5.1 — Compute contextual Suggested Prompts
- Create `lib/features/ai_assistant/application/suggested_prompts_provider.dart`.
- `suggestedPromptsProvider` (FutureProvider\<List\<String\>\>):
  - Reads today's tasks (`todayAllTasksRowsProvider`) and active goals.
  - Generates context-specific prompts:
    - If user has a recurring fitness task → *"Schedule your workout for tomorrow"*.
    - If user has an unscheduled goal → *"Set time for [goal title]"*.
    - If user has overdue tasks → *"Move overdue tasks to today"*.
    - Generic fallbacks: *"Add a workout at 5AM"*, *"Move my study session tomorrow"*.
  - Cap at 3 prompts.

### Task 5.2 — Update `SuggestedPromptsSection` to consume dynamic provider
- Replace hardcoded list with `ref.watch(suggestedPromptsProvider)`.
- Loading shimmer while fetching.
- Error → static fallback.

---

## Epic 6 — History-Enriched Payload

### Task 6.1 — Add entity patterns to `AiOperatingLayerPayload`
- Add `recentPatterns` field (List\<Map\<String, dynamic\>\>) to `AiOperatingLayerPayload`.
- Each entry: `{ category, lastUsedTime, lastUsedDuration, frequency }`.
- Populated in `AiPayloadAssembler.assemble` using a new private method `_buildRecentPatterns()`:
  - Groups last 14 days of task history by normalised category.
  - For each category: most recent time, average duration, count.
  - Limit to top 5 categories by frequency.
- This allows the OpenAI model to understand the user's schedule rhythm even before the Assumption Engine runs.

### Task 6.2 — Update `AiPayloadAssembler` unit tests
- Add tests for `_buildRecentPatterns` with mocked task history.
- Assert output is human-readable (no IDs) and capped at 5.

---

## Epic 7 — Testing

### Task 7.1 — Unit tests: `EntityNormaliser`
- All dictionary entries match correctly.
- Unknown entity passes through as lowercase.
- `similarityScore` returns correct ranges.

### Task 7.2 — Unit tests: `AiAssumptionEngine`
- Mock `PlanningRepository` returning a recent task with known time/duration.
- Assert confidence ≥ 0.80 and `suggestedParameters` contains correct values.
- Assert `reasonLabel` is set correctly.
- Assert confidence < 0.80 when no matching history exists.
- Assert user-provided values are never overwritten.

### Task 7.3 — Unit tests: `AiIntentParser` assumption integration
- Simulate incomplete action (missing time) + matching history → assert time is pre-filled, no follow-up question.
- Simulate incomplete action + no history → assert follow-up question is returned.

### Task 7.4 — Widget test: reason label rendering
- `PlannedChangesCard` renders reason label when `action.reasonLabel != null`.
- Label is absent when `reasonLabel == null`.

### Task 7.5 — Provider tests: `quickDirectivesProvider` and `suggestedPromptsProvider`
- With sufficient history → dynamic output.
- With < 5 entries → static fallback.

---

## Acceptance Criteria

- [ ] When user says "schedule workout", system finds last workout task and pre-fills time + duration with confidence ≥ 80%.
- [ ] Pre-filled values show a reason label ("Based on your latest fitness setup") in the preview card.
- [ ] If no matching history exists, system asks a follow-up question instead of guessing.
- [ ] User-provided values are never overwritten by the Assumption Engine.
- [ ] Quick Directives chips reflect the user's most-used action types after sufficient history.
- [ ] Suggested Prompts are context-specific (based on today's tasks and active goals).
- [ ] `aiSuggestionAccepted` and `aiSuggestionRejected` events fire correctly.
- [ ] `recentPatterns` in the AI payload includes top 5 categories with time/duration data.
