# Tasks: Phase 2 — Identity & Auth Implementation

**PRD:** `tasks/prd-phase2-identity-auth-implementation.md`  
**Branch:** `platform-refactor`  
**Status:** Ready to implement

---

## How to read this file

Tasks are grouped by phase (A → E).  
Within each phase, subtasks are ordered by **dependency** — implement top to bottom.  
A phase must pass `flutter analyze` + its own tests before moving to the next.

---

## Phase A — Auth shell

> Real sign-out, centralized auth state, `AuthGate`, local session wipe policy.  
> **No new UI screens needed (landing is a placeholder). No regression to current anonymous flow.**

---

### T-A1 — `AuthFailure` domain model

**File:** `lib/features/auth/domain/auth_failure.dart`

- [ ] Create directory `lib/features/auth/domain/`
- [ ] Create `lib/features/auth/domain/auth_failure.dart`
  - Sealed class `AuthFailure` with subclasses:
    ```dart
    sealed class AuthFailure {
      const AuthFailure();
    }
    class NetworkFailure extends AuthFailure { const NetworkFailure(); }
    class InvalidCredentials extends AuthFailure { const InvalidCredentials(); }
    class EmailAlreadyInUse extends AuthFailure { const EmailAlreadyInUse(); }
    class WeakPassword extends AuthFailure { const WeakPassword(); }
    class RequiresRecentLogin extends AuthFailure { const RequiresRecentLogin(); }
    class UnknownAuthFailure extends AuthFailure {
      const UnknownAuthFailure(this.message);
      final String message;
    }
    ```
  - No imports required

---

### T-A2 — `AuthRepository`

**File:** `lib/features/auth/application/auth_repository.dart`

- [ ] Create directory `lib/features/auth/application/`
- [ ] Create `auth_repository.dart`
  - Wraps `FirebaseAuth.instance` — no Riverpod imports
  - Properties: `User? get currentUser`, `bool get isSignedIn`, `bool get isAnonymous`
  - Methods (each catches `FirebaseAuthException`, maps to `AuthFailure`):
    - `Stream<User?> authStateChanges()`
    - `Future<void> signOut()` — calls `FirebaseAuth.instance.signOut()`
    - `Future<(AuthFailure?, User?)> signInWithEmail({required String email, required String password})`
    - `Future<(AuthFailure?, User?)> createUserWithEmail({required String email, required String password, String? displayName})`  
      — after creation, calls `user.updateDisplayName(displayName)` if provided
    - `Future<(AuthFailure?, User?)> linkAnonymousWithEmail({required String email, required String password})`  
      — uses `currentUser!.linkWithCredential(EmailAuthProvider.credential(...))`
    - `Future<void> sendPasswordResetEmail(String email)`
    - `Future<AuthFailure?> updatePassword(String newPassword)` — calls `currentUser!.updatePassword`
    - `Future<AuthFailure?> reauthenticate({required String email, required String password})` — `currentUser!.reauthenticateWithCredential`
    - `Future<AuthFailure?> deleteAccount()` — `currentUser!.delete()`
  - Private helper `AuthFailure _mapException(FirebaseAuthException e)`:
    | `e.code` | `AuthFailure` |
    |---|---|
    | `wrong-password`, `user-not-found`, `invalid-credential` | `InvalidCredentials` |
    | `email-already-in-use`, `credential-already-in-use` | `EmailAlreadyInUse` |
    | `weak-password` | `WeakPassword` |
    | `requires-recent-login` | `RequiresRecentLogin` |
    | `network-request-failed` | `NetworkFailure` |
    | anything else | `UnknownAuthFailure(e.message ?? e.code)` |

---

### T-A3 — `AuthSessionPolicy`

**File:** `lib/features/auth/application/auth_session_policy.dart`

