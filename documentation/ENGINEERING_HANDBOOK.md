# PathPal Engineering Handbook — How This System Actually Works

*A mentoring document for developers joining the project. It teaches the
**why** behind the architecture: the reasoning, the trade-offs, the patterns,
and the honest critique. It complements — never replaces — the existing docs.*

---

## 0. How to use this handbook (and where it sits among the other docs)

This project already has good documentation. Each doc has a distinct job, and
this handbook deliberately does **not** duplicate them:

| Doc | Job | Read it when |
|---|---|---|
| [`CLAUDE.md`](../CLAUDE.md) | The short, always-enforced rules | Before every change |
| [`CODEBASE_GUIDE.md`](CODEBASE_GUIDE.md) | The **map**: where things live, playbooks, recipes, learning path | You need to find something or fix something |
| [`GUIDELINES.md`](GUIDELINES.md) | Feature checklist + append-only **decision log** | Before feature work; when tempted to relitigate a decision |
| [`OPTIMISTIC_UPDATES_AUDIT.md`](../OPTIMISTIC_UPDATES_AUDIT.md) | The offline-first contract and its rationale, screen by screen | Working on anything that writes or syncs |
| [`errors.md`](errors.md) | 21 incidents with root causes | Before Firestore queries, iOS build changes, boot changes |
| [`AUDIT.md`](../AUDIT.md) / [`PERFORMANCE.md`](../PERFORMANCE.md) | Known weaknesses / performance invariants | Reviewing or optimizing |
| **This handbook** | The **engineering**: why the architecture is shaped this way, how the pieces interlock, what a reviewer would say | Your first week; whenever a design decision feels arbitrary |

> **One historical note so the docs don't appear to contradict each other:**
> `CODEBASE_GUIDE.md` §2-P2 and §4 describe the *original* write pattern
> ("try Firestore inline, enqueue only on failure"). On **2026-07-12** the
> project adopted the stronger contract (see the decision log): **every
> replicated write goes through the outbox unconditionally** via
> `outboxUpsert`/`outboxDelete`, and awaiting a Firestore `set`/`delete` on an
> interaction path is banned by CI
> (`test/architecture/local_first_guard_test.dart`). This handbook describes
> the current contract. When the two disagree, `CLAUDE.md` + the decision log
> + the guard test win — they describe the code as it is today.

---

## 1. The product and the one big idea

### What the app is

PathPal ("Coach for Life") is a **local-first productivity coach**: users plan
tasks into daily routines, execute them with a focus timer, self-score their
completion, track goals, get AI coaching, and join accountability circles.
iOS-first; Flutter + Riverpod + Isar + Firebase.

### The one big idea: the phone is the server

Almost every architectural decision in this codebase is a consequence of a
single product commitment:

> **No user gesture ever waits on the network.**

Most mobile apps are thin clients: the UI calls an API, shows a spinner, and
renders the response. PathPal inverts this. The **local database (Isar) is the
source of truth**. The UI reads only from Isar. Writes commit to Isar first
and the cloud copy catches up in the background. Airplane mode is supposed to
be *indistinguishable* from online for the user's own data.

Why commit to this so hard? Because the product is a daily-habit coach — it is
used at 6 AM in bed, on the subway, in a gym basement. A coach that stalls on
a spinner when you try to check off a task loses the user's trust in exactly
the moment the product exists for.

### The trade-offs you inherit

Local-first is not free. By choosing it, the project accepted:

1. **Eventual consistency.** Two devices can disagree; conflicts are resolved
   by last-write-wins on a timestamp (§7). No merging, no conflict UI.
2. **A replication subsystem you own.** The outbox queue, pull cursors, merge
   logic, and account-switch wipes (§6–§8, §10) are all hand-maintained code
   that a thin client simply wouldn't have.
3. **Two representations of every synced entity.** A domain model *and* an
   Isar collection class, kept in sync by hand.

**Alternatives that were considered and rejected** (recorded in the decision
log — don't relitigate them without a new entry):

- *Rely on the Firestore SDK's built-in offline queue* (don't await, let the
  SDK retry). Rejected because queued writes become invisible — no pending
  count, no stuck-writes banner, no way to drop foreign-uid ops on account
  switch. The hand-rolled outbox exists precisely to make failure *inspectable*.
- *Render from Firestore snapshots directly.* Rejected: couples every screen
  to network liveness and makes airplane mode a degraded mode instead of a
  first-class one.

---

## 2. Concepts you must understand before reading any code

Five ideas explain ~90% of the codebase. Learn them in this order.

### 2.1 Riverpod providers (state management + dependency injection in one)

A **provider** is a globally declared, lazily created, cached value that
widgets and other providers can *watch*. When a provider's value changes,
everything watching it rebuilds. This codebase uses Riverpod 2 with
**hand-written providers only** — no codegen, no `freezed`, no `get_it`.
That's deliberate: one less build step, and every provider is greppable
plain Dart.

Riverpod is also the app's **dependency injection** container. There is a
composition root at `lib/core/di/providers.dart` where cross-cutting
repositories and services are wired. Example — the planning repository:

