# Optimistic Updates Audit

**Scope:** Why saving/loading feels slow across Add Task, Plan Tomorrow, goal
save, goal detail, and Community — and the architecture to fix it app-wide,
including the rules future features must follow.

**Status:** Implemented through P0 + parts of P1 — see §4 for per-item state.
Foundation (Rule 1) is live app-wide: every user-data write is Isar + outbox +
background flush. Goal subcollections are mirrored in Isar with watch-based
providers (Rule 2/3); the invalidate-refetch pattern is retired for goals.

---

## 1. Root cause — one pattern, five symptoms

The app is *architecturally* local-first (Isar + a `SyncService` outbox with
connectivity-triggered flush and a "writes stuck" banner), but the happy path
**bypasses all of it**. The repeated pattern (`IsarPlanningRepository`,
`IsarGoalsRepository`, `FirestoreGoalsRepository`):

```dart
Future<void> _enqueueUpsert({...}) async {
  try {
    await FirebaseFirestore.instance.doc(path).set(payload, SetOptions(merge: true));
  } catch (_) {
    await SyncService.instance.enqueueUpsert(...);   // fallback only
  }
}
```

Three problems compound here:

1. **`set()`'s Future completes only on server acknowledgment.** Firestore
   applies the write to its local cache instantly, but the `await` blocks the
   UI flow until the server round-trip finishes. On a slow connection that is
   seconds — per interaction.
2. **The outbox is a fallback, not the path.** A slow-but-alive connection
   never throws, so `SyncService` — the correct tool, already built with
   flush-on-connectivity and stuck-writes UX — almost never engages exactly
   when it's needed most.
3. **A dead connection can hang forever.** Firestore's `set()` has no
   timeout; it waits for connectivity. The `catch` never fires, the `await`
   never returns, the UI never unfreezes.

On the read side, a second pattern: several hot screens read **one-shot
Firestore `.get()`s (server-first)** instead of Isar, then respond to every
mutation with `ref.invalidate(...)` → full network refetch.

Everything below is these two patterns wearing different clothes.

---

## 2. Findings by area

### 2.1 Add Task save (`add_task_screen.dart` `_onSave`, ~line 965)

Sequential awaited chain between button press and `Navigator.pop`:

| Step | Cost |
|---|---|
| `ensureDefaultDayPlan` (first save of a day) | up to 2 **server-ack writes** (routine + block) |
| `getTasks` (order index) | Isar — fast |
| overlap + time-block conflict checks | local — fast |
| `planning.upsertTask` | Isar put + 1 **server-ack write** |
| `_syncTimeBlock` | Isar — fast |
| `_applySleepSchedulingSideEffects` | possible extra writes |
| `_persistReminder` | reminder write (same awaited-remote pattern) + OS scheduling |
| `ScheduleMutationCoordinator.run` | recompute graph, awaited |
| draft delete → pop | prefs |

**Worst case ≈ 4–6 sequential network round-trips** while the button shows a
spinner. Every one of those writes is already durable in Isar within
milliseconds; the user is waiting for nothing they can see.

### 2.2 Plan Tomorrow

- **Reads are already Isar-local** (`getRoutinesForDate` / `getBlocks` /
  `getTasks`) — steady-state load is genuinely fast.
- **First visit for a given day**: `tomorrowRoutineSlotsProvider` bootstraps
  Morning/Afternoon/Night = 3 × (`upsertRoutine` + `upsertBlock`) =
  **6 sequential server-ack writes before the page renders anything.** This is
  the "takes much time / does not load properly" you see: the FutureProvider
  stays in `loading` until the last ack lands.
- **Adding a task** re-enters the §2.1 chain, then `invalidateTomorrowProviders`
  (the re-read is cheap; the awaited writes are the delay).

### 2.3 Saving goals (`goal_editor_screen.dart` `_save`)

- `upsertGoal`: Isar put + 1 server-ack write.
- **Setup steps loop**: `upsertAction` is called **once per step, sequentially,
  each one a server-ack write** (`FirestoreGoalsRepository.upsertAction`).
  A goal with 5 steps ≈ 6 round-trips.
- Plus stale-action deletes, reminder apply, block sync, coordinator run — all
  awaited before pop.

### 2.4 Goal detail (worst offender)

Unlike goals themselves (mirrored in Isar), **actions, milestones, and
check-ins live only in Firestore** — `IsarGoalsRepository` delegates all three
straight to `_remote`.

- **Page load** (`goalDetailProvider`): `getGoal` (Isar) then `getActions` →
  `getMilestones` → `getCheckInsForGoal` — three **sequential server-first
  `.get()`s**. `getCheckInsForGoal` fetches the **entire check-in history**
  every time and filters client-side.
