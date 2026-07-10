# Coach for Life — Codebase Guide for New Developers

This guide teaches you how the app works: the flow, the data, where things live,
and where to look when something breaks. Read it top to bottom once, then use
the playbooks (§9) and recipes (§10) as reference.

---

## 1. What this app is

A **local-first productivity coach** for iOS (Android is not configured yet).
Users plan tasks into daily routines, execute them with a focus timer, self-score
their completion, track goals, get AI coaching, and join accountability "circles."

**Stack:**

| Layer | Technology |
|---|---|
| UI / state | Flutter + Riverpod 2 (hand-written providers — **no** codegen, no freezed, no get_it) |
| Local DB | Isar (`isar_community` 3.3.2) — the app's primary datastore |
| Backend | Firebase: Auth, Firestore (sync target), Storage (images), Remote Config, Crashlytics |
| AI | One Cloud Function `aiChat` (functions/src/index.ts) proxying OpenAI `gpt-4o-mini` |
| Notifications | `flutter_local_notifications` only — **there is no FCM/push** |

The only codegen is Isar's (`dart run build_runner build` regenerates the
`.g.dart` schema files after editing any `lib/core/local_db/isar_collections/` class).

---

## 2. The five principles (your mental model)

Almost every design decision in this codebase follows from these. Internalize
them and the rest of the code becomes predictable.

### P1 — Isar is the source of truth on device; Firestore is the sync target
The UI **never** renders from Firestore directly (for user-owned data). Writes go
to Isar first; reads come from Isar watchers. Firestore is where data goes to be
backed up and to reach other devices. If the network is gone, the app fully works.

### P2 — Writes try the network inline, and queue only on failure
Every synced repository does:
```dart
try { FirebaseFirestore...set(payload, SetOptions(merge: true)); }
catch (_) { SyncService.instance.enqueueUpsert(...); }   // outbox on disk
```
The queue (`offline_sync_queue.json` in app documents) is a *failure-recovery
outbox*, not a write-ahead log. It flushes on connectivity restore, app resume,
and boot. See `lib/features/planning/data/isar_planning_repository.dart:29`.

### P3 — Conflicts resolve by Last-Write-Wins on `updatedAtMs`
Whole-document, strictly-greater timestamp comparison
(`lib/core/sync/lww_updated_at.dart`). No field merging, no conflict UI. Every
synced entity carries `updatedAtMs`; forget to bump it and your write loses.

### P4 — The first frame is sacred
Boot is split in two (`lib/core/bootstrap/app_bootstrap.dart`):
`initializePreFrame` does only Firebase init + Isar open (both local/fast);
`completeDeferred` does everything network-bound *after* the first frame.
Anything that can block on network before `runApp` has historically produced
permanent white screens. Never add awaits to the pre-frame phase.

### P5 — Schedule mutations flow through one pipeline
Any write that changes the schedule (task/goal/reminder/time-block) finishes by
calling `ScheduleMutationCoordinator.instance.run(...)`
(`lib/core/runtime/schedule_mutation_coordinator.dart:44`) with a typed mutation.
The pipeline is: **Validate → Commit → recompute providers (`UnifiedRecomputeGraph`,
debounced 400ms) → reconcile notifications → publish `ScheduleDomainEvent`**.
Features never call each other's analytics/notification code directly — they
publish through this pipeline. When adding a write path, end it here.

---

## 3. What happens when the app starts

All in `lib/main.dart`, inside `runZonedGuarded`:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Create the single root `ProviderContainer` → stored in the global
   `appRootProviderContainer` so non-widget code (notification handlers,
   singletons) shares provider state with the widget tree.
3. **`AppBootstrap.initializePreFrame`** — Firebase Core init, then
   `OfflineStore.instance.initialize()` which calls **`Isar.openSync`**
   (deliberately synchronous: async `Isar.open` hangs on iOS AOT builds —
   see `lib/core/offline/offline_store.dart:35`), then attaches the
   `ScheduleMutationCoordinator` to the container.
