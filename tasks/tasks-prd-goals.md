# Task list — Goals (Habits & Outcomes)

Generated from [`prd-goals.md`](prd-goals.md). Implements user goals separate from day-planned tasks: horizons (daily / weekly / monthly calendar month), flexible measurement units, actions, milestones, check-ins + milestone progress, intensity, category filter+tag, archive and reopen.

**Subtasks** below use `x.y.z` under each `x.y` for step-by-step execution.

## Relevant files

### New (suggested layout)

- `lib/features/goals/domain/models/user_goal.dart` — Core `UserGoal` (or `CoachGoal`) entity: id, title, categoryId, horizon, status, measurement, target value, intensity, period bounds (`periodStartMs` / `periodEndMs` or month/year for monthly), `createdAtMs`, `updatedAtMs`.
- `lib/features/goals/domain/models/goal_action.dart` — Action line: id, goalId, title/description, `orderIndex`.
- `lib/features/goals/domain/models/goal_milestone.dart` — Milestone: id, goalId, title, `done`, `orderIndex`.
- `lib/features/goals/domain/models/goal_check_in.dart` — Check-in for a calendar day (or week key): `goalId`, `dateKey` (`String` yyyymmdd), `metCommitment` bool, optional `note`, `updatedAtMs`.
- `lib/features/goals/domain/models/goal_enums.dart` — `GoalHorizon`, `GoalStatus`, `MeasurementKind`, etc.
- `lib/features/goals/data/goals_repository.dart` — Abstract + Firestore implementation + sync.
- `lib/features/goals/application/goals_providers.dart` — Providers + invalidation.
- `lib/features/goals/presentation/goals_home_screen.dart` — List, filters, CTAs.
- `lib/features/goals/presentation/goal_editor_screen.dart` — Create/edit form.
- `lib/features/goals/presentation/goal_detail_screen.dart` — Detail, check-ins, milestones.
- `lib/features/goals/application/goal_period_helpers.dart` — Period bounds and date-key math.

### Existing to modify

- `lib/core/firebase/firestore_paths.dart`, `lib/core/di/providers.dart`, `lib/features/goals/presentation/goal_selection_screen.dart`, `lib/app/app.dart`, `documentation/firebase-rules.md`

### Notes

- **Monthly = calendar month**; **measurement** + **target** per user; **progress** = check-ins + milestones; **categories** = filter + tag.
- Run `dart analyze lib` after each milestone. Optional UI cap ~20 milestones/actions.

---

## Tasks

- [ ] **1.0 Domain models and period helpers**
  - [ ] **1.1** Add `GoalHorizon` enum: `daily`, `weekly`, `monthly`. Add `GoalStatus` enum: `active`, `paused`, `completed`.
    - [ ] **1.1.1** Create `goal_enums.dart` (or split files if preferred).
    - [ ] **1.1.2** Add string serializers `name` / `fromString` (or index) for Firestore `String` fields.
    - [ ] **1.1.3** Document enum values in a short file comment for PRD traceability.
  - [ ] **1.2** Add `MeasurementKind`: at minimum `minutes`, `sessions`, `count`, `distance`, `custom`; `String? customLabel` when `custom`.
    - [ ] **1.2.1** Add `displayLabel` helper for UI (e.g. “Minutes”, “Sessions”).
    - [ ] **1.2.2** Serialize `customLabel` only when kind == `custom`; omit or null otherwise in `toMap`.
  - [ ] **1.3** Define `UserGoal` with id, title, categoryId, horizon, status, measurement, target, intensity 1–5, timestamps, period fields (monthly: year+month **or** start/end ms; daily/weekly: start/end ms).
    - [ ] **1.3.1** Choose **one** period representation; add `copyWith` for editor flows.
    - [ ] **1.3.2** Implement `toMap` / `fromMap` with null-safe defaults for older docs.
    - [ ] **1.3.3** Add lightweight `==` / `hashCode` only if needed for tests; otherwise skip.
  - [ ] **1.4** Define `GoalAction` and `GoalMilestone` with `toMap` / `fromMap`.
    - [ ] **1.4.1** Use `bool` / `completed` field name consistent with Firestore keys (`completed` vs `done` — pick one, document).
    - [ ] **1.4.2** Default `orderIndex` to `0` when missing from map.
  - [ ] **1.5** Define `GoalCheckIn`: goalId, dateKey, metCommitment, updatedAtMs, optional note.
    - [ ] **1.5.1** Document id strategy: composite key `goalId_dateKey` **or** random doc id + query by fields — pick one.
    - [ ] **1.5.2** `toMap` / `fromMap` for persistence.
  - [ ] **1.6** Implement `goal_period_helpers.dart`.
    - [ ] **1.6.1** `DateTime periodStart(UserGoal)` / `DateTime periodEnd(UserGoal)` inclusive end-of-day if using dates.
    - [ ] **1.6.2** `bool isDateKeyInPeriod(UserGoal, String dateKey)` using device local timezone (document choice).
    - [ ] **1.6.3** `int eligibleDayCount(UserGoal)` for denominator of “X of Y days” (exclude future days if period not started).
    - [ ] **1.6.4** `Iterable<String> dateKeysInPeriod(UserGoal)` or range for batch load of check-ins.
    - [ ] **1.6.5** Unit tests for March non-leap / leap year month boundaries and a weekly sample.

