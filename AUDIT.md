# Coach for Life — Audit

## 1. Security & Auth

_Audited 2026-07-01. Scope: firestore.rules, storage.rules, auth_repository.dart, auth_gate.dart, auth_session_policy.dart, user_scoped_invalidation.dart, circle_providers.dart, account_settings_screen.dart, profile_screen.dart, ai_remote_config_service.dart. Report-only; no fixes applied._

### [CRITICAL] OpenAI API key distributed to every client via Remote Config
- `lib/core/ai/ai_remote_config_service.dart:54-64`, consumed in `lib/features/ai_assistant/application/ai_operating_layer_client.dart:410`, `lib/features/community/application/circle_ai_pulse_service.dart:114`, `lib/features/analytics/application/ai_summary_providers.dart:28`
- Firebase Remote Config values are readable by **any** app instance — including anonymous sessions the app creates automatically on first launch (`auth_gate.dart:101`). Anyone can extract the OpenAI key from a device or intercepted config fetch and run unlimited billed requests against your account. There are no Cloud Functions in the repo, so all OpenAI calls go directly from the client with the raw key (`Authorization: Bearer $apiKey`).
- **Fix:** revoke the current key; proxy OpenAI calls through a backend (Cloud Function) that authenticates the Firebase user and enforces per-user quotas.

### [HIGH] Activity feed writable by any signed-in user, member or not
- `firestore.rules:117` — `allow create: if isSignedIn();`
- Any authenticated user (including a fresh anonymous account) can inject arbitrary activity items into **any** circle's feed, with no membership check and no validation that the authored `userId`/name fields match `request.auth.uid` → spam and impersonation of member activity.
- **Fix:** `allow create: if isCircleMember(circleId) && request.resource.data.userId == request.auth.uid;`

### [HIGH] Circle members can edit anyone's chat messages
- `firestore.rules:109` — `allow update: if isCircleMember(circleId);`
- Any member can rewrite another member's message content and `senderId` (delete is correctly sender-or-moderator, but update is not) → tampering/impersonation inside circles.
- **Fix:** `allow update: if resource.data.senderId == request.auth.uid && request.resource.data.senderId == resource.data.senderId;` (plus moderator carve-out if needed).

### [HIGH] Challenge proof images readable/writable by all users
- `storage.rules:30-33` — `challenge_proofs/{challengeId}/{fileName}`: read/write requires only `isSignedIn()`.
- Any user (incl. anonymous) can read every proof photo in the app and overwrite other users' proofs (path has no circle or owner scoping, and existing filenames can be clobbered).
- **Fix:** nest under circle (`/circles/{circleId}/challenge_proofs/...`) and require `isCircleMember(circleId)`; include uploader uid in the path and require it to match `request.auth.uid` for writes.

### [MEDIUM] Weekly commitments fully writable by any circle member
- `firestore.rules:122-124` — `allow read, write: if canAccessCircleContent(circleId);`
- Members can create, modify, and delete **each other's** commitments; no field validation at all. `write` also grants delete.
- **Fix:** split rules; restrict update/delete to the commitment owner (`resource.data.userId == request.auth.uid`) with moderator override.

### [MEDIUM] Challenges updatable by any member, including creatorId
- `firestore.rules:131` — `allow update: if isCircleMember(circleId);`
- Any member can alter another member's challenge — title, status, and even `creatorId` (self-promotion to "creator") — since no diff whitelist is enforced.
- **Fix:** restrict to creator/moderator, or whitelist mutable fields via `diff().affectedKeys().hasOnly([...])`.

### [MEDIUM] memberCount mutation not tied to actual membership change
- `firestore.rules:45-55, 81-83`
- `isJoinIncrementingMemberCount()`/`isLeaveDecrementingMemberCount()` only require a signed-in user and a ±1 diff — the rules never verify the caller's member doc is created/deleted in the same transaction. Any signed-in non-member can repeatedly increment/decrement any circle's `memberCount`.
- **Fix:** use `getAfter(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid))` to bind the count change to the caller's membership write in the same transaction.

### [MEDIUM] Account deletion orphans all Firestore user data
- `lib/features/settings/presentation/account_settings_screen.dart:152-160`; no Cloud Functions in repo (firebase.json has only rules)
- `deleteAccount()` deletes the Auth user and wipes local data, but `users/{uid}` and its entire subtree remain in Firestore forever. After deletion no principal can ever access or purge it (rules require `auth.uid == uid`), which is a data-retention/GDPR problem. Circle member docs and messages authored by the deleted uid also remain.
- **Fix:** add an Auth `onDelete` Cloud Function (or pre-delete client purge) that removes `users/{uid}/**` and circle memberships.

### [MEDIUM] Delete-account path skips in-memory provider invalidation
- `account_settings_screen.dart:150-160` vs `profile_screen.dart:94`
- Logout calls `invalidateUserScopedProviders(ref)` before wiping, but the delete-account flow only calls `AuthSessionPolicy.clearLocalSession()`. In-memory state (AI conversation history, execution/timer state, etc.) survives until the next sign-in's uid-change wipe in AuthGate.
- **Fix:** call `invalidateUserScopedProviders(ref)` in `_deleteAccount()` after a successful delete.

### [MEDIUM] AuthGate re-entrancy guard can drop a uid-change wipe
- `lib/features/auth/presentation/auth_gate.dart:64` — `if (_handlingUidChange) return;`
- If a second auth emission with a *different* uid arrives while a uid-change wipe/sync is in flight (fast account switch, token refresh race), it is silently dropped: no wipe, no `persistUid`, and the prior user's freshly synced data stays visible to the new uid until an app restart re-detects the mismatch.
- **Fix:** after `finally`, re-read `_auth.currentUser?.uid` and re-run the handler if it no longer matches the uid just processed.

### [LOW] All circles and member lists enumerable by any signed-in user
- `firestore.rules:74, 92`
- Every circle doc and every member list is readable app-wide (needed for discovery per comments), which lets any user enumerate who belongs to which circle. Fine if all circles are public by design; add a `visibility` field check if private circles are ever introduced.

### [LOW] Anonymous auth makes `isSignedIn()` effectively public
- `auth_gate.dart:101-112` auto-creates anonymous sessions with zero friction, so every rules gate requiring only sign-in (activity feed create, challenge_proofs storage, circle reads) is reachable by anyone who installs the app — an amplifier for the findings above. Consider Firebase App Check plus tightening `isSignedIn()`-only gates to membership checks.

### [LOW] Firebase iOS API key ships in the bundle (expected, but unrestricted?)
- `lib/firebase_options.dart:19` (correctly gitignored — verified never present in git history; only `*.example.*` files are tracked)
- Firebase API keys are identifiers, not secrets, but since security rests entirely on Firestore rules, ensure the key is restricted to the iOS bundle ID in Google Cloud Console and enable App Check. The pre-`32a1bda` hardcoded OAuth client IDs remaining in git history are public identifiers, not secrets — no rotation needed.

### [LOW] First-install uid-change detection gap
- `lib/features/auth/application/auth_session_policy.dart:49-53`
- `hasUidChanged()` returns `false` when no uid is stored, so a device that has local Isar data but no persisted uid (app upgrade from a pre-policy version, restored backup) will hand that data to whichever account signs in first. Mitigated going forward by `persistUid` on every sign-in path.

### [LOW] Partial identifiers logged in release builds
- `lib/features/auth/application/auth_repository.dart` (throughout: uid prefixes, email prefix at :299)
- `debugPrint` is not compiled out of release builds; 8-char uid prefixes and email prefixes end up in device logs. Redaction is already careful — just gate the calls with `kDebugMode`.

