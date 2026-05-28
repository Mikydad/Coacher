# PRD: Inline scheduling conflict resolution & form draft persistence

**Status:** Draft  
**Problem:** Creating a task or goal at a time that overlaps an existing item forces the user to leave the form, fix the other item elsewhere, and return — often re-entering all fields from scratch.  
**Vision:** Coach feels like a smart assistant: detect overlap, resolve **in place**, keep the original form alive, then save once.

---

## 1. Background (current behavior)

| Step | Today |
|------|--------|
| User fills Add Task / Goal editor | Form state lives only in `StatefulWidget` controllers |
| Save → conflict (moderate/severe) | `ConflictBottomSheet`: Save anyway / **Adjust time** / Shorten duration |
| User wants to fix the **other** item | Must navigate away; form state is lost on dispose |
| Return to create | Re-type title, time, duration, notes, actions |

**Existing assets to reuse (do not rewrite):**

- `TimeBlockSyncService`, `ConflictDetectionEngine`, `TimeBlockRepository`
- `TimeConflict`, `ConflictCheckResult`, `ConflictSeverity`
- `buildSchedulingConflictEntityTitles` / `conflict_entity_title_resolver.dart`
- `ConflictBottomSheet` (Phase 2 replaces/extends for moderate+ severe)
- `AddTaskScreen._checkTimeBlockConflicts`, `GoalEditorScreen._checkGoalTimeBlockConflicts`
- `GoalBlockSyncService` for goal time blocks

---

## 2. Goals

1. **Never lose in-progress create/edit data** when the user briefly leaves to fix a schedule (or when the app is backgrounded).
2. **Resolve overlaps without leaving** the task/goal form for the common case (move one of the two items).
3. **Show human-readable choices**: which item to move, current window, 1–2 suggested windows, custom time.
4. **Re-check conflicts** after each inline change until clean or user explicitly allows overlap.
5. Preserve **Save anyway** for power users.

---

## 3. Non-goals (v1)

- Full calendar drag-and-drop editor.
- AI-generated reschedule prose (optional Phase 3).
- Conflict resolution from Home / Tasks hub list rows (create/edit flows only in v1).
- Persisting drafts across app reinstall (local only, same device).
- Multi-day batch reschedule of entire routines.

---

## 4. User stories

1. **As a** user creating Workout at 5:00–5:30, **when** it overlaps Morning Routine, **I want** to move Morning Routine to 5:30–6:00 **without leaving** the Workout form, **so that** I can save in one session.
2. **As a** user who tapped away to check something, **I want** my half-filled Add Task form restored within ~30–60 minutes, **so that** I don’t re-enter everything.
3. **As a** user editing a goal with a daily reminder time, **I want** the same inline conflict flow as tasks.
4. **As a** user who must overlap intentionally, **I want** **Allow overlap** to remain available with clear labeling.

---

## 5. Functional requirements

### Phase 1 — Form draft persistence

**FR-D1** — Add Task draft snapshot includes: title, notes, duration chip key, category, reminder on/off, reminder `DateTime`, mode, habit anchor, strict, rigid, focus session (if applicable), edit args identity (`taskId` when editing), `savedAtMs`.

**FR-D2** — Goal editor draft snapshot includes: title, target, category, horizon, period fields, reminder, intensity, measurement, and all action draft rows (id, title, completed).

**FR-D3** — Drafts stored in **local persistence** (Isar collection or `shared_preferences` JSON — prefer Isar if already used for similar ephemeral state; else a small dedicated store). TTL default **60 minutes** (config constant).

**FR-D4** — On `AddTaskScreen` / `GoalEditorScreen` `initState`: if a non-expired draft exists for that screen key (`add_task_create`, `add_task_edit:{taskId}`, `goal_create`, `goal_edit:{goalId}`), offer **Restore draft?** dialog (Restore / Start fresh). Auto-restore optional setting deferred.

**FR-D5** — Draft saved on: `dispose`, app lifecycle `paused`/`inactive`, and debounced every ~10s while form is dirty.

**FR-D6** — Draft cleared on successful save, explicit “Start fresh”, or TTL expiry.

**FR-D7** — Draft must **not** overwrite a successful save with stale data (clear before navigation pop on save).

### Phase 2 — Inline conflict resolver

**FR-C1** — Replace moderate/severe-only bottom sheet with **`SchedulingConflictSheet`** (new widget) that receives:
- Proposed entity (title, kind `task`|`goal`, id if edit, `startAt`, `durationMinutes`, rigid, modeRefId)
- `List<TimeConflict>`
- Callbacks: `onResolved`, `onCancel` (stay on form)