- [ ] **2.0 Firestore paths, schema, and `GoalsRepository`**
  - [ ] **2.1** Extend `FirestorePaths` with goal paths; document chosen layout in repository header.
    - [ ] **2.1.1** Add `goals` collection path under `userRoot`.
    - [ ] **2.1.2** If subcollections: `goalActions(goalId)`, `goalMilestones(goalId)`, `goalCheckIns(goalId)` helpers.
    - [ ] **2.1.3** If embedded arrays: no sub-path helpers; document max array size guidance.
  - [ ] **2.2** Create abstract `GoalsRepository` with full API from parent task list.
    - [ ] **2.2.1** Define method signatures returning domain types, not `DocumentSnapshot`.
    - [ ] **2.2.2** Add `watchGoals()` stream contract: emit on snapshot changes; handle empty collection.
  - [ ] **2.3** Implement `FirestoreGoalsRepository`.
    - [ ] **2.3.1** Mirror `PlanningRepository` patterns: `FirestoreClient`, batch writes where helpful.
    - [ ] **2.3.2** `deleteGoal`: delete subcollections first (batch or recursive pattern) per Firestore rules.
    - [ ] **2.3.3** Wire `SyncService` (or existing `_upsertWithQueue`) for offline resilience on `upsert*` failures.
    - [ ] **2.3.4** `getCheckInsForGoal`: query by `goalId` + optional `dateKey` range; index in Firebase if compound query needed.
  - [ ] **2.4** Register `goalsRepositoryProvider`.
    - [ ] **2.4.1** `Provider<GoalsRepository>` or override in tests.
    - [ ] **2.4.2** Export from `goals_providers.dart` and import in `providers.dart` if that’s the project pattern.

- [ ] **3.0 Riverpod providers**
  - [ ] **3.1** `activeGoalsProvider` — filter `status == active`, sort intensity desc, then `updatedAtMs` desc.
    - [ ] **3.1.1** Use `StreamProvider` or `FutureProvider` + refresh — match how `watchGoals` works.
    - [ ] **3.1.2** Handle loading/error states for UI.
  - [ ] **3.2** `archivedGoalsProvider` — paused + completed, `updatedAtMs` desc.
    - [ ] **3.2.1** Single stream that splits in provider **or** two queries — avoid duplicate listeners if possible.
  - [ ] **3.3** `goalDetailProvider.family` — goal + actions + milestones + check-ins for detail screen.
    - [ ] **3.3.1** Define `GoalDetailView` (plain class) holding aggregated data.
    - [ ] **3.3.2** Parallel `Future.wait` for sub-reads after goal doc load.
  - [ ] **3.4** `selectedGoalCategoryFilterProvider` + `filteredActiveGoalsProvider`.
    - [ ] **3.4.1** Toggle same chip → set filter to `null` (All).
    - [ ] **3.4.2** Category id constants shared with editor (single source of truth).
  - [ ] **3.5** `invalidateGoals(ref)` — invalidate active, archived, detail family, filtered derivative.
    - [ ] **3.5.1** If using code-generated riverpod, call correct `ref.invalidate` for each provider.