- [ ] Create `auth_session_policy.dart`
  - Constants:
    ```dart
    const String kLastSignedInUidPrefsKey = 'last_signed_in_uid';
    const bool kRequireRegisteredAuth = bool.fromEnvironment(
      'REQUIRE_REGISTERED_AUTH',
      defaultValue: false,
    );
    ```
  - Static methods:
    - `Future<String?> getLastSignedInUid()` — `SharedPreferences.getString`
    - `Future<void> persistUid(String uid)` — `SharedPreferences.setString`
    - `Future<bool> hasUidChanged(String newUid)` — compares `newUid` with stored; returns `false` if nothing stored yet (first install)
    - `Future<void> clearLocalSession()`:
      1. `await LocalNotificationsService.instance.cancelAll()`
      2. `await OfflineStore.instance.clearAll()` ← new method, see T-A4
      3. `final p = await SharedPreferences.getInstance()`
      4. `await p.remove('isar_seeded_v1')`
      5. `await p.remove(kLastSignedInUidPrefsKey)`
      6. `await p.remove('notification_task_id_index_v1')`

---

### T-A4 — `OfflineStore.clearAll()`

**File:** `lib/core/offline/offline_store.dart`

- [ ] Add `Future<void> clearAll()` method to `OfflineStore`:
  ```dart
  Future<void> clearAll() async {
    final db = isar;
    if (db == null) return;
    await db.writeTxn(() => db.clear());
    debugPrint('OfflineStore: all collections cleared (sign-out wipe)');
  }
  ```

---

### T-A5 — `AuthProviders`

**File:** `lib/features/auth/application/auth_providers.dart`

- [ ] Create `auth_providers.dart`:
  ```dart
  final authRepositoryProvider = Provider<AuthRepository>(
    (_) => AuthRepository(),
  );

  final authStateProvider = StreamProvider<User?>(
    (ref) => ref.read(authRepositoryProvider).authStateChanges(),
  );
  ```
- [ ] Import `firebase_auth` and the repository

---

### T-A6 — `AuthGate`

**File:** `lib/features/auth/presentation/auth_gate.dart`

- [ ] Create `lib/features/auth/presentation/` directory
- [ ] Create `auth_gate.dart`
  - `ConsumerStatefulWidget` (needs `ref` + `initState` logic)
  - Watches `authStateProvider`
  - In `initState`: listen to `authStateProvider` — when a non-null user arrives:
    1. Check `hasUidChanged(user.uid)`
    2. If changed: `await clearLocalSession()`, then `await SyncService.instance.syncFromRemote(force: true)`
    3. Always: `await AuthSessionPolicy.persistUid(user.uid)`
  - `build` logic:
    ```
    authStateProvider.when(
      loading: → full-screen spinner (Color(0xFF050806) bg + green indicator)
      error:   → same spinner (fail gracefully)
      data: (user) →
        if user != null → widget.child
        else if kRequireRegisteredAuth → AuthLandingScreen()
        else → trigger signInAnonymously(), show spinner while pending
    )
    ```
  - Anonymous sign-in: use a `_signingInAnonymously` bool flag to prevent double calls
  - The spinner matches `FirstLaunchGate` exactly (same colors + "Loading your plan…" text)

---

### T-A7 — `AuthLandingScreen` placeholder

**File:** `lib/features/auth/presentation/auth_landing_screen.dart`

- [ ] Create `auth_landing_screen.dart` — Phase A version is a **placeholder only**:
  - Dark `#050806` background
  - App icon / name at center
  - Text: *"Sign in — available in the next update"* in `#888888`
  - No buttons yet (Phase B fills this in)
  - `static const routeName = '/auth'`

---

### T-A8 — Wire `AuthGate` into `main.dart`

**File:** `lib/main.dart`

- [ ] Add import for `AuthGate`
- [ ] Wrap existing `FirstLaunchGate` subtree:
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

---

### T-A9 — Remove `AuthInitializer` from `AppBootstrap`

**File:** `lib/core/bootstrap/app_bootstrap.dart`

- [ ] Remove `await AuthInitializer.ensureSignedIn()`  
  Anonymous sign-in is now `AuthGate`'s responsibility
- [ ] Remove `import '../firebase/auth_initializer.dart'` (check if unused elsewhere first)
- [ ] Keep `await FirebaseInitializer.initialize()` — Firebase must still init before anything else

---

### T-A10 — Real sign-out in `ProfileScreen`

**File:** `lib/features/profile/presentation/profile_screen.dart`

