# PRD — AI Operating Layer (Coach AI)

**Feature name:** AI Operating Layer  
**Status:** Draft  
**Last updated:** 2026-05-22

---

## 1. Introduction / Overview

Users of the app currently interact with productivity features — tasks, goals, reminders, context overrides, scheduling, time blocks — through a series of manual screens. Each action requires navigation: open screen, fill fields, save. As the app grows this friction compounds.

The **AI Operating Layer** introduces a natural-language interface called **Coach AI**. Users type or speak what they want and the AI translates their intent into structured, preview-able, confirmable app actions. The assistant never writes directly to the database — it always generates a plan first, shows the user a preview, and executes only after explicit confirmation.

**Core principle:**

```
Understand → Validate → Preview → Confirm → Execute
```

The feature lives on a dedicated **Coach tab** in the bottom navigation bar and is also accessible via a **FAB on the Home screen**.

---

## 2. Goals

1. Allow users to create, move, delete, and manage tasks, goals, reminders, and context overrides using natural language (text + voice).
2. Eliminate multi-screen navigation for common scheduling intents.
3. Surface all planned changes in a clear preview card before any data is modified.
4. Reuse confirmed patterns from the user's history to pre-fill suggestions with high confidence.
5. Integrate conflict detection (time overlap, reminder collision, context conflicts) into every action before confirmation.
6. Persist a short interaction history (48-hour rolling window) for debugging and future learning.
7. Track AI command analytics (submitted, executed, cancelled, follow-up questions, suggestions accepted/rejected).

---

## 3. User Stories

- As a user, I want to type "Add a workout at 5AM tomorrow" and have the app create the task without manually filling in every field, so I can stay focused.
- As a user, I want to speak a multi-step command ("Create a meeting at 9AM and silence the app after") and see all planned changes at once before they apply, so I know exactly what will change.
- As a user, I want the AI to suggest the same time and duration I used last time for a similar task, so I don't have to repeat myself.
- As a user, I want to be asked a follow-up question only when the AI genuinely cannot infer a required value, so interactions stay fast.
- As a user, I want to see a clear conflict warning ("Workout overlaps with Commute") inside the preview card, so I can choose to edit or confirm anyway.
- As a user, I want to cancel or edit a plan before it executes, so I never feel locked in.
- As a user, I want to tap a "Quick Directive" chip (Add task, Create goal, Move schedule) to start a common action without typing.
- As a user, I want the AI to remember what I said earlier in a session, so I can refine requests naturally.

---

## 4. Functional Requirements

### 4.1 Entry Points

1. The app **must** add a **Coach tab** to the bottom navigation bar. The tab icon uses the existing app icon style with an "AI pulse" indicator when the coach is ready.
2. The Home screen **must** display a **FAB** (floating action button) that opens the Coach AI screen directly, following the glassmorphism style in the design system.

### 4.2 AI Chat Screen (UI)