**FR-C2** — Primary prompt: **Choose an action** with three paths:
- **Move [conflicting title]** — user reschedules the *existing* block
- **Move [proposed title]** — user adjusts the *draft* time/duration on the form (updates parent state via callback)
- **Allow overlap** — same as today’s save anyway

**FR-C3** — **Move existing item** expands inline panel:
- Shows current start–end (formatted)
- Shows **Suggested A** and **Suggested B** (computed — see §6)
- **Custom time** opens time picker (+ duration for tasks; goals use `kGoalBlockDefaultDurationMinutes` unless task path)
- **Apply** persists the other entity’s schedule (task: `upsertTask` + reminder + `syncBlock`; goal: `upsertGoal` reminder fields + `GoalBlockSyncService.syncBlockForGoal`) **without** navigating to another screen

**FR-C4** — **Move proposed item** collapses panel and focuses parent form’s time/duration controls (scroll into view + highlight); re-run conflict check when user taps **Check schedule** or on next save attempt.

**FR-C5** — After any successful move of the *other* entity, show confirmation chip: `Morning Routine → 5:30–6:00 ✓` and re-run `checkConflicts` for proposed block. If clear → enable **Continue & save** or auto-return to save flow.

**FR-C6** — `AddTaskScreen._checkTimeBlockConflicts` returns extended result type e.g. `ConflictResolutionOutcome { proceed, adjustedStart?, adjustedDuration? }` instead of only `bool`.

**FR-C7** — `GoalEditorScreen` uses the same sheet; proposed block from `GoalBlockSyncService` derivation.

**FR-C8** — Minor severity: keep current SnackBar auto-continue behavior (no sheet).

### Phase 3 — Polish & intelligence

**FR-P1** — Slot suggestions use day-aware scan: load all blocks for plan day, find gaps ≥ proposed duration, prefer nearest gap after conflict end (or after proposed start).

**FR-P2** — Show stacked conflicts when >1 overlap (pick which to resolve first).

**FR-P3** — Analytics: `overlap_resolved_inline`, `draft_restored`, `draft_discarded`.

**FR-P4** — Widget tests for slot finder + sheet interaction (golden or pump).

**FR-P5** — Optional: “Apply suggestion to both” when user created duplicate habit (out of scope unless trivial).

---

## 6. Suggested time algorithm (v1)

Input: `planDate` (local day), `durationMinutes`, `avoidBlockIds`, existing blocks for that day.

1. Build sorted list of occupied intervals from `TimeBlockRepository` for `[dayStart, dayEnd]`.
2. Candidate A: start at `conflictBlock.computedEndAt` (end of overlapping block).
3. Candidate B: start at Candidate A + `durationMinutes` (stack after).
4. If Candidate A still overlaps, scan forward in 15-minute steps until free or end of day.
5. Cap suggestions at 2 labeled options; custom always available.

Unit-test the pure function in `scheduling_slot_suggestions.dart`.

---

## 7. UX wireframe (reference)

```
Create task: Workout  5:00 AM · 30m
────────────────────────────────────
⚠ Overlap with Morning Routine (5:00–5:30)

Choose an action:
[ Move Morning Routine ]
[ Move Workout        ]
[ Allow overlap       ]

▼ Move Morning Routine
  Current: 5:00 – 5:30
  Suggested: 5:30 – 6:00  [Apply]
  Alternative: 6:00 – 6:30 [Apply]
  [ Custom time… ]

[ Continue ]  (enabled when no severe conflict remains)
```

Parent form remains mounted underneath (modal sheet does not pop the route).

---

## 8. Technical considerations

| Topic | Decision |
|--------|----------|
| Draft storage | New `FormDraftRepository` + Isar model OR `SharedPreferences` for v1 speed — document in tasks |
| Sheet vs route | `showModalBottomSheet(isScrollControlled: true)` — parent `AddTaskScreen` stays in tree |
| Moving other task | Need load path: `PlanningRepository.getTask` by ids from `TimeConflict` + block metadata; goals via `GoalsRepository.getGoal` |
| Edit vs create | Proposed entity may not exist in DB yet — moving “other” only; proposed updates via callback to parent state |
| Conflict re-check | Call existing `checkConflicts` with updated `entityTitles` map |
| Permissions | No new Firebase rules |

---

## 9. Success metrics

- % of conflict saves that use inline move vs navigate away (analytics)
- Reduction in abandoned Add Task sessions after conflict (proxy: draft restore used + eventual save)
- QA: zero field loss on restore within TTL

---

## 10. Open questions (defaults for v1)

| Question | Default |
|----------|---------|
| TTL | 60 minutes |
| Auto-restore without dialog | No — always ask Restore / Start fresh |
| Phase 1 before Phase 2? | Yes — ship draft persistence first (1–2 days) |
