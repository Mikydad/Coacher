# PRD: Phase 2-A — Identity & Auth Implementation

**Branch:** `platform-refactor`  
**Status:** Ready for implementation  
**Depends on:** Phase 1-A + Phase 1-B complete ✅  
**Source of truth:** `PRD/Platform_Refactor/Runtime_Consolidation_and_Platform_Stabilization.md` §PHASE 2  
**Extends:** `tasks/prd-auth-real-accounts-phases.md` (high-level design; all architecture decisions locked there apply here)

---

## 1. What this PRD covers

This is the **implementation-level** PRD for Phase 2-A. It generates the concrete task list for executing Phases A → E from the existing auth PRD, split into checkboxed subtasks ordered by dependency.

Phase 2 goal: transition from a **single-device, anonymous-auth** runtime to an **identity-based platform** that is safe for real accounts, multi-device sync, and future subscription gating.

---

## 2. Current state (pre-Phase 2)

| Area | Current behavior | Problem |
|---|---|---|
| Sign-in | `AuthInitializer.ensureSignedIn()` always calls `signInAnonymously()` on cold start if no session | Anonymous UIDs lost on reinstall |
| Sign-out | Profile `_signOut()` only calls `Navigator.popUntil(r.isFirst)` — **no `FirebaseAuth.signOut()`** | Firebase session persists; shared device risk |
| Auth gate | None — app always opens directly into `FirstLaunchGate → CoachForLifeApp` | No login wall |
| Isar DB | Single file `coach_isar` — not partitioned by uid | User A's data visible to User B on same device |
| Account screen | `AccountSettingsScreen` has placeholder rows with "coming soon" snackbars | Dead UI |
| Dependencies | `firebase_auth: ^5.7.0` only — no `google_sign_in` / `sign_in_with_apple` | Social login blocked |

---

## 3. Implementation phases & task list

### Phase A — Auth shell (no new identity providers)

**Goal:** Centralize auth state, implement real sign-out + local session policy, prepare `AuthGate` without forcing login yet.

#### A.1 — `AuthRepository` + `AuthSessionPolicy`

- [ ] **A.1.1** Create `lib/features/auth/` module skeleton:
  ```
  lib/features/auth/
    application/
      auth_repository.dart
      auth_providers.dart
      auth_session_policy.dart
    domain/
      auth_failure.dart
    presentation/
      auth_gate.dart
      auth_landing_screen.dart       ← placeholder only in Phase A
      login_screen.dart              ← scaffold only in Phase A
      sign_up_screen.dart            ← scaffold only in Phase A
      forgot_password_screen.dart    ← scaffold only in Phase A
      widgets/
        auth_text_field.dart
        auth_primary_button.dart
  ```

- [ ] **A.1.2** Create `auth_failure.dart`
  - Sealed class: `AuthFailure` with variants:
    - `NetworkFailure`
    - `InvalidCredentials`
    - `EmailAlreadyInUse`
    - `WeakPassword`
    - `RequiresRecentLogin`
    - `Unknown(String message)`

- [ ] **A.1.3** Create `auth_repository.dart`
  - Plain Dart class wrapping `FirebaseAuth.instance`
  - Methods:
    - `Stream<User?> authStateChanges()` — thin wrapper
    - `User? get currentUser`
    - `bool get isSignedIn`
    - `bool get isAnonymous`
    - `Future<Either<AuthFailure, User>> signInAnonymously()`
    - `Future<void> signOut()` — calls `FirebaseAuth.signOut()`
    - `Future<Either<AuthFailure, User>> signInWithEmail({required String email, required String password})`
    - `Future<Either<AuthFailure, User>> createUserWithEmail({required String email, required String password, String? displayName})`
    - `Future<Either<AuthFailure, User>> linkAnonymousWithEmail({required String email, required String password})`
    - `Future<void> sendPasswordResetEmail(String email)`
    - `Future<Either<AuthFailure, void>> updatePassword(String newPassword)`
    - `Future<Either<AuthFailure, void>> reauthenticateWithEmail({required String email, required String password})`
    - `Future<Either<AuthFailure, void>> deleteAccount()`
  - All `FirebaseAuthException` codes mapped to `AuthFailure` variants
  - Uses `dartz` or a simple `Result<L, R>` sealed class — **do not add `dartz` as a dep**, implement a minimal `Result` sealed class inline

