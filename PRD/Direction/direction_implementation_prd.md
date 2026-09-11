# Direction — Implementation PRD (v1.0)

> Status: **IMPLEMENTED on `feat/direction`, 2026-09-11 — phases D1–D5 done,
> `flutter analyze` clean for touched files, full Dart suite + functions suite
> green. Awaiting Miko's commit and the (already pending) `firebase deploy
> --only functions` for the `coach_prompts.ts` rule. Not yet exercised on a
> device — the D4 manual Coach transcript check is still open.**
> Decisions settled by Miko's answers 1–16 + OQ-1..3 (2026-09-11).
> Sources: `direction_prd.md` (the product idea), a two-agent codebase
> reconnaissance (AI payload seams, insight pipeline, Home/Profile surfaces,
> rollover hooks, shared UI), and Miko's answers.
>
> One-line spec, to be repeated in every file header of this feature:
> **Direction is not something SidePal asks the user to accomplish. It is
> something SidePal remembers while helping them.**

---

## 0. Decisions as settled (do not relitigate)

| # | Topic | Decision |
|---|---|---|
| 1 | Periods | Calendar year, calendar quarter, calendar month. Keys `2026`, `2026-Q3`, `2026-09`. |
| 2 | Carry-forward | Nothing auto-copies. At rollover the new period starts **empty**, with the previous period's text shown as a **suggestion** the user can keep or replace. Same for year and quarter. |
| 3 | History | Kept. One row per horizon per period, never overwritten by the next period. **No history UI in V1** — store it properly, that's all. |
| 4 | Text | Free text, 280 chars max per horizon. Visually a short statement field, not an essay box. |
| 5 | Empty | Any horizon may be empty. Never force all three. |
| 6 | Placement | Profile hub → **Direction** page (the real page). Goals tab gets an **extremely subtle** one-line strip ("Your current direction · <month text>") that opens the page. **Not on Home permanently.** |
| 7 | Rollover prompt | **Month only.** A dismissible Home card ("A new month · What's your focus for September? · + Add your direction"). No notification. Quarter/year never prompt; their rows appear lazily when the user writes. |
| 8 | Editing | **Revised 2026-09-12 after device test:** empty horizon shows the question + a quiet `+ Add` row; tapping opens a field with Save / Cancel. A set horizon renders as a plain statement; tap to edit. Invisible safety net: backing out with a dirty open editor still saves. (Originally inline autosave — three always-open fields read as a form, and autosave had no clear "done" moment on a phone.) |
| 9 | Tier | **Free.** Foundational context, never gated. |
| 10 | AI consumers (V1) | All three, each with its own responsibility: **Coach** = context when helping; **Insight phrasing** = phrase observations in relation to what matters; **Thinking Loop** = the "Something I noticed" reflection (≤1/day, no notification). |
| 11 | Direction vs Time mirror | **Context only in V1.** No planned-minutes stand-in — planned ≠ actual. The mirror ships with the Time tracker (next PRD). |
| 12 | Reflection cadence | Daily loop makes small observations only when there's genuinely something. Monthly "here's what your month looked like" reflection lands **with Time tracking**, not now. Not on Progress ("Progress implies scoring"). |
| 13 | Quoting | Reason silently ("given what you're focusing on this quarter…"). A short natural quote is allowed only when it genuinely improves a reflection. Prompt rule, verbatim: *Direction is context, not a command. Do not repeatedly quote it, preach it, or use it to judge the user's behavior.* |
| 14 | Onboarding | Untouched. Interest tags never become a Direction. |
| 15 | Goals / categories | Fully decoupled. Direction = where I'm going; Goals = outcomes; Tasks = doing; Time = did. AI relates them later; data models don't. |
| 16 | Branch | `feat/direction` off `main`. Touch only Direction-related files (another session shares the checkout). |

**Conceptual architecture (Miko):** Direction is a *context source*.

```
                    ┌─────────────┐
                    │  Direction  │
                    │ Year/Quarter│
                    │    /Month   │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              ↓            ↓            ↓
           Coach        Insights     Thinking
                                      Loop
