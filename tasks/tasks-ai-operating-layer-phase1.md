# Tasks — AI Operating Layer · Phase 1: Foundation

**PRD reference:** `tasks/prd-ai-operating-layer.md`  
**Goal:** Build the core end-to-end pipeline — Coach AI screen, text + voice input, intent parsing, missing-field detection, planned-changes preview, execution engine, interaction history, analytics.  
**Entry criteria:** PRD approved.  
**Exit criteria:** A user can type or speak a natural-language command, see a preview card, confirm it, and have the action applied to the app's data using existing services.

---

## Epic 1 — Domain Models & Data Layer

### Task 1.1 — Define `AiAction` model
- Create `lib/features/ai_assistant/domain/models/ai_action.dart`.
- Fields: `actionType` (String), `parameters` (Map\<String, dynamic\>), `confidence` (double 0–1).
- Add `ActionType` enum with V1 values:
  - `createTask`, `editTask`, `moveTask`, `deleteTask`
  - `createGoal`, `modifyGoal`, `deleteGoal`
  - `addReminder`, `removeReminder`, `rescheduleReminder`
  - `activateContextOverride`, `endContextOverride`
  - `suggestFreeTimeBlock`, `moveConflictingTasks`
- Add `riskLevel` getter (low / medium / high) derived from `actionType`.
- Add `fromJson` / `toJson`.
- Write unit tests for `riskLevel` getter and `fromJson`.

### Task 1.2 — Define `AiPlannedChanges` model
- Create `lib/features/ai_assistant/domain/models/ai_planned_changes.dart`.
- Fields: `actions` (List\<AiAction\>), `conflicts` (List\<String\>), `followUpQuestion` (String?), `sessionId` (String).
- Add `hasConflicts` getter.
- Add `requiresFollowUp` getter.

### Task 1.3 — Define `AiChatMessage` model
- Create `lib/features/ai_assistant/domain/models/ai_chat_message.dart`.
- Fields: `id`, `role` (enum: user / assistant / system), `content` (String), `timestamp` (DateTime), `plannedChanges` (AiPlannedChanges?).
- `plannedChanges` is non-null only for assistant messages that carry a preview card.

### Task 1.4 — Define `AiInteractionHistory` Isar collection
- Create `lib/features/ai_assistant/domain/models/ai_interaction_history.dart`.
- Fields: `id` (Isar auto-int), `sessionId` (String), `userInput` (String), `parsedActionsJson` (String — serialized), `confirmed` (bool), `executed` (bool), `timestamp` (DateTime).
- Annotate with `@Collection()`, `@Index` on `timestamp` for TTL purge query.
- Run `flutter pub run build_runner build` to generate `.g.dart` file.
- Register the collection in `lib/core/local_db/isar_collections/isar_schemas.dart`.

### Task 1.5 — Create `AiInteractionHistoryRepository`
- Create `lib/features/ai_assistant/data/ai_interaction_history_repository.dart`.
- Methods:
  - `Future<void> save(AiInteractionHistory entry)`
  - `Future<List<AiInteractionHistory>> getRecent({int limit = 10})` — ordered descending by timestamp.
  - `Future<void> purgeBefore(DateTime cutoff)` — deletes entries with `timestamp < cutoff`.
  - `Future<void> markConfirmed(String sessionId)`
  - `Future<void> markExecuted(String sessionId)`
- Inject `IsarDb` instance via constructor.
- Register provider `aiInteractionHistoryRepositoryProvider` in `lib/core/di/providers.dart`.

### Task 1.6 — Add TTL purge on app open
- In `AppBootstrap.initialize`, after existing startup tasks, call `aiInteractionHistoryRepositoryProvider.purgeBefore(DateTime.now().subtract(const Duration(hours: 48)))`.

---

## Epic 2 — AI Client & Intent Parser

### Task 2.1 — Create `AiOperatingLayerClient` interface + OpenAI implementation
- Create `lib/features/ai_assistant/application/ai_operating_layer_client.dart`.
- Abstract class `AiOperatingLayerClient`:
  - `Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload)`
  - `Future<String> askFollowUp(String sessionId, String userAnswer, AiOperatingLayerPayload payload)`
