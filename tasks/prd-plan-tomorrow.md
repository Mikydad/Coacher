# PRD — Plan Tomorrow

## 1. Introduction / Overview

**Plan Tomorrow** is a structured daily planning screen that users open by tapping the "Plan Tomorrow" button on the Home screen. It replaces the current placeholder Goal Selection screen for that entry point.

The screen shows a user's plan for the **next calendar day**, organised into time-of-day routine **slots** (Morning, Afternoon, Night by default). Each slot is a collapsible section that lists its tasks. Users can add tasks to any slot, edit or delete them, rename slots, reorder slots, and add or remove custom slots. When they're done, a confirmation summary is shown before the screen closes.

**Problem it solves:** Users currently have no structured way to plan the next day. Tasks added for tomorrow appear in a flat list with no sense of when during the day they belong. This screen gives tomorrow a clear time structure and lets users enter each task with full detail (duration, priority, category, reminder, notes) before the day begins.

---

## 2. Goals

1. A user can open "Plan Tomorrow" and see tomorrow's date and any tasks already saved for that day, organised into routine slots.
2. A user can add a task to any slot using the existing Add Task screen, pre-set to tomorrow's date and the chosen slot's routine.
3. A user can edit or delete any task already in tomorrow's plan from this screen.
4. A user can reorder tasks within a slot via drag-and-drop.
5. A user can rename, reorder, add, and delete routine slots.
6. Today's incomplete tasks are surfaced as a "carry-forward" suggestion so users can easily re-plan them for tomorrow.
7. Tapping "Done" saves all changes and shows a brief summary before returning to Home.

---

## 3. User Stories

- **As a user**, I want to see tomorrow's date and my plan for each part of the day so I can feel prepared before I sleep.
- **As a user**, I want to add a new task to my Morning routine with a reminder at 7:30 AM so I don't forget to do it.
- **As a user**, I want to carry forward a task I didn't finish today into tomorrow's Afternoon slot so it stays on my radar.
- **As a user**, I want to rename "Night" to "Evening Wind-Down" and add a custom "Pre-Workout" slot so the plan fits my actual schedule.
- **As a user**, I want to delete a task I accidentally added to the wrong slot and add it to the correct one.
- **As a user**, I want to see a summary of what I've planned before I close the screen so I feel confident about tomorrow.

---

## 4. Functional Requirements

### 4.1 Entry Point
1. The "Plan Tomorrow" button on the Home screen must navigate to the Plan Tomorrow screen (`/plan-tomorrow` route), **not** the existing Goal Selection screen.

### 4.2 Screen Header
2. The screen must display an app bar with the title **"Plan Tomorrow"** and tomorrow's full date (e.g. "Sunday, Mar 22").
3. The screen must show a motivational sub-headline in the Quittr neon dark style (e.g. "Design your tomorrow.").

### 4.3 Routine Slots — Default State
4. When a user opens Plan Tomorrow for the **first time** (no existing tomorrow routines in Firestore), the screen must create and display three default slots in order: **Morning**, **Afternoon**, **Night**.
5. Each slot is stored as a `Routine` document in Firestore with `dateKey = tomorrowKey()` and the slot title as `Routine.title`.
6. If tomorrow's routines already exist in Firestore (user planned before), the screen must load and display them in their saved order.

### 4.4 Slot Expansion / Collapse
7. Each slot must render as a collapsible header. Tapping the header toggles the task list open or closed.
8. Slots must default to **expanded** on first open.
9. The header must show the slot title, the count of tasks in that slot (e.g. "3 tasks"), and an expand/collapse icon.

### 4.5 Task List Inside a Slot
10. Each task row must display: **title**, **duration**, **priority** (shown as a label or badge, e.g. "High"), and **category** chip if set.
11. Each task row must show a reminder indicator (bell icon) if a reminder is enabled for that task.
12. Each task row must support **edit** (opens Add Task screen in edit mode for that task) and **delete** (confirmation dialog before deleting).
13. Tasks within a slot must be **reorderable** via drag-and-drop. The new order must be persisted to Firestore immediately.