### Verified OK (Security & Auth)
- **Users collection isolation** (`firestore.rules:61-67`): `users/{uid}` + recursive wildcard is owner-only; no path lets another user read/write it. Challenge votes (`:134-137`) correctly bind doc id to `request.auth.uid`.
- **Logout flow** (`profile_screen.dart:76-99`): order is correct — `invalidateUserScopedProviders` (which calls `invalidateCircleScopedProviders` first, covering all 7 circle providers) → `clearLocalSession` (notifications, Isar, seed prefs) → `signOut`. Remaining circle stream providers are `autoDispose` and watch `authUidProvider`, so they re-scope on uid change.
- **Anonymous → account linking** (`auth_repository.dart:100-107, 175-182, 268-289`): `linkWithCredential` preserves the uid (no data migration needed); when the credential already belongs to another account, the code surfaces `EmailAlreadyInUse` rather than silently signing into the other account — no cross-account data merge. Apple sign-in uses a hashed nonce correctly.
- **Secrets hygiene**: `GoogleService-Info.plist` and `firebase_options.dart` are gitignored and absent from all git history; no OpenAI/Anthropic-style keys hardcoded in `lib/`.

## 2. Sync Integrity

_Audited 2026-07-01. Scope: sync_service.dart, remote_isar_merge.dart, offline_sync_queue.dart, lww_updated_at.dart, firestore_client.dart, firestore_paths.dart, post_sync_refresh_coordinator.dart, and dual-write repositories (isar_planning_repository, goals_repository, isar_goals_repository, execution_repository, scoring_repository, reminder repos, analytics repos). Report-only; no fixes applied._

### [HIGH] Offline sync queue survives logout / account switch
- `lib/core/sync/sync_service.dart:36-37, 46-47` (singleton `_queue` + `offline_sync_queue.json`); `lib/features/auth/application/auth_session_policy.dart:63-80` and `lib/core/offline/offline_store.dart:41-45` clear Isar/prefs/notifications but **never** the sync queue.
- User A's pending operations — full document payloads of their private data — persist on disk and in the `SyncService` singleton across logout. Consequences: (a) A's data remains readable on the device during B's session (leak); (b) after switch, the ops replay against paths embedding A's uid and get permission-denied forever, becoming permanent poison entries that inflate `pendingCount`; (c) if A signs back in later, stale queued payloads flush and can overwrite data A has since edited on another device (push side has no LWW guard — see below).
- **Fix:** clear `_queue`, `pendingCount`, and `offline_sync_queue.json` in `AuthSessionPolicy.clearLocalSession()`, and tag queued ops with the enqueue-time uid so foreign-uid ops are dropped at process time.

### [HIGH] Writes enqueued during an active queue flush are silently lost
- `lib/core/sync/sync_service.dart:194-221`
- `processQueue()` iterates the list referenced by `_queue` at loop start; a concurrent `_enqueue()` (any repo write while a flush is in flight — routine on slow networks) replaces `_queue` with a new list containing the new op. At the end of the flush, `_queue = remaining` (failures from the *old* snapshot only) and `_queueStore.save(_queue)` overwrite both memory and disk — the newly enqueued op vanishes without a trace. The user's edit exists in Isar but never reaches Firestore, and no error is ever surfaced.
- **Fix:** compute `remaining` as `failures + anything appended after the snapshot` (e.g. track processed op ids and subtract), or guard enqueue/flush with a lock.

### [HIGH] No delete propagation or tombstones — deleted records resurrect
- `lib/core/sync/remote_isar_merge.dart` (upsert-only: `:151-229`); `lib/core/sync/lww_updated_at.dart:9` (`localUpdatedAtMs == null → apply remote`)
- Two distinct failures: (1) A record deleted remotely (or from another device) is **never** removed from local Isar — the pull only upserts, so devices never converge on deletes. (2) A record deleted locally while offline (Firestore delete queued in `isar_planning_repository.dart:45-57`) is resurrected by any remote pull that runs before the queue flushes: the local row is gone, so `shouldApplyRemoteUpdatedAt` sees `local == null` and re-applies the not-yet-deleted remote doc. `SyncService.initialize()` (`:56-57`) even fires `processQueue()` and `syncFromRemote()` concurrently, making this race a cold-start default.
- **Fix:** soft-delete with a `deletedAtMs` tombstone field synced like any other LWW field; purge tombstones after a retention window.

### [HIGH] Account switch mid-pull: forced pull can be satisfied by the previous user's in-flight pull, which writes into the freshly wiped Isar
- `lib/core/sync/sync_service.dart:74-77`; `lib/features/auth/presentation/auth_gate.dart:72-74`; `lib/core/sync/remote_isar_merge.dart:100, 112, 126, 138`
- `syncFromRemote(force: true)` returns early by awaiting `_activeRemotePullFuture` if one exists — but that pull may have started under the **previous** uid. During AuthGate's uid-change handling (`invalidate → clearLocalSession → syncFromRemote(force:true)`), an in-flight pull for user A (started by the connectivity listener or debounced timer) will (a) keep merging A's documents into Isar *after* the wipe, and (b) satisfy the "forced" pull so B's data is never fetched until the 30s debounce lapses. Compounding it, `RemoteIsarMerge` mixes uid capture: routines use `FirestoreClient` (uid frozen at construction, `firestore_client.dart:13-17`) while reminders/goals/analytics use `FirestorePaths` getters that resolve `FirebaseAuth.instance.currentUser` at call time (`firestore_paths.dart:10-15`) — a mid-pull auth change fetches different users' collections into the same merge run.
- **Fix:** capture the uid once per pull, abort the merge when `currentUser?.uid` no longer matches, and make `force: true` cancel/supersede the in-flight pull instead of joining it.

### [MEDIUM] Push side has no conflict detection — blind `set(merge:true)` can overwrite newer remote data
- `lib/features/planning/data/isar_planning_repository.dart:35`, `lib/core/sync/sync_service.dart:202-205`, same pattern in goals/execution/scoring/reminders/analytics repos
- Pull is LWW on `updatedAtMs`, but push never checks anything: a queued op carrying a stale payload (written offline days ago, or replayed after a crash — ops are removed from the queue only after the full loop, so a kill mid-flush re-runs already-applied ops on restart) unconditionally overwrites a newer remote document. The offline edit can even be overwritten locally by the concurrent pull and *still* get pushed afterward, reverting the remote.
- **Fix:** push via a transaction that compares `updatedAtMs` server-side (or a rules-level `request.resource.data.updatedAtMs > resource.data.updatedAtMs` guard), and persist queue progress per-op rather than post-loop.

### [MEDIUM] Catch-all error handling creates permanent poison ops; no backoff or retry budget
- `lib/features/planning/data/isar_planning_repository.dart:36, 51` (`catch (_)` on the direct write), `lib/core/sync/sync_service.dart:209-212` (`catch (_)` keeps op forever)
- Permanent failures (permission-denied, invalid-argument, document-path errors) are indistinguishable from transient network errors: they re-queue forever, retried on every connectivity change with zero backoff and no retry counter, and the user is never told a write will never land. `pendingCount` grows and the badge (if surfaced) never clears.
- **Fix:** inspect `FirebaseException.code` — drop or dead-letter non-retryable codes; add per-op retry count and exponential backoff for the rest.