```dart
final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  final firestore = FirestorePlanningRepository(ref.watch(firestoreClientProvider));
  return IsarPlanningRepository(firestore);   // decorator: Isar wraps Firestore
});
```

Note the `ref.watch(firestoreClientProvider)`: `firestoreClientProvider`
itself watches auth state, so **when the signed-in uid changes, every
repository downstream is rebuilt with the new uid**. This is a load-bearing
convention (invariant #6 in the guide): using `ref.read` here has caused
cross-user data leaks, because the repository would keep a Firestore client
pinned to the previous account.

### 2.2 Isar watch streams (how the UI stays live without refetching)

Isar can *watch* a collection: `collection.watchLazy(fireImmediately: true)`
emits whenever anything in it changes. Feature providers wrap those streams
(`StreamProvider`s), and screens watch the providers. The consequence that
makes the whole architecture click:

> **There is no "refresh after mutation" anywhere.** A write to Isar *is* the
> UI update — the watcher fires, the provider re-emits, the screen rebuilds.
> And a background sync pull that merges remote rows into Isar updates the UI
> through *the exact same path*. One pipe, two producers.

This is why `CLAUDE.md` bans invalidate-and-refetch after mutations: it's not
just style, it's redundant work and a race waiting to happen. (The retired
`invalidateGoals` pattern is the cautionary tale.)

### 2.3 The outbox pattern (how writes replicate)

An **outbox** is a durable, disk-persisted queue of "writes I owe the cloud."
Every replicated write does two things, in order:

1. Commit to Isar (authoritative, instant).
2. Append a replication op to the outbox and kick a **background** flush.

The helpers are in `lib/core/sync/outbox_writer.dart` (`outboxUpsert` /
`outboxDelete`), and the queue lives in `SyncService`
(persisted to `offline_sync_queue.json` in app documents). The flush is
`unawaited` — the caller returns in milliseconds regardless of connectivity.

Why not "try Firestore inline, queue only on failure" (the original design)?
Because Firestore's `set()` resolves only on **server ack** — and a dead
connection doesn't throw, it just never completes. Every save paid a network
round-trip when online and hung indefinitely when the connection was silently
dead. The outbox-always design makes the local path the *only* path the user
ever waits on.

### 2.4 Last-write-wins on `updatedAtMs` (how conflicts resolve)

Every synced entity carries `updatedAtMs`, stamped at write time. When a pull
finds a remote row and a local row with the same id, the one with the strictly
greater `updatedAtMs` wins — whole document, no field merging
(`lib/core/sync/lww_updated_at.dart`). Simple, predictable, and with two known
blind spots you must memorize (§7.4).

The corollary is **invariant #3: always bump `updatedAtMs` on write.** Forget
it and the next pull silently overwrites your write with the older remote copy.

### 2.5 The singleton↔Riverpod bridge

Some machinery must be reachable from *outside* the widget tree — notification
tap handlers, the sync service, boot code. Those are plain-Dart singletons
(`SyncService.instance`, `OfflineStore.instance`,
`ScheduleMutationCoordinator.instance`, …). They bridge into Riverpod by
holding the **root `ProviderContainer`** (global `appRootProviderContainer`,
attached during bootstrap). So there are two state worlds — Riverpod providers
and singletons — sharing one container.

This duality is a pragmatic trade-off, not an accident: pure-Riverpod would
force a `BuildContext`/`ref` into places that have none (background isolates,
cold-start notification taps). The cost is that singleton state is invisible
to Riverpod's lifecycle — which is exactly why account switching needs the
manual wipe registry (§10).

---

## 3. The 10,000-foot architecture

```
                    ┌──────────────────────────────────────────────┐
                    │                    UI                        │
                    │   screens & widgets (features/*/presentation)│
                    └──────────────┬───────────────▲───────────────┘
                          user     │               │ rebuilds
                          actions  ▼               │
                    ┌──────────────────────────────┴───────────────┐
                    │              APPLICATION                     │
                    │  providers / controllers / services          │
                    │  (features/*/application, core/di)           │
                    └──────┬───────────────────────▲───────────────┘
                           │ calls                 │ StreamProviders
                           ▼                       │ (Isar watchers)
                    ┌──────────────────────────────┴───────────────┐
                    │              REPOSITORIES                    │
                    │  Isar impl decorating a Firestore impl       │
                    │  (features/*/data)                           │
                    └──────┬───────────────────────────────────────┘
                           │ 1. writeTxn (authoritative)
                           ▼
   ╔════════════════ ISAR — LOCAL SOURCE OF TRUTH ════════════════╗
   ║        lib/core/local_db/isar_collections/*                  ║
   ╚═══════▲══════════════════════════════════════════════╤═══════╝
           │ LWW merge                          2. outboxUpsert
           │ (RemoteIsarMerge)                            │
   ┌───────┴───────────┐                        ┌─────────▼─────────┐
   │  PULL (background)│                        │  PUSH (background)│
   │  cursors, 30s     │◄──── SyncService ─────►│  disk-persisted   │
   │  debounce, LWW    │      (singleton)       │  outbox queue     │
   └───────▲───────────┘                        └─────────┬─────────┘
           │                                              ▼
   ╔═══════╧══════════════ FIRESTORE (sync target) ═══════════════╗
   ║              users/{uid}/... , circles/{id}/...              ║
   ╚══════════════════════════════════════════════════════════════╝

   Side-effect fan-out (after any schedule-affecting write):
   ScheduleMutationCoordinator.run → recompute graph → notification
   reconcile → domain event bus            (lib/core/runtime/)
```

