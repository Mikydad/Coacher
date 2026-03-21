# Error Log

This file tracks implementation/runtime errors encountered during development of `Coach_for_life`, plus the fix and current status.

## 1) Flutter project creation failed (invalid package name)
- **Where**: `flutter create .`
- **Error**: `"Coach_for_life" is not a valid Dart package name`
- **Root cause**: Dart package names must be lowercase with underscores.
- **Fix applied**: Re-ran create with explicit project name:
  - `flutter create --project-name coach_for_life .`
- **Status**: Resolved

## 2) Dependency solver conflict: `isar_generator` vs `build_runner`
- **Where**: `flutter pub get`
- **Error**: Version solving failed due to analyzer/dart_style constraints.
- **Root cause**: `build_runner ^2.6.0` was incompatible with `isar_generator ^3.1.0+1`.
- **Fix applied**: Pinned:
  - `build_runner: ^2.4.13`
- **Status**: Resolved

## 3) Widget test failed after app shell changed
- **Where**: `flutter test`
- **Error**: Expected bootstrap text from old screen; not found.
- **Root cause**: Test assertions referenced old scaffold content.
- **Fix applied**: Updated test to assert current home scaffold content.
- **Status**: Resolved

## 4) Compile error in Home screen (`const` + dynamic interpolation)
- **Where**: `flutter test` compile step
- **Error**: `Not a constant expression` for text using `$doneCount`.
- **Root cause**: Dynamic values were inside a `const` children list.
- **Fix applied**: Removed `const` from that widget list and kept only truly const widgets.
- **Status**: Resolved

## 5) `ProviderScope` missing in widget test
- **Where**: `flutter test`
- **Error**: `Bad state: No ProviderScope found`
- **Root cause**: `ConsumerWidget` screens require Riverpod scope in tests.
- **Fix applied**: Wrapped test app with:
  - `ProviderScope(child: CoachForLifeApp())`
- **Status**: Resolved

## 6) Local notifications API mismatch
- **Where**: `flutter test` compile step
- **Error**: Unknown named parameter `uiLocalNotificationDateInterpretation`
- **Root cause**: Parameter not available in installed plugin API version.
- **Fix applied**: Removed unsupported parameter from `zonedSchedule` call.
- **Status**: Resolved

## 7) iOS white screen on startup (runtime crash)
- **Where**: iOS simulator runtime (`flutter run`)
- **Error**: `IsarError: At least one collection needs to be opened`
- **Root cause**: `Isar.open([])` attempted with zero schemas.
- **Fix applied**: Changed `OfflineStore.initialize()` to defer opening Isar until schemas are added.
- **Status**: Resolved (app startup no longer blocked by this crash)

## 8) Firebase default app not initialized at runtime
- **Where**: Firebase test and AddTask reminder sync calls
- **Error**: `[core/no-app] No Firebase App '[DEFAULT]' has been created`
- **Root cause**: Firestore call executed before Firebase app was initialized on device runtime.
- **Fix applied**:
  - Hardened Firebase initializer with explicit + fallback init attempts.
  - Added runtime initialization guard in Firebase test screen before Firestore access.
- **Status**: Resolved (moved to next-stage permission error)

## 9) Firestore permission denied on test write/read
- **Where**: Firebase test screen button (`diagnostics/firebase_test`)
- **Error**: `[cloud_firestore/permission-denied] The caller does not have permission`
- **Root cause**: Firestore security rules rejected unauthenticated client writes/reads (no `request.auth`).
- **Fix applied**: Enable **Anonymous** sign-in in Firebase Console; use user-scoped rules (`users/{uid}/...` with `request.auth.uid == uid`). See `documentation/firebase-rules.md`.
- **Status**: Resolved

## 10) Firestore composite index required (`failed-precondition`) on routines query
- **Where**: Add Task → `PlanningRepository.getRoutinesForDate` / `ensureDefaultDayPlan`
- **Error**: `[cloud_firestore/failed-precondition] The query requires an index` (composite on `dateKey` + `orderIndex` for collection `routines`).
- **Root cause**: Firestore requires a composite index when combining `where('dateKey', isEqualTo: …)` with `orderBy('orderIndex')`.
- **Fix applied**: Query by `dateKey` only, then sort by `orderIndex` in Dart (`planning_repository.dart`).
- **Status**: Resolved

---

## How to use this log
- Add each new error immediately after it appears.
- Include: **where**, **error text**, **root cause**, **fix**, **status**.
- If an error returns, update status to `Reopened` and append what changed.
