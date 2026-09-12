# Time Tracker V1.1 + V1.2 — Implementation PRD (v1.0)

> Status: **IMPLEMENTED on `feat/time-tracker-v1.2`, 2026-09-12 — phases
> A–E done; Time Tracker suite 91 green, functions suite green. Awaiting
> Miko's device run (Siri intent + Coach card need a real device) and
> commit. `coach_prompts.ts` changed → needs `firebase deploy --only
> functions` for the "Their time" rule and logActivity parameter docs.**
> Decisions settled by Miko's answers 1–12 (2026-09-12).
> Sources: `time_tracker_prd.md` §§12–17, 20; `time_tracker_implementation_prd.md`
> (V1, shipped at 3a8f18a); Direction PRD (the mirror); a code read of the
> Siri App Intent bridge, the Coach action pipeline, the Thinking Loop
> parser/apply path, and the time-block repository.
>
> Guiding line for everything reflective here:
> **Don't tell people how to live. Help them see how they're living.**

---

## 0. Decisions as settled (do not relitigate)

| # | Topic | Decision |
|---|---|---|
| 1 | Deep link with text | **Dropped.** No `sidepal://track?text=`, no user-built Shortcuts. |
| 2 | Siri | **Native App Intent** "Log activity": *"Hey Siri, log activity in SidePal"* → Siri asks *"What are you doing?"* → the event is created, no user setup. (Build finding: App Shortcut phrases may only embed AppEntity/AppEnum parameters, so a free-text activity cannot be spoken inline in the phrase — Siri prompts for it.) Optional minutes parameter. |
| 3 | Coach logging | The **existing action card**, one tap: `Log Gym at 7:42 PM · [Log]`. Never a silent write, never an inline chip — logging writes data. |
| 4 | Coach reading | **Yes.** Today's timeline joins the Coach payload so "what did I do today?" / "how long did I work?" work. |
| 5 | Gap tap | **Yes.** Tapping an untracked row opens the capture sheet with the gap's start prefilled. Today only. |
| 6 | Categories | **AI classification** in the daily reflection into a fixed set, stored per activity text so the same word is never re-asked; **override on the edit sheet**; capture stays category-free. |
| 7 | Weekly view | **Day \| Week toggle** on the Time page. |
| 8 | Planned vs actual | **Timer-sourced events only** (exact task link). No fuzzy matching of manual entries. |
| 9 | Observations | **Time page only.** Never on Home / On your radar. |
| 10 | AI budget | **Ride the existing daily Thinking Loop call**: timeline snapshot every day; week/month aggregates on the boundary days. No new purpose. |
| 11 | Direction mirror | **Time page** (month view). Direction stays quiet. |
| 12 | Tone | Observational only. Banned in the prompt AND the validator: *wasted, should, failed, bad, lazy, "you need to", "you should", "you ought to", "you wasted", "you failed", "you were unproductive", "you spent too much"*, and any comparison implying a correct amount of time. |
| — | Branch | One: `feat/time-tracker-v1.2`. |

**Fixed category set (decision 6):** `work, learning, exercise, entertainment,
rest, chores, social, other`. Stored as strings; `other` is a real answer,
not a fallback.

---

## 1. Feature review checklist (short form)

- **Problem** — the timeline exists but nothing reads it: no Siri capture,
  the Coach can't see or write it, and the user gets no reflection.
- **Duplication** — Siri mirrors `SiriVoiceEntry`; Coach logging mirrors
  `createIntention` (minus auto-commit); observations reuse the reflection
  pass and insight cache; categories reuse the Direction/ActivityEvent
  synced-entity pattern.
- **Offline class** — category rules + observations are user-own data →
  local-first. AI calls are the existing budgeted ones → optimistic-then-
  honest is already how they fail (silent skip, retry next open).
- **Failure story** — no reflection = no section (silence is normal). A
  Siri log that can't reach Isar (never, Isar is local) would show nothing;
  the intent always opens the app so Dart does the write.
- **Navigation** — no new routes except none; Siri lands on Home with a
  toast; Coach card is the existing sheet.

---

## 2. Phase A — in-app V1.1 (no native, no AI pass changes)

