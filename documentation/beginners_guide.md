# SidePal / Coach for Life: Beginner's Guide

This is a practical map of the repository for a junior developer. Its purpose
is not to make you memorize every file. It is to help you answer these three
questions quickly:

1. **Where does this screen or behaviour live?**
2. **What is the safe path for changing it?**
3. **Where should I investigate when it breaks?**

Read this once from top to bottom, then use the tables and playbooks as your
day-to-day reference. For the deeper architectural reference, see
[`documentation/CODEBASE_GUIDE.md`](CODEBASE_GUIDE.md).

---

## 1. What this app does

SidePal is a personal productivity coach. People can plan tasks and routines,
work through them with focus/timer tools, track goals and progress, receive
reminders and AI coaching, and participate in accountability circles.

The important product promise is **local-first**: normal personal planning
actions should feel instant and should still work offline. The phone's local
database is therefore the UI's main source of data. Firebase synchronizes that
data in the background when a connection is available.

The repository contains two applications:

| Area | Location | Responsibility |
| --- | --- | --- |
| Mobile/desktop/web client | `lib/` | Flutter UI, business logic, local data, sync, notifications |
| Firebase backend functions | `functions/src/` | Trusted server-side operations: AI, stakes/accountability, intentions, speech |

There are also Firebase security rules (`firestore.rules`, `storage.rules`),
their indexes (`firestore.indexes.json`), automated tests (`test/`), product
requirements (`PRD/` and `tasks/`), and engineering documentation
(`documentation/`).

---

## 2. Technologies to learn, in a useful order

Do not try to learn everything at once. Learn enough of each topic to follow a
feature end-to-end, then deepen it while working.

| Priority | Learn | Why it matters here |
| --- | --- | --- |
| 1 | Dart fundamentals: null safety, `async`/`await`, collections, classes, extensions | Almost every source file uses these. |
| 2 | Flutter: widgets, layout, stateful vs stateless widgets, navigation, forms | The client UI is Flutter. |
| 3 | Riverpod 2: `Provider`, `StreamProvider`, `StateProvider`, `ConsumerWidget`, `ref.watch` vs `ref.read` | This is how UI and application state are connected. |
| 4 | Isar | The on-device database and the normal source for reactive UI reads. |
| 5 | Firebase Auth, Firestore, Storage, Cloud Functions, Crashlytics | Authentication, cloud replication, uploads, trusted backend work, crash reports. |
| 6 | Git, Flutter testing, and the Dart analyzer | Required to make small changes safely. |
| 7 | TypeScript, Node.js, Firebase Emulator Suite | Needed when changing `functions/`, rules, or integration tests. |
| 8 | Mobile notifications and platform setup | Needed for reminders, notification taps, push transport, and iOS/Android-specific issues. |

Good official starting points are the Dart language tour, Flutter's first-app
codelab, Riverpod documentation, Isar documentation, and Firebase's Flutter
documentation. Learn them alongside a small change in this app; that is much
more effective than trying to finish every tutorial first.

---

## 3. The big mental model

### 3.1 A feature is usually organized by responsibility

Most substantial features use this shape:

```text
lib/features/<feature>/
  presentation/   screens, sheets, widgets; collects user input and renders UI
  application/    providers, controllers, use cases, orchestration
  domain/         business models and pure rules
  data/           repositories; turns models into local/cloud persistence
```

Not every older or smaller feature has all four folders. For example,
`add_task` is presentation-focused, while `planning` contains the task models,
providers, and repositories it uses. That is normal: follow imports and the
feature's tests rather than forcing a folder pattern that is not already there.

Use the layers this way:

- **Presentation** should decide how to display and collect input, not contain
  Firestore calls or complicated business rules.
- **Application** coordinates a user action or exposes state to widgets.
- **Domain** should be the easiest code to test because it is mostly plain
  Dart and deterministic logic.
- **Data** knows how objects are stored, synchronized, or fetched.

### 3.2 Shared code belongs in `core/`

`lib/core/` is cross-feature infrastructure. The folders you will visit most:

