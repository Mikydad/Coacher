## Relevant Files

- `PRD/prd-task-prioritization-layered-v1.md` - Source PRD for this implementation checklist.
- `lib/features/planning/application/planned_task_collect.dart` - Planned row collection helpers and open-task predicates.
- `lib/features/planning/application/planned_task_providers.dart` - Home/task provider pipelines where ordering is applied.
- `lib/features/planning/application/next_task_ranker.dart` - Existing "what next" ranking logic to align with layered ordering.
- `lib/features/execution/application/execution_day_loader.dart` - Focus task list source (must consume layered order).
- `lib/features/focus/presentation/focus_selection_screen.dart` - Focus list UI using ordered execution tasks.
- `lib/features/home/presentation/home_screen.dart` - Home task display and "what next" expectations.
- `lib/features/tasks_hub/presentation/tasks_hub_screen.dart` - Today list ordering and manual reorder behavior.
- `lib/features/planning/domain/models/task_item.dart` - Task fields used for classification and scoring.
- `lib/features/planning/domain/models/block.dart` - Block urgency/time window data used for urgency score.
- `lib/features/planning/application/auto_next_task_flow.dart` - Post-score next-task choice flow; should use consistent ranking.
- `lib/features/reminders/domain/models/reminder_config.dart` - Reminder-time semantics reference.
- `test/features/planning/` - Unit tests for ranking, model compatibility, and prioritization behavior.
- `test/features/timer/` - Ensure timer/auto-next behavior remains stable with new ranking order.
- `test/features/focus/` - Focus list ordering and running-task visibility tests (create if missing).
- `test/features/tasks_hub/` - Tasks list ordering compatibility tests (create if missing).

### Notes

- Keep V1 deterministic and explainable; avoid opaque adaptive logic in this phase.
- Scheduled classification should rely on valid `reminderTimeIso` for the current day.
- Completed tasks must never appear in prioritized open-task output.
- Maintain backward compatibility with existing local-first and reminder behavior.

## Tasks

- [ ] 1.0 Create layered prioritization core module
  - [ ] 1.1 Add `lib/features/planning/application/task_prioritizer.dart` with a pure function API (input rows -> ordered output).
  - [ ] 1.2 Define output model (e.g. `PrioritizedTaskRow`) containing:
    - [ ] 1.2.1 original `PlannedTaskRow`
    - [ ] 1.2.2 layer kind enum: `overdueScheduled`, `upcomingScheduled`, `doNow`, `flexible`
    - [ ] 1.2.3 computed score metadata (optional for debugging/tests)
  - [ ] 1.3 Include strict open-task filtering (`notStarted`, `inProgress`, `partial` only).
  - [ ] 1.4 Add stable deterministic tie-break fallback (`orderIndex`, then `id`).

- [ ] 2.0 Implement scheduled-task classification and ordering (layers 1 and 2)
  - [ ] 2.1 Add safe parser for `task.reminderTimeIso`; invalid parse -> treat as flexible.
  - [ ] 2.2 Ensure scheduled task is considered "today-scheduled" only when date aligns with today.
  - [ ] 2.3 Classify scheduled open tasks into:
    - [ ] 2.3.1 `overdueScheduled` when scheduled time < now
    - [ ] 2.3.2 `upcomingScheduled` when scheduled time >= now
  - [ ] 2.4 Sort both scheduled groups by nearest time ascending.
  - [ ] 2.5 Guarantee scheduled groups always precede all flexible groups.

- [ ] 3.0 Implement "Do Now" quick-win layer (layer 3)
  - [ ] 3.1 Build flexible candidate pool excluding tasks already in scheduled layers.
  - [ ] 3.2 Rank do-now candidates by:
    - [ ] 3.2.1 lower duration first
    - [ ] 3.2.2 higher priority next (`1` before `5`)
    - [ ] 3.2.3 deterministic fallback
  - [ ] 3.3 Take top 3 max for do-now section.
  - [ ] 3.4 Remove selected do-now tasks from remaining flexible pool to avoid duplicates.

