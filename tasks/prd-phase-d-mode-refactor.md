# PRD: Phase D — Mode Refactor

## 1. Introduction / Overview

`RoutineMode` (flexible / disciplined / extreme) currently conflates two
distinct concerns into one enum:

1. **Coaching philosophy** — how the app communicates, frames accountability,
   and decides when to back off vs. push harder (global, per-user).
2. **Enforcement intensity** — how aggressively a specific task or habit is
   tracked, escalated, and penalized for missed completion (per-entity).

This conflation creates several problems:
- The AI can't use mode to shape tone independently of reminder pressure.
- A user who wants "intense" coaching can't set "flexible" enforcement on a
  specific low-stakes habit.
- "Extreme mode" currently maps directly to notification count, not behavioral
  depth.
- Changing one concern requires changing both.

Phase D cleanly separates these into:
- **`CoachingStyle`** — global, user-level, controls AI tone + accountability
  framing + persistence philosophy
- **`EnforcementMode`** — per-entity, controls escalation intensity, streak
  sensitivity, recovery tolerance, and urgency weighting

`RoutineMode` is deprecated gradually using dual-write + compatibility adapters.
No hard replacement — all existing consumers continue to work.

---

## 2. Goals

1. Define `CoachingStyle` as a stable global enum with documented behavioral
   contracts across AI, delivery, and accountability framing.
2. Define `EnforcementMode` as a stable per-entity enum that formalizes what
   "extreme" actually means beyond notification count.
3. Wire `CoachingStyle` into the AI summarization pipeline
   (`CoachingFraming` derivation) and `AttentionOrchestrator` persistence
   philosophy.
4. Wire `EnforcementMode` into focus scoring urgency weights and escalation
   timing.
5. Deprecate `RoutineMode` gradually with dual-write and adapters — zero
   breaking changes.
6. Allow users to change `CoachingStyle` at any time from settings (initial
   selection at onboarding).

---

## 3. User Stories

- As a user, I want to choose "supportive" coaching so the app encourages me
  without making me feel guilty when I miss something.
- As a user in "intense" coaching style, I want the app to push back harder
  and not let me off easy — but I still want one specific habit to have flexible
  enforcement because it's experimental.
- As a user who has grown over time, I want to upgrade my coaching style from
  "supportive" to "disciplined" without re-doing onboarding.
- As a developer, I want the AI tone, delivery pressure, and insight framing to
  all derive from a single source of truth (`CoachingStyle`) so they stay
  consistent.

---

## 4. Functional Requirements

### 4.1 CoachingStyle enum

**FR-D-01** — Define a `CoachingStyle` enum:

```dart
enum CoachingStyle {
  supportive,
  balanced,
  disciplined,
  intense,
}
```

**FR-D-02** — `CoachingStyle` is a **global, user-level** setting. There is
one value per user, not per entity.

**FR-D-03** — `CoachingStyle` controls three behavioral dimensions:

| Dimension | Supportive | Balanced | Disciplined | Intense |
|-----------|-----------|----------|-------------|---------|
| **AI tone** | Warm, empathetic | Neutral, friendly | Direct, clear | Assertive, high-standards |
| **Accountability framing** | "You're doing great, here's a gentle nudge" | "Here's what's happening and what to do" | "You committed to this — act on it" | "No excuses — you said this matters" |
| **Persistence philosophy** | Backs off after 1–2 ignored reminders | Standard escalation | Full escalation before backing off | Maximum escalation, backs off only at sleep/DND |

**FR-D-04** — `CoachingStyle` must be persisted in a new `UserCoachingProfile`
model (see FR-D-08).

### 4.2 EnforcementMode enum

**FR-D-05** — Define an `EnforcementMode` enum (replaces `RoutineMode` for
per-entity use):

```dart
enum EnforcementMode {
  flexible,
  disciplined,
  extreme,
}
```

**FR-D-06** — `EnforcementMode` is a **per-entity** setting on each task and
habit. It controls four behavioral contracts:

