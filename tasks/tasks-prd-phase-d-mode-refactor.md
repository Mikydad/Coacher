# Tasks: Phase D — Mode Refactor

PRD reference: `tasks/prd-phase-d-mode-refactor.md`

---

## Group 1.0 — Core enums + adapter

- [ ] 1.1 Create `CoachingStyle` enum in `lib/features/coaching/domain/models/coaching_style.dart`
  - Values: `supportive`, `balanced`, `disciplined`, `intense`
  - `fromStorage(String?)` safe parser
  - `toStorage()` serializer
  - `displayName` getter (user-facing label)
  - `description` getter (one-sentence description for UI)
  - `exampleMissedWorkout` getter (example framing for selection screen)

- [ ] 1.2 Create `EnforcementMode` enum in `lib/features/coaching/domain/models/enforcement_mode.dart`
  - Values: `flexible`, `disciplined`, `extreme`
  - `fromStorage(String?)` / `fromModeRefId(String?)` safe parsers
  - `toStorage()` serializer
  - `displayName` / `description` / `uiLabel` getters (for per-entity edit screen)
  - Note: storage format matches existing `ReminderConfig.modeRefId` strings — no migration needed

- [ ] 1.3 Create `RoutineModeAdapter` in `lib/features/coaching/domain/models/routine_mode_adapter.dart`
  - `EnforcementMode fromRoutineMode(RoutineMode mode)` — 1:1 mapping
  - `CoachingStyle defaultStyleForMode(RoutineMode mode)`:
    - `flexible → supportive`
    - `disciplined → disciplined`
    - `extreme → intense`
  - Mark `RoutineMode` as `@Deprecated` with migration message in `routine_mode.dart`

---

## Group 2.0 — UserCoachingProfile model + persistence

- [ ] 2.1 Create `StyleChangeEntry` model in `lib/features/coaching/domain/models/user_coaching_profile.dart`
  - Fields: `previousStyle`, `newStyle`, `changedAtMs`
  - `toMap()` / `fromMap()`

- [ ] 2.2 Create `UserCoachingProfile` model in same file
  - Fields: `id` (fixed `"user_coaching_profile"`), `coachingStyle`, `lastChangedAtMs`, `onboardingCompletedAtMs?`, `styleChangeHistory` (max 10), `updatedAtMs`, `schemaVersion`
  - `toMap()` / `fromMap()` / `copyWith()` / `validate()`
  - `withStyleChange(CoachingStyle newStyle)` helper — returns new profile with entry appended and history trimmed to 10

- [ ] 2.3 Create `isar_user_coaching_profile.dart` Isar collection schema
  - Single-record pattern (fixed ID `"user_coaching_profile"`)
  - `fromDomain()` / `toDomain()` converters
  - Add `IsarUserCoachingProfileSchema` to `isar_schemas.dart`

- [ ] 2.4 Create `CoachingStyleRepository` in `lib/features/coaching/data/coaching_style_repository.dart`
  - Abstract interface: `getProfile()`, `upsertProfile()`, `watchProfile()`
  - `IsarCoachingStyleRepository` implementation (single-record Isar pattern)

- [ ] 2.5 Create Riverpod providers in `lib/features/coaching/application/coaching_style_providers.dart`
  - `coachingStyleRepositoryProvider` → `Provider<CoachingStyleRepository>`
  - `coachingProfileProvider` → `StreamProvider<UserCoachingProfile?>` (watches Isar)
  - `activeCoachingStyleProvider` → `Provider<CoachingStyle>` — returns `profile?.coachingStyle ?? CoachingStyle.balanced`
  - `coachingStyleServiceProvider` → `Provider<CoachingStyleService>`

- [ ] 2.6 Create `CoachingStyleService` in `lib/features/coaching/application/coaching_style_service.dart`
  - `setStyle(CoachingStyle style)` — upserts profile with `withStyleChange()`, sets `lastChangedAtMs`
  - `setOnboardingStyle(CoachingStyle style)` — same but also sets `onboardingCompletedAtMs`
  - `getActiveStyle() → Future<CoachingStyle>` — returns persisted style or `balanced` fallback

---

## Group 3.0 — Policy classes (pure Dart)

- [ ] 3.1 Create `CoachingStyleDeliveryPolicy` in `lib/features/coaching/application/coaching_style_delivery_policy.dart`
  - Pure static class, no state
  - `shouldBackOff(CoachingStyle style, int consecutiveIgnoredCount) → bool`:
    - `supportive`: back off when `consecutiveIgnoredCount >= 2`
    - `balanced`: standard (never backs off here — Phase C handles it)
    - `disciplined`: never backs off (`false` always)
    - `intense`: never backs off (`false` always)
  - `backOffDurationMinutes(CoachingStyle style) → int`:
    - `supportive`: 240 (4h)
    - all others: 0

