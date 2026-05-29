# PRD: Real Accounts — Auth Phases A–E

**Status:** Draft  
**Author:** AI  
**Target:** Replace anonymous-only V1 auth with sign-up, login, logout, account linking, and production hardening  
**Related:** `documentation/firebase-rules.md`, `documentation/future_todo.md` (Security), `lib/core/firebase/auth_initializer.dart`

---

## 1. Background

### 1.1 Current behavior (as of main)

| Area | Today |
|------|--------|
| **Sign-in** | `AuthInitializer.ensureSignedIn()` in `AppBootstrap` calls `FirebaseAuth.signInAnonymously()` if no session exists. |
| **UI** | No login, sign-up, or forgot-password screens. App launches straight into `FirstLaunchGate` → `CoachForLifeApp` (`MainTabShell`). |
| **Logout** | Profile **Log Out** shows a dialog then `Navigator.popUntil((r) => r.isFirst)` only — **no** `FirebaseAuth.signOut()`. |
| **Identity** | Display name from Isar `UserProfilePreference`; community bridges use `FirebaseAuth.currentUser?.displayName ?? 'User'`. |
| **Cloud paths** | `FirestorePaths.userRoot` → `users/{uid}/...` when Firebase is initialized. |
| **Local DB** | Single Isar file `coach_isar` on device — **not** partitioned by `uid`. |
| **Account settings** | `AccountSettingsScreen` has placeholder rows (password, 2FA, export, delete) with “coming soon” snackbars. |
| **Dependencies** | `firebase_auth: ^5.7.0` only — no `google_sign_in` / `sign_in_with_apple` yet. |

### 1.2 Why change

- Anonymous UIDs change on reinstall → cloud data under old UID is effectively lost unless linked.
- “Log out” does not end the Firebase session or protect shared devices.
- Product expectation: email (and optionally Apple/Google), password reset, and real account management on `AccountSettingsScreen`.
- Community, circles, and sync already assume `request.auth.uid`; real auth completes that model.

### 1.3 Design principles

1. **Local-first preserved** — Isar remains source of truth on device; Firestore sync continues under `users/{uid}`.
2. **Link, don’t orphan** — Prefer upgrading anonymous → registered on the **same** Firebase `uid` when possible.
3. **Explicit local policy on uid change** — Never show User B’s cached Isar data after User A without a defined wipe or partition strategy.
4. **Incremental delivery** — Each phase ships a testable vertical slice; anonymous can remain behind a flag until Phase B is stable.

---

## 2. Goals

- Phase **A:** Auth state in the app, real sign-out, optional gate (no new providers).
- Phase **B:** Sign-up / login UI (email + password minimum); post-auth bootstrap unchanged in spirit.
- Phase **C:** Anonymous → registered **account linking** so existing Firestore/Isar investment survives first registration.
- Phase **D:** Wire `AccountSettingsScreen` (password, export stub progression, delete account).
- Phase **E:** App Check, rules audit, observability, and auth/sync integration tests.

## 3. Non-Goals (all phases)

- Social login for every possible provider in V1 of Phase B (prioritize email; Apple/Google as stretch in B or C).
- Server-side Cloud Functions for auth (client-only Firebase Auth unless a gap forces Functions).
- Multi-profile / family accounts on one device.
- Migrating legacy `AppConfig.localUserId` cloud data (test-only path).
- Changing Home app bar (settings gear already removed; Profile remains settings hub).

---

## 4. Architecture decisions (locked for implementation)

### AD-1: Auth gate placement

```
main()
  → WidgetsFlutterBinding
  → ProviderContainer
  → AppBootstrap.initialize()          // Firebase init; see AD-2
  → runApp(AuthGate → FirstLaunchGate → AppLifecycle… → CoachForLifeApp)
```

- **`AuthGate`** listens to `FirebaseAuth.authStateChanges()` (via Riverpod).
- **Signed out:** show `AuthLandingScreen` (login / sign-up entry).
- **Signed in:** show existing app subtree.

`FirstLaunchGate` stays **inside** the signed-in branch so seed/sync only runs for authenticated users.

### AD-2: Bootstrap vs anonymous sign-in