- Create `OpenAiOperatingLayerClient` implementing the interface:
  - Reuse `AiRemoteConfigService` for API key and model name (same pattern as `OpenAiCoachingClient`).
  - POST to OpenAI chat completions with `response_format: { type: "json_object" }`.
  - Temperature: 0.2 (lower than coaching client — determinism matters more here).
  - Max tokens: 800.
  - System prompt defines the `AiAction` JSON schema, action types, entity-normalisation rules, and V1 scope.
- Create `MockAiOperatingLayerClient` for tests.
- Register `aiOperatingLayerClientProvider` (FutureProvider, same pattern as `coachingAiClientProvider`).

### Task 2.2 — Define `AiOperatingLayerPayload`
- Create `lib/features/ai_assistant/domain/models/ai_operating_layer_payload.dart`.
- Fields (all human-readable strings / simplified objects — no raw IDs):
  - `userInput` (String)
  - `activeTasks` (List\<Map\<String, dynamic\>\>) — title, time, duration, status
  - `goals` (List\<Map\<String, dynamic\>\>) — title, target, deadline
  - `todaySchedule` (List\<Map\<String, dynamic\>\>) — time blocks summary
  - `focusState` (Map\<String, dynamic\>)
  - `contextOverride` (Map\<String, dynamic\>?)
  - `behaviorPreferences` (Map\<String, dynamic\>)
  - `sessionHistory` (List\<Map\<String, dynamic\>\>) — last ≤10 user↔AI exchanges
- Add `toJson()`.

### Task 2.3 — Create `AiPayloadAssembler`
- Create `lib/features/ai_assistant/application/ai_payload_assembler.dart`.
- Inject: `PlanningRepository`, `GoalsRepository`, `ContextOverrideRepository`, `CoachingStyleRepository`, `AiInteractionHistoryRepository`.
- Method `Future<AiOperatingLayerPayload> assemble(String userInput, String sessionId)`:
  - Reads today's tasks → map to simplified form (title, timeString, duration).
  - Reads active goals → map to simplified form.
  - Reads current context override → simplified form or null.
  - Reads coaching style preference.
  - Reads last 10 history entries for `sessionId` → `sessionHistory`.
  - Returns assembled payload.
- Register `aiPayloadAssemblerProvider`.

### Task 2.4 — Create `AiIntentParser`
- Create `lib/features/ai_assistant/application/ai_intent_parser.dart`.
- Inject: `AiOperatingLayerClient`, `AiPayloadAssembler`.
- Method `Future<AiPlannedChanges> parse(String userInput, String sessionId)`:
  1. Assemble payload via `AiPayloadAssembler.assemble`.
  2. Call `AiOperatingLayerClient.parseIntent(payload)`.
  3. Return `AiPlannedChanges`.
- Handle `Exception` → return `AiPlannedChanges` with a user-facing error message as `followUpQuestion`.
- Register `aiIntentParserProvider`.

---

## Epic 3 — Missing Field Detector

### Task 3.1 — Implement `AiMissingFieldDetector`
- Create `lib/features/ai_assistant/application/ai_missing_field_detector.dart`.
- Static method `MissingFieldResult check(AiAction action)`:
  - Returns `MissingFieldResult { bool isComplete, List<String> missingFields, String? questionToAsk }`.
  - Required fields per action type (from PRD §4.6):
    - createTask / editTask: title, time, duration.
    - createGoal: title, target, deadline.
    - moveTask: destinationDate (or destinationTime).
    - activateContextOverride: overrideType, duration.
    - deleteTask / deleteGoal / removeReminder: entityId or entityTitle.
  - `questionToAsk` is a human-readable single question (first missing field only — ask one at a time).
- Method `MissingFieldResult checkAll(List<AiAction> actions)`:
  - Iterates actions; returns first incomplete result, or complete if all pass.
- Unit tests: cover each action type with complete and incomplete parameter sets.

