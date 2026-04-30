## Relevant Files

- `PRD/prd-v2-auto-next-task-flow.md` - Source PRD for this implementation checklist.
- `lib/features/home/presentation/home_screen.dart` - Existing auto-next prompt logic and completion hooks from Home.
- `lib/features/timer/presentation/timer_session_screen.dart` - Timer stop + score submit flow where post-completion auto-next must be triggered.
- `lib/features/tasks_hub/presentation/tasks_hub_screen.dart` - "Complete now" path that should reuse shared auto-next behavior.
- `lib/features/planning/application/next_task_ranker.dart` - Canonical next-task ranking logic (`chooseNext`, `rank`).
- `lib/features/planning/application/planned_task_providers.dart` - Fresh task row reads (`readFreshTodayPlannedRows`) and flow snapshot dependencies.
- `lib/features/planning/application/planned_task_collect.dart` - Planned row collection and open task semantics.
- `lib/features/planning/domain/models/flow_transition_event.dart` - Transition model to enrich with high-level intent (`feeling/logical`) while preserving compatibility.
- `lib/features/planning/data/planning_repository.dart` - Transition/accountability persistence APIs.
- `lib/features/planning/data/isar_planning_repository.dart` - Local-first repository wiring and flow transition delegation behavior.
- `lib/features/execution/application/execution_controller.dart` - Task session state transitions and persistence readiness (`stopAndPersist`).
- `lib/features/scoring/application/scoring_controller.dart` - Score submit point and completion percent contract.
- `lib/core/di/providers.dart` - Potential provider registration for shared auto-next orchestration utility.
- `lib/app/notification_response_handler.dart` - Existing notification-triggered auto-start behavior reference for UX parity.
- `test/features/timer/` - Timer flow tests (create/update if folder missing).
- `test/features/home/` - Home completion and next-prompt behavior tests.
- `test/features/tasks_hub/` - Complete-now and post-completion branching tests.
- `test/features/planning/` - Flow transition model and compatibility tests.

### Notes

- Keep existing ranking logic unchanged; this checklist focuses on orchestration and consistency.
- Auto-next must run only when score submit returns `completionPercent == 100`.
- Reuse existing countdown UX pattern from notification-triggered launch: 10 seconds + cancel.
- Preserve backward compatibility for existing `FlowTransitionEvent` readers and stored records.

## Tasks

- [x] 1.0 Build a shared post-completion auto-next orchestrator
  - [x] 1.1 Create a dedicated application helper/service (for example `auto_next_task_flow.dart`) that owns post-completion decision flow.
  - [x] 1.2 Define one public entrypoint (example: `runAfterCompletion(context, ref, completedTaskId, completionPercent)`).
  - [x] 1.3 Enforce trigger guard in the shared layer: return immediately if `completionPercent != 100`.
  - [x] 1.4 Read fresh rows using `readFreshTodayPlannedRows(ref)` rather than stale provider futures.
  - [x] 1.5 Exclude `completedTaskId` from candidates before ranking.
  - [x] 1.6 Select candidate via `NextTaskRanker.chooseNext(candidates, preferUserSequence: true)`.
  - [x] 1.7 If no next candidate exists, show a short success completion message and exit gracefully.
  - [x] 1.8 Keep async safety with `context.mounted` checks before dialogs/navigation.

- [x] 2.0 Standardize the next-step prompt and branching behavior
  - [x] 2.1 Move the Home prompt content ("Start next task?") into shared UI logic.
  - [ ] 2.2 Keep exactly three core actions in V2:
    - [x] 2.2.1 `Start now`
    - [x] 2.2.2 `Need extra time`
    - [x] 2.2.3 `Move to later`
  - [x] 2.3 Ensure prompt shows chosen next task title in message body.
  - [x] 2.4 On `Start now`, log transition event before launching timer.
  - [x] 2.5 On `Need extra time`, route to existing extra-time branch logic (no behavior regression).
  - [x] 2.6 On `Move to later`, route to existing reason-required branch logic.
  - [x] 2.7 Keep snackbar/dialog copy consistent across Home, Timer, and Tasks Hub flows.

- [ ] 3.0 Integrate shared auto-next into Timer completion path
  - [x] 3.1 In `timer_session_screen.dart`, call shared auto-next flow only after score submit succeeds.
  - [ ] 3.2 Ensure score-cancel path does not trigger auto-next.
  - [x] 3.3 Ensure partial score (`<100`) does not trigger auto-next.
  - [x] 3.4 Preserve existing timer session persistence and score writes unchanged.
  - [ ] 3.5 Prevent duplicate prompt invocation if user double-taps stop or re-enters flow quickly.

