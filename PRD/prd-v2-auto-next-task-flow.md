# PRD — V2 Auto Next-Task Flow

## 1. Introduction / Overview

This PRD defines how the app should move a user from one completed task to the next task with minimal friction, while preserving user control.

The flow starts only after the user stops the timer, confirms task completion via score input, and marks the task as fully done. Then the app prompts the user to start the next task. If the user agrees, the timer screen opens with a 10-second auto-start countdown and a visible cancel option.

Goal: help users continue execution momentum immediately after finishing a task.

---

## 2. Goals

1. Reduce delay between finishing one task and starting the next.
2. Preserve user agency by asking for explicit readiness before starting next task.
3. Reuse existing notification-triggered auto-start behavior for consistency.
4. Standardize "Plans Changed?" data so it supports both high-level and detailed reasoning.
5. Keep implementation deterministic and reusable across Home, Timer, and Tasks Hub entry points.

---

## 3. User Stories

- As a user, after I finish a task, I want to be asked if I am ready for the next task so I can stay in flow.
- As a user, when I accept the next task, I want it to auto-start after a short countdown so I can begin quickly.
- As a user, I want to cancel the countdown if I need a brief pause before starting.
- As a user, if I am not ready, I want to defer with a valid reason instead of silently dropping the plan.
- As a developer, I want one shared auto-next flow so behavior is consistent in all screens.

---

## 4. Functional Requirements

### 4.1 Trigger Conditions

1. The system must trigger auto-next evaluation only after:
   - Timer session is stopped and persisted.
   - Score dialog is completed.
   - User completion is confirmed as fully done (`completionPercent == 100`).
2. If score dialog is canceled, auto-next must not run.
3. If completion is partial (`completionPercent < 100`), auto-next must not run in V2.
4. If no open next task exists, the system must show a brief completion message and end the flow.

### 4.2 Next Task Selection

5. Next task must be selected using `NextTaskRanker.chooseNext(...)`.
6. Selection must exclude the just-completed task ID.
7. Ranking should prefer user sequence where available (`preferUserSequence: true`) with current urgency override behavior preserved.

### 4.3 Next-Step Prompt

8. After selecting candidate next task, app must show prompt:
   - Title: "Start next task?"
   - Content: next task title
9. Prompt must provide at least three actions:
   - `Start now`
   - `Need extra time`
   - `Move to later`
10. Choosing `Start now` must log a flow transition event before navigation.

### 4.4 Start Behavior (Option B)

11. On `Start now`, app must navigate to `TimerSessionScreen`.
12. Screen must launch with countdown auto-start set to 10 seconds.
13. Countdown UI must include a clear `Cancel` button.
14. If countdown reaches 0, timer starts automatically.
15. If user taps `Cancel`, countdown stops and timer remains in not-started state.
16. This behavior must match the existing notification-driven auto-start UX pattern.

### 4.5 Plans Changed Data Model (Option C)

17. "Plans Changed?" logging must store both:
   - High-level intent: `feeling` or `logical`.
   - Detailed reason category (existing structured categories, e.g. dependency blocked).
18. Free-text reason note remains required for defer/move flows per existing validation rules.
19. `logical` should be default when detailed structured reason is provided and user does not explicitly pick `feeling`.
20. Data shape must remain backward compatible with existing `FlowTransitionEvent` consumers.

### 4.6 Integration Points

21. Auto-next flow must be reusable and called from:
   - Timer completion + score submit path.
   - Home task completion path.
   - Tasks Hub "Complete now" path.
22. A shared application-level helper/service should own this flow to avoid duplicated UI logic.

### 4.7 Logging and Analytics

23. System must log at minimum:
   - Prompt shown
   - Decision selected (`startNow`, `extraTime`, `moveWithReason`)
   - Countdown started
   - Countdown canceled
   - Auto-start executed
24. Existing flow transition logging must remain the source of truth for accountability history.

---

## 5. Non-Goals (Out of Scope)

- Changing next-task ranking algorithm weights in this PRD.
- AI evaluation of completion honesty.
- Redesigning score dialog UX.
- Migrating all old reason categories to only feeling/logical.
- Advanced adaptive countdown lengths (fixed 10s only in V2).

---

## 6. Design Considerations

- Prompt and countdown should be short, high-clarity, and low-friction.
- Cancel action should be visible without extra taps.
- Text and behavior should mirror existing notification auto-start pattern for familiarity.
- Avoid heavy modal stacking; keep transition focused: score -> next prompt -> timer.

---

## 7. Technical Considerations

- Extract shared flow handler (example: `auto_next_task_flow.dart`) callable from multiple features.
- Reuse existing providers:
  - `readFreshTodayPlannedRows(...)`
  - `NextTaskRanker.chooseNext(...)`
  - `executionControllerProvider`
  - `planningRepositoryProvider.logFlowTransitionEvent(...)`
- Use `TimerLaunchArgs(autoStartDelaySeconds: 10)` when navigating from auto-next.
- Ensure `context.mounted` checks remain in async boundaries.
- Keep offline-first behavior intact (local writes first, queued sync unchanged).

---

## 8. Implementation Sequence

### Phase 1: Shared Flow Extraction

1. Create one shared function/service for post-completion auto-next.
2. Move existing Home `_promptStartNextTask` behavior into shared flow.

### Phase 2: Timer Integration

3. Invoke shared auto-next flow after successful score submit when `completionPercent == 100`.
4. Pass launch args for 10-second auto-start.

### Phase 3: Tasks Hub Integration

5. Invoke shared auto-next flow after "Complete now" success.
6. Ensure logs and messages are consistent with Home/Timer behavior.

### Phase 4: Plans Changed Enrichment

7. Add/propagate high-level reason (`feeling` vs `logical`) while preserving detailed categories.
8. Validate backward compatibility with existing logs and screens.

### Phase 5: QA

9. Validate normal path: complete -> prompt -> start now -> 10s countdown -> auto-start.
10. Validate cancel path: complete -> prompt -> start now -> cancel countdown.
11. Validate defer paths: extra time, move with reason.
12. Validate no-next-task and partial-score behaviors.

---

## 9. Success Metrics

1. Increased share of completed tasks followed by starting another task within 60 seconds.
2. Reduced idle gap between consecutive task sessions.
3. High completion rate of prompt decisions (fewer silent exits).
4. No regression in timer/session persistence and scoring flows.

---

## 10. Open Questions

1. Should partial completion threshold be configurable later (e.g., trigger at >=90%)?
2. Should countdown duration become user-configurable in settings in V2.1?
3. Should the next-task prompt include quick context (duration, priority, block) in V2 or later?