- [ ] Add imports: `auth_repository.dart`, `auth_session_policy.dart`, `auth_providers.dart`
- [ ] Replace `_signOut()` body:
  ```dart
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ObsidianDialog(
        title: 'Log Out?',
        body: "You'll be signed out on this device. "
              "Your cloud data stays tied to your account.",
        confirmLabel: 'Log Out',
        confirmColor: _kError,
      ),
    );
    if (confirmed != true || !mounted) return;
    await AuthSessionPolicy.clearLocalSession();
    await ref.read(authRepositoryProvider).signOut();
    // AuthGate reacts to authStateChanges → navigates to AuthLandingScreen automatically.
    // No manual Navigator call needed.
  }
  ```
- [ ] **Remove** `if (mounted) Navigator.of(context).popUntil((r) => r.isFirst)` — `AuthGate` handles navigation

---

### T-A11 — Phase A tests

**Files:** `test/features/auth/`

- [ ] Create `test/features/auth/` directory
- [ ] `auth_session_policy_test.dart`:
  - Setup: `SharedPreferences.setMockInitialValues({})`
  - Test: `persistUid('abc')` → `getLastSignedInUid()` returns `'abc'`
  - Test: `hasUidChanged('abc')` when stored is `'abc'` → `false`
  - Test: `hasUidChanged('xyz')` when stored is `'abc'` → `true`
  - Test: `hasUidChanged('abc')` when nothing stored → `false` (first install)
  - Test: `clearLocalSession()` removes `'isar_seeded_v1'` and `kLastSignedInUidPrefsKey` from prefs
    (mock `LocalNotificationsService` + `OfflineStore` — or test only the prefs side)

- [ ] `auth_failure_mapping_test.dart`:
  - Test: each `FirebaseAuthException` code → correct `AuthFailure` subclass
  - Use `FirebaseAuthException(code: '...')` directly (no Firebase init needed)
  - Cover: `wrong-password`, `email-already-in-use`, `weak-password`, `requires-recent-login`, `network-request-failed`, unknown code

---

### T-A12 — Phase A verification

- [ ] `flutter analyze lib/features/auth/ lib/core/offline/offline_store.dart lib/main.dart lib/core/bootstrap/app_bootstrap.dart lib/features/profile/presentation/profile_screen.dart` → zero errors
- [ ] `flutter test test/features/auth/` → all green
- [ ] **Manual smoke test** (flag=false):
  - Cold start → app opens (anonymous sign-in still works)
  - Log out → `FirebaseAuth.currentUser` is null (check with `debugPrint`)
  - Log out → local tasks not visible on next cold start (Isar wiped + no re-seed yet because no network login)

---

## Phase B — Login & sign-up UI

> Full email/password flow. `AuthGate` now routes to real screens. `kRequireRegisteredAuth` can be flipped.

---

### T-B1 — Shared auth widgets

**Files:** `lib/features/auth/presentation/widgets/`

- [ ] Create directory `lib/features/auth/presentation/widgets/`

- [ ] `auth_text_field.dart`
  ```dart
  class AuthTextField extends StatelessWidget {
    const AuthTextField({
      required this.label,
      required this.controller,
      this.obscure = false,
      this.errorText,
      this.keyboardType,
      this.textInputAction,
      this.onSubmitted,
    });
    // Dark fill #1A1A1A, #B2ED00 focused border, 12px radius
    // Shows errorText in red below field when non-null
  }
  ```

- [ ] `auth_primary_button.dart`
  ```dart
  class AuthPrimaryButton extends StatelessWidget {
    const AuthPrimaryButton({
      required this.label,
      required this.onPressed, // null = disabled
      this.isLoading = false,
    });
    // #B2ED00 background, black bold text, full-width
    // CircularProgressIndicator(color: Colors.black) when isLoading
    // Opacity 0.4 when disabled
  }
  ```

- [ ] `auth_error_text.dart` — small widget:
  ```dart
  class AuthErrorText extends StatelessWidget {
    const AuthErrorText(this.message);
    // Color #FF5252, fontSize 13, centered
  }
  ```

---

### T-B2 — `AuthFailure` → human string helper