| Folder | Go here when you need… |
| --- | --- |
| `bootstrap/` | to understand startup and what can safely run before/after the first frame |
| `di/` | a shared Riverpod repository/service provider |
| `local_db/` | Isar collection definitions and generated schemas |
| `offline/` | opening or clearing the Isar database |
| `sync/` | outbox writes, queue flushing, cloud pulls, conflict merging |
| `runtime/` | the common schedule-change pipeline and domain events |
| `notifications/` and `push/` | local reminders, notification routing, ledger reconciliation, push setup |
| `firebase/` | Firebase initialization, current-user paths, Firestore client helpers |
| `presentation/` | shared colors, typography/header components, UI helpers |
| `validation/` | shared model validation |

`lib/app/` is app-wide UI composition: the `MaterialApp`, named routes,
navigator key, splash/onboarding/auth gates, lifecycle refresh, and the main
tab shell.

### 3.3 The most important data rule: local first

For synced personal data, use this direction:

```text
User taps Save
  -> validate model
  -> write to Isar in a transaction
  -> Isar watcher updates Riverpod provider
  -> UI redraws immediately
  -> add an operation to the durable sync outbox
  -> background sync sends it to Firestore later
```

The reverse direction is also simple:

```text
Firestore pull -> merge incoming data into Isar -> Isar watchers -> UI redraws
```

The UI should not normally read user-owned planning data directly from
Firestore. That would create a second data path, make offline behaviour worse,
and often cause stale-screen bugs.

The key files are:

- `lib/core/offline/offline_store.dart` — opens the one Isar database.
- `lib/core/sync/outbox_writer.dart` — records local changes that must sync.
- `lib/core/sync/sync_service.dart` — processes the queue and pulls updates.
- `lib/core/sync/remote_isar_merge.dart` — merges remote records into Isar.
- `lib/core/sync/lww_updated_at.dart` — resolves conflicts using
  last-write-wins timestamps.

### 3.4 Two kinds of data exist

Do not assume every feature has identical offline support.

| Data type | Typical approach | Examples |
| --- | --- | --- |
| Personal planning data | Isar first, Firestore replication | tasks, routines, blocks, goals, reminders, analytics |
| Network-inherent data | optimistic UI where appropriate, then network reconciliation | community circles, uploads, AI responses |
| Local-only device state | Isar or preferences only | UI preferences, some AI/memory caches, notification ledger |
| Server-only / trusted work | Cloud Function | AI proxying, payment/stake enforcement, some speech and intention flows |

Before adding data, explicitly decide which row it belongs to. This choice
changes the models, repository, error behaviour, tests, and sync work.

---

## 4. How the app starts and reaches a screen

Start with [`lib/main.dart`](../lib/main.dart). It creates one root Riverpod
`ProviderContainer`, performs a minimal startup phase, renders the app, then
starts slower work after the first frame.

```text
main()
  -> AppBootstrap.initializePreFrame()
       Firebase initialization + open Isar
  -> runApp()
       splash -> onboarding -> auth -> first-launch data gate
       -> lifecycle wrapper -> CoachForLifeApp
  -> AppBootstrap.completeDeferred() after first frame
       notifications, sync, reminder scheduling, maintenance, push setup
```

The first-frame rule is deliberate. Do not add a network request before
`runApp()` just because it is convenient. A slow or unavailable network can
otherwise leave a user staring at a white screen.

`CoachForLifeApp` in [`lib/app/app.dart`](../lib/app/app.dart) configures theme,
the navigator, and named routes. `MainTabShell` in
[`lib/app/presentation/main_tab_shell.dart`](../lib/app/presentation/main_tab_shell.dart)
is the primary shell. Its current five tabs are:

1. Home
2. Goals
3. Accountability
4. Community
5. Profile

The coach is presented as a sheet, not a permanent tab. Other screens use
named routes from `app.dart`. Add Task is also a sheet; begin at
`showAddTaskSheet` in
`lib/features/add_task/presentation/add_task_screen.dart`.

