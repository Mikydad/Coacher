# Performance Optimization Pass — July 2026

This documents the performance work done on 2026-07-05, from the original
audit through every fix: what was wrong, why it mattered, how it was fixed,
and how the code behaves now. Read this before touching the timer, boot,
or task-provider code paths — several fixes encode invariants that are easy
to accidentally undo.

**Origin:** the findings come from the repo-wide performance audit recorded
in [AUDIT.md §5](AUDIT.md) (audited 2026-07-02, report-only at the time).
On 2026-07-05 every finding was re-verified against the current code and
then fixed one by one. All fixes were verified with the full test suite
(985 tests) after each change.

---

## 1. Home screen rebuilt every second during a focus session

**Severity:** HIGH · **Status:** fixed

### What was wrong

`TaskTimerEngine` emits a snapshot every second while a focus timer runs,
and `ExecutionController` copies it into its Riverpod state — including the
`elapsed` field, which changes on every tick. Three widgets/providers
watched the *whole* state object:

- `home_screen.dart` — top of the `HomeScreen` build
- `focus_selection_screen.dart` — top of the screen build
- `delivery_providers.dart` — `layer4IsActiveFocusFlowProvider`

A whole-object watch means "rebuild me when *anything* in this object
changes", so each 1-second tick invalidated the entire home Scaffold
(analytics card, goals, task sections — everything), the entire focus
selection screen, and the layer-4 provider subgraph. At the time of the
audit, `.select(` appeared **zero** times in the whole repo — Riverpod's
primary rebuild-scoping tool was simply unused.

### How it was fixed

- Added a derived getter on `ExecutionState`
  (`lib/features/execution/application/execution_controller.dart`):

  ```dart
  /// True while a task focus session is running or paused.
  bool get hasActiveFocusTask =>
      targetType == TimerSessionTargetType.task &&
      taskId.isNotEmpty &&
      (phase == ExecutionPhase.inProgress || phase == ExecutionPhase.paused);
  ```

  This derivation was previously copy-pasted at four call sites; it now
  lives in one place.

- **HomeScreen** ended up needing *no* execution watch at all. The build
  only used the state for the derived bool and for the Focus button's
  launch arguments — the button now does `ref.read(...)` at press time,
  which is also more correct (arguments reflect the state at the moment of
  the tap, not at the last rebuild).

- **FocusSelectionScreen** watches only the bool:
  `ref.watch(executionControllerProvider.select((s) => s.hasActiveFocusTask))`.
  Its `_selectTask` used to receive a state snapshot from build time; it
  now reads fresh state when the user taps a task.

- **`layer4IsActiveFocusFlowProvider`** selects the derived bool directly,
  so it recomputes only when the active/inactive answer actually flips.

### What deliberately did NOT change

Two widgets still watch the whole state, on purpose:

- `_FlowNowStrip` in `home_screen.dart` — the small (~72 px) home strip
  **renders live elapsed time and a progress ring**, so per-second
  rebuilds are its job. The audit originally missed this. The point of the
  fix is that the per-second rebuild is now contained to this small
  subtree instead of the whole Scaffold.
- `timer_session_screen.dart` — the full-screen timer; same reason.

### How it works now

While a timer runs, exactly two small widgets rebuild per second (the
strip and, if open, the timer screen). Everything else rebuilds only on
phase changes (start/pause/resume/finish) or task switches. Rule for
future code: **never `ref.watch(executionControllerProvider)` whole unless
the widget displays `elapsed`; watch
`.select((s) => s.hasActiveFocusTask)` or the specific fields you need.**

---

## 2. Disk write on every timer tick

**Severity:** HIGH · **Status:** fixed

### What was wrong

The same per-second engine listener called `runtimeCache.save(...)`
(unawaited) on every tick — serializing the full resume state to a JSON
file with `flush: true`, 60×/minute, for the entire session. Continuous
storage I/O for the whole focus session: battery drain, flash wear, jank
risk on slow storage.

### Why the writes were pointless

The resume file stores `elapsedMs` *and* `runningSinceMs`. The restore
path (`TaskTimerEngine.restore` → `_currentElapsed()`) computes:

```
current elapsed = saved elapsed + (now − runningSince)
```

So a save taken **once at a phase transition** restores correctly no
matter how much later the app comes back — even if the process is killed
20 minutes after the last write. The per-second writes bought zero
durability.

### How it was fixed

`ExecutionController` now persists only when the **session shape**
changes. The listener computes a signature over
`(targetType, taskId, blockId, taskLabel, blockLabel, phase,
targetDurationMinutes)` — everything *except* `elapsed` — and calls
`runtimeCache.save` only when the signature differs from the last saved
one (`_persistIfSessionShapeChanged`).

