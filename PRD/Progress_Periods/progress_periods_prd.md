# Progress Periods — Day · Week · Month · Quarter · Year

**Status:** P1–P4 built 2026-09-12/13 (Q1–Q4 answered yes). Uncommitted on `feat/progress-periods`; awaiting a device walkthrough before merge.
**Owner decisions already settled (Miko, 2026-09-12):**

| Decision | Value |
|---|---|
| Day metric | one blended ring: `0.6 × goals/habits rate + 0.4 × tasks rate` |
| Week | Monday → Sunday (ISO week) |
| Pro gate | Day is free; Week, Month, Quarter, Year are Pro |
| Per-goal filter | not in V1; no per-entity snapshot schema |
| Time tracker | shown in Day detail as a supporting fact ("Time logged 2h 15m"), never part of the score |

---

## 1. Overview

The Progress screen (`lib/features/analytics/presentation/analytics_progress_screen.dart`)
is static today: a weekly hero, an insights row, and two cards with fixed
Today / Week / Month percentages. It cannot answer "how did Tuesday go?",
"how was last month?", or "how is the year going?".

This feature turns Progress into a period browser. One segmented control
(Day · Week · Month · Quarter · Year) selects a horizon, arrows move
between periods, and every day is drawn as the same **day ring** whose fill
is the day's blended discipline rate. Tapping a day in Week or Month view
opens that day's detail inline: goals %, tasks %, the task list, goal
check-ins, and time logged.

The aggregate daily snapshot (`IsarAnalyticsStats`, scopes `goal_habit_daily`
and `task_daily`) is the sole data foundation. No new synced entity is
introduced.

## 2. Goals

1. Any past day, week, month, quarter, or year can be opened and read
   offline, instantly, from the local snapshot cache.
2. One number per day everywhere on the page, computed one way (the blend).
3. The page remains "mathematically about completion": time-tracker data is
   context, never an input to any percentage or streak.
4. Free users keep the Day view; Week and beyond are the first visible Pro
   surface in the app.

## 3. User stories

- As a user I open Progress and see today's ring with the blended % and,
  underneath, what today asked of me and what I did.
- As a user I switch to Week and see seven rings (Mon → Sun); I tap Tuesday
  and see Tuesday's detail without leaving the page.
- As a user I switch to Month and see a calendar of rings; I page back to
  August and tap a day.
- As a user I switch to Quarter and see a 13-week heatmap headed by my Q3
  direction text, with three month bars.
- As a user I switch to Year and see a 53-week heatmap headed by my year
  direction text, with twelve month bars.
- As a free user I can switch to Week; the content renders blurred with an
  "Unlock Progress" pill that opens the Pro sheet.

## 4. Metric definitions

### 4.1 Blended day rate

For a day with goal/habit snapshot `g` and task snapshot `t`
(`weightedCompletionRate`, `weightedCreated` from `DailyAnalyticsSnapshot`):

```
if g.weightedCreated > 0 and t.weightedCreated > 0 → 0.6·g.rate + 0.4·t.rate
if only g planned                                  → g.rate
if only t planned                                  → t.rate
if neither planned                                 → null   ("quiet day")
```

Renormalising when one scope is empty stops a user who planned only tasks
from being capped at 40 %. A quiet day draws a hollow ring and shows an em
dash, never "0 %" (2026-08-23 precedent: a quiet day is not a failure).

### 4.2 Period rate

Weighted, not a mean of day rates:

```
periodRate = 0.6 · Σg.weightedCompleted / Σg.weightedCreated
           + 0.4 · Σt.weightedCompleted / Σt.weightedCreated
```
with the same renormalisation when one scope's Σcreated is 0 across the
period. This keeps a heavy day heavier than a light one, matching
`rollupDailyAnalytics`.

### 4.3 Ring states

| State | Rule | Drawing |
|---|---|---|
| qualified | blended ≥ `EnforcementModePolicy.streakDayThreshold(mode)` | full accent ring, filled centre |
| partial | 0 < blended < threshold | ring arc = blended, muted track |
| missed | blended == 0 and something was planned | empty track only |
| quiet | blended == null | thin dashed hollow circle |
| protected | dateKey ∈ `buildStreakProtectedDateKeys` (vacation) | muted full ring with a small shield glyph |
| today | any of the above + accent outline halo | |
| future | nothing planned yet | plain number, no ring |

Threshold uses the user's current enforcement mode
(`defaultEnforcementModeProvider`), the same as streaks today.

### 4.4 Streaks

Period cards show **current streak** (only when the period contains today)
and **best streak in period**, computed by `rollupDailyAnalytics` over the
blended series (a synthetic `DailyAnalyticsSnapshot` per day whose weighted
fields are the 60/40-scaled sums, so the existing engine and vacation
protection apply unchanged).