**File:** `lib/features/auth/domain/auth_failure.dart`

- [ ] Add extension `AuthFailureX` on `AuthFailure`:
  ```dart
  extension AuthFailureX on AuthFailure {
    String toUserMessage() => switch (this) {
      InvalidCredentials() =>
        "That email or password doesn't match. Try again or reset your password.",
      EmailAlreadyInUse() =>
        'An account with this email already exists. Sign in instead.',
      WeakPassword() =>
        'Password must be at least 8 characters.',
      NetworkFailure() =>
        'No internet connection. Check your network and try again.',
      RequiresRecentLogin() =>
        'Please sign in again before making this change.',
      UnknownAuthFailure(:final message) =>
        message.isEmpty ? 'Something went wrong. Please try again.' : message,
    };
  }
  ```

---

### T-B3 — `ForgotPasswordScreen`

**File:** `lib/features/auth/presentation/forgot_password_screen.dart`

- [ ] Build `ForgotPasswordScreen`
  - `static const routeName = '/auth/forgot-password'`
  - Single `AuthTextField` for email
  - `AuthPrimaryButton('Send reset email')`
  - On submit: `await authRepository.sendPasswordResetEmail(email)`
  - Success state: hide form, show *"Check your email — we've sent a password reset link."* + "Back to sign in" `TextButton`
  - Error state: `AuthErrorText` below button (invalid email, network)
  - Loading state: button shows spinner, form disabled

---

### T-B4 — `LoginScreen`

**File:** `lib/features/auth/presentation/login_screen.dart`

- [ ] Build `LoginScreen`
  - `static const routeName = '/auth/login'`
  - Fields: email (`emailAddress` keyboard), password (obscured, `done` action submits)
  - `AuthPrimaryButton('Sign in')`
  - On submit:
    1. Validate non-empty (inline, before network call)
    2. `await authRepository.signInWithEmail(email, password)`
    3. On failure → set `_error` state, show `AuthErrorText`
    4. On success → `AuthGate` reacts reactively, no manual navigation needed
  - Row below button: `"Forgot password?"` text button → `/auth/forgot-password`
  - Row at bottom: `"Don't have an account?  Create one"` → `/auth/sign-up`
  - Loading: button spinner, form disabled

---

### T-B5 — `SignUpScreen`

**File:** `lib/features/auth/presentation/sign_up_screen.dart`

- [ ] Build `SignUpScreen`
  - `static const routeName = '/auth/sign-up'`
  - Fields: display name (optional), email, password, confirm password
  - Client-side validation before submit:
    - password ≥ 8 chars → `AuthErrorText` inline
    - confirm password mismatch → `AuthErrorText` inline
  - ToS checkbox: `"I agree to the Terms of Service"` (placeholder — no link yet). Submission disabled until checked.
  - `AuthPrimaryButton('Create account')`
  - Submit logic:
    ```dart
    final (failure, user) = currentUser?.isAnonymous == true
      ? await authRepository.linkAnonymousWithEmail(email, password)
      : await authRepository.createUserWithEmail(email, password, displayName);
    ```
  - Handle `EmailAlreadyInUse`: show error + "Sign in instead" text button → `/auth/login`
  - Handle `credential-already-in-use` (from link): show dialog (see T-C2)
  - On success → `AuthGate` reacts, no manual navigation
  - "Already have an account? Sign in" link at bottom

---

### T-B6 — Replace `AuthLandingScreen` placeholder with real landing

**File:** `lib/features/auth/presentation/auth_landing_screen.dart`

- [ ] Replace Phase A placeholder with real landing:
  - Full-height `#050806` background, `SafeArea`
  - Top: app logo/icon (`SizedBox` placeholder if no asset yet) + app name *"Coach for Life"* in white bold
  - Center: tagline in `#888888`
  - Bottom section (stuck to safe-area bottom):
    - `AuthPrimaryButton('Sign in')` → `Navigator.pushNamed(context, LoginScreen.routeName)`
    - `SizedBox(height: 12)`
    - Outlined secondary button `"Create account"` → `/auth/sign-up`
    - If `kRequireRegisteredAuth == false`: small text link `"Continue as guest"` that triggers `signInAnonymously()` and shows a spinner

