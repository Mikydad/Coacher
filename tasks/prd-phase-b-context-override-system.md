# PRD: Phase B — Context Override System

## 1. Introduction / Overview

Currently, the app has no awareness of what the user is doing outside of it.
Reminders fire regardless of whether the user is in a meeting, sleeping, deep
in focused work, or on vacation. This creates noise, erodes trust, and makes
"extreme mode" feel like spam rather than coaching.

Phase B builds the **context override system** — a data layer + UI layer that
lets the user communicate their current attention state to the app. When an
override is active, the app knows not to interrupt. When it expires, the app
surfaces a recovery review so the user can decide what to do with anything that
was suppressed — without the app making those decisions on their behalf.

Phase B builds the model, repository, UI controls, and the
`OverrideAttentionPolicy` abstraction. It does **not** wire suppression into
notification delivery yet — that happens in Phase C when `AttentionOrchestrator`
is introduced. Phase B is the foundation Phase C depends on.

---

## 2. Goals

1. Define a stable `UserAttentionState` model that captures which override is
   active, when it expires, and whether recurring sleep windows apply.
2. Provide override-specific attention policies so different overrides suppress
   different interruption levels.
3. Persist override state locally in Isar (local-first, no Firestore sync).
4. Give the user quick-activate controls from the home screen and full management
   in settings.
5. Show a persistent visible indicator whenever an override is active.
6. Support auto-expiry with a post-override recovery review rather than blind
   catch-up replay.
7. Protect streak integrity during vacation: missed days do not break streaks.

---

## 3. User Stories

- As a user entering a meeting, I want to quickly activate meeting mode so the
  app stops sending reminders for the next hour without me having to mute my
  phone entirely.
- As a user on vacation, I want all reminders suppressed and my streaks protected
  so I come back to a motivating state, not a broken one.
- As a user who just woke up, I want the app to show me what it held back
  overnight so I can decide what to reschedule, start now, or skip.
- As a user in focus mode, I want low-priority nudges suppressed but high-urgency
  ones (like an imminent streak break) to still reach me.
- As a user, I want to always know at a glance whether an override is currently
  active and how long it has left.

---

## 4. Functional Requirements

### 4.1 ContextOverride enum

**FR-B-01** — The system must define a `ContextOverride` enum:

```dart
enum ContextOverride {
  none,
  meeting,
  focus,
  sleep,
  vacation,
  doNotDisturb,
}
```

### 4.2 OverrideAttentionPolicy

**FR-B-02** — Each override type must have an associated `OverrideAttentionPolicy`
that defines which interruption levels are suppressed. This must be implemented
as a pure Dart abstraction (no I/O), not a single global flag.

**FR-B-03** — Define an `InterruptionLevel` enum used to classify notifications:

```dart
enum InterruptionLevel {
  low,      // Coaching tips, soft suggestions
  medium,   // Standard reminders
  high,     // Urgent reminders (imminent streak risk, overdue critical)
  critical, // Emergency bypass (extreme mode at max escalation)
}
```

**FR-B-04** — Suppression behavior per override type:

| Override | Suppresses | Allows |
|----------|-----------|--------|
| `meeting` | `low`, `medium` | `high`, `critical` |
| `focus` | `low`, `medium` | `high`, `critical` |
| `sleep` | `low`, `medium`, `high` | `critical` only |
| `vacation` | `low`, `medium`, `high` | `critical` only |
| `doNotDisturb` | `low`, `medium`, `high`, `critical` | nothing |
| `none` | nothing | everything |

**FR-B-05** — `OverrideAttentionPolicy.shouldSuppress(InterruptionLevel level,
ContextOverride override)` must be a static pure function — same input always
produces the same output.

**FR-B-06** — Suppression applies to **notification delivery only**, not to
behavioral computation. The insight engine, pattern detection, and focus engine
continue to run on their normal schedule regardless of override state. Coaching
insights may update silently in-app even when notifications are suppressed.

### 4.3 UserAttentionState model

**FR-B-07** — Define a `UserAttentionState` model:

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Fixed ID (`"user_attention_state"`) — single record |
| `activeOverride` | `ContextOverride` | Currently active override (`none` if inactive) |
| `overrideExpiresAt` | `DateTime?` | When the override auto-expires (null = manual end) |
| `manuallyMuted` | `bool` | User explicitly muted all non-critical notifications |
| `lastOverrideActivatedAt` | `int?` | Epoch ms when current override started |
| `lastAttentionResetAt` | `int?` | Epoch ms when last override ended or expired |
| `sleepWindowStart` | `String?` | Daily sleep window start time (`"HH:mm"` local) |
| `sleepWindowEnd` | `String?` | Daily sleep window end time (`"HH:mm"` local) |
| `updatedAtMs` | `int` | Epoch ms |
| `schemaVersion` | `int` | Schema version (starts at 1) |