- [ ] **A.1.4** Create `auth_providers.dart`
  - `authRepositoryProvider = Provider<AuthRepository>(_ => AuthRepository())`
  - `authStateProvider = StreamProvider<User?>(ref => ref.read(authRepositoryProvider).authStateChanges())`
  - `isSignedInProvider = Provider<bool>(ref => ref.watch(authStateProvider).valueOrNull != null)`

- [ ] **A.1.5** Create `auth_session_policy.dart`
  - Constants:
    - `const String kLastSignedInUidPrefsKey = 'last_signed_in_uid'`
    - `const bool kRequireRegisteredAuth = false` (flip to `true` when Phase B ships to production)
  - Methods:
    - `static Future<String?> getLastSignedInUid()` — reads from `SharedPreferences`
    - `static Future<void> persistUid(String uid)` — writes to `SharedPreferences`
    - `static Future<bool> hasUidChanged(String newUid)` — compares with stored uid
    - `static Future<void> clearLocalSession()`:
      1. Cancel all scheduled local notifications: `LocalNotificationsService.instance.cancelAll()`
      2. Clear Isar: call `OfflineStore.instance.clearAll()` (add method — see A.1.6)
      3. Clear relevant `SharedPreferences` keys: `isar_seeded_v1`, `kLastSignedInUidPrefsKey`, `notification_task_id_index_v1`
      4. **Does NOT** clear `FirebaseAuth` session — caller handles that separately

- [ ] **A.1.6** Add `clearAll()` to `OfflineStore`
  - Iterates all registered Isar collections and calls `isar.writeTxn(() => isar.clear())`
  - Kept internal; only called from `AuthSessionPolicy`

#### A.2 — `AuthGate` + `main.dart` wiring

- [ ] **A.2.1** Create `lib/features/auth/presentation/auth_gate.dart`
  - `ConsumerWidget` that watches `authStateProvider`
  - **Loading state:** returns the existing full-screen spinner (matches `FirstLaunchGate` style — `Color(0xFF050806)` + green indicator)
  - **Signed in:** returns `child` (the existing `FirstLaunchGate → AppLifecycleTaskRefresh → CoachForLifeApp` subtree)
  - **Signed out, `kRequireRegisteredAuth == false`:** triggers anonymous sign-in via `authRepositoryProvider.signInAnonymously()`, stays on spinner until resolves
  - **Signed out, `kRequireRegisteredAuth == true`:** returns `AuthLandingScreen` (Phase A: just a placeholder — "Sign in coming soon" + app icon)

- [ ] **A.2.2** Wrap `runApp` in `main.dart` with `AuthGate`:
  ```dart
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: AuthGate(
        child: FirstLaunchGate(
          child: AppLifecycleTaskRefresh(
            child: CoachForLifeApp(),
          ),
        ),
      ),
    ),
  );
  ```

- [ ] **A.2.3** Remove `AuthInitializer.ensureSignedIn()` call from `AppBootstrap.initialize()`
  - Move the "ensure signed in" responsibility entirely to `AuthGate` (which calls `signInAnonymously` when flag is false)
  - `AppBootstrap` now starts with Firebase init then proceeds — anonymous sign-in is no longer blocking the bootstrap sequence

#### A.3 — Real sign-out in Profile

- [ ] **A.3.1** Update `_signOut()` in `profile_screen.dart`:
  - Show existing confirmation dialog (update copy to: *"You'll be signed out on this device. Your cloud data stays tied to your account."*)
  - On confirm:
    1. `await ref.read(authRepositoryProvider).signOut()`
    2. `await AuthSessionPolicy.clearLocalSession()`
    3. Navigation handled automatically by `AuthGate` listening to `authStateChanges`
  - Remove the `Navigator.popUntil` hack — `AuthGate` will reactively show `AuthLandingScreen`

- [ ] **A.3.2** Persist `last_signed_in_uid` on each confirmed sign-in
  - In `AuthGate`, after `authStateProvider` emits a non-null user: call `AuthSessionPolicy.persistUid(user.uid)`
  - On sign-in (Phase B), also call `AuthSessionPolicy.hasUidChanged` and invoke `clearLocalSession()` if uid differs

#### A.4 — Tests (Phase A)