When you cannot find a screen, search for one of these in this order:

```sh
rg -n "Visible text from the screen" lib
rg -n "static const routeName|routeName =" lib
rg -n "Navigator\.push|showModalBottomSheet|showAddTaskSheet" lib
```

---

## 5. A concrete example: saving a task

Following one real flow is the quickest way to understand a codebase.

```text
Add Task sheet
  lib/features/add_task/presentation/add_task_screen.dart
    _onSave()
      -> builds a PlannedTask
      -> PlanningRepository.upsertTask()

Planning repository
  lib/features/planning/data/isar_planning_repository.dart
      -> updates local Isar rows
      -> queues cloud replication using outboxUpsert()

Schedule side effects
  lib/core/runtime/schedule_mutation_coordinator.dart
      -> validates/commits, recomputes dependent state,
         reconciles notifications, publishes a schedule event

Reactive read
  lib/features/planning/application/planned_task_providers.dart
      todayAllTasksRowsProvider
        -> Isar watch stream -> Home/Task UI rebuilds
```

This reveals a useful debugging technique: find the visible action first,
then follow the call one layer at a time. Do not start by reading every file in
`core/`.

Any change to a task, goal, reminder, or time block that changes the schedule
must finish through `ScheduleMutationCoordinator`. It is how the app keeps
derived UI, analytics, and notifications in agreement. Avoid making one
feature manually call another feature's reminder or analytics code.

---

## 6. Repository map: where to go for common work

| If you are changing… | Start here | Then inspect |
| --- | --- | --- |
| App launch, splash, auth gates | `lib/main.dart` | `lib/core/bootstrap/`, `lib/features/auth/presentation/` |
| Routes, tabs, theme | `lib/app/app.dart` | `lib/app/presentation/`, `lib/core/presentation/` |
| Home task list | `lib/features/home/presentation/home_screen.dart` | `features/planning/application/planned_task_providers.dart` |
| Add/edit task behaviour | `features/add_task/presentation/add_task_screen.dart` | `features/planning/domain/` and `data/` |
| Task ranking/routines/planning | `lib/features/planning/` | `lib/features/time_blocks/` |
| Goals | `lib/features/goals/` | `core/runtime/`, `core/sync/` |
| Focus/timer and completion scoring | `lib/features/focus/`, `timer/`, `execution/`, `scoring/` | corresponding tests in `test/features/` |
| Reminders/notification taps | `lib/features/reminders/` | `lib/core/notifications/`, `lib/app/notification_response_handler.dart` |
| AI coach/voice | `lib/features/ai_assistant/` | `lib/core/ai/`, `functions/src/index.ts`, `functions/src/speech.ts` |
| Analytics, insights, coaching delivery | `lib/features/analytics/` | `lib/features/coaching/`, `lib/features/thinking/` |
| Accountability stakes | `lib/features/accountability/` | `functions/src/stakes/` |
| Community circles and messages | `lib/features/community/` | Firestore rules and community tests |
| Sign-in/profile/preferences | `lib/features/auth/`, `profile/`, `settings/` | `core/firebase/` |
| A cloud-sync problem | `lib/core/sync/` | repository write path and `test/core/sync/` |
| Firebase permissions/indexes | `firestore.rules`, `storage.rules`, `firestore.indexes.json` | `rules-tests/`, `documentation/errors.md` |

The source tree is large. It is fine to ignore advanced feature folders until
your work needs them. Start with the current screen, its provider/controller,
its model, and its repository.

---

## 7. How Riverpod is used here

Riverpod makes values and state available without passing them through every
widget constructor.

- A **provider** creates or exposes something: a repository, service, or
  derived value. Shared dependency wiring is in `lib/core/di/providers.dart`.
- A **`StreamProvider`** exposes changing data, usually an Isar watcher.
- In a widget, use `ref.watch(provider)` when the widget should redraw after a
  change. Use `ref.read(provider)` for a one-time action, such as calling Save
  inside a button handler.
- Read `AsyncValue` carefully: it has loading, error, and data states. Shared
  UI helpers include `lib/core/presentation/async_value_ui.dart`.