**FR-B-08** — There is exactly **one** `UserAttentionState` record per device.
It is upserted (never duplicated).

### 4.4 ContextOverrideRepository

**FR-B-09** — Implement `ContextOverrideRepository` backed by Isar with the
following operations:

- `getAttentionState()` → `UserAttentionState?`
- `upsertAttentionState(UserAttentionState state)` → saves the single record
- `watchAttentionState()` → `Stream<UserAttentionState?>` for reactive UI updates

No Firestore sync in this phase.

### 4.5 Override activation

**FR-B-10** — When the user activates an override, the system must:
1. Set `activeOverride` to the selected type
2. Set `overrideExpiresAt` based on the chosen preset or custom duration
3. Record `lastOverrideActivatedAt`
4. Persist to Isar via `ContextOverrideRepository`

**FR-B-11** — Preset duration options per override type:

| Override | Preset options |
|----------|---------------|
| `meeting` | 30 min, 1h, 2h, Until I end it |
| `focus` | 45 min, 90 min, 2h, Custom, Until I end it |
| `sleep` | Uses scheduled daily window (see FR-B-18), or Until I end it |
| `vacation` | Until I end it (no preset duration) |
| `doNotDisturb` | 30 min, 1h, 2h, Until I end it |

**FR-B-12** — "Custom" duration (focus mode) must allow the user to input
minutes via a numeric field or a slider, with a minimum of 15 minutes and a
maximum of 12 hours.

### 4.6 Auto-expiry

**FR-B-13** — When `overrideExpiresAt` is set and the current time passes it,
the system must automatically transition `activeOverride` to `none` and record
`lastAttentionResetAt`.

**FR-B-14** — Auto-expiry must be checked:
- When the app comes to foreground (app lifecycle resume)
- When `watchAttentionState()` emits an update
- Via a lightweight periodic check (≥ every 5 minutes) while the app is active

**FR-B-15** — Auto-expiry must NOT blindly replay or reschedule suppressed
notifications. Instead it must trigger the **post-override recovery review**
(see FR-B-21).

**FR-B-16** — When the override is ended manually (user taps "End now"), the
same expiry flow runs: `activeOverride → none`, `lastAttentionResetAt` recorded,
recovery review triggered.

### 4.7 Vacation mode — streak protection

**FR-B-17** — When `activeOverride == vacation`:
- Missed habit/task days do **not** break streaks
- The user can still complete habits and grow streaks voluntarily
- The streak counter is simply not decremented for missed days during vacation
- This requires the streak calculation logic to check `UserAttentionState` and
  skip penalty application for dates that fall within the vacation window

### 4.8 Recurring sleep window

**FR-B-18** — The user may configure a daily sleep window in settings:
- A single start time (e.g. `"23:00"`) and end time (e.g. `"07:00"`)
- Stored as `sleepWindowStart` and `sleepWindowEnd` on `UserAttentionState`
- When the current local time falls within this window, the system treats it
  as if `sleep` override is active, even if `activeOverride == none`
- The sleep window check is evaluated at the same points as auto-expiry (FR-B-14)
- The user can disable the sleep window by clearing both fields

### 4.9 UI — Quick-activate from home screen

**FR-B-19** — The existing "I'm distracted" button (or equivalent home screen
control) must be evolved into the **attention quick-activate entry point**. When
tapped it shows a bottom sheet with the available override modes:
- Meeting
- Focus
- Sleep / Do Not Disturb
- Vacation