- [ ] **A.4.1** `test/features/auth/auth_session_policy_test.dart`
  - Test: `clearLocalSession` resets all expected prefs keys
  - Test: `hasUidChanged` returns true when uid differs from stored
  - Test: `persistUid` → `getLastSignedInUid` round-trip

- [ ] **A.4.2** `test/features/auth/auth_repository_test.dart`
  - Mock `FirebaseAuth`
  - Test: `AuthFailure` mapping for each `FirebaseAuthException` code
  - Test: `signOut()` calls `FirebaseAuth.signOut()`

#### A.5 — Phase A acceptance criteria

- [ ] Cold start (flag false): app opens anonymously, no regression
- [ ] Log out: `FirebaseAuth.currentUser` is null after sign-out
- [ ] Log out: Isar is wiped (tasks/goals not visible until next sign-in + sync)
- [ ] Log out: `AuthGate` reacts and shows landing placeholder (or re-triggers anonymous sign-in per flag)
- [ ] `flutter analyze lib/features/auth/` → zero errors

---

### Phase B — Login & sign-up UI

**Goal:** Email/password registration and login; full auth flow when flag is true.

#### B.1 — Auth landing + route registration

- [ ] **B.1.1** Register auth routes in `lib/app/app.dart`:
  ```dart
  '/auth':           (_) => const AuthLandingScreen(),
  '/auth/login':     (_) => const LoginScreen(),
  '/auth/sign-up':   (_) => const SignUpScreen(),
  '/auth/forgot-password': (_) => const ForgotPasswordScreen(),
  ```

- [ ] **B.1.2** Build `AuthLandingScreen`
  - Dark background `#050806`, app icon/logo at top third
  - Primary CTA: "Sign in" → `/auth/login`
  - Secondary CTA: "Create account" → `/auth/sign-up`
  - Tertiary text link: "Continue as guest" → triggers `signInAnonymously()` (only shown when `kRequireRegisteredAuth == false`)
  - Design language: matches Profile/Settings screens — `#0E0E0E` card surfaces, `#B2ED00` accent buttons

#### B.2 — Shared auth widgets

- [ ] **B.2.1** Create `auth_text_field.dart`
  - `AuthTextField(label, controller, [obscure=false, errorText, keyboardType])`
  - Dark fill `#1A1A1A`, `#B2ED00` focused border, white input text

- [ ] **B.2.2** Create `auth_primary_button.dart`
  - `AuthPrimaryButton({label, onPressed, isLoading})`
  - `#B2ED00` background, black bold text, `CircularProgressIndicator` inside when loading
  - Disabled + opacity when `onPressed == null`

#### B.3 — LoginScreen

- [ ] **B.3.1** Build `LoginScreen`
  - Fields: email (keyboard `emailAddress`), password (obscured)
  - Submit: calls `authRepository.signInWithEmail(email, password)`
  - Loading state disables form + shows button spinner
  - Error: inline `AuthFailure` → human string below button
  - Links: "Forgot password?" → `/auth/forgot-password`, "Create account" → `/auth/sign-up`
  - On success: navigation handled by `AuthGate` reactively — no manual `Navigator.push`

- [ ] **B.3.2** `AuthFailure` → human-readable error strings:
  | `AuthFailure` | String |
  |---|---|
  | `InvalidCredentials` | "That email or password doesn't match. Try again or reset your password." |
  | `NetworkFailure` | "No internet connection. Check your network and try again." |
  | `Unknown` | "Something went wrong. Please try again." |

#### B.4 — SignUpScreen

- [ ] **B.4.1** Build `SignUpScreen`
  - Fields: display name (optional), email, password, confirm password
  - Password validation: ≥ 8 chars (inline, before submission)
  - Confirm password match validation (inline)
  - ToS checkbox: "I agree to the Terms of Service" (placeholder text link OK in Phase B)
  - Submit logic:
    - If `currentUser?.isAnonymous == true` → call `authRepository.linkAnonymousWithEmail(email, password)` (Phase C logic, stubbed in B with `createUserWithEmail` fallback)
    - Else → call `authRepository.createUserWithEmail(email, password, displayName)`
  - On success: if `displayName` provided, call `FirebaseAuth.currentUser?.updateDisplayName(displayName)`; store in Isar `UserProfilePreference` too
  - `AuthFailure.EmailAlreadyInUse` → "An account with this email already exists. Sign in instead."
  - `AuthFailure.WeakPassword` → "Password must be at least 8 characters."