- [ ] **4.0 Goals home UI (replace `GoalSelectionScreen` body)**
  - [ ] **4.1** Scaffold: `AppBar` **Goals**, `FloatingActionButton` or top **New goal** → `/goals/new` (or named route + args).
    - [ ] **4.1.1** Preserve `GoalSelectionScreen.routeName = '/goals'` by delegating `build` to `GoalsHomeScreen` **or** swap route widget in `app.dart`.
  - [ ] **4.2** Category `Wrap` bound to `selectedGoalCategoryFilterProvider`.
    - [ ] **4.2.1** Visual selected state (neon lime vs dark card) consistent with old `_GoalTile` aesthetic.
    - [ ] **4.2.2** Add “All” chip **or** tap-to-clear behaviour — document in UI.
  - [ ] **4.3** `ListView` / `ListView.builder` of goal rows from `filteredActiveGoalsProvider`.
    - [ ] **4.3.1** Subtitle: horizon + measurement summary (e.g. “90 min/week”).
    - [ ] **4.3.2** Trailing: intensity dots or numeric badge.
    - [ ] **4.3.3** Progress snippet: load light-weight aggregate (optional `goalListRowProvider.family`) or embed counts in `UserGoal` denormalized fields later — v1 can query detail on expand **or** compute from streamed check-ins (keep simple: open detail for full stats).
    - [ ] **4.3.4** `onTap` → `GoalDetailScreen` with `goalId`.
  - [ ] **4.4** Empty state widget: icon + 2 lines copy + CTA **Create a goal**.
    - [ ] **4.4.1** Separate empty for “no goals” vs “no matches for filter”.
  - [ ] **4.5** Archive entry: `ListTile` / button **Paused & completed** → `GoalsArchiveScreen` **or** bottom sheet listing `archivedGoalsProvider`.

- [ ] **5.0 Goal editor (create / edit)**
  - [ ] **5.1** `GoalEditorScreen` with `goalId` nullable; `AppBar` title Create vs Edit.
    - [ ] **5.1.1** `Form` + `GlobalKey<FormState>` validation on title + category.
    - [ ] **5.1.2** `SegmentedButton` / chips for horizon.
  - [ ] **5.2** Monthly: `showDatePicker` in **year/month** mode **or** two `DropdownButton`s for month + year.
    - [ ] **5.2.1** Persist as `periodYear` / `periodMonth` on `UserGoal`.
    - [ ] **5.2.2** Preview string: “March 2025” using same formatting approach as Plan Tomorrow (no `intl` if project avoids it).
  - [ ] **5.3** Daily/weekly: two date pickers start/end; validate `end >= start`.
    - [ ] **5.3.1** Store as `periodStartMs` / `periodEndMs` at local midnight boundaries.
    - [ ] **5.3.2** Weekly: optional helper text “Week runs Mon–Sun” or match **1.6** choice.
  - [ ] **5.4** Measurement: `DropdownButton<MeasurementKind>` + `TextFormField` numeric `target` + optional custom label field.
    - [ ] **5.4.1** Parse int/double safely; show error if empty or non-numeric.
    - [ ] **5.4.2** Helper text varies by horizon (daily vs weekly target copy).
  - [ ] **5.5** Intensity: `Slider` divisions 4 (values 1–5) with labels Low/High ends.
  - [ ] **5.6** Action lines: `Column` of `TextField`s + **Add action**; remove icon per row; min 1 row.
    - [ ] **5.6.1** Cap at ~20 rows with `SnackBar` if exceeded.
  - [ ] **5.7** Save button: disable while submitting; on success `invalidateGoals` + `Navigator.pop`.
    - [ ] **5.7.1** New goal: `StableId.generate('goal')`; new action ids per line.
    - [ ] **5.7.2** Edit: load existing actions; diff delete removed action ids from Firestore.
    - [ ] **5.7.3** Show `SnackBar` on repository error.

