# Tasks — AI Operating Layer · Phase 3: Context Awareness

**PRD reference:** `tasks/prd-ai-operating-layer.md`  
**Depends on:** Phase 1 and Phase 2 complete and merged.  
**Goal:** Make the AI aware of the user's current state — active context overrides, focus modes, sleep windows, coaching style, enforcement mode, and reminder collisions — so that every suggested plan respects the user's live environment, not just their history.

---

## Epic 1 — Full Conflict Engine Integration

### Task 1.1 — Extend `AiActionExecutor` conflict pre-check
- Currently (Phase 1) the conflict check only detects time-block overlaps.
- Extend `AiIntentParser._checkConflicts(actions)` to also detect:

  **1a — Reminder collision**
  - For any action that creates or reschedules a reminder, check if an existing `ReminderConfig` fires within 3 minutes of the proposed reminder time.
  - Source: query `ReminderRepository.getRemindersForDate(proposedDate)`.
  - If collision detected, add to `AiPlannedChanges.conflicts`:
    *"Reminder for [task A] fires at [time], only X minutes before this reminder."*

  **1b — Context conflict**
  - For any action that schedules a task/event, check whether the proposed time falls inside an active or scheduled `ContextOverride` (sleep, DND, vacation).
  - Source: read `effectiveOverrideProvider` current state + `UserAttentionState.sleepWindowStart/End`.
  - If conflict detected, add to `AiPlannedChanges.conflicts`:
    *"[Task] is scheduled during your sleep window (11 PM – 7 AM)."*
    *"[Task] overlaps with your active Focus mode (10:00–12:00)."*

  **1c — Enforcement mode conflict**
  - If a `moveTask` action would move a task that has `strictModeRequired == true` (disciplined/extreme mode) to a time outside the allowed schedule window, add a warning:
    *"[Task] uses Extreme mode — moving it may require a typed CONFIRM override."*

### Task 1.2 — Surface new conflict types in `PlannedChangesCard`
- Reminder collision: amber row, bell-slash icon.
- Context conflict (sleep/DND): amber row, moon icon.
- Context conflict (focus): amber row, eye-slash icon.
- Enforcement mode warning: amber row, lock icon.
- All styled identically to Phase 1 conflict rows — `amber` background at 30% opacity, warning icon, text.

### Task 1.3 — Unit tests: extended conflict detection
- Reminder collision: mock two reminders 2 minutes apart → conflict detected.
- Sleep window conflict: task at 2 AM when sleep window is 11 PM–7 AM → conflict detected.
- Focus overlap: task at 10:30 AM when focus override active 10–12 → conflict detected.
- No conflicts when clear → no conflict strings returned.

---

## Epic 2 — Coaching Style & Enforcement Mode Awareness

### Task 2.1 — Include coaching style in the AI payload
- In `AiPayloadAssembler.assemble`, read `activeCoachingStyleProvider` (already available in `providers.dart`).
- Add `coachingStyle` field to `AiOperatingLayerPayload`:
  ```
  "coachingStyle": "disciplined"   // supportive | balanced | disciplined | intense
  ```
- The system prompt must instruct the model to:
  - Use firmer, more direct language for `disciplined` / `intense`.
  - Use encouraging, supportive language for `supportive` / `balanced`.

### Task 2.2 — Include default enforcement mode in the payload
- In `AiPayloadAssembler.assemble`, read `ProfilePreferenceService.getDefaultEnforcementMode()`.
- Add `defaultEnforcementMode` field to `AiOperatingLayerPayload`:
  ```
  "defaultEnforcementMode": "disciplined"   // flexible | disciplined | extreme
  ```
- When the executor creates a task and no `modeRefId` is in `action.parameters`, default to this value.

### Task 2.3 — Apply enforcement mode to task creation
- In `AiActionExecutor._createTask`:
  - If `parameters['modeRefId']` is null, read `defaultEnforcementModeProvider` and set `modeRefId` accordingly.
  - This ensures AI-created tasks obey the user's default mode, not the app default `flexible`.

---

## Epic 3 — Focus State Integration

### Task 3.1 — Block scheduling during active focus/sleep overrides
- In `AiPlannedChanges`, add a new field `blockedByContext` (List\<String\>) — separate from soft conflicts.
- In the conflict pre-check (Task 1.1b):
  - If the proposed action is `createTask` / `editTask` / `moveTask` AND the entire proposed duration falls inside an active `ContextOverride` of type `sleep` or `doNotDisturb`:
    - Move the conflict string to `blockedByContext` (hard warning, not just advisory).
- In `PlannedChangesCard`:
  - `blockedByContext` rows use a **red** background (30% opacity) instead of amber.
  - Show label: *"⛔ Blocked: [Task] falls inside your active DND window."*
  - The CONFIRM CHANGES button becomes **"Confirm Anyway"** (still callable — user has final say) with red tint.
  - Add small disclaimer: *"This task will be created but reminders may be suppressed."*

### Task 3.2 — Add `focusState` to payload
- In `AiPayloadAssembler.assemble`, read `effectiveOverrideProvider` current value.
- Populate `focusState` field in payload:
  ```json
  {
    "isActive": true,
    "type": "focus",
    "endsAt": "12:00",
    "suppressedReminders": 3
  }
  ```
- Model should use this to avoid suggesting tasks that would immediately be suppressed.

### Task 3.3 — Unit tests: focus/DND block
- Task proposed during active DND → appears in `blockedByContext`, not just `conflicts`.
- Task proposed outside any override → neither list affected.
- CONFIRM CHANGES button label changes to "Confirm Anyway" when `blockedByContext` is non-empty.

---

## Epic 4 — Session History in Prompt Payload