#### B.5 — ForgotPasswordScreen

- [ ] **B.5.1** Build `ForgotPasswordScreen`
  - Single email field, submit button
  - Calls `authRepository.sendPasswordResetEmail(email)`
  - On success: show "Check your email — we've sent a password reset link." with a "Back to sign in" button
  - Error: inline (invalid email format, network failure)

#### B.6 — Bootstrap & uid-change policy

- [ ] **B.6.1** In `AuthGate`, after each `authStateProvider` emission of a non-null user:
  - If `await AuthSessionPolicy.hasUidChanged(user.uid)`:
    1. `await AuthSessionPolicy.clearLocalSession()` (wipes stale local data)
    2. Show brief "Syncing your data…" overlay
    3. `await SyncService.instance.syncFromRemote(force: true)`
  - Always: `await AuthSessionPolicy.persistUid(user.uid)`

- [ ] **B.6.2** `FirstLaunchGate` — reset `isar_seeded_v1` on uid wipe
  - `AuthSessionPolicy.clearLocalSession()` already clears this prefs key (A.1.5 step 3)
  - `FirstLaunchGate` will re-run its seed on the new uid automatically

- [ ] **B.6.3** Set `kRequireRegisteredAuth = true` for the release flavor:
  - Add `--dart-define=REQUIRE_REGISTERED_AUTH=true` to release build script
  - Read via `const kRequireRegisteredAuth = bool.fromEnvironment('REQUIRE_REGISTERED_AUTH', defaultValue: false)`

#### B.7 — Tests (Phase B)

- [ ] **B.7.1** Widget tests `test/features/auth/login_screen_test.dart`
  - Test: submit with empty fields shows validation error
  - Test: `InvalidCredentials` failure shows inline error string
  - Test: loading state disables button

- [ ] **B.7.2** Widget tests `test/features/auth/sign_up_screen_test.dart`
  - Test: mismatched passwords show error before submit
  - Test: `EmailAlreadyInUse` shows correct message

#### B.8 — Phase B acceptance criteria

- [ ] New user creates account → lands on Home → tasks/goals empty or synced from cloud
- [ ] Returning user signs in on second launch → correct data loaded
- [ ] Invalid credentials → inline error, no crash, no snackbar
- [ ] Password reset email sends (verified in Firebase test project)
- [ ] `kRequireRegisteredAuth = true` in release build: cold start shows `AuthLandingScreen`

---

### Phase C — Anonymous account linking

**Goal:** Users who used the app anonymously keep their Firebase uid and Firestore tree when they register.

#### C.1 — Link anonymous → email

- [ ] **C.1.1** In `SignUpScreen.submit()`: detect `currentUser?.isAnonymous == true`
  - If anonymous → call `authRepository.linkAnonymousWithEmail(email, password)`
  - `linkAnonymousWithEmail` implementation:
    ```dart
    final credential = EmailAuthProvider.credential(email: email, password: password);
    await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
    ```
  - On success: uid is unchanged — Firestore data is preserved automatically

- [ ] **C.1.2** Handle `credential-already-in-use`:
  - Store pending email credential
  - Show dialog: *"An account with this email already exists. Sign in to it? Your offline guest data won't be merged automatically."*
  - On confirm: call `authRepository.signInWithEmail(email, password)` — uid changes → uid-change policy in `AuthGate` runs (wipe + sync)
  - On cancel: stay on sign-up, clear password field

- [ ] **C.1.3** Show migration banner on `AuthLandingScreen` for anonymous users
  - Guard: `ref.watch(authStateProvider).valueOrNull?.isAnonymous == true`
  - Banner text: *"Create an account to save your progress across devices."*
  - Taps → `/auth/sign-up`
  - Dismissible; persists between sessions via prefs flag `auth_migration_banner_dismissed`

#### C.2 — Tests (Phase C)

- [ ] **C.2.1** `test/features/auth/auth_repository_test.dart` — add:
  - Mock `linkWithCredential` success path: uid unchanged
  - Mock `credential-already-in-use`: returns `AuthFailure` mapped correctly

#### C.3 — Phase C acceptance criteria