| Contract | Flexible | Disciplined | Extreme |
|----------|---------|-------------|---------|
| **Escalation speed** | Slow — long snooze intervals | Medium — moderate decay | Fast — snooze decays quickly |
| **Streak sensitivity** | Misses are forgiven more often | Standard streak logic | Streak breaks on first miss, no grace period |
| **Recovery tolerance** | High — gap before re-escalating | Medium | Low — follows up immediately after recovery |
| **Urgency weight in FocusScoringEngine** | ×0.8 multiplier on urgencyScore | ×1.0 (baseline) | ×1.3 multiplier on urgencyScore |

**FR-D-07** — `EnforcementMode` for an entity is stored on the entity's
`ReminderConfig.modeRefId` field (already exists), which currently accepts
`"flexible"`, `"disciplined"`, or `"extreme"` strings. Phase D formalizes the
enum but does not change the storage format.

### 4.3 UserCoachingProfile model

**FR-D-08** — Define a `UserCoachingProfile` model:

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Fixed ID `"user_coaching_profile"` — single record |
| `coachingStyle` | `CoachingStyle` | Active coaching style |
| `lastChangedAtMs` | `int` | Epoch ms when style was last changed |
| `onboardingCompletedAtMs` | `int?` | Epoch ms when onboarding style was set |
| `styleChangeHistory` | `List<StyleChangeEntry>` | Log of past style changes (max 10) |
| `updatedAtMs` | `int` | Epoch ms |
| `schemaVersion` | `int` | Schema version (starts at 1) |

**FR-D-09** — `StyleChangeEntry` contains:
- `previousStyle: CoachingStyle`
- `newStyle: CoachingStyle`
- `changedAtMs: int`

**FR-D-10** — `UserCoachingProfile` is persisted in Isar (single record,
upsert pattern). No Firestore sync in Phase D.

### 4.4 CoachingStyleRepository

**FR-D-11** — Implement `CoachingStyleRepository` backed by Isar:
- `getProfile() → Future<UserCoachingProfile?>`
- `upsertProfile(UserCoachingProfile profile)`
- `watchProfile() → Stream<UserCoachingProfile?>` for reactive UI

### 4.5 CoachingStyle → AI pipeline integration

**FR-D-12** — The `CoachingFraming` derivation logic (currently in
`coaching_ai_payload.dart`) must be updated to incorporate `CoachingStyle`.

Current derivation: `FocusReason → CoachingFraming`

Updated derivation: `FocusReason × CoachingStyle → CoachingFraming`

The mapping rules:

| FocusReason | Supportive | Balanced | Disciplined | Intense |
|-------------|-----------|----------|-------------|---------|
| `imminentStreakRisk` | `recovery` | `protection` | `protection` | `protection` |
| `highestMomentumLeverage` | `momentum` | `momentum` | `momentum` | `momentum` |
| `bestRecoveryOpportunity` | `recovery` | `recovery` | `recovery` | `stabilization` |
| `goalDriftDetected` | `recovery` | `stabilization` | `stabilization` | `protection` |
| `consistencyBreakdownAlert` | `stabilization` | `stabilization` | `protection` | `protection` |
| All others | (existing logic unchanged) | | | |

**FR-D-13** — `CoachingAiPayload` must include `coachingStyle` as a field so
the AI system prompt can adapt accountability language accordingly.

**FR-D-14** — The AI system prompt must include a style instruction block:

| CoachingStyle | Instruction |
|--------------|------------|
| `supportive` | "Be warm and encouraging. Avoid guilt framing. Focus on small wins." |
| `balanced` | "Be clear and friendly. Present facts and suggest action without pressure." |
| `disciplined` | "Be direct. The user values accountability. State what's expected clearly." |
| `intense` | "Be assertive. The user has high standards for themselves. Don't soften the message." |

### 4.6 CoachingStyle → AttentionOrchestrator persistence philosophy

**FR-D-15** — `AttentionOrchestrator` must read `CoachingStyle` from
`UserCoachingProfile` and apply the following persistence philosophy rules:

| CoachingStyle | Back-off trigger | Effect |
|--------------|-----------------|--------|
| `supportive` | 2 ignored notifications in a row | Suppress follow-ups for 4h, log `reminderSuppressed` |
| `balanced` | Standard escalation (Phase C rules) | No change |
| `disciplined` | Full escalation reached | Continue at tail frequency until resolved |
| `intense` | Only sleep/DND override | Never backs off voluntarily; only context suppression |

**FR-D-16** — The back-off logic must be implemented as
`CoachingStyleDeliveryPolicy.shouldBackOff(CoachingStyle style, int
consecutiveIgnoredCount)` — a pure static function, fully unit-testable.

### 4.7 EnforcementMode → FocusScoringEngine urgency weighting

**FR-D-17** — `FocusScoringEngine` must apply an `EnforcementMode` multiplier
to `urgencyScore` when scoring a `FocusCandidate`:

```
adjustedUrgency = urgencyScore × enforcementUrgencyMultiplier(mode)

where:
  flexible    → ×0.8
  disciplined → ×1.0
  extreme     → ×1.3
```

**FR-D-18** — `enforcementUrgencyMultiplier()` must be a pure static function
in a new `EnforcementModePolicy` class.

### 4.8 EnforcementMode → streak sensitivity

**FR-D-19** — The streak calculation logic must respect `EnforcementMode` when
determining whether a missed day breaks a streak:

| EnforcementMode | Grace period |
|----------------|-------------|
| `flexible` | 1 missed day grace before streak breaks |
| `disciplined` | No grace — streak breaks on first miss (current behavior) |
| `extreme` | No grace + no partial credit for late completions (only on-time counts) |

**FR-D-20** — This requires `EnforcementMode` to be passed into the streak
computation path. The entity's `modeRefId` on `ReminderConfig` is the source.

### 4.9 RoutineMode deprecation

**FR-D-21** — `RoutineMode` must NOT be removed in Phase D. It is marked
`@Deprecated` with a migration message:
```dart
@Deprecated('Use CoachingStyle (global) or EnforcementMode (per-entity). '
            'RoutineMode will be removed in a future release.')
enum RoutineMode { flexible, disciplined, extreme }
```

**FR-D-22** — A `RoutineModeAdapter` must be provided for backward
compatibility:
- `EnforcementMode fromRoutineMode(RoutineMode mode)` — maps 1:1
- `CoachingStyle defaultStyleForMode(RoutineMode mode)` — maps:
  - `flexible → supportive`
  - `disciplined → disciplined`
  - `extreme → intense`

**FR-D-23** — All new code must use `CoachingStyle` and `EnforcementMode`.
Existing consumers of `RoutineMode` continue to work via `RoutineModeAdapter`
until they are individually migrated.

**FR-D-24** — `AdaptiveReminderPolicy.cadenceFor()` currently accepts
`modeRefId: String?`. It must be updated to also accept
`EnforcementMode? enforcementMode` as an alternative parameter. If
`enforcementMode` is provided it takes precedence; otherwise it falls back to
parsing `modeRefId` as before.

### 4.10 UI — CoachingStyle selection

**FR-D-25** — During onboarding, the user must be presented with a
`CoachingStyle` selection screen showing all 4 options with:
- Name
- One-sentence description
- Example of how it frames a missed workout

**FR-D-26** — In Settings, a "Coaching Style" section must allow the user to
change their `CoachingStyle` at any time. When changed:
- `UserCoachingProfile` is updated with the new style
- A `StyleChangeEntry` is appended to `styleChangeHistory`
- A confirmation message is shown: "Your coaching style has been updated. The
  AI and reminders will adapt from now on."

**FR-D-27** — EnforcementMode must be selectable per entity on the task/habit
edit screen, replacing any existing "mode" toggle. The UI labels:
- `flexible` → "Flexible" — "Reminders are gentle. Missing a day is okay."
- `disciplined` → "Disciplined" — "Hold me accountable. Streaks matter."
- `extreme` → "Extreme" — "No excuses. Follow up until I act."

---