Behavioral equivalence notes:

- While **paused** there are no ticks, so the old code didn't save on
  label changes during pause either — no regression there.
- Saves still happen on start, pause, resume, task/block switch, and
  restore-echo — the same moments that matter for resume correctness.

### How it's verified

`test/features/execution/execution_controller_block_timer_test.dart` has a
`fake_async` test ("persists on phase transitions, never on per-second
ticks") that starts a session, elapses 5 simulated seconds, and asserts
the save count did not move; pause then adds exactly one save.
(`fake_async` was added to `dev_dependencies` for this — it was already in
the tree transitively via `flutter_test`.)

---

## 3. First frame blocked on network calls in bootstrap

**Severity:** HIGH · **Status:** fixed

### What was wrong

`main()` awaited `AppBootstrap.initialize(container)` in full before
`runApp`. That single awaited call chained: Firebase init → anonymous
sign-in (network) → notifications init (incl. iOS permission prompt) →
Isar open → sync-queue load → reminder scheduling → **a Firestore goals
fetch** → goal reminder sync → a Firestore retention prune. On a slow
connection the user stared at the native splash for multiple seconds.
Only Firebase init and the Isar open genuinely need to precede the first
frame.

### How it was fixed

`AppBootstrap` (`lib/core/bootstrap/app_bootstrap.dart`) is now split:

- **`initializePreFrame`** — awaited before `runApp`. Firebase (Crashlytics
  and AuthGate depend on it), the Isar store (first screens read from it),
  and attaching the `ScheduleMutationCoordinator`. Nothing network-bound.
- **`completeDeferred`** — kicked off from `main.dart` in an
  `addPostFrameCallback` after `runApp`. Notification wiring + cold-start
  tap drain, notification reconciliation, sync-service init, reminder
  scheduling, AI-history purges, community bridges, and the per-user
  Firestore maintenance (goals fetch, goal reminder sync, retention
  prune).

Crashlytics is installed right after the pre-frame phase, so crash
coverage now starts *earlier* than before (it used to wait behind the
whole bootstrap).

### The auth race — important invariant

The old bootstrap called `AuthInitializer.ensureSignedIn()` (anonymous
sign-in) before the per-user work. But `AuthGate` **also** triggers
anonymous sign-in when it sees a signed-out state in guest mode. Running
both concurrently after the split could create **two different anonymous
accounts**; the loser would be detected as a uid change and trigger the
local-data wipe in `AuthGate`.

So the deferred phase **never signs in**. `_awaitSignedInUser()` waits for
the user AuthGate produces (`authStateChanges().firstWhere(u != null)`
with a 30 s timeout for offline boots), and skips the per-user work if
none arrives. In registered-auth mode with no persisted session it skips
immediately — the landing screen is showing and no sign-in is imminent,
which matches the old behavior of skipping per-user work when signed out.

**Do not add a sign-in call to bootstrap.** AuthGate owns sign-in.

### Cold-start notification taps

`drainLaunchNotificationResponse` moved to the deferred phase. This is
safe because the plugin retains the launch response until drained, and
navigation from a tap was already deferred internally until a navigator
exists. Handling now happens one frame later than before — imperceptible.

### How it works now

First frame = Firebase init + Isar open, full stop. AuthGate's spinner
("Loading your plan…") covers the async tail. A slow or dead connection
can no longer hold the splash hostage.

---

## 4. Morning-brief side effect inside build()

**Severity:** MEDIUM · **Status:** fixed

### What was wrong

`_maybeTriggerMorningBrief(context, ref)` ran on **every** HomeScreen
rebuild. Worse than the audit stated: it had no "already shown today"
guard at all — during the 06:00–10:00 window, every rebuild scheduled
another post-frame callback and queued another snackbar (only suppressed
once the user actually opened the coach tab that day).

### How it was fixed

A file-level `_morningBriefShownForDateKey` guard in `home_screen.dart`:
checked first thing after the time-window test, set when the snackbar is
actually scheduled (i.e., after the enabled-preference check passes, so a
not-yet-loaded preference doesn't burn the once-per-day slot). The call
stays in build — after the guard, the per-rebuild cost is one
`DateTime.now()` and two string compares — but it can fire at most once
per day per app session.

---

## 5. Community images: full-res decode and uncompressed uploads

**Severity:** MEDIUM · **Status:** fixed (minimal variant)

### What was wrong

- `circle_chat_view.dart` rendered proof images with a bare
  `Image.network(width: 220)`. Without decode sizing, each ~1080 px source
  is decoded at full resolution for a 220-logical-px bubble — several MB
  of RAM per visible message.
- The **challenge** proof picker (`circle_challenges_view.dart`) set no
  `imageQuality`/`maxWidth`, so original camera photos (up to the 10 MB
  storage-rules limit) were uploaded raw and re-downloaded full-size by
  every circle member. The **chat** picker was already correct
  (quality 70 / maxWidth 1080).

### How it was fixed

- Chat image: `cacheWidth: (220 * devicePixelRatio).round()` — decodes at
  display size.
- Challenge picker: same compression settings as the chat picker
  (`imageQuality: 70, maxWidth: 1080`).

### Known remaining gap

Flutter's image cache is memory-only, so proof images still re-download
once per app session. The full fix is adopting `cached_network_image`
(disk cache); we chose not to add the dependency in this pass. If feeds
get heavier, that's the next step.

---

## 6. Two providers recomputed the same task list forever

**Severity:** MEDIUM · **Status:** fixed

### What was wrong

`todayAllTasksRowsProvider` (hub/home task list) and
`homeFlowSnapshotProvider` (home "flow now" strip: current block label,
open count, next task) each ran their **own** three Isar `watchLazy`
subscriptions plus their **own** 1-minute `Timer.periodic`, and each
emission independently re-read routines + blocks + tasks from Isar and
re-ran prioritization. Identical inputs, duplicate heavy work, running
forever (both providers are pinned by the bootstrap bridge).

They also computed subtly *different* answers: the snapshot path skipped
the `routine.dateKey` and `planDateKey` guards that the hub's
`collectTodayPlannedRows` applies, so home could count stale tasks the
hub filtered out.

### How it was fixed

`homeFlowSnapshotProvider` no longer touches Isar watchers or timers. It
derives from `todayAllTasksRowsProvider` via `ref.listen(...,
fireImmediately: true)` inside the stream builder
(`lib/features/planning/application/planned_task_providers.dart`):

- On each upstream emission, `_snapshotFromTodayRows` filters the
  already-prioritized rows to open ones (`taskIsOpenForHub`), picks the
  first row passing `isTaskAvailableForFocusNow` as the next task, and
  does one cheap routines→blocks read for the current-block label.
- No re-prioritization: the upstream rows are already in prioritized
  order, so the "next task" is by construction the same task the hub
  shows first — the invariant asserted by
  `test/features/planning/prioritized_order_consistency_test.dart`.

### How it works now

One watcher set, one 1-minute timer, one heavy recompute per change —
then a light derivation for the snapshot. The 1-minute cadence for the
block-label/time-window updates is inherited from the upstream timer.

---

## 7. Full provider refresh after every sync pull, even no-ops

**Severity:** LOW · **Status:** fixed

### What was wrong

Every successful Firestore → Isar pull (as often as every 30 s from the
connectivity listener / periodic sync) called
`PostSyncRefreshCoordinator.scheduleAfterSuccessfulRemotePull()`, which
invalidates the task-list providers **and** schedules a full
analytics/coaching recompute via `UnifiedRecomputeGraph` — regardless of
whether the pull changed a single row. The common case (nothing changed
remotely) paid the full recompute price anyway.

### How it was fixed

- `mergePlannedTaskLwwIntoIsar` (`lib/core/sync/isar_lww_merge.dart`) now
  returns `bool` — true only when the incoming row won LWW and was
  written.
- `RemoteIsarMerge` counts applied rows across all seven collections
  (routines, blocks, tasks, reminders, goals, analytics events, analytics
  stats); `run()` returns `_appliedCount > 0` and logs the count.
- `SyncService._runRemotePull` schedules the post-sync refresh only when
  the pull succeeded **and** applied at least one row. The
  `debugRemotePullForTests` override path conservatively keeps
  `appliedAny = true` since it can't report.

### How it works now

A 30-second heartbeat pull that finds nothing new is silent: no provider
invalidation, no recompute-graph run, no UI loader flashes. Any pull that
actually changes local data refreshes exactly as before.

---

## Deliberately not done

- **`ListView` → `ListView.builder` in four community views**
  (`circle_members_view`, `weekly_commitments_view`,
  `circle_activity_view`, `circle_discovery_screen`). The audit itself
  scoped this as "when list sizes become user-controlled" — today the
  backing queries are capped (50 messages / 30 feed items), so the impact
  is bounded. Convert them if those caps are lifted.
- **`cached_network_image`** — see §5's known remaining gap.

## Verification summary

- `flutter analyze` on every touched file: no new issues (all remaining
  warnings/infos pre-existed; confirmed by stash-and-reanalyze).
- Full `flutter test` suite run after each fix: 985 tests passing,
  including one new test (§2's tick-persistence test).
- The hub/focus/home consistency test passes against the derived snapshot
  provider (§6), which it now guarantees structurally.