- [ ] Anonymous user with synced goals registers → same uid in Firebase console → goals still accessible at `users/{sameUid}/goals`
- [ ] Reinstall + email login retrieves cloud data (no dependency on anonymous session)
- [ ] `credential-already-in-use` → dialog shown, existing account sign-in works

---

### Phase D — Account settings (password, export, delete)

**Goal:** Wire the placeholder rows on `AccountSettingsScreen` with real Firebase flows.

#### D.1 — Change password

- [ ] **D.1.1** `AccountSettingsScreen` "Change Password" row → push to `ChangePasswordScreen` (new)
  - Fields: current password, new password, confirm new password
  - On submit:
    1. `await authRepository.reauthenticateWithEmail(email, currentPassword)`
    2. If fails with `RequiresRecentLogin` or `InvalidCredentials`: show error
    3. On success: `await authRepository.updatePassword(newPassword)`
  - Only shown when `currentUser?.providerData` contains email provider

#### D.2 — Delete account

- [ ] **D.2.1** `AccountSettingsScreen` "Delete Account" row
  - Step 1: confirmation dialog with type-to-confirm: user must type `DELETE`
  - Step 2: re-auth dialog (email + password) — calls `reauthenticateWithEmail`
  - Step 3: `await authRepository.deleteAccount()` → `await AuthSessionPolicy.clearLocalSession()`
  - Navigation handled by `AuthGate` reactively (user is now null)
  - Note in comments: Firestore `users/{uid}` data is orphaned in V1; manual cleanup via Firebase console script

#### D.3 — Export data (V1)

- [ ] **D.3.1** `AccountSettingsScreen` "Export Data" row
  - Export Isar tasks, goals, reminders to JSON
  - Trigger device share sheet via `share_plus` (already a dep or add it)
  - File: `coach_export_{date}.json`

#### D.4 — Forgot password deep link from account screen

- [ ] **D.4.1** `AccountSettingsScreen` "Forgot Password" text link → navigate to `/auth/forgot-password`

#### D.5 — Phase D acceptance criteria

- [ ] User can change password when signed in with email provider; new password works on next sign-in
- [ ] Delete account: Firebase user gone; app shows login; old credentials rejected
- [ ] Export: file produced and shareable

---

### Phase E — Hardening & production readiness

**Goal:** Lock security, add observability, complete rule audit.

#### E.1 — Firestore rules audit

- [ ] **E.1.1** Audit every Firestore collection path used in `lib/core/firebase/firestore_paths.dart`
  - Verify all paths are under `users/{uid}` or have explicit shared-path rules
  - Check community paths (circles, activity feed) — add explicit `request.auth != null` guards
  - Update `documentation/firebase-rules.md` with final rule set

#### E.2 — Email verification (optional)

- [ ] **E.2.1** After `createUserWithEmail` success: call `user.sendEmailVerification()`
- [ ] **E.2.2** Show non-blocking banner on Home: *"Please verify your email to unlock all features."* with "Resend email" action
  - Guard: `user?.emailVerified == false && !user?.isAnonymous`
  - Store `email_verification_banner_dismissed_until` in prefs (dismiss for 24h)
- [ ] **E.2.3** Community post guard: if `!user.emailVerified` → show "Verify your email to post in circles"

#### E.3 — Structured auth error logging

- [ ] **E.3.1** Add `debugPrint('[Auth]', ...)` tags to all `AuthRepository` failure paths
  - Never log passwords, tokens, or credentials
  - Log: event type, `FirebaseAuthException.code`, uid (truncated to 8 chars for privacy)

#### E.4 — Firebase App Check (staging gate)

- [ ] **E.4.1** Add `firebase_app_check` dependency
- [ ] **E.4.2** Initialize in `AppBootstrap` with `DebugProvider` for debug builds, `PlayIntegrityProvider` / `AppAttestProvider` for release
- [ ] **E.4.3** Enable App Check enforcement in Firebase Console (staging project first)

#### E.5 — Tests (Phase E)

- [ ] **E.5.1** Document manual QA checklist for auth emulator:
  - anonymous → register → uid unchanged
  - logout → relaunch → auth gate shown
  - login → data sync → correct data loaded
  - wrong password → error, no crash
  - delete account → gone from Firebase console