### [MEDIUM] Remote pull failures rethrow into `unawaited()` callers — unhandled async errors; partial pull leaves mixed state
- `lib/core/sync/sync_service.dart:52-57` (connectivity listener), `:120-122` (rethrow), `lib/features/home/presentation/home_screen.dart:2068`
- `_runRemotePull` rethrows after logging; every fire-and-forget caller (`unawaited(syncFromRemote())`) turns a routine network failure into an unhandled zone exception. Because `RemoteIsarMerge.run()` is sequential (`remote_isar_merge.dart:42-48`), a failure mid-run leaves routines merged but reminders/goals/analytics stale until the next debounced pull — with the 60s timeout, a slow connection makes this the common case. Individual bad documents are correctly skipped per-doc, but a collection-level `get()` failure aborts everything after it.
- **Fix:** don't rethrow to fire-and-forget callers (return false / expose a status); or wrap each `_pullX()` so one collection's failure doesn't starve the rest.

### [MEDIUM] Queue persistence is not crash-safe
- `lib/core/sync/offline_sync_queue.dart:26-30` (non-atomic `writeAsString`), `:15-24` (`load()` has no try/catch), `lib/core/bootstrap/app_bootstrap.dart:75` (awaited during bootstrap)
- A crash/kill mid-write leaves truncated JSON; the next launch `jsonDecode` throws inside `SyncService.initialize()`, which is awaited in `AppBootstrap.initialize` — one corrupt file can break app startup, and the entire pending queue is unrecoverable either way.
- **Fix:** write to a temp file + rename (atomic on iOS/Android), and make `load()` catch parse errors, preserve the corrupt file for diagnostics, and return `[]`.

### [MEDIUM] LWW ordering depends on device wall clocks
- `lib/features/planning/data/isar_planning_repository.dart:159, 208, 261` (and all other writers): `updatedAtMs = DateTime.now()`; `lib/core/sync/lww_updated_at.dart`
- Conflict resolution between two devices is decided by whichever has the faster clock. A device with a skewed-ahead clock permanently wins all conflicts (its writes are "newer" even for older edits); a skewed-behind device's edits are silently discarded on every pull. No `FieldValue.serverTimestamp()` anywhere in the sync path.
- **Fix:** stamp a parallel `serverUpdatedAt: FieldValue.serverTimestamp()` on push and prefer it in `shouldApplyRemoteUpdatedAt`, falling back to client ms only for never-pushed rows.

### [MEDIUM] [PERF] Full-dataset pull on every sync, with N+1 nested queries
- `lib/core/sync/remote_isar_merge.dart:50-97` (routines → per-routine blocks query → per-block tasks query, all sequential awaits), `:125-148` (entire `analytics_events` + `analytics_stats` collections re-read every pull)
- There is no incremental cursor (`where('updatedAtMs', '>', lastPullMs)`) — every pull (connectivity change, 30s debounce, app resume, pull-to-refresh) re-downloads the user's complete history. Read costs and latency grow unboundedly; once a heavy user's full pull exceeds the 60s timeout (`sync_service.dart:22`), **every** pull aborts with `TimeoutException` and sync is permanently broken for that account, since a retry restarts from scratch rather than resuming.
- **Fix:** track `lastSuccessfulPullMs` per collection and filter with `updatedAtMs > cursor`; use `collectionGroup('tasks')`/`collectionGroup('blocks')` to flatten the N+1 into one query each; parallelize independent collection pulls.

### [LOW] [PERF] One Isar write transaction per merged record
- `lib/core/sync/remote_isar_merge.dart:159-228` — every `_mergeX` opens its own `writeTxn`. For a pull of hundreds of docs this is hundreds of serialized transactions (each with fsync overhead). Batch all applicable rows of a collection into a single `writeTxn`.

### [LOW] Signed-out writes target a shared fallback uid
- `lib/core/firebase/firestore_paths.dart:14` falls back to `AppConfig.localUserId` (`'local-user-v1'`, `app_config.dart:5`) when `currentUser` is null. Any repo write during a brief signed-out window enqueues an op targeting `users/local-user-v1/...`, which rules will reject forever (another poison-op source). AuthGate keeps a user signed in almost always, so exposure is small — but the enqueue path should refuse to queue when there is no real uid.

### [LOW] `ensureDefaultDayPlan` is not concurrency-safe
- `lib/features/planning/data/isar_planning_repository.dart:318-357` — read-then-create with no transaction or unique index on `dateKey`; two concurrent callers (e.g. app-resume refresh + user action) can both see "no routine for today" and create duplicate "Daily plan" routines, which then both sync remotely and never converge (no dedupe on pull).

### Verified OK (Sync)
- **Single-flight + debounce on pulls** (`sync_service.dart:66-102`): concurrent callers join the in-flight pull; 30s debounce prevents pull storms from connectivity flapping (the account-switch interaction above notwithstanding).
- **Per-document fault isolation on pull** (`remote_isar_merge.dart:54, 85, 89, 93`): one malformed document skips only itself, not the whole merge.
- **Upsert idempotency**: replayed queue upserts with identical payloads are harmless in isolation (`set(merge:true)` + LWW pull); the risk is only in the stale-payload/ordering cases flagged above.
- **`FirestoreClient` uid pinning** (`firestore_client.dart:9-17`) is the right design — the finding is that half of `RemoteIsarMerge` bypasses it via `FirestorePaths`.

## 3. State Lifecycle

_Audited 2026-07-02. Scope: root container setup (main.dart, app_bootstrap.dart), core/di/providers.dart, user_scoped_invalidation.dart, and provider files across goals, planning, analytics, AI assistant, reminders, community, execution, ui_state. Report-only; no fixes applied._

### [HIGH] `firestoreClientProvider`'s uid re-scoping is defeated by `ref.read` in every consumer
- `lib/core/di/providers.dart:37-42` (provider watches `authStateProvider`, comment: "Rebuilds whenever the signed-in uid changes so all downstream repositories always use the correct uid-scoped Firestore path") vs `:50` (`ref.read(firestoreClientProvider)`) and `lib/features/goals/application/goals_providers.dart:17` (same)
- `FirestoreClient` pins the uid at construction by design. The rebuild-on-uid-change only propagates through `ref.watch`, but both consumers (`planningRepositoryProvider`, `goalsRepositoryProvider`) use `ref.read`, and neither is `autoDispose` nor in `invalidateUserScopedProviders`. After an account switch the cached repository instances keep the **previous user's uid** for the rest of the app session: `goalsStreamProvider` (`goals_providers.dart:21`, also never invalidated) streams the old user's goals path, and `FirestorePlanningRepository` remote ops (routine modes, flow events, accountability logs) target the old uid — permission-denied at best, cross-user reads/writes at worst.
- **Fix:** change both to `ref.watch(firestoreClientProvider)` (dependents then rebuild automatically), or add both repository providers + `goalsStreamProvider` to `invalidateUserScopedProviders`.

### [HIGH] The logout invalidation list is a hand-maintained subset — the analytics and AI-cache layers survive account switches
- `lib/features/auth/application/user_scoped_invalidation.dart:28-61` (~20 providers) vs `lib/features/analytics/application/` (**zero** `autoDispose` occurrences across the entire directory: KPI snapshots, streak summaries, AI summaries, delivery history/decisions, pattern detection, feature caches) and `lib/features/ai_assistant/application/ai_assistant_providers.dart:111-128` (`lastAiBatchProvider`, `canUndoLastAiBatchProvider`, `recentAiBatchesProvider`), `lib/features/planning/application/planned_task_providers.dart:203` (`openTasksOutsideTodayProvider`), `lib/features/goals/application/goals_providers.dart:21-142`
- Isar-backed **Stream**Providers self-heal when `clearLocalSession()` wipes Isar (the `watchLazy` triggers re-emit), but **Future**Providers evaluated once do not re-run on Isar clear — they keep serving user A's cached values (streaks, KPIs, undo state, off-day tasks, goal details) into user B's session. The post-sync full refresh (`PostSyncRefreshCoordinator` → `UnifiedRecomputeGraph`) only fires after B's *first successful remote pull*, so between sign-in and pull completion — or indefinitely if the pull fails — B sees A's computed data.
- **Fix:** make user-scoped FutureProviders `autoDispose` (or make them `ref.watch` a uid-keyed provider like `authUidProvider` so they rebuild on switch); treat the manual list as a fallback, not the mechanism. A widget/unit test asserting "every provider reachable from the home screen returns empty state after `invalidateUserScopedProviders` + Isar clear" would catch regressions.