---

### T-B7 — Register routes in `app.dart`

**File:** `lib/app/app.dart`

- [ ] Add imports for all four auth screens
- [ ] Add to `routes` map:
  ```dart
  '/auth':                  (_) => const AuthLandingScreen(),
  '/auth/login':            (_) => const LoginScreen(),
  '/auth/sign-up':          (_) => const SignUpScreen(),
  '/auth/forgot-password':  (_) => const ForgotPasswordScreen(),
  ```

---

### T-B8 — Phase B tests

- [ ] `test/features/auth/login_screen_test.dart`
  - Mock `authRepositoryProvider`
  - Test: submit with empty email/password → validation error shown, no network call
  - Test: mock returns `InvalidCredentials` → `AuthErrorText` appears with correct message
  - Test: loading state → button shows spinner + is disabled

- [ ] `test/features/auth/sign_up_screen_test.dart`
  - Test: password < 8 chars → inline error before submit
  - Test: confirm password mismatch → inline error before submit
  - Test: mock returns `EmailAlreadyInUse` → correct error shown
  - Test: ToS unchecked → submit button disabled

---

### T-B9 — Phase B verification

- [ ] `flutter analyze lib/features/auth/` → zero errors
- [ ] `flutter test test/features/auth/` → all green
- [ ] **Manual smoke test:**
  - Create new account with email → lands on Home
  - Sign out → `AuthLandingScreen` shown
  - Sign back in → same data
  - Wrong password → inline error, no crash
  - Password reset email sends (Firebase test project)

---

## Phase C — Anonymous account linking

> Users who used the app anonymously keep their Firebase uid when they register.

---

### T-C1 — `linkAnonymousWithEmail` path in `SignUpScreen`

Already scaffolded in T-B5. Activate the real path:

- [ ] Verify `authRepository.linkAnonymousWithEmail` is called when `currentUser?.isAnonymous == true`
- [ ] On link success: uid is unchanged — add `debugPrint('[Auth] anonymous linked: uid=${user?.uid}')` to confirm
- [ ] Write integration comment: *"Firestore data at users/{uid} is preserved — no migration needed."*

---

### T-C2 — Handle `credential-already-in-use` in `SignUpScreen`

**File:** `lib/features/auth/presentation/sign_up_screen.dart`

- [ ] Detect when `linkAnonymousWithEmail` returns `EmailAlreadyInUse` failure
- [ ] Show `AlertDialog`:
  - Title: *"Account already exists"*
  - Body: *"An account with this email already exists. Sign in to it instead? Your offline guest data won't be merged automatically."*
  - Actions: `"Cancel"` (dismiss) and `"Sign in instead"` (→ pop to `/auth/login` with email pre-filled)
- [ ] Pre-fill `LoginScreen` email if routing there from this dialog (pass via route arguments)

---

### T-C3 — Anonymous migration banner

**File:** `lib/features/auth/presentation/auth_landing_screen.dart`

- [ ] Add banner at top of landing screen when user is anonymous:
  ```dart
  if (ref.watch(authStateProvider).valueOrNull?.isAnonymous == true)
    _MigrationBanner()
  ```
  - Banner text: *"Create an account to save your progress across devices."*
  - CTA: *"Create account"* → `/auth/sign-up`
  - Dismissible: store `auth_migration_banner_dismissed` in prefs; hide once dismissed

---

### T-C4 — Phase C tests

- [ ] `test/features/auth/auth_repository_test.dart` additions:
  - Test: `linkAnonymousWithEmail` on a mock anonymous user → calls `linkWithCredential`
  - Test: when `linkWithCredential` throws `credential-already-in-use` → returns `EmailAlreadyInUse` failure

---

### T-C5 — Phase C verification

- [ ] **Manual test:**
  - Sign in anonymously → create a task → force sync
  - Open sign-up → enter email/password → confirm "link" path taken (uid unchanged in debugPrint)
  - Sign out → sign back in with email → same uid → same Firestore data visible after sync

---

## Phase D — Account settings

> Wire the placeholder rows on `AccountSettingsScreen`.

