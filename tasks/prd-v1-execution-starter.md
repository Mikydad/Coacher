# PRD: V1 Execution Starter

## 1. Introduction / Overview
This PRD defines V1 of the AI Accountability app focused on reliable task completion tracking for a solo user first, with a structure that can later support multiple users.

V1 goal is to help the user plan next-day work, execute tasks with a timer, receive reminders, and manually score completion quality. This creates the foundation for accountability features in later versions.

## 2. Goals
- Enable the user to plan tomorrow using `Routine -> Block -> Task` hierarchy.
- Enable task execution with a per-task timer.
- Provide reminder delivery using Firebase-backed settings plus local device triggers.
- Capture manual task completion quality using `% complete + reason note`.
- Build measurable consistency through daily planning and completion behavior.

## 3. User Stories
- As a solo user, I want to create routines, blocks, and tasks for tomorrow so I can start my day with a clear plan.
- As a solo user, I want to start and stop a timer for a task so I can track whether I worked as intended.
- As a solo user, I want to receive reminders at planned times so I stay on schedule.
- As a solo user, I want to record completion percentage and a reason note so I can honestly evaluate execution.
- As a future multi-user app owner, I want data modeled cleanly so the same flows can later support multiple accounts.

## 4. Functional Requirements
1. The system must allow creating a plan for the next day with this hierarchy:
   - Routine (Morning/Afternoon/Night or custom label)
   - Block (group of tasks)
   - Task (title, optional description, planned duration, priority, planned reminder time optional)
2. The system must allow editing and deleting routines, blocks, and tasks before execution.
3. The system must persist all planning data in Firebase Firestore using a user-scoped structure that is compatible with future authentication.
4. The system must show tomorrow's planned routines/blocks/tasks in execution order.
5. The system must allow the user to start, pause, resume, and stop a per-task timer.
6. The system must store actual time spent for each task timer session.
7. The system must allow the user to mark a task as completed or partially completed.
8. The system must require manual scoring on task close:
   - Completion percentage (0-100)
   - Reason note (required if completion < 100, optional if 100)
9. The system must save task scoring data to Firebase.
10. The system must allow reminder configuration for tasks in Firebase (time and enabled/disabled status).
11. The app must schedule local notifications on device based on Firebase reminder settings.
12. When reminder settings change, local notifications must be updated to match the latest Firebase state.
13. The app must support offline operation for planning, timer tracking, task completion, and scoring.
14. When connectivity returns, offline changes must sync to Firebase without duplicate task records.
15. The system must operate without user authentication in V1 (single local user mode).
16. The UI must provide a daily view with clear status labels for each task (Not Started, In Progress, Completed, Partial).

## 5. Non-Goals (Out of Scope)
- AI nudges, AI decisioning, or AI accountability conversations.
- Hard alarms and escalation modes (Easy/Normal/Discipline/Extreme behavior is excluded).
- Block-level analytics/reflection dashboards beyond basic task-level data capture.
- Notes and revision reminder workflow.
- Pomodoro mode.
- Multi-user account/login flows.

## 6. Design Considerations
- Prioritize fast input and low friction for nightly planning.
- Keep execution screen focused on current task, timer, and completion action.
- Use simple, readable status indicators and clear call-to-action buttons.
- Keep visual architecture ready for future mode/escalation and AI layers without exposing those controls in V1.
- Use the provided UI layouts in `/UI` as the visual reference for V1 screens:
  - `Homepage.png`: daily overview of planned routines/blocks/tasks and entry point to execution.
  - `Goal_section.png`: planning section layout for creating/editing routines/blocks for tomorrow.
  - `AddTask_page.png`: UI for adding/updating tasks (title, duration, priority, optional reminder time).
  - `Focus_page.png`: focused view for the currently active task (timer actions + completion entry).
  - `Timer_page.png`: timer UI for start/pause/resume/stop and displaying time spent.

In V1, the implementation must ensure these user interactions exist on the corresponding screens:
- From `Homepage.png`, the user can navigate into executing a selected planned task.
- From `AddTask_page.png`, the user can create/edit task fields required by V1 (title, duration, priority, optional reminder time).
- From `Timer_page.png` and `Focus_page.png`, the user can drive the per-task timer and submit completion scoring (`% complete` + `reason note` when needed).

## 7. Technical Considerations
- Framework: Flutter (iOS + Android).
- Backend: Firebase (Firestore; reminder config stored remotely).
- Notifications: local notification scheduling on device, driven by Firebase reminder data.
- State management: Riverpod.
- Architecture: pragmatic layered approach (Presentation, Domain, Data) without overengineering.
- Offline-first behavior required for planning and execution flows.
- Data model should align with future authenticated structure (e.g., user-scoped collections), even though V1 does not require login.

## 8. Success Metrics
- `% of planned tasks completed per day` (primary).
- `Number of planned tasks per day`.
- `Reminder acknowledgment rate`.

## 9. Open Questions
- Confirm non-goals selection: interpreted as excluding `A (AI)`, `B (hard alarms/escalation)`, and `D (block analytics)` from your response.
- Should reminder acknowledgment be captured as explicit user action (tap/open) or inferred from task start within a time window?
- For single-user mode without auth, confirm whether a fixed local user ID should be used for Firestore paths in V1.