### [MEDIUM] App-lifetime bridge services hold cross-user in-memory state and permanently pin user-scoped providers
- `lib/core/bootstrap/app_bootstrap.dart:117-144` (dispose callback "intentionally not stored"), `lib/features/community/application/circle_activity_bridge_service.dart:44-50` (`_lastKnownStreak`, `_seenCompletedTaskIds`, `_seenCompletedMilestoneIds`)
- `CircleActivityBridgeService` and `ChallengeProgressSyncService` are started once in bootstrap with `container.listen(..., fireImmediately: true)` and never disposed or reset. Consequences: (a) their dedupe/baseline maps are keyed by user A's goal/task ids and survive into user B's session — milestone posts can be wrongly suppressed or wrongly fired for B; (b) the permanent listeners pin `goalsStreamProvider` and `todayAllTasksRowsProvider` alive forever — including on the signed-out landing screen — which also defeats any future `autoDispose` migration of those providers; (c) `currentUserId` is resolved per-event via closure, so an event observed just after an account switch can be attributed to the new uid using the old user's data.
- **Fix:** store the dispose callbacks, and restart the bridges (clearing internal maps) from AuthGate's uid-change handler.

### [MEDIUM] Non-`autoDispose` `.family` providers accumulate one cached instance per argument forever
- `lib/features/goals/application/goals_providers.dart:100, 117` (`goalDetailProvider`, `goalActionsProvider`), `lib/features/analytics/application/analytics_streak_providers.dart:9`, `analytics_kpi_providers.dart:6` (`.family` keyed by habit id), `lib/features/community/application/circle_providers.dart:116` (`circleActiveTabProvider.family` — invalidated on logout but unbounded within a session)
- Every distinct goalId/habitId/circleId creates a permanently retained provider element. Memory grows monotonically with navigation, and the cached `FutureProvider.family` snapshots go stale after edits unless every mutation path remembers to invalidate (goals has `invalidateGoalScopedProviders`, `goals_providers.dart:143-147`, but it must be called manually at each call site).
- **Fix:** add `.autoDispose` to the family providers that back detail screens; keep `keepAlive()` selectively if a specific cache is intentional.

### [LOW] Demo-value defaults resurface after logout invalidation
- `lib/features/ui_state/ui_state_providers.dart:3` (`selectedTaskProvider` → `'Deep Work: UI Architecture'`), `lib/core/di/providers.dart:66-67` (`activeExecutionTaskIdProvider` → `'task_ui_architecture'`, `activeExecutionTaskLabelProvider` → `'Deep Work: UI Architecture'`)
- `invalidateUserScopedProviders` resets these to hardcoded demo strings, not empty state — a freshly signed-in user can see a phantom "Deep Work: UI Architecture" task label until real state overwrites it. **Fix:** default to empty/null and handle that in the UI.

### [LOW] `ref.read` of an `autoDispose` stream's `.valueOrNull` in an action path
- `lib/features/community/presentation/circle_discovery_screen.dart:147` — `ref.read(myCircleIdsProvider).valueOrNull?.toSet() ?? {}`
- If nothing is currently watching `myCircleIdsProvider` (autoDispose), this read instantiates it fresh in `loading` state and gets `null` → `joinedIds` is empty → the join-guard logic evaluates against wrong data (possible duplicate join attempt). Harmless while the screen also watches the provider, but fragile. **Fix:** pass the already-watched value in, or `await ref.read(myCircleIdsProvider.future)`.

### [LOW] [PERF] Two 1-minute periodic timers run for the app's entire lifetime
- `lib/features/planning/application/planned_task_providers.dart:135, 184` — `todayAllTasksRowsProvider` and `homeFlowSnapshotProvider` each run a `Timer.periodic(1 min)` that recomputes the full prioritized task list. Because the bootstrap bridge pins them (see above), both tick even on the signed-out landing screen and in guest sessions with no planner data. **Fix:** compute the delay to the next block/task boundary instead of polling, or at least pause when signed out.

### Verified OK (State Lifecycle)
- **Bootstrap container setup** (`main.dart:11-28`): single root `ProviderContainer` + `UncontrolledProviderScope` is standard; `appRootProviderContainer` is assigned before any consumer runs. Pre-auth provider reads in bootstrap all resolve repositories that compute Firestore paths per-call (`FirestorePaths`), so they don't freeze a pre-auth uid — the exceptions are exactly the two `FirestoreClient` consumers flagged above.
- **Isar watcher hygiene** (`planned_task_providers.dart:137-143, 186-192` and the same pattern in `delivery_providers.dart`, `feature_cache_providers.dart`, `pattern_detection_providers.dart`): every `StreamController` + `watchLazy` subscription + timer is cleaned up in `ref.onDispose`.
- **ExecutionController** (`execution_controller.dart:225-227`): cancels its engine subscription and disposes `TaskTimerEngine` (which cancels its ticker) on provider disposal.
- **ContextOverrideExpiryPoller** (`context_override_expiry_poller.dart:49-55`): `ref.onDispose(poller.dispose)` correctly wired.
- **Circle providers** (`circle_providers.dart`): the model citizens — `autoDispose`, re-scope via `ref.watch(authUidProvider)`, and covered by explicit invalidation as a belt-and-suspenders.
- **AuthGate `listenManual`** (`auth_gate.dart:48-51`): tied to widget state lifetime; no leak.
- **`ref.read` in event handlers** across sampled screens is idiomatic (services/repos/one-shot state); no build-method `ref.read` of reactive state found.

## 4. Release & Compliance

_Audited 2026-07-02. Scope: android/app/build.gradle.kts, AndroidManifest.xml, ios/Runner/Info.plist, Runner.xcodeproj, Podfile, pubspec.yaml, main.dart, app_bootstrap.dart, local_notifications_service.dart, firebase_options.dart, account_settings_screen.dart. Report-only; no fixes applied._

### [HIGH] No crash reporting of any kind
- `pubspec.yaml:36-50` (no `firebase_crashlytics`/`sentry`), `lib/main.dart:11-28` (no `runZonedGuarded`, no `FlutterError.onError`, no `PlatformDispatcher.instance.onError` anywhere in `lib/`)
- Every release crash, Flutter framework error, and uncaught async exception is invisible. This compounds Section 2's finding that sync failures rethrow into `unawaited()` futures — those become uncaught zone errors that nobody will ever see in production.
- **Fix:** add `firebase_crashlytics`; in `main()` wire `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError` and `PlatformDispatcher.instance.onError` before `runApp`.

### [HIGH] Android release build is non-functional: Firebase not configured for Android
- `lib/firebase_options.dart:13, 18` — only `FirebaseOptions ios` exists; any other platform hits `throw UnsupportedError('DefaultFirebaseOptions are not configured for this platform yet.')`; `android/app/google-services.json` is absent
- An Android build crashes at bootstrap (`FirebaseInitializer.initialize()` is the first awaited call). If Android launch is planned this is a blocker chain; if the release is iOS-only, say so explicitly and gate the Android build.