4. Load persisted brightness (local disk) so the theme never flashes.
5. Enable Crashlytics with a **4-second timeout** — this call once hung forever
   on-device and white-screened the app (`documentation/errors.md` #19).
6. `runApp` with this gate hierarchy (outer → inner):

```
UncontrolledProviderScope
 └─ AnimatedSplashGate        fixed ~3.4s splash; real app builds behind it
     └─ AuthGate              signed in → child; else anonymous sign-in or login UI;
                              detects uid CHANGES and wipes local state (see §8)
         └─ FirstLaunchGate   first install: blocks on a forced full remote pull
                              so the UI is never empty (pref key: isar_seeded_v1)
             └─ AppLifecycleTaskRefresh   on resume: sync, day-rollover refresh
                 └─ CoachForLifeApp       the MaterialApp
```

7. **After the first frame**: `AppBootstrap.completeDeferred` — notification
   wiring + cold-start tap drain, notification-ledger reconciliation,
   `SyncService.initialize()` (first pull + queue flush), reminder scheduling
   from cache, AI-history pruning, community bridges. It deliberately **never
   signs in** — AuthGate owns sign-in (a second sign-in path once created
   duplicate anonymous accounts and triggered data wipes).

Boot problems are traced with `[boot]` breadcrumbs — plain `print()`, not
`debugPrint`, because `debugPrint` is silenced in release. A hang between two
breadcrumbs localizes itself in device logs.

---

## 4. Data flow — the life of a write and a read

### Navigation first (30 seconds)
Plain `Navigator` with named routes (no go_router). Six tabs live in one
`IndexedStack` inside `MainTabShell` (route `/`), switched by
`mainTabIndexProvider` (`lib/app/application/main_tab_navigation.dart`):
**Home, Coach (AI), Goals, Progress (analytics), Community, Profile**.
Everything else is a named route pushed on top (route table:
`lib/app/app.dart:110`). A global `appNavigatorKey` lets notification handlers
navigate without a BuildContext.

### The write path (example: saving a task)

```
AddTaskScreen._onSave                    add_task_screen.dart:948
  → builds PlannedTask (domain model)    planning/domain/models/task_item.dart
  → planningRepositoryProvider.upsertTask
      (DI: core/di/providers.dart — IsarPlanningRepository wrapping Firestore repo)
  → task.validate()                      throws ArgumentError; the ONLY validation gate
  → stamp updatedAtMs = now
  → Isar writeTxn: putByTaskId(...)      ← UI updates from here (watchers fire)
  → try Firestore set(merge:true) at users/{uid}/routines/{r}/blocks/{b}/tasks/{id}
      catch → SyncService.enqueueUpsert  ← offline outbox
  → ScheduleMutationCoordinator.run(TaskCreatedMutation…)   ← side-effect fan-out
```

### The read path (how the UI sees data)

```
Isar watchLazy() on tasks/routines/blocks collections
  → re-collect + prioritize rows
  → todayAllTasksRowsProvider (StreamProvider)     planning/application/planned_task_providers.dart:186
  → HomeScreen / TasksHubScreen watch it
```

Key point: the UI is reactive **purely off Isar**. When a remote pull merges
rows into Isar, the same watchers fire — there is no separate "remote data"
path into the UI. A 1-minute timer also re-emits to handle time-based
reprioritization ("task became overdue") with no data change.

### Sync: when and how

- **Push** (`SyncService.processQueue`): connectivity restore, app resume, boot.
  Ops tagged with a foreign uid are dropped (protects against account-switch replay).
- **Pull** (`SyncService.syncFromRemote`): same triggers, debounced to once per
  30s, one-shot `.get()` queries (no Firestore listeners), 60s total timeout.
  Incremental via per-collection cursors (`where('updatedAtMs', > cursor)`),
  stored in SharedPreferences. `force: true` ignores cursors (first launch,
  account switch). The pull **aborts if the uid changes mid-flight**.
- After a pull that changed anything, `PostSyncRefreshCoordinator` (450ms
  debounce) invalidates the non-stream providers. No-op pulls are silent.

### Know the persistence split — it explains many "why is my data gone" questions

| Data | Storage | Offline durability |
|---|---|---|
| Tasks, routines, blocks, reminders, goals, analytics | **Isar + Firestore** (full local-first) | Strong |
| Timer sessions (`execution`), task scores (`scoring`) | **Firestore only** (queue fallback on failure) | Weaker — no local mirror |
| AI coaching caches, delivery history, coaching style, profile prefs, notification ledger, AI chat history | **Isar only** — never synced | Lost on reinstall/device switch |
| Community/circles | **Firestore only**, live from network | None |

Two Isar collections (`IsarActivityFeedCache`, `IsarAiPulseCache`) are
registered but **dead code** — nothing reads or writes them.

### Firestore layout & rules (the short version)
All user data: `users/{uid}/...` guarded by one blanket rule
(`request.auth.uid == uid`) — there is **no server-side field validation** for
planning data; client-side `validate()` is the only guard. Circles are
top-level `circles/{circleId}/...` with per-subcollection rules. Full paths:
`lib/core/firebase/firestore_paths.dart`; rules: `firestore.rules`.

---

## 5. The domain loop: create → plan → execute → score

This is the heart of the app. `planning` is the hub feature — almost everything
else reads/writes through `planningRepositoryProvider`.

**The model hierarchy for a day:**
```
Routine (dateKey: "2026-07-10", mode: flexible/disciplined/extreme)
 └─ TaskBlock (ordered, optional start/end time)
     └─ PlannedTask (title, duration, priority, status, planDateKey, modeRefId…)
```
`PlannedTask.planDateKey` is the authoritative "which day" field — not the
parent routine's dateKey.

**1. Create** — `AddTaskScreen` (features/add_task/) builds a `PlannedTask` and
saves via the planning repo. Saving also derives a `ScheduledTimeBlock`
(features/time_blocks/) used for overlap/conflict detection across tasks,
habits, and goals.

**2. Plan** — `PlanTomorrowScreen` ensures three default routines
(Morning/Afternoon/Night) for tomorrow and reuses `AddTaskScreen` to place
tasks into slots (`plan_tomorrow/application/plan_tomorrow_providers.dart`).

**3. Execute** — `FocusSelectionScreen` seeds the single global
`executionControllerProvider` (a `StateNotifier` wrapping the pure
`TaskTimerEngine` state machine: notStarted/inProgress/paused/finished).
`TimerSessionScreen` drives start/pause/stop. Elapsed time is in-memory,
mirrored to `TimerRuntimeCache` on phase changes for crash recovery. Stopping
persists a `TimerSession` (Firestore-only).

**4. Score** — there is **no computed score algorithm**. After a session (or a
Home-screen check-off), `ScoreTaskDialog` asks the user for 0–100% + optional
reason (required in stricter modes). `ScoringController.submit` writes a
`TaskScore` to Firestore. Then — separately, from the *screen*, not
transactionally — the task's status is flipped: ≥100% → `completed`, else
`partial`. The "discipline score" on Home is a different thing entirely: a
derived weekly completion percentage from analytics.

**Goals** are deliberately decoupled: `PlannedTask` has **no** `goalId`. Goals
relate to tasks only through shared time-block conflict detection and the
habit-anchor aggregator. Goal progress (actions/check-ins/milestones) is
self-contained in `features/goals/`.

---

## 6. Map of the codebase

```
lib/
├─ main.dart                 boot (§3)
├─ app/                      MaterialApp, tab shell, gates, notification tap routing
├─ core/
│  ├─ bootstrap/             two-phase startup (P4)
│  ├─ di/providers.dart      composition root — cross-cutting repo/service providers
│  ├─ runtime/               ★ the mutation pipeline (P5) — read these 6 files early
│  ├─ sync/                  ★ SyncService, queue, RemoteIsarMerge, LWW, cursors
│  ├─ local_db/isar_collections/   every Isar collection + isar_schemas.dart
│  ├─ offline/               OfflineStore (Isar open/wipe), connectivity
│  ├─ firebase/              FirestoreClient (uid pinned at construction), FirestorePaths
│  ├─ notifications/         LocalNotificationsService, ledger reconciliation
│  ├─ ai/                    AiProxyClient (calls the aiChat function), remote-config kill switch
│  ├─ presentation/          theme (app_colors.dart), shared widgets
│  └─ validation/            ModelValidators used by domain .validate()
└─ features/<name>/
   ├─ domain/                models + pure logic (no Flutter, no Firebase)
   ├─ data/                  repositories (Isar and/or Firestore impls)
   ├─ application/           providers, controllers, services  ← state lives here
   └─ presentation/          screens + widgets
```

**Feature importance tiers:**
- **Tier 1 (the core loop, understand deeply):** `planning` (the hub),
  `add_task`, `execution`, `scoring`, `time_blocks`, `home`
- **Tier 2 (big subsystems):** `ai_assistant`, `reminders` + `core/notifications`,
  `goals`, `analytics`, `auth`
- **Tier 3 (self-contained):** `community`, `education`, `feedback`,
  `context_override`, `settings`, `profile`, `focus`, `timer`, `tasks_hub`,
  `plan_tomorrow` (thin UI layers over Tier 1)

**Provider conventions:** feature providers live in
`features/<x>/application/<x>_providers.dart`. User-scoped providers must
`ref.watch` (never `ref.read`) `firestoreClientProvider` / `authStateProvider`
so they rebuild on account switch — `ref.read` here has caused cross-user data
bugs (AUDIT §3). Plain-Dart singletons (`SyncService`, `OfflineStore`,
`ScheduleMutationCoordinator`…) bridge into Riverpod by holding the root
`ProviderContainer`.

---

## 7. The AI coach and notifications (how the "smart" parts work)

### AI pipeline
One Cloud Function, `aiChat` (`functions/src/index.ts`), is the **only**
deployed function. OpenAI key lives in Secret Manager; model pinned server-side
(`gpt-4o-mini`); per-uid rate limit 40/hour; anonymous accounts rejected
(guests see a sign-in nudge instead of Coach AI).

Client flow (`features/ai_assistant/application/`):
```
sendMessage → fast paths (yes/no plan replies, feature-guide questions — no LLM)
  → AiPayloadAssembler.assemble   ← gathers tasks, goals, schedule, free windows,
                                    behaviour stats, last 10 chat turns (30s cache)
  → ProxyAiOperatingLayerClient   ← tool-calling loop (max 3): propose_changes
                                    (writes) + get_day_schedule (reads)
  → sanity passes: missing fields, assumptions, dedupe, conflicts
  → preview card — NOTHING is written until the user taps Confirm
  → AiActionExecutor.execute (with snapshot-based undo)
```
The "AI never writes directly" rule is prompt-enforced, not structural — hence
the undo mechanism. Chat history is Isar-only, purged after 48h. A Remote
Config bool `ai_enabled` swaps in a mock client as a kill switch.

### Notifications & reminders (all local — no FCM)
- `LocalNotificationsService` (core/notifications/) wraps the plugin.
  **Timezone setup is load-bearing**: skipping `tz.setLocalLocation` was the
  root cause of reminders silently not appearing.
- Reminders are never fire-and-forget: `ReminderSyncService` computes the next
  fire time, then `AttentionOrchestratorService` (features/reminders/) decides
  **approved / batched / delayed / suppressed** based on context overrides
  (focus/sleep), collisions, coaching style, and ignore counts.
- Every scheduled notification is written to an Isar **ledger**; at each cold
  start `NotificationReconciliationService` diffs the OS tray against the
  ledger and repairs both directions.
- Tap routing: single entry `handleNotificationResponse`
  (`lib/app/notification_response_handler.dart:210`). Payload prefixes route:
  `task:` → focus timer, `goal:` → goal detail, `layer4:` → progress/insight,
  `circle:` → circle. If the navigator isn't ready, the intent is persisted to
  prefs and flushed after boot. Fallback chain when payload is lost:
  payload → persisted id→task index → reminder-table scan.

---

## 8. Auth and the account-switch danger zone

Supported: anonymous (guest), Google, Apple, email/password — with
anonymous→registered account *linking*. `kRequireRegisteredAuth`
(a `--dart-define`) gates guest mode.

**Account switching is the most dangerous flow in the app.** Because Isar,
SharedPreferences, the sync queue, and many in-memory providers are all
per-user, a uid change must wipe *everything*, in the right order.
`AuthGate` detects the change and runs:

1. `invalidateUserScopedProviders(ref)` — in-memory state Isar-wiping can't
   reach (AI chat history, timer state, onboarding controller…). File:
   `features/auth/application/user_scoped_invalidation.dart`.
2. `AuthSessionPolicy.clearLocalSession()` — cancel all OS notifications, wipe
   every Isar collection, clear sync queue **and** sync cursors, scrub specific
   prefs keys.
3. Restart community bridges, then a **forced** full remote pull for the new uid.

**If you ever add per-user state in a new place (a prefs key, a non-autoDispose
provider, a singleton cache), you must register it in one of those two wipe
paths — nothing does it automatically.** Most historical cross-user data-leak
bugs (AUDIT §3) came from missing exactly this.

---

## 9. When something breaks — playbooks

### White screen at launch (release/profile iOS)
The classic. Three known causes, all documented in `documentation/errors.md`:
1. **Crashlytics urgent mode** blocking the main thread (#19) — mitigated by
   plist-disable + runtime enable with 4s timeout in main.dart.
2. **Isar FFI symbols dead-stripped** by the release linker (#20) — requires
   `DEAD_CODE_STRIPPING = NO` in `ios/Flutter/Release.xcconfig`. Debug works,
   release hangs — check this first after touching iOS build config or Isar.
3. Anything newly awaited before the first frame (violates P4).

**Method:** read the `[boot]` breadcrumbs in the device console. The hang is
between the last printed breadcrumb and the next expected one.

### A button/action "does nothing"
Historically this has been a **swallowed exception**, most often a Firestore
composite-index error: an equality `where()` + `orderBy()` on a different field
throws `failed-precondition`, and a generic `catch` eats it (errors.md #16,
#18 — it happened three times). Codebase convention: **query on a single field,
sort client-side**. Check the debug console for `[cloud_firestore/...]` and
suspect any new query mixing filters and sorts.

### Data missing / stale / resurrected
- Check `SyncService.pendingCount` and `offline_sync_queue.json` — writes may be
  queued.
- Remember the LWW blind spots: cursor pulls **never see remote deletions**
  (deleted docs resurrect or linger), and a clock-skewed device writes
  timestamps below the cursor (invisible until a `force` pull).
- Wrong user's data → §8; check `invalidateUserScopedProviders` and prefs wipe
  lists first.
- Timer sessions / scores missing offline → expected; they're Firestore-only.

### Reminder never fired / tap went nowhere
Follow the checklist in
`documentation/isar-local-first-and-notification-routing.md` §5. Short version:
grep logs for `[NotifTap]`; check the attention orchestrator didn't *suppress*
it (that's a feature); verify timezone init; check the notification ledger.

### Crash in the wild
Crashlytics is wired in `main.dart` (FlutterError + PlatformDispatcher + zone).
For anything schedule-related, the mutation almost certainly flowed through
`ScheduleMutationCoordinator.run` — its pipeline stages are the natural
breakpoint spots.

### `flutter test` weirdness
- Isar in VM tests: use `test/support/isar_test_harness` and `debugIsarOverride`.
- `No Firebase App '[DEFAULT]'` → a test touched real Firebase; use
  `fake_cloud_firestore`.
- Queue-persistence failures → set `SyncService.debugSkipQueuePersistenceForTests`.

---

## 10. How to add things — recipes

### A new synced entity (the full pattern)
1. Domain model in `features/<x>/domain/models/` with `id`, `updatedAtMs`, and
   a `validate()` using `ModelValidators`.
2. Isar collection in `core/local_db/isar_collections/` (auto-increment `Id` +
   unique string domain id + `updatedAtMs` index), register it in
   `isar_schemas.dart`, run `dart run build_runner build`.
3. Add the path to `FirestorePaths` (under `users/{uid}/...` — the blanket rule
   covers it; add narrower rules only for shared data).
4. Repository: Isar impl wrapping a Firestore impl, copying the
   try-Firestore-else-enqueue pattern **exactly** (uid-tagged ops, paths via
   `FirestorePaths`) — it is *not* centralized; forgetting the enqueue fallback
   silently drops offline writes.
5. Add pull support in `RemoteIsarMerge` (cursor-filtered query + LWW merge)
   and a cursor key in `SyncCursorStore`.
6. Expose via a provider in `features/<x>/application/`, watching Isar.
7. If it affects the schedule: define a `MutationRequest` subtype and finish
   writes with `ScheduleMutationCoordinator.run`.
8. If it's per-user in-memory/prefs state: register in the §8 wipe paths.

### A new screen
Named route in `lib/app/app.dart`'s route table (or a new tab — extend
`MainTabIndex` + `IndexedStack` + `ObsidianBottomNav`). Follow the
`domain/data/application/presentation` layering; keep providers in
`application/`.

### A new AI capability
Server: extend `aiChat` validation if needed. Client: new tool in
`ai_operating_layer_client.dart` + executor mapping in `AiActionExecutor`
(keep the propose→confirm→execute→undo contract). Ground factual "teach me"
answers in `features/education/domain/feature_guides.dart`, not the LLM.

### Performance rules (from PERFORMANCE.md — these are invariants)
- `.select()` when watching big state objects (the Home screen once rebuilt
  every second without it).
- Persist on state-*shape* change, not on every tick.
- Derive heavy providers from existing ones; never duplicate Isar watchers/timers.
- Skip provider refresh when a sync pull applied zero changes.
- Compress images on upload, `cacheWidth` at display size.

---

## 11. Invariants — never break these

1. **Never block the first frame on network** (P4).
2. **Never sign in from bootstrap** — AuthGate owns sign-in.
3. **Always bump `updatedAtMs` on write** — LWW discards your write otherwise.
4. **Never add `orderBy` to a Firestore query with an equality filter on another
   field** without declaring the composite index — prefer client-side sort.
5. **New per-user state must join the account-switch wipe paths** (§8).
6. **User-scoped providers `ref.watch` their uid dependencies**, never `ref.read`.
7. **Schedule writes end at `ScheduleMutationCoordinator.run`** (P5).
8. **Don't remove `Isar.openSync` / `DEAD_CODE_STRIPPING = NO`** — both are
   deliberate workarounds for release-build hangs, not style choices.
9. Release builds need `--dart-define`s (`REQUIRE_REGISTERED_AUTH`,
   `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID`) — a vanilla build silently
   breaks Google sign-in.

---

## 12. Suggested learning path

**Day 1 — the skeleton.** `lib/main.dart` → `core/bootstrap/app_bootstrap.dart`
→ `app/app.dart` + `main_tab_shell` → run the app, tap through the six tabs.

**Day 2 — one full data round-trip.** Read
`features/planning/domain/models/task_item.dart`, then
`data/isar_planning_repository.dart`, then
`application/planned_task_providers.dart`. Add a task with the debugger
attached and watch it hit Isar, Firestore, and the Home list.

**Day 3 — sync.** `core/sync/sync_service.dart` → `remote_isar_merge.dart` →
`lww_updated_at.dart` → `sync_cursor_store.dart`. Then read AUDIT.md §2 — it's
a catalog of every way this layer has failed.

**Day 4 — the loop.** Trace focus → timer → score in
`features/execution/application/execution_controller.dart` and
`features/timer/presentation/timer_session_screen.dart`.

**Day 5 — the smart layer.** `features/ai_assistant/application/` (service →
payload assembler → operating-layer client → action executor) and
`features/reminders/application/attention_orchestrator_service.dart`.

**Reference shelf (in-repo, all worth skimming):**
- `AUDIT.md` + `AUDIT_FIX_PLAN.md` — every known weakness, with fixes tracked
- `PERFORMANCE.md` — the performance invariants and their history
- `documentation/errors.md` — 21 incidents with root causes (read #16–#21)
- `documentation/isar-local-first-and-notification-routing.md` — deep dive + debug checklists
- `documentation/education_system.md`, `firebase-rules.md`
- `tasks/` and `PRD/` — the product/architecture intent behind each phase
- `test/` — ~1000+ tests; `test/support/isar_test_harness` for Isar in VM tests
