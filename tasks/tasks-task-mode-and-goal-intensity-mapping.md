# Tasks — Per-task execution mode + goal intensity → mode mapping

**Goal intensity policy (option 2, no removal of intensity):**

| Intensity | Effective mode (concept) |
|-----------|--------------------------|
| 1–2       | Flexible / normal        |
| 3–4       | Disciplined              |
| 5         | Extreme                  |

**Scope:** Add explicit mode selection on **Add Task / edit task**, default from routine where possible; derive execution strictness for **goals** from existing **intensity** using the table above (UI copy + any services that need a `RoutineMode`-like policy).

---

## 1.0 Per-task execution mode (Add Task + persistence)

- [x] **1.1** Add Task UI: mode selector + strict toggle
  - [x] **1.1.1** Add `_modeRefId` (or enum-backed) state defaulting to `flexible`.
  - [x] **1.1.2** Add `_strictModeRequired` bool state default `false`.
  - [x] **1.1.3** Build segmented buttons or `DropdownButtonFormField` for Flexible / Disciplined / Extreme (`storageValue` = `flexible` | `disciplined` | `extreme`).
  - [x] **1.1.4** Add `SwitchListTile` or checkbox for “Strict for this task” bound to `_strictModeRequired`.
  - [x] **1.1.5** Match spacing/typography to existing Add Task sections (dark theme).

- [x] **1.2** Load mode fields when editing
  - [x] **1.2.1** After `_loadedTask` is ready, set `_modeRefId` from `modeRefId ?? 'flexible'` (or map null → flexible).
  - [x] **1.2.2** Set `_strictModeRequired` from `loaded.strictModeRequired`.
  - [x] **1.2.3** Ensure re-build doesn’t reset user edits on subsequent `setState`.

- [x] **1.3** Save on all `PlannedTask` paths
  - [x] **1.3.1** Include `modeRefId` + `strictModeRequired` in `_buildPlannedTask`.
  - [x] **1.3.2** Audit create branch (new task): same fields passed to `upsertTask`.
  - [x] **1.3.3** Audit edit branch and move-day / delete+recreate paths for parity.
  - [x] **1.3.4** Grep `PlannedTask(` in `add_task_screen.dart` for any missed constructor.

- [x] **1.4** Default from parent Routine
  - [x] **1.4.1** When opening Add Task with slot args, `getRoutine(routineId)` or pass mode from args if already available.
  - [x] **1.4.2** If routine has `modeId` / `mode`, seed `_modeRefId` for **new** tasks only (not when editing existing with saved mode).
  - [x] **1.4.3** If routine fetch fails or id missing, keep `flexible` default.

- [x] **1.5** ReminderConfig alignment
  - [x] **1.5.1** Extend `_persistReminder` to set `modeRefId` from task’s chosen mode.
  - [x] **1.5.2** Optionally set `blockUrgencyScore` when block context is known (fetch block or default 50).
  - [x] **1.5.3** After `upsertReminder`, `syncForTaskIds([taskId])` still refreshes cache.

- [x] **1.6** Stop reminders on action / reason
  - [x] **1.6.1** Call `markTaskStarted(taskId)` when timer starts for that task (ExecutionController or Timer screen).
  - [x] **1.6.2** Call `markLogicalReasonProvided(taskId)` (or `markTaskStarted`) when override flow logs valid reason for that task.
  - [x] **1.6.3** Call on task complete if reminder should clear (align with product: complete = started+done).
  - [x] **1.6.4** Optional: `onDidReceiveNotificationResponse` in `LocalNotificationsService` to open app + stop/snooze — only if timeboxed.

- [x] **1.6.5** Auto-repeat cadence (no user action)
  - [x] Flexible: one-shot by default (repeat only on explicit snooze).
  - [x] Disciplined: 3 nudges in first 10m, then 3 nudges over next 30m, then hourly.
  - [x] Extreme: 3 nudges in first 10m, then 5 nudges over next 30m, then hourly × 5.
  - [x] Notification body tap opens timer with 10s auto-start countdown + cancel; start is still explicit/cancellable.

- [x] **1.7** Tests
  - [x] **1.7.1** Unit: `PlannedTask.toMap` / `fromMap` preserves `modeRefId` + `strictModeRequired`.
  - [ ] **1.7.2** Widget or integration: save task with disciplined mode → Firestore mock / repository sees correct payload.
  - [x] **1.7.3** Reminder config includes `modeRefId` when reminder enabled (unit on builder or screen test).