### Task 4.1 — Build session history for multi-turn context
- `AiPayloadAssembler` already reads last 10 `AiInteractionHistory` entries for `sessionId`.
- In Phase 3, format these as an OpenAI-compatible `messages` array (roles: `user` / `assistant`):
  ```json
  [
    { "role": "user", "content": "Add workout at 5AM" },
    { "role": "assistant", "content": "Planned: Add Morning Workout (5:00 AM)" },
    { "role": "user", "content": "Actually make it 6AM" }
  ]
  ```
- Pass this as a `conversationHistory` field in `AiOperatingLayerPayload`.
- In `OpenAiOperatingLayerClient.parseIntent`, inject `conversationHistory` as preceding messages before the current user turn, so the model has full context for follow-up edits.

### Task 4.2 — Handle follow-up refinements
- When user sends a message that refines an earlier intent (e.g. "Actually make it 6AM"):
  - The previous `AiPlannedChanges` (stored in `AiAssistantService._pendingPlan`) is passed back to the parser.
  - Add `previousPlan` (AiPlannedChanges?) field to `AiOperatingLayerPayload`.
  - System prompt instructs the model: if a `previousPlan` exists, treat the new user message as a delta update — carry over unchanged actions and modify only what the user specified.
- This enables natural back-and-forth without re-stating the full intent.

### Task 4.3 — Persist follow-up exchanges in history
- Each follow-up message (user answer to a question) is saved as a new `AiInteractionHistory` entry with `sessionId` matching the parent interaction.
- Ensure TTL purge still works on session-level entries (all entries with same `sessionId` purged together when oldest entry expires).

---

## Epic 5 — Behaviour Pattern Integration

### Task 5.1 — Add behaviour patterns to the payload
- Extend `AiPayloadAssembler._buildRecentPatterns()` (from Phase 2) to also include:
  - `averageTasksPerDay` (int) — last 7 days.
  - `mostActiveHour` (String) — hour of day when most tasks are scheduled, e.g. "09:00".
  - `streakStatus` (String) — from `analyticsStreakProvider` (e.g. "5-day streak").
  - `mostUsedEnforcementMode` (String) — from task history.
- Add these to `behaviorPreferences` in the payload:
  ```json
  {
    "averageTasksPerDay": 5,
    "mostActiveHour": "09:00",
    "streakStatus": "5-day streak",
    "mostUsedEnforcementMode": "disciplined"
  }
  ```
- The model uses this to make scheduling suggestions that fit the user's rhythm.

### Task 5.2 — Coaching-style-aware response phrasing
- Extend the system prompt in `OpenAiOperatingLayerClient` with a phrasing guide:
  - `supportive`: *"Great choice! Here's what I'll add…"*
  - `balanced`: *"Here's the plan:…"*
  - `disciplined`: *"Scheduled. No excuses."*
  - `intense`: *"Locked in. Execute."*
- This affects the assistant's text messages in the chat thread (not the preview card structure).

---

## Epic 6 — Conflict Summary Banner

### Task 6.1 — Add conflict summary to `AiAssistantScreen`
- When `AiPlannedChanges` has `conflicts.isNotEmpty || blockedByContext.isNotEmpty`:
  - Show a compact amber/red summary banner directly above the `PlannedChangesCard` in the chat thread.
  - Example: *"⚠ 2 conflicts detected — review below before confirming."*
  - Banner is dismissible (tapping it scrolls to the conflict rows in the card).

### Task 6.2 — Conflict count badge
- In the Coach bottom nav tab icon:
  - If there is a pending plan with unresolved `blockedByContext` entries, show a small red badge dot on the tab icon.
  - Remove the badge when the plan is confirmed or cancelled.

---

## Epic 7 — Testing

### Task 7.1 — Unit tests: reminder collision detection
- Two reminders 2 min apart → collision string added.
- Two reminders 5 min apart → no collision.

### Task 7.2 — Unit tests: context conflict detection
- Task inside sleep window → added to `conflicts`.
- Task inside DND override → added to `blockedByContext`.
- Task inside focus override → added to `conflicts` (advisory only).

### Task 7.3 — Unit tests: enforcement mode default
- `AiActionExecutor._createTask` with no `modeRefId` → uses `defaultEnforcementMode`.
- `AiActionExecutor._createTask` with explicit `modeRefId` → uses provided value.

### Task 7.4 — Unit tests: multi-turn session history
- `AiPayloadAssembler.assemble` with 3 history entries → `conversationHistory` has 3 exchanges.
- Model receives them as `user`/`assistant` role alternation.

### Task 7.5 — Widget tests: context-aware `PlannedChangesCard`
- `blockedByContext` non-empty → rows show red background, "Confirm Anyway" button label.
- `conflicts` non-empty → rows show amber background, normal "CONFIRM CHANGES" button.
- Both empty → no conflict section rendered.

### Task 7.6 — Widget test: conflict summary banner
- Banner appears above card when conflicts exist.
- Banner absent when no conflicts.

---

## Acceptance Criteria

- [ ] Scheduling a task during an active sleep window shows a red "Blocked" row in the preview card.
- [ ] Scheduling a task during an active focus override shows an amber "Conflict" warning.
- [ ] Two reminders within 3 minutes trigger a reminder collision warning.
- [ ] AI-created tasks inherit the user's default enforcement mode if none is specified.
- [ ] The AI's conversational tone changes based on the user's coaching style.
- [ ] Follow-up messages ("actually make it 6AM") refine the previous plan without re-stating everything.
- [ ] The session history (up to 10 exchanges) is included in the AI prompt as a prior `messages` array.
- [ ] `behaviorPreferences` payload includes average tasks/day, most-active hour, streak status, and most-used enforcement mode.
- [ ] Conflict summary banner appears above the preview card when conflicts are present.
- [ ] Coach tab shows a red badge dot when there is a pending plan with blocked context items.
