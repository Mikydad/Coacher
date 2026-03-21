## Relevant Files
- `pubspec.yaml` - Flutter dependencies (Riverpod, Firebase, Firestore, local notifications, offline storage)
- `lib/main.dart` - Flutter entry point (wraps app in `ProviderScope`)
- `lib/app/app.dart` - Root app widget and navigation shell
- `lib/core/config/app_config.dart` - V1 single-user configuration (local user id / Firestore root ids)
- `lib/core/firebase/firestore_client.dart` - Firestore client/wrapper for reads/writes
- `lib/core/notifications/local_notifications_service.dart` - Local notification scheduling & updating
- `lib/core/offline/offline_repository.dart` - Offline cache + queued writes + sync trigger
- `lib/features/planning/data/planning_repository.dart` - CRUD for `Routine -> Block -> Task` in Firestore
- `lib/features/planning/presentation/plan_tomorrow_screen.dart` - Night-before planning UI
- `lib/features/execution/presentation/execution_day_screen.dart` - Daily execution screen (tasks in order)
- `lib/features/execution/domain/task_timer_engine.dart` - Timer logic (start/pause/resume/stop + time spent)
- `lib/features/execution/data/execution_repository.dart` - Persists timer sessions and task states
- `lib/features/scoring/presentation/score_task_dialog.dart` - UI for `% complete + reason note` on task close
- `lib/features/scoring/data/scoring_repository.dart` - Persists scoring results
- `lib/features/reminders/data/reminder_repository.dart` - Listens to Firebase reminder config and exposes it to notification scheduler
- `/UI/Homepage.png` - Visual reference for the V1 daily overview + entry point to task execution
- `/UI/Goal_section.png` - Visual reference for the routine/block planning section in “plan tomorrow”
- `/UI/AddTask_page.png` - Visual reference for task creation/editing form
- `/UI/Focus_page.png` - Visual reference for the currently active task view (completion + timer entry)
- `/UI/Timer_page.png` - Visual reference for timer controls (start/pause/resume/stop) and displayed elapsed time
- `test/` - Unit tests for timer/formatting/sync rules and widget tests for critical UI flows

### Notes
- This repo currently contains PRD/task documentation but no Flutter/Dart source code; the paths above are intended starting points for the V1 implementation in this project.
- If you later point me to an existing Flutter app folder you want to reuse, I will update the `Relevant Files` section accordingly.

## Tasks
- [x] 1.0 Project bootstrap (Flutter + Riverpod + Firebase + local notifications + offline storage)
  - [x] 1.1 Create or confirm Flutter app structure in this repo with `ProviderScope` and Riverpod wiring
  - [x] 1.2 Add and configure Firebase for Firestore (Firestore client + single local user mode pathing)
  - [x] 1.3 Add and configure local notifications plugin (Android + iOS permissions + scheduling ability)
  - [x] 1.4 Add offline storage layer for: planning entities, timer state, scoring results, reminder cache
  - [x] 1.5 Add an offline write queue + sync trigger (connectivity listener + retry strategy)
  - [x] 1.6 Create a DI/provider layout (repositories + services) following a pragmatic layered approach
  - [x] 1.7 Add logging/diagnostics for timer ticks, sync operations, and notification scheduling updates

- [x] 1.1 V1 UI scaffold (screens + navigation) using `/UI/*.png` as the visual reference
  - [x] 1.8 Create screens/routes for: Homepage, Goal section, AddTask, Focus, Timer
  - [x] 1.9 Implement navigation flow matching the V1 journey: Homepage -> select task -> Focus/Timer -> completion
  - [x] 1.10 Reproduce UI layout elements from the provided screenshots (buttons, fields, status labels)
  - [x] 1.11 Wire UI to placeholder/mock controllers first so screens work before backend integration
  - [x] 1.12 Add state holders for selected day + selected task + timer state + completion entry state

- [x] 2.0 V1 data model (single local user mode) and Firestore collections design
  - [x] 2.1 Define domain entities and required fields:
    - Routine, Block, Task
    - Timer session (pause/resume/stop + total elapsed)
    - Scoring (completion %, reason note, timestamps)
    - Reminder configuration (enabled + scheduled time per task)
  - [x] 2.2 Decide Firestore document structure for V1 and keep it compatible with future authenticated multi-user structure
  - [x] 2.3 Implement client-generated stable IDs for idempotent sync (avoid duplicates)
  - [x] 2.4 Implement DTO <-> domain mapping and repository interfaces (planning, execution, scoring, reminders)
  - [x] 2.5 Add validation rules (completion 0-100; reason required when completion < 100; optional reminder time)
  - [x] 2.6 Implement local user id strategy and ensure all Firestore paths include it in V1

