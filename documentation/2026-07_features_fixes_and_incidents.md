# Engineering Log — July 2026: Features, Fixes & Incidents

_Covers work done 2026-07-05 → 2026-07-06 on branch `platform-refactor`,
commits `cc2c9c9` → `6da1a20`._

This document exists so a future engineer can understand **what** changed,
**why** it changed, and — for the several production incidents in this window —
**what broke, why, and how it was fixed**. It is deliberately narrative: the
commit messages have the diffs; this has the reasoning and the traps.

Related docs:
- [`PERFORMANCE.md`](../PERFORMANCE.md) — the July performance pass in full detail.
- [`documentation/errors.md`](errors.md) — running error log (entries #16–#18 below
  are also summarised there).
- [`documentation/firebase-rules.md`](firebase-rules.md) — Firestore rules reference.

---

## Table of contents

1. [Performance pass](#1-performance-pass-commit-cc2c9c9)
2. [Design tokens: centralized color palette](#2-design-tokens-centralized-color-palette-commit-d5493b7)
3. [Task detail page](#3-task-detail-page-commit-2a211c6)
4. [Mode-aware task rating (+ session-query crash)](#4-mode-aware-task-rating--session-query-crash-commit-6155ca3)
5. [Goal detail redesign](#5-goal-detail-redesign-commit-da42213)
6. [Chat image caching + full-screen viewer](#6-chat-image-caching--full-screen-viewer-commit-7e79da1)
7. [Weekly commitments crash + Firestore indexes](#7-weekly-commitments-crash--firestore-indexes-commit-6da1a20)
8. [Incident log (the traps)](#8-incident-log-the-traps)
9. [Recurring theme: the Firestore composite-index landmine](#9-recurring-theme-the-firestore-composite-index-landmine)

---

## 1. Performance pass (commit `cc2c9c9`)

**What:** Seven performance findings from the 2026-07-02 audit (`AUDIT.md §5`)
were re-verified and fixed one by one.

**Why:** The audit was report-only. Re-checking showed all seven were still
live — most notably a rebuild storm and a per-tick disk write during focus
sessions, and a cold start that blocked the first frame on network calls.

**How / full detail:** see [`PERFORMANCE.md`](../PERFORMANCE.md). Headlines:
- Scoped Riverpod watches with `.select()` so the whole home screen no longer
  rebuilds every timer tick.
- Timer persists on **session-shape change** only, not every second.
- `AppBootstrap` split into `initializePreFrame` (Firebase + Isar) and
  `completeDeferred` (all network work, after first frame).
- De-duplicated two providers that recomputed the same task list forever.
- Skipped the post-sync provider refresh when a pull changed nothing.

**Invariant to protect:** the deferred bootstrap phase **must never call
sign-in** — AuthGate owns anonymous sign-in, and a competing call would create
a second anonymous account and trigger the local-data wipe. See PERFORMANCE.md §3.

---

## 2. Design tokens: centralized color palette (commit `d5493b7`)

**What:** Every `Color(0x…)` literal in `lib/` (784 across 67 files) moved into
one file: [`lib/core/presentation/app_colors.dart`](../lib/core/presentation/app_colors.dart).

**Why:** Colors were declared inline everywhere. The same brand lime appeared
135 times; a near-identical second lime appeared 27 times — proof of drift
(someone eyeballs a hex from a nearby file and gets it slightly wrong). A theme
change was a 67-file hunt. The user's explicit goal: *change the theme from one
place.*

**How:**
- `AppColors` holds ~39 role-named core tokens (brand limes, accents, text
  shades, two surface families) plus a documented **one-off section** (~55
  single-use colors, each commented with which file uses it and what it paints).
- Truly identical duplicates were merged (17 call sites: `FF5252`→danger,
  `00E6FF`→cyan, `C0FF00`→accentBright). The three *intentionally* distinct
  lime shades were kept, with a header comment warning against "fixing" them.
- The sweep was scripted and is idempotent:
  [`tool/color_token_sweep.py`](../tool/color_token_sweep.py) records every
  hex→token mapping including the merge decisions.
- Existing feature palettes (`AddTaskColors`, `GoalEditorColors`, …) keep their
  local names but now alias `AppColors` — no call-site churn.

**Rule for future code:** no raw `Color(0x…)` in UI; reference a token, and
promote a one-off to a token the moment a second call site wants it.

---

## 3. Task detail page (commit `2a211c6`)

**What:** A new full detail screen for a task
([`lib/features/tasks_hub/presentation/task_detail_screen.dart`](../lib/features/tasks_hub/presentation/task_detail_screen.dart)),
opened by tapping a task on Home or in the Tasks hub (also a "Details" item in
the hub's overflow menu).

**Why:** There was no way to *see* a task — only edit it. Users wanted a place
to view everything (schedule, coaching mode, priority, notes, activity) and act
on it (start focus, mark done, edit, delete).

**How:**
- Reads fresh through `taskDetailProvider` (a family keyed on
  task/routine/block/date) and re-fetches after edit/complete/focus — so the
  page never shows a stale copy passed through navigation.
- Complete / delete / plans-changed logic was **extracted** from the hub into
  [`lib/features/planning/application/planned_task_actions.dart`](../lib/features/planning/application/planned_task_actions.dart)
  so the hub and detail page share one implementation and can't drift in their
  side effects (analytics, reminder sync, mutation coordinator). Each caller
  passes its own `sourceSurface` so analytics still record *where* it happened.
- Shows the effective discipline mode **and its source** ("Disciplined · from
  routine" vs "Extreme · set on task"), computed via `EffectiveTaskMode` — the
  same precedence execution uses.

---

## 4. Mode-aware task rating (+ session-query crash) (commit `6155ca3`)

This commit did two things: a **crash fix** and a **behavior change**. The
crash is the more important story because it masqueraded as "the checkbox is
broken."

### 4a. The session-query crash (see incident #16)

**Symptom the user reported:** tapping a task's checkbox on Home "did nothing"
— no rating card appeared.

**Actual cause:** completing a disciplined/extreme task first checks for a
finished timer session. That query
(`FirestoreExecutionRepository.getSessionsForTask`) combined two equality
filters with `orderBy('startedAtMs')`, which needs a Firestore **composite
index that was never created**. The query threw `failed-precondition`, the
exception killed `_completeTaskFromHome` before the rating card could open, and
from the outside the checkbox looked dead.

**Fix:** removed the `orderBy`, sort client-side (a task has a handful of
sessions). Also wrapped the call in `_completeTaskFromHome` in try/catch so a
failed fetch degrades to "no sessions" instead of aborting the whole flow.

### 4b. Mode-aware rating contract

**What:** The completion rating card now enforces the task's effective
discipline mode, consistently across Home and the focus/timer flow.

| Mode | Home checkbox | Focus / timer flow |
|---|---|---|
| **Flexible** | Card opens; tap-outside = done at 100% (mis-taps recoverable by unchecking) | Card dismissible; walking away saves nothing |
| **Disciplined** | Must submit a score (reason if < 100%) | Same — must submit |
| **Extreme** | Timer gate first, then must submit score **and** reason at any % | Must submit score + reason always; mandatory "next task" card on completion |

**Why:** The three discipline modes are an escalation ladder — flexible is
zero-friction, disciplined demands one honest tap, extreme demands evidence
(a timer session) plus reflection (a reason). The rating card had to reflect that.

**How:** `ScoreTaskDialog.show` gained `requireSubmit` (sets `barrierDismissible`
false + `PopScope` + hides Cancel) and `requireReasonAlways`. On Home the
mandatory-timer gate was narrowed to **extreme / strict-required only** so
disciplined tasks stay low-friction (product decision confirmed with the user).
`effectiveModeRefIdForTaskId` resolves the mode for the timer flow, which only
holds a task id.

**Subtle design point worth preserving:** the *same* card returns `null` on
tap-outside in both flows, but the two callers interpret `null` differently
(Home = "accept default 100%", timer = "cancel"). This is intentional and
documented in `score_task_dialog.dart`; don't "unify" it.

---

## 5. Goal detail redesign (commit `da42213`)

**What:** Rebuilt the goal detail screen (opened from the Home goals section)
in the "Obsidian Pulse" style from a Stitch mockup, replacing the basic
Material chips/list layout.

**Why:** The old page looked like a stock table view. The design brief (in the
attached Stitch `DESIGN.md`) calls for tonal layering instead of dividers, lime
as a "light source" for achievement, and editorial typography.

**How:** two-tone hero title, compact one-line metadata strip (scrolls
horizontally on narrow screens), a Current Streak counter (consecutive met
check-ins), a "Mission Accomplished" commitment card, the signature lime→cyan
gradient cycle-progress bar, and rounded checklist tiles with a circular check
"LED". All colors from `AppColors`; no 1px dividers (per the design's no-line
rule).

**Follow-up tweaks the user requested:** metadata pills made rectangular and
one-line by shrinking them; the target line ("30 MINUTES (PER DAY)") downsized
to reduce clutter.

**Note on the "UNDO TODAY not working" report (see incident, non-code):** the
user reported the button did nothing. Widget tests proved the wiring is
correct — tapping writes `metCommitment: false` and the card flips back. The
real cause was a **stale build / slow re-fetch**, not a code bug. Lesson: when a
button "does nothing," confirm with a test before changing code; the fix may be
"hot restart," not a patch.

---

## 6. Chat image caching + full-screen viewer (commit `7e79da1`)

**What:** Circle chat proof images now use `cached_network_image` (disk cache)
instead of `Image.network`, and tapping one opens a full-screen pinch-zoom
viewer ([`full_screen_image_viewer.dart`](../lib/features/community/presentation/widgets/full_screen_image_viewer.dart)).

**Why:** Flutter's image cache is memory-only, so every proof image
re-downloaded each app session — the last open item from the July perf pass
(PERFORMANCE.md §5). The full-screen viewer was a user request; it reuses the
cached bytes, so it costs **no extra bandwidth** (net bandwidth goes down).

**How:** swapped the widget, kept the decode-at-display-size optimization via
`memCacheWidth`, added a loading spinner and Hero transition.

**Trap it introduced (see incident #17):** `cached_network_image` pulls in the
native `sqflite` plugin (via `flutter_cache_manager`). Native code only links
during a **full build**, so after pulling this change a **hot restart** throws
`MissingPluginException (sqflite)` and every image spins forever. The fix is a
full stop + rebuild, not a code change. This is why the commit message says
"Requires a full rebuild after pulling."

---

## 7. Weekly commitments crash + Firestore indexes (commit `6da1a20`)

**What:** Fixed the "Could not load commitments" error on the circle
commitments tab, and added version-controlled Firestore composite indexes.

**Why (the bug):** the commitments stream combined
`where('weekKey' == …)` with `orderBy('updatedAtMs')` — **the same
composite-index landmine as the timer-session crash (#16)**. The query failed
with `failed-precondition`, and the view's error handler swallowed the detail,
showing only "Could not load commitments."

**How:**
- Dropped the `orderBy`, sort client-side in
  [`weekly_commitment_repository.dart`](../lib/features/community/data/weekly_commitment_repository.dart)
  (a circle's weekly commitments are a handful of rows).
- Hunted for the same pattern elsewhere and found two queries that genuinely
  need indexes because they use `limit(1)` to fetch the newest doc (client-side
  sort would mean downloading full history): latest-score-per-task, and the
  circle AI pulse banner.
- Created [`firestore.indexes.json`](../firestore.indexes.json) (taskScores:
  `taskId`+`updatedAtMs`; aiPulse: `type`+`generatedAtMs`), wired it into
  `firebase.json`, and **deployed** it. Indexes are now in version control
  instead of living only in the Firebase console.

---

## 8. Incident log (the traps)

Format matches [`documentation/errors.md`](errors.md); these are entries
**#16–#18** there.

### #16 — Task checkbox "does nothing" (Firestore composite index)
- **Where:** Home task checkbox → `_completeTaskFromHome` →
  `FirestoreExecutionRepository.getSessionsForTask`.
- **Error:** `[cloud_firestore/failed-precondition] The query requires an index`
  (composite on `targetType` + `taskId` + `startedAtMs` for `timerSessions`).
- **Root cause:** two equality filters + `orderBy` needs a composite index that
  was never created; the thrown exception killed the completion flow before the
  rating card opened, so the checkbox looked dead.
- **Fix:** remove `orderBy`, sort in Dart; wrap the fetch in try/catch so a
  failure degrades to "no sessions". (`execution_repository.dart`,
  `home_screen.dart`.)
- **Status:** Resolved.

### #17 — Chat image upload "unauthorized" + images never open
Two separate problems surfaced together:

- **17a — Upload blocked (cross-service IAM).**
  - **Where:** Circle chat image upload → Firebase Storage.
  - **Error:** `[firebase_storage/unauthorized] User is not authorized to
    perform the desired action.` Text messages worked; only uploads failed;
    creating your own circle still failed.
  - **Root cause:** `storage.rules` calls `firestore.exists()` to check circle
    membership (**cross-service rules**). That requires the Storage service
    agent to hold the **"Firebase Rules Firestore Service Agent"** IAM role.
    The role is normally provisioned when a ruleset is *uploaded*, but our
    deploy skipped the upload ("already up to date"), so it was never granted.
    Diagnostic tell: the *same* membership check passed in `firestore.rules`
    (text send worked) but failed when **Storage** evaluated it.
  - **Fix:** granted the role manually in Google Cloud console → IAM to
    principal `service-<PROJECT_NUMBER>@gcp-sa-firebasestorage.iam.gserviceaccount.com`.
    Documented the requirement in a comment at the top of `storage.rules` so it
    isn't rediscovered.
  - **Status:** Resolved.

- **17b — Images spin forever after adding disk cache.**
  - **Where:** Any chat image, right after commit `7e79da1`.
  - **Error:** `MissingPluginException (No implementation found for method
    getDatabasesPath on channel com.tekartik.sqflite)`.
  - **Root cause:** `cached_network_image` → `flutter_cache_manager` → native
    `sqflite`. Native plugins only link during a full build; a **hot restart**
    leaves the running binary without the implementation.
  - **Fix:** full stop + `flutter run` (rebuild). No code change.
  - **Status:** Resolved (operational, not a code defect).

### #18 — "Could not load commitments" (Firestore composite index, again)
- **Where:** Circle → Commitments tab →
  `FirestoreWeeklyCommitmentRepository.watchCommitments`.
- **Error:** `[cloud_firestore/failed-precondition]` (composite on `weekKey` +
  `updatedAtMs`), swallowed by the view's `error: (_, _)` handler.
- **Root cause:** identical to #16 — equality filter + `orderBy` without an
  index.
- **Fix:** drop `orderBy`, sort client-side; and declare the *other* indexes the
  app needs (`firestore.indexes.json`) so screens using `limit(1)` work.
- **Status:** Resolved.

### Known / deferred
- **Analytics-event log spam:** the periodic Firestore→Isar pull logs
  `RemoteIsarMerge: skip analytics event … Unique index violated.` on every
  sync for old duplicate events. The skip is correct; only the repeated log is
  noise. Being fixed under a separate task (silence the duplicate case instead
  of logging it each pull).

---

## 9. Recurring theme: the Firestore composite-index landmine

Three times in this window (timer sessions #16, commitments #18, plus the
pre-existing routines query in `errors.md` #10) the **same** bug bit:

> Combining `.where(field == value)` with `.orderBy(otherField)` on a Firestore
> query requires a **composite index**. If the index doesn't exist, the query
> throws `failed-precondition` at runtime — invisible until that exact screen
> runs, and easy to swallow in an error handler.

**Two ways to avoid it going forward:**
1. **Prefer client-side sort** when the result set is small (a task's sessions,
   a circle's weekly commitments). No index, no deploy step, works offline.
2. **When you truly need server-side ordering** (e.g. `limit(1)` for "the
   newest"), add the composite index to
   [`firestore.indexes.json`](../firestore.indexes.json) and
   `firebase deploy --only firestore:indexes` **in the same PR**. Now it's in
   version control and reviewable, not hidden in the console.

**Don't** swallow query errors with `error: (_, _) => genericMessage`. At least
log the exception — a `failed-precondition` message from Firestore includes a
one-click console link to create the exact index.

## 10. The release white-screen saga (2026-07-09)

**Goal**: install a standalone release build on-device so the app can be tested
"like a normal user" all day. **Symptom**: debug via `flutter run` worked
perfectly; release (and profile) builds launched from the home screen sat on a
white screen forever.

It turned out to be **two independent bugs stacked on top of each other**, with
a third bug hiding the second. Fixing only one still left a white screen, which
is what made this so confusing.

### 10a. Bug 1 — Crashlytics "urgent mode" blocks native startup

Device logs showed
`Crashlytics skipped rotating the Install ID during urgent mode` and
"uploading urgently"… then silence. When Crashlytics has **pending crash
reports** from previous launches and native auto-collection is on,
`FirebaseApp.configure` blocks the main thread to upload them **before a single
line of Flutter runs**. On a slow network the upload never completes → the
launch screen never goes away. (Ironically, the pending crashes were from Bug 2
— the bugs fed each other.)

**Fix**
- [`ios/Runner/Info.plist`](../ios/Runner/Info.plist):
  `FirebaseCrashlyticsCollectionEnabled = false` — Crashlytics no longer
  auto-starts natively, so it can never block `configure`.
- [`lib/main.dart`](../lib/main.dart): enable collection at runtime instead,
  wrapped in try/catch with a **4-second timeout** — crash reporting must never
  cost the first frame.

### 10b. Bug 2 — release linker dead-strips the Isar database engine

After Bug 1, boot advanced but "hung" at opening the local database. The real
error (revealed by Bug 3's fix):

> `IsarError: Could not initialize IsarCore library for processor architecture "ios_arm64"`

`isar_community_flutter_libs` ships the database engine as a **static library**
(`libisar.a`). Nothing in Swift/ObjC references its symbols — Dart looks them
up at runtime via `dlsym`. Release and profile builds run the linker with
dead-code stripping, which sees "unreferenced symbols" and deletes the entire
engine from the binary. Debug builds don't strip → the classic
**"works in debug, broken in release"**.

**Fix**
- [`ios/Flutter/Release.xcconfig`](../ios/Flutter/Release.xcconfig):
  `DEAD_CODE_STRIPPING = NO` (Profile inherits Release in the Flutter
  template). Cost: a few hundred KB of binary size. A comment in the file
  explains why it must stay.
- Also migrated `isar` 3.1.0 → **`isar_community` 3.3.2**
  ([`pubspec.yaml`](../pubspec.yaml), 62 import rewrites
  `package:isar/` → `package:isar_community/`, codegen rerun). The stock
  package is unmaintained; the community fork is a drop-in v3 replacement with
  the **same on-disk data format** (no user-data migration), current bug fixes,
  and active support. `Isar.open` → `Isar.openSync` in
  [`offline_store.dart`](../lib/core/offline/offline_store.dart) (it runs
  pre-frame anyway; sync surfaces errors with a clean stack).

### 10c. Bug 3 — the error handler that turned crashes into "hangs"

The `runZonedGuarded` error handler in `main.dart` forwarded uncaught errors
**only to Crashlytics** — which (a) wasn't initialized yet during early boot
and (b) was itself broken by Bug 1. So Bug 2's crash produced *zero output
anywhere*: it looked exactly like a hang, and we spent hours chasing "why does
Isar.open never return" when it was actually **throwing instantly**.

**Fix** ([`lib/main.dart`](../lib/main.dart))
- The zone handler now **always** `print`s the error + stack trace locally
  *before* attempting Crashlytics.
- `[boot]` **breadcrumbs** (`binding ready` → `pre-frame init done` →
  `brightness loaded` → `runApp`, plus `opening isar at …` in
  `offline_store.dart`) via raw `print` — `debugPrint` is deliberately silenced
  in release, so breadcrumbs must use `print`. A future white screen will now
  localize itself between two breadcrumbs in the device console
  (`idevicesyslog` or Console.app).

### 10d. Aftershock — VM tests and the stale/truncated `libisar.dylib`

`flutter test` failed post-migration: the gitignored repo-root `libisar.dylib`
was still the 3.1.0 binary (`Incorrect Isar Core version`), and Isar's
auto-download has no retry/resume, so the flaky network left a truncated 182 KB
file (`dlopen: slice extends beyond end of file`). Manual resumable download
fixed it (full command in [`errors.md`](errors.md) #21); the full suite then
passed **1005/1005**.

### Lessons

1. **"Works in debug, white screen in release" on iOS** → suspect AOT/linker
   differences first: dead-code stripping of FFI static libs, JIT-only code
   paths, silenced logging.
2. **Never route errors only to a crash reporter** — especially during boot,
   before the reporter is guaranteed alive. Print locally first.
3. **Crash reporting must be fenced off from startup**: disable native
   auto-start, enable at runtime with a timeout.
4. **Breadcrumb the boot path** with `print`. The cost is a handful of log
   lines; the payoff is that hangs and crashes localize themselves.
5. When a fix "doesn't work", consider that there may be **two bugs** — the
   Crashlytics fix *was* correct; Isar just failed right behind it.