---

## 2.0 Goal intensity → execution mode mapping (keep intensity field)

- [x] **2.1** Pure helper module
  - [x] **2.1.1** Add e.g. `lib/features/goals/application/goal_intensity_mode.dart` (or under `domain/`).
  - [x] **2.1.2** `RoutineMode routineModeFromGoalIntensity(int intensity)` with clamp 1–5.
  - [x] **2.1.3** `String modeRefIdFromGoalIntensity(int intensity)` returning `.name` for Firestore consistency.
  - [x] **2.1.4** Document table in a single doc comment on the function.

- [x] **2.2** Use helper in goal flows
  - [x] **2.2.1** `GoalReminderSyncService` / schedule: if policy needs mode, pass derived `modeRefId` for notification cadence (when goal reminders expand beyond daily-once).
  - [x] **2.2.2** Goal detail: any “strictness” copy uses derived mode from `goal.intensity`.
  - [x] **2.2.3** Avoid duplicating the mapping table elsewhere — import helper only.

- [x] **2.3** Goal editor UX
  - [x] **2.3.1** Below intensity slider/stepper, add one line subtitle: `1–2 flexible · 3–4 disciplined · 5 extreme`.
  - [x] **2.3.2** Optional: update intensity section title to “Intensity (discipline level)” if copy review OK.

- [x] **2.4** Goal detail (optional)
  - [x] **2.4.1** Show read-only chip: `Mode: ${derivedMode.label}` from intensity helper.
  - [x] **2.4.2** No new `UserGoal` fields; derive in `build` only.

- [x] **2.5** Tests
  - [x] **2.5.1** intensity 1, 2 → `RoutineMode.flexible`.
  - [x] **2.5.2** intensity 3, 4 → `RoutineMode.disciplined`.
  - [x] **2.5.3** intensity 5 → `RoutineMode.extreme`.
  - [x] **2.5.4** intensity 0 or 6+ → clamp and assert stable result (or document ArgumentError).

---

## 3.0 Effective policy resolution (tasks + cross-feature consistency)

- [x] **3.1** Resolver helper
  - [x] **3.1.1** Add e.g. `lib/features/planning/application/effective_task_mode.dart`: `String effectiveModeRefId({PlannedTask task, Routine? routine})`.
  - [x] **3.1.2** Order: known `task.modeRefId` (`flexible` | `disciplined` | `extreme`) wins; else valid `routine.modeId` / `routine.mode`; else `'flexible'`.
  - [x] **3.1.3** Unknown task `modeRefId` strings fall through to routine / default (not applied as-is).

- [x] **3.2** Replace ad-hoc reads
  - [x] **3.2.1** `ExtensionPolicy` / `home_screen` extension flow: pass effective mode from resolver + routine fetch if needed.
  - [x] **3.2.2** `OverrideRules` / mandatory timer paths: use resolver when task mode null.
  - [x] **3.2.3** `ReminderConfig` builds from task: `modeRefId` for save uses same resolver (`AddTaskScreen._effectiveModeRefIdForSave`).
  - [x] **3.2.4** Grep `modeRefId`, `RoutineMode`, `ExtensionPolicy.forTask` for drift.

- [x] **3.3** Documentation
  - [x] **3.3.1** Top-of-file comment on `effective_task_mode.dart` linking goal intensity helper.
  - [x] **3.3.2** One line in `tasks/manual-qa-v2.md` that task override beats routine.

---

## 4.0 Verification & docs

- [ ] **4.1** Manual QA
  - [ ] **4.1.1** Append subsection to `tasks/manual-qa-v2.md`: new task default mode matches slot; override persists after edit.
  - [ ] **4.1.2** Goal editor shows intensity legend; detail shows derived mode if implemented.
  - [ ] **4.1.3** Device: reminder cadence smoke per task mode (if 1.5–1.6 done).

- [ ] **4.2** Regression
  - [ ] **4.2.1** Plan Tomorrow: change slot mode → new task from that slot gets default mode.
  - [ ] **4.2.2** Existing tasks without `modeRefId` in Firestore still load and resolve via routine/flexible.

---

## Notes

- Goals **do not** need a new `modeRefId` field if policy is always derived from `intensity`; avoid duplicate sources of truth.
- If product later wants explicit goal mode independent of intensity, add a field and “custom vs derived” flag in a follow-up task.