- [ ] 4.0 Implement flexible score ordering (layer 4)
  - [ ] 4.1 Add V1 scoring helpers:
    - [ ] 4.1.1 `priorityScore` from task priority
    - [ ] 4.1.2 `urgencyScore` from block urgency (default fallback if unknown)
    - [ ] 4.1.3 `easeScore` inverse of duration
  - [ ] 4.2 Apply default V1 weights:
    - [ ] 4.2.1 priorityWeight = 0.5
    - [ ] 4.2.2 urgencyWeight = 0.3
    - [ ] 4.2.3 easeWeight = 0.2
  - [ ] 4.3 Sort remaining flexible tasks by descending combined score.
  - [ ] 4.4 Keep stable tie-break ordering (`orderIndex`, then `id`).

- [ ] 5.0 Integrate prioritizer into providers and ranking consumers
  - [ ] 5.1 Apply prioritizer in `planned_task_providers.dart` for today/open task sourcing.
  - [ ] 5.2 Update `execution_day_loader.dart` so Focus list uses layered order output.
  - [ ] 5.3 Align Home "what next" source with new layered ordering.
  - [x] 5.4 Ensure `NextTaskRanker` or next-task selection path is consistent with layered ordering.
  - [ ] 5.5 Keep non-prioritization logic unchanged (timers, scoring, reminder, auto-next branches).

- [ ] 6.0 Preserve Tasks Hub manual reorder compatibility
  - [ ] 6.1 Define and implement rule for manual order interplay:
    - [x] 6.1.1 scheduled precedence still enforced
    - [x] 6.1.2 user order used for equal/untimed ties (or full flexible ordering if chosen)
  - [x] 6.2 Ensure reorder writes do not break prioritizer assumptions.
  - [x] 6.3 Confirm no duplicate or unstable oscillation after reorder + refresh.

- [ ] 7.0 Optional V1 UI grouping (if enabled in this phase)
  - [ ] 7.1 Decide whether to render section headers now or keep flattened list.
  - [ ] 7.2 If sectioned, add headers in order:
    - [ ] 7.2.1 Overdue
    - [ ] 7.2.2 Upcoming
    - [ ] 7.2.3 Do Now
    - [ ] 7.2.4 Flexible
  - [ ] 7.3 Keep current visual style and avoid large UX regressions.

- [ ] 8.0 Add test coverage for prioritization behavior
  - [ ] 8.1 Unit tests for parser/classification:
    - [x] 8.1.1 valid today time -> scheduled
    - [x] 8.1.2 invalid time -> flexible
    - [x] 8.1.3 past time -> overdue
    - [x] 8.1.4 future time -> upcoming
  - [ ] 8.2 Unit tests for layer ordering guarantees:
    - [x] 8.2.1 overdue before upcoming
    - [x] 8.2.2 scheduled before do-now/flexible
    - [x] 8.2.3 do-now max 3 and no duplicates
  - [x] 8.3 Unit tests for flexible score sort and tie-break determinism.
  - [x] 8.4 Integration/widget tests for Focus/Home/Tasks order consistency.
  - [x] 8.5 Regression tests for auto-next selection compatibility.

- [ ] 9.0 Validation and release checks
  - [ ] 9.1 Manual QA scenarios:
    - [ ] 9.1.1 overdue + upcoming + untimed mixed day
    - [ ] 9.1.2 all untimed tasks
    - [ ] 9.1.3 invalid reminder times present
    - [ ] 9.1.4 running task present with prioritized list updates
  - [x] 9.2 Run `flutter analyze` and fix any new diagnostics.
  - [x] 9.3 Run focused tests first, then full `flutter test`.
  - [ ] 9.4 Confirm no regressions in reminder scheduling and score flow.

