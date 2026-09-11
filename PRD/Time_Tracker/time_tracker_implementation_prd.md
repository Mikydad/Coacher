# Time Tracker — Implementation PRD (v1.0)

> Status: **IMPLEMENTED on `feat/time-tracker`, 2026-09-12 — phases T1–T6
> done, `flutter analyze` clean for touched files, full Dart suite green.
> Awaiting Miko's device run and commit. No Cloud Functions change.**
> Decisions settled by Miko's answers 1–17 + follow-ups F1–F4 (2026-09-12).
> Sources: `time_tracker_prd.md` (the product idea), the Direction build
> (same local-first entity pattern, same AI seams), and a code read of the
> execution controller, the attention orchestrator, the notification tap
> router, and the bottom-sheet helpers.
>
> One-line spec, repeated in every file header of this feature:
> **SidePal doesn't track your time for you. It makes it effortless for you
> to record your time, then helps you see what you actually did with it.**

---

## 0. Decisions as settled (do not relitigate)

| # | Topic | Decision |
|---|---|---|
| 1 | Day boundary | **Calendar day**, local. Same `dateKey` convention as everything else; a 2 AM entry belongs to the next day's timeline. |
| 2 | Gap threshold | **2 hours.** If the next event is more than 2 h away, the activity is not credited the whole gap: `10:09 Planning` / `? · 3h 51m untracked` / `2:00 Sleep`. |
| 3 | Latest entry | Shown as **Ongoing** — no live ticking counter in V1 (a ticking number makes it feel like a timer). Duration appears once the next log lands. |
| 4 | Intended duration | The optional duration is **intent, not a stop time**. Actual is still derived (§2 priority). Shown as `Planned 30m · Actual 45m` when both exist. |
| 5 | Sleep | A plain activity. No special sleep logic in V1. |
| 6 | Backdating | Timestamp editable **within today only**. No date picker. |
| 7 | Recent chips | **V1.** The user's own recent distinct activities as tap chips above the field. Never global suggestions. |
| 8 | Text | 80 chars, visually encouraged short rather than explained. |
| 9 | Home placement | A **thin pill row** directly under the four action circles, before Promises: `◷ Track what you're doing +`. Not a card, not a tab. |
| 10 | Capture shape | **Bottom sheet for capture** (from the pill) + a **full Time page** for the timeline. Capture is the common path; the timeline is history. |
| 11 | Deep link | `sidepal://track` — **V1.1.** |
| 12 | Coach logging | **V1.1**, conservative: a one-tap confirm ("Log 'Gym' at 7:42 PM? [Track]"), never a silent write. |
| 13 | Duration reminder | Goes through the **attention orchestrator** and **respects** focus/sleep suppression. The event is still recorded; only the reminder is suppressed. |
| 14 | Focus timer | Starting a focus session **auto-logs** an event with the task title, `source: timer`, editable. Stopping writes the explicit end. |
| 15 | Categories | Optional `category` field from day one, **empty in V1**, never exposed in capture. |
| 16 | Daily summary | At the **bottom of the Time page**, not a new destination. V1 groups by activity text (categories are empty). |
| 17 | Scope | Build everything that makes it useful now (§10), except items marked V1.1. |
| F1 | Explicit end | `endedAtMs` on the event. Priority: **explicit end → next event → 2-hour cap → untracked gap.** Timer stop writes it; the edit sheet exposes it. |
| F2 | Plan suggestions | **Dropped for now.** |
| F3 | Entry points | Pill → capture sheet. Sheet footer: `Today's timeline →`. Profile hub row `Time`. The pill never opens the full page. |
| F4 | Previous days | **View-only** paging back on the Time page. Today: view + create + edit + delete. Previous days: view only. |

**Conceptual architecture (from the Direction PRD):**
`Direction → Plan → Actual Time → Insights`. This feature is the third box.
Direction = where I'm going, Plan = what I intend, **Time = what I actually
did**, Reflection = what SidePal notices about the difference.

**Larger philosophy:** *Don't tell people how to live. Help them see how
they're living.*

---

## 1. Feature review checklist (GUIDELINES.md)

1. **Problem** — "Where did my day actually go?" has no answer in SidePal:
   the app knows intentions (tasks, goals, direction) but nothing about
   actual time except task-bound timer sessions.