---

### T-D1 — `ChangePasswordScreen`

**File:** `lib/features/auth/presentation/change_password_screen.dart`

- [ ] Create `ChangePasswordScreen`
  - `static const routeName = '/auth/change-password'`
  - Fields: current password, new password (≥ 8), confirm new password
  - Submit:
    1. `await authRepository.reauthenticate(email: currentUser.email!, password: currentPassword)`
    2. On `RequiresRecentLogin` or `InvalidCredentials` → show error
    3. On success: `await authRepository.updatePassword(newPassword)`
    4. On success: show snackbar *"Password updated."* + pop screen
  - Only navigable for email-provider users (`currentUser.providerData.any(p => p.providerId == 'password')`)

---

### T-D2 — `AccountSettingsScreen` — wire rows

**File:** `lib/features/settings/presentation/account_settings_screen.dart`

- [ ] Convert to `ConsumerWidget` (needs `ref` for `authRepositoryProvider`)
- [ ] Add imports for `AuthRepository`, `auth_providers.dart`
- [ ] **Change password** row:
  - Replace `SettingsPlaceholderRow` with a real tappable row
  - `Navigator.pushNamed(context, ChangePasswordScreen.routeName)`
  - Only visible if email provider: `ref.read(authStateProvider).valueOrNull?.providerData.any(...) == true`
- [ ] **Delete account** row:
  - Step 1 dialog: `"This permanently deletes your account and cannot be undone. Type DELETE to confirm."`
    - `TextField` inside dialog; submit only enabled when text == `'DELETE'`
  - Step 2 dialog: re-auth — email + password fields inline
  - On re-auth success: `await authRepository.deleteAccount()` → `await AuthSessionPolicy.clearLocalSession()`
  - `AuthGate` reacts → `AuthLandingScreen` shown
- [ ] **Export my data** row:
  - Collect Isar data: tasks, goals, reminders → encode to JSON
  - Add `share_plus` dependency: `flutter pub add share_plus`
  - `Share.shareXFiles([XFile.fromData(jsonBytes, mimeType: 'application/json')], fileNameOverrides: ['coach_export_$date.json'])`
- [ ] **Forgot password** deep link:
  - Replace placeholder with `Navigator.pushNamed(context, ForgotPasswordScreen.routeName)`
- [ ] **Two-factor authentication** and **Privacy preferences** rows:
  - Keep as `SettingsPlaceholderRow` (no change — they are explicitly Phase E non-goals)
- [ ] Register route in `app.dart`: `'/auth/change-password': (_) => const ChangePasswordScreen()`

---

### T-D3 — Phase D verification

- [ ] Change password: new password works on next sign-in
- [ ] Delete account: user gone from Firebase console; old credentials rejected; `AuthLandingScreen` shown
- [ ] Export: JSON file produced and shareable on device

---

## Phase E — Hardening

> Security, observability, and production readiness. Can run in parallel with C/D.

---

### T-E1 — Firestore rules audit

**File:** `documentation/firebase-rules.md`

- [ ] Review all paths in `lib/core/firebase/firestore_paths.dart`
  - `users/{uid}/**` — covered by existing user-scoped rule ✅
  - `circles/**` — community paths — verify `request.auth != null` guard on each:
    - `circles/{circleId}` read/write
    - `circles/{circleId}/members/{userId}` — write only by `request.auth.uid == userId`
    - `circles/{circleId}/messages` — write by authenticated members only
    - `circles/{circleId}/activityFeed` — write by authenticated members
    - `users/{uid}/circleIds` — write only by `request.auth.uid == uid`
- [ ] Update `documentation/firebase-rules.md` with final audited rule set
- [ ] Note Firestore orphan cleanup needed on account delete (manual/script)

---

### T-E2 — Structured auth logging

**File:** `lib/features/auth/application/auth_repository.dart`

- [ ] Add `debugPrint('[Auth] ...')` tags at each failure path with format:
  ```
  [Auth] signInWithEmail failed: code=wrong-password uid_prefix=abcd1234
  ```
- [ ] Never log passwords, full UIDs, or tokens

---