### A1. Gap tap
`_UntrackedTile` becomes tappable on today: `showTrackActivitySheet(context,
presetStartMs: row.fromMs)`. The sheet's clamp-to-now still applies. On
previous days untracked rows stay inert.

### A2. Cross-midnight successor
`buildTimeline` gains an optional `nextDayFirstStartMs`: when the last event
of the day has no explicit end and the next day's first event starts within
the 2-hour cap, it ends the last event (source `nextEvent`); beyond the cap
→ `capped` + untracked row to midnight? **No** — untracked rows never cross
the day boundary; the row is simply `capped` with no untracked row (the gap
belongs to no day). `dayEventsProvider` gets a sibling
`nextDayFirstStartProvider(dateKey)` reading the following day's first
event.

### A3. Coach reads the timeline
- `AiOperatingLayerPayload.todayActivityLog: List<String>` — rendered rows
  `"10:03–10:09 Scrolling · 6m"`, `"10:50 Cleaning house · ongoing"`,
  `"? · 3h 51m untracked"`, plus one tail line `"Logged 8h 42m · untracked
  3h 51m"`. Max 25 rows (newest kept). Per-turn (never session-cached).
- `AiPayloadAssembler._buildTodayActivityLog()` via
  `ActivityEventRepository.fetchDayOnce(todayKey)` + `buildTimeline` +
  `buildDaySummary`. Injected repository (nullable, like the others).
- `_buildUserPrompt`: block `Today's timeline (what they actually did —
  recorded, not planned):` placed after the goals/progress blocks. Rule
  inline: *Describe it, don't judge it. Never call time wasted, never say
  they should have done otherwise.*
- Trimming: dropped on non-planning turns? **No** — questions like "what
  did I do today" are informational turns; keep it on every turn (it is
  small and the day's truth).

### A4. Coach logs an activity (confirm card)
- `ActionType.logActivity` — risk **low**, **not** in `autoCommitTypes` (card
  + Confirm/Log, decision 3).
- Parameters: `text` (required, ≤80), `time` ("HH:mm", optional, default
  now; today only — a time later than now clamps to now), `intendedMinutes`
  (optional int).
- Executor `_logActivity(p, ops)`: pre-assign `_activityEventId` in the
  pre-pass (like `_intentionId`); `TimeTrackerActions.log(ActivityEvent(...
  id: presetId, source: manual))`; returns `Logged "Gym" at 7:42 PM`.
- Undo/rollback: `_rollbackLoggedActivities(batchId)` → `actions.delete(id)`
  (tombstone + reminder cancel), wired wherever `_rollbackCreatedIntentions`
  is called.
- Card copy (`planned_changes_card.dart`): icon `schedule_outlined`,
  description `Log "Gym" at 7:42 PM` (+ ` · 30m` when intended). Voice
  speech: `log Gym`. Missing-field detector: `text` → "What are you doing?".
- Tool schema enum + `coach_prompts.ts` parameter docs + a rule:
  *"I'm at the gym now" / "just started studying" → propose ONE logActivity
  (never mixed with other kinds). If they already logged it (see Today's
  timeline), don't propose a duplicate — say it's already there.* This is a
  server prompt change → **needs `firebase deploy --only functions`**; the
  tool enum and the inline user-prompt block work before the deploy.
- `AiActionExecutor` gets `timeTrackerActions` injected (nullable).

---

## 3. Phase B — Siri "Log activity" (native)

`ios/Runner/SiriLogActivity.swift`, compiled into the Runner target like
`SiriVoiceEntry.swift` (no extension, no App Groups), `@available(iOS 16.0, *)`:

```swift
struct LogActivityIntent: AppIntent {
  static var title: LocalizedStringResource = "Log activity"
  static var openAppWhenRun = true
  @Parameter(title: "Activity") var activity: String
  @Parameter(title: "Minutes", default: nil) var minutes: Int?
  static var parameterSummary: some ParameterSummary { Summary("Log \(\.$activity)") }
  @MainActor func perform() async throws -> some IntentResult {
    SiriLogActivityBridge.stamp(activity: activity, minutes: minutes)   // UserDefaults JSON + NotificationCenter
    return .result()
  }
}
```

