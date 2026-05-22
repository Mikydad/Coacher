# Tasks: Phase B — Context Override System

PRD reference: `tasks/prd-phase-b-context-override-system.md`

---

## Group 1.0 — Domain models

- [ ] 1.1 Create `ContextOverride` enum in `context_override.dart`
  - Values: `none`, `meeting`, `focus`, `sleep`, `vacation`, `doNotDisturb`
  - Add `fromStorage(String?)` safe parser

- [ ] 1.2 Create `InterruptionLevel` enum in `interruption_level.dart`
  - Values: `low`, `medium`, `high`, `critical`
  - Add `fromStorage(String?)` safe parser

- [ ] 1.3 Create `UserAttentionState` model in `user_attention_state.dart`
  - Fields: `id` (fixed `"user_attention_state"`), `activeOverride`, `overrideExpiresAt`, `manuallyMuted`, `lastOverrideActivatedAt`, `lastAttentionResetAt`, `sleepWindowStart`, `sleepWindowEnd`, `updatedAtMs`, `schemaVersion`
  - `toMap()` / `fromMap()` round-trip
  - `validate()` using `ModelValidators`
  - Convenience getters: `hasActiveOverride`, `isVacationActive`, `isExpired(DateTime now)`

- [ ] 1.4 Create `SuppressedItem` model in `suppressed_item.dart`
  - Fields: `entityId`, `entityKind`, `entityTitle`, `originalScheduledAt` (int ms), `suggestedAction` (`SuggestedAction` enum)
  - `SuggestedAction` enum: `startNow`, `reschedule`, `shorten`, `skipIntentionally`, `dismiss`

- [ ] 1.5 Create `PostOverrideReview` model in `post_override_review.dart`
  - Fields: `overrideType`, `activeFromMs`, `activeUntilMs`, `suppressedItems`
  - In-memory only (no Isar persistence in Phase B)

---

## Group 2.0 — OverrideAttentionPolicy

- [ ] 2.1 Create `OverrideAttentionPolicy` as a pure static Dart class in `override_attention_policy.dart`
  - `shouldSuppress(InterruptionLevel level, ContextOverride override) → bool`
  - Covers all 6 override types × 4 interruption levels per the PRD table

- [ ] 2.2 Add `allowedMinimumLevel(ContextOverride override) → InterruptionLevel` helper
  - Returns the lowest interruption level that gets through for each override type
  - Used by UI to display the suppression summary description

- [ ] 2.3 Add `suppressionSummary(ContextOverride override) → String` helper
  - Returns a human-readable summary for the quick-activate bottom sheet
  - E.g. `"Holds standard reminders, allows urgent alerts"` for `meeting`

---

## Group 3.0 — Sleep window utility

- [ ] 3.1 Create `sleep_window_util.dart` with function:
  `isWithinSleepWindow(DateTime now, String? windowStart, String? windowEnd) → bool`
  - Parses `"HH:mm"` strings
  - Handles midnight crossover (e.g. `"23:00"` → `"07:00"`)
  - Returns `false` if either field is null/empty

- [ ] 3.2 Add `effectiveOverride(UserAttentionState state, DateTime now) → ContextOverride` helper
  - Returns `state.activeOverride` if non-none and not expired
  - Falls back to `ContextOverride.sleep` if current time is within sleep window
  - Falls back to `ContextOverride.none` otherwise
  - This is the single source of truth for "what override is actually active right now?"

---

## Group 4.0 — Isar schema + repository

- [ ] 4.1 Create `isar_user_attention_state.dart` Isar collection
  - Fields matching `UserAttentionState` (indexed on `stateId`)
  - `fromDomain()` / `toDomain()` converters
  - Stores `payloadJson` for safe round-trip

- [ ] 4.2 Run `build_runner` to generate `isar_user_attention_state.g.dart`

- [ ] 4.3 Add `IsarUserAttentionStateSchema` to `isar_schemas.dart`

- [ ] 4.4 Create abstract `ContextOverrideRepository` interface in `context_override_repository.dart`
  - `getAttentionState() → Future<UserAttentionState?>`
  - `upsertAttentionState(UserAttentionState) → Future<void>`
  - `watchAttentionState() → Stream<UserAttentionState?>`

- [ ] 4.5 Create `IsarContextOverrideRepository` implementing the interface
  - Single-record pattern: always upsert by fixed `stateId`
  - `watchAttentionState()` uses Isar's `.watchLazy()` stream

---

## Group 5.0 — Override activation service

