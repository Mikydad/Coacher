# PRD — V2 Structured Routines + Flow

## 1. Introduction / Overview

V2 introduces a guided daily execution system so users do not just create plans and forget them. The product should actively guide users through their day, suggest the next best task, enforce commitment based on selected mode, and require a logical override when plans change.

This version focuses on reducing chaos and indecision by combining:
- Structured routine blocks (morning/afternoon/night + custom blocks)
- Auto next-task guidance within blocks
- Strong reminder and escalation behavior
- Task and block timers
- "Plans Changed?" override flow with reason logging

Primary outcome: users follow through on planned tasks more consistently instead of abandoning plans.

---

## 2. Goals (Product Objectives)

1. Help users always know what to do next during the day.
2. Reduce drop-off after planning by enforcing follow-through with reminders and escalation.
3. Provide predictable daily structure while still allowing controlled flexibility.
4. Require clear, logical reasoning when users postpone/skip tasks.
5. Increase daily completion and accountability without making the app unusable.

---

## 3. User Stories

- As a user, I want my day broken into meaningful blocks so I can stay structured.
- As a user, I want the app to suggest the best next task so I do not overthink what to do.
- As a user, if I finish a task, I want a prompt to start the next one immediately.
- As a user, if I cannot continue, I want to change plan with a valid reason so I stay honest.
- As a user, I want reminders to persist until I act or explain why I cannot.
- As a user, I want mode-based discipline (Flexible, Disciplined, Extreme) that matches my intent.
- As a user, I want my accountability history kept for 30 days with export/delete options.

---

## 4. Functional Requirements

### 4.1 Routines and Blocks

1. The system must support routine blocks for a day, with defaults for Morning / Afternoon / Night.
2. The user must be able to add custom blocks (name, start, end).
3. The user must be able to reorder blocks and enable/disable custom blocks.
4. Each block must show its active tasks and current block status (upcoming, active, completed, overflow).
5. Block urgency must be calculated from time remaining, pending priority tasks, and mode strictness.

### 4.2 Modes and Enforcement

6. The system must support three base modes: Flexible, Disciplined, Extreme.
7. The user can optionally create custom modes in later iterations; V2 should keep data model extensible for this.
8. Enforcement behavior must vary by mode and task priority:
   - Flexible: light reminders, easier override.
   - Disciplined: stronger reminders, stricter override.
   - Extreme: timer required, strong escalation, minimal bypass.
9. For high-priority tasks, escalation rules must be stricter regardless of mode.

### 4.3 Auto Next-Task Flow

10. When a task is completed, the app must immediately prompt: "Start next task?"
11. Next task ranking must use priority + urgency by default.
12. The user must be able to self-define sequence; when defined, sequence is respected unless urgency rules require override.
13. If user does not start suggested task, the app must ask for one of:
   - Start now
   - Need extra time on current task
   - Move to another time with logical reason

### 4.4 Plans Changed? (Override Flow)

14. User must be able to trigger "Plans Changed?" from task/block flow.
15. Override must require:
   - Reason category (structured list)
   - Short explanation text (1-2 sentences)
16. Override choices must include:
   - Reshuffle remaining tasks
   - Defer selected task(s)
   - Skip selected task(s)
17. For strict modes/high-priority tasks, override confirmation must be more explicit and include consequences.
18. Override records must be saved as accountability logs.

### 4.5 Timers (Task + Block)

19. The user must be able to run timer per task.
20. The user must be able to run timer per block.
21. In Disciplined/Extreme (or task configured as strict), timer must be mandatory before marking completion.
22. Timer UI must support pause/resume/extend within policy limits.

### 4.6 Extensions and Extra Time

23. Extra time requests must be limited by reason and context.
24. V2 should allow up to +60 minutes maximum extra time per request flow, with policy checks.
25. During extension flow, app must display a commitment reflection prompt (e.g., "What you promised yourself") before approval.
26. Extension approvals/denials must be logged.

### 4.7 Reminders, Snooze, and Escalation

27. Reminders must be mode-aware and urgency-aware.
28. Soft snooze intervals must adapt by mode/block urgency (shorter intervals for strict/urgent contexts).
29. Reminder chain must not silently disappear until user:
   - Starts the task, or
   - Provides valid logical reason
30. Escalation framework must support all levels based on context:
   - Persistent nag reminders
   - Escalated prompt on next app open
   - Hard gating of non-essential actions (strict contexts only)
31. Escalation must include guardrails to avoid unsafe lockouts (e.g., always allow emergency exit path).

### 4.8 Accountability Logs and Data Controls

32. Reason logs must be retained for 30 days by default.
33. User must be able to manually delete logs.
34. User must be able to export logs (human-readable format) from settings/history area.
35. Logs must include timestamp, task/block id, mode, reason category, free-text reason, and action taken.

### 4.9 Platform Scope

36. V2 initial release scope is iOS only.
37. Architecture must avoid iOS-only assumptions that block Android in V2.1.

---

## 5. Non-Goals (Out of Scope)

- Full social/accountability community features in V2.
- Fully AI-evaluated reason quality in V2 (future enhancement).
- Deep analytics dashboard beyond essential accountability and completion metrics.
- Full custom mode marketplace/presets beyond base modes (future enhancement).

---

## 6. Design Considerations

- UX tone should feel coaching and decisive, not punitive.
- "Next action" prompts should be short and immediate.
- Strict-mode prompts should be explicit about why enforcement is happening.
- Reflection prompts should reinforce self-commitment rather than shame language.
- Critical flows: task completion -> next prompt, reminder escalation, plan override.

---

## 7. Technical Considerations

- Integrate with existing task, reminder, and goal infrastructure.
- Add mode-aware policy engine (enforcement, snooze, escalation, extension).
- Use deterministic next-task ranking (priority + urgency + optional sequence).
- Store accountability logs with retention management and export endpoint.
- Keep reminder scheduling resilient to stale dates/timezone changes.
- Keep data model extensible for future AI reason-scoring.

---

## 8. Success Metrics

1. Increase in users reporting fewer "I don't know what to do next" moments.
2. Increase in daily task completion rate.
3. Secondary: lower share of plans created but not acted on in the same day.
4. Secondary: reduction in skipped tasks without valid reason.

---

## 9. Open Questions

1. Exact urgency formula weights (priority vs time-left) need final tuning values.
2. Final list of valid structured reason categories needs product sign-off.
3. Hard gating boundaries for Extreme mode must be finalized to avoid over-friction.
4. Export format for accountability logs (CSV vs JSON vs PDF) needs decision.
5. Whether custom user-defined modes are V2 or V2.1 toggle-gated.
6. AI reason quality validation target timeline (currently future phase).

