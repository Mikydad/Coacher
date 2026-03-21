# PRD: Today’s tasks — plan date rules, home interactions, and tasks hub

## 1. Introduction / overview

Users need a clear model for **which calendar day a task belongs to**, quick **completion** from the home screen without extra navigation, and a **dedicated hub** to see today’s work in full and manage it (including **editing** via the existing Add Task flow). Completion **percentage** (from scoring / partial completion) should be visible as extra context wherever tasks are listed in detail.

This PRD aligns with product choices:

- **Plan date (1B):** Unless the user targets another day via the reminder, the task is for **today** and stored under **today’s** `dateKey`. If the user sets a reminder for **another calendar day**, the task is stored under **that day’s** `dateKey` (it will surface on Home’s “today” section only when that day is actually “today”).
- **Hub scope (2C):** The tasks hub supports **full management**: view, reorder, delete, edit (via Add Task), plus showing **completion %** where available.
- **Home UX (3–4):** Users can **check off / complete** tasks by interacting with the row on Home **without** opening the hub. Tapping the **“Today’s Tasks” heading** or a **small affordance** (e.g. chevron) on the card opens the hub. From the hub, **per-task edit** opens **Add Task** with **current data pre-filled**; saving updates Firestore and returns appropriately.
- **List differentiation (5C):** **Home** shows tasks **due today** (`dateKey == todayKey`). The **hub** shows **today’s tasks in full** **and** a separate view of **other open tasks** (not completed) **across other plan days**, so users see both “today” and “still open elsewhere.”

## 2. Goals

1. Make **plan date** predictable: default **today**; **reminder on another day** implies **plan date = that day**.
2. Reduce friction: **complete / tick** tasks from **Home** in one tap (or clear gesture) without opening the hub.
3. Provide a **Tasks** hub with **full list**, **management** actions, and **completion %** visibility.
4. Reuse **Add Task** for **edit** with **prefill** and **save** to avoid duplicate forms.
5. Differentiate **Home (today only)** vs **hub (today + cross-day open)** per **5C**.

## 3. User stories

1. **As a** user adding a task **without** changing the reminder to another day, **I want** the task saved for **today**, **so that** it appears in **Today’s Tasks** on Home and in the hub’s today section.
2. **As a** user setting a reminder on **another calendar day**, **I want** the task’s **plan date** to match that day, **so that** it appears on Home when that day is “today” and doesn’t clutter today’s list before then.
3. **As a** user on Home, **I want** to **mark a task done** by tapping the task row (or a control on it), **so that** I don’t have to open another screen.
4. **As a** user, **I want** to tap **“Today’s Tasks”** or a **chevron** to open a **Tasks** screen, **so that** I see the **full** today list and cross-day open items.
5. **As a** user on the hub, **I want** to see **completion percentage** (e.g. after a partial scoring session), **so that** I understand progress beyond a simple checkbox.
6. **As a** user on the hub, **I want** to **reorder**, **delete**, and **edit** tasks, **so that** I can manage my plan in one place; **edit** should open Add Task with **existing values** filled in.

## 4. Functional requirements

### Plan date & Add Task

1. The system **must** default new tasks to **`dateKey = todayKey`** (local calendar) when the user does **not** assign a reminder to a **different calendar day** than today.
2. The system **must** set the task’s **`dateKey`** (and thus the routine/block used under `ensureDefaultDayPlan`) to the **reminder’s calendar day** when the user explicitly sets a reminder for **another day** than today (per **1B**).
3. Add Task **must** expose UI to pick a **reminder date** when needed (not only time-of-day), so “another day” is unambiguous.
4. On save, the system **must** persist `PlannedTask` (and linked reminder config) consistently with the chosen **`dateKey`** and **task id**.

### Home — Today’s Tasks card

5. The Home **“Today’s Tasks”** section **must** load and display only tasks whose **plan `dateKey`** equals **`todayKey`** (and respect existing status rules for what “listed” means, e.g. hide `completed` or show with strikethrough — **open question** if we hide completed on Home).
6. The user **must** be able to **mark a task complete** (or toggle done) **from the row** without navigating to the hub (e.g. tap checkbox or the row’s leading control).
7. Tapping the **section title** “Today’s Tasks” **or** a **small arrow/chevron** on the card **must** navigate to the **Tasks hub** route.
8. Home **may** continue to show a **compact** subset (e.g. first N tasks) if needed for layout, but **must** make clear that more exist (e.g. “+3 more”) **or** show all — **open question** for final layout.

### Tasks hub screen