- **Ticking/unticking one action**: `upsertAction` (server-ack write) →
  `invalidateGoals(ref, goalId)` → refetches `goalDetailProvider` (3 server
  reads) + `goalTodayProgressProvider` (getActions + getTodayCheckIn + window
  check-ins ≈ 2–3 server reads) + `goalActionsProvider` (another getActions).
  **One checkbox ≈ 1 write + ~6 network reads.** Same math for milestones,
  "I DID IT TODAY", and the counter sheet.
- **Adding a milestone**: getMilestones (server read for the order index) +
  server-ack write + the invalidate storm above.

### 2.5 Community

- **Chat send** (`circle_chat_view.dart`): composer sets `_sending=true`,
  `await sendMessage` (plain `set()`, server-acked), only then clears the
  input. The message list itself comes from Firestore snapshot listeners which
  would show the local echo *immediately* — the awaited send is pure perceived
  lag.
- **Image/proof upload** (`circle_proof_storage.dart`): `await putFile(...)`
  inline in the interaction, no progress feedback, no visible optimistic entry,
  no compression step.
- **Reactions**: awaited full-`reactions`-map write per tap.
- Community is **multi-user data** — the right model here is Firestore snapshot
  listeners + optimistic local echo, *not* the Isar outbox (see §3, Rule 3b).

---

## 3. Target architecture — "optimistic by default"

> **Principle: Isar is the source of truth the UI talks to. Firestore is a
> background replication concern. No user gesture ever awaits the network.**

### Rule 1 — Writes: local commit + outbox, never await the server

Invert `_enqueueUpsert`'s semantics everywhere:

```dart
Future<void> _localFirstUpsert({...}) async {
  // 1. Isar write — THIS is the save the user sees (<5 ms).
  // 2. SyncService.enqueueUpsert(...) — ALWAYS, primary path, not fallback.
  // 3. unawaited(SyncService.instance.flush()) — background drain.
}
```

- `SyncService` already has connectivity-triggered flush, per-flush snapshot
  isolation, and the stuck-writes banner (commit `6be7944`). It only needs to
  become the *primary* channel plus: **dedupe by document path**
  (last-write-wins per doc so rapid ticks collapse), **per-entity ordering**,
  and **retry with backoff**.
- Alternative considered: simply not awaiting `set()` (Firestore's own offline
  queue retries forever). Rejected as the primary approach: it works, but
  writes become invisible — no stuck-writes banner, no queue introspection,
  and the already-built outbox UX goes to waste. Route through `SyncService`.

### Rule 2 — Reads: UI reads Isar watches; the network hydrates Isar

- **Close the goal-subcollection gap**: add `IsarGoalAction`,
  `IsarGoalMilestone`, `IsarGoalCheckIn` collections mirroring the existing
  `IsarGoal`/`IsarTask` pattern. Hydrate from Firestore in the background
  (on sign-in and on goal open), not on the render path.
- Convert `goalDetailProvider` & friends from FutureProvider-with-gets to
  **StreamProviders over Isar `watch(fireImmediately: true)`** — the same
  pattern `watchGoals()` already uses.
- Check-ins: hydrate a **rolling window** (current evaluation period + recent
  history), never the full collection.

### Rule 3 — Interactions: one-frame feedback, reconcile in background

- **(a) Single-user data** (tasks, goals, actions, milestones, check-ins,
  reminders): the Isar write from Rule 1 *is* the optimistic update — a watch
  provider re-emits in the same frame. This **deletes the
  invalidate-and-refetch pattern entirely**: no `invalidateGoals` after every
  tick, no refetch storms, no spinner.