### [HIGH] Android identity and signing are still template defaults
- `android/app/build.gradle.kts:24` — `applicationId = "com.example.coach_for_life"` (Play Console rejects `com.example.*`, and the id is immutable after first upload); `:34-38` — `release` build type signs with the **debug** keystore (template TODO untouched); `android/key.properties` is gitignored but doesn't exist; `AndroidManifest.xml` `android:label="coach_for_life"` is the raw project name as the user-visible app name.
- **Fix:** pick the final application id now (it must match a Firebase Android app registration), create an upload keystore + `key.properties`-driven `signingConfig`, set a proper label.

### [HIGH] Android notification scheduling will not survive release conditions
- `android/app/src/main/AndroidManifest.xml` (permissions block) vs `lib/core/notifications/local_notifications_service.dart:102, 163`
- Three gaps: (1) no `POST_NOTIFICATIONS` permission declared — on Android 13+ `requestNotificationsPermission()` (`:68`) cannot grant, so **all** reminders are silently undeliverable; (2) `AndroidScheduleMode.exactAllowWhileIdle` is used but neither `SCHEDULE_EXACT_ALARM` nor `USE_EXACT_ALARM` is declared — on Android 12+ `zonedSchedule` throws `exact_alarms_not_permitted`; (3) no `RECEIVE_BOOT_COMPLETED` permission or `ScheduledNotificationBootReceiver` — every scheduled reminder vanishes on device reboot.
- **Fix:** add the three permissions + boot receiver per flutter_local_notifications setup docs, and fall back to `inexactAllowWhileIdle` when exact-alarm permission is denied.

### [HIGH] Sign in with Apple entitlement is missing
- `ios/Runner/` contains no `.entitlements` file (verified), yet `sign_in_with_apple: ^7.0.1` is a login path (`auth_repository.dart:134`)
- Without the `com.apple.developer.applesignin` capability, Apple sign-in fails with an authorization error in TestFlight/App Store builds. Apple also *requires* Sign in with Apple to work when third-party login (Google) is offered — a broken Apple flow is a review rejection.
- **Fix:** add the Sign in with Apple capability in Xcode (creates `Runner.entitlements`) and verify the App ID in the developer portal has it enabled.

### [HIGH] Debug/test surfaces reachable in release builds
- `lib/app/app.dart:100` routes `FirebaseTestScreen`; `lib/features/home/presentation/home_screen.dart:477-480` renders an unguarded "Open Firebase Test Screen" button (no `kDebugMode` check anywhere in either file); the screen writes diagnostics docs to Firestore (`firebase_test_screen.dart:48-50`). Directly above it (`home_screen.dart:470`) sits an "I'M DISTRACTED" button with an empty `onPressed: () {}` — visible dead UI.
- **Fix:** wrap the button/route in `if (kDebugMode)` or delete the screen; wire or remove the placeholder button.

### [MEDIUM] Release behavior depends on undocumented `--dart-define` flags
- `lib/features/auth/application/auth_session_policy.dart:14-17` (`REQUIRE_REGISTERED_AUTH`, default `false`), `lib/core/config/google_auth_config.dart:13-14` (`GOOGLE_IOS_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID`, default empty)
- There is no build script or CI config in the repo that passes these. A vanilla `flutter build ipa` ships guest/anonymous mode and **silently breaks Google sign-in** (empty client IDs → `signInWithGoogle` returns the "missing idToken" failure). Nothing fails loudly at build time.
- **Fix:** add a release build script that supplies all defines, and an assert-at-startup (release mode only) that required defines are non-empty.

### [MEDIUM] iOS notification permission prompt fires at first launch, during bootstrap
- `lib/core/notifications/local_notifications_service.dart:26` — `DarwinInitializationSettings()` defaults request alert/badge/sound at plugin `initialize()`, which `AppBootstrap` awaits before `runApp` (`app_bootstrap.dart:48`). The system permission dialog appears before the user has seen a single screen, which tanks opt-in rates and undermines the otherwise-correct lazy flow (`requestPermissionsIfNeeded` at first reminder toggle, `home_screen.dart:929`, `goal_editor_screen.dart:815`).
- **Fix:** pass `DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false)` and rely solely on the lazy request.

### [MEDIUM] Account deletion exists but does not delete server-side data (App Store 5.1.1(v) risk)
- In-app deletion is present and well-built (`account_settings_screen.dart:139-167`: type-DELETE confirmation + re-auth for email users) — the Apple *capability* requirement is met. However, Apple's guideline requires deleting the **account and associated data**; as flagged in Section 1, `users/{uid}/**`, circle messages, and memberships are never purged and become permanently inaccessible orphans. This is both a privacy-label inaccuracy and a plausible review/complaint vector.
- **Fix:** same as Section 1 — server-side purge on account deletion.

### [MEDIUM] No minification/obfuscation configured, and no ProGuard rules staged
- `android/app/build.gradle.kts` release block sets no `isMinifyEnabled`/`isShrinkResources`; `android/app/proguard-rules.pro` does not exist
- Today the release APK ships unshrunk and unobfuscated (larger binary, trivially decompilable). The sharper edge: the day someone enables minify without adding keep-rules for Isar (`isar.**`), flutter_local_notifications (Gson `TypeToken`), and Firebase, release builds will crash at runtime in ways debug never shows.
- **Fix:** enable minify+shrink with `flutter build --obfuscate --split-debug-info`, and add the Isar/notifications keep-rules now.