- [ ] 3.2 Create `EnforcementModePolicy` in `lib/features/coaching/application/enforcement_mode_policy.dart`
  - Pure static class, no state
  - `urgencyMultiplier(EnforcementMode mode) → double`:
    - `flexible`: 0.8
    - `disciplined`: 1.0
    - `extreme`: 1.3
  - `gracePeriodDays(EnforcementMode mode) → int`:
    - `flexible`: 1
    - `disciplined`: 0
    - `extreme`: 0
  - `allowsLateCompletion(EnforcementMode mode) → bool`:
    - `flexible`: true
    - `disciplined`: true
    - `extreme`: false

---

## Group 4.0 — CoachingStyle → AI pipeline

- [ ] 4.1 Add `coachingStyle: CoachingStyle` field to `CoachingAiPayload` model
  - Serialized as `coachingStyle.toStorage()`
  - Default `CoachingStyle.balanced` preserves existing behavior
  - Bump `promptVersion` to `"v1.1.0"`

- [ ] 4.2 Update `deriveCoachingFraming()` in `coaching_ai_payload.dart`
  - New signature: `deriveCoachingFraming({required FocusReason focusReason, required double urgency, required double risk, CoachingStyle style = CoachingStyle.balanced})`
  - Apply the `FocusReason × CoachingStyle` mapping table from PRD FR-D-12:
    - `imminentStreakRisk` + `supportive` → `recovery`; others → `protection`
    - `bestRecoveryOpportunity` + `intense` → `stabilization`; others → `recovery`
    - `goalDriftDetected` + `supportive` → `recovery`; `balanced/disciplined` → `stabilization`; `intense` → `protection`
    - `consistencyBreakdownAlert` + `supportive/balanced` → `stabilization`; `disciplined/intense` → `protection`
    - All other `FocusReason` values: unchanged from existing logic

- [ ] 4.3 Add style instruction block to the AI system prompt builder
  - Map `CoachingStyle → instruction string` per PRD FR-D-14
  - Append to `systemPrompt` after existing tone guidance
  - Read `coachingStyle` from `CoachingAiPayload`

- [ ] 4.4 Update caller of `deriveCoachingFraming` to pass `activeCoachingStyleProvider` value
  - Find where `CoachingAiPayload` is constructed (in the AI summarization pipeline)
  - Read `coachingStyle` from `activeCoachingStyleProvider` and pass it in

---

## Group 5.0 — EnforcementMode → FocusScoringEngine

- [ ] 5.1 Add `enforcementMode: EnforcementMode` field to `FocusCandidate` model
  - Default `EnforcementMode.disciplined` preserves existing behavior
  - Parse from `modeRefId` on the entity's `ReminderConfig` at candidate construction time

- [ ] 5.2 Update `FocusScoringEngine` to apply urgency multiplier
  - After computing raw `urgencyScore`, multiply by `EnforcementModePolicy.urgencyMultiplier(candidate.enforcementMode)`
  - Result is clamped to `[0.0, 1.0]`

- [ ] 5.3 Update `FocusCandidate` construction site(s) to resolve `EnforcementMode` from `ReminderConfig.modeRefId`
  - Use `EnforcementMode.fromModeRefId(config?.modeRefId)` — falls back to `disciplined`

---

## Group 6.0 — EnforcementMode → streak sensitivity

- [ ] 6.1 Add `EnforcementMode` parameter to `computeStreakSummary` / `computeStreakSummaryWithVacationProtection` in `streak_engine.dart`
  - Default `EnforcementMode.disciplined` preserves existing behavior

- [ ] 6.2 Apply grace period logic inside streak computation:
  - `flexible`: treat 1 missed day as if completed (grace period = 1 day)
  - `disciplined`: current behavior (no grace)
  - `extreme`: no grace + only count days where completion was on-time (before day boundary)

- [ ] 6.3 Update `habitStreakSummaryProvider` and related streak providers to resolve `EnforcementMode` per entity from `ReminderConfig` and pass it into `computeStreakSummary`

---

## Group 7.0 — AdaptiveReminderPolicy update

- [ ] 7.1 Add optional `EnforcementMode? enforcementMode` parameter to `AdaptiveReminderPolicy.cadenceFor()`
  - If `enforcementMode` is provided, it takes precedence over parsing `modeRefId` string
  - Map `EnforcementMode → RoutineMode` internally using `RoutineModeAdapter` for cadence lookup (keeps cadence definitions in one place)

---

## Group 8.0 — CoachingStyle → AttentionOrchestrator back-off

- [ ] 8.1 Add `CoachingStyle` as an input to `AttentionOrchestrator.evaluate()`
  - New optional parameter: `CoachingStyle coachingStyle = CoachingStyle.balanced`
  - Pass it through from `AttentionOrchestratorService`

- [ ] 8.2 Implement back-off check in `AttentionOrchestratorService._scheduleFollowUp`
  - Track `_consecutiveIgnoredByEntity: Map<String, int>` in memory
  - Increment on each `ignored` interaction; reset to 0 on `opened`
  - Before scheduling follow-up: check `CoachingStyleDeliveryPolicy.shouldBackOff(style, count)`
  - If back-off triggered: suppress follow-up for `backOffDurationMinutes` and log `reminderSuppressed`

