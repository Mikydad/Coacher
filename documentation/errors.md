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

## 11) Notification tap only resumes app (no Focus / wrong timing)
- **Where**: iOS device or simulator; cold start or background.
- **Error / symptom**: App comes to foreground but Dart never logs handling of the tap; or navigator pushes fail silently because `Navigator` is not ready.
- **Root cause**: (1) Pending route not replayed after first frame / after seed gate. (2) On iOS, `UNUserNotificationCenter` delegate not set, so interaction callbacks do not reach the expected pipeline. (3) Launch notification response consumed too late or not correlated with `taskId`.
- **Fix applied**:
  - Queue **pending notification intent** in `SharedPreferences` and **`flushPendingNotificationNavigationIntent()`** from lifecycle, bootstrap, and `FirstLaunchGate` when the UI is ready (`lib/app/notification_response_handler.dart`, `lib/app/app_lifecycle_task_refresh.dart`, `lib/app/first_launch_gate.dart`).
  - **Early drain** of launch notification response after plugin init (`lib/core/bootstrap/app_bootstrap.dart`, `lib/core/notifications/local_notifications_service.dart`).
  - Persist **`notification_task_id_index_v1`** (`notificationId` → `taskId`) on schedule/cancel.
  - iOS: set **`UNUserNotificationCenter.current().delegate`** in `AppDelegate` (`ios/Runner/AppDelegate.swift`).
- **Status**: Resolved (reopen if a specific iOS version or notification category still skips Dart)

## 12) Unknown task id when handling `NotificationResponse`
- **Where**: `notification_response_handler` / reminder lookup.
- **Error / symptom**: Tap handled but cannot resolve which task to open.
- **Root cause**: Plugin provides `id` (notification id) but payload parsing alone is insufficient; legacy reminder scans miss edge cases.
- **Fix applied**: Maintain persisted map in `LocalNotificationsService` (`notification_task_id_index_v1`); handler uses **`taskIdForNotificationId`** before falling back to legacy scan.
- **Status**: Resolved

## 13) VM tests: Firestore paths without Firebase init
- **Where**: `flutter test` for repositories using `FirestorePaths`.
- **Error / symptom**: Firebase default app errors or inconsistent `users/...` paths.
- **Root cause**: `Firebase.apps` empty in VM tests.
- **Fix applied**: `FirestorePaths._activeUid` falls back to **`AppConfig.localUserId`** when no Firebase app exists (`lib/core/firebase/firestore_paths.dart`).
- **Status**: Resolved

## 14) VM tests: `SyncService` queue persistence / `path_provider`
- **Where**: Isar repository tests, stream provider tests.
- **Error / symptom**: Test failures or flakes when sync queue writes to disk.
- **Root cause**: Queue persistence uses app directories not set up in lightweight VM tests.
- **Fix applied**: **`SyncService.debugSkipQueuePersistenceForTests`** toggled in test `setUp`/`tearDown` where appropriate.
- **Status**: Resolved

## 15) Isar native library / test runner download
- **Where**: `flutter test` on clean machine or CI.
- **Error / symptom**: Isar core download blocked or tests fail to open Isar.
- **Root cause**: Headless/test binding may restrict network; Isar needs native `libisar` available.
- **Fix applied**: Documented in `documentation/isar-local-first-and-notification-routing.md` (section 4); repo-root **`libisar.dylib`** is gitignored; use Isar’s recommended test initialization for your environment.
- **Status**: Documented / environment-dependent

## 16) Task checkbox “does nothing” — Firestore composite index (`failed-precondition`)
- **Where**: Home task checkbox → `_completeTaskFromHome` → `FirestoreExecutionRepository.getSessionsForTask` (`lib/features/execution/data/execution_repository.dart`).
- **Error / symptom**: Tapping a task checkbox appeared to do nothing (no rating card). Terminal showed `[cloud_firestore/failed-precondition] The query requires an index` (composite on `targetType` + `taskId` + `startedAtMs` for `timerSessions`).
- **Root cause**: Combining two equality filters with `orderBy('startedAtMs')` needs a composite index that was never created. The thrown exception killed the completion flow before the score card could open, so the checkbox looked dead.
- **Fix applied**: Removed `orderBy`, sort client-side; wrapped the fetch in try/catch so a failure degrades to “no sessions” instead of aborting (`execution_repository.dart`, `home_screen.dart`).
- **Status**: Resolved. See `documentation/2026-07_features_fixes_and_incidents.md` §4a.