### [LOW] Real Google OAuth reversed client ID re-added to tracked Info.plist
- `ios/Runner/Info.plist:31-36` — `com.googleusercontent.apps.8992228827-...` URL scheme, in a **tracked, currently-modified** file, after commit `32a1bda` deliberately replaced it with a placeholder. Client IDs are public identifiers (not secrets), but the working tree silently reverts that commit's policy.
- **Fix:** decide once — either the scheme is fine to track (revert 32a1bda's placeholder approach) or restore the placeholder + build-time injection; the current half-state will keep regressing.

### [LOW] Raw `print()` and `debugPrint` output in release builds
- `lib/core/bootstrap/app_bootstrap.dart:37, 59` (`print('[NotifTap] ...')` with `// ignore: avoid_print`, marked TEMP) plus pervasive `debugPrint` (neither is stripped in release). Log noise plus the partial-identifier leakage flagged in Section 1.
- **Fix:** remove the TEMP prints; gate `debugPrint` behind `kDebugMode` or a logger with release filtering.

### Verified OK (Release & Compliance)
- **iOS bundle identity**: Runner is `com.milkesa.coachForLife` (project.pbxproj:495/678/701); only the non-shipping RunnerTests target still uses `com.example.*`. Version `1.0.1+2` (pubspec.yaml:19) is sane; Podfile targets iOS 13.0, static frameworks.
- **iOS permission strings all map to real features** (`Info.plist:82-87`): photo library → `image_picker` proof uploads; microphone + speech recognition → `speech_to_text` Coach dictation. No orphaned or missing usage descriptions found for the current feature set.
- **Account-deletion capability** (Apple hard requirement) is present, discoverable in settings, and correctly re-authenticates before destructive action — the gap is server-side purge only.
- **Notification permission *request* flow** is correctly lazy on Android and correctly retried per-surface; `requestPermissionsIfNeeded` is invoked at the two reminder-creating touchpoints rather than blindly at startup (the iOS init-time default is the one exception, flagged above).
- **No dev/staging Firebase project split found**: a single Firebase project config is used; the debug-only Remote Config behavior (`kDebugMode` → zero fetch interval, `ai_remote_config_service.dart:34-36`) correctly tightens to 1h in release.

## 5. Performance

_Audited 2026-07-02. Scope: home/timer/focus/community presentation, execution_controller.dart, planned_task_providers.dart, Isar schemas (lib/core/local_db/isar_collections/), app_bootstrap.dart, main.dart, image flows. Report-only; no fixes applied._

> **RESOLVED 2026-07-05** — every finding in this section was fixed except
> the community `ListView.builder` conversion (deferred per its own "when
> list sizes become user-controlled" scoping). See [PERFORMANCE.md](PERFORMANCE.md)
> for what/why/how each fix works and the invariants it introduced.

### [HIGH] Home screen rebuilds every second during a focus session — `select()` is never used anywhere in the app
- `lib/features/execution/application/execution_controller.dart:84-85` (engine tick → `state = state.copyWith(elapsed: ...)` every second) + `lib/features/home/presentation/home_screen.dart:75` (`ref.watch(executionControllerProvider)` at the top of the HomeScreen build)
- While a timer runs, the whole-object watch invalidates the entire home Scaffold — including the non-builder `ListView` body (`:107`) with the analytics card, goals, and task sections — **once per second**, even though the build only uses `targetType`/`taskId`/`phase`, never `elapsed`. The same whole-object watch appears in `focus_selection_screen.dart:240` and `delivery_providers.dart:137` (which needs only `.phase.name` but recomputes its provider subgraph every tick). Repo-wide grep for `.select(` returns **zero** matches — the primary Riverpod rebuild-scoping tool is unused.
- **Fix:** `ref.watch(executionControllerProvider.select((s) => (s.targetType, s.taskId, s.phase)))` at these three sites; adopt `select()` for any watch that reads a subset of a frequently-changing state object.

### [HIGH] Disk write on every timer tick
- `lib/features/execution/application/execution_controller.dart:86-98` — the same per-second engine listener fires `runtimeCache.save(...)` (unawaited), serializing and persisting the full resume state 60×/minute for the entire session.
- Continuous storage I/O for the whole focus session (battery + flash wear + jank risk on slow storage), when the data being saved changes meaningfully only on phase transitions — `elapsed` is derivable from `runningSince` at restore time.
- **Fix:** persist on phase transitions plus a coarse checkpoint (e.g. every 15-30s), reconstructing elapsed from the stored `runningSince` timestamp.

### [HIGH] First frame is blocked on network calls in bootstrap
- `lib/main.dart:15` (`await AppBootstrap.initialize(container)` before `runApp`) + `lib/core/bootstrap/app_bootstrap.dart:46` (anonymous sign-in — network round-trip on first launch), `:48-57` (notifications init incl. the iOS permission prompt from Section 4), `:76` (`scheduleFromCache` awaited), `:81-95` (when signed in: `fetchGoalsOnce()` **network fetch**, `applyForGoals`, and `AccountabilityRetentionWorker` Firestore batch deletes — all awaited)
- The user stares at the native splash until Firebase init + auth + a Firestore goals fetch + maintenance pruning complete. On a slow connection that is multi-second cold start; only Firebase init and the Isar open (`:60`) genuinely need to precede the first frame.
- **Fix:** split bootstrap into a minimal pre-frame phase (Firebase + Isar) and a post-first-frame phase (`addPostFrameCallback`/deferred future) for sign-in, notification wiring, goal reminder sync, and retention pruning; AuthGate already renders a spinner that can cover the async tail.

### [MEDIUM] Side effect executed inside `build()`
- `lib/features/home/presentation/home_screen.dart:78` — `_maybeTriggerMorningBrief(context, ref)` runs on **every** home rebuild (i.e., once per second during a focus session until the select() fix lands, and on every task-list emission otherwise), doing date/window checks and potentially showing a snackbar from the build phase.
- **Fix:** move to `ref.listen` on the enabling condition, or a one-shot in `initState`/first-frame callback.

### [MEDIUM] Chat/proof images: no disk cache, no decode sizing, uncompressed challenge uploads
- `lib/features/community/presentation/views/circle_chat_view.dart:452` — `Image.network` (no `cached_network_image` dependency in pubspec.yaml): proof images re-download on every app session (Flutter's cache is memory-only), and with no `cacheWidth`, each ~1080px source is decoded at full resolution for a 220-logical-px bubble — several MB of RAM per visible message.
- `lib/features/community/presentation/views/circle_challenges_view.dart:635-637` — challenge proof picker sets **no** `imageQuality`/`maxWidth` (unlike the chat picker, which correctly uses quality 70 / maxWidth 1080 at `circle_chat_view.dart:88-91`), so original camera images upload at up to the 10MB rules limit and then get re-downloaded full-size by every member.
- **Fix:** add `cached_network_image` (or `Image.network(cacheWidth: ...)` at minimum) for feed/chat images; mirror the chat picker's compression settings in the challenges picker.

### [MEDIUM] Two providers recompute the full prioritized task list on a shared 1-minute poll (cross-ref §3)
- `lib/features/planning/application/planned_task_providers.dart:109-135` and `:163-184` — `todayAllTasksRowsProvider` and `homeFlowSnapshotProvider` each run their own `Timer.periodic(1 min)` plus three `watchLazy` triggers, and each emit re-reads routines + blocks + tasks from Isar and re-runs prioritization — duplicate work over identical inputs, running forever because the bootstrap bridge pins both providers (Section 3).
- **Fix:** derive `homeFlowSnapshotProvider` from `todayAllTasksRowsProvider` instead of re-querying; replace the 1-minute poll with a timer scheduled to the next block boundary.

### [LOW] Non-builder `ListView`s materialize all children in community views
- `circle_members_view.dart:51-115`, `weekly_commitments_view.dart:38-85`, `circle_activity_view.dart:121`, `circle_discovery_screen.dart:351` — `ListView(children: [...spread .map()])` builds every row up-front. Today the backing queries are capped (50 messages / 30 feed items), so impact is bounded; it becomes real if member counts or discovery results grow. The remaining `ListView(` hits (settings, editors, detail screens) are short static forms — fine.
- **Fix:** switch the four community views to `ListView.builder`/`SliverList` with item keys when list sizes become user-controlled.

### [LOW] Coarse invalidation after every successful sync
- `lib/core/sync/post_sync_refresh_coordinator.dart:44-46` + `unified_recompute_graph` full-refresh scope — every successful remote pull (as often as every 30s) invalidates the task list providers and schedules a full analytics/coaching recompute regardless of whether the pull changed anything.
- **Fix:** have `RemoteIsarMerge` report whether any row was actually applied and skip the refresh when the pull was a no-op (common case).

### Verified OK (Performance)
- **Isar schemas are well-indexed**: every collection has a unique business-id index plus indexes on the exact fields queried (`routineId`, `blockId`, `dateKey`, timestamp fields — `isar_task.dart:11-23`, `isar_routine.dart:12-16`, `isar_block.dart:11-15`, analytics/AI caches likewise). No unindexed filter fields found in the query paths sampled.
- **No Isar queries inside build methods** — all data access flows through providers/repositories; widgets only watch.
- **`ListView.builder` is used where it matters** (15 sites: chat, feeds, task hub, history lists); `ReorderableListView` children carry keys as required.
- **Const discipline in the home tree is good** — the hot sections (`_HomeTopAnalyticsCard`, app-bar widgets, bridges) are const-constructed, which caps the damage of the per-second rebuild flagged above.
- **Chat image picker compression** (`circle_chat_view.dart:88-91`) is correctly configured; the gap is only the challenges picker.

## 6. Cleanup

_Audited 2026-07-02. Method: repo-wide reference counting for providers/classes/deps, implementation counts per abstraction, duplicate-pattern grep. All LOW severity except where noted. Report-only._

### [LOW] 28 providers declared but never consumed anywhere in lib/ (spot-checked: almost none in tests either)
- Heaviest cluster is the analytics layer-2/3/4 surface — `pattern_detection_providers.dart` (5: `layer2EntityPatternsProvider`, `layer2EntityCanonicalPatternsProvider`, `layer2TodayGlobalSnapshotProvider`, `layer2TodayGlobalCanonicalSnapshotProvider`, `layer2TodayRunMetadataProvider`), `insight_generation_providers.dart` (4), `delivery_providers.dart` (3: `layer4TodayHomeDecisionProvider` — 1 test ref — `layer4TodayHistoryProvider`, `layer4TodayRunMetadataProvider`), `feature_cache_providers.dart` (3), plus `dailyTaskAnalyticsProvider`, `habitKpiSnapshotProvider`, `habitStreakSummaryProvider`, `habitTaskFallbackSnapshotProvider`, `focusHistoryProvider`, `featureBuilderInputsProvider`, `patternDetectionDebugEventsProvider`.
- Elsewhere: `isSignedInProvider`/`isRegisteredProvider` (auth_providers.dart), `latestWeeklyPulseProvider` (ai_pulse_providers.dart), `totalCompletionsCountProvider` (profile_providers.dart:61), `reminderCacheStoreProvider` (di/providers.dart:89, already `@Deprecated`), `syncServiceProvider` (di/providers.dart:47).
- Two of these hide real issues: (a) `syncServiceProvider` exists but every call site uses `SyncService.instance` directly — the DI seam was built and then bypassed, which is why SyncService is untestable/unmockable everywhere (relevant to §2's findings); (b) `habitKpiSnapshotProvider`/`habitStreakSummaryProvider` were flagged in §3 as unbounded `.family` caches — they're also dead, so the cheapest fix is deletion.

### [LOW] Fully dead UI-state providers that are still ceremonially invalidated on logout
- `lib/features/ui_state/ui_state_providers.dart:3-5` — `selectedTaskProvider`, `timerRunningProvider`, `timerDisplayProvider` have **zero** references outside their declarations and `user_scoped_invalidation.dart:55-57`. The real timer state lives in `executionControllerProvider`; these are leftovers from an earlier demo (hence the `'Deep Work: UI Architecture'` / `'25:00'` defaults).
- This supersedes §3's "demo-value defaults" finding for these three — they can't leak into UI because nothing watches them. The cleanup win is the file plus three lines of the invalidation list; their presence in that list makes the list look more complete than it is.

### [LOW] The offline-write helper is copy-pasted across the data layer
- Same `try { direct Firestore set/delete } catch (_) { SyncService.instance.enqueue… }` block appears in at least 8 files: `isar_planning_repository.dart:29-57`, `planning_repository.dart:74-89`, `goals_repository.dart:55-83` (`_upsertWithQueue`/`_deleteWithQueue`), `isar_goals_repository.dart:23-38`, `execution_repository.dart:39-49`, `scoring_repository.dart:28-38`, `reminder_repository.dart:64-74`, `isar_reminder_repository.dart:58-68`, `analytics_repository.dart` + `isar_analytics_repository.dart` (4 more copies).
- Bug-hiding: §2's fixes (retryable-error classification, uid tagging, backoff) must be applied to every copy; any one missed silently keeps the old behavior. Extract to a single `syncedSet()/syncedDelete()` helper next to SyncService.
- Same pattern in miniature: `remote_isar_merge.dart:151-229` has six structurally identical `_mergeX` methods (fetch-existing → LWW check → `writeTxn` put) that differ only in collection and key — a single generic merge function would also enable §2's batching fix in one place.

### [LOW] 11 single-implementation abstractions with no test seam using them
- All community repositories declare an abstract class with exactly one `Firestore*` implementation and **zero** test implementations: `CircleRepository`, `CircleMemberRepository`, `CircleMessageRepository`, `ChallengeRepository`, `ActivityFeedRepository`, `WeeklyCommitmentRepository`, `RemovalVoteRepository`, `AiPulseRepository`, `CircleNotifPrefsRepository` (lib/features/community/data/*.dart), plus `ScoringRepository` (scoring_repository.dart:7) and `ConflictResolutionPort` (conflict_resolution_port.dart:5).
- Contrast with the justified ones: `GoalsRepository` (2 lib impls + 3 test fakes), `PlanningRepository` (Isar + Firestore), `AuthRepositoryInterface`, `ExecutionRepository`, `TimeBlockRepository`, `ProfilePreferenceRepository` all have test doubles. The community layer pays the indirection tax without collecting the benefit — either write the fakes (the community feature has essentially no unit tests today) or collapse the interfaces.

### [LOW] Deprecated/legacy code retained
- `lib/features/reminders/data/reminder_cache_store.dart` — entire file `@Deprecated`, its only reference is the equally unused provider above; delete both.
- `lib/features/analytics/application/pattern_layer2_compatibility.dart` — self-described "Temporary adapter: canonical Layer 2 → legacy" still bridging `behavior_pattern_phase2.dart:133`; the migration it was temporary for appears stalled.
- `lib/features/analytics/application/discipline_score.dart:82` — `@Deprecated` `disciplineActiveStreakDays` (no non-deprecated callers found); `lib/features/planning/domain/models/routine_mode.dart:6` — another deprecated member.
- `lib/features/firebase_test/` — entire feature directory is a diagnostics screen; §4 already flags its release reachability [HIGH there]; from a cleanup angle it should be deleted or moved under a debug-only flag rather than shipped.

### [LOW] Unused dependency
- `pubspec.yaml` — `cupertino_icons`: zero `CupertinoIcons` references in lib/. Safe to drop.
- **Not** unused despite zero imports: `isar_flutter_libs` (ships the native Isar binaries — required at runtime). Flagging explicitly so a future dep-prune doesn't remove it.

### [LOW] Near-duplicate accountability-log deletion loops
- `lib/features/planning/data/planning_repository.dart:294-322` — `deleteAccountabilityLogsInRange` and `pruneOldAccountabilityLogs` both fetch-then-loop over `deleteAccountabilityLog(l.id)` per document (also an N+1 of round trips); one parameterized range-delete using a batched write would replace both bodies.

### Verified OK (Cleanup)
- **Isar collection schemas**: all 23 collections in `isar_schemas.dart` are referenced by live repositories/providers; no orphaned collections found.
- **Interfaces with test seams** (`GoalsRepository`, `PlanningRepository`, `AuthRepositoryInterface`, `ExecutionRepository`, `TimeBlockRepository`, `ProfilePreferenceRepository`, `ReminderSyncService`'s notification port) are earning their keep — the pattern itself is fine; it's the blanket application to the community layer that isn't.
- **Dev dependencies** are all in use (`isar_generator`/`build_runner` for codegen, `fake_cloud_firestore` in tests, `flutter_lints` via analysis_options.yaml).

---

## 7) Final audit — security, performance, reliability (2026-07-06)

_Audited on branch `fix/ai-chat-context` at 1000 passing tests. Report-only;
no fixes applied. Every finding was verified against the code, not assumed._

> **Implementation spec:** [`AUDIT_FIX_PLAN.md`](AUDIT_FIX_PLAN.md) — exact
> rule blocks, code changes, deploy commands, and verification per finding,
> written to be executed mechanically by a lower-effort session.

### 7.1 Security

| # | Sev | Finding |
|---|-----|---------|
| S1 | **HIGH** → **FIXED** `d200c40` | **`weeklyCommitments` writable by any circle member.** `firestore.rules` grants `allow read, write: if canAccessCircleContent(circleId)` — write covers create/update/delete of ANY member's commitment docs. A member (or holder of a stale `circleIds` index) can edit, delete, or inflate `completedCount` on other members' commitments. The client only writes its own (`setCommitments`, `markProgress`) but the rules don't enforce it. Fix direction: `create` requires `request.resource.data.userId == request.auth.uid`; `update/delete` require `resource.data.userId == request.auth.uid` (progress updates could additionally restrict `affectedKeys` to `completedCount`/`updatedAtMs`). |
| S2 | **HIGH (cost abuse)** → **FIXED** `5be5653` (App Check still TODO) | **`aiChat` callable: no App Check, anonymous accounts accepted.** Guest mode is default (`kRequireRegisteredAuth` defaults `false`), the function only checks `request.auth != null`, and the 40/hour quota is **per uid**. Anonymous sign-up is free and scriptable → fresh uid = fresh quota → unbounded OpenAI spend. No App Check anywhere in the app or functions. Fix direction: enable Firebase App Check and enforce on the function; and/or reject or heavily throttle `sign_in_provider == 'anonymous'`; set a billing alert regardless. |
| S3 | MED → **FIXED** `ee82115` | **`challenges` docs updatable by any member** (`allow update: if isCircleMember`) — title/target/status of anyone's challenge can be rewritten by any member (votes subcollection is properly scoped). Restrict metadata updates to creator/moderator or whitelist fields. |
| S4 | MED | **Any signed-in user can read all circle metadata and full member lists** (`/circles/{id}` and `/members` both `allow read: if isSignedIn()`). No private-circle flag exists today, so this is "public by design", but membership enumeration across all circles is a social-graph leak worth a deliberate decision before launch. |
| S5 | MED → **FIXED** `ee82115` | **Chat proof uploads not uid-namespaced and not write-once.** `storage.rules` lets any member write ANY filename under `circles/{id}/proofs/` — overwriting another member's proof is possible if the name is known (StableIds are timestamped+random, so hard to guess, but nothing enforces immutability). `challenge_proofs` got this right (uid-prefix). Mirror that, or make proofs create-only. |
| S6 | LOW → **FIXED** `9cd619d` | **Reactions are blocked by the message-update rule (fails closed).** `updateReactions` writes to other members' message docs, but the rule requires `resource.data.senderId == request.auth.uid` → reacting to someone else's message is permission-denied (feature broken, not exploitable). Inverse gap: a sender can forge arbitrary uids inside `reactions` on their own message. Proper fix: dedicated rule allowing only the `reactions` key to change with the caller's own uid added/removed, or a reactions subcollection. |
| S7 | LOW | **153 `debugPrint` call sites, no release override.** `debugPrint` is not stripped in release builds; task titles/uids leak into device logs. Override it to a no-op in release in `main()`. |
| S8 | INFO | **Prompt injection surface** — task titles/notes flow into LLM prompts. Mitigated: model is pinned server-side, all mutations require the user to confirm a preview card, informational output is sanitized. Keep the confirm-gate invariant. |
| S9 | INFO | Anonymous uid-change → local-data wipe (`AuthSessionPolicy`) remains the known data-loss trap; already documented. |

**Verified OK:** `users/{uid}/**` rules airtight (owner-only); message `create` enforces `senderId == auth.uid`; `activityFeed` immutable after post; votes uid-scoped; OpenAI key via `defineSecret` (never in repo — grepped); model/token caps pinned server-side; per-turn quota accounting with loop bounds; offline queue drops foreign-uid ops; AI history has a 48h TTL purge.

### 7.2 Performance & app speed

| # | Sev | Finding |
|---|-----|---------|
| P1 | **HIGH (grows silently)** | **Every remote pull reads entire collections.** `RemoteIsarMerge` has no `updatedAtMs > lastSync` cursor: each pull (app open, connectivity change, 30s debounce window) re-downloads ALL routines→blocks→tasks (serial nested gets), reminders, goals, **analytics_events**, analytics_stats. Firestore read cost and pull latency grow with account age — analytics_events is unbounded. Fix direction: per-collection since-cursor + occasional full reconcile; flatten the nested routine/block/task walk with collection-group queries. |
| P2 | MED | `goalDetailProvider` loads **all check-ins ever** per open (`getCheckInsForGoal` unbounded); streak/cycle math needs ~90 days at most. Cap the query window. |
| P3 | MED | AI payload includes full week overview + schedule + patterns on **every** message → token cost per turn scales with schedule size. Consider trimming payload sections by intent route (the router already exists). |
| P4 | LOW | Four community `ListView`s still non-builder — bounded by query caps (30–50), fine until caps lift (already documented). |
| P5 | LOW | Duplicate-analytics "Unique index violated" skip logs every 30s pull — fix already in flight as a background task. |
| P6 | INFO | July-5 perf pass verified still intact: `select()` scoping, shape-only timer persistence, pre-frame/deferred bootstrap split, no-op-pull refresh skip, disk-cached chat images. No regressions found. |

### 7.3 Reliability & code quality

| # | Sev | Finding |
|---|-----|---------|
| R1 | MED | **57 swallowed-error sites** (`error: (_, _) => genericText`, `catch (_) {}`). This exact pattern hid the commitments outage (incident #18). Minimum: log the error; better: surface a retry. |
| R2 | MED | **4 `use_build_context_synchronously`** spots (add_task 1416, focus_selection 119, goal_editor 695, home 2187) — context used across async gaps without a mounted guard; latent use-after-dispose crashes. |
| R3 | LOW | Deprecated API debt: ~9 `withOpacity` (→ `withValues`), `ReorderableListView.onReorder` (tasks hub), and `RoutineMode` is `@Deprecated` yet still core to `EffectiveTaskMode` — the migration it points to (CoachingStyle/EnforcementMode) is unfinished. |
| R4 | LOW | Analyzer baseline: 105 infos/warnings (style-level; no errors). |
| R5 | LOW | **Dependency staleness:** entire Firebase suite one major behind (`cloud_firestore` 5.6→6.6, `firebase_auth` 5.7→6.5, `firebase_core` 3→4, …), `flutter_local_notifications` 19→22, Riverpod 3 available. No pub-flagged advisories, but majors compound migration risk. |
| R6 | INFO | Tests: 1000 passing, strong unit/widget coverage (AI pipeline, planning, scoring, rules-adjacent repos). Gaps: no integration test for the sync round-trip/LWW, the uid-change wipe path, notification scheduling e2e; no golden tests for the redesigned screens. |
| R7 | LOW → **FIXED** `9cd619d` | **AI pulse write-rule mismatch:** any member's client triggers `savePulse`, but `aiPulse` writes are moderator-only in rules → silent permission-denied for non-moderator members (banner just never updates for them). Functional, fails closed. |

### 7.4 Hygiene & other

- **H1 (FIXED `38fe467`):** `ios/build/` is untracked but NOT gitignored (`.gitignore` has root `/build/` only) — add `ios/build/`. Stray root `package-lock.json` (npm lives only in `functions/`) — remove or ignore.
- **H2:** `firestore.indexes.json` is now authoritative — keep console drift at zero (deploy indexes with rules in the same PR).
- **H3 (accessibility):** near-zero `Semantics` usage outside the app bar brand; several 9.5–11px all-caps labels; `textFaint` (#666) on ink (#0E0E0E) ≈ 4.6:1 — AA-passing for large text only. Needs a deliberate a11y pass before store review.

### 7.5 Priority order

1. **Before any public/beta exposure:** S1, S2 (rules + cost abuse), H1 (one-liner).
2. **Next sprint:** P1 (sync cursors — cost grows every day it waits), S3, S5, S6/R7 (circle integrity + broken reactions), R2.
3. **Scheduled debt:** R1 error-surfacing sweep, P2, P3, R5 major upgrades, H3 a11y pass, R6 integration tests.