**Open question Q1 (recommend yes):** make this blended streak the app's
single "day streak", replacing `homeDisplayStreakDays` (goal/habit-only) on
Home and Profile. Otherwise the app shows two different streak numbers.

### 4.5 Quiet days and streaks

Existing engine behaviour: a day with nothing planned has rate 0 and breaks
the streak unless protected. V1 keeps that rule (streak semantics are out
of scope) but draws the day as *quiet*, not *missed*.
**Open question Q2:** should a quiet day be streak-neutral instead? If yes,
it is a one-line change in `qualifies()` and applies app-wide.

## 5. Period model

New file `lib/features/analytics/domain/progress_period.dart`:

```dart
enum ProgressHorizon { day, week, month, quarter, year }

class ProgressPeriod {
  final ProgressHorizon horizon;
  final String key;          // 2026-09-12 | 2026-W37 | 2026-09 | 2026-Q3 | 2026
  final String startDateKey; // inclusive
  final String endDateKey;   // inclusive
  final String label;        // "Sat, 12 Sep" | "8 – 14 Sep" | "September 2026" | "Q3 2026" | "2026"
  ProgressPeriod previous(); ProgressPeriod next();
  bool contains(String dateKey); bool get isCurrent; bool get startsAfterToday;
  static ProgressPeriod current(ProgressHorizon h, [DateTime? now]);
}
```

Built on existing helpers only: `DateKeys.isoWeekKey`, `WeekPeriods`
(Monday ISO weeks), `WeekPeriods.monthOf`, `DirectionPeriods` (quarter and
year bounds and key regexes). ISO week 1 crossing a year boundary follows
`DateKeys.isoWeekKey` exactly, with a unit test for 2026-12-28 → 2027-01-03.

**Next** is disabled when `startsAfterToday`. **Previous** is unbounded;
periods before the user's first plan day render as all-quiet.

## 6. Data layer

### 6.1 Range read on the stats cache (new)

`AnalyticsRepository.listStatsCacheRange({required scopeType, required fromDateKey, required toDateKey})`.