- [ ] 5.1 Create `ContextOverrideService` in `context_override_service.dart`
  - `activateOverride({required ContextOverride type, DateTime? expiresAt}) → Future<void>`
    - Sets `activeOverride`, `overrideExpiresAt`, `lastOverrideActivatedAt`, `updatedAtMs`
  - `endOverride() → Future<PostOverrideReview>`
    - Sets `activeOverride = none`, records `lastAttentionResetAt`
    - Builds and returns `PostOverrideReview`
  - `checkAndExpireIfNeeded(DateTime now) → Future<PostOverrideReview?>`
    - If `overrideExpiresAt` is past `now` and override is still active → runs `endOverride()`
    - Returns review if one was triggered, else null
  - `setSleepWindow({required String start, required String end}) → Future<void>`
  - `clearSleepWindow() → Future<void>`

- [ ] 5.2 Build `presetDurations(ContextOverride type) → List<({String label, Duration? duration})>` pure function
  - Returns preset durations per override type per PRD FR-B-11
  - `duration == null` means "Until I end it"

---

## Group 6.0 — Riverpod providers

- [ ] 6.1 Create `context_override_providers.dart`
  - `contextOverrideRepositoryProvider` → `ContextOverrideRepository`
  - `contextOverrideServiceProvider` → `ContextOverrideService`
  - `attentionStateProvider` → `StreamProvider<UserAttentionState?>` (reactive, from `watchAttentionState()`)
  - `effectiveOverrideProvider` → `Provider<ContextOverride>` derived from `attentionStateProvider` + `effectiveOverride()` utility

- [ ] 6.2 Create `pendingRecoveryReviewProvider` → `StateProvider<PostOverrideReview?>`
  - Holds the in-progress review after an override ends
  - Cleared when the home screen card is dismissed

---

## Group 7.0 — Auto-expiry lifecycle hook

- [ ] 7.1 Find the existing app lifecycle observer (or `AppLifecycleTaskRefresh`) and add a call to `contextOverrideServiceProvider.checkAndExpireIfNeeded(now)` on foreground resume

- [ ] 7.2 Add a `Timer.periodic(5 minutes)` in-app expiry poller
  - Runs `checkAndExpireIfNeeded(DateTime.now())`
  - Sets `pendingRecoveryReviewProvider` if a review is generated
  - Poller starts when `attentionStateProvider` has a non-none override
  - Poller cancels when override becomes `none`
  - Create `context_override_expiry_poller.dart` to encapsulate this

---

## Group 8.0 — Vacation streak protection

- [ ] 8.1 Locate the streak calculation logic (search for where consecutive missed days decrement streaks)

- [ ] 8.2 Inject `UserAttentionState` (or `effectiveOverride`) into the streak engine
  - Skip decrement if `activeOverride == vacation` and the missed date falls within the vacation window
  - `vacationWindowContains(UserAttentionState state, String dateKey) → bool` helper
    - Returns true if `dateKey` falls between `lastOverrideActivatedAt` and `lastAttentionResetAt` (or now, if still active)

- [ ] 8.3 Add unit test for `vacationWindowContains` covering:
  - Date inside window → returns true
  - Date before window → returns false
  - Date after window ends → returns false
  - Vacation still active (no end yet) → returns true for recent date

---

## Group 9.0 — Quick-activate bottom sheet UI

- [ ] 9.1 Create `ContextOverrideQuickActivateSheet` widget in `context_override_quick_activate_sheet.dart`
  - Lists all override modes with icon, name, and `suppressionSummary` description
  - Tapping a mode expands to show duration presets (inline or push to next page)
  - Confirm button calls `contextOverrideServiceProvider.activateOverride()`
  - "Until I end it" is always the last preset option
  - "Custom" duration for `focus` shows a numeric input or slider (15 min – 12 hours)

- [ ] 9.2 Update the existing "I'm distracted" button on `home_screen.dart`
  - Replace existing behavior with `showModalBottomSheet` opening `ContextOverrideQuickActivateSheet`

- [ ] 9.3 Add duration preset selection step
  - After choosing override type, show a row of `ChoiceChip` preset buttons
  - "Custom" option shows a slider or text field
  - Confirm tap resolves `expiresAt = now + duration` (or null for indefinite)

---

## Group 10.0 — Active override indicator on home screen

- [ ] 10.1 Create `ActiveOverrideBanner` widget in `active_override_banner.dart`
  - Shows override type icon + name + remaining time (if time-limited)
  - Updates every 60 seconds via a periodic timer
  - Tapping opens the override management screen or bottom sheet
  - Renders nothing when `effectiveOverrideProvider == none`

- [ ] 10.2 Insert `ActiveOverrideBanner` at the top of the home screen (above the main content, below app bar)
  - Conditionally visible — renders nothing when no override is active