A common beginner mistake is to call a network service directly from a widget
and then manually force a refresh. In this app, prefer the existing
repository/provider path. A successful local Isar write should naturally
update watchers; it is not necessary to refetch just to make the UI change.

---

## 8. Adding a feature safely

First read `CLAUDE.md` and `documentation/GUIDELINES.md`. They are project
rules, not optional suggestions. Then use this checklist.

### A UI-only feature

1. Find the owning feature folder or create a focused one under `lib/features/`.
2. Reuse `AppColors`, `PageTitle`, `SectionHeader`, and existing shared widgets;
   do not add hard-coded widget colors or a new visual language.
3. Add navigation in `lib/app/app.dart` only if it truly needs a route.
4. Add a widget test if interaction or rendering is meaningful.

### A feature with new personal, synced data

1. Write/adjust the domain model, including a client-generated ID and
   `updatedAtMs` if it syncs.
2. Add an Isar collection under `lib/core/local_db/isar_collections/` and
   register its schema in `isar_schemas.dart`.
3. Regenerate generated files:

   ```sh
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Create a local-first repository: commit to Isar, then queue with
   `outboxUpsert`/`outboxDelete`. Do **not** wait for a Firestore write during
   a tap/save path.
5. Expose reads through an Isar watcher and `StreamProvider`.
6. Add a remote pull/merge phase in `core/sync/remote_isar_merge.dart`, using
   the last-write-wins `updatedAtMs` policy.
7. If the data affects the schedule, route the completed mutation through
   `ScheduleMutationCoordinator`.
8. Add tests for the model/rules, repository, and the important UI path.
9. Verify the feature in airplane mode as well as online.

### A feature needing trusted server logic

1. Keep secrets and privileged authorization checks on the server.
2. Add TypeScript under the appropriate `functions/src/` area; `index.ts`
   exports the functions.
3. Check auth and validate all callable/function input on the server.
4. Update Firestore/Storage rules and indexes only when the data shape/query
   requires it, then add emulator tests.
5. Build and test the Functions project before deployment.

Do not commit or deploy as part of ordinary coding unless you have explicit
permission.

---

## 9. Debugging playbooks

### “I changed something but the screen did not update”

1. Confirm the button handler actually runs (breakpoint/log).
2. Confirm the repository writes to Isar successfully.
3. Find the screen's provider. Is it a watcher-based provider, and is the
   widget using `ref.watch` rather than `ref.read`?
4. Confirm the entity IDs and date/routine filters used by the provider match
   the item you saved.
5. Only after the local flow works, investigate sync. Cloud sync is not needed
   for a same-device UI update.

### “It works online but not offline”

Look for an awaited Firestore request in the interaction path. Personal data
must be committed locally first and put in the outbox. Network-only behaviour
(AI, community, upload) needs an honest retry/error state rather than silently
pretending it completed.

### “My change disappears after sync”

Check these in order:

1. Does the entity carry a fresh `updatedAtMs` timestamp for every update?
2. Does the Isar model encode/decode every field correctly?
3. Is an outbox operation created with the right user/document path and
   payload?
4. Is `RemoteIsarMerge` pulling and merging this entity type?
5. Is an older remote row winning because its timestamp is larger?

### “The app hangs or starts on a blank screen”

Start at `main.dart` and inspect `[boot]` logs. Compare the last breadcrumb to
`AppBootstrap.initializePreFrame`. Keep pre-frame work limited to Firebase and
opening Isar; move network-dependent work to `completeDeferred`.

### “A reminder is missing or opens the wrong screen”

Trace `ReminderIntent` and the attention orchestrator in
`features/reminders/`, then `core/notifications/` for scheduling/ledger state.
For the tap destination, inspect `app/notification_response_handler.dart` and
the notification route resolver.

### “A Firestore query fails in production”

Read `documentation/errors.md` before changing a query. Then check security
rules, the active user's Firestore path, required composite indexes, and
emulator tests. Query/index changes often need a matching change in
`firestore.indexes.json`.

### “It only fails on one account”

Inspect authentication first. Repositories are scoped to the active Firebase
UID. Account switches intentionally clear local session state to avoid showing
one person's data to another; a stale UID or wrong document path is a common
cause of this class of bug.

---

## 10. Tests and routine commands

Run commands from the repository root unless stated otherwise.

```sh
# Get Dart/Flutter packages after dependency changes
flutter pub get