`SidePalAppShortcuts` gains a second `AppShortcut` with phrases
`"Log activity in \(.applicationName)"`, `"Track activity in
\(.applicationName)"`, `"Log what I'm doing in \(.applicationName)"`,
`"Track my time in \(.applicationName)"`. Siri then asks "What are you
doing?" (the String parameter's `requestValueDialog`) — a phrase cannot
embed a free-text parameter (only AppEntity/AppEnum), which the first
simulator build proved.

`AppDelegate`: a third channel `sidepal/siri_log_activity` with
`consumePendingLog` (returns `{text, minutes}` or null) + warm event
`logRequested`. Dart `lib/app/siri_log_activity.dart` mirrors
`SiriVoiceEntry`: consume on launch/resume/event, then
`TimeTrackerActions.log(...)` with `startedAtMs = now`, and a snackbar on
Home: `Logged Gym at 7:42 PM`. Idempotent consume (native clears on read);
text trimmed/capped at 80; empty text → sheet opens instead (never a blank
log).

---

## 4. Phase C — categories

### C1. Entity `ActivityCategoryRule` (synced, local-first set)
`id = 'cat_' + normalizedText hash? ` → **deterministic** id from the
normalized text (`cat_<base64url(normalizedText)>` truncated safely) so two
devices converge. Fields: `normalizedText`, `category` (fixed set),
`source` (`ai` | `user`), `createdAtMs`, `updatedAtMs`. No tombstone: a
rule is overwritten, never deleted. Isar collection + `users/{uid}/
activityCategoryRules` + repository (`watchAll`, `upsert`,
`fetchAllOnce`) + LWW merge + pull phase. `user` beats `ai` regardless of
timestamp? **No** — LWW is the one conflict rule in this app; instead the
reflection pass never proposes a rule for a text that already has a
`user` rule (the snapshot marks them), so a user override is never
overwritten by AI.

### C2. Reflection proposes categories
Snapshot `activity.uncategorizedTexts: [..≤20]` (distinct normalized texts
from the last 7 days with no rule). Parser gains `activityCategories:
[{text, category}]`, validated: text ∈ the sent list, category ∈ fixed set,
≤20. Apply → `ActivityCategoryRule(source: ai)` upsert (skip if a rule now
exists). Inputs hash includes rule count so new texts re-arm the loop.

### C3. Override on the edit sheet
Edit mode only: a `CATEGORY` micro-label + chip row of the eight, selected =
current rule (if any). Picking writes a `user` rule for the event's
normalized text (applies to every past and future event with that text —
say so in a one-line hint: *"Applies to every 'Gym'."*).

### C4. Summary by category
`buildDaySummary(rows, rules)` → `DaySummary.categoryLines` (category →
total, `other` for texts with no rule) rendered ABOVE the activity lines:

```
SUMMARY
You logged 8h 42m · Untracked 3h 51m
Work 3h 20m · Exercise 1h 10m · Entertainment 2h 30m · Other 1h 42m
By activity
SidePal   3h 20m
Gym       1h 10m
…
```

Category block hidden when no rule matches anything that day.

---

## 5. Phase D — V1.2 reflection

### D1. Day | Week toggle
Segmented control above the pager. Week = ISO week (`DateKeys.isoWeekKey`),
pager steps by week, label `This week · 8–14 Sep`. `weekEventsProvider(weekKey)`
via `repository.watchRange(fromMs, toMs)`; `WeekSummary` = the day summary
over the week's concatenated per-day timelines (build each day separately
so the gap cap never crosses midnight), plus `days logged / 7` and the
biggest activity. Week view is read-only (no swipe, no FAB).

### D2. Planned vs actual (timer-sourced rows)
For `source == timer` with `sourceEntityId`: `TimeBlockRepository
.getBlockForEntity(id)` → if the block's day is the row's day, a detail
line `Planned 7:00–8:00 · Started 7:42` (and `· Ended 8:27` when explicit).
No line when there is no block. Provider `plannedForEventProvider(eventId)`;
never a judgment word.