- **(b) Multi-user data** (chat, reactions, proofs): keep Firestore snapshot
  listeners as the read path; make sends non-awaited (clear the composer
  immediately — the listener's local echo renders the message instantly),
  attach a per-message "failed, tap to retry" state on error.
- **(c) Binary uploads**: start a background `UploadTask`, show the entry
  optimistically with the local file + progress indicator, compress images
  before upload, allow retry on failure.
- Every optimistic mutation defines its **failure story** up front: silent
  outbox retry (+ existing stuck-writes banner) for single-user data;
  visible per-item retry for social data; revert-plus-snackbar only where a
  server rejection is meaningful (e.g. permission-denied).

---

### Rule 4 — Sync UX: silent by default, manual on demand, quiet on failure

The product contract for how sync is *seen* (the building blocks already exist
from the `feat(sync)` work — this codifies them as requirements):

- **Silent background sync.** Routine push/pull shows nothing. No spinners, no
  toasts, no per-screen "syncing…" states.
- **Manual sync button** (Home app bar `Icons.sync`, today's
  `_syncFromCloud`): a user-triggered "pull now". Success/failure is reported
  once, via a short snackbar ("Updated from cloud" / "Could not sync. Try
  again.") — feedback is fine here because the user *asked*.
- **Quiet failure surface** (`CloudSyncGlobalIndicator`): sync is *allowed to
  fail*. When the outbox is stuck, the only signal is the thin static amber
  line under the status bar — non-animated, non-blocking, no dialog. It
  disappears on the next successful flush.
- As the outbox becomes the primary write path (Rule 1), these two surfaces
  become the **only** sync UI in the app; everything else that currently
  communicates sync state through blocking spinners gets deleted.

## 4. Rollout plan (priority order)

**P0 — biggest pain, clearest wins**
1. ✅ **Goal detail interactions** — `IsarGoalAction` / `IsarGoalMilestone` /
   `IsarGoalCheckIn` mirror collections; `IsarGoalsRepository` is fully
   local-first with `watch*` streams; detail/progress/actions providers are
   synchronous combines over those watches; `invalidateGoals` is a no-op
   (the local write IS the update). `RemoteIsarMerge` hydrates subcollections
   (cursor-incremental; full for goals new to this device; active goals only
   on periodic pulls, everything on force pull).
2. ✅ **Add Task save** — all writes on the path (`upsertTask`, day-plan
   bootstrap, reminders) now commit to Isar and enqueue; nothing on the save
   path awaits the network. (Coordinator recompute remains awaited — it is
   local compute; revisit only if measurably slow.)
3. ✅ **Goal save** — same via the shared foundation; per-step action writes
   are local + queued.
   *(Foundation: `outbox_writer.dart` — ALL nine repos now route writes
   through the outbox first: planning, goals, reminders, analytics ×2,
   execution, scoring, remote-planning, remote-goals.)*

**P1**
4. ✅ **Plan Tomorrow bootstrap** — the six slot/block writes are local +
   queued via the foundation; the page renders without waiting for acks.
5. ✅ **Chat text send** — fire-and-forget with instant composer clear; the
   snapshot listener echoes the message; genuine rejection shows a snackbar
   and restores the text. (Reactions/read-paths unchanged for now.)
6. ⬜ **Uploads**: background task + progress + optimistic entry + compression.

**P2 — hygiene**
7. ⬜ Parallelize independent awaits that remain.
8. ⬜ Timeout every awaited network call that survives (nothing UI-blocking
   > ~4 s, ever).
9. ⬜ Coordinator/analytics recompute always `unawaited` post-commit.
10. ✅ Windowed check-in reads — check-ins are local now; the progress window
    is pure in-memory math over the Isar mirror.

**Sequencing note:** P0.1 (goal subcollections into Isar) is the largest item
and the template for everything else — do it first; the remaining items mostly
*delete* code (awaits and invalidations).

---

## 5. Rules for all future features (definition of done)

Add to the project conventions; every new feature must satisfy:

1. **No `await` on a network call between a user gesture and its visible
   result.** Validation and local persistence only.
2. **Every new entity ships with three parts**: an Isar collection, an outbox
   sync path, and a watch-based provider. Firestore is sync, not storage.
3. **Every screen renders from local data in one frame**; the network only
   hydrates/refreshes in the background.
4. **Every optimistic mutation names its failure story** (outbox retry,
   per-item retry chip, or revert+toast) before it ships.
5. **IDs are client-generated** (`StableId` — already the convention), so
   creation never needs a server round-trip.
6. **The airplane-mode test**: the feature must work end-to-end offline —
   create, edit, tick, navigate — and sync cleanly when connectivity returns.
   If it can't, it isn't done.

## 6. Risks & trade-offs

- **Conflicts**: last-write-wins per document is the current de-facto model and
  is acceptable for single-user data; outbox must preserve per-document write
  order. Multi-device edits of the same goal within the sync gap remain
  possible (already true today via SyncService fallback).
- **Late failures**: security-rule rejections now surface after the UI moved
  on. The stuck-writes banner is the designated surface; permission-denied
  should mark the op failed (no infinite retry) and be visible there.
- **Firestore cache growth**: hydration listeners should be scoped (per-goal,
  windowed check-ins) to keep local mirrors bounded.
- **Tests**: repository tests shift from "did it call Firestore" to "did it
  write Isar + enqueue" — largely simpler; add outbox-drain integration tests.