# Static analysis (run before handing off a Flutter change)
flutter analyze

# Dart/Flutter test suite
flutter test

# Regenerate Isar code after changing an @collection model
dart run build_runner build --delete-conflicting-outputs

# Backend Functions: build and test
npm --prefix functions run build
npm --prefix functions test

# Security rules tests (requires Firebase CLI/emulators)
npm --prefix rules-tests test

# End-to-end stake tests (requires Firebase CLI/emulators)
npm --prefix integration-tests test
```

Tests mirror source ownership. For example, a task-ranking change should lead
you to `test/features/planning/`; a queue/sync change belongs near
`test/core/sync/`; an Isar schema change should include a local-database or
repository test. The architectural guard
`test/architecture/local_first_guard_test.dart` protects the most important
rule: interaction-path Firestore writes must not be awaited.

When running locally, do not “fix” unrelated changes you see in `git status`.
This repository may already contain another developer's work. Narrow your
review to the files you intentionally changed.

---

## 11. A first-week learning plan

### Day 1: Run and navigate

- Read `README.md`, this guide, and `CLAUDE.md`.
- Run the app with the team's configured Firebase environment.
- Click through Home, adding a task, Goals, Accountability, Community, and
  Profile. Keep a note of what each screen is for.
- Follow `main.dart` -> `app.dart` -> `MainTabShell` in the editor.

### Day 2: Follow one task end-to-end

- Read `add_task_screen.dart` around `_onSave`.
- Follow `PlanningRepository.upsertTask` into `IsarPlanningRepository`.
- Read `todayAllTasksRowsProvider` and locate a widget that watches it.
- Read the matching planning tests before editing anything.

### Day 3: Understand local-first sync

- Read the five key sync files listed in section 3.3.
- Make a harmless local task edit and observe that the UI changes before the
  network is relevant.
- Read the local-first architecture guard test.

### Day 4: Make a small, reviewable UI change

- Change existing copy, spacing, or a clearly isolated visual detail.
- Reuse tokens/components and add/adjust one relevant test.
- Run analysis and the smallest relevant test file first.

### Day 5: Explore one advanced vertical

Pick AI, notifications, analytics, or accountability. Start from its visible
screen, then map presentation -> application -> data/domain -> tests. You do
not need to understand all advanced systems before becoming productive.

---

## 12. Rules worth memorizing

1. **For user-owned synced data, Isar is the local truth; Firestore is the
   background replica.**
2. **Never make a tap wait for Firestore `set` or `delete`.** Write locally,
   enqueue sync, and let the UI react to Isar.
3. **A synced entity needs a consistent package:** local model/schema,
   repository/outbox write, watcher provider, remote merge, and tests.
4. **Every synced update needs a new `updatedAtMs`.** Conflicts are
   last-write-wins, not field-by-field merges.
5. **Do not put slow network work before `runApp`.** First frame matters.
6. **Schedule changes use `ScheduleMutationCoordinator`.**
7. **Reuse the design system.** Use `AppColors` and shared header components;
   do not introduce random hard-coded styles.
8. **Keep secrets out of the Flutter client.** Privileged logic belongs in
   Cloud Functions and must validate callers.
9. **Read existing tests before changing an unfamiliar behaviour.** They are
   often the clearest statement of an intended edge case.
10. **For a meaningful product/architecture decision, update the decision log
    in `documentation/GUIDELINES.md`.**

If you remember only one approach, use this: begin at the user-visible screen,
follow the action into the provider/repository, and then find the corresponding
test. That gives you a small, reliable slice of the system without getting
lost in the whole repository.