2. **Principle fit** — P1/P2 offline-first (user's own data), P4 silent
   sync, P6 chrome recedes (a pill, a sheet, one page).
3. **Duplication** — `TimerSession` is the closest thing: Firestore-only,
   task-bound, no free text, no date-range query. It stays as-is; the timer
   now *also* logs an activity event (decision 14). Nothing else overlaps.
4. **Offline class** — user-own data → full local-first set, airplane-mode
   indistinguishable from online.
5. **Consistency** — `AppColors`, `PageTitle`/`SectionHeader`, micro-labels,
   `SwipeActionsRow` for edit/delete, the Add-Task / intention sheet chrome
   (`showModalBottomSheet`, drag handle, 28 px top radius), `AddTaskField`
   styling for the text field.
6. **Navigation** — sheet dismisses to wherever it was opened; the Time page
   is a single pushed route; day paging is in-page state (back pops the
   page). Notification tap opens the capture sheet on top of Home.
7. **Failure story** — none visible for writes (Isar, then outbox). Reminder
   scheduling failure is logged and silent (the event is still saved).
8. **Maintenance cost** — one new synced entity + one reminder entity kind
   + one tap prefix + one hook in the execution controller.
9. **Semantics confirmed** — §0.

---

## 2. Domain: the activity event and the derivation rules

### 2.1 Model — `lib/features/time_tracker/domain/models/activity_event.dart`

```dart
enum ActivitySource { manual, timer }

class ActivityEvent {
  final String id;               // StableId.generate('act') — NOT deterministic (many per day)
  final String text;             // 1..80 chars after trim, required
  final int startedAtMs;         // "the time the user says it started" — editable
  final int? endedAtMs;          // explicit end (timer stop, or user edit); must be > startedAtMs
  final int? intendedMinutes;    // optional intent, 1..720; never a stop time
  final String dateKey;          // local calendar day of startedAtMs ('2026-09-12') — index for day queries
  final ActivitySource source;
  final String? sourceEntityId;  // taskId / blockId when source == timer
  final String? category;        // nullable, unexposed in V1 (decision 15)
  final bool active;             // soft tombstone for LWW sync
  final int createdAtMs;
  final int updatedAtMs;         // LWW key — bump on every write
  void validate();               // text 1..80, ended > started, intended 1..720, dateKey == keyOf(startedAtMs)
}
```

`dateKey` is **derived at write** from `startedAtMs` (local) and re-derived
when the start is edited. It is stored (not computed on read) so the
timeline query is a single indexed equality.

### 2.2 Derivation — `lib/features/time_tracker/domain/timeline_builder.dart` (pure)

Input: the day's active events sorted by `startedAtMs`, `now`.
Output: `List<TimelineRow>` where a row is one of:

```dart
sealed class TimelineRow {}
class ActivityRow extends TimelineRow {
  final ActivityEvent event;
  final int? endMs;               // resolved end, null = ongoing
  final Duration? actual;         // endMs - startedAtMs, null = ongoing
  final DurationSource endSource; // explicit | nextEvent | capped | ongoing
}
class UntrackedRow extends TimelineRow {
  final int fromMs, toMs;         // the uncredited stretch
  Duration get length;
}
```

Rules, in priority order for each event `e` with successor `n` (or none):

1. **Explicit end**: `e.endedAtMs != null` → `endMs = e.endedAtMs`,
   source `explicit`. If `n.startedAtMs - endMs > 0` the space between is
   an `UntrackedRow` only when it exceeds **`kUntrackedMinGap` = 15 min**
   (tiny slivers between a timer stop and the next log are noise, not
   information).
2. **Next event within the cap**: `n != null && n.startedAtMs - e.startedAtMs <= 2h`
   → `endMs = n.startedAtMs`, source `nextEvent`.
3. **Next event beyond the cap**: `n != null && gap > 2h` → `endMs = null`
   is *wrong* (it would read as ongoing). Instead `endMs = null`,
   `actual = null`, source `capped`, rendered as `10:09 · Planning` with
   no duration, followed by `UntrackedRow(e.startedAtMs, n.startedAtMs)`
   rendered `? · 3h 51m untracked`. The activity is credited **nothing**
   — decision 2 says don't attribute the gap; crediting exactly 2 h would
   be its own false precision.
4. **No successor** → `endMs = null`, source `ongoing`, rendered
   `Ongoing`. No live counter (decision 3). This holds regardless of how
   old the entry is; the gap rule applies only once a successor exists.
5. **Intended duration** never changes any of the above. It renders as
   `Planned 30m` next to `Actual 45m` (or alone while ongoing).
6. **Cross-midnight**: the last event of a day has no successor *within the
   day* → ongoing on that day's timeline. V1 does not look into the next
   day. (Noted as a V1.1 refinement: use the next day's first event as the
   successor when it is within 2 h.)

### 2.3 Day summary — `lib/features/time_tracker/domain/day_summary.dart` (pure)

From the rows: `loggedTotal` = sum of `actual` over rows with a resolved end
(ongoing and capped rows contribute 0). Grouped by **normalised text**
(trim, lowercase, collapse whitespace; display the most recent casing),
descending by total, top 6 + "Other". Untracked total shown separately,
never inside "logged". Copy: `You logged 8h 42m` / `Untracked 3h 51m`.

### 2.4 Recent chips — `lib/features/time_tracker/domain/recent_activities.dart` (pure)

From the last **30 days** of active events, distinct by normalised text,
ordered by most recent use, **6** chips, excluding timer-sourced events'
task titles? — **No**: include them; a task the user focuses on is exactly
what they'll log by hand too. Exclude nothing.

### 2.5 Time formatting

Reuse the app's existing 12/24-hour handling if a helper exists
(`MaterialLocalizations.formatTimeOfDay` with the device setting); durations
as `6m`, `45m`, `1h 05m`, `3h 51m`.

---

## 3. Data + sync (the Direction pattern, verbatim)

- **Isar** `lib/core/local_db/isar_collections/isar_activity_event.dart`:
  auto-increment `Id`, `@Index(unique: true) eventId`, `@Index() updatedAtMs`,
  `@Index() dateKey`, `@Index() startedAtMs`, plus the fields. Register in
  `isar_schemas.dart`, run `build_runner`.
- **Firestore** `FirestorePaths.activityEvents = '$userRoot/activityEvents'`,
  `activityEventDocument(id)`. Blanket owner rule covers it — no rules
  change.
- **Repository** `lib/features/time_tracker/data/activity_event_repository.dart`:
  `watchDay(dateKey)`, `watchRecentSince(ms)`, `fetchDayOnce`, `getById`,
  `upsert(event)` (validate → stamp → Isar → `outboxUpsert(entityType:
  'activity_event')`), `softDelete(id)` (tombstone `active: false` +
  outbox upsert, **never** `outboxDelete` — deletes must win LWW across
  devices), `setEnd(id, endedAtMs)` for the timer stop. Never `await` a
  Firestore write (architecture guard).
- **LWW merge helper** `activity_event_lww_merge.dart` (unit-testable) +
  `_pullActivityEvents()` in `RemoteIsarMerge.run()` after
  `_pullDirections()`, cursor key `'activity_events'`.
- **Providers** `application/time_tracker_providers.dart`:
  `activityEventRepositoryProvider`; `timelineDayKeyProvider =
  StateProvider<String>` (the day shown on the Time page, defaults to
  today, reset when the page opens); `dayEventsProvider(dateKey)` — a
  `StreamProvider.family` over `watchDay`; `timelineRowsProvider(dateKey)`
  derived via `buildTimeline`; `daySummaryProvider(dateKey)`;
  `recentActivityChipsProvider` (30-day stream → chips);
  `ongoingEventProvider` (today's last active event, for the pill copy and
  the reminder cancel path).
- **Wipe paths**: the Isar collection is wiped automatically. Prefs keys
  introduced (§6, reminder bookkeeping) join `AuthSessionPolicy.clearLocalSession`;
  `timelineDayKeyProvider` joins `invalidateUserScopedProviders`.
- **No `ScheduleMutationCoordinator`** — activity events never touch the
  schedule.

---

## 4. Capture sheet — `presentation/track_activity_sheet.dart`

`Future<void> showTrackActivitySheet(BuildContext, {ActivityEvent? edit, int? presetStartMs})`
— `showModalBottomSheet` with the intention-sheet chrome (drag handle, 28 px
radius, `AppColors.surfacePanel`). Not full-height: content-sized so a
sliver of Home stays visible.

```
10:03 PM                                  ← tappable; opens showTimePicker (today only)
What are you doing?
[ Scrolling                         ]     ← AddTaskField styling, 80 chars, autofocus
RECENT                                    ← micro-label; hidden when no history
(Gym) (Scrolling) (Gaming) (Flutter) (SidePal)
DURATION · OPTIONAL                       ← micro-label
(15m) (30m) (45m) (1h) (custom…)          ← chips; selected = filled; tap again to clear
[            TRACK ▸            ]         ← primary; disabled while text empty
(Today's timeline → moved to the top row, right of the timestamp — device test 2026-09-12: at the foot it was easy to miss under the keyboard.)
```

Behaviour:
- **Timestamp** defaults to `now` when the sheet opens (captured once, at
  open — the user's "I'm doing this now" moment, not the save moment).
  Tapping opens a time picker; a picked time later than now is clamped to
  now with a one-line hint ("Can't log the future yet"). The resulting
  `startedAtMs` is on **today's** date always (decision 6).
- **Chip tap** fills the field (does not auto-submit — the user may want to
  add a duration or adjust time; Track is one more tap).
- **Track** → `repository.upsert(ActivityEvent(...source: manual))` →
  cancel any pending duration reminder for the previous ongoing event →
  if `intendedMinutes` set, schedule the reminder (§6) → pop. Nothing
  awaits the network.
- **Edit mode** (`edit != null`): same sheet, title `Edit`, prefilled,
  plus an **End** row (`Ended at · 8:27 PM · ✕`) exposing `endedAtMs`
  (decision F1), and a `Delete` text button at the foot (confirm dialog →
  `softDelete`). Editing the start time re-derives `dateKey`; edits are
  today-only, so it stays today.
- **Keyboard Done** = Track.

---

## 5. Home pill + Time page + Profile row

### 5.1 Home pill — `presentation/track_pill.dart`

Mounted in `home_screen.dart` **directly after the action-circle row's
`SizedBox(height: 20)` and before `SeizeTheMomentCard`**. One line, 40 px,
pill shape (`AppColors.fg.withAlpha(12)` fill, no shadow):

```
◷  Track what you're doing                                 +
```

When today has an ongoing event, the copy becomes
`◷  Scrolling · since 10:03 PM                              +`
so the pill doubles as the "what am I doing" reminder. Tap anywhere →
`showTrackActivitySheet`. Never opens the page (decision F3).

### 5.2 Time page — `presentation/time_screen.dart`, route `/time`

`SettingsPageScaffold`-style chrome, `PageTitle('Time')`, `HelpAppBarButton('time')`.

```
‹  Today · Fri 12 Sep  ›                 ← day pager; › disabled on today
TIMELINE                                 ← SectionHeader
10:03 PM  Scrolling                       6m        ← ActivityRow
10:09 PM  Planning                       17m
10:26 PM  Bathroom                       24m
10:50 PM  Cleaning house              Ongoing
   ?      3h 51m untracked                          ← UntrackedRow, muted
7:42 PM   Study Flutter    Planned 30m · Actual 45m
… 
SUMMARY                                  ← SectionHeader
You logged 8h 42m · Untracked 3h 51m
SidePal        3h 20m
Gym            1h 10m
Gaming         2h 30m
Other          1h 42m
```

- Rows are `SwipeActionsRow(onEdit, onDelete)` **on today only**; on
  previous days rows are plain (decision F4) and the FAB is absent.
- FAB on today: `+ Track` → the capture sheet.
- Empty today: `Nothing logged yet.` + the same `+ Track` FAB. Empty
  previous day: `Nothing logged.`
- Timer-sourced rows carry a small `⏱` glyph after the text (source
  honesty — the user did not type this).
- Paging is `timelineDayKeyProvider` ± 1 day; going back past 30 days is
  allowed (the data is there) but chips/summary logic is unchanged.

### 5.3 Profile hub row

`SettingRow(icon: Icons.schedule_outlined, title: 'Time', subtitle: 'Record
your day, see where your time went')` **after** Direction, before Smart
Timing. Pushes `/time`.

### 5.4 Feature guide

`FeatureGuides.time` (`id: 'time'`, emoji ⏱️, `tryItRoute: '/time'`) so
the Coach can explain it and the page has a help button.

---

## 6. Duration reminder ("30 minutes are up")

- On Track with `intendedMinutes`, build a
  `ReminderIntent(entityId: event.id, entityKind: ReminderEntityKinds.activity /* new: 'activity' */,
  entityTitle: event.text, proposedAt: startedAt + intended, importance: 45,
  interruptionLevel: InterruptionLevel.low, enforcementMode: 'flexible',
  sourceReason: 'activity_intended_duration',
  bodyOverride: '${intended}m are up. What are you doing now?')` and call
  `AttentionOrchestratorService.evaluate(intent)`. The orchestrator owns
  suppression (focus/sleep/DND), collisions and the ledger — decision 13.
  If `proposedAt` is already in the past (user backdated), skip.
- **Cancel** via `orchestrator.cancelForEntity(event.id)` when: a newer
  event is logged, the event is edited (re-schedule if still relevant),
  deleted, or given an explicit end.
- **Tap routing**: new prefix `activity:` in
  `notification_response_handler.dart` → open Home (root) and
  `showTrackActivitySheet` with `presetStartMs = now`. If the navigator
  isn't ready, persist via the existing pending-intent mechanism.
- Copy is the PRD's: *"30 minutes are up. What are you doing now?"* — never
  "you failed", never "time's up on your task".
- A reminder is never re-armed after firing; one per event.

---

## 7. Focus timer hook (decision 14 + F1)

In `ExecutionController` (`lib/features/execution/application/execution_controller.dart`):

- **Start**: when `start()` moves the engine from `notStarted` to
  `inProgress` (not on `resume()`), create
  `ActivityEvent(text: state.taskLabel /* or block label */, startedAtMs: now,
  source: timer, sourceEntityId: taskId|blockId, intendedMinutes:
  targetDurationMinutes when > 0)` and remember its id in the controller
  state (`activityEventId`), persisted in `TimerRuntimeCache` so a crash
  mid-session still ends the right event.
- **Stop** (`stopAndPersist`): `repository.setEnd(activityEventId, now)`.
  The existing `TimerSession` write is untouched.
- **No duration reminder** for timer-sourced events — the timer already
  owns that moment.
- The controller gets the repository injected (nullable, like the
  Direction seams) so tests and the no-op harness stay byte-identical.
- If a session is abandoned (app killed, never stopped) the event stays
  ongoing and the normal derivation applies; the user can set an end by
  editing. Honest, not invented.

---

## 8. AI seams (V1: data only; reflection is V1.2)

Nothing in V1 sends activity data to the Coach, the insight phrasing, or
the Thinking Loop. The PRD is explicit that reflection comes after the
timeline data is trustworthy. Two small, safe exceptions ship now:

- `FeatureGuides.time` so the Coach can *explain* the feature.
- The Coach payload gains **nothing** yet; a `todayActivityLog` section
  (last N rows, compact) is the first V1.2 item, gated on Miko's go.

Recorded for V1.2 (not built): daily/weekly "Something I noticed" via the
Thinking Loop snapshot (`snapshot.activity`), Direction-aware monthly
mirror, planned-vs-actual comparison against `ScheduledTimeBlock`.

---

## 9. Non-goals (V1)

No automatic app/screen-time/location tracking; no category picker; no
start/stop timers in the capture flow; no productivity scores, streaks,
rewards, penalties; no constant reminders; no judgmental copy anywhere; no
gap-explanation prompts; no historical editing; no plan suggestions
(F2); no deep link (V1.1); no Coach logging (V1.1); no live ticking
duration; no AI reflection (V1.2); no Pro gating.

---

## 10. Phases and definition of done

> **Implementation notes (2026-09-12):** all six phases landed in one
> session. Deviations from the plan: (a) write-side use cases live in
> `application/time_tracker_actions.dart` (log / update / delete / end)
> so reminder bookkeeping cannot be forgotten at a call site — the sheet
> and page never touch the repository directly; (b) the reminder service
> takes `evaluate`/`cancel` callbacks (wired to the orchestrator in the
> provider) so it is testable without the orchestrator's dependency
> graph; (c) cold-start taps on the "are up" reminder land via a
> near-invisible `/track` host route (`track_sheet_host_screen.dart`)
> that opens the sheet and pops itself — the pending-intent mechanism
> only replays routes; (d) `TimerRuntimeCache.save` gained an optional
> `activityEventId` so a crash-restore still ends the right event;
> (e) the Home pill shows the ongoing event only while it is younger than
> the 2-hour cap, so it never claims "since 10:03 PM" at noon the next
> day — the timeline itself still says "Ongoing" until the next log.

Each phase: `flutter analyze` clean for touched files, full `flutter test`
green, airplane-mode works, decision-log entry, only Time Tracker paths
staged.

### T1 — Domain + data + sync (no UI)
`domain/models/activity_event.dart`, `domain/timeline_builder.dart`,
`domain/day_summary.dart`, `domain/recent_activities.dart`,
`domain/duration_format.dart`, Isar collection + schema registration +
codegen, `FirestorePaths`, repository, LWW helper, merge phase, providers,
wipe-path registrations.
Tests: validate/round-trip; **timeline builder table** — explicit end
beats next event; next within 2 h; next beyond 2 h → capped + untracked
row; explicit end with a 10-min sliver → no untracked row; with a 40-min
sliver → untracked row; ongoing last row; intended shown but never
changes actual; day summary totals exclude ongoing/capped and untracked;
recent chips distinct/ordered/capped at 6; repository upsert/softDelete/
setEnd with the Isar harness; LWW older-ignored/newer-applied/tombstone
wins; architecture guard.

### T2 — Capture sheet + Home pill + Profile row
`track_activity_sheet.dart`, `track_pill.dart`, `home_screen.dart` mount,
`profile_screen.dart` row, `app.dart` route stub for `/time` (T3 fills it),
feature guide. Widget tests: sheet defaults to now; chip fills the field;
Track writes with source manual and pops; Track disabled when empty;
time picker clamps to now; duration chips set/clear intended; edit mode
prefills and exposes End; delete tombstones; pill copy switches to the
ongoing event.

### T3 — Time page
`time_screen.dart`, day pager, rows, untracked rows, summary, swipe
edit/delete on today only, FAB, empty states. Widget tests: rows render
the builder output; previous day is read-only; summary matches.

### T4 — Duration reminder + notification tap
`ReminderEntityKinds.activity`, scheduling/cancel in the repository-facing
`activity_reminder_service.dart`, `activity:` tap prefix → sheet.
Tests: schedule on Track with intended; cancel on next log/edit/delete/
end; skip when proposedAt in the past; tap handler opens the sheet.

### T5 — Focus timer hook
`ExecutionController` start/stop, runtime-cache field, injection in
`core/di/providers.dart`. Tests: start creates one timer-sourced event;
resume creates none; stop sets the explicit end; crash-restore keeps the
id; no reminder scheduled for timer events.

### T6 — Docs
Decision-log entry, `CODEBASE_GUIDE.md` persistence row + a line in §5
("Execute" now also logs an activity event), PRD status header.

---

## 11. Bug traps

1. **`dateKey` drift.** Editing the start time must re-derive `dateKey`;
   validate() enforces `dateKey == keyOf(startedAtMs)`. Local time, never
   UTC (a 22:00 UTC−7 entry is today).
2. **Sort by `startedAtMs`, never by insertion or `updatedAtMs`.** Backdated
   entries land mid-timeline.
3. **The capped case is not "ongoing".** Both have `actual == null`; the
   `endSource` enum is what the UI switches on. Test both renderings.
4. **Tombstones, not deletes.** `softDelete` writes `active:false`; every
   read filters `active`; the merge never deletes locally.
5. **Reminder bookkeeping across devices.** The reminder is device-local
   (the orchestrator + ledger are per device); a log on device A cannot
   cancel device B's OS notification. Acceptable in V1 — the ledger
   reconciliation and the "ignored" back-off already bound the damage;
   note it in the decision log.
6. **Timer hook must not await anything slow** on `start()` — the Isar
   write is milliseconds, but keep it `unawaited` after the engine
   transition so the timer UI never waits.
7. **Runtime cache shape change** (`activityEventId`) — bump its version /
   tolerate a missing field, or crash-restore of an old cache breaks.
8. **Sheet captured `now` once.** Do not re-read the clock at Track time;
   the PRD says the timestamp is the moment they opened the tracker.
9. **Chip normalisation.** "gym", "Gym " and "GYM" are one chip; display
   the most recent spelling.
10. **No `orderBy` on Firestore.** Cursor pull on `updatedAtMs` only; day
    filtering is Isar-side.
11. **Parallel session.** Stage only Time Tracker paths; check `git status`
    before every commit.
12. **The pill lives on Home, which rebuilds a lot.** Watch a tiny derived
    provider (`ongoingEventProvider`), not the whole day stream.

---

## 12. Open questions

None blocking. Defaults chosen and recorded above: `kUntrackedMinGap` =
15 min after an explicit end (§2.2 rule 1); recent chips = 6 from 30 days;
duration chips = 15m / 30m / 45m / 1h / custom; reminder importance 45,
interruption low; timer-sourced events get no duration reminder; V1 does
not look across midnight for a successor.