- [ ] 8.3 Read `activeCoachingStyleProvider` in `AttentionOrchestratorService.evaluate()` via the injected `getCoachingStyle` callback (keeps service testable)
  - Add `Future<CoachingStyle> Function()? getCoachingStyle` constructor param with fallback to `balanced`

---

## Group 9.0 — UI

- [ ] 9.1 Create `CoachingStyleSelectionScreen` in `lib/features/coaching/presentation/coaching_style_selection_screen.dart`
  - Shows all 4 options with name, description, example framing
  - Tapping a card calls `coachingStyleServiceProvider.setStyle(style)` or `setOnboardingStyle(style)` depending on context
  - Used both in onboarding and settings

- [ ] 9.2 Add "Coaching Style" section to `SettingsScreen`
  - Shows current style with name + description
  - "Change" button opens `CoachingStyleSelectionScreen`
  - After change, shows snackbar: "Your coaching style has been updated. The AI and reminders will adapt from now on."

- [ ] 9.3 Add per-entity `EnforcementMode` selector to `add_task_screen.dart`
  - Replace or complement the existing mode toggle
  - Compact 3-option segmented control (Flexible / Disciplined / Extreme) with short labels
  - Persists selected mode as `modeRefId` on the task via `ReminderConfig`

---

## Group 10.0 — Tests

- [ ] 10.1 `coaching_style_delivery_policy_test.dart`
  - All 4 styles × `consecutiveIgnoredCount` 0, 1, 2, 3, 5
  - `supportive` backs off at 2; others never back off
  - `backOffDurationMinutes` returns 240 for supportive, 0 for others

- [ ] 10.2 `enforcement_mode_policy_test.dart`
  - `urgencyMultiplier` for all 3 modes: 0.8 / 1.0 / 1.3
  - `gracePeriodDays` for all 3 modes: 1 / 0 / 0
  - `allowsLateCompletion` for all 3 modes

- [ ] 10.3 `coaching_framing_derivation_test.dart`
  - Cover the 5 `FocusReason` × 4 `CoachingStyle` combinations that have explicit overrides
  - Verify all other reasons return same result regardless of style (no regression)

- [ ] 10.4 `focus_scoring_engine_enforcement_mode_test.dart`
  - Same entity, same inputs, only `enforcementMode` differs
  - Verify urgency score is multiplied correctly for flexible / disciplined / extreme
  - Verify final `focusScore` reflects the multiplier

- [ ] 10.5 `streak_engine_enforcement_mode_test.dart`
  - Flexible: 1 missed day is forgiven, streak continues
  - Disciplined: 1 missed day breaks streak (existing behavior preserved)
  - Extreme: 1 missed day breaks streak; late completion on same day not counted

- [ ] 10.6 `routine_mode_adapter_test.dart`
  - All 3 `RoutineMode` values map to correct `EnforcementMode` and `CoachingStyle`

---

## Summary

| Group | What it covers | Tasks |
|-------|---------------|-------|
| 1.0 Core enums + adapter | `CoachingStyle`, `EnforcementMode`, `RoutineModeAdapter`, deprecate `RoutineMode` | 3 |
| 2.0 UserCoachingProfile | Model, Isar schema, repository, providers, service | 6 |
| 3.0 Policy classes | `CoachingStyleDeliveryPolicy`, `EnforcementModePolicy` (pure Dart) | 2 |
| 4.0 AI pipeline | `CoachingAiPayload`, `deriveCoachingFraming`, system prompt style block | 4 |
| 5.0 FocusScoringEngine | `FocusCandidate.enforcementMode`, urgency multiplier | 3 |
| 6.0 Streak sensitivity | Grace period per `EnforcementMode`, streak providers wiring | 3 |
| 7.0 AdaptiveReminderPolicy | `EnforcementMode` overload for `cadenceFor()` | 1 |
| 8.0 Orchestrator back-off | `CoachingStyle` in orchestrator, ignore-count tracking, back-off logic | 3 |
| 9.0 UI | `CoachingStyleSelectionScreen`, settings section, per-entity enforcement mode selector | 3 |
| 10.0 Tests | 6 test files covering all policy + derivation + scoring + streak logic | 6 |
| **Total** | | **34 tasks** |

---

## Key architectural invariants to preserve

1. `CoachingStyle` is **global** — one value per user, never per entity.
2. `EnforcementMode` is **per-entity** — sourced from `ReminderConfig.modeRefId`; storage format unchanged.
3. `RoutineMode` is **not deleted** — deprecated with adapter, all existing callers still compile.
4. `CoachingStyleDeliveryPolicy` and `EnforcementModePolicy` are **pure static classes** — no I/O, fully unit-testable.
5. Default values (`CoachingStyle.balanced`, `EnforcementMode.disciplined`) preserve all existing behavior for code not yet migrated.
6. `AdaptiveReminderPolicy` cadence definitions are **not duplicated** — `EnforcementMode` maps through `RoutineModeAdapter` internally.