- Isar: `filter().scopeTypeEqualTo(...).dateKeyBetween(from, to)`. The
  `dateKey` index is a hash index (Isar's String default), which serves
  equality only, so this is a filter scan over the stats collection (two
  rows per day of use) rather than an index range — still one query per
  scope per period, and no schema change or regeneration.
- Firestore implementation: fetch the scope's docs and filter in Dart. No
  new `orderBy`/range query, so nothing in `documentation/errors.md`
  applies. Reads are Isar-only in the UI path regardless.
- The existing `listStatsCache` (loads all rows, filters in Dart) is left as
  is; the loader's `_readCachedDailyRange` is switched to the new call.

### 6.2 Series provider (new)

`progressPeriodSeriesProvider = AsyncNotifierProvider.family<…, ProgressPeriodSeries, ProgressPeriod>`

```dart
class ProgressDayPoint { dateKey, goal (Daily?), task (Daily?), blended (double?), state (RingState) }
class ProgressPeriodSeries {
  ProgressPeriod period; List<ProgressDayPoint> days;   // one per calendar day, start → end
  double? periodRate; double? goalRate; double? taskRate;
  int daysMet; int daysPlanned; int currentStreak; int bestStreak;
  double? previousPeriodRate;                              // for the delta chip
  List<double?> monthRates;                                // quarter: 3, year: 12, else empty
}
```

Build order (same shape as `AnalyticsPeriodBundleNotifier`):

1. Read both scopes for the range via 6.1 → publish immediately.
2. If the period contains today, recompute today live (existing
   `_computeGoalHabitDailyForDate` / `_computeTaskDailyForDate`) and
   re-publish.
3. **Backfill**: for days in the period that are ≥ the user's earliest
   routine `dateKey` and < today and have no cached row, compute and persist
   through the existing upsert path, in the background, yielding every 10
   days, then re-publish once. Bounded by the period, so a year view at
   worst computes the uncached days of that year once; subsequent opens are
   cache hits. Backfill is skipped when the tier gate hides the view.
4. Watches `goalsStreamProvider`, `todayAllTasksRowsProvider`,
   `defaultEnforcementModeProvider`, `attentionStateProvider` exactly like
   the bundle notifier, so the local write is the update (no
   invalidate-and-refetch).

Previous-period rate is read with one extra pair of range reads (cache only,
no backfill).

### 6.3 Week convention fix (existing bundle)

`loadCachedAnalyticsPeriodBundle` and `computeAnalyticsPeriodBundle` change
the week window from "trailing 7 days" to "Monday of this ISO week → today".
Consequences, all intended: Home's WEEKLY DISCIPLINE bar, Home's sparkline
(`_MiniSparkline` already pads to 7, so Mon → today renders as a partial
week), and the hero label (`progressWeekDateRangeLabel`, already Monday)
finally agree with Profile's THIS WEEK and the Time tracker.

### 6.4 Day detail provider (new)

`progressDayDetailProvider(dateKey)` → `ProgressDayDetail`:

- `tasks`: `collectTasksForDateKey(planningRepo, dateKey, enforceTaskPlanDate: true)`
  → title, status, priority, `isHabitAnchor`.
- `checkIns`: new `GoalsRepository.getCheckInsForDate(dateKey)` (Isar query
  on the existing `IsarGoalCheckIn.dateKey` index; Firestore impl filters
  per goal) joined to goal titles.
- `timeLogged`: `activityEventRepository.fetchDayOnce(dateKey)` →
  `buildTimeline` → `DaySummary.logged` (`Duration`). Displayed as
  `2h 15m`; `—` when zero. Never read by any percentage.
- `goalRate`, `taskRate`, `blended`, `state` from the series point.

All reads are Isar; the provider is a plain `FutureProvider.family` because
the day's rows only change through today's live path, which already
re-emits via the series provider's watches.

## 7. Screen design

Chrome stays as is: `PageTitle('Progress')`, help button, tester-only AI
button, recompute button. Body top → bottom:

1. **`PeriodSwitcher`** — five-segment control, `AnimatedSwitcher` (260 ms)
   on the content below. Selected horizon persists for the session
   (`progressSelectionProvider`: horizon, period key, selected dateKey).
2. **`PeriodNav`** — `SectionHeader`-weight label ("September 2026") with
   ‹ › arrows; › disabled when `startsAfterToday`. Swiping the hero left or
   right also pages.
3. **Hero (per horizon)**
   - Day: one large `DayRing` (gradient, `_GradientRingPainter` lineage)
     with the blended % as the big number and "goals g% · tasks t%" as the
     micro line.
   - Week: `WeekRingStrip` — seven `DayRing`s Mon → Sun with day labels,
     the existing 7-point sparkline beneath (blended series).
   - Month: `MonthCalendarGrid` — weekday header (Mon first), six rows,
     leading/trailing days muted, each cell a `DayRing`.
   - Quarter: `PeriodHeatmap` with 13 columns (weeks) × 7 rows (Mon → Sun),
     month labels above, plus `MonthBars` (3). Header line above the hero:
     the quarter's Direction text, if any (`IsarDirectionEntry`, key
     `2026-Q3`), as a quiet italic line, otherwise nothing.
   - Year: `PeriodHeatmap` with up to 53 columns, month labels, plus
     `MonthBars` (12). Header: the year's Direction text.
   Heatmap cell colour is the ring gradient sampled at the blended rate;
   quiet = surface-container-high; protected = muted with the shield tint.
   At 53 columns a cell is ~5 px on a 375 pt screen, which is legible as
   density, not as individual days; tapping a heatmap cell is **not** a
   feature in V1 (tap targets are too small), so Quarter and Year carry no
   day detail.
4. **`PeriodRollupCard`** — big blended % · "N of M planned days met" ·
   best streak · current streak (only when the period contains today) ·
   delta vs previous period as a chip ("+6 pts vs last month").
5. **`ScopeSplitCard`** — replaces `GoalsHabitsSection` and
   `TaskIntegritySection`: two `ProgressThinBar`s, "Goals & Habits · 60 %
   weight · g%" and "Tasks · 40 % weight · t%", with the existing HelpDots.
6. **`DayDetailCard`** — shown in Day always, and in Week/Month when a ring
   is tapped (default selection: today if inside the period, else none).
   Sections with 11 px micro-labels: TASKS (rows with status glyph,
   priority dot, habit-anchor tag), GOAL CHECK-INS (goal title, met/not,
   value), TIME LOGGED (single row "2h 15m", tap opens the Time screen on
   that day via `timelineDayKeyProvider`). Appears with the same 260 ms
   switcher; tapping the selected ring again collapses it.
7. **`ProgressInsightsRow`** — unchanged, period-agnostic, keeps the
   coaching focus and AI summary where the `layer4:` notification taps land.

Colours only through `ProgressDesignTokens` / `AppColors`; new widgets live
in `lib/features/analytics/presentation/progress/`. Skeleton: extend
`ProgressBundleSkeleton` with a per-horizon placeholder. Back gesture: the
page is single-step, so no `PopScope`; a selected day is a selection, not a
step.