3. The Coach AI screen **must** display the heading **"Coach AI"** with a `• READY` status pill in `secondary` (#00e3fd).
4. The screen **must** contain a large multi-line text input field (styled per the design system: `surface-container-highest`, `xl` radius) with placeholder text like *"Plan a workout tomorrow…"*.
5. The input area **must** include:
   - a **voice microphone button** (bottom-left) that activates speech-to-text when tapped;
   - a **SEND button** (bottom-right, `primary-container` pill style) to submit.
6. Below the input the screen **must** show a **Quick Directives** row of chip buttons: *Add task*, *Create goal*, *Move schedule*. Tapping a chip pre-fills the input with a starting prompt.
7. Below the directives the screen **must** show a **Suggested Prompts** section with 2–3 contextual example prompts (e.g., *"Add a workout at 5AM"*, *"Move my study session tomorrow"*). Tapping a prompt fills the input.
8. The screen **must** display a **conversation thread** above the input field, showing the user's messages and the AI's responses (questions, status, and plan previews) in chronological order.
9. All colours, typography, and component styles **must** follow the "Obsidian Pulse" design system defined in `PRD/AI_Assistance/AI_coach_page_design/DESIGN.md` (deep-space black backgrounds, kinetic green `#eaffb8` / `#b2ed00` accents, electric blue `#00e3fd`, no 1px dividers, glassmorphism modals, Inter font).

### 4.3 Voice Input

10. When the microphone button is tapped, the app **must** activate the device speech-to-text engine and display an animated voice waveform (visualised in `secondary` blue) inside the input area while listening.
11. Recognised speech **must** be inserted as text into the input field; the user can edit before sending.
12. Voice and text input **must** share the same backend parsing pipeline.

### 4.4 Intent Parser

13. When the user submits input, the system **must** send it to an **Intent Parser** that calls the existing `CoachingAiClient` infrastructure (or a dedicated sibling client) via OpenAI, producing a structured list of one or more `AiAction` objects:
   ```
   AiAction {
     actionType: String,    // e.g. "createTask", "deleteTask", "activateContextOverride"
     parameters: Map<String, dynamic>,
     confidence: double,    // 0.0–1.0
   }
   ```
14. A single user message **may** contain multiple intents; the parser **must** return all of them as an ordered list.
15. The parser **must never** invent entity values from pure AI reasoning. Values must either come from the user's explicit input or from the Assumption Engine (§4.5).

### 4.5 Assumption Engine (Smart Suggestions)

16. Before presenting a preview, the system **must** check the user's task/goal history for a recent matching entity (normalised by category, e.g. "Push day" → "fitness").
17. If a match with confidence ≥ 80% is found, the system **must** pre-fill the missing fields with the latest confirmed configuration (time, duration, reminder settings, enforcement mode) and display a reason label: *"Based on your latest workout setup"*.
18. If no confident match exists and a required field is missing, the system **must** ask a targeted follow-up question inside the chat thread (e.g., *"What time is the meeting?"*).
19. Required fields per action type:
   - **Task / Meeting:** title, time, duration.
   - **Goal:** title, target, deadline.
   - **Move tasks:** destination date/time.
   - **Context override:** type (focus / sleep / DND / meeting), duration.

### 4.6 Missing Field Detector

20. After parsing, the system **must** scan every `AiAction` for required fields with null values.
21. If critical fields are missing and cannot be inferred at ≥ 80% confidence, the system **must** pause the pipeline and post a follow-up question to the user in the chat thread.
22. The system **must** wait for the user's clarifying answer before continuing to conflict detection and preview generation.
23. Ambiguous intents (e.g., *"Move tomorrow tasks"* with no destination) **must** trigger a clarification question (*"Move to when?"*) rather than making an assumption.

### 4.7 Conflict Engine Integration

24. Before generating a preview, the system **must** run every scheduling action through the existing `TimeBlockSyncService.checkConflicts` / `ConflictDetectionEngine`.
25. The following conflict types **must** be detected:
   - Time overlap between two scheduled items.
   - Reminder collision (two reminders within 3 minutes).
   - Context conflict (task scheduled during an active sleep/DND override).
26. Detected conflicts **must** appear in the preview card with a warning label styled in amber/orange per the design: *"⚠ CONFLICT: Workout overlaps with Commute"*.

### 4.8 Planned Changes Preview Card

27. After all intents are resolved and conflicts checked, the system **must** render a **Planned Changes Preview** card inside the chat thread (not a separate screen).
28. The preview card **must** list every planned action with icons:
   - `+` (green) for additions.
   - `−` (red) for deletions.
   - Pencil for modifications.
   - Shield/clock for context overrides.
29. Conflict warnings **must** appear below the action list inside the same card, styled with an amber background and warning icon.
30. The preview card **must** contain three action buttons at the bottom:
   - **CONFIRM CHANGES** (primary, full-width pill) — executes all approved actions.
   - **EDIT PLAN** (secondary ghost) — returns focus to the input field so the user can refine.
   - **CANCEL** (secondary ghost, red label) — discards the plan with no changes applied.

### 4.9 Risk Levels & Confirmation Rules

31. In V1, **all actions** (regardless of risk level) require explicit confirmation via the preview card before execution.
32. Risk classification (for analytics and future auto-approval):
   - **Low:** create task, enable focus mode, add reminder.
   - **Medium:** move tasks, modify schedule, change reminders.
   - **High:** delete tasks, remove goals, bulk actions.
33. High-risk bulk deletions **must** display a secondary warning inside the preview card listing each item to be deleted.

### 4.10 Execution Engine

34. On confirmation, the system **must** route each `AiAction` to the appropriate existing service, never to Firestore or Isar directly:
   | Action type | Service |
   |-------------|---------|
   | createTask / editTask / moveTask / deleteTask | `PlanningRepository.upsertTask` / `.deleteTask` + `ReminderSyncService` + `TimeBlockSyncService` |
   | createGoal / modifyGoal / deleteGoal | `GoalsRepository` via `goalsRepositoryProvider` |
   | addReminder / removeReminder / rescheduleReminder | `ReminderRepository` + `ReminderSyncService.syncForTaskIds` |
   | activateContextOverride / endContextOverride | `ContextOverrideService.activateOverride` / `.endOverride` |
   | suggestFreeTimeBlock / moveConflictingTasks | `TimeBlockSyncService` + `ConflictDetectionEngine` |
35. After execution the system **must** invalidate the affected Riverpod providers (e.g. `invalidateTaskListProviders`) so the rest of the UI reflects changes immediately.
36. A success/failure status **must** be posted as a new message in the chat thread (e.g., *"Done! Workout added for tomorrow at 6:00 AM."*).

### 4.11 Interaction History

37. Every user interaction **must** be persisted to a local `AiInteractionHistory` Isar collection with the following fields:
   ```
   AiInteractionHistory {
     id: String,
     userInput: String,
     parsedActions: List<AiAction>,
     confirmed: bool,
     executed: bool,
     timestamp: DateTime,
   }
   ```
38. History entries older than **48 hours** **must** be automatically purged.
39. The most recent session history (up to 10 exchanges) **must** be included in the prompt context sent to the AI model to enable follow-up refinements within a session.

### 4.12 AI Prompt Payload

40. The payload sent to the AI **must** include human-readable context only — no raw Firestore IDs, no internal object references:
   ```json
   {
     "userInput": "...",
     "activeTasks": [],
     "goals": [],
     "todaySchedule": [],
     "focusState": {},
     "contextOverride": {},
     "behaviorPreferences": {},
     "recentPatterns": [],
     "sessionHistory": []
   }
   ```
41. The `sessionHistory` field **must** carry up to the last 10 user↔AI exchanges from the current session.

### 4.13 Analytics

42. The system **must** log the following analytics events using the existing `fireAndForgetAnalyticsEvent` / `AnalyticsRepository`:
   - `aiCommandSubmitted` — user sends input.
   - `aiCommandExecuted` — confirmation tapped and services called.
   - `aiCommandCanceled` — cancel tapped after preview.
   - `aiFollowupQuestionAsked` — missing field detected.
   - `aiSuggestionAccepted` — assumed value confirmed.
   - `aiSuggestionRejected` — user edits an assumed value.

---

## 5. Non-Goals (Out of Scope — V1)

- Direct execution without confirmation (no auto-approve even for low-risk actions in V1).
- Autonomous AI behaviour (the AI never acts without user approval).
- Long-term conversational memory beyond 48 hours.
- External integrations (calendar sync, email parsing).
- Self-modifying or self-optimising schedules.
- AI-generated goals or routines without user input.
- Multi-user or circle-level AI commands.
- Deleting data automatically without preview and confirmation.

---

## 6. Design Considerations

### Screen Layout (from design reference)

The Coach AI screen follows the "Obsidian Pulse" system:

- **Background:** `#0e0e0e` (surface).
- **Input card:** `#1a1a1a` card with `xl` rounded corners; electric-blue cursor; waveform animation during voice.
- **Quick Directive chips:** ghost style pills (`outline-variant` border at 20%).
- **Suggested Prompts:** `surface-container-high` (#201f1f) cards with an arrow-out icon, subtle scale on tap.
- **Planned Changes card:** `surface-container-low` (#131313) background; action rows with coloured `+`/`−` prefixes; amber conflict banner (separate row, 30% opacity amber background).
- **CONFIRM CHANGES button:** full-width `primary-container` (`#befc00`) pill.
- **EDIT PLAN / CANCEL:** ghost secondary buttons side-by-side below confirm.
- **"• READY" pill:** `secondary` (#00e3fd) dot + label, top-right of header.

### Bottom Navigation

- New **Coach** tab uses an icon that aligns with the existing bottom nav style.
- Active state: `primary` (#eaffb8) tint; inactive: `on-surface-variant` (#adaaaa).

### Voice Waveform

- Animated bars in `secondary` blue, centred in the input area during listening.
- Disappears and text populates the field when recognition completes.

---

## 7. Technical Considerations

### Architecture

- Add a new feature module: `lib/features/ai_assistant/`.
- Sub-structure follows existing feature conventions:
  ```
  ai_assistant/
    application/
      ai_intent_parser.dart
      ai_assumption_engine.dart
      ai_missing_field_detector.dart
      ai_action_executor.dart
      ai_assistant_providers.dart
    data/
      ai_interaction_history_repository.dart
    domain/
      models/
        ai_action.dart
        ai_interaction_history.dart
        ai_planned_changes.dart
    presentation/
      ai_assistant_screen.dart
      widgets/
        planned_changes_card.dart
        quick_directives_row.dart
        suggested_prompts_section.dart
        voice_input_button.dart
  ```

### AI Client

- Reuse `CoachingAiClient` infrastructure (`OpenAiCoachingClient`) with a dedicated prompt template for the operating layer.
- Wrap in a new `AiOperatingLayerClient` that targets the same API key / model from `AiRemoteConfigService`.
- Response format: `json_object` mode, returning an array of `AiAction` objects.
- Consider a dedicated system prompt that defines the action schema and entity-normalisation rules.

### Riverpod Integration

- Add `aiAssistantServiceProvider` in `lib/features/ai_assistant/application/ai_assistant_providers.dart`.
- Register the `AiInteractionHistoryRepository` (Isar-backed) in `providers.dart` alongside existing infra repos.
- Expose `aiSessionHistoryProvider` (stream of last 10 interactions) for prompt payload assembly.

### Isar Collection

- Add `Isar_AiInteractionHistory` collection with TTL purge triggered on app open (similar to existing cache purge patterns).

### Navigation

- Add `/coach` named route in `app.dart`.
- Bottom nav Coach tab navigates to `/coach`.
- Home FAB navigates to `/coach` using `appNavigatorKey` (consistent with notification-tap navigation pattern).

### Conflict Detection

- Reuse `ConflictDetectionEngine` and `TimeBlockSyncService.checkConflicts` synchronously (before preview render) to avoid a separate async round-trip during confirmation.

---

## 8. Implementation Phases

### Phase 1 — Foundation
Build:
- Coach AI screen (UI per design).
- Bottom nav Coach tab + Home FAB entry point.
- Text input + voice speech-to-text.
- Intent Parser (OpenAI call, `AiAction` model).
- Missing Field Detector + follow-up question flow.
- Planned Changes Preview card (in-chat).
- Execution Engine routing to existing services.
- Basic `AiInteractionHistory` persistence (48h TTL).
- Analytics events.

### Phase 2 — Smart Suggestions
Build:
- Assumption Engine (entity normalisation, history matching, ≥80% confidence pre-fill).
- Task/goal history integration for context-aware suggestions.
- "Based on your latest X setup" reason labels.
- Quick Directives and Suggested Prompts populated dynamically from usage patterns.

### Phase 3 — Context Awareness
Build:
- Full Conflict Engine integration (time overlap, reminder collision, context conflicts).
- Behaviour pattern integration (coaching style, enforcement mode awareness).
- Focus state integration (don't suggest tasks during active focus/sleep windows).
- Session history in prompt payload.

### Phase 4 — Proactive AI
Build:
- Proactive suggestions (AI surfaces scheduling opportunities without being asked).
- Schedule optimisation recommendations.
- Predictive action cards on Home screen ("You usually add a workout — want to schedule one?").

### Phase 5 — Conversational Intelligence
Build:
- **Read path:** Informational answers for today/tomorrow/week schedule and goal progress (Schema C).
- **Suggest path:** Collaborative planning with "Apply this plan" before preview (Schema E).
- **Intent routing:** Query vs suggest vs mutate classification with router guardrails.
- **Capability registry:** Honest unsupported boundaries for community, billing, account, sync.
- **Conversation memory:** All turn types persisted for multi-turn context.
- **Proactive bridge:** Home suggestion cards auto-open Coach with session context.
- **Week overview payload:** 7-day task counts for week-level questions.
- **Safety:** Informational output guard — no raw IDs or internal field names in user-facing text.

---

## 9. Success Metrics

- **Task creation via AI** accounts for ≥ 30% of all task creations within 30 days of launch.
- **Confirmation rate** (preview → confirm, not cancel) ≥ 60%.
- **Follow-up question rate** (missing field detector triggered) ≤ 25% of commands (decreasing as assumption engine improves).
- **AI command executed** events grow week-over-week during first month.
- **Suggestion accepted rate** ≥ 50% in Phase 2 (assumption engine evaluated).
- No increase in support tickets related to accidental data deletion (zero-tolerance on the "no direct execute" rule).

---

## 10. Open Questions

1. **Voice provider:** Should speech-to-text use the native platform (iOS `SFSpeechRecognizer` / Android `SpeechRecognizer`) or a third-party SDK (e.g. OpenAI Whisper)? Native is free; Whisper may have higher accuracy.
2. **AI model selection:** Will the operating layer share the same model/API key as the coaching summary client, or use a separate key/model (e.g. GPT-4o-mini for lower latency and cost)?
3. **Offline behaviour:** What should the UI show when there is no network? Options: (a) disable the send button with a notice, (b) queue the request and process when reconnected.
4. **Rate limiting / cost control:** Should there be a daily cap on AI calls per user? If so, what is the limit and what message should be shown when exceeded?
5. **Entity normalisation dictionary:** Where does the category mapping live (e.g. "Push day" → "fitness")? Hardcoded list, AI-determined, or user-configurable?
6. **Multi-language support:** Is Phase 1 English-only, or must it support additional locales?
7. **Goal CRUD scope:** Creating goals via AI requires a `target` and `deadline`. Should the AI present a structured form or attempt to infer these from natural language?
8. **EDIT PLAN flow:** When the user taps "Edit Plan", should the preview card remain visible (read-only) while the input accepts changes, or should the card collapse?