- [ ] 3.0 Night-before planning module (CRUD for `Routine -> Block -> Task` + next-day ordering)
  - [x] 3.1 Build repositories/services to CRUD routines, blocks, and tasks
  - [x] 3.2 Add a “tomorrow plan” key (what date field/doc identifies tomorrow’s schedule)
  - [x] 3.3 Implement execution ordering (store explicit order index for tasks within a block/routine)
  - [ ] 3.4 Implement Add/Edit flows matching `Goal_section.png` and `AddTask_page.png`
  - [ ] 3.5 Implement task fields required by V1:
    - title
    - planned duration
    - priority
    - optional reminder time + enabled/disabled status
  - [ ] 3.6 Ensure planning reads/writes work offline (local cache first + queue writes immediately)
  - [ ] 3.7 Implement sync for planning changes with a conflict resolution strategy (timestamp-based last-write-wins)
  - [ ] 3.8 Update Homepage so tomorrow’s tasks show `Not Started` status before execution

- [x] 4.0 Execution module (per-task timer: start/pause/resume/stop + store time spent)
  - [x] 4.1 Implement execution-day loader: fetch tomorrow’s tasks in execution order and show active task
  - [x] 4.2 Implement timer state machine:
    - Not Started -> In Progress -> Paused -> Finished (awaiting scoring)
  - [x] 4.3 Implement timer engine with correct pause/resume elapsed tracking (no drift accumulation)
  - [x] 4.4 Persist timer state + elapsed time in offline cache for lifecycle safety
  - [x] 4.5 Persist timer sessions so actual time spent is stored per task
  - [x] 4.6 Implement UI actions on `/UI/Timer_page.png` and `/UI/Focus_page.png` (start/pause/resume/stop)
  - [x] 4.7 On stop, transition to scoring entry and mark task as ready to score

- [x] 5.0 Completion & scoring module (mark completed/partial + `% complete + reason note` + persist)
  - [x] 5.1 Implement scoring entry UX:
    - completion input 0-100
    - reason note field
  - [x] 5.2 Enforce scoring validation:
    - completion < 100 requires reason note
    - completion == 100 allows empty reason note
  - [x] 5.3 Persist scoring results linked to task id + timer session/timestamps
  - [x] 5.4 Update UI task status after scoring:
    - Completed (100)
    - Partial (0-99)
  - [x] 5.5 Ensure scoring works offline and syncs idempotently on reconnect
  - [x] 5.6 Update Homepage daily view to reflect new statuses and display summary counts

- [x] 6.0 Reminder system module (Firebase reminder settings -> local notifications; keep in sync)
  - [x] 6.1 Implement reminder repository that reads reminder settings for tomorrow’s planned tasks
  - [x] 6.2 Schedule local notifications from cached reminder settings immediately on app start
  - [x] 6.3 Keep local schedule in sync when planning/reminder settings change:
    - cancel old notifications
    - schedule new ones
  - [x] 6.4 Implement permissions UX for Android/iOS
  - [x] 6.5 Handle reminder edge cases (time in past; rescheduling rules when plan changes)
  - [x] 6.6 Add debug logging for notification ids and scheduled times to validate sync behavior
  - [x] 6.7 Ensure reminder scheduling works offline using cached settings

- [ ] 7.0 Offline-first sync (offline reads/writes, queue changes, sync without duplicates)
  - [x] 7.1 Implement connectivity detection and a sync orchestrator service
  - [x] 7.2 Define local write queue schema (operation type, entity type, stable id, payload, timestamps)
  - [x] 7.3 Implement sync handlers for each V1 area: planning, timer sessions, scoring, reminder cache
  - [x] 7.4 Ensure idempotency: use stable ids and upsert semantics in Firestore
  - [x] 7.5 Make conflict resolution consistent across entity types (timestamp/version based)
  - [x] 7.6 Optional but recommended: show “pending sync” indicator in UI for debugging
  - [ ] 7.7 Add unit tests for sync ordering + duplicate avoidance

- [ ] 8.0 Verification plan (happy path + offline scenarios + notifications update checks; add basic tests)
  - [ ] 8.1 Unit test timer engine (start/pause/resume/stop -> correct elapsed time)
  - [ ] 8.2 Unit test scoring validation + task state transitions
  - [ ] 8.3 Repository tests for planning CRUD and offline queue -> sync -> load (no duplicates)
  - [ ] 8.4 Widget tests for critical UI flow: Homepage -> Focus/Timer -> scoring -> updated status
  - [ ] 8.5 Mock-based tests for notification scheduling + cancellation behavior on updates
  - [ ] 8.6 Manual QA checklist for iOS/Android for offline completion/scoring and reminder update behavior

## Interaction Model
I generated Phase-2 sub-tasks for each V1 parent task in this file. Tell me which parent task number you want to start implementing first (for example: `1.0`, `1.1`, `2.0`, etc.).

