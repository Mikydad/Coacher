# PRD: Phase E — Profile Screen

**Status:** Draft  
**Author:** AI  
**Target:** Wire the existing "Profile" bottom-nav tab into a real screen

---

## 1. Background

The app's bottom navigation bar already has a fifth item labelled **Profile** (`Icons.person`, index 4) that does nothing — `onTap` only handles indices 1 and 2. The user has no single place to see who they are, how they are set up to be coached, or their top-level progress.

This PRD defines a minimal-but-meaningful profile screen that surfaces the **coaching contract** (how the user wants to be coached) alongside identity, progress snapshot, and account actions.

---

## 2. Goals

- Give the Profile nav item a real destination.
- Make `CoachingStyle` feel like an owned identity, not a buried setting.
- Provide a lightweight progress snapshot without duplicating the full Analytics screen.
- Surface account-level actions (sign-out, data, delete) in one predictable place.
- Keep the screen scannable in under 10 seconds; no infinite scroll.

---

## 3. Non-Goals

- Community / social features (the Community tab is a separate initiative).
- Detailed analytics charts (those live in the Progress tab).
- Avatar image upload (deferred; initials-based avatar is sufficient for V1).
- Real authentication beyond the existing anonymous Firebase auth.

---

## 4. Functional Requirements

### FR-E-01 — Route & Navigation
- A new `ProfileScreen` is registered at `/profile`.
- `HomeScreen.bottomNavigationBar.onTap(4)` navigates to `/profile`.
- The screen uses `Navigator.pushNamed` (consistent with the app's existing routing pattern — no go_router).

### FR-E-02 — Identity Section
- Display name: editable inline `TextField`. Default: `"You"` on first launch.
- Avatar: circle with the user's initials (first letter of display name). Uses `CoachingStyle` accent color as background.
- Member-since date: derived from the earliest `createdAtMs` across all `UserGoal` records, or the `onboardingCompletedAtMs` from `UserCoachingProfile`, whichever is earlier. Falls back to "—" if no data.
- Display name persisted via a new single-record `UserDisplayNamePreference` stored in Isar (see §6).

### FR-E-03 — Coaching Contract Section
Header: **"Your Coaching Contract"**

- **Coaching Style tile**: shows current style name + one-line description. Taps into `CoachingStyleSelectionScreen` (already exists).
- **Default Enforcement Mode tile**: shows current default `EnforcementMode` name + description. Taps into a new `DefaultEnforcementModeSelectionScreen` (a thin wrapper reusing `EnforcementMode` display logic). Persisted via `UserDisplayNamePreference` payload (same record, extended — see §6).
- Both tiles show a small `>` chevron.

### FR-E-04 — Progress Snapshot Section
Header: **"Progress"**

Three stat chips in a row:

| Chip | Value | Source |
|---|---|---|
| Longest Streak | Max `longestStreak` across all habit streak summaries | `habitStreakSummaryProvider` family, iterated |
| Goals Active | Count of `UserGoal` with `status == active` | `allGoalsProvider` |
| Total Completions | Count of all `AnalyticsEvent` with type `habitCompleted` | new lightweight provider (count query from Isar) |

- Chips are read-only, tap does nothing in V1.
- If all values are 0 / unavailable, show a placeholder: *"Complete your first task to see progress here."*

### FR-E-05 — Preferences Section
Header: **"Preferences"**

- **Quiet Hours** tile: shows current sleep window start/end from `UserAttentionState`. Taps into the existing `OverrideSettingsSection` logic or a new dedicated quiet-hours picker (can be a bottom sheet). Read-only display is acceptable for V1 if the picker is deferred.
- **Coaching Setup** tile: label "Revisit onboarding". Taps into `CoachingStyleSelectionScreen` with an `isOnboarding: false` flag.

### FR-E-06 — Account Section
Header: **"Account"**

- **Export Data** tile: placeholder action — shows a `SnackBar("Export coming soon")` for V1.
- **Sign Out** tile (destructive style): shows a confirmation dialog before calling `FirebaseAuth.instance.signOut()` and resetting navigation to `HomeScreen`.
- **Delete Account** tile (destructive, red label): shows a two-step confirmation dialog. V1 action: `SnackBar("Contact support to delete your account")`. Full deletion deferred.

### FR-E-07 — App Version Footer
- Bottom of the screen: `"Coach for Life v{version}"` in `bodySmall` muted style.
- Version pulled from `package_info_plus` (already a common Flutter dependency).

---

## 5. UI Layout

```
┌─────────────────────────────────┐
│  [←]            Profile         │  ← AppBar (no back button needed, root tab)
├─────────────────────────────────┤
│  ● [Avatar]  Your Name      ✎  │  ← Identity row
│             Member since Jan 25 │
├─────────────────────────────────┤
│  YOUR COACHING CONTRACT         │
│  ┌─────────────────────────┐   │
│  │ Coaching Style          >│   │
│  │ Balanced                 │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ Enforcement Mode        >│   │
│  │ Disciplined              │   │
│  └─────────────────────────┘   │
├─────────────────────────────────┤
│  PROGRESS                       │
│  ┌────────┐┌────────┐┌────────┐│
│  │  🔥 14 ││  🎯 3  ││  ✓ 82 ││
│  │Longest ││ Goals  ││ Total  ││
│  │Streak  ││Active  ││Complet.││
│  └────────┘└────────┘└────────┘│
├─────────────────────────────────┤
│  PREFERENCES                    │
│  Quiet Hours             22–07 >│
│  Coaching Setup               > │
├─────────────────────────────────┤
│  ACCOUNT                        │
│  Export Data                  > │
│  Sign Out                     > │
│  Delete Account               > │  ← red
├─────────────────────────────────┤
│         Coach for Life v1.0.0   │
└─────────────────────────────────┘
```

Screen is a `CustomScrollView` with `SliverList` sections, each section a `SliverToBoxAdapter` wrapping a `Column`.

---

## 6. Data Model

### New: `UserProfilePreference`

Single-record domain model (mirrors `UserCoachingProfile` pattern).

```dart
class UserProfilePreference {
  static const kRecordId = 'user_profile_preference';
  static const kSchemaVersion = 1;

  final String id;
  final String displayName;              // FR-E-02
  final EnforcementMode defaultEnforcementMode; // FR-E-03
  final int updatedAtMs;
  final int schemaVersion;
}
```

Isar collection: `IsarUserProfilePreference` with `profileId` + `payloadJson` pattern.

Schema registered in `isar_schemas.dart`.

Riverpod:
- `userProfilePreferenceRepositoryProvider`
- `userProfilePreferenceServiceProvider`
- `userProfilePreferenceStreamProvider` → `AsyncValue<UserProfilePreference>`
- `displayNameProvider` → convenience getter (derived)
- `defaultEnforcementModeProvider` → convenience getter (derived)

### New lightweight provider: `totalCompletionsCountProvider`

```dart
// Returns int — count of all habitCompleted events in Isar
final totalCompletionsCountProvider = FutureProvider<int>((ref) async { ... });
```

### Existing providers consumed (no changes needed)
- `activeCoachingStyleProvider`
- `coachingProfileStreamProvider`
- `habitStreakSummaryProvider` (family — iterate all habit ids)
- `allGoalsProvider`
- `userAttentionStateStreamProvider`

---

## 7. File Plan

| File | Action |
|---|---|
| `lib/features/profile/domain/models/user_profile_preference.dart` | NEW — domain model |
| `lib/core/local_db/isar_collections/isar_user_profile_preference.dart` | NEW — Isar collection |
| `lib/core/local_db/isar_collections/isar_schemas.dart` | MODIFY — add schema |
| `lib/features/profile/data/profile_preference_repository.dart` | NEW — abstract + Isar impl |
| `lib/features/profile/application/profile_preference_service.dart` | NEW — set display name, set default enforcement mode |
| `lib/features/profile/application/profile_providers.dart` | NEW — all Riverpod providers for profile feature |
| `lib/features/profile/presentation/profile_screen.dart` | NEW — main screen |
| `lib/features/profile/presentation/default_enforcement_mode_selection_screen.dart` | NEW — thin mode picker |
| `lib/features/home/presentation/home_screen.dart` | MODIFY — wire `onTap(4)` to ProfileScreen |
| `lib/app/app.dart` | MODIFY — register `/profile` route |

---

## 8. Implementation Groups

### Group 1 — Data Layer
1.1 `UserProfilePreference` domain model  
1.2 `IsarUserProfilePreference` collection + register schema  
1.3 `ProfilePreferenceRepository` (abstract + Isar)  
1.4 `ProfilePreferenceService`  
1.5 `profile_providers.dart` (repository, service, stream, convenience providers)  
1.6 `totalCompletionsCountProvider`

### Group 2 — Screens
2.1 `DefaultEnforcementModeSelectionScreen`  
2.2 `ProfileScreen` (all sections)

### Group 3 — Wiring
3.1 Register `/profile` route in `app.dart`  
3.2 Wire `HomeScreen` bottom nav `onTap(4)`

### Group 4 — Tests
4.1 `user_profile_preference_model_test.dart` — serialization round-trip, `copyWith`, defaults  
4.2 `profile_preference_service_test.dart` — setDisplayName, setDefaultEnforcementMode  
4.3 `profile_screen_widget_test.dart` — renders all sections, displays coaching style name

---

## 9. Acceptance Criteria

- [ ] Tapping the Profile tab opens `ProfileScreen` (no crash, no blank screen).
- [ ] Display name is editable and persists across app restarts.
- [ ] Coaching Style tile shows the current style and navigates to `CoachingStyleSelectionScreen`.
- [ ] Default Enforcement Mode tile shows the current mode and navigates to picker.
- [ ] All three progress chips show real values (not hardcoded).
- [ ] Sign Out shows a confirmation dialog and completes without error.
- [ ] App version is visible at the bottom of the screen.
- [ ] All Group 4 tests pass.