### T-E3 — Email verification banner (optional gate)

- [ ] After `createUserWithEmail` success: call `FirebaseAuth.instance.currentUser?.sendEmailVerification()`
- [ ] In `MainTabShell` (or `HomeScreen`), show non-blocking top banner:
  - Condition: `user?.emailVerified == false && !(user?.isAnonymous ?? true)`
  - Text: *"Verify your email to unlock all features."* + "Resend" action
  - "Resend" calls `user.sendEmailVerification()`
  - Dismissible for 24h (store dismiss timestamp in prefs)

---

### T-E4 — Phase E verification

- [ ] `flutter analyze lib/` → zero errors in auth module and all modified files
- [ ] `flutter test test/features/auth/` → all green
- [ ] Manual QA checklist:
  - [ ] Anonymous → register → uid unchanged in Firebase console
  - [ ] Logout → relaunch → auth gate shown (not app content)
  - [ ] Login → data sync → correct data loaded
  - [ ] Wrong password → inline error
  - [ ] Delete account → gone from console

---

## Full task checklist (quick reference)

### Phase A
- [ ] T-A1 `AuthFailure` sealed class
- [ ] T-A2 `AuthRepository`
- [ ] T-A3 `AuthSessionPolicy`
- [ ] T-A4 `OfflineStore.clearAll()`
- [ ] T-A5 `AuthProviders`
- [ ] T-A6 `AuthGate`
- [ ] T-A7 `AuthLandingScreen` placeholder
- [ ] T-A8 Wire `AuthGate` in `main.dart`
- [ ] T-A9 Remove `AuthInitializer` from `AppBootstrap`
- [ ] T-A10 Real sign-out in `ProfileScreen`
- [ ] T-A11 Phase A tests
- [ ] T-A12 Phase A verification

### Phase B
- [ ] T-B1 Shared auth widgets
- [ ] T-B2 `AuthFailure.toUserMessage()` extension
- [ ] T-B3 `ForgotPasswordScreen`
- [ ] T-B4 `LoginScreen`
- [ ] T-B5 `SignUpScreen`
- [ ] T-B6 Real `AuthLandingScreen`
- [ ] T-B7 Register routes
- [ ] T-B8 Phase B tests
- [ ] T-B9 Phase B verification

### Phase C
- [ ] T-C1 Anonymous link path in `SignUpScreen`
- [ ] T-C2 `credential-already-in-use` dialog
- [ ] T-C3 Migration banner on landing
- [ ] T-C4 Phase C tests
- [ ] T-C5 Phase C verification

### Phase D
- [ ] T-D1 `ChangePasswordScreen`
- [ ] T-D2 Wire `AccountSettingsScreen` rows
- [ ] T-D3 Phase D verification

### Phase E
- [ ] T-E1 Firestore rules audit
- [ ] T-E2 Structured auth logging
- [ ] T-E3 Email verification banner
- [ ] T-E4 Phase E verification

---

## Dependency order summary

```
T-A1 (AuthFailure)
    ↓
T-A2 (AuthRepository)   T-A3 (AuthSessionPolicy)
         ↓                        ↓
    T-A4 (OfflineStore.clearAll)  ←────────────┐
         ↓                                     │
    T-A5 (Providers)                           │
         ↓                                     │
    T-A6 (AuthGate) ─── T-A7 (Landing placeholder)
         ↓
    T-A8 (main.dart) + T-A9 (Bootstrap) + T-A10 (Profile signout)
         ↓
    T-A11 (Tests) → T-A12 (Verify Phase A)
         ↓
    T-B1 (Widgets) + T-B2 (Error strings)
         ↓
    T-B3 (Forgot PW) → T-B4 (Login) → T-B5 (SignUp)
         ↓
    T-B6 (Real Landing) → T-B7 (Routes)
         ↓
    T-B8 (Tests) → T-B9 (Verify Phase B)
         ↓
    T-C1 + T-C2 + T-C3          T-D1 + T-D2
         ↓                            ↓
    T-C4 → T-C5               T-D3 (Verify D)
         ↓
    T-E1 + T-E2 + T-E3
         ↓
    T-E4 (Verify E)
```