| Build / flag | Behavior |
|--------------|----------|
| `kRequireRegisteredAuth == false` (dev / transition) | After Firebase init, if no user: `signInAnonymously()` (current behavior) until user explicitly registers. |
| `kRequireRegisteredAuth == true` (production target) | **Do not** auto-anonymous on cold start; `AuthGate` shows login until `signInWith*` succeeds. |

Phase A introduces the flag; Phase B flips production default to `true` when login ships.

### AD-3: Local data on sign-out / uid change

**Default policy (recommended):**

| Event | Action |
|-------|--------|
| **Sign out** | `FirebaseAuth.signOut()` → clear Isar (all user collections) → clear `SharedPreferences` keys: `isar_seeded_v1`, pending notification intent, coaching notification budget if stored → cancel scheduled local notifications → navigate to `AuthLandingScreen`. |
| **Sign in** (uid ≠ last stored uid) | Same local wipe **before** `syncFromRemote(force: true)` for new uid. |
| **Sign in** (same uid as last session) | Keep Isar; run debounced sync. |

Persist `last_signed_in_uid` in `SharedPreferences` to detect uid changes.

**Alternative (deferred):** per-uid Isar database name `coach_isar_$uid` — more complex, better for “quick account switch” later. Not V1 unless product insists.

### AD-4: Account linking (Phase C)

When `currentUser.isAnonymous == true` and user completes email registration:

1. `EmailAuthProvider.credential(email, password)`
2. `currentUser.linkWithCredential(credential)` (handle `credential-already-in-use` → sign-in flow + merge policy doc)

Do **not** `createUserWithEmailAndPassword` on a fresh auth instance without linking if an anonymous session already holds data.

### AD-5: Routing

Continue `MaterialApp.routes` / `pushNamed` (no go_router in this PRD). New routes:

| Route | Screen |
|-------|--------|
| `/auth` | `AuthLandingScreen` |
| `/auth/login` | `LoginScreen` |
| `/auth/sign-up` | `SignUpScreen` |
| `/auth/forgot-password` | `ForgotPasswordScreen` |

Existing `/settings/account` unchanged; gains real actions in Phase D.

### AD-6: New module layout

```
lib/features/auth/
  application/
    auth_repository.dart
    auth_providers.dart
    auth_session_policy.dart      // wipe local, last uid
  domain/
    auth_failure.dart
  presentation/
    auth_gate.dart
    auth_landing_screen.dart
    login_screen.dart
    sign_up_screen.dart
    forgot_password_screen.dart
    widgets/
```

---

## 5. Firebase Console & rules (cross-phase)

### 5.1 Providers (enable before Phase B QA)

| Provider | When | Notes |
|----------|------|-------|
| Anonymous | Already | Keep enabled during transition; optional disable in prod after C. |
| Email/Password | Phase B | Required for MVP login. |
| Apple | Phase B stretch / C | Required for App Store if other third-party login exists. |
| Google | Phase B stretch / C | Android + optional iOS. |

### 5.2 Firestore rules

Keep user-scoped rule (see `documentation/firebase-rules.md`):