Read the arrows carefully — they encode the two most important rules:

- **The UI never touches Firestore** (for user-owned data). Data reaches the
  UI only by first landing in Isar, whether it was written locally or pulled
  remotely.
- **The network appears only below the sync layer**, and only in background
  arrows. Nothing above `SyncService` awaits it.

### Layer responsibilities and boundaries

| Layer | Lives in | May depend on | Must NOT |
|---|---|---|---|
| **Domain** | `features/*/domain/` | pure Dart, `core/validation` | import Flutter or Firebase — models + pure logic only |
| **Data** (repositories) | `features/*/data/` | domain, Isar collections, `outbox_writer`, `FirestorePaths` | be watched directly by UI; skip the outbox |
| **Application** | `features/*/application/` | data, domain, other providers | do Firestore I/O inline; hold uid via `ref.read` |
| **Presentation** | `features/*/presentation/` | application (providers) | reach into `data/` or Firestore; hardcode colors/text styles |
| **Core** | `lib/core/` | — (the foundation) | know about individual features (with the pragmatic exception of `remote_isar_merge.dart`, which imports feature models — see §11) |

The dependency direction is **presentation → application → data → domain**,
with `core` underneath everything. Features talk to each other only through
providers and the domain event bus — never by calling another feature's
internals (that's what `ScheduleMutationCoordinator` fan-out is for, §8).

---

## 4. Folder structure and the patterns catalog

### The feature template

Every feature follows the same four-folder layout (§6 of the guide has the
full map; here is the *meaning* of each folder):

```
features/<name>/
├─ domain/         WHAT the feature is about: models + pure business rules.
│                  No Flutter, no Firebase. Testable in a plain Dart VM.
├─ data/           HOW it persists: repository interfaces + Isar/Firestore
│                  implementations. The outbox pattern lives here.
├─ application/    WHEN things happen: providers, controllers, services.
│                  All state lives here. File convention: <x>_providers.dart.
└─ presentation/   HOW it looks: screens + widgets. Watches providers only.
```

Why feature-first instead of layer-first (all models in one `/models`, all
screens in one `/screens`)? Because features are the unit of change: a goals
bug fix touches `features/goals/` and almost nothing else, so the blast radius
of a change matches the folder you're standing in. The price is that
genuinely shared machinery must be promoted to `core/` — and this project is
disciplined about doing that (sync, notifications, theme, validation).

### Patterns you'll meet, and where they're used

| Pattern | Where | Why it was chosen |
|---|---|---|
| **Repository** | every `features/*/data/` | Screens/providers never know *where* data lives; enabled the inline-Firestore → outbox migration without touching UI |
| **Decorator** | `IsarPlanningRepository(FirestorePlanningRepository(...))` | The Isar repo *is a* PlanningRepository that adds local-first behavior around the Firestore one — swap or peel layers freely |
| **Outbox / store-and-forward** | `core/sync/outbox_writer.dart`, `SyncService` | Durable, inspectable replication (§2.3) |
| **Coordinator** | `core/runtime/schedule_mutation_coordinator.dart` | One pipeline for all schedule side effects instead of N×N feature coupling (§8) |
| **Event bus (pub/sub)** | `core/runtime/schedule_domain_event_bus.dart` | Features react to schedule changes without importing each other |
| **Adapter (incremental migration)** | `run(commitOverride: ...)` on the coordinator | Lets legacy write paths keep their commit code while adopting the pipeline's steps 3–5 — migration one call site at a time |
| **State machine** | `TaskTimerEngine` (execution) | Timer phases (notStarted/inProgress/paused/finished) as explicit states, pure and unit-testable |
| **Gate (nested guards)** | `main.dart`: splash → onboarding → auth → first-launch | Each boot concern is one widget with one job (§5) |
| **Singleton + container bridge** | `SyncService`, `OfflineStore`, coordinator | Reachability from non-widget code (§2.5) |
| **DI via providers** | `core/di/providers.dart` | Composition root; uid-scoped rebuilds for free via `ref.watch` |

---

## 5. Boot: the most fragile 4 seconds of the app

**Overview.** Startup is where this app has historically been hurt the worst —
three separate incidents produced permanent white screens on release iOS
builds. The design that came out of those scars is a **two-phase bootstrap**
plus a **stack of gate widgets**, each owning exactly one boot concern.

**Purpose.** Get a frame on screen *unconditionally fast*, then do everything
network-shaped behind it.

**The rule (P4, "the first frame is sacred"):**
`AppBootstrap.initializePreFrame` (`lib/core/bootstrap/app_bootstrap.dart`)
may only do local, fast work — Firebase Core init and opening Isar. Everything
network-bound runs in `completeDeferred`, *after* the first frame. Never add
an `await` to the pre-frame phase; that is how white screens are born.

**Execution flow** (all in `lib/main.dart`, inside `runZonedGuarded`):

```
main()
 ├─ ensureInitialized
 ├─ create root ProviderContainer  → appRootProviderContainer (the bridge, §2.5)
 ├─ AppBootstrap.initializePreFrame
 │   ├─ Firebase.initializeApp            (local plist read, fast)
 │   ├─ OfflineStore.initialize → Isar.openSync   ← SYNC on purpose:
 │   │     async Isar.open hangs on iOS AOT builds (errors.md #20 territory)
 │   └─ ScheduleMutationCoordinator.attachContainer
 ├─ load persisted brightness          (so the theme never flashes)
 ├─ enable Crashlytics with 4s TIMEOUT (it once hung forever — errors.md #19)
 └─ runApp(
      UncontrolledProviderScope            shares the root container
       └─ AnimatedSplashGate               ~3.4s splash; real app builds behind it
           └─ OnboardingGate               fresh installs: 15-step marketing flow.
           │                               Sits ABOVE AuthGate on purpose —
           │                               "Skip" just reveals AuthGate, whose
           │                               silent anonymous sign-in IS the skip
           │                               path (zero new auth code; decision
           │                               log 2026-07-12)
           └── AuthGate                    owns ALL sign-in; detects uid CHANGES
                │                          and runs the wipe protocol (§10)
                └─ FirstLaunchGate         first install: forced full pull so
                    │                      the UI is never empty (isar_seeded_v1)
                    └─ AppLifecycleTaskRefresh   on resume: sync + day rollover
                        └─ CoachForLifeApp        the MaterialApp
    )
 └─ after first frame: AppBootstrap.completeDeferred
     notification wiring + cold-tap drain, ledger reconciliation,
     SyncService.initialize (first pull + queue flush), reminder scheduling,
     AI-history pruning, community bridges.
     Deliberately NEVER signs in — a second sign-in path once created
     duplicate anonymous accounts and triggered data wipes.
```

**Design decisions worth internalizing:**

- *Why gates instead of one init function?* Each gate is independently
  testable, has an obvious owner for its failure mode, and composes by
  nesting. Adding a boot concern = adding one widget at the right depth,
  not editing a 300-line function.
- *Why does OnboardingGate sit above AuthGate?* So registration during
  onboarding lands every answer under the real uid — no anonymous→registered
  data migration ever needed. The alternative (register at the end) was
  considered and rejected in the decision log.
- *Why `print()` breadcrumbs, not `debugPrint`?* `debugPrint` is silenced in
  release builds — exactly where boot hangs happen. `[boot]` breadcrumbs in
  the device console bracket any hang between the last printed line and the
  next expected one.

**Debugging tips.** White screen playbook is `CODEBASE_GUIDE.md` §9 — the
three known causes (Crashlytics urgent mode, Isar FFI dead-stripping, a new
pre-frame await) cover every historical instance.

**Extension point.** New startup work goes in `completeDeferred`, full stop.
If you believe something belongs pre-frame, it must be provably local and
fast — and you should say so in a comment, because the next reviewer will ask.

---

## 6. The write path — life of a save

**Overview.** This is the single most important flow in the codebase. Every
piece of user-owned data follows it. Learn it once with a task; every other
entity (goal, reminder, check-in, onboarding profile…) is the same shape.

### Execution flow, end to end

```
1. USER      taps Save in AddTaskScreen
2. UI        _onSave builds a PlannedTask (pure domain object)
3. DI        planningRepositoryProvider → IsarPlanningRepository
                                          (decorating FirestorePlanningRepository)
4. VALIDATE  task.validate()      ← throws ArgumentError; the ONLY validation
                                    gate — there is no server-side validation
5. STAMP     updatedAtMs = now    ← the LWW conflict key (invariant #3)
6. COMMIT    isar.writeTxn { putByTaskId(...) }
                │
                └───► Isar watchers fire → StreamProviders re-emit →
                      Home/TasksHub rebuild.  THE USER IS DONE HERE.
                      Total elapsed: milliseconds, zero network.
7. REPLICATE outboxUpsert(entityType, documentPath, payload)
                ├─ SyncService.enqueueUpsert  → disk (offline_sync_queue.json)
                └─ unawaited(processQueue())  → background Firestore push
8. FAN-OUT   ScheduleMutationCoordinator.run(TaskCreatedMutation…)   (§8)
```

Steps 6 and 7 are the contract. Step 6 makes the write real; step 7 makes it
durable in the cloud *eventually*. The user's experience ends at step 6.

### Key functions (the reviewer's tour)

**`outboxUpsert` / `outboxDelete`** — `lib/core/sync/outbox_writer.dart`
- *Triggered by:* every repository write/delete on a synced entity.
- *Exists because:* the replication decision (enqueue-always) must live in one
  place, not be re-decided per repository. The file's doc comment is the
  canonical statement of the local-first write rule.
- *Side effects:* appends to the disk queue; kicks an unawaited flush.
- *Failure story:* none per-call, by design. A flush that leaves ops behind
  sets `SyncService.hasSyncIssue`, which the app surfaces as the thin amber
  stuck-writes line. Quiet failure, loud only on user demand (Home sync button).
- *What could go wrong:* you forget to call it after a writeTxn → the write
  exists locally but never replicates. Nothing crashes; the data just never
  reaches other devices. This is the #1 code-review check on any new write path.

**`SyncService.processQueue`** — `lib/core/sync/sync_service.dart`
- *Triggered by:* every enqueue, connectivity restore, app resume, boot.
- *What it does:* drains the outbox to Firestore in order; ops tagged with a
  foreign uid are dropped (protects against account-switch replay).
- *State:* `pendingCount` and `hasSyncIssue` `ValueNotifier`s — deliberately
  not Riverpod, so plain widgets and singletons can listen.
- *Debugging:* check `pendingCount` and read `offline_sync_queue.json` directly;
  test hooks (`debugOpWriterForTests`, `debugSkipQueuePersistenceForTests`)
  let VM tests exercise it without Firebase.

**`ScheduleMutationCoordinator.run`** — see §8.

### Common pitfalls

- **Skipping the outbox** (writing Firestore directly): banned by the
  architecture guard test; the only allowlisted awaiter is the outbox flusher
  itself inside `sync_service.dart`.
- **Forgetting `updatedAtMs`**: your write commits locally, then loses LWW to
  a staler remote copy on the next pull and silently reverts. If a user
  reports "my edit undid itself," check this first.
- **Validating in the UI instead of the model**: `validate()` on the domain
  model is the single gate. UI-level checks are UX sugar, not protection —
  remember there is no server-side validation for planning data.

---

## 7. The read path and sync — life of a pull

### 7.1 Reads: one pipe

```
Isar collection change (local write OR remote merge — same thing)
  → watchLazy(fireImmediately: true)
  → feature StreamProvider (e.g. todayAllTasksRowsProvider)
  → screen rebuilds
```

A 1-minute timer also re-emits task rows so time-based reprioritization
("this task is now overdue") happens without any data change. When you see a
provider combining a watcher and a timer, that's why.

### 7.2 Pull: `SyncService.syncFromRemote` → `RemoteIsarMerge`

- **Triggers:** connectivity restore, app resume, boot; `force: true` on first
  launch and account switch.
- **Debounce:** at most once per 30s (unless forced). Concurrent callers
  *join* the in-flight pull — but only if it belongs to the same uid; after an
  account switch the in-flight pull is the previous user's, so the new caller
  waits for it to settle and starts fresh. (Read that check in
  `sync_service.dart` — it's a beautiful example of defensive uid hygiene.)
- **Mechanics:** one-shot `.get()` queries — deliberately **no Firestore
  listeners**. Listeners would duplicate the watch pipe, keep sockets alive,
  and reintroduce network liveness as a UI dependency. 60s total timeout so a
  stalled network can't wedge the gate that awaits a forced pull.
- **Incremental:** per-collection cursors (`where updatedAtMs > cursor`,
  stored via `SyncCursorStore` in SharedPreferences) so the periodic pull
  doesn't re-read the whole account. Routines and blocks are still walked in
  full — they're the cheap "skeleton," and cursor-filtering them would skip
  descending into unchanged parents and miss task edits underneath.
- **uid pinning:** `RemoteIsarMerge` pins the uid at construction via
  `FirestoreClient`, and the pull aborts if the signed-in uid changes
  mid-flight. Every collection in one pull reads from one user's tree, never
  a mix.

### 7.3 After the pull

`RemoteIsarMerge` counts rows it actually wrote (LWW no-ops excluded). If the
pull changed nothing — the common case for the periodic pull — the post-sync
provider refresh is skipped entirely (a `PERFORMANCE.md` invariant). Otherwise
`PostSyncRefreshCoordinator` (450ms debounce) invalidates the few non-stream
providers. Stream-based providers need nothing: the Isar watchers already fired.

### 7.4 The LWW blind spots (memorize these two)

1. **Cursor pulls never see remote deletions.** A doc deleted on another
   device produces no row above the cursor, and the merge never deletes
   locally (it's LWW *upsert-only*). Deleted items can linger or resurrect
   until a **force pull** — the deliberate reconcile escape hatch.
2. **Clock skew hides writes.** A device with a skewed-back clock stamps
   `updatedAtMs` below the cursor; those writes are invisible to incremental
   pulls until a force pull.

If a bug report says "data came back from the dead" or "my other device never
got the change," start here, then check `pendingCount` and the queue file.

### 7.5 The persistence split (why "where did my data go" has four answers)

| Data | Storage | Offline durability |
|---|---|---|
| Tasks, routines, blocks, reminders, goals (+subentities), analytics, onboarding profile | Isar + Firestore (full local-first) | Strong |
| Timer sessions, task scores | Firestore via outbox, **no Isar mirror** | Write survives offline (queued); *reads* need network |
| AI chat history, coaching caches, notification ledger, profile prefs | Isar only — never synced | Lost on reinstall / device switch |
| Community / circles | Firestore only, live | None — this is a network-inherent feature (Telegram model) |

The second and third rows are conscious scope decisions, not oversights — but
they are also the rows most likely to surprise you (§11).

---

## 8. The mutation pipeline — how side effects stay sane

**Overview.** A schedule write (task/goal/reminder/time-block) has
consequences far beyond its own row: derived providers must recompute,
notifications must be rescheduled or cancelled, analytics and other features
want to know. The naive approach — each feature calls the others — produces
an N×N dependency web where adding one feature means touching five.

**Purpose.** `ScheduleMutationCoordinator`
(`lib/core/runtime/schedule_mutation_coordinator.dart`) makes side-effect
fan-out a **pipeline with one entry point** instead of a web.

```
ScheduleMutationCoordinator.run(TypedMutationRequest)
  1. Validate     entityId non-empty; container attached
  2. Commit       the write (or commitOverride — see below)
  3. Recompute    UnifiedRecomputeGraph.schedule(scope)   ← debounced ~400ms;
                                                            scoped, not global
  4. Reconcile    notifications for the affected entities
  5. Publish      ScheduleDomainEvent on the event bus    ← features subscribe;
                                                            no direct coupling
```

**Key design choices:**

- **Typed mutations** (`MutationRequest` subtypes in `mutation_request.dart`):
  the pipeline can derive the recompute *scope* and the domain event from the
  type, instead of every caller hand-picking what to refresh.
- **`commitOverride` — the adapter pattern for incremental migration.** Call
  sites that already performed their write (e.g. `AiActionExecutor`) pass a
  no-op commit; the coordinator still runs steps 3–5. This let the pipeline be
  adopted one call site at a time instead of a big-bang rewrite. The flip side:
  `_commit` still contains `UnimplementedError` stubs for unmigrated mutation
  types — passing such a type *without* an override fails at runtime, not
  compile time (§11).
- **Debounced, scoped recompute.** A burst of writes (AI applying five
  changes) triggers one recompute, not five, and only for the affected scope.

**Rule of thumb:** if your new write changes what today's schedule looks like,
it is not done until it ends with `ScheduleMutationCoordinator.run(...)`
(invariant #7). If it doesn't affect the schedule, don't route it through the
coordinator — the pipeline is not a general write bus.

**Debugging:** every stage logs under `[ScheduleMutationCoordinator]`; the
five stages are the natural breakpoint spots for any "I saved X but Y didn't
update" bug. If a derived value updates only after restart, suspect step 3's
scope mapping for your mutation type.

---

## 9. The data — models, owners, lifecycles

### The core hierarchy (one day of the user's life)

```
Routine (dateKey: "2026-07-10", mode: flexible/disciplined/extreme)
 └─ TaskBlock (ordered; optional start/end time)
     └─ PlannedTask (title, duration, priority, status, planDateKey, …)
```

Three model facts that prevent whole classes of bugs:

1. **`PlannedTask.planDateKey` is the authoritative "which day" field** — not
   the parent routine's `dateKey`. Filtering by the parent is a latent bug.
2. **Goals are deliberately decoupled from tasks.** `PlannedTask` has no
   `goalId`. Goals and tasks meet only via time-block conflict detection and
   the habit-anchor aggregator. If a feature "obviously" needs a task→goal
   link, that's a product decision to raise, not a field to quietly add.
3. **IDs are client-generated (`StableId`)** — mandatory in a local-first
   system, because the device must mint identity while offline. `updatedAtMs`
   is stamped at write time and is the entity's entire conflict story.

### Model lifecycle template (every synced entity follows it)

| Stage | Who | Where |
|---|---|---|
| Created | a screen/controller builds the domain model | `features/*/presentation` → `application` |
| Validated | `model.validate()` via `ModelValidators` | domain — the only gate |
| Persisted | Isar writeTxn, then outbox payload | `features/*/data` repository |
| Mirrored | Isar collection class ↔ domain mapping | `core/local_db/isar_collections/` |
| Replicated | outbox → `users/{uid}/...` | `core/sync` |
| Hydrated | pull → LWW merge into Isar | `remote_isar_merge.dart` |
| Consumed | watch-based providers | `features/*/application` |
| Retired | outboxDelete + local delete (remember blind spot §7.4-1) | repository |

The dual representation (domain model + `Isar*` collection class) is the tax
of the architecture: two classes per entity, mapped by hand, regenerated with
`dart run build_runner build` when the Isar class changes. The full recipe for
a new synced entity is `CODEBASE_GUIDE.md` §10 — treat it as a checklist, all
eight steps; the failure mode of skipping one is always *silent*.

### Trivia that will save you an afternoon

- Two registered Isar collections are **dead code**: `IsarActivityFeedCache`
  and `IsarAiPulseCache` — nothing reads or writes them. Don't cargo-cult them
  as examples; don't be surprised they're empty.
- Firestore paths are centralized in `core/firebase/firestore_paths.dart`;
  security rules are one blanket `request.auth.uid == uid` for user data.
  **There is no server-side field validation** — the client `validate()` is
  the only line of defense (a real weakness; see §11).

---

## 10. The danger zone: auth and account switching

Everything in this app is per-user, but the storage is per-*device*: Isar,
SharedPreferences, the outbox queue, sync cursors, and a crowd of in-memory
providers and singleton caches. **A uid change must wipe all of it, in the
right order, or user A's data leaks into user B's session.** Most historical
cross-user bugs came from missing exactly one of these.

`AuthGate` detects the uid change and runs, in order:

```
1. invalidateUserScopedProviders(ref)     in-memory state Isar-wiping can't
                                          reach (AI chat, timer, onboarding…)
   features/auth/application/user_scoped_invalidation.dart
2. AuthSessionPolicy.clearLocalSession()  cancel ALL OS notifications, wipe
                                          every Isar collection, clear outbox
                                          queue AND sync cursors, scrub prefs
3. restart community bridges, then a FORCED full pull for the new uid
```

> **The rule you must never forget:** if you add per-user state in a new
> place — a prefs key, a non-autoDispose provider, a singleton cache — you
> must register it in one of those two wipe paths. **Nothing does it
> automatically.** This is the single most error-prone convention in the
> codebase (§11 discusses why), so it's a standing code-review question:
> *"does this new state survive an account switch, and should it?"*

Also remember the defensive layers that back this up: outbox ops are
uid-tagged (foreign ops dropped on flush), pulls pin their uid and abort on
change, and `firestoreClientProvider` rebuilds all repositories on uid change.
Defense in depth exists because each layer alone has failed before.

---

## 11. Reviewer's notes — an honest critique

You asked to be taught like an engineer, so here is the code review I would
leave on this architecture. Strengths first, then the debt. (The weaknesses
below largely agree with `AUDIT.md`; where they matter day-to-day I say so.)

### What is genuinely well designed

- **The failure stories are designed, not accidental.** Silent routine sync,
  the amber stuck-writes line, per-item retry for network-inherent features —
  every failure has a named UX. Most codebases can't answer "what does the
  user see when this fails?"; this one answers it in writing.
- **The guard test.** Banning awaited Firestore writes via a CI test
  (`test/architecture/local_first_guard_test.dart`) turns an architecture rule
  into a compile-adjacent fact. This is how you keep rules alive after the
  people who made them move on. More rules deserve this treatment.
- **Incident-driven hardening with receipts.** `Isar.openSync`, the
  Crashlytics 4s timeout, `DEAD_CODE_STRIPPING = NO`, `print` breadcrumbs —
  each weird-looking choice links to a documented incident. The docs make the
  scar tissue legible instead of mysterious.
- **The decision log.** Append-only, with alternatives considered. It prevents
  the most expensive failure mode of long-lived projects: relitigating settled
  decisions from scratch.
- **One read pipe.** Local writes and remote merges reaching the UI through
  the same Isar watchers eliminates an entire category of "refresh raced the
  mutation" bugs.

### The debt, ranked by how likely it is to bite you

1. **The manual account-switch wipe registry (§10).** Correctness depends on
   every developer remembering an unenforced convention. This is the inverse
   of the guard test — a rule that lives only in docs and review vigilance.
   *What I'd do:* a registration API (`UserScopedState.register(...)`) that
   wipe paths iterate, plus a test that fails when a new Isar collection or
   known prefs key isn't registered. Highest-value refactor in the codebase.
2. **The new-entity recipe is copied, not centralized.** Eight steps per
   synced entity, each silently skippable: forget the outbox call → local-only
   data; forget the merge phase → one-way sync; forget `updatedAtMs` → LWW
   losses. A generic `SyncedRepository<T>` base could make several steps
   structural. The counter-argument — explicit per-entity code is easier to
   read and debug than a generic layer — is real, which is why this is #2 and
   not #1. At the current entity count it's manageable; at 2× it won't be.
3. **`remote_isar_merge.dart` knows every feature.** It imports goal, task,
   reminder, analytics, and onboarding models — a `core/` file depending on
   `features/`, inverting the layering, and it grows with every entity. A
   per-entity "merge phase" registration would fix both this and part of #2.
4. **No server-side validation.** The blanket Firestore rule means any
   authenticated client can write anything shaped however it likes into its
   own tree. Fine while the only client is this app; a liability the moment
   there's a second client, a web app, or a compromised token. Client
   `validate()` is UX, not security.
5. **Coordinator `_commit` stubs throw `UnimplementedError`.** The incremental
   migration is honest about being incomplete, but the failure is at runtime.
   An exhaustive `switch` over a sealed mutation type would move it to
   compile time.
6. **Firestore-only entities (timer sessions, scores) and the non-transactional
   score→status flip.** Scoring writes the `TaskScore`, then the *screen*
   separately flips the task status. A crash between the two leaves a scored
   task that still looks unscored. Low frequency, confusing when it happens.
7. **LWW at document granularity.** Editing a task's title on the phone and
   its duration on the tablet within the same sync window loses one edit
   silently. Acceptable for a single-user personal tool; the thing to revisit
   first if real multi-device usage grows.
8. **Dead code:** the two unused Isar cache collections. Cheap to delete,
   mildly misleading to keep.

### What is *not* overengineered (even if it looks like it)

A junior reviewer might flag the coordinator, the outbox, the ledger
reconciliation, or the two-phase boot as ceremony. They aren't — each one is
a response to a documented incident or a structural N×N problem. The bar for
removing any of them is "read the incident that created it first."

### Scaling notes

This is a single-user-per-account personal tool; "scale" here means *more
entities and more devices*, not millions of concurrent users. The components
that feel it first: `RemoteIsarMerge` (grows per entity — see #3), the force
pull (full account re-read; fine now, slow at 10× data), and LWW granularity
(#7). Firestore itself scales per-uid trees effortlessly — the pressure is
all client-side.

---

## 12. The impact map — predict the blast radius

Before touching X, check Y:

| If you change… | It affects… | Because… |
|---|---|---|
| Any domain model's fields | Isar collection class + build_runner, `toMap` payload, merge phase, `validate()` | dual representation (§9) |
| Anything about writes | the guard test, the outbox payload shape, `updatedAtMs` stamping | §6 contract |
| A Firestore query (adding `orderBy`/range) | composite-index requirements → runtime `failed-precondition` swallowed by generic catches | errors.md #16/#18 — it has happened **three times**; sort client-side |
| Boot order in `main.dart` / gates | white-screen risk, sign-in duplication, wipe ordering | §5, §10 |
| Per-user state anywhere new | the two wipe paths | §10 — nothing is automatic |
| A provider's uid dependency (`watch`→`read`) | cross-user data leaks after account switch | §2.1 |
| Schedule-affecting writes | coordinator routing, recompute scope, notification reconcile | §8 |
| Isar schema / iOS build config | `Isar.openSync`, `DEAD_CODE_STRIPPING = NO` — release-only hangs | invariant #8 |
| Notification scheduling | the ledger + reconciliation service, attention orchestrator suppression | guide §7 |
| Anything visual | `AppColors` + `page_headers.dart` only; themed transitions | design system rules |

---

## 13. Where to start, for the usual jobs

These defer to the canonical recipes/playbooks rather than duplicating them:

- **Add a synced entity** → `CODEBASE_GUIDE.md` §10, all 8 steps as a
  checklist. Budget the full set (Isar + outbox + provider + merge phase) into
  the estimate — it *is* the feature, not overhead.
- **Add a screen/tab** → guide §10; named route in `app/app.dart`, or extend
  `MainTabIndex` + `IndexedStack` + `ObsidianBottomNav` for a tab.
- **Add an AI capability** → guide §10; keep the propose→confirm→execute→undo
  contract, ground factual answers in `feature_guides.dart`, not the LLM.
- **Something broke** → guide §9 playbooks (white screen, silent button,
  missing data, reminders, tests). They cover every historical incident class.
- **Before any feature work** → the `GUIDELINES.md` checklist, especially
  item 4 (decide the offline class *before* writing code) and item 9 (confirm
  ambiguous semantics with the product owner — this team answers in detail).
- **Learning path for week one** → guide §12 (five days, one subsystem a day).

And the meta-rule of this codebase: **when a decision feels arbitrary, check
the decision log and `errors.md` before "fixing" it.** The weird thing is
load-bearing more often than not.

---

## 14. Summary — the mental model on one screen

1. **Isar is the truth; Firestore is a replica.** The UI reads only Isar.
2. **Writes:** validate → stamp `updatedAtMs` → Isar writeTxn → outbox →
   background flush. The user waits for none of the network.
3. **Reads:** Isar watchers → StreamProviders → screens. Remote pulls feed the
   same pipe. Never refetch after a mutation.
4. **Conflicts:** last-write-wins on `updatedAtMs`, whole-document; deletions
   and clock skew are the blind spots; force pull is the escape hatch.
5. **Side effects:** schedule writes end at `ScheduleMutationCoordinator.run`;
   features hear about each other through events, not imports.
6. **Boot:** first frame is sacred; gates own one concern each; network work
   is post-frame only.
7. **Accounts:** a uid change wipes everything through two manual wipe paths —
   new per-user state must join them, and nothing enforces it but you.
8. **Failure UX is specified:** silent sync, amber line for stuck writes,
   Telegram-style per-item retry for network-inherent features.
9. **The docs are part of the system:** decision log before relitigating,
   errors.md before Firestore queries or iOS build changes, guard test keeps
   rule #2 honest.

If you internalize those nine lines, you can predict what almost any file in
this repository does before opening it — which is the actual definition of
understanding an architecture.