### 7.1 Pro gate

- `TierGate.canViewProgressHorizon(ProgressHorizon h) => isBypassed || h == ProgressHorizon.day`.
  Pure rule, no new `tier_limits_v1` value; unit-tested.
- When blocked, sections 2–6 render with real data under an `ImageFiltered`
  Gaussian blur (σ ≈ 6) inside an `AbsorbPointer`, with a centred pill
  "Unlock Progress" (lock glyph, primary-container fill, radius full) that
  calls `showTierLimitSheet(title: 'Progress history is Pro', message: …)`.
  Backfill and the day-detail provider are not started for blocked views.
- Home's weekly bar and Profile's THIS WEEK stay free: they are already
  computed and are single numbers, not history. This narrows the
  2026-07-20 tier-matrix line "basic analytics (streaks, weekly %,
  calendar…)" and is recorded in the decision log.
- `tier_limits_v1` enforcement is currently off, so the gate is dormant in
  production until the paywall ships — same status as every other tier gate.

## 8. Functional requirements

1. The Progress body must offer horizons Day, Week, Month, Quarter, Year.
2. Every horizon must support previous/next paging with next disabled for
   future periods.
3. Every calendar day in a period must render as a `DayRing` in the state
   table of §4.3, using the blended rate of §4.1.
4. Period rate, days met, best streak, current streak, and previous-period
   delta must be computed as in §4.2 and §4.4.
5. Tapping a ring in Week or Month must show that day's `DayDetailCard`
   inline; tapping it again must collapse it.
6. Day detail must list tasks, goal check-ins, and time logged for that day.
7. Time logged must never contribute to any rate, ring, or streak.
8. Week windows everywhere in analytics must be Monday → Sunday.
9. Week, Month, Quarter, Year must be blurred with an unlock pill for free
   users when tier enforcement is on.
10. All reads must come from Isar; cache misses for past days are
    backfilled in the background and persisted through the existing upsert
    path, never awaited on a gesture.
11. Quarter and Year must show the matching Direction text when one exists.
12. Everything must work identically in airplane mode.

## 9. Non-goals

- Per-goal or per-habit filtering and per-entity daily snapshots.
- Tap-to-detail on heatmap cells (Quarter, Year).
- Task integrity scores (Firestore-only, dateless) on the calendar.
- Changing streak semantics (beyond Q1/Q2 if approved).
- A completion timestamp on tasks (backfilled past days keep today's
  approximation: current task rows for that `planDateKey`).
- Export, sharing, or widgets.

## 10. Tests

- `progress_period_test.dart`: week keys across the year boundary, quarter
  and year bounds, previous/next round-trips, `startsAfterToday`.
- `blended_rate_test.dart`: all four branches of §4.1, weighted period
  rate of §4.2, ring-state table of §4.3 for each enforcement mode.
- `isar_analytics_repository_range_test.dart`: range read honours bounds
  and scope.
- `progress_period_series_test.dart`: cache-first publish, today live
  recompute, backfill persists and re-publishes, previous-period delta.
- `tier_gate_test.dart`: `canViewProgressHorizon`.
- Widget: month grid tap selects and collapses; blocked horizon shows the
  pill and absorbs taps; week strip renders seven rings Mon → Sun.
- `test/architecture/local_first_guard_test.dart` must stay green.
- `flutter analyze` clean, full suite green.

## 11. Phases

| Phase | Scope | Done when |
|---|---|---|
| P1 Foundation | period model, blend, range read, series + day-detail providers, Monday week fix, tests | providers unit-tested, Home numbers verified after the week change |
| P2 Day · Week · Month | switcher, nav, `DayRing`, week strip, month grid, rollup card, split card, day detail | tap a day in month view, see its detail, offline |
| P3 Quarter · Year | heatmap, month bars, Direction header lines | year view opens instantly from cache on a device with data |
| P4 Gate + polish | tier gate + blur pill, skeletons, help-guide text, decision-log entry, `CODEBASE_GUIDE.md` note | full suite green, airplane-mode walkthrough of all five horizons |

## 12. Open questions (answer before P1)

- **Q1** Unify the app-wide day streak (Home, Profile) on the blended
  series? *Recommend yes.*
- **Q2** Quiet days: keep "breaks the streak" (current) or make them
  streak-neutral? *Recommend keep for V1.*
- **Q3** Confirm the narrowing of the 2026-07-20 free tier line ("weekly %,
  calendar" free) to: Home/Profile weekly numbers free, Progress history Pro.
- **Q4** Day-detail task rows: show every planned task, or cap at 8 with
  "show all"? *Recommend show all; a day rarely exceeds ten.*
