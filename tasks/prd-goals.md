# PRD — Goals (Habits & Outcomes)

## 1. Introduction / Overview

**Goals** is a dedicated area of the app (reachable from the Home footer **Goals** tab) for **outcome-oriented commitments** that are **not** the same as day-planned **tasks**. A goal answers questions like *“What am I trying to achieve over time?”* and *“How do I stay consistent?”*

**Example:** *Learn Chinese in 30 days* is a **goal**. Under it, the user defines supporting **actions** (e.g. *Practice Chinese for 30 minutes every day*) and optional **sub-tasks / milestones** (e.g. *Learn the first 10 words*, *Complete lesson 1*). The app helps the user see **intensity**, **target** (time, sessions, or other units they define), **horizon** (daily / weekly / monthly framing), and **completion / consistency** so dedication to the habit is visible and measurable.

**Problem it solves:** Today, **Goal Selection** is a static placeholder. Users who think in **goals and habits** (multi-day, layered work) have no structured place to define them, break them into actionable pieces, or see progress separate from the single-day **Plan Tomorrow** / **Today’s tasks** flows. This feature gives goals a first-class home aligned with the app’s coaching tone (Quittr-style dark UI, neon accents).

**Relationship to existing features:**

| Area | Role |
|------|------|
| **Goals** | Longer-horizon outcomes, habit framing, milestones, intensity, aggregate progress. |
| **Today / Plan Tomorrow tasks** | Concrete items on a calendar day; may *inspire* or *duplicate* goal actions in future versions, but v1 treats goals as their own data unless specified otherwise in Open Questions. |

---

## 2. Goals (Product Objectives)

1. A user can **create** a goal with a clear **title**, **type/category**, **time horizon**, and **target end** (or equivalent duration).
2. A user can attach **required actions** and set **targets** using the **measurement they choose** (minutes, sessions, counts, etc.), appropriate to the goal’s horizon.
3. A user can add **sub-tasks / milestones** under a goal to break work into smaller steps.
4. A user can set **intensity** (relative importance vs other goals) so the UI surfaces what matters most.
5. The user sees **completion / consistency signals** using **both** habit check-ins and milestone progress (see §4.4 and §9).
6. A user can **view a list** of active (and optionally completed) goals and **open** a goal for detail and editing.
7. The experience feels **cohesive** with Home / Plan Tomorrow (same visual language, readable on mobile).

---

## 3. User Stories

- **As a user**, I want to create a goal like “Learn Chinese in one month” so I have a north star beyond today’s task list.
- **As a user**, I want to set that goal to a **monthly** horizon (a **calendar month**) and define **30 minutes of practice per day** so the app reflects how much time I’m committing.
- **As a user**, I want to add sub-items such as “Learn first 10 words” and “Finish lesson 1” so big goals feel achievable.
- **As a user**, I want to mark some goals **higher intensity** than others so I know what to protect when I’m busy.
- **As a user**, I want to see **how consistent** I am (e.g. completion rate or days hit) so I stay motivated.
- **As a user**, I want to **edit, pause, complete, or reopen** a goal when life changes, with **completed / paused** goals kept in an archive I can browse.
- **As a user**, I want goals to be separate from **random daily chores** so “learn a language” doesn’t feel like the same thing as “buy milk.”

---

## 4. Functional Requirements

### 4.1 Navigation & Shell

1. Tapping **Goals** on the Home **bottom navigation** must open the **Goals** experience (replace or evolve the current `GoalSelectionScreen`), route remains **`/goals`** unless the team standardises a new path.
2. The screen must include a clear **title** (e.g. “Goals”) and a path to **create a new goal** (primary CTA).

### 4.2 Goal — Create & Edit

3. The user must be able to **create** a goal with at minimum:
   - **Title** (required, free text).
   - **Category / type** — e.g. chips aligned with (**Study**, **Fitness**, **Productivity**, **Focus**, **Habits**, **Mental Clarity**); see requirements **17–18** for filter + tag behaviour.
   - **Horizon** — **Daily**, **Weekly**, or **Monthly**.
   - **Monthly** must use a **calendar month**: the goal period runs from the **start of the chosen calendar month** through the **end of that month** (not an arbitrary 30-day sprint unless we add that as a separate option later).
   - **Duration / end** for **Daily** / **Weekly** — defined per UX (e.g. end date or rolling window); **Monthly** bound to calendar month as above.
4. The user must define a **measurement** for the goal that fits what they are tracking (not only time). Examples: **minutes**, **sessions**, **reps**, **distance**, **count**, etc. The **target** (e.g. “90 minutes per week”, “5 sessions”, “20 pages”) must follow the **unit the user chose**. For **weekly** goals specifically, targets and copy follow that measurement (weekly minutes, weekly sessions, etc.) rather than forcing “minutes per day” when the user picked a different unit.
5. The user must be able to set **intensity** on an ordinal scale (e.g. **1–5** or **Low / Medium / High**) and have it persist; UI should make “more important” goals visually distinct in lists (badge, order, or accent).
6. The user must be able to **save** the goal and **see it** in a **goal list**; **edit** and **delete** (with confirmation) must be supported for goals they own.

### 4.3 Actions & Sub-tasks Under a Goal

7. Each goal must support **one or more action lines** (working name: **goal actions**): short descriptions of what the user does repeatedly (e.g. “Practice Chinese 30 minutes”).
8. Each goal must support **optional sub-tasks / milestones** (working name: **milestones**): ordered or unordered checklist items (e.g. “First word list”, “Lesson 1 complete”); user can **add**, **rename**, **reorder** (if feasible), **mark complete**, and **delete** milestones.
9. **Milestone completion** must contribute to the user-visible **progress** for that goal alongside check-ins (see **10**).