### Task 3.2 — Integrate missing-field check into the pipeline
- In `AiIntentParser.parse`, after receiving `AiPlannedChanges` from the client:
  - Run `AiMissingFieldDetector.checkAll(plannedChanges.actions)`.
  - If not complete, set `followUpQuestion` on `AiPlannedChanges` and return early (no conflict check yet).
  - If complete, continue to conflict check.

---

## Epic 4 — Execution Engine

### Task 4.1 — Implement `AiActionExecutor`
- Create `lib/features/ai_assistant/application/ai_action_executor.dart`.
- Inject all needed services/repositories:
  - `PlanningRepository`, `ReminderSyncService`, `TimeBlockSyncService`
  - `GoalsRepository`
  - `ReminderRepository`
  - `ContextOverrideService`
  - `Ref` (for provider invalidation)
- Method `Future<ExecutionResult> execute(List<AiAction> actions)`:
  - Dispatches each action to the correct service call per the routing table in PRD §4.10.
  - Collects successes and failures.
  - After all actions, calls `invalidateTaskListProviders(ref)` and any other affected provider invalidations.
  - Returns `ExecutionResult { List<String> successes, List<String> failures }`.
- Individual handlers (private methods or a `_dispatch` switch):
  - `_createTask(Map params)` → `planningRepository.ensureDefaultDayPlan` + `planningRepository.upsertTask` + `reminderSyncService` + `timeBlockSyncService.syncBlock`.
  - `_editTask(Map params)` → fetch existing task, merge params, upsert.
  - `_moveTask(Map params)` → update `planDateKey` + time, upsert.
  - `_deleteTask(Map params)` → `planningRepository.deleteTask` + `timeBlockSyncService.removeBlockForEntity`.
  - `_createGoal(Map params)` → `goalsRepository.createGoal`.
  - `_modifyGoal(Map params)` → `goalsRepository.updateGoal`.
  - `_deleteGoal(Map params)` → `goalsRepository.deleteGoal`.
  - `_addReminder(Map params)` → `reminderRepository.upsertReminder` + sync.
  - `_removeReminder(Map params)` → `reminderRepository.deleteReminder` + sync.
  - `_rescheduleReminder(Map params)` → update reminder time, upsert + sync.
  - `_activateContextOverride(Map params)` → `contextOverrideService.activateOverride`.
  - `_endContextOverride(Map params)` → `contextOverrideService.endOverride`.
  - `_suggestFreeTimeBlock` → call `timeBlockSyncService.checkConflicts`, return list (read-only; no write in V1).
- Register `aiActionExecutorProvider`.

### Task 4.2 — Conflict pre-check before preview
- In `AiIntentParser.parse` (after missing-field check passes):
  - For any action that involves scheduling (createTask, editTask, moveTask), extract proposed time + duration.
  - Call `TimeBlockSyncService.checkConflicts(proposedBlock)`.
  - Append conflict strings to `AiPlannedChanges.conflicts`.
  - Do NOT block execution — conflicts are warnings, not hard stops.

---

## Epic 5 — AI Assistant Service (Orchestrator)

### Task 5.1 — Implement `AiAssistantService`
- Create `lib/features/ai_assistant/application/ai_assistant_service.dart`.
- This is the single entry point for the presentation layer. It owns the in-memory session state.
- State it manages:
  - `sessionId` (UUID, generated at first interaction or app open).
  - `_messages` (List\<AiChatMessage\>) — the full conversation thread for the current session.
  - `_pendingPlan` (AiPlannedChanges?) — the last unconfirmed plan.
- Public methods:
  - `Future<void> sendMessage(String userInput)`:
    1. Append user `AiChatMessage` to `_messages`.
    2. Append a "thinking…" assistant message (loading state).
    3. Call `AiIntentParser.parse(userInput, sessionId)`.
    4. Replace loading message with result.
    5. If `followUpQuestion` is set → append assistant question message, set `_pendingPlan = null`.
    6. If plan is complete → set `_pendingPlan = plannedChanges`, append assistant preview message.
    7. Save to `AiInteractionHistoryRepository`.
    8. Log `aiCommandSubmitted` analytics event.
  - `Future<void> confirmPlan()`:
    1. Guard: `_pendingPlan` must not be null.
    2. Call `AiActionExecutor.execute(_pendingPlan!.actions)`.
    3. Append success/failure message to thread.
    4. Mark history entry as confirmed + executed.
    5. Set `_pendingPlan = null`.
    6. Log `aiCommandExecuted`.
  - `void cancelPlan()`:
    1. Set `_pendingPlan = null`.
    2. Append "Plan cancelled." assistant message.
    3. Log `aiCommandCanceled`.
  - `void editPlan()`:
    1. Keep `_pendingPlan` visible in chat (read-only card).
    2. Notify UI to focus the input field.
    3. Log nothing (user is refining).
  - `List<AiChatMessage> get messages` — read-only view.
  - `bool get hasPendingPlan` — `_pendingPlan != null`.