```txt
match /users/{uid}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

Before Phase E: audit **all** collections (circles, activity feed, storage) for paths outside `users/{uid}` and add explicit matches.

### 5.3 Storage rules (community proofs)

Align Firebase Storage paths with `request.auth.uid` — verify `circle_proof_storage` error messages match real auth states.

---

## Phase A — Auth shell (no new identity providers)

**Objective:** Centralize auth state, implement real sign-out + local session policy, prepare `AuthGate` without forcing login yet.

### A.1 Functional requirements

| ID | Requirement |
|----|-------------|
| FR-A-01 | `AuthRepository` wraps `FirebaseAuth`: `authStateChanges`, `currentUser`, `signOut()`. |
| FR-A-02 | `authStateProvider` = `StreamProvider<User?>` for UI. |
| FR-A-03 | `AuthSessionPolicy.clearLocalSession()` clears Isar, relevant prefs, cancels notifications (reuse bootstrap cancel hooks where they exist). |
| FR-A-04 | Profile `_signOut()` calls `signOut()` + `clearLocalSession()` + reset navigation to auth or root per AD-3. |
| FR-A-05 | `AuthGate` widget: if `user == null` and `kRequireRegisteredAuth` → landing placeholder (“Sign in — coming in next release”) **or** anonymous sign-in when flag false. |
| FR-A-06 | `AppBootstrap`: move `AuthInitializer.ensureSignedIn()` behind flag — when `kRequireRegisteredAuth`, skip anonymous auto sign-in. |
| FR-A-07 | Store `last_signed_in_uid` on successful session; on uid change, run wipe before sync (hook in `AuthGate` or `SyncService`). |

### A.2 Files to touch

| File | Change |
|------|--------|
| `lib/features/auth/...` | New module (see AD-6). |
| `lib/main.dart` | Wrap app with `AuthGate`. |
| `lib/core/bootstrap/app_bootstrap.dart` | Conditional anonymous sign-in. |
| `lib/features/profile/presentation/profile_screen.dart` | Real sign-out. |
| `lib/core/config/app_config.dart` | `kRequireRegisteredAuth` default `false`. |

### A.3 Acceptance criteria

- [ ] Log out clears Firebase session (verify in Firebase debug / `currentUser == null`).
- [ ] After log out, local tasks/goals not visible until next sign-in + sync (with wipe policy).
- [ ] Cold start with flag `false`: app still opens (anonymous) without regression.
- [ ] Unit tests: `AuthSessionPolicy` uid-change detection; mock `AuthRepository`.

### A.4 Risks

- Wipe too aggressive → user surprise. Mitigation: dialog copy on logout explaining local data is cleared on this device.

---

## Phase B — Login & sign-up UI

**Objective:** Email/password registration and login; gate app behind auth when flag true.

### B.1 Functional requirements

| ID | Requirement |
|----|-------------|
| FR-B-01 | `AuthLandingScreen`: primary CTA “Sign in”, secondary “Create account”. |
| FR-B-02 | `LoginScreen`: email, password, submit, link to forgot password & sign up. |
| FR-B-03 | `SignUpScreen`: email, password, confirm password, display name (optional), ToS checkbox (placeholder text OK). |
| FR-B-04 | `ForgotPasswordScreen`: email → `sendPasswordResetEmail`. |
| FR-B-05 | Map `FirebaseAuthException` codes to user-readable errors (`wrong-password`, `email-already-in-use`, `weak-password`, `network-request-failed`). |
| FR-B-06 | On successful `createUserWithEmailAndPassword` or `signInWithEmailAndPassword`: update `last_signed_in_uid`, run uid-change policy, `FirstLaunchGate` seed if needed, enter `MainTabShell`. |
| FR-B-07 | Set `kRequireRegisteredAuth = true` for release flavor (or `--dart-define`). |
| FR-B-08 | Optional: update Firebase `displayName` from sign-up name; still keep Isar `UserProfilePreference.displayName` as UI source unless product merges later. |

### B.2 UI / UX (Obsidian Pulse)

- Reuse tokens from Profile / `settings_page_scaffold.dart` (`#0E0E0E` surface, `#B2ED00` accent).
- Full-screen auth flows with back navigation to landing.
- Loading state on submit; disable double-tap.

### B.3 Dependencies

```yaml
# pubspec.yaml — Phase B minimum
firebase_auth: ^5.7.0  # existing
# Optional Phase B stretch:
# google_sign_in: ...
# sign_in_with_apple: ...
```

### B.4 Files to touch

| File | Change |
|------|--------|
| `lib/features/auth/presentation/*` | Screens |
| `lib/app/app.dart` | Register auth routes |
| `lib/core/config/app_config.dart` | Release flag |
| `test/features/auth/` | Widget tests for validation + error mapping |

### B.5 Acceptance criteria

- [ ] New user can create account and land on Home with empty or synced remote data.
- [ ] Returning user can sign in on second launch without anonymous re-creation.
- [ ] Invalid credentials show inline error, no crash.
- [ ] Password reset email sends (test with Firebase test project).

### B.6 Non-goals for B

- Apple/Google (document as B+ or C).
- Email verification gate (can add in E: `sendEmailVerification` + banner).

---

## Phase C — Anonymous account linking

**Objective:** Users who used the app before registration keep the same Firebase `uid` and `users/{uid}` Firestore tree.

### C.1 Functional requirements