---

## Group 11.0 — Post-override recovery review card

- [ ] 11.1 Create `PostOverrideReviewCard` widget in `post_override_review_card.dart`
  - "While you were in [override type], N item(s) were held back"
  - Lists up to 5 suppressed items with title + `SuggestedAction` chips
  - "Show more" expander if > 5 items
  - "Dismiss all" button marks everything as dismissed and clears `pendingRecoveryReviewProvider`
  - Each action chip tap calls a handler (stub in Phase B — in Phase C the handler will mutate schedules)

- [ ] 11.2 Insert `PostOverrideReviewCard` into the home screen body
  - Watches `pendingRecoveryReviewProvider`
  - Renders nothing when provider is null
  - Placed between the active override banner and the main coaching card

- [ ] 11.3 Persist pending review flag across restarts
  - On `endOverride()`, if `suppressedItems` is non-empty, write a lightweight flag to SharedPreferences: `pending_override_review = true`
  - On app start, if flag is set and no review is in state, rebuild a stub review from persisted data
  - Clear flag when review is dismissed
  - Use `shared_preferences` package (already in pubspec if present, otherwise add it)

---

## Group 12.0 — Settings page section

- [ ] 12.1 Create `OverrideSettingsSection` widget in `override_settings_section.dart`
  - Current active override status row (icon + name + time remaining, or "No active override")
  - "End now" button (only visible when override is active)
  - Sleep window toggle + start time picker + end time picker
  - Recent override history list (last 7 entries — override type, duration, item count)

- [ ] 12.2 Add `overrideHistoryProvider` → `Provider<List<OverrideHistoryEntry>>`
  - `OverrideHistoryEntry`: `overrideType`, `startedAtMs`, `endedAtMs`, `suppressedItemCount`
  - In Phase B this can be in-memory (accumulated since app launch) or stored in a small Isar collection
  - Add `IsarOverrideHistoryEntry` schema if persisting (optional in Phase B)

- [ ] 12.3 Wire `OverrideSettingsSection` into the main settings screen

---

## Group 13.0 — Tests

- [ ] 13.1 `override_attention_policy_test.dart`
  - 24 cases: all 6 override types × 4 interruption levels
  - Verify `shouldSuppress` matches the PRD table exactly

- [ ] 13.2 `sleep_window_util_test.dart`
  - Same-day window (e.g. 01:00–07:00)
  - Midnight crossover (e.g. 23:00–07:00) — time before midnight, after midnight, outside window
  - Both fields null → always returns false
  - Edge: exactly at boundary times

- [ ] 13.3 `context_override_service_test.dart` (uses fake `ContextOverrideRepository`)
  - `activateOverride` persists correct state
  - `endOverride` clears override and records `lastAttentionResetAt`
  - `checkAndExpireIfNeeded` returns null before expiry, returns review after expiry
  - `setSleepWindow` / `clearSleepWindow` update correctly

- [ ] 13.4 `vacation_streak_protection_test.dart`
  - Date inside vacation window → no streak decrement
  - Date outside window → normal decrement applies
  - Vacation still active (no end) → recent date protected

---

## Summary

| Group | What it covers | Tasks |
|-------|---------------|-------|
| 1.0 Domain models | `ContextOverride`, `InterruptionLevel`, `UserAttentionState`, `SuppressedItem`, `PostOverrideReview` | 5 |
| 2.0 OverrideAttentionPolicy | Pure Dart suppression logic + helpers | 3 |
| 3.0 Sleep window utility | Midnight-crossover-aware helper + `effectiveOverride()` | 2 |
| 4.0 Isar schema + repository | Schema, codegen, `isar_schemas.dart`, abstract interface, Isar impl | 5 |
| 5.0 Override activation service | `ContextOverrideService` + preset durations | 2 |
| 6.0 Riverpod providers | Repository, service, stream, effective override, review state | 2 |
| 7.0 Auto-expiry lifecycle | Foreground hook + 5-min poller | 2 |
| 8.0 Vacation streak protection | Streak logic injection + `vacationWindowContains` + tests | 3 |
| 9.0 Quick-activate UI | Bottom sheet, duration selector, home screen hook | 3 |
| 10.0 Active override banner | Home screen indicator with live countdown | 2 |
| 11.0 Recovery review card | Card widget, home screen insertion, restart persistence | 3 |
| 12.0 Settings section | Override status, sleep window config, history | 3 |
| 13.0 Tests | Policy (24 cases), sleep window, service, vacation streak | 4 |
| **Total** | | **39 tasks** |
