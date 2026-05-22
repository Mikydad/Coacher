# Tasks — AI Operating Layer · Phase 4: Proactive AI

**PRD reference:** `tasks/prd-ai-operating-layer.md`  
**Depends on:** Phases 1, 2, and 3 complete and merged.  
**Goal:** Shift the AI from reactive (user asks → AI responds) to proactive (AI surfaces opportunities before being asked). The assistant detects scheduling gaps, predicts recurring tasks, and presents lightweight action cards on the Home screen — all still requiring user confirmation before any data changes.

---

## Epic 1 — Proactive Suggestion Engine

### Task 1.1 — Define `ProactiveSuggestion` model
- Create `lib/features/ai_assistant/domain/models/proactive_suggestion.dart`.
- Fields:
  - `id` (String)
  - `type` (enum: `recurringTaskMissing`, `scheduleGap`, `optimiseOrder`, `goalBehindPace`, `lowEnergySlot`)
  - `title` (String) — headline for the suggestion card.
  - `description` (String) — one-sentence explanation.
  - `preDraftedInput` (String) — the text that would be pre-filled in the Coach AI input if the user taps "Let's do it".
  - `confidence` (double)
  - `generatedAt` (DateTime)
  - `dismissed` (bool, default false)

### Task 1.2 — Implement `ProactiveSuggestionEngine`
- Create `lib/features/ai_assistant/application/proactive_suggestion_engine.dart`.
- Inject: `PlanningRepository`, `GoalsRepository`, `EntityNormaliser`, `AiInteractionHistoryRepository`, `AiAssumptionEngine`.
- Method `Future<List<ProactiveSuggestion>> generateForToday()`:

  **Rule 1 — Recurring task missing**
  - Look at the last 7 days of task history.
  - For each category that appeared on ≥ 4 of the last 7 days AND is not yet scheduled today:
    - Generate suggestion: *"You usually schedule a [category] — want to add one today?"*
    - `preDraftedInput`: *"Schedule [most recent title] at [most recent time]"*.
    - confidence: 0.85.

  **Rule 2 — Schedule gap**
  - Find time gaps > 90 minutes in today's scheduled time blocks.
  - If there are active goals without a time block today:
    - Generate suggestion: *"You have a free slot at [time] — want to work on [goal]?"*
    - `preDraftedInput`: *"Add [goal title] at [gap start time] for 60 minutes"*.
    - confidence: 0.75.

  **Rule 3 — Goal behind pace**
  - For each active goal, compare progress to expected pace (deadline vs. today's date vs. completion %).
  - If a goal is ≥ 20% behind pace:
    - Generate suggestion: *"[Goal] is behind schedule — want to add a catch-up session?"*
    - `preDraftedInput`: *"Schedule [goal title] session today for 45 minutes"*.
    - confidence: 0.80.

  **Rule 4 — Optimise task order**
  - If today has ≥ 5 tasks AND any high-priority task is scheduled after low-priority tasks:
    - Generate suggestion: *"Some high-priority tasks are scheduled late — want to reorder?"*
    - `preDraftedInput`: *"Move my most important tasks to the morning"*.
    - confidence: 0.70.

- Cap output at **3 suggestions** — take the top 3 by confidence.
- Suppress any suggestion type the user has dismissed 3+ times in the last 7 days (tracked via Isar).

### Task 1.3 — Persist dismissed suggestions
- Add `DismissedSuggestionLog` Isar collection:
  - `id`, `suggestionType` (String), `dismissedAt` (DateTime).
- Purge entries older than 7 days on app open.
- Register `dismissedSuggestionLogRepositoryProvider`.

### Task 1.4 — Register `proactiveSuggestionEngineProvider`
- `FutureProvider<List<ProactiveSuggestion>>` that calls `generateForToday()`.
- Refresh on: app foreground (via `AppLifecycleTaskRefresh`), task mutation (invalidated alongside `invalidateTaskListProviders`).

---

## Epic 2 — Proactive Suggestion Cards on Home Screen

### Task 2.1 — Build `ProactiveSuggestionCard` widget
- Create `lib/features/ai_assistant/presentation/widgets/proactive_suggestion_card.dart`.
- Design: matches Obsidian Pulse system.
  - Container: `surface-container-high` (#201f1f), radius 16.
  - Accent line: 3px left border in `primary-dim` (#b2ed00).
  - Title: `Body-MD` white.
  - Description: `Label-SM` `on-surface-variant` (#adaaaa).
  - Two action buttons (right-aligned):
    - **"Let's do it"** — `primary-container` pill (small) → opens Coach AI screen with `preDraftedInput` pre-filled.
    - **"Not now"** — ghost, `on-surface-variant` text → logs dismissal, removes card.
- Entrance animation: slide-in from right + fade, 300 ms.
- Exit animation: slide-out + fade when dismissed.

### Task 2.2 — Add `ProactiveSuggestionSection` to Home Screen
- Create `lib/features/ai_assistant/presentation/widgets/proactive_suggestion_section.dart`.
- Placed between the "Today's Tasks" header and the task list on `HomeScreen`.
- Consumes `proactiveSuggestionEngineProvider`.
- Renders up to 3 `ProactiveSuggestionCard` widgets in a vertical list.
- If the list is empty (no suggestions) the section collapses to zero height.
- Loading: shows a single skeleton card while the provider is loading.

### Task 2.3 — Pre-fill Coach AI input from proactive card
- When "Let's do it" is tapped:
  - Navigate to `/coach`.
  - Pass the `preDraftedInput` string as a route argument: `Navigator.pushNamed(context, '/coach', arguments: CoachRouteArgs(preDraftedText: suggestion.preDraftedInput))`.
- In `AiAssistantScreen.initState`, check `ModalRoute.of(context)?.settings.arguments` for `CoachRouteArgs`; if present, pre-fill the `TextEditingController` and auto-focus.
- Add `CoachRouteArgs` model: `{ preDraftedText: String? }`.

### Task 2.4 — Dismiss tracking
- On "Not now" tap:
  - Save `DismissedSuggestionLog(suggestionType: suggestion.type.name, dismissedAt: DateTime.now())`.
  - Invalidate `proactiveSuggestionEngineProvider` so the card disappears immediately.

---

## Epic 3 — Schedule Optimisation Recommendations

### Task 3.1 — Implement `ScheduleOptimisationService`
- Create `lib/features/ai_assistant/application/schedule_optimisation_service.dart`.
- Method `Future<List<OptimisationRecommendation>> analyse(String dateKey)`:
  - Reads all `PlannedTask` items for `dateKey`.
  - Applies rules:

    **Rule A — Priority inversion**: high-priority task starts after a low-priority task in the same time window.
    → Recommendation: swap their order.

    **Rule B — Fatigue stacking**: ≥ 3 high-enforcement (disciplined/extreme) tasks scheduled back-to-back with no break.
    → Recommendation: insert a 15-minute gap between sessions 2 and 3.

    **Rule C — Reminder noise**: ≥ 4 reminders firing within any 30-minute window.
    → Recommendation: spread reminder times to avoid notification overload.

  - Returns a list of `OptimisationRecommendation` objects.
- `OptimisationRecommendation` model: `{ ruleCode, description, preDraftedInput }`.

### Task 3.2 — Surface optimisation recommendations
- Reuse `ProactiveSuggestionCard` widget with `type: optimiseOrder`.
- Add to `ProactiveSuggestionEngine.generateForToday()` output (alongside Rules 1–4).

---

## Epic 4 — Predictive Action Quick Access

### Task 4.1 — "Pick up where you left off" banner
- In `AiAssistantScreen`, when the screen is opened:
  - If `AiInteractionHistory` has an entry from the last 30 minutes that was NOT confirmed:
    - Show a dismissible amber banner at the top of the chat: *"You had a pending plan — want to continue?"*
    - Tapping it re-sends the original `userInput` through `AiAssistantService.sendMessage`, restoring context.

### Task 4.2 — "Morning brief" proactive trigger (optional, toggleable)
- Add a preference toggle in `ProfilePreferenceService`: `morningBriefEnabled` (bool, default false).
- On first app open each day between 06:00–10:00:
  - If `morningBriefEnabled == true` AND the Coach screen has not been opened today:
    - Show a `SnackBar` or subtle banner on Home: *"Coach AI has suggestions for today — tap to review."*
    - Tapping navigates to `/coach` with a pre-drafted message: *"Give me a quick plan for today"*.
- This is purely a notification-style prompt; Coach AI still requires user action to execute anything.

---

## Epic 5 — Analytics Enhancements

### Task 5.1 — Log proactive suggestion analytics
- `proactiveSuggestionShown` — when a suggestion card renders on screen (`{ suggestionType, confidence }`).
- `proactiveSuggestionAccepted` — "Let's do it" tapped (`{ suggestionType }`).
- `proactiveSuggestionDismissed` — "Not now" tapped (`{ suggestionType }`).
- `scheduleOptimisationSuggested` — optimisation recommendation generated (`{ ruleCode }`).

### Task 5.2 — Weekly suggestion effectiveness report (for debugging)
- Add a `ProactiveSuggestionAnalyticsSummary` to the existing `AiSummaryRepository` schema (or a new Isar record).
- Fields: week start, total shown, total accepted, total dismissed, acceptance rate.
- Computed in `ProactiveSuggestionEngine` after each `generateForToday()` run.
- Used internally for tuning suggestion rules; not surfaced to users in Phase 4.

---

## Epic 6 — Testing

### Task 6.1 — Unit tests: `ProactiveSuggestionEngine`
- Rule 1 (recurring missing): task appeared 5/7 days, not today → suggestion generated.
- Rule 1: task appeared 2/7 days → no suggestion.
- Rule 2 (schedule gap): 2-hour gap + active goal → suggestion generated.
- Rule 2: no gap → no suggestion.
- Rule 3 (goal behind pace): goal 25% behind → suggestion generated.
- Rule 4 (priority inversion): high-priority after low-priority → suggestion generated.
- Dismiss suppression: type dismissed 3x in 7 days → excluded.
- Output capped at 3 suggestions.

### Task 6.2 — Unit tests: `ScheduleOptimisationService`
- Rule A (priority inversion): correct tasks identified.
- Rule B (fatigue stacking): correct gap insertion recommendation.
- Rule C (reminder noise): correct spread recommendation.

### Task 6.3 — Widget tests: `ProactiveSuggestionCard`
- "Let's do it" navigates to `/coach` with correct `preDraftedText`.
- "Not now" triggers dismiss callback.
- Slide-in animation completes on mount.

### Task 6.4 — Widget tests: `ProactiveSuggestionSection`
- 3 suggestions → 3 cards rendered.
- 0 suggestions → section collapses (zero height).
- Loading state → skeleton card shown.

### Task 6.5 — Integration test: pre-fill flow
- Navigate to `/coach` with `CoachRouteArgs(preDraftedText: 'Schedule workout')`.
- Assert text field is pre-filled and auto-focused.

---

## Acceptance Criteria

- [ ] When a recurring task is missing from today's schedule, a suggestion card appears on Home before the user opens Coach AI.
- [ ] When a goal is ≥ 20% behind pace, a catch-up suggestion card appears.
- [ ] When a free time slot ≥ 90 min exists alongside an active goal, a gap-fill suggestion appears.
- [ ] Tapping "Let's do it" on any suggestion opens Coach AI with the text pre-filled.
- [ ] Tapping "Not now" dismisses the card; if dismissed 3+ times in 7 days that suggestion type is suppressed.
- [ ] Schedule optimisation recommendations (priority inversion, fatigue stacking, reminder noise) appear as suggestion cards.
- [ ] An un-confirmed plan from < 30 minutes ago is surfaced as a "pick up where you left off" banner in the Coach screen.
- [ ] All proactive suggestion analytics events fire correctly.
- [ ] The section collapses cleanly when there are no suggestions.
- [ ] No proactive action executes without user confirmation — the suggestion only pre-fills input.