### Task 5.2 — Expose via Riverpod
- Create `lib/features/ai_assistant/application/ai_assistant_providers.dart`.
- `aiAssistantServiceProvider` — `StateNotifierProvider<AiAssistantNotifier, AiAssistantState>`.
- `AiAssistantState`:
  - `messages` (List\<AiChatMessage\>)
  - `isLoading` (bool)
  - `hasPendingPlan` (bool)
  - `inputFocusRequested` (bool) — UI listens to this to refocus the text field after "Edit Plan".
- `AiAssistantNotifier` wraps `AiAssistantService` and exposes `sendMessage`, `confirmPlan`, `cancelPlan`, `editPlan`.

---

## Epic 6 — Presentation Layer

### Task 6.1 — Add `/coach` route and Coach bottom nav tab
- In `lib/app/app.dart`:
  - Add `'/coach': (context) => const AiAssistantScreen()` to `routes`.
- In the bottom navigation widget (wherever bottom nav tabs are defined):
  - Add Coach tab between the existing tabs (position: 2nd, after Home and before Progress, matching the design screenshot).
  - Use an appropriate icon (e.g. `Icons.auto_awesome_outlined` or a custom SVG).
  - Active tint: `#eaffb8`; inactive: `#adaaaa`.
- In `HomeScreen`: add a glassmorphism FAB (bottom-right) that calls `Navigator.pushNamed(context, '/coach')`.
  - FAB style: `surface-variant` (#262626) at 60% opacity, `backdrop-filter` blur (use `BackdropFilter` + `ClipRRect` in Flutter), `primary` icon.

### Task 6.2 — Build `AiAssistantScreen` scaffold
- Create `lib/features/ai_assistant/presentation/ai_assistant_screen.dart`.
- Layout (top → bottom):
  1. Custom AppBar: title "Coach AI" (left, Headline-SM style), "• READY" status pill (right).
  2. Scrollable conversation thread (fills remaining space, reverse: false, scroll-to-bottom on new message).
  3. Fixed bottom area: input card + Quick Directives row.
- Background: `#0e0e0e`.
- No dividers anywhere — tonal separation only.
- Consume `aiAssistantServiceProvider`; listen to `isLoading` for send-button state.
- Listen to `inputFocusRequested` to call `FocusScope.of(context).requestFocus(_inputFocusNode)`.

### Task 6.3 — Build `AiInputCard` widget
- Create `lib/features/ai_assistant/presentation/widgets/ai_input_card.dart`.
- Container style: `surface-container-highest` (#262626), radius 24, padding 16.
- Contains:
  - `TextField` (multiline, max 4 lines, `#adaaaa` hint text, no border, `secondary` cursor color).
  - Row at the bottom of the card:
    - Left: `VoiceInputButton` (mic icon, see Task 6.4).
    - Right: "SEND ▶" pill button (`#befc00` background, `#445d00` text, disabled when empty or loading).
- On send: call `ref.read(aiAssistantServiceProvider.notifier).sendMessage(controller.text)` then `controller.clear()`.
- On voice result: populate `controller.text` with recognised string.

### Task 6.4 — Build `VoiceInputButton` widget
- Create `lib/features/ai_assistant/presentation/widgets/voice_input_button.dart`.
- Uses `speech_to_text` Flutter package (add to `pubspec.yaml`).
- States: idle (mic icon, `#adaaaa`), listening (animated waveform bars, `#00e3fd`), processing (spinner).
- Waveform: 4–5 vertical bars with staggered `AnimationController` opacity/height pulses.
- On recognition complete: calls `onResult(String text)` callback.
- On error: shows a `SnackBar` with a brief message.
- Handle platform permission (microphone) request on first use.

### Task 6.5 — Build `QuickDirectivesRow` widget
- Create `lib/features/ai_assistant/presentation/widgets/quick_directives_row.dart`.
- A horizontal `SingleChildScrollView` of ghost-style chip buttons.
- V1 chips: "Add task", "Create goal", "Move schedule".
- Tapping a chip calls `onSelected(String startingText)` callback to pre-fill the input.
- Style: `outline-variant` border at 20% opacity, `on-surface-variant` text, radius full.

### Task 6.6 — Build `SuggestedPromptsSection` widget
- Create `lib/features/ai_assistant/presentation/widgets/suggested_prompts_section.dart`.
- Section label "SUGGESTED PROMPTS" (Label-SM style, all-caps, `#adaaaa`).
- Two hard-coded V1 example prompts (dynamic prompts come in Phase 2):
  - "Add a workout at 5AM"
  - "Move my study session tomorrow"
- Each prompt is a `surface-container-high` card with an arrow-out icon (right), scale animation on tap.
- Tapping calls `onSelected(String prompt)` callback.
- Hide section when conversation thread has messages (screen transitions to pure chat mode).

### Task 6.7 — Build conversation thread widgets

#### Task 6.7a — `UserMessageBubble`
- Right-aligned bubble, `surface-container-highest` (#262626) background, white text, radius 16 (top-right 4).
- Shows `message.content`.

#### Task 6.7b — `AssistantMessageBubble`
- Left-aligned, no background (text directly on `#0e0e0e`), `on-surface-variant` text.
- Shows `message.content`.

#### Task 6.7c — `LoadingIndicator` (thinking state)
- Three pulsing dots in `secondary` (#00e3fd). Shown while `isLoading == true`.

#### Task 6.7d — Message list builder
- In `AiAssistantScreen`, `ListView.builder` over `messages`.
- For each message: render `UserMessageBubble`, `AssistantMessageBubble`, or `PlannedChangesCard` (when `message.plannedChanges != null`).
- Auto-scroll to bottom on new message using `ScrollController`.

### Task 6.8 — Build `PlannedChangesCard` widget
- Create `lib/features/ai_assistant/presentation/widgets/planned_changes_card.dart`.
- Container style: `surface-container-low` (#131313), radius 16, padding 16.
- Section label "PLANNED CHANGES PREVIEW" (Label-SM, all-caps, `#adaaaa`).
- Action list:
  - For each `AiAction` render a row with:
    - Prefix icon + label:
      - `+` green (`#b2ed00`) for create actions.
      - `−` red for delete actions.
      - Pencil `#adaaaa` for edit/move.
      - Shield/clock `#00e3fd` for context overrides.
    - Human-readable description derived from `action.actionType` + `action.parameters` (e.g. "Add Morning Workout (5:00 AM)").
- Conflict warnings section (if `plannedChanges.hasConflicts`):
  - Each conflict as its own row: amber background (30% opacity), warning icon, conflict text in amber.
- High-risk warning (if any action `riskLevel == high`):
  - Red-tinted info box: "This will permanently delete X item(s)."
- Action buttons (bottom, only shown if `isCurrentPlan == true`):
  - **CONFIRM CHANGES** — full-width `#befc00` pill → calls `confirmPlan()`.
  - **EDIT PLAN** (left ghost) → calls `editPlan()`.
  - **CANCEL** (right ghost, red label) → calls `cancelPlan()`.
- Past plans (already confirmed or cancelled) show buttons in a disabled/faded state with a "Executed" or "Cancelled" label instead.

---

## Epic 7 — Analytics

### Task 7.1 — Log AI analytics events
- In `AiAssistantService` methods, call `fireAndForgetAnalyticsEvent` (from existing analytics infra):
  - `sendMessage` → `aiCommandSubmitted { sessionId, inputLength }`.
  - `confirmPlan` → `aiCommandExecuted { sessionId, actionCount, actionTypes }`.
  - `cancelPlan` → `aiCommandCanceled { sessionId }`.
  - Follow-up question path → `aiFollowupQuestionAsked { sessionId, missingFields }`.
- In `PlannedChangesCard`, when confirm is tapped after an assumption was pre-filled → `aiSuggestionAccepted`.
- When user edits a pre-filled value → `aiSuggestionRejected` (Phase 2; stub the call now).

---

## Epic 8 — Infrastructure & Wiring

### Task 8.1 — Add `speech_to_text` dependency
- Add `speech_to_text: ^6.x.x` (latest stable) to `pubspec.yaml`.
- Run `flutter pub get`.
- Add microphone permission entries:
  - `ios/Runner/Info.plist`: `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`.
  - `android/app/src/main/AndroidManifest.xml`: `RECORD_AUDIO` permission.

### Task 8.2 — Register all new providers
- In `lib/core/di/providers.dart`, add:
  - `aiInteractionHistoryRepositoryProvider`
- In `lib/features/ai_assistant/application/ai_assistant_providers.dart`, expose:
  - `aiOperatingLayerClientProvider`
  - `aiPayloadAssemblerProvider`
  - `aiIntentParserProvider`
  - `aiActionExecutorProvider`
  - `aiAssistantServiceProvider` / `AiAssistantNotifier`

### Task 8.3 — Register Isar collection
- Add `IsarAiInteractionHistorySchema` to the `isar_schemas.dart` collection list.
- Confirm `build_runner` generates the `.g.dart` file without errors.

### Task 8.4 — Feature flag (optional safety net)
- Add a `aiAssistantEnabled` boolean to `AiRemoteConfigService` (default `true`).
- In `AiAssistantScreen` init, check flag; if false, show a "Coming soon" placeholder instead of the full UI.
- This lets the team disable the feature remotely without a hotfix.

---

## Epic 9 — Testing

### Task 9.1 — Unit tests: domain models
- `AiAction.riskLevel` getter for all action types.
- `AiPlannedChanges.hasConflicts` / `requiresFollowUp`.
- `AiMissingFieldDetector.check` for each action type (complete + missing cases).

### Task 9.2 — Unit tests: `AiPayloadAssembler`
- Mock repos; assert payload fields are correctly populated.
- Assert no raw IDs appear in the serialised payload.

### Task 9.3 — Unit tests: `AiActionExecutor`
- Mock all services.
- For each action type: assert the correct service method is called with correct arguments.
- Assert `invalidateTaskListProviders` is called after task mutations.

### Task 9.4 — Widget test: `PlannedChangesCard`
- Renders action rows with correct prefix icons.
- Renders conflict warning section when `hasConflicts == true`.
- Renders high-risk warning when an action has `riskLevel == high`.
- Confirm / Edit / Cancel buttons call the correct callbacks.

### Task 9.5 — Integration smoke test
- Pump `AiAssistantScreen` with a mock `AiAssistantNotifier`.
- Simulate typing text + tapping Send.
- Assert loading indicator appears, then a `PlannedChangesCard`.
- Simulate tapping Confirm — assert `confirmPlan` was called.

---

## Acceptance Criteria

- [ ] User can open Coach AI from the bottom nav tab and the Home FAB.
- [ ] User can type a command, see a loading state, then a Planned Changes card.
- [ ] If a required field is missing, the AI asks one follow-up question before showing the plan.
- [ ] The preview card lists all planned actions with correct icons and colours per the design.
- [ ] Conflict warnings appear in the preview card if time overlaps are detected.
- [ ] Tapping Confirm executes all actions via the correct existing services (no direct DB writes).
- [ ] Tapping Cancel discards the plan with no side effects.
- [ ] Tapping Edit Plan re-focuses the input field.
- [ ] Voice input fills the text field; sending it follows the same pipeline.
- [ ] All 6 analytics events fire at the correct moments.
- [ ] Interaction history is persisted and entries older than 48 hours are purged on next open.
- [ ] UI matches the Obsidian Pulse design system (colours, typography, no dividers).