### 4.4 Progress & Completion Rate

10. The goal **detail** view must surface **both**:
    - **Habit / check-in consistency** — e.g. user marks whether they met their commitment for a day (or period); show streaks or “**X of Y days**” style copy where it fits the horizon.
    - **Milestone progress** — e.g. percentage or fraction of milestones completed.
    Both must be visible (e.g. two lines, two rings, or a simple combined summary plus breakdown—implementation detail).
11. Copy must stay **conversational**, not technical (aligned with the rest of the app).

### 4.5 List & Empty States

12. **Active goal list** shows goals sorted by **intensity** (higher first) then **recently updated**, respecting the **category filter** when active.
13. **Empty state**: if no goals (or none match the filter), show copy that invites creation and explains the difference between **goals** and **today’s tasks** in one short sentence.

### 4.6 Goal lifecycle (pause, complete, archive, reopen)

14. The user must be able to set a goal to **paused** or **completed** (or equivalent statuses).
15. **Paused** and **completed** goals must appear in an **archive** (or separate section / filter), not deleted by default.
16. The user must be able to **reopen** or **reactivate** a completed or paused goal (restore to active list), preserving history where reasonable.

### 4.7 Category tiles — filter and tag

17. Category chips/tiles must **filter** the goal list when one is selected (show only goals with that category).
18. Creating or editing a goal must **assign** the selected category as that goal’s **tag** (stored on the goal). Filter and tag behaviours work **together**: same categories for picking when creating and for narrowing the list.

### 4.8 Data & Account

19. Goals, actions, milestones, check-ins, and progress events must be **scoped to the signed-in user** (same pattern as `users/{uid}/...` elsewhere).
20. Changes must **persist** across app restarts (local + remote sync acceptable if aligned with existing **Firestore + offline queue** architecture).

---

## 5. Non-Goals (Out of Scope — Initial Release)

1. **Full automatic sync** of goal actions into **PlannedTask** / **Plan Tomorrow** without explicit user action (may be a later story).
2. **Social / community** features on goals (sharing, leaderboards).
3. **AI-generated** goal plans or task breakdowns (user mentioned AI suggestions elsewhere; not required for v1 of this PRD).
4. **Notifications** specific to goals (e.g. “time to practice Chinese”) unless trivial reuse of existing reminder infrastructure is chosen later.
5. **Multi-user / coach** assignment of goals.

---

## 6. Design Considerations

1. Reuse **Quittr-style** dark scaffold, **neon lime** (`#B7FF00`) accents, cards, and typography consistent with `GoalSelectionScreen` and Home.
2. **Create / edit** may be a **full screen** or **modal sheet**; goal **detail** should show hierarchy: title → meta (horizon, dates, **measurement + target**, intensity) → actions → milestones → **check-in + milestone progress**.
3. **Intensity** should be glanceable on list rows (icon, pill, or subtle border).
4. Avoid clutter: progressive disclosure (e.g. milestones in an expandable section) is acceptable.

---

## 7. Technical Considerations

1. **New feature module** suggested: `lib/features/goals/` with `domain` (models), `data` (repository), `application` (providers), `presentation` (screens), matching existing **planning** / **plan_tomorrow** layout.
2. **Firestore** collections under `users/{uid}/` e.g. `goals/{goalId}`, with subcollections or embedded maps for `actions` and `milestones`—exact schema to be defined during implementation (balance query needs vs document size).
3. Align **offline behaviour** with `SyncService` / existing patterns so creates/updates queue when offline.
4. **Riverpod** `FutureProvider` / `StreamProvider` for goal list and `FutureProvider.family` for goal detail, analogous to planning providers.
5. **Migration**: current static `GoalSelectionScreen` widgets become wired to real state; route name preserved for minimal navigation churn.

---

## 8. Success Metrics

1. Users can **create** a goal with horizon, time commitment, and intensity without leaving the app.
2. Users **return** to the Goals tab to view progress at least as often as other secondary tabs (qualitative / analytics if instrumented later).
3. **Support / confusion** (“Is this a task or a goal?”) reduced via copy and structure (measure via feedback if available).

---

## 9. Product decisions (locked)

| # | Topic | Decision |
|---|--------|----------|
| 1 | **Monthly horizon** | Use a **calendar month** (start → end of the chosen month), not a generic 30-day sprint for the “monthly” option. |
| 2 | **Weekly / measurement** | Progress targets follow the **measurement the user sets** (minutes, sessions, counts, etc.). Weekly goals use **weekly-appropriate** targets for that unit—not a single fixed “minutes per day” rule for every goal. |
| 3 | **Completion / progress** | Show **both**: **check-in (habit) consistency** and **milestone completion** on the goal detail experience. |
| 4 | **Paused / completed** | Keep **archive** (or equivalent); user can **reopen / reactivate** goals. |
| 5 | **Categories** | **Both**: tiles/chips **filter** the list **and** **tag** the goal on create/edit. |

---

## 10. Open questions (remaining)

1. **Soft limits:** Reasonable **maximum** count of actions or milestones per goal for UI performance (e.g. cap at 20 milestones)?
2. **Daily / weekly date rules:** Exact definition of “day” for check-ins (local midnight) and **weekly** period boundaries (calendar week vs rolling 7 days)—implementation detail.
3. **Optional later:** **Custom end date** or **N-day sprint** as an extra horizon type if users ask for it alongside calendar month.

---

## Document control

| Item | Value |
|------|--------|
| **Authoring** | Derived from product discussion + `PRD/create-prd.md` structure |
| **Location** | `tasks/prd-goals.md` |
| **Task list** | [`tasks-prd-goals.md`](tasks-prd-goals.md) |
| **Implementation** | Follow the task list; adjust order if pairing/mobbing |