## 17) Circle chat image upload `unauthorized` + images never open
- **Where**: Circle chat image upload → Firebase Storage; then image render after adding disk cache.
- **Error / symptom**: (a) `[firebase_storage/unauthorized] User is not authorized…` on upload even though text messages sent fine. (b) After adding `cached_network_image`, images spun forever with `MissingPluginException (… getDatabasesPath on channel com.tekartik.sqflite)`.
- **Root cause**: (a) `storage.rules` reads Firestore via `firestore.exists()` (cross-service rules), which needs the **“Firebase Rules Firestore Service Agent”** IAM role on the Storage service agent; it was never provisioned because the rules deploy skipped the upload. (b) `cached_network_image` → `flutter_cache_manager` → native `sqflite`; native plugins only link on a full build, so hot restart leaves the implementation missing.
- **Fix applied**: (a) Granted the role manually in Google Cloud IAM to `service-<PROJECT_NUMBER>@gcp-sa-firebasestorage.iam.gserviceaccount.com`; documented in a comment at the top of `storage.rules`. (b) Full stop + rebuild (`flutter run`), no code change.
- **Status**: Resolved. See `documentation/2026-07_features_fixes_and_incidents.md` §8 (#17).

## 18) “Could not load commitments” — Firestore composite index (again)
- **Where**: Circle → Commitments tab → `FirestoreWeeklyCommitmentRepository.watchCommitments` (`lib/features/community/data/weekly_commitment_repository.dart`).
- **Error / symptom**: Tab showed “Could not load commitments.” Underlying `[cloud_firestore/failed-precondition]` (composite on `weekKey` + `updatedAtMs`) was swallowed by the view’s `error: (_, _)` handler.
- **Root cause**: Same as #16 — equality filter + `orderBy` without a composite index.
- **Fix applied**: Dropped `orderBy`, sort client-side; declared the app’s genuinely-needed indexes in `firestore.indexes.json` (taskScores, aiPulse — both use `limit(1)`), wired into `firebase.json`, deployed.
- **Status**: Resolved. See `documentation/2026-07_features_fixes_and_incidents.md` §7 and §9.

## 19) Release/profile iOS build stuck on white screen — Crashlytics "urgent mode"
- **Where**: Standalone launch from the home screen (release/profile build). Debug builds via `flutter run` were fine.
- **Error / symptom**: App never left the native launch screen (white). Device log showed `Crashlytics skipped rotating the Install ID during urgent mode` and "uploading urgently" — then nothing.
- **Root cause**: Crashlytics had pending crash reports from earlier boot failures. With native auto-collection enabled, `FirebaseApp.configure` enters **urgent mode** and blocks the main thread uploading those reports *before Flutter ever runs*. On a slow network that upload effectively never finishes → permanent white screen.
- **Fix applied**: `FirebaseCrashlyticsCollectionEnabled=false` in `ios/Runner/Info.plist` (disables native auto-start), then enable at runtime in `lib/main.dart` with `.timeout(Duration(seconds: 4))` wrapped in try/catch so it can never block the first frame.
- **Status**: Resolved. See `documentation/2026-07_features_fixes_and_incidents.md` §10.

## 20) Release/profile iOS build white screen #2 — Isar symbols dead-stripped
- **Where**: `Isar.open` during pre-frame bootstrap (`lib/core/offline/offline_store.dart`), release/profile builds only.
- **Error / symptom**: Boot "hung" at `[boot] opening isar at …`. Once the zone error handler was taught to `print` (see below), the real error surfaced: `IsarError: Could not initialize IsarCore library for processor architecture "ios_arm64"`.
- **Root cause**: `isar_community_flutter_libs` vendors a **static** `libisar.a`. Its FFI symbols are only referenced at runtime via `dlsym`, so the release/profile linker's dead-code stripping removes them all. Debug builds don't strip → "works in debug, white screen in release". **Masking bug**: the `runZonedGuarded` handler only forwarded errors to Crashlytics (itself not yet working), so a boot *crash* looked like a boot *hang*.
- **Fix applied**: (a) `DEAD_CODE_STRIPPING = NO` in `ios/Flutter/Release.xcconfig` (Profile inherits it in the Flutter template). (b) Migrated `isar` 3.1.0 → `isar_community` 3.3.2 (maintained fork, drop-in v3 API, same on-disk format). (c) Zone handler in `main.dart` now ALWAYS prints the error + stack locally before Crashlytics. (d) `[boot]` breadcrumbs via `print` (survives release; `debugPrint` is silenced there) bracket every boot phase so a hang localizes itself.
- **Status**: Resolved — profile build boots end-to-end on device. See `documentation/2026-07_features_fixes_and_incidents.md` §10.

## 21) VM tests: `Incorrect Isar Core version` / `slice extends beyond end of file`
- **Where**: `flutter test` after the isar_community 3.3.2 migration.
- **Error / symptom**: First `IsarError: Incorrect Isar Core version: Required 3.3.2 found 3.1.0+1`; after deleting the old binary, `dlopen … slice 0 extends beyond end of file`.
- **Root cause**: The gitignored repo-root `libisar.dylib` was (1) the stale 3.1.0 binary from stock Isar, then (2) a **truncated** download — `Isar.initializeIsarCore(download: true)` has no resume/retry, and the flaky network cut it at 182 KB of ~2.1 MB.
- **Fix applied**: Delete `libisar.dylib`, re-download resumably: `curl -L --retry 100 --retry-all-errors -C - -o libisar.dylib https://binaries.isar-community.dev/3.3.2/libisar_macos.dylib`, verify with `file` (should say "Mach-O universal binary … x86_64 … arm64", ~2.1 MB). All 1005 tests then passed.
- **Status**: Resolved. Supersedes the environment notes in #15 for the community fork.

---

## How to use this log
- Add each new error immediately after it appears.
- Include: **where**, **error text**, **root cause**, **fix**, **status**.
- If an error returns, update status to `Reopened` and append what changed.
- For the **Isar + notification routing** arc (architecture, diagrams, file index), see `documentation/isar-local-first-and-notification-routing.md`.