9. The hub **must** include a **primary section**: all tasks for **`todayKey`**, with **full** detail appropriate to the row (title, duration, category if set, reminder summary, **completion %** if known, status).
10. The hub **must** include a **secondary section**: **open** tasks (`notStarted` or `inProgress`, and optionally `partial` per product rules) whose **`dateKey` ≠ `todayKey`**, grouped or labeled by date so users understand **which day** each belongs to (implements **5C**).
11. The hub **must** support **reorder** for tasks **within the same block/day grouping** (or document if reorder is today-only in v1 — see open questions).
12. The hub **must** support **delete** with confirmation (or undo pattern).
13. **Edit** on a task **must** navigate to **Add Task** in **edit mode** with **all persisted fields** pre-filled; **Save** **must** update the existing document (same ids) and refresh providers/lists.
14. The hub **must** display **completion percentage** from the app’s scoring source (e.g. map `taskId` → latest or aggregate score %) when available; if none, show neutral state (e.g. “—” or “Not scored”).

### Navigation & state

15. After add/edit/delete/reorder, the system **must** **invalidate or refresh** providers so Home and hub stay consistent.
16. Routes **must** be registered in the app shell (e.g. `/tasks` hub, `/add-task?taskId=` or arguments object for edit).

## 5. Non-goals (out of scope)

- Building a separate **design system** beyond existing app theme (reuse current neon/card patterns).
- **Server-side** migration of legacy tasks created under old date rules (manual or one-off script acceptable later).
- **Push** notification content redesign (only reminder **date** linkage to plan date is in scope).
- **Collaborative / shared** tasks.

## 6. Design considerations

- Reuse **`_NeonCard`**, typography, and **lime accent** from Home / Add Task.
- **Today’s Tasks** card: add a **trailing chevron** or **“View all”** aligned with the title row; avoid accidental navigation when the user intends to tap a task row — use **hit targets** (title/chevron vs row body).
- Hub: clear **section headers** — e.g. **“Today”** and **“Open on other days”** (or dated subheaders).
- **Completion %**: show as **badge** or trailing text (e.g. `72%`).

## 7. Technical considerations

- **Data model:** `PlannedTask` already has `routineId`, `blockId`, `status`, `category`, reminder fields. **Plan day** is implied by parent **Routine**’s `dateKey` (current architecture). Changing plan day may require **moving** a task document (delete + recreate under another routine/block) or a **document field** `planDateKey` on the task for queries — **prefer** aligning with existing Routine `dateKey` unless a cheaper query pattern is needed.
- **Queries:** “Today only” = existing `getRoutinesForDate(todayKey)` + tasks. “Open across days” may require **multiple** `getRoutinesForDate` calls for known keys, a **collection group** query (if indexed), or a **denormalized** `users/{uid}/taskIndex` — document chosen approach in implementation tasks.
- **Edit mode:** `AddTaskScreen` **must** accept optional **`taskId`** + **`routineId`** + **`blockId`** + **`dateKey`** (or fetch task by id) to load and call **`upsertTask`** without generating a new id.
- **Quick complete from Home:** update **`PlannedTask.status`** to `completed` (and/or write **score 100%** per existing scoring rules — align with timer/scoring flows to avoid inconsistent state).
- **Riverpod:** extend or add providers for hub lists; reuse **`scoredTaskStatusesProvider`** or **scoring repository** for % display.

## 8. Success metrics

- Users can add a task and see it on **Home** and **hub** same day without manual refresh bugs.
- **Reminder on future day** does **not** show that task on today’s Home list until that calendar day.
- **Hub** shows **today + cross-day open** lists without duplicate rows for the same `taskId`.
- **Edit** from hub updates Firestore and reflects on Home within one navigation cycle.

## 9. Open questions

1. **Home row tap:** Should tapping the **main row** (not checkbox) open **hub**, **task detail**, or **only** the checkbox completes? (PRD assumes **dedicated control** completes; title/chevron opens hub — confirm.)
2. **Completed tasks on Home:** Hide completed, show struck through, or move to “Done today” sublist?
3. **Reorder scope:** Reorder **only today’s** tasks in v1, or also cross-day open section?
4. **Moving tasks between days:** If user edits reminder to another day in Add Task, **must** the implementation **move** the task to that day’s routine/block?
5. **Query strategy** for “open across days”: acceptable to load **last N days + next M days** with bounded reads, or require a new index/collection?

---

**Document status:** Ready for task breakdown (`generate-tasks.md`) after open questions are resolved or defaults are chosen by the team.