Each option shows its suppression level summary (e.g. "Holds standard reminders,
allows urgent alerts").

**FR-B-20** — After selecting an override type, a second screen or expanded
section shows the duration presets (FR-B-11) and a confirm button. The user can
also tap "Until I end it" to activate indefinitely.

### 4.10 Post-override recovery review

**FR-B-21** — When an override ends (by expiry or manual end), the system must
generate a `PostOverrideReview`:

| Field | Type | Description |
|-------|------|-------------|
| `overrideType` | `ContextOverride` | Which override just ended |
| `activeFromMs` | `int` | When it started |
| `activeUntilMs` | `int` | When it ended |
| `suppressedItems` | `List<SuppressedItem>` | Items held back during the window |

Where `SuppressedItem` contains:
- `entityId`, `entityKind`, `entityTitle`
- `originalScheduledAt` (when it was due)
- `suggestedAction` — one of: `startNow`, `reschedule`, `shorten`, `skipIntentionally`, `dismiss`

**FR-B-22** — The recovery review must be surfaced as a **dismissible card** on
the home screen (not a forced modal). The card shows:
- "While you were in [override type], [N] items were held back"
- A list of suppressed items with their suggested action chips
- The user taps an action chip to act on each item
- The card can be dismissed entirely (all items marked as `dismiss`)

**FR-B-23** — The system must NOT automatically execute any suggested actions.
Every schedule mutation must be authorized by the user tapping an action chip.

**FR-B-24** — The recovery review card must disappear once all items have been
actioned or the card is dismissed.

### 4.11 Active override indicator

**FR-B-25** — When an override is active (`activeOverride != none` or sleep
window is active), a persistent visual indicator must be shown on the home screen:
- A banner or status chip at the top of the home screen
- Shows the override type icon + name + remaining time (if time-limited)
- Tapping it opens the full override management screen

**FR-B-26** — The indicator must update in real time as `overrideExpiresAt`
counts down (refresh ≥ every 60 seconds while visible).

### 4.12 Full management in settings

**FR-B-27** — A dedicated section in Settings must provide:
- Current active override status (or "No active override")
- Quick end button if an override is active
- Sleep window configuration (start time, end time, enable/disable toggle)
- History of recent overrides (last 7 days) — override type, duration, items
  suppressed count

---

## 5. Non-Goals (Out of Scope for Phase B)

- **No actual notification suppression** — `OverrideAttentionPolicy` is built
  but not wired into `ReminderSyncService`. That is Phase C.
- **No Firestore sync** of `UserAttentionState`.
- **No calendar integration** — no auto-detection of calendar events.
- **No per-day sleep window** configuration (weekday vs weekend) — single daily
  window only.
- **No AI-driven override suggestions** — context is always user-initiated.
- **No automatic schedule mutations** on override expiry — user authorizes all.

---

## 6. Design Considerations

- The quick-activate bottom sheet should be fast: 2 taps max to activate an
  override (select type → select duration → done).
- Override type icons should be distinct and recognizable: e.g. 📅 meeting,
  🎯 focus, 🌙 sleep, 🏖 vacation, 🔕 DND.
- The suppression summary per override type ("holds standard reminders, allows
  urgent alerts") is critical UX — users need to know what still gets through.
- The home screen indicator must not be alarming or guilt-inducing. It should
  feel like a status badge, not a warning.
- The recovery review card should feel helpful, not overwhelming. Max 5 items
  shown initially with a "show more" if there are more.

---

## 7. Technical Considerations

- `UserAttentionState` needs an Isar collection schema
  (`isar_user_attention_state.dart`). Single-record pattern (fixed ID).
- `OverrideAttentionPolicy` is a pure Dart static class — no constructor, no
  state. Unit-testable with zero setup.
- `ContextOverrideRepository` follows the abstract + Isar implementation pattern
  used elsewhere (`FocusRepository`, `TimeBlockRepository`, etc.).
- The sleep window evaluation logic should live in a small utility function
  `isWithinSleepWindow(DateTime now, String? windowStart, String? windowEnd)`
  that parses `HH:mm` strings and handles midnight crossover (e.g. 23:00–07:00).
- Auto-expiry checking on app foreground should hook into the existing
  `AppLifecycleTaskRefresh` mechanism or equivalent lifecycle observer.
- `PostOverrideReview` does not need Isar persistence in Phase B — it can be
  computed in memory from the suppressed item list and held in Riverpod state.
  In Phase C, suppressed items will be tracked by `AttentionOrchestrator`.
  For Phase B, the review may be a stub or populated from a simple in-memory
  list accumulated during the override window.
- `isar_schemas.dart` must be updated to include `IsarUserAttentionStateSchema`.

---

## 8. Success Metrics

- Override activates and persists correctly across app restarts.
- Auto-expiry fires within 5 minutes of `overrideExpiresAt` passing.
- Sleep window evaluated correctly including midnight crossover.
- Recovery review card appears on home screen after every override expiry.
- Streak penalty correctly skipped for missed days during vacation.
- `OverrideAttentionPolicy.shouldSuppress()` unit tests cover all 6 override
  types × 4 interruption levels (24 cases).

---

## 9. Open Questions

- Should the recovery review card persist if the app is killed and relaunched?
  (Recommendation: yes — store a flag in SharedPreferences or Isar indicating
  a pending review so it survives restarts.)
- Should vacation mode have a scheduled end date (e.g. "back on [date]") so
  streak protection auto-ends, or always manual? (Recommendation: optional date
  picker on vacation activate, but always overridable manually.)
- When sleep window overlaps with an active manual override (e.g. user activated
  DND and sleep window also starts), which one takes precedence? (Recommendation:
  the stricter policy wins — in this case DND, since it suppresses everything.)