### 4.6 Adding a Task to a Slot
14. Each expanded slot must show an **"+ Add Task"** button at the bottom of its task list.
15. Tapping "+ Add Task" must navigate to the existing `AddTaskScreen` with:
    - The **plan day pre-set to tomorrow** (so `_planDateKey()` returns `tomorrowKey()`).
    - The **routine pre-selected** to that slot's routine (the `routineId` and `blockId` are passed as context so the task is saved under the correct slot).
16. When the user saves from Add Task and returns, the slot must refresh and show the new task.

> **Task fields available on Add Task (all required for this flow):**
> - Title (text field)
> - Duration (15 MIN / 25 MIN / 45 MIN / 1 HOUR chips)
> - Category (Study / Fitness / Work / Personal / Planning chips)
> - Priority (1–5, represented as High / Medium / Low or a 5-star selector)
> - Reminder toggle + date/time picker (fires a local notification at the chosen time)
> - Notes / description field *(to be added to Add Task screen — see section 7)*
> - Status (defaults to `notStarted` at plan time)

### 4.7 Carry-Forward: Today's Incomplete Tasks
17. Below the slot list, the screen must show a collapsible **"Unfinished from Today"** section.
18. This section must list all tasks from today's plan (`todayKey()`) whose status is `notStarted`, `inProgress`, or `partial`.
19. Each item in this section must have a **"Move to Tomorrow →"** button. Tapping it must:
    - Prompt the user to pick which slot to move it into (bottom sheet or dialog with slot names).
    - Delete the task from today's routine.
    - Save it under the chosen tomorrow slot's routine with `planDateKey = tomorrowKey()`.
    - Refresh both today's and tomorrow's data.
20. If there are no incomplete tasks today, this section must be hidden entirely.

### 4.8 Slot Management
21. A **"+ Add Slot"** button must appear below all existing slots. Tapping it opens a dialog asking for a slot name. Confirming creates a new `Routine` with `dateKey = tomorrowKey()` appended at the end of the list.
22. Long-pressing a slot header (or tapping a "⋮" menu on the header) must offer **Rename**, **Reorder**, and **Delete** actions.
    - **Rename:** inline text edit or dialog; persists the new `Routine.title` to Firestore.
    - **Reorder:** drag handle on the slot header moves the entire slot (and its tasks) to a new position; `orderIndex` values are updated in Firestore for all affected routines.
    - **Delete:** confirmation dialog. If the slot has tasks, the dialog must warn the user ("This will also delete N tasks"). On confirm, deletes the `Routine` and all its `TaskBlock` and `PlannedTask` children.
23. A slot cannot be deleted if it is the only one remaining. The delete action must be disabled in that case.

### 4.9 Done / Summary
24. A **"Done — See Summary"** primary button must be fixed at the bottom of the screen (above the keyboard when focused).
25. Tapping it must navigate to (or show as a modal/bottom sheet) a **Plan Summary** view that lists:
    - Tomorrow's date.
    - Each slot name with its task count and total planned duration.
    - A list of any tasks with reminders set (title + reminder time).
26. The summary must have a **"Close"** button that pops back to Home.