| ID | Requirement |
|----|-------------|
| FR-C-01 | On `SignUpScreen`, if `currentUser?.isAnonymous == true`, use `linkWithCredential` instead of `createUserWithEmailAndPassword`. |
| FR-C-02 | On link success: prompt to set password/email already set; optional `updateEmail` if needed. |
| FR-C-03 | Handle `credential-already-in-use`: offer “Sign in to existing account” — on success, define **merge policy** (see C.3). |
| FR-C-04 | First-launch anonymous users see banner on auth landing: “Create an account to save progress across devices.” |
| FR-C-05 | After linked registration, flip `isAnonymous` false; sync continues same `FirestorePaths.userRoot`. |

### C.2 Merge policy (credential already in use)

**V1 (simple):** If email exists on another account, sign in to that account → **wipe local** → `syncFromRemote` for that uid. Show copy: “Signed in to your existing account. This device’s offline data from guest mode won’t be merged automatically.”

**V2 (future):** Cloud Function or client batch copy from `users/{anonymousUid}` → `users/{registeredUid}` with admin SDK — out of scope unless product requires silent merge.

### C.3 Acceptance criteria

- [ ] Anonymous user with goals in Firestore registers with email → same uid in Firebase console → goals still at `users/{sameUid}/goals`.
- [ ] Reinstall + login with email retrieves cloud data (no dependence on anonymous session persistence).
- [ ] Integration test: anonymous sign-in → create goal locally → sync → link email → uid unchanged.

### C.4 Files to touch

| File | Change |
|------|--------|
| `lib/features/auth/application/auth_repository.dart` | `linkAnonymousWithEmail`, `signInWithEmail` |
| `lib/features/auth/presentation/sign_up_screen.dart` | Branch on `isAnonymous` |
| `documentation/future_todo.md` | Mark linking item done when C ships |

---

## Phase D — Account settings (password, export, delete)

**Objective:** Replace placeholders on `AccountSettingsScreen` with real flows where Firebase supports them.

### D.1 Functional requirements

| ID | Requirement |
|----|-------------|
| FR-D-01 | **Change password:** requires recent login; if `requires-recent-login`, show re-auth dialog (email + password) then `updatePassword`. |
| FR-D-02 | **Forgot password** deep link from account screen → `ForgotPasswordScreen`. |
| FR-D-03 | **Two-factor authentication:** remain “Coming soon” **or** hide row until provider supports MFA — do not half-implement. |
| FR-D-04 | **Export data:** V1 = export Isar + prefs JSON to share sheet / files (no Cloud Function). Update placeholder to real export or keep snackbar with date. |
| FR-D-05 | **Delete account:** confirmation (type “DELETE”) → re-auth → `currentUser.delete()` → `clearLocalSession()` → auth landing. Document Firestore orphan cleanup (manual/script in Firebase console for V1). |
| FR-D-06 | **Privacy preferences:** placeholder OK for V1. |

### D.2 Sign-out vs delete

| Action | Firebase | Local |
|--------|----------|-------|
| Log out (Profile) | `signOut()` | Wipe per AD-3 |
| Delete account | `user.delete()` | Wipe + no return |

### D.3 Acceptance criteria

- [ ] User can change password when logged in with email provider.
- [ ] Delete account removes Firebase user; app shows login; cannot sign in with old password.
- [ ] Export produces a readable file on device (smoke test).

### D.4 Files to touch

| File | Change |
|------|--------|
| `lib/features/settings/presentation/account_settings_screen.dart` | Wire rows |
| `lib/features/auth/application/auth_repository.dart` | `updatePassword`, `reauthenticate`, `deleteAccount` |

---

## Phase E — Hardening & production readiness

**Objective:** Reduce abuse risk, improve debuggability, lock rules and tests.

### E.1 Functional requirements

| ID | Requirement |
|----|-------------|
| FR-E-01 | Enable **Firebase App Check** (Play Integrity / App Attest / debug provider for dev). |
| FR-E-02 | Firestore rules review: all collections used by app; deny by default outside `users/{uid}` and documented shared paths (circles). |
| FR-E-03 | Optional: **email verification** — banner on Home until `emailVerified`; block community post if unverified (product choice). |
| FR-E-04 | Structured logging for auth failures (no passwords in logs). |
| FR-E-05 | Integration tests: auth gate, login, logout wipe, link anonymous (emulator). |
| FR-E-06 | Disable anonymous provider in Firebase Console for production project (after C + migration window). |
| FR-E-07 | Update `documentation/firebase-rules.md` and README auth section. |