- [ ] **6.0 Goal detail — milestones, check-ins, progress**
  - [ ] **6.1** Header section: title, `Chip` category, status, intensity, formatted period, target line.
    - [ ] **6.1.1** Use `Consumer` + `goalDetailProvider(goalId)`.
  - [ ] **6.2** Check-in card: if today’s `dateKey` in period and goal active → show **Mark today done** toggle/button.
    - [ ] **6.2.1** If already checked, show checked state + optional “Undo” with confirm.
    - [ ] **6.2.2** Call `upsertCheckIn`; `invalidateGoals`.
  - [ ] **6.3** Habit stats row: streak + “**X** of **Y** days in this period” using helpers + loaded check-ins.
    - [ ] **6.3.1** Edge case: period not started → Y = 0 or “Starts on …” copy.
  - [ ] **6.4** Milestones: `ReorderableListView` or list with drag handle; checkbox toggles `completed`.
    - [ ] **6.4.1** Inline add: `TextField` + icon add; persist new milestone with next `orderIndex`.
    - [ ] **6.4.2** Delete with `AlertDialog`.
    - [ ] **6.4.3** On reorder, batch `upsertMilestone` for changed order indices.
  - [ ] **6.5** Milestone summary: `LinearProgressIndicator` value = completed/total (0 if total 0).
  - [ ] **6.6** `PopupMenuButton`: Edit, Pause, Mark complete, Delete.
    - [ ] **6.6.1** Pause → `status = paused`; Complete → `status = completed`.
    - [ ] **6.6.2** Delete → confirm dialog + `deleteGoal`.

- [ ] **7.0 Archive and reopen**
  - [ ] **7.1** `GoalsArchiveScreen`: `ListView` of archived from `archivedGoalsProvider`; show status icon + `updatedAt` relative or date.
    - [ ] **7.1.1** Tap → same `GoalDetailScreen` with `goalId`.
  - [ ] **7.2** On detail when `status != active`: show prominent **Resume** / **Reopen** button.
    - [ ] **7.2.1** Sets `status = active`; `upsertGoal`; pop or stay per UX choice.
    - [ ] **7.2.2** Do not wipe check-ins/milestones on reopen.
  - [ ] **7.3** After any status change, call `invalidateGoals` from **6.6** / **7.2** handlers.

- [ ] **8.0 Routing and cleanup**
  - [ ] **8.1** `app.dart`: routes `GoalEditorScreen.routeName`, `GoalDetailScreen.routeName`, `GoalsArchiveScreen.routeName` (if separate).
    - [ ] **8.1.1** Pass `goalId` via `ModalRoute.settings.arguments` typed class (e.g. `GoalEditorArgs`).
  - [ ] **8.2** Delete placeholder UI from `goal_selection_screen.dart`; keep only thin wrapper if route stability needed.
  - [ ] **8.3** Grep for `/goals` and Home `GoalSelectionScreen.routeName`; confirm footer still opens goals.

- [ ] **9.0 Firebase rules and docs**
  - [ ] **9.1** `documentation/firebase-rules.md`: example match for `match /users/{userId}/goals/{goalId}` and subcollections; `allow read, write: if request.auth != null && request.auth.uid == userId`.
    - [ ] **9.1.1** Note composite indexes if `checkIns` queries by range.
  - [ ] **9.2** Deploy rules in Firebase console / CLI; smoke-test read/write as authenticated user.

- [ ] **10.0 QA**
  - [ ] **10.1** Monthly March goal: first/last day check-in eligibility; cannot check in for April 1 for that goal.
  - [ ] **10.2** Weekly + sessions: labels show “sessions per week” (or agreed copy).
  - [ ] **10.3** Filter Study → only study goals; create new Study goal → appears.
  - [ ] **10.4** Pause from menu → archive list; reopen → active list; data preserved.
  - [ ] **10.5** `dart analyze lib` on CI/local; fix new issues in `lib/features/goals/**`.