### 4.10 Persistence
27. All create/update/delete operations must use the existing `PlanningRepository` and `upsertTask` / `upsertRoutine` / `deleteTask` / `deleteRoutine` methods so the offline sync queue remains intact.
28. Every `PlannedTask` saved from this screen must have `planDateKey = tomorrowKey()` set.
29. Providers `todayAllTasksRowsProvider` and `executionDayTasksProvider` must be invalidated after carry-forward moves (today's list changes).

---

## 5. Non-Goals (Out of Scope)

- **AI-generated task suggestions** — will not be included in this sprint.
- **Recurring / repeating tasks** — "Do this every morning" repeat patterns are deferred.
- **Calendar app sync** — no Google Calendar / Apple Calendar integration.
- **Push notification delivery for the new "persistent reminder"** (the check-again-until-done reminder type described in Q2) — that is a separate future feature. The existing single local notification at a chosen time is sufficient for this sprint.

---

## 6. Design Considerations

- Match the existing Quittr dark neon aesthetic: black/dark background (`#0A0A0C`), neon green accent (`#B7FF00`), cyan label (`#00E6FF`), white text, rounded cards.
- Slot headers use large bold typography (similar to section headings on Home). A chevron icon rotates on expand/collapse.
- Task rows are compact cards (similar to the Tasks Hub `_HubTaskTile` style) with swipe-to-delete or trailing icon buttons for edit/delete.
- The "Unfinished from Today" section uses a muted colour (e.g. `Colors.white54` heading) to distinguish it from tomorrow's own slots.
- The Plan Summary sheet uses the same neon card style as Home's streak card.
- The fixed "Done" button matches the `FilledButton` style used throughout (green background, black text, full width, 60 px height).

---

## 7. Technical Considerations

### Existing data model (reuse as-is)
- **`Routine`** (`id`, `title`, `dateKey`, `orderIndex`) — one per slot per day.
- **`TaskBlock`** (`id`, `routineId`, `title`, `orderIndex`) — one default block per routine (title "Main"), created by `ensureDefaultDayPlan`.
- **`PlannedTask`** — all fields already present; `planDateKey` added in the current sprint.
- **`ReminderConfig`** — existing reminder pipeline handles local notifications.

### Model change needed
- `PlannedTask` needs a **`notes`** field (`String?`) for the description/notes requirement in 4.6. Add it to `toMap`, `fromMap`, and the `PlannedTask` constructor (optional, safe for existing docs).

### Provider / repository changes needed
- A new **`tomorrowRoutineSlotsProvider`** that loads all routines for `tomorrowKey()` from Firestore (server-preferred), ensures three defaults if none exist, and exposes `List<Routine>`.
- A new **`tomorrowTasksForRoutineProvider(routineId)`** (family provider) that loads `PlannedTaskRow` list for a single routine slot.
- `AddTaskScreen` needs to accept an **optional pre-set `routineId` + `blockId`** override so "Add Task" from a slot saves directly into that slot rather than calling `ensureDefaultDayPlan` (which would pick or create a generic first routine).
- Alternatively, a simpler approach: pass `AddTaskEditArgs`-style context with `dateKey = tomorrowKey()` and a specific `routineId` / `blockId` through the route arguments.

### Firestore path (unchanged)
```
users/{uid}/routines/{routineId}
users/{uid}/routines/{routineId}/blocks/{blockId}
users/{uid}/routines/{routineId}/blocks/{blockId}/tasks/{taskId}
```
Multiple routines sharing the same `dateKey` is already handled — the query `where('dateKey', isEqualTo: ...)` returns all of them.

### Route
- New route: `/plan-tomorrow` → `PlanTomorrowScreen`.
- Wire in `app.dart` routes map.
- Update Home "Plan Tomorrow" button to navigate to `/plan-tomorrow` instead of `/goals`.

---

## 8. Success Metrics

- A user can open Plan Tomorrow, add at least one task to each slot, set a reminder on one of them, and tap Done — seeing the summary — within 2 minutes.
- Tasks saved from Plan Tomorrow appear in the correct date on the Tasks Hub "Open on other days" section until that day arrives.
- Carry-forward moves a task from today's list and it no longer appears on Home (today) but does appear on Plan Tomorrow (tomorrow).
- No tasks planned for tomorrow appear on today's Home or Focus screens.

---

## 9. Open Questions

1. Should the **slot default times** (Morning / Afternoon / Night) pre-fill the reminder time picker when a user enables a reminder? (e.g. Morning defaults to 7:00 AM, Afternoon 1:00 PM, Night 8:00 PM.) This would improve UX but requires storing a `defaultReminderHour` on the Routine model.
2. If the user opens Plan Tomorrow at 11 PM the night before and again at 6 AM on the same day, should the screen warn them that "tomorrow" is now the same day (i.e. today)?
3. Should **reordering slots** also reorder them for future days, or only affect tomorrow's copy?
4. The `notes` field on `PlannedTask` needs to be added to the `AddTaskScreen` UI — is a simple multi-line text field below the title sufficient, or should it be a secondary screen/bottom sheet?