- [x] 4.0 Integrate shared auto-next into Home and Tasks Hub completion paths
  - [x] 4.1 Replace Home-specific `_promptStartNextTask` usage with shared orchestrator call.
  - [x] 4.2 Ensure Home completion still respects mandatory timer policy checks before completion.
  - [x] 4.3 In Tasks Hub `_completeFromHub`, invoke shared auto-next after completion success.
  - [x] 4.4 Keep existing reorder/edit/delete behaviors untouched in Tasks Hub.
  - [x] 4.5 Confirm all three entry points produce same prompt options and same follow-up behavior.

- [ ] 5.0 Enforce 10-second auto-start countdown parity (Option B)
  - [x] 5.1 Pass `TimerLaunchArgs(autoStartDelaySeconds: 10)` on `Start now` navigation.
  - [ ] 5.2 Verify timer screen shows countdown banner with a clear `Cancel` action.
  - [ ] 5.3 Verify countdown reaching zero starts session automatically.
  - [ ] 5.4 Verify cancel keeps session in `notStarted` and removes countdown.
  - [ ] 5.5 Validate parity with notification-driven auto-start UX (copy, behavior, affordances).

- [ ] 6.0 Extend Plans Changed model with dual reason format (Option C)
  - [x] 6.1 Add high-level intent field to transition payload (`feeling` / `logical`) in a backward-compatible way.
  - [x] 6.2 Preserve existing detailed reason category field and validation.
  - [x] 6.3 Keep free-text reason note validation rules unchanged (required where already required).
  - [x] 6.4 Default high-level intent to `logical` when structured reason exists and user did not explicitly choose `feeling`.
  - [x] 6.5 Ensure old records deserialize without crashes or behavior changes.
  - [ ] 6.6 Update any relevant mapping/serialization tests and docs.

- [ ] 7.0 Logging, telemetry, and observability for auto-next flow
  - [ ] 7.1 Log "prompt shown" event when next-task dialog is displayed.
  - [ ] 7.2 Log selected action (`startNow`, `extraTime`, `moveWithReason`).
  - [ ] 7.3 Log countdown lifecycle (`started`, `canceled`, `autoStarted`).
  - [ ] 7.4 Keep existing `FlowTransitionEvent` as accountability source of truth.
  - [ ] 7.5 Confirm no duplicate logging when user dismisses/backs out unexpectedly.

- [ ] 8.0 Automated test coverage
  - [ ] 8.1 Add/extend unit tests for shared orchestrator guards:
    - [ ] 8.1.1 No trigger when score canceled.
    - [ ] 8.1.2 No trigger when completion is partial.
    - [ ] 8.1.3 No prompt when no next task exists.
  - [ ] 8.2 Add tests for ranking invocation semantics:
    - [ ] 8.2.1 Completed task excluded.
    - [ ] 8.2.2 `preferUserSequence: true` is used.
  - [ ] 8.3 Add widget/integration tests for timer path:
    - [ ] 8.3.1 Score 100 -> prompt -> start now -> 10s countdown visible.
    - [ ] 8.3.2 Countdown cancel keeps timer not started.
  - [ ] 8.4 Add widget/integration tests for Home + Tasks Hub parity.
  - [ ] 8.5 Add serialization tests for new high-level reason field backward compatibility.

- [ ] 9.0 Manual QA checklist (release readiness)
  - [ ] 9.1 Timer flow: stop -> score 100 -> prompt appears exactly once.
  - [ ] 9.2 Timer flow: stop -> score 60 -> no auto-next prompt.
  - [ ] 9.3 Start-now branch: timer opens with 10-second countdown and cancel button.
  - [ ] 9.4 Countdown cancel: user remains on timer screen in ready state.
  - [ ] 9.5 Extra-time branch: existing extension behavior still works and logs correctly.
  - [ ] 9.6 Move-to-later branch: reason required and saved correctly.
  - [ ] 9.7 Home completion and Tasks Hub completion behave identically to timer path.
  - [ ] 9.8 No-next-task scenario exits cleanly with user-friendly message.
  - [ ] 9.9 Offline/local-first behavior unaffected (no UI blocking on remote sync).
  - [x] 9.10 Run `flutter analyze` and full `flutter test` before merge.