#### E.6 — Phase E acceptance criteria

- [ ] Firestore rules deny all reads/writes outside documented paths
- [ ] App Check enforced on staging build
- [ ] Auth errors logged structurally (no credentials in logs)
- [ ] `documentation/firebase-rules.md` updated

---

## 4. Files created / modified (full list)

### New files

```
lib/features/auth/
  application/
    auth_repository.dart
    auth_providers.dart
    auth_session_policy.dart
  domain/
    auth_failure.dart
  presentation/
    auth_gate.dart
    auth_landing_screen.dart
    login_screen.dart
    sign_up_screen.dart
    forgot_password_screen.dart
    change_password_screen.dart         ← Phase D
    widgets/
      auth_text_field.dart
      auth_primary_button.dart
      auth_migration_banner.dart        ← Phase C

test/features/auth/
  auth_repository_test.dart
  auth_session_policy_test.dart
  login_screen_test.dart
  sign_up_screen_test.dart
```

### Modified files

| File | Change |
|---|---|
| `lib/main.dart` | Wrap with `AuthGate` |
| `lib/app/app.dart` | Register auth routes |
| `lib/core/bootstrap/app_bootstrap.dart` | Remove `AuthInitializer.ensureSignedIn()` |
| `lib/core/offline/offline_store.dart` | Add `clearAll()` method |
| `lib/features/profile/presentation/profile_screen.dart` | Real `signOut()` + `clearLocalSession()` |
| `lib/features/settings/presentation/account_settings_screen.dart` | Wire change password, delete, export, forgot-pw rows |

---

## 5. Design system (auth screens)

All auth screens follow the existing Obsidian Pulse design language:

| Token | Value |
|---|---|
| Background | `#050806` (matches `FirstLaunchGate`) |
| Card surface | `#0E0E0E` |
| Input fill | `#1A1A1A` |
| Accent / CTA | `#B2ED00` (lime green — matches Profile) |
| Error | `#FF5252` |
| Text primary | `#FFFFFF` |
| Text secondary | `#888888` |
| Border radius | 12px (fields), 24px (buttons) |
| Font | existing Material 3 bold |

Screens are full-height with `SafeArea`, a `SingleChildScrollView` body, and no `AppBar` on landing (back arrow only on sub-screens).

---

## 6. Dependency changes

```yaml
# No new required deps for Phase A/B/C/D
# Phase E adds:
firebase_app_check: ^0.3.x   # check latest on pub.dev

# Phase D export — if not already present:
share_plus: ^10.x
```

---

## 7. Risk register

| Risk | Likelihood | Mitigation |
|---|---|---|
| `clearLocalSession()` too aggressive — user surprise | Medium | Dialog copy warns: "local data cleared, cloud data safe" |
| Uid-change wipe fires on same user (clock drift / token refresh) | Low | `hasUidChanged` uses stored pref — same uid → no wipe |
| Anonymous users with large offline-only datasets lose data if `credential-already-in-use` | Medium | Phase C dialog clearly warns; V2 merge is documented but out of scope |
| `FirstLaunchGate` seed runs before `AuthGate` resolves | Low | `AuthGate` wraps `FirstLaunchGate` — seed only runs for authenticated user |
| App Check breaks dev emulator | Low | `DebugProvider` for debug builds; env flag to disable |

---

## 8. Success metrics

| Priority | Metric |
|---|---|
| 1 (highest) | Sign-out calls `FirebaseAuth.signOut()` and clears Isar — verified by unit test |
| 1 | Cold start with `kRequireRegisteredAuth=true` shows `AuthLandingScreen`, not app content |
| 2 | Anonymous user registers → uid unchanged in Firebase console |
| 2 | New user creates account → `users/{uid}` Firestore path seeded after first sync |
| 3 | Delete account → Firebase user removed; old credentials rejected |
| 4 | Firestore rules deny unauthorized access (App Check staging) |

---

## 9. Implementation order

```
Phase A  (auth shell)
    ↓
Phase B  (login/signup UI)
    ↓
Phase C  (anonymous linking)    ← can begin after B is stable
Phase D  (account settings)     ← can run in parallel with C (different files)
    ↓
Phase E  (hardening)
```

Recommended cadence: ship A + B together as one PR (core functionality), then C + D as a second PR, then E as a hardening PR before release.