## 5. Non-Goals (Out of Scope for Phase D)

- **No removal of `RoutineMode`** — deprecated only, not deleted.
- **No Firestore sync** of `UserCoachingProfile`.
- **No per-entity CoachingStyle** — style is always global.
- **No ML-driven style suggestions** — user sets it manually.
- **No changes to the notification scheduling or orchestration engine** —
  that is Phase C. Phase D only adds policy inputs to existing systems.
- **No redesign of the onboarding flow** beyond adding the style selection
  screen.

---

## 6. Design Considerations

- The CoachingStyle selection screen should feel like a values/identity choice,
  not a settings toggle. Use descriptive language and examples rather than
  technical labels.
- The per-entity EnforcementMode UI should be compact — a 3-option segmented
  control or radio group on the edit screen, not a full page.
- When the user upgrades from `supportive` to `intense`, consider a brief
  confirmation: "This will make reminders more persistent and coaching more
  direct. You can change this anytime."
- `styleChangeHistory` (max 10 entries) can power a future "your coaching
  journey" feature showing how the user's preferences have evolved.

---

## 7. Technical Considerations

- `UserCoachingProfile` needs an Isar collection schema
  (`isar_user_coaching_profile.dart`). Single-record pattern (fixed ID).
- `isar_schemas.dart` must be updated to include
  `IsarUserCoachingProfileSchema`.
- `CoachingStyleDeliveryPolicy` and `EnforcementModePolicy` are pure Dart
  static classes — no constructor, no state, fully unit-testable.
- `FocusScoringEngine` receives `EnforcementMode` via `FocusCandidate` — the
  candidate model needs an `enforcementMode` field added.
- `CoachingAiPayload` needs a `coachingStyle` field (String, stored as
  `coachingStyle.name`) and `promptVersion` must be incremented to `v1.1.0`
  when the style instruction block is added to the prompt.
- The `CoachingFraming` derivation function signature changes from
  `deriveCoachingFraming({FocusReason, double, double})` to
  `deriveCoachingFraming({FocusReason, double, double, CoachingStyle})`.
  Default `CoachingStyle.balanced` preserves existing behavior for callers
  not yet updated.
- Streak grace period logic needs `EnforcementMode` passed in. The
  `modeRefId` string on `ReminderConfig` is the current source — parse it
  via `EnforcementMode.fromModeRefId(String?)` helper.

---

## 8. Success Metrics

- `CoachingStyle` is stored and retrieved correctly across app restarts.
- AI prompt includes correct style instruction block for all 4 styles.
- `CoachingFraming` derivation produces correct framing for all
  `FocusReason × CoachingStyle` combinations (unit tests: 10 reasons × 4
  styles = 40 cases).
- `FocusScoringEngine` applies correct urgency multiplier for all 3
  `EnforcementMode` values.
- Streak grace period respected for `flexible` mode (1-day grace), not
  applied for `disciplined`/`extreme`.
- All existing `RoutineMode` consumers continue to compile and behave
  correctly via `RoutineModeAdapter`.
- `CoachingStyleDeliveryPolicy.shouldBackOff()` unit tests cover all 4 styles
  × multiple consecutive-ignore counts.

---

## 9. Open Questions

- Should `CoachingStyle` be synced to Firestore eventually so it persists
  across device reinstalls? (Recommendation: yes, in a future phase — add it
  to the user profile document.)
- When `CoachingStyle` changes, should in-flight AI summaries be invalidated
  and regenerated? (Recommendation: yes — invalidate
  `recomputeAiSummaryProvider` on style change so the next home screen render
  reflects the new tone.)
- Should the `styleChangeHistory` be visible to the user in settings, or is it
  internal only? (Recommendation: keep it internal for Phase D; expose as a
  "coaching journey" card in a future UX pass.)
- Should `EnforcementMode.extreme` on a specific entity be able to override a
  `supportive` `CoachingStyle` for delivery persistence? (Recommendation: yes
  — entity-level extreme enforcement always escalates fully regardless of
  global style, but the AI tone still follows the global style.)