```

Later (after Time): `Direction → Plan → Actual Time → Insights`.

**Size discipline:** Direction itself stays tiny. No goal-management system
grows out of this entity. If a step below feels like it is adding management
(status, progress, linking), stop.

---

## 1. Feature review checklist (GUIDELINES.md)

1. **Problem** — SidePal helps with tasks and schedules but has no idea what the
   person is ultimately trying to move toward, so its help is generic.
2. **Principle fit** — P2 offline-first (user's own data), P4 sync is silent,
   P6 chrome recedes (a quiet page, a quiet strip, one quiet card).
3. **Duplication** — Nothing does this. Memory facts are extracted, ≤200 chars,
   scored and evicted; intentions are hours-to-days promises; goals are
   measured outcomes; onboarding interests are tags. Direction is its own
   entity (§3).
4. **Offline class** — user-own data → full local-first set. Airplane mode
   must be indistinguishable from online.
5. **Consistency** — `AppColors`, `PageTitle`/`SectionHeader`, 11px
   micro-labels, `SettingsPageScaffold`, `SettingRow`, `GoalEditorTextField`
   styling via `goalEditorInputDecoration`.
6. **Navigation** — Direction is a single pushed route; back pops to Profile
   (or Goals, or Home, wherever it was opened). No multi-step flow.
7. **Failure story** — none visible: local write is the update; the outbox
   replicates; a stuck write shows only the existing thin amber line. The AI
   consumers degrade to "no direction block" silently.
8. **Maintenance cost** — one new synced entity: Isar collection + outbox +
   watch provider + pull phase + cursor key + wipe-list prefs key.
9. **Semantics** — confirmed above (§0).

---

## 2. Period logic (pure Dart, no Flutter)

File: `lib/features/direction/domain/direction_periods.dart`

```dart
enum DirectionHorizon { year, quarter, month }

class DirectionPeriod {
  final DirectionHorizon horizon;
  final String key;        // '2026' | '2026-Q3' | '2026-09'
  final int startMs;       // local midnight of first day
  final int endMs;         // local midnight of first day of NEXT period (exclusive)
  final String label;      // '2026' | 'Q3 2026' | 'September'
}

class DirectionPeriods {
  static DirectionPeriod current(DirectionHorizon h, DateTime now);
  static DirectionPeriod previous(DirectionPeriod p);   // Jan → previous Dec, Q1 → previous Q4
  static String keyFor(DirectionHorizon h, DateTime now);
  static DirectionPeriod? parseKey(String key);         // inverse, for history reads
}
```

Rules:
- All boundaries are **local calendar** (`DateTime(y, m, 1)`), same as
  `goal_period_helpers.localCalendarMonthBounds`. Never UTC.
- Quarter = `((month - 1) ~/ 3) + 1`.
- `previous` crosses year boundaries correctly (`2026-01` → `2025-12`,
  `2026-Q1` → `2025-Q4`, `2026` → `2025`).
- Keys sort lexicographically within a horizon (zero-padded month).

Tests: `test/features/direction/direction_periods_test.dart` — boundaries at
Dec 31 23:59 / Jan 1 00:00, leap Feb, each quarter edge, `previous` across
years, `parseKey` round-trips.

---

## 3. Data model

### 3.1 Domain — `lib/features/direction/domain/models/direction_entry.dart`

```dart
class DirectionEntry {
  final String id;             // deterministic: 'dir_<horizon>_<periodKey>' e.g. 'dir_month_2026-09'
  final DirectionHorizon horizon;
  final String periodKey;      // '2026-09'
  final String text;           // '' allowed (cleared), max 280 after trim
  final int periodStartMs;
  final int periodEndMs;
  final int createdAtMs;
  final int updatedAtMs;       // LWW key — bump on EVERY write

