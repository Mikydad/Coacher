# SidePal (Coach for Life) — Project Rules

Flutter + Riverpod + Isar (local source of truth) + Firebase (background
replication). These rules apply to EVERY change; they are not suggestions.

## Product principles

1. **Instantaneous by default** — no user gesture ever waits on the network.
2. **Offline-first for the user's own data** (tasks, goals, plans, check-ins,
   reminders, settings): airplane mode must be indistinguishable from online;
   sync happens silently when a connection exists.
3. **Optimistic-then-honest for network-inherent features** (AI, chat,
   uploads, circle membership): act locally/instantly, reconcile in the
   background, show a per-item error with retry only on genuine failure —
   the Telegram model.
4. **Sync is silent; failure is quiet.** Routine sync shows nothing. Stuck
   writes show only the thin amber line; the Home sync button is the one
   user-triggered loud path.
5. **One design system** — reuse tokens and shared components; consistency
   over novelty.
6. **Chrome recedes, content leads** — quiet page titles, loud section
   content, one primary action per screen.

## Hard architecture rules

- **Writes**: commit to Isar, then replicate via `outboxUpsert`/`outboxDelete`
  (`lib/core/sync/outbox_writer.dart`). NEVER `await` a Firestore
  `set`/`delete` on an interaction path — enforced by
  `test/architecture/local_first_guard_test.dart`.
- **Reads**: UI reads Isar watch streams (`.watch(fireImmediately: true)` →
  StreamProvider); `RemoteIsarMerge` hydrates Isar in the background.
  Never invalidate-and-refetch after a mutation — the local write IS the
  update (see `invalidateGoals` for the retired pattern).
- **A new synced entity ships as a set**: Isar collection (registered in
  `isar_schemas.dart`, regenerate with build_runner) + outbox write path +
  watch-based provider + a pull phase in `lib/core/sync/remote_isar_merge.dart`
  (last-write-wins on `updatedAtMs` — the model must carry it).
- IDs are client-generated (`StableId`); `updatedAtMs` is stamped at write.
- **Definition of done**: works end-to-end in airplane mode (or has the
  optimistic-then-honest treatment); failure story named; `flutter analyze`
  clean; full test suite passes.

## Design system

- Colors only through `AppColors` (light/dark palette-switched) — never
  hardcoded hex in widgets.
- Type hierarchy via `lib/core/presentation/page_headers.dart`:
  `PageTitle` (small-caps AppBar chrome, centered), `SectionHeader` (18px,
  the loudest in-page text), 11px uppercase micro-labels for field groups.
  No inline header styles.
- Route transitions come from the app theme (`pageTransitionsTheme`);
  in-screen step changes animate (AnimatedSwitcher, ~260 ms) — nothing snaps.
- Back must respect flows: multi-step screens intercept with `PopScope` and
  step back; never `pushReplacement` mid-flow (exception: create-screen →
  the created item's detail).

## Process

- Before feature work: restate the design back to the user and confirm any
  ambiguous semantics — they expect this and will answer in detail.
- Consult `documentation/GUIDELINES.md` (feature checklist + decision log);
  **append a decision-log entry for every significant product/architecture
  decision** so later sessions don't relitigate it.
- Deep references: `documentation/CODEBASE_GUIDE.md` (structure),
  `OPTIMISTIC_UPDATES_AUDIT.md` (offline-first rationale),
  `PRD/DESIGN_PRD.md` + `PRD/create-prd.md` (design & PRD templates),
  `documentation/errors.md` (known Firestore/index pitfalls — read before
  adding any Firestore query with `orderBy`/range filters).
- Never commit or push without explicit permission.