### E.2 Acceptance criteria

- [ ] App Check enforced on Firestore in staging without breaking dev emulators.
- [ ] CI runs auth emulator tests (or documented manual QA checklist).
- [ ] Security review checklist completed (see §8).

---

## 6. Data model & sync interaction

### 6.1 Unaffected by auth (stay as-is)

- Isar schemas, LWW merge, `SyncService`, `RemoteIsarMerge` — still pull `FirestorePaths` for current uid.
- `UserProfilePreference`, `UserCoachingProfile`, coaching style — remain Isar; consider adding `ownerUid` field later if multi-account without wipe is needed.

### 6.2 Must align with auth

| Component | Alignment |
|-----------|-----------|
| `CircleActivityBridgeService` | `currentUserId` must be non-empty registered uid. |
| `Community` screens | Guard when `currentUser == null`; show “Sign in to join circles”. |
| `FirstLaunchGate` | Only after auth; reset `isar_seeded_v1` on uid wipe. |
| `Firebase test screen` | Keep for dev; call same `AuthRepository`. |

---

## 7. User-facing copy (draft)

| Moment | Copy |
|--------|------|
| Log out confirm | “You’ll be signed out on this device. Local data here will be cleared; your cloud data stays tied to your account.” |
| Sign up success | “Account created. Syncing your plan…” |
| Link from anonymous | “Save your progress — create an account with email.” |
| Wrong password | “That email or password doesn’t match. Try again or reset your password.” |
| Delete account | “This permanently deletes your account and cannot be undone.” |

---

## 8. Security checklist (Phase E)

- [ ] No API keys in repo; use `firebase_options.dart` / CI secrets.
- [ ] Password fields obscured; no logging of credentials.
- [ ] Re-auth before password change and account delete.
- [ ] Rate limiting understood (Firebase built-in).
- [ ] App Check on production Firebase project.
- [ ] Rules deny global read/write.

---

## 9. Test plan summary

| Phase | Automated | Manual |
|-------|-----------|--------|
| A | `AuthSessionPolicy` unit tests | Log out → relaunch → data state |
| B | Login/sign-up widget tests | Email create, login, reset password |
| C | Emulator: anonymous + link | Same uid in console after register |
| D | — | Change password, delete test user |
| E | Emulator integration | App Check staging build |

**Firebase Auth Emulator** recommended for B/C/E CI (`firebase emulators:start --only auth,firestore`).

---

## 10. Implementation order & estimates

| Phase | Depends on | Rough effort |
|-------|------------|--------------|
| A | — | 2–3 days |
| B | A | 4–6 days |
| C | B | 3–4 days |
| D | B | 3–4 days |
| E | B, C, D | 3–5 days |

Phases **D** and **C** can overlap after B is stable (different files).

---

## 11. Open questions (product)

1. **Log out wipes local data** — acceptable for V1, or require “Keep offline copy” option?
2. **Email verification** required before using Coach AI / Community?
3. **Apple/Google** in Phase B or C?
4. **Guest mode** — keep anonymous indefinitely for try-before-buy, or hard gate at install?

---

## 12. Task breakdown (for `tasks/tasks-prd-auth-*.md`)

When implementation starts, generate:

- `tasks/tasks-prd-auth-phase-a.md`
- `tasks/tasks-prd-auth-phase-b.md`
- `tasks/tasks-prd-auth-phase-c.md`
- `tasks/tasks-prd-auth-phase-d.md`
- `tasks/tasks-prd-auth-phase-e.md`

Each should reference this PRD section and list checkboxes mapped to FR IDs above.

---

## 13. References (code)

| Topic | Path |
|-------|------|
| Anonymous sign-in | `lib/core/firebase/auth_initializer.dart` |
| Bootstrap | `lib/core/bootstrap/app_bootstrap.dart` |
| Firestore uid | `lib/core/firebase/firestore_paths.dart` |
| Profile logout (current) | `lib/features/profile/presentation/profile_screen.dart` |
| Account placeholders | `lib/features/settings/presentation/account_settings_screen.dart` |
| First seed gate | `lib/app/first_launch_gate.dart` |
| Local DB | `lib/core/offline/offline_store.dart` |
| Future security note | `documentation/future_todo.md` |