  bool get isEmpty => text.trim().isEmpty;
  void validate();             // horizon/periodKey consistent, text ≤ 280, start < end, ids match
  Map<String, dynamic> toMap(); factory fromMap(Map);
  DirectionEntry copyWith({...});
}

const int kDirectionMaxChars = 280;
String directionEntryId(DirectionHorizon h, String periodKey) => 'dir_${h.name}_$periodKey';
```

**Why a deterministic id (not `StableId.generate`)**: two devices offline in the
same month both writing "this month" must converge on ONE document. Same id →
same Isar row (unique index) → same Firestore doc → plain LWW on `updatedAtMs`.
Random ids would produce duplicate September rows that no merge could
reconcile. This is the single most important correctness decision in the
feature.

**Clearing is not deleting.** Clearing the field writes `text: ''` with a fresh
`updatedAtMs`. No tombstone flag, no delete path, no `outboxDelete`. The row
stays (history) and LWW handles a clear-vs-edit race across devices.

### 3.2 Isar — `lib/core/local_db/isar_collections/isar_direction_entry.dart`

```dart
@collection
class IsarDirectionEntry {
  Id id = Isar.autoIncrement;
  @Index(unique: true) late String entryId;
  @Index() late int updatedAtMs;
  @Index() late String horizonStorage;   // 'year' | 'quarter' | 'month'
  @Index() late String periodKey;
  late String text;
  late int periodStartMs;
  late int periodEndMs;
  late int createdAtMs;
  static IsarDirectionEntry fromDomain(DirectionEntry e);
  DirectionEntry toDomain();
}
```

Register `IsarDirectionEntrySchema` in `isar_schemas.dart`; run
`dart run build_runner build --delete-conflicting-outputs`. (Mirror
`isar_intention.dart` exactly for enum-as-string storage.)

### 3.3 Firestore — `lib/core/firebase/firestore_paths.dart`

```dart
static String get directions => '$userRoot/directions';
static String directionDocument(String entryId) => '$directions/$entryId';
```

`firestore.rules` already covers `users/{uid}/{collection}/**` with the blanket
owner rule — **no rules change, no deploy needed for data.**

---

## 4. Repository and providers

### 4.1 `lib/features/direction/data/direction_repository.dart`

Copy the `IntentionsRepository` shape exactly:

```dart
class DirectionRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  Stream<List<DirectionEntry>> watchAll();               // all rows, history included, sorted updatedAt desc
  Future<List<DirectionEntry>> fetchAllOnce();
  Future<DirectionEntry?> get(DirectionHorizon h, String periodKey);

  /// Upsert-or-create for (horizon, period). Trims, validates, stamps updatedAtMs,
  /// Isar writeTxn putByEntryId, then outboxUpsert(entityType: 'direction',
  /// documentPath: FirestorePaths.directionDocument(id), payload: toMap()).
  /// NO-OP when the trimmed text equals what is already stored (prevents
  /// autosave from bumping updatedAtMs and spamming the outbox).
  Future<DirectionEntry> setText(DirectionHorizon h, DirectionPeriod period, String text);
}
```

Rule enforced by `test/architecture/local_first_guard_test.dart`: never
`await` a Firestore write here.

### 4.2 `lib/features/direction/application/direction_providers.dart`

```dart
final directionRepositoryProvider = Provider<DirectionRepository>(...);

/// Every row (history included). UI and AI derive from this; the local write IS the update.
final directionEntriesStreamProvider = StreamProvider<List<DirectionEntry>>(...);

/// The three current-period slots, resolved against `now`.
/// `current` may be null (never written) — that is the normal empty state.
/// `suggestion` = previous period's non-empty text, only when current is null/empty.
class DirectionSlot { final DirectionPeriod period; final DirectionEntry? current; final String? suggestion; }
final currentDirectionProvider = Provider<Map<DirectionHorizon, DirectionSlot>>(...);

/// Compact, ordered lines for the AI consumers (§8). Empty list when nothing is set.
final directionContextLinesProvider = Provider<List<String>>(...);
```

`currentDirectionProvider` needs "now". Use a `directionClockProvider =
StateProvider<DateTime>` that `AppLifecycleTaskRefresh` re-stamps on day change
and resume (§7) — so the slots roll over without restarting the app, and tests
can pin time.

**No `ScheduleMutationCoordinator`** — Direction never touches the schedule.

---

## 5. Sync

### 5.1 Pull — `lib/core/sync/remote_isar_merge.dart`

Add `_pullDirections()` (clone `_pullIntentions`) with cursor key
`'directions'`, and `_mergeDirection(DirectionEntry incoming)` (clone
`_mergeIntention`: `shouldApplyRemoteUpdatedAt` then `putByEntryId`). Insert
the call in `run()` right after `_pullIntentions()` + `_abortIfUidChanged()`.
It is a core phase (not `_pullGuarded`) — the collection is under the blanket
rule so it cannot be permission-denied on the live project.

### 5.2 Push

Handled entirely by `outboxUpsert` in the repository; the queue is uid-tagged
already. Nothing to add.

### 5.3 Account-switch wipe (§8 of CODEBASE_GUIDE)

- Isar collection: wiped automatically by the "wipe every collection" path.
- Prefs key `direction_month_card_handled_v1` (§7): **must** be added to the
  `prefs.remove(...)` list in `AuthSessionPolicy.clearLocalSession`.
- Providers: `directionEntriesStreamProvider` watches Isar, so it re-emits after
  wipe + forced pull; nothing to add to `invalidateUserScopedProviders` unless
  a non-autoDispose cache is introduced (don't introduce one).

---

## 6. The Direction page

Route `/direction`, `DirectionScreen.routeName`, registered in the flat
`routes:` map in `lib/app/app.dart`. File:
`lib/features/direction/presentation/direction_screen.dart`.

### 6.1 Layout (SettingsPageScaffold, title `PageTitle('Direction')`)

```
YOUR DIRECTION                                   ← SectionHeader
Give SidePal some context about where you
want your life to go.                            ← SectionHeader.subtitle

THIS YEAR · 2026                                 ← 11px micro-label
What do you want this year to be about?          ← hint inside the field
[ Build a successful business              ]     ← field   ✓ Saved (fades)

THIS QUARTER · Q3 2026
What are you focused on right now?
[                                           ]
Last quarter: Build the product        Keep     ← suggestion row (only when field empty AND previous non-empty)

THIS MONTH · SEPTEMBER
What matters most this month?
[ Get SidePal ready for launch             ]

Direction isn't a to-do. SidePal keeps it in     ← quiet footer, AppColors.fg38, 12px
mind while helping you.
```

- Field: `TextField` styled with `goalEditorInputDecoration`, `maxLength: 280`
  with the counter hidden (`buildCounter` returns null) — show the counter only
  when ≥ 240 chars. `maxLines: null`, `minLines: 1` (grows if the user writes
  two lines, still *looks* like a statement field). `textCapitalization:
  sentences`.
- Suggestion row: previous period label + text (single line, ellipsis) +
  `Keep` text button. `Keep` calls `setText(current period, suggestion)` — it
  is the only way the previous text enters the new period. Row disappears once
  the field has any text.
- Footer copy is the product spec sentence in plain words.
- No delete, no history, no reorder, no chevrons, no progress.

### 6.2 Entry semantics (revised 2026-09-12 — see decision 8)

> The autosave design below was replaced by `+ Add` → field + Save / Cancel,
> statement view when set, and a dispose/pause safety net for dirty open
> editors. Rules 4 and 6 still hold (an open editor is never clobbered by
> the stream; text is trimmed on save). The original text is kept for the
> record.

#### Original autosave semantics (superseded)

Controller per horizon (`_DirectionFieldController`):

1. **Debounced save while typing**: 700 ms after the last keystroke →
   `repository.setText`. (Repo no-ops if unchanged.)
2. **Save on focus loss** immediately (cancels the pending debounce).
3. **Save on `dispose`** and on `AppLifecycleState.paused` — the user backing
   out mid-word must not lose the word.
4. **Never re-populate the controller from the stream while it has focus.**
   Remote merges (another device) update the field only when it is unfocused;
   if the user is typing, their keystrokes win locally and LWW settles it.
5. **Saved indicator**: `Idle → Dirty → Saving → Saved(✓, 1.5 s) → Idle`, an
   `AnimatedOpacity` 12px label at the field's trailing edge. "Saving" is
   never shown for < 150 ms (avoid flicker); since the write is a local Isar
   txn it will essentially always jump Dirty → Saved.
6. Trim on save; do not trim the live controller text.

Widget test: type, wait 700 ms → one repo call; type again, blur → one more;
type identical text → zero calls.

### 6.3 Entry points

- **Profile hub** — new **first** `SettingRow` in `_ProfileHubList`
  (`profile_screen.dart`): icon `Icons.explore_outlined`, title `Direction`,
  subtitle = current month text if set, else `Where you're heading — year,
  quarter, month`. Chevron trailing. Pushes `/direction`.
- **Goals tab strip** — `lib/features/direction/presentation/direction_strip.dart`,
  mounted in `goals_home_screen.dart` between `FirstTimeFeatureCard` and
  `CategoryChipRow`. One line, `AppColors.textSoft`, 12px, no card, no
  background: `YOUR CURRENT DIRECTION` micro-label + the month text (falls
  back to quarter, then year). When nothing is set at all: `Set your
  direction` in the same quiet style (the feature's only discovery surface
  besides Profile). Tapping anywhere pushes `/direction`. Nothing else.
- **Feature guide** — add a `direction` entry to
  `features/education/domain/feature_guides.dart` so the Coach can answer
  "what is Direction?" from the guide, and `HelpAppBarButton('direction')` on
  the page. No `FirstTimeFeatureCard` anywhere (would contradict "quiet").

---

## 7. Month rollover card (Home)

File: `lib/features/direction/presentation/new_month_direction_card.dart`,
mounted on Home **directly above `PostOverrideReviewCard`** (the one-off band;
after `RecoveryCard`, since a standing debt outranks a one-off ask).

Copy (Miko's):

```
A new month
What's your focus for September?
+ Add your direction                      ×
```

Tapping the CTA or the body pushes `/direction` (the page shows last month's
text as the suggestion). `×` dismisses.

### 7.1 Visibility rule (pure function, unit-tested)

```
show ⇔ monthKey(now) != prefs['direction_month_card_handled_v1']
     && current month entry is null or empty
     && prefs key is not unset-because-fresh-install
```

- **Fresh install / account switch seeding**: on first evaluation with the key
  unset, write `handled = monthKey(now)` and show nothing. The card is a
  *rollover* prompt, not an onboarding prompt (day 1 discovery is the Goals
  strip + Profile row).
- **Handled** is written when: the user dismisses, or the user opens the page
  from the card, or the month entry becomes non-empty by any path (page, Keep,
  Coach). Once handled it never returns this month.
- Quarter/year: **no card, ever** (decision 7).
- No notification, no badge, no dot.

### 7.2 Rollover detection

`AppLifecycleTaskRefresh._invalidateIfDayChanged` already ticks every minute
and on resume. Add one line each place `_lastTodayKey` is re-stamped:
`container.read(directionClockProvider.notifier).state = DateTime.now()`.
`currentDirectionProvider` and the card's provider derive from that clock, so
the card appears on the first tick of the new month without a restart. No new
timer, no monthly hook in core.

Prefs key must join `AuthSessionPolicy.clearLocalSession` (§5.3).

---

## 8. AI consumers

One shared source: `directionContextLinesProvider` → e.g.

```
This year (2026): Build a successful business
This quarter (Q3 2026): Launch SidePal
This month (September): Get SidePal ready for launch
```

Empty horizons are omitted. **A previous period is never sent as current
context** (OQ-2, Miko): current period has text → use it; current period is
empty → that horizon is simply absent; the previous period stays available
as history and as the page's suggestion, nothing more. If nothing at all is
set, the block is omitted entirely.

> **Key rule (put in every consumer's header comment):** A previous Direction
> can inform history or be offered as a suggestion, but it must never be
> treated as the user's current Direction unless the user explicitly carries
> it forward.

Shared rule text, used verbatim in all three prompts:

> Direction is context, not a command. Do not repeatedly quote it, preach it,
> or use it to judge the user's behavior. Reason with it ("given what you're
> focusing on this quarter…"); quote a short phrase only when it genuinely
> helps.

### 8.1 Coach

- `AiOperatingLayerPayload`: new `final List<String> direction;` (default
  `const []`), serialized in `toJson` as `direction`.
- `AiPayloadAssembler.assemble`: add `_buildDirection()` to the **per-turn**
  `Future.wait` (the user can edit Direction mid-session; the 30 s slice cache
  would hide it). Reads `DirectionRepository.fetchAllOnce()` and derives the
  same lines as the provider (share the pure function
  `buildDirectionContextLines(entries, now)` in `domain/`).
- `AiOperatingLayerClient._buildUserPrompt`: insert **after** the
  `intentHint` block and **before** `FEATURE GUIDE`:
  ```
  What matters to them right now (their own words):
    - This year (2026): …
  (Direction is context, not a command. … — the shared rule text)
  ```
  Because the user prompt is client-built, this works on the live project
  **before any functions deploy**.
- Server (`functions/src/coach_prompts.ts` `BASE_PROMPT`): add a `## Their
  direction` section after `## Memory grounding` with the rule text, and a
  step 0 in `## Planning method`: *If a direction is given, prefer items that
  move it when choosing what to suggest — quietly.* Ships on the next
  `firebase deploy --only functions` (a deploy is already pending for
  reminders/stakes). Until then the inline rule carries it; the RC key
  `ai_system_prompts` can also hot-patch it.

### 8.2 Insight phrasing

- `CoachingAiPayload`: new `final List<String> direction;` (default empty).
  Populate at the single construction site in `lib/features/analytics/application/`
  from the direction repository (read once, no stream).
- `CoachingAiClient._buildUserPrompt`: add
  `- What the user says matters right now: <lines joined by ' · '>` (only when
  non-empty).
- `_buildSystemPrompt`: add `DIRECTION RULE: Connect the recommendation to
  their stated direction only when it honestly fits; never invent a link;
  never judge.` + the shared rule text.
- Bump `kCoachingAiPromptVersion` to `v1.1.0`.
- The deterministic fallback renderer is untouched (it never sees direction).
- `AiResponseValidator` untouched.

### 8.3 Thinking Loop

- `ThinkingLoopService._reflectIfDue`: fetch `directions` alongside facts /
  people / intentions. Keep the existing empty-gate (`facts.isEmpty &&
  people.isEmpty && intentions.isEmpty`) — a direction with nothing to
  connect it to is not worth a call.
- `reflection_payload.dart`:
  - `buildReflectionSnapshot(..., directions)` → `'direction': [{id, horizon,
    period, text}]` for current-period non-empty entries only.
  - `reflectionInputsHash(..., directions)` → add `'d:${id}:${updatedAtMs}'`
    parts, so editing Direction re-arms the loop.
  - `reflectionKnownIds(..., directions)` → direction ids join the `basedOn`
    grounding universe, so an observation may cite the direction entry.
- `_kReflectionSystemPrompt` (client-owned; `reflect` is a system-class purpose
  the server does not override): add
  ```
  snapshot.direction is what the user says matters this year/quarter/month.
  It is context, not a task. You may make ONE gentle observation connecting
  the facts/intentions to it when the link is real (e.g. a promise that
  serves the month's focus keeps getting pushed). Never judge or preach. Never
  propose a dormantIntention just to "work on" the direction.
  ```
- Output rides the existing single `InsightType.reflectionObservation` →
  "On your radar" row, labeled INFERRED, zero notifications. No new insight
  type, no new surface.

---

## 9. Non-goals (V1)

- No Time tracking, no hours-per-category, no planned-minutes proxy.
- No monthly "here's what your month looked like" reflection (lands with Time).
- No history UI, no timeline, no edit of past periods.
- No deadlines, progress, percentages, priorities, subtasks, complete button.
- No goal ↔ direction linking, no task ↔ direction linking.
- No onboarding step, no seeding from interest tags.
- No notifications of any kind, no badges, no Home permanent widget.
- No quarter/year rollover prompts.
- No Coach tool to write Direction (the Coach reads it; the user writes it).
  *(Revisit only if Miko asks — the propose→confirm contract would apply.)*
- No Pro gating.

---

## 10. Phases and definition of done

> **Implementation notes (2026-09-11):** all five phases landed in one
> session. Deviations from the plan below: (a) the LWW merge helper lives in
> `lib/features/direction/data/direction_lww_merge.dart` (unit-testable
> without Firestore) and `RemoteIsarMerge._pullDirections` calls it;
> (b) `DirectionScreen` caches the repository and slots in state because a
> `ConsumerState`'s `ref` is invalid inside `dispose()`/after an await —
> the save-on-leave path needs both; (c) the month card's controller
> seeds the handled key itself on first load, so no provider side effects;
> (d) `directionClockProvider` + `newMonthPromptControllerProvider` are
> also invalidated in `invalidateUserScopedProviders`.

Each phase: `flutter analyze` clean, full `flutter test` green, works in
airplane mode, decision-log entry appended, only Direction files staged.

### D1 — Data + sync (no UI)
Files: `domain/direction_periods.dart`, `domain/models/direction_entry.dart`,
`domain/direction_context_lines.dart`, `isar_direction_entry.dart` (+ `.g.dart`,
`isar_schemas.dart`), `firestore_paths.dart`, `data/direction_repository.dart`,
`application/direction_providers.dart`, `remote_isar_merge.dart`,
`auth_session_policy.dart` (prefs key constant referenced from the feature).
Tests: periods; entry validate/round-trip; repository with
`test/support/isar_test_harness` (upsert → watch emits; same text → no
`updatedAtMs` bump; deterministic id collides correctly); merge LWW (older
remote ignored, newer applied); context-lines builder (current period only — a
previous period must never leak in); architecture guard passes.
Done when: an entry written on device A appears on device B after a pull,
and a clear on A beats a stale edit on B.

### D2 — Page + entry points
Files: `presentation/direction_screen.dart`, `presentation/direction_strip.dart`,
`app.dart` route, `profile_screen.dart` row, `goals_home_screen.dart` strip,
`feature_guides.dart` entry.
Tests: autosave widget test (§6.2); suggestion row appears/disappears; Keep
writes; strip fallback order month → quarter → year → "Set your direction".
Done when: type → back → reopen shows the text, with the phone in airplane
mode; the amber line never appears for this flow.

### D3 — New-month card
Files: `presentation/new_month_direction_card.dart`,
`application/new_month_prompt.dart` (pure visibility function + prefs key),
`home_screen.dart` mount, `app_lifecycle_task_refresh.dart` clock stamps,
`auth_session_policy.dart` prefs removal.
Tests: visibility function table (fresh install → hidden + seeded; new month +
empty → shown; filled → hidden; dismissed → hidden; next month → shown again);
account-switch removes the key.
Done when: setting the device date to the 1st shows the card once and
dismissing it keeps it gone.

### D4 — AI consumers
Files: `ai_operating_layer_payload.dart`, `ai_payload_assembler.dart`,
`ai_operating_layer_client.dart`, `coaching_ai_payload.dart`,
`coaching_ai_client.dart` (+ version bump), the analytics payload construction
site, `reflection_payload.dart`, `thinking_loop_service.dart`,
`functions/src/coach_prompts.ts`.
Tests: payload `toJson` includes `direction`; `_buildUserPrompt` renders the
block in the right position and omits it when empty (extend the existing
client prompt tests); `reflectionInputsHash` changes when a direction's
`updatedAtMs` changes and not when only `now` changes; snapshot includes only
current-period non-empty entries; `coach_prompts.test.ts` asserts the new
section exists.
Done when: asking the Coach "what should I work on?" with a month direction
set produces a reply that reflects it without quoting it verbatim (manual
check, one transcript pasted into the decision log).

### D5 — Docs + deploy note
`documentation/GUIDELINES.md` decision log (the §0 table, condensed),
`CODEBASE_GUIDE.md` persistence table row, `documentation/errors.md` only if
something bit. Note in the pending-deploy list that `coach_prompts.ts` changed.

---

## 11. Bug traps (read before each phase)

1. **`updatedAtMs` churn from autosave.** Every save bumps LWW and enqueues an
   outbox op. The repo's *no-op on unchanged text* + the 700 ms debounce are
   load-bearing. Test both.
2. **Stream re-populating a focused field.** Isar watchers fire on every
   write, including the user's own. Guard: only push stream values into an
   unfocused controller, and only when the text actually differs.
3. **Deterministic id must be the Firestore doc id.** `_docFieldId(doc, m)`
   in the merge reads `m['id']` falling back to `doc.id` — keep `id` in
   `toMap()` and pass it as the document path segment. Never let two ids for
   one period exist.
4. **Local calendar, never UTC.** A user at UTC−7 on Sep 30 22:00 is still in
   September. Use `DateTime.now()` (local) and `DateTime(y, m, 1)`.
5. **`previous()` across year boundaries.** Jan/Q1/year edges — unit-tested.
6. **Prefs key without a wipe entry** leaks the card state across accounts.
   Add it to `clearLocalSession` in the same commit that introduces it.
7. **Thinking Loop hash** — forgetting `directions` in `reflectionInputsHash`
   means edits never re-arm the loop; including day-relative values means it
   re-arms every midnight. Hash `id:updatedAtMs` only.
8. **Server prompt drop.** For chat purposes the server discards client
   `system` messages. Direction *data* goes in the **user** prompt (survives),
   the *rule* goes in both the user block (works today) and `coach_prompts.ts`
   (works after deploy).
9. **Isar codegen.** New collection → `build_runner` → commit the `.g.dart`.
   A release build with a stale `.g.dart` white-screens at `Isar.openSync`.
10. **No Firestore `orderBy`.** The pull uses `where('updatedAtMs', >)` only,
    like every other phase; sort client-side (errors.md #16/#18).
11. **Do not touch `ScheduleMutationCoordinator`, `UnifiedRecomputeGraph`, or
    reminders.** Direction has no schedule side effects; adding it there
    invites recompute storms.
12. **Parallel session.** `git add` only Direction paths; check `git status`
    before every commit; never `git add -A`.

---

## 12. Open questions — resolved (Miko, 2026-09-11)

| Question | Decision |
|---|---|
| Goals strip when empty | Show the quiet `Set your direction →` line. Not a card, not a notification, not an explanation. Once set it reads `This month: Launch SidePal`. |
| Previous period as AI context | **Never.** History ≠ current direction. Suggestion on the page only. |
| Month rollover copy | `What's your focus for September?`; on Jan 1 simply `…for January?`. No new-year variant, no competing cards. |
| Notifications | None. Direction is silent context, never a nudge source. |