### D3. Observations (the "Something I noticed")
Reflection snapshot `activity`:
```
{ "today": [{"id","text","start":"10:03","minutes":6|null,"source"}],
  "todayLogged": "8h 42m", "todayUntracked": "3h 51m",
  "last7Days": {"loggedMinutes", "byCategory": {..}, "byActivity": [{text, minutes}] ≤10,
                "byHourBand": {"morning","afternoon","evening","night"} minutes,
                "daysWithEntries": 5},
  "weekBoundary": {...}   // only on the first reflect of a new ISO week: previous week's aggregates
  "monthBoundary": {...}  // only on the first reflect of a new month: previous month's aggregates
                          //   + that month's Direction texts (from history — never current context)
  "uncategorizedTexts": [...] }
```
Parser gains `timeObservations: [{scope: "day"|"week"|"month", message ≤200,
basedOn}]`, ≤1 per scope per pass, message rejected if it matches the banned
list (case-insensitive, word-boundary) — **the validator enforces tone, not
just the prompt**. Apply → insight cache scope `time:day:<dateKey>`,
`time:week:<weekKey>`, `time:month:<monthKey>` (entity scope, type
`reflectionObservation`). The radar reads only `reflectionScopeId`, so
nothing leaks to Home; the focus/notification pipeline already excludes
`reflectionObservation`.

Time page rendering: day view tail shows today's day observation under the
summary as `SOMETHING I NOTICED` + message (INFERRED label, dismiss ×);
week view shows the week observation for the displayed week; the month
observation (the Direction mirror) shows at the tail of the week view for
the current month, headed `YOUR MONTH · SEPTEMBER`.

Prompt rules (client-owned `reflect` prompt): describe patterns in the
user's own words for activities; one sentence, ≤200 chars; only when the
snapshot genuinely shows something (empty is the right answer); the full
banned list; for the month scope, *put the Direction text next to what the
time shows and stop there — no advice*.

### D4. Direction mirror copy shape (month)
> Your focus was getting SidePal ready for launch. You logged 31h 20m on
> SidePal, 24h 10m gaming, 18h 40m scrolling. SidePal work was concentrated
> in late-night sessions.

---

## 6. Phase E — docs + deploy

> **Implementation notes (2026-09-12):** (a) the Siri intent lives inside
> `ios/Runner/SiriVoiceEntry.swift` (no new Xcode file references) with its
> own bridge enum, channel `sidepal/siri_log_activity`, and Dart
> `lib/app/siri_log_activity.dart`; (b) `logActivity` rides the standard
> confirm card — the executor pre-assigns `_activityEventId` so undo
> tombstones exactly what was logged; (c) category rules are a synced
> entity with a deterministic id per normalised text; the repository
> refuses `ai` over `user` locally and the snapshot never lists user-set
> texts, so LWW stays the only conflict rule; (d) time observations are
> cached under `time:<day|week|month>:<key>` through a generalised
> `_cacheObservationForScope`, the parser enforces the tone list, and the
> Time page is the only reader; (e) week/month boundary aggregates are
> gated by two per-account prefs keys (wipe-listed); (f) the Week view
> sums per-day timelines so the 2-hour cap never crosses midnight.
Decision log; PRD status; CODEBASE_GUIDE (new entity row, Siri intent line,
Coach action); `coach_prompts.ts` ships on the next functions deploy.

---

## 7. Non-goals
No deep link with text; no manual category on capture; no fuzzy planned/
actual; no observations on Home; no new AI purpose; no live counter; no
notifications for any reflection; no editing of previous days.

---

## 8. Bug traps
1. `logActivity` must not join `autoCommitTypes`.
2. Undo of a logged activity is a tombstone + reminder cancel, never a
   hard delete.
3. Siri stamp must be consumed once — native clears on read; Dart guards
   against a double `resume` with the same value.
4. Week aggregates: build per-day timelines, then sum — never run the gap
   cap across midnight.
5. Category rule ids are deterministic from normalized text; `user` rules
   are excluded from AI proposals at snapshot time.
6. Tone validator runs on every observation before caching; a rejected
   message is dropped silently (no fallback copy — silence is the answer).
7. Boundary aggregates only on the FIRST reflect after the boundary
   (prefs key `time_reflect_week_done_v1` = weekKey, `…_month_done_v1`),
   per-account → wipe list.
8. The Coach prompt block is data; the banned-tone rule for the Coach lives
   in the same inline block (works pre-deploy) and in `coach_prompts.ts`.
