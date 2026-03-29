## Relevant Files

- `tasks/prd-v2-structured-routines-flow.md` - Source PRD for this implementation task list.
- `lib/features/plan_tomorrow/presentation/plan_tomorrow_screen.dart` - Existing day-structure UX that can evolve into block/routine flow entry.
- `lib/features/plan_tomorrow/application/plan_tomorrow_providers.dart` - Planning state providers that can host block urgency and next-task signals.
- `lib/features/planning/domain/models/routine.dart` - Routine model; likely needs mode/block metadata extensions.
- `lib/features/planning/domain/models/block.dart` - Block model; likely needs urgency/status/timer policy fields.
- `lib/features/planning/domain/models/task_item.dart` - Planned task model; likely needs sequence, strictness, extension policy hooks.
- `lib/features/planning/data/planning_repository.dart` - Persistence layer for routine/block/task changes and override logs.
- `lib/features/execution/domain/task_timer_engine.dart` - Existing task timer logic; base for mandatory timer policies.
- `lib/features/execution/domain/models/timer_session.dart` - Timer session model; likely needs task vs block session type.
- `lib/features/execution/data/execution_repository.dart` - Execution persistence and queries for active sessions / transitions.
- `lib/features/reminders/application/reminder_sync_service.dart` - Existing reminder scheduler; base for escalation-aware reminders.
- `lib/core/notifications/local_notifications_service.dart` - Notification channels, schedule cadence, and repeat/snooze strategy.
- `lib/features/tasks_hub/presentation/tasks_hub_screen.dart` - Task list touchpoint for next-task prompts and override entry points.
- `lib/features/home/presentation/home_screen.dart` - Home-level "what next" entry and routine progress surfacing.
- `lib/core/firebase/firestore_paths.dart` - Firestore path additions for override logs / mode configuration storage.
- `lib/core/sync/sync_service.dart` - Offline queue behavior for strict-flow events and logs.
- `lib/app/app.dart` - Route wiring for new V2 routine/flow screens.
- `test/features/execution/` - Timer and next-task policy tests.
- `test/features/reminders/` - Reminder cadence/escalation tests.
- `test/features/planning/` - Routine/block/override policy tests.

### Notes

- iOS-first behavior should be preserved, but data/model design should remain Android-ready.
- Enforce strict-mode guardrails: never fully block emergency exits; always allow reason submission path.
- Keep data contract backward-compatible for existing routines/tasks/reminders.

## Tasks

- [x] 1.0 Build V2 routine structure and mode-aware policy foundation
  - [x] 1.1 Define mode enum + config contract (`Flexible`, `Disciplined`, `Extreme`) with extension points for user-defined modes.
  - [x] 1.2 Extend routine/block domain models to store mode, block windows, urgency metadata, and policy references.
  - [x] 1.3 Add migration-safe `fromMap` defaults so old documents load without crashes.
  - [x] 1.4 Create policy resolver service that returns enforcement rules by mode + task priority.
  - [x] 1.5 Persist mode/routine settings via repository + sync queue fallback.
  - [x] 1.6 Add unit tests for mode policy resolution and backward-compatible deserialization.
- [x] 2.0 Implement auto next-task flow with priority+urgency ranking and user-defined sequence override
  - [x] 2.1 Create next-task ranking function combining priority, urgency, and block context.
  - [x] 2.2 Add user-defined sequence support and precedence rules (sequence first unless urgency override triggers).
  - [x] 2.3 Add completion hook: after task completion, show "Start next task?" confirmation.
  - [x] 2.4 Add response branches: start now, request extra time, move to another time with reason.
  - [x] 2.5 Store transition events (accepted next task, deferred, skipped) for analytics/accountability.
  - [x] 2.6 Add tests for ranking edge cases (equal priority, urgent nearing block end, custom sequence override).
- [x] 3.0 Implement "Plans Changed?" override flow with structured reason + mandatory explanation logging
  - [x] 3.1 Define structured reason categories and validation rules (category required + 1-2 sentence text).
  - [x] 3.2 Build "Plans Changed?" flow UI with options: reshuffle, defer, skip.
  - [x] 3.3 Add stricter confirmation UX for high-priority tasks and stricter modes.
  - [x] 3.4 Persist override decision + reason payload to accountability logs.
  - [x] 3.5 Update task/block scheduling after override (order changes, new time targets, status flags).
  - [x] 3.6 Add tests for invalid reason handling and strict-mode override paths.
- [x] 4.0 Extend timer system to support task and block timers with Disciplined/Extreme mandatory rules
  - [x] 4.1 Extend timer session model to differentiate task session vs block session.
  - [x] 4.2 Add block timer lifecycle (start/pause/resume/stop) and persistence.
  - [x] 4.3 Enforce mandatory timer in Disciplined/Extreme (or strict task configuration) before completion.
  - [x] 4.4 Add extension request flow with policy-based allowance and max +60 minute guard.
  - [x] 4.5 Show commitment reflection prompt before approving extension.
  - [x] 4.6 Add timer tests for mandatory enforcement, extension limits, and resume behavior after app relaunch.
- [x] 5.0 Implement adaptive reminder, snooze, and escalation framework that persists until action/reason
  - [x] 5.1 Design reminder cadence matrix by mode and block urgency.
  - [x] 5.2 Implement adaptive snooze intervals (shorter for urgent/strict contexts).
  - [x] 5.3 Add escalation ladder: persistent reminders -> app-open escalation -> non-essential action gating.
  - [x] 5.4 Ensure reminders stop only when user starts task or provides valid logical reason.
  - [x] 5.5 Add safety guardrails to prevent hard lock without reason/emergency paths.
  - [x] 5.6 Add tests for cadence, escalation transitions, and stale schedule recovery.
- [x] 6.0 Add accountability log retention (30 days), delete/export controls, and settings/history surfaces
  - [x] 6.1 Define accountability log schema (timestamp, mode, priority, reason category, reason text, action taken).
  - [x] 6.2 Implement retention worker to prune logs older than 30 days.
  - [x] 6.3 Build history screen with filtering by date/mode/reason category.
  - [x] 6.4 Add manual delete flow (single entry + bulk range delete).
  - [x] 6.5 Add export flow (initial format decision placeholder: CSV or JSON).
  - [x] 6.6 Add tests for retention pruning, export content correctness, and delete operations.
- [x] 7.0 Integrate V2 flow into Home / Tasks / Plan screens with iOS-first UX and migration-safe persistence
  - [x] 7.1 Add Home entry points for current block status and "what next" quick action.
  - [x] 7.2 Integrate next-task prompt and override triggers in Tasks Hub flow.
  - [x] 7.3 Integrate block/mode controls in Plan Tomorrow or dedicated routine setup surface.
  - [x] 7.4 Add route wiring for new V2 screens/components in app shell.
  - [x] 7.5 Ensure all new writes use existing sync/offline queue patterns.
  - [x] 7.6 Run migration QA on accounts with old routine/task/reminder data.
- [x] 8.0 Verification: automated tests + manual QA for mode, urgency, timer, reminder, and override scenarios
  - [x] 8.1 Add unit test suites for policy engine, ranking, override validation, and escalation rules.
  - [x] 8.2 Add widget tests for critical flows (task complete -> next prompt, plans changed dialog, extension prompt).
  - [x] 8.3 Add repository/integration tests for persistence + sync queue fallback.
  - [x] 8.4 Create manual QA checklist for each mode (Flexible/Disciplined/Extreme).
  - [x] 8.5 Manual test iOS notification behavior for snooze/escalation and app restart safety.
  - [x] 8.6 Define release readiness gates (no crash regressions, reminder reliability, baseline completion telemetry).

