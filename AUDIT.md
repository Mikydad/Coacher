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
| S7 | LOW → **FIXED** `c10000d` | **153 `debugPrint` call sites, no release override.** `debugPrint` is not stripped in release builds; task titles/uids leak into device logs. Override it to a no-op in release in `main()`. |
| S8 | INFO | **Prompt injection surface** — task titles/notes flow into LLM prompts. Mitigated: model is pinned server-side, all mutations require the user to confirm a preview card, informational output is sanitized. Keep the confirm-gate invariant. |
| S9 | INFO | Anonymous uid-change → local-data wipe (`AuthSessionPolicy`) remains the known data-loss trap; already documented. |

**Verified OK:** `users/{uid}/**` rules airtight (owner-only); message `create` enforces `senderId == auth.uid`; `activityFeed` immutable after post; votes uid-scoped; OpenAI key via `defineSecret` (never in repo — grepped); model/token caps pinned server-side; per-turn quota accounting with loop bounds; offline queue drops foreign-uid ops; AI history has a 48h TTL purge.

### 7.2 Performance & app speed

| # | Sev | Finding |
|---|-----|---------|
| P1 | **HIGH (grows silently)** → **FIXED** `840de55` | **Every remote pull reads entire collections.** `RemoteIsarMerge` has no `updatedAtMs > lastSync` cursor: each pull (app open, connectivity change, 30s debounce window) re-downloads ALL routines→blocks→tasks (serial nested gets), reminders, goals, **analytics_events**, analytics_stats. Firestore read cost and pull latency grow with account age — analytics_events is unbounded. Fix direction: per-collection since-cursor + occasional full reconcile; flatten the nested routine/block/task walk with collection-group queries. |
| P2 | MED | `goalDetailProvider` loads **all check-ins ever** per open (`getCheckInsForGoal` unbounded); streak/cycle math needs ~90 days at most. Cap the query window. |
| P3 | MED | AI payload includes full week overview + schedule + patterns on **every** message → token cost per turn scales with schedule size. Consider trimming payload sections by intent route (the router already exists). |
| P4 | LOW | Four community `ListView`s still non-builder — bounded by query caps (30–50), fine until caps lift (already documented). |
| P5 | LOW | Duplicate-analytics "Unique index violated" skip logs every 30s pull — fix already in flight as a background task. |
| P6 | INFO | July-5 perf pass verified still intact: `select()` scoping, shape-only timer persistence, pre-frame/deferred bootstrap split, no-op-pull refresh skip, disk-cached chat images. No regressions found. |

### 7.3 Reliability & code quality

| # | Sev | Finding |
|---|-----|---------|
| R1 | MED → **FIXED** `bbd93ea` | **57 swallowed-error sites** (`error: (_, _) => genericText`, `catch (_) {}`). This exact pattern hid the commitments outage (incident #18). Minimum: log the error; better: surface a retry. |
| R2 | MED → **FIXED** `9d486c9` | **4 `use_build_context_synchronously`** spots (add_task 1416, focus_selection 119, goal_editor 695, home 2187) — context used across async gaps without a mounted guard; latent use-after-dispose crashes. |
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

## 8) AI chat & live conversation — deep audit (2026-08-27)

_Audited on branch `feat/ux-fixes-and-stake-surrender`. Scope: everything AI —
the chat pipeline (send → parse → agent loop → render/store), the Cloud
Functions backend (`aiChat`, `aiChatStream`, `aiSpeech*`, `ai_routing`),
context/payload assembly + memory extraction/injection, the action executor
(confirm gate, batches, undo), Voice Mode end-to-end (STT → LLM → TTS), the
Coach sheet UI, conversation persistence/tiering, and the secondary AI
surfaces (coaching summary, circle pulse, proactive engine, thinking loop).
~18k lines read in full by seven parallel deep-readers; all 15 distinct
CRITICAL/HIGH claims were then each handed to an independent adversarial
verifier instructed to refute them against the live code. **None were
refuted**; three were downgraded to MEDIUM where verification narrowed their
reach. Findings marked **✓ verified** went through that pass; the rest are
single-reader findings with exact citations. Report-only; no fixes applied.
Yardstick, per Miko: "a ChatGPT-level assistant that does what it's supposed
to do."_

**The one-paragraph verdict:** the scaffolding around the model is genuinely
excellent — server-pinned models and quotas, a bounded agent loop, a
deterministic clarify-loop, quote-verified memory extraction, an airtight
confirm-gate topology, honest offline capture — but the core promise breaks
at the last step: **five of the confirmed mutation verbs are no-op stubs that
report success** (move/delete task, modify/delete goal, remove reminder),
**edit duplicates instead of editing**, and **undo cannot revert creations**.
The coach says "Done — moved it to tomorrow" and nothing moved. Everything
else in this section is secondary to that: a coach that confirms actions it
did not perform is not a trust problem to polish later, it is the product
gap. The second systemic theme: the project's own "optimistic-then-honest /
Telegram model" rule is not implemented on its flagship AI surface — failed
turns have no retry, several failure modes are silently presented as success,
and two kill-switch paths actively fabricate content.

### 8.0 How it works today (orientation)

- **Client pipeline** — `AiAssistantService.sendMessage` runs local guards
  (guest nudge, yes/no plan interception, decline regexes), then
  `AiIntentParser.parse` assembles an all-Isar payload and drives a bounded
  tool-calling agent loop (≤4 rounds, 20s each) against the `aiChat`
  callable; `propose_changes` becomes the confirm card, `get_day_schedule`
  executes locally between rounds. Results pass through the unrequested-
  delete guard, param normaliser, missing-field detector, assumption engine,
  deduplicator, and conflict detector before rendering. The thread is
  in-memory per sheet-open; turns persist to device-local Isar history
  (last 10 feed the next prompt; summarize-then-purge distills them into
  synced memory at 48h).
- **Server** — two Cloud Functions in us-central1 (Node 22, raw `fetch`, no
  SDK/retries): `aiChat` (agent turns) and `aiChatStream` (NDJSON deltas for
  conversational voice). Per-purpose routing pins model (gpt-4o-mini
  everywhere), temperature, and token caps, RC-overridable behind a model
  allow-list. Quota: 40 charged turns/uid/hour in a Firestore transaction run
  concurrently with the OpenAI call; agent follow-ups sharing a `turnId` are
  free (≤3); system purposes draw a separate silent-skip daily budget.
  Anonymous uids are rejected; App Check is still a TODO.
- **Voice** — a per-entry phase machine (connecting/listening/thinking/
  speaking) over three seams: `speech_to_text` (pauseFor 1.8s, continuation
  stitching, stall watchdog), a resilient TTS stack (OpenAI head+tail clips
  over one keep-alive client, falling back to on-device with a 60s cooldown),
  and two reply paths — query turns stream `aiChatStream` sentence-pipelined,
  everything else takes the agent path and is spoken from the settled bubble.
  Confirm-by-voice reads the plan aloud; spoken "confirm" is intercepted
  locally.
- **Secondary surfaces** — coaching summary (analytics), circle AI pulse,
  proactive suggestion engine, thinking loop, memory extraction — all share
  `AiProxyClient` but each duplicates its own prompt builder, parser, and
  fallback semantics.

### 8.1 Execution integrity — the coach says "done" when nothing happened

| # | Sev | Finding |
|---|-----|---------|
| E1 | **CRITICAL** ✓ verified | **Five confirmed mutation kinds are no-op stubs that report success.** `_moveTask` returns `'Moved "…"'`, `_deleteTask` returns `'Deleted "…"'`, `_modifyGoal`/`_deleteGoal` return success strings, `_removeReminder` writes nothing (`ai_action_executor.dart:965-977, 1021-1031, 1065-1068`) — all with `// Full implementation: …` comments. The model is offered all of them in the tool enum (`ai_operating_layer_client.dart:304-323`) and `AiCapabilityRegistry.supportedMutate` advertises them. User says "delete my 3pm meeting", reviews the card, taps CONFIRM — chat says done, batch marked completed, `markExecuted` stamps the session, and the task still sits on the schedule firing reminders. The executor's own standard elsewhere (`suggestFreeTimeBlock` **throws** UnsupportedError "so confirm does not look successful", `:641-646`) proves fake success is a recognized anti-pattern; these handlers violate it. Worse, `quickDirectivesProvider` pins "Move schedule" / "Remove task" / "Edit task" as top chips by usage frequency — the UI actively advertises the broken verbs. **Fix:** implement the five handlers against the existing repositories (title→id resolution via `_findTaskRowByTitle`, `planningRepository.deleteTask`/`upsertTask` with new `planDateKey`, `goalsRepository`, `reminderSyncService.removeForDeletedTask`); until each is real, remove it from `kCoachAgentTools`, the capability prompt, and the directive chips so the model routes around it. |
| E2 | **HIGH** ✓ verified | **editTask creates a duplicate task instead of editing.** `_editTask` builds a `PlannedTask` with a fresh `StableId`, priority 3, orderIndex 0, status notStarted, no modeRefId/notes/category and upserts it (`ai_action_executor.dart:912-963`; the comment admits "Simplified: upsert a new task"). "Change my 9am workout to 10am" → a second workout at 10:00 while the 9:00 original stays; the clone loses enforcement mode and completion state and skips `tierGuard.ensureCanCreateTask`. **Fix:** resolve the existing row and upsert the same id with changed fields (`_attachReminderToExistingTask` at `:1174-1204` already shows the correct copy-all-fields pattern). |
| E3 | **HIGH** ✓ verified | **Undo/rollback cannot revert creations — the most common batch kind.** `_captureSnapshot` snapshots only pre-existing *task* rows (`:312-360`); `_rollbackBatch` only re-upserts them (`:366-413`). A created task (plus its ReminderConfig, armed OS notification, derived time block, or a created goal) is not in the snapshot, so "Undo AI changes" returns UndoSuccess — "AI changes have been undone." — while everything created survives. The same gap makes the partial-failure message "I've restored your schedule to its previous state" false whenever the failed batch contained creates. **Fix:** pre-assign client ids for createTask/createGoal exactly like `_intentionId` already does, persist in actionsJson, and have rollback delete those ids before restoring the snapshot — or better, record an inverse-operation log per dispatched action (see 8.9). |
| E4 | **HIGH** ✓ verified | **The undo-warning dialog's Cancel is fake — rollback already ran.** `_undoBatch` unconditionally calls `_rollbackBatch` *then* returns `UndoWarningTasksCompleted` (`ai_action_executor.dart:293-303`); the screen then shows "Undoing will revert those completions" with Cancel / "Undo anyway" (`ai_assistant_screen.dart:1706-1747`; the comment at `:1737` admits it). Whatever the user presses, their completions were already reverted — and LWW propagates the reversion to other devices. Cancel also skips the provider invalidations, leaving the stale Undo chip pointing at a rolled-back batch. **Fix:** split into dry-run check → dialog → rollback-on-confirm. |
| E5 | **HIGH** ✓ verified | **The undo entry point never appears when it matters.** `lastAiBatchProvider` / `canUndoLastAiBatchProvider` / `recentAiBatchesProvider` are cached non-autoDispose FutureProviders watching only `authUidProvider` (`ai_assistant_providers.dart:159-184`); the only invalidations live *inside the undo handlers themselves* — circular: refreshing the undo affordance requires performing an undo. After the user confirms a plan, the "Undo AI changes" chip stays at its stale pre-confirm value for the rest of the app session; the gap hides a feature the executor correctly persists. (Verification refinements: a sheet-mode first mount after the session's first confirm can show the chip correctly once; auto-committed intention messages have their own working inline Undo — the missing affordance specifically hits confirmed preview-card plans. Staleness also runs the other way: a cached `true` never re-checks the 30-min window, leaving a dead chip.) Also violates the house rule that UI reads Isar watch streams. **Fix:** StreamProviders over `isarAiActionBatchs` watches (`fireImmediately: true`) — which deletes every manual invalidate. |
| E6 | **HIGH** ✓ verified | **A decorative action in a confirmed plan poisons the whole batch.** `suggestFreeTimeBlock`/`moveConflictingTasks` throw UnsupportedError inside `_dispatch` (`:641-645`) but are still offered in the tool enum and rendered on the preview card. 4 creates + 1 suggest → the 4 succeed, the 5th throws, the batch rolls back "everything" (except, per E3, the created tasks survive), the message claims full restoration, and the batch lands `rolledBack` where undo is refused. `ExecutionResult` discards the successes list, so there is no per-item outcome — the exact opposite of the mandated per-item-error-with-retry model. **Fix:** strip non-executable kinds at parse time; report per-action outcomes instead of all-or-nothing rollback for independent actions. |
| E7 | MED | **Rollback/undo leaves armed OS notifications and ReminderConfig rows behind.** `_upsertReminderForTask` schedules notifications; `_rollbackBatch` never cancels or deletes configs (`:366-413, 1230-1276`) — and `reminder_sync_service.dart:112-119`'s own comment warns boot reconciliation re-arms every stored config. Undo a "remind me to stretch at 7pm" and the phone still rings at 19:00, forever. **Fix:** cancel + delete configs for batch-created tasks and re-sync restored ones during rollback. |
| E8 | MED | **Crash mid-batch strands it in `executing` — half-applied, no rollback, no undo, ever.** Nothing reconciles executing-state batches on boot; `_undoBatch` refuses them (`:277-284`). The persisted snapshot needed for repair sits unused. The adjacent "idempotency guard" (`:175-182`) is dead code — batchId is freshly generated per call and can never pre-exist. **Fix:** boot sweep rolling back stale pending/executing batches from their stored snapshot. |
| E9 | MED | **Unvalidated model dates write to phantom days and fire reminders today.** `_resolveDate` passes any non-today/tomorrow string through verbatim; `'Saturday'` becomes a `planDateKey` no screen queries (invisible task) while `_parseReminderDateTime`'s failure fallback is `DateTime.now()` — a mystery notification today (`:1287-1295, 1156-1172`). The normaliser canonicalises time but never date. **Fix:** canonicalise dates in `AiActionParamNormaliser` (weekday → next date key, validate `YYYY-MM-DD`), throw on unparseable. |
| E10 | MED | **Plan deduplicator is date-blind.** "Set up the same deep-work block for tomorrow" is silently dropped because a same-titled task exists *today*, and the coach answers "That already appears on today's list" (`ai_plan_deduplicator.dart:43-79`; dedupe set is today-only). **Fix:** skip the redundancy check when the action's resolved date differs from today. |
| E11 | MED | **The preview card doesn't say what an edit will change.** `describePlannedAction` renders `'Edit "Gym"'` / `'Update goal "x"'` with no old→new values even though the parameters carry them (`planned_changes_card.dart:212-230`; reminders inconsistently *do* show the time). The confirm gate is only as good as what it discloses; for edits it discloses nothing. **Fix:** render changed params ("Edit "Gym" — time → 19:00, duration → 45 min"). |
| E12 | MED | **Voice confirm never speaks conflicts or hard context blocks.** On the orb-only stage "the voice IS the preview", but `formatPlanForSpeech` renders actions only — a plan inside the sleep/DND window is read aloud with no mention of the red hard-block the sighted user sees, and spoken "confirm" executes it; `confirmPlan` doesn't gate on `isBlockedByContext` (`voice_plan_speech.dart:11-27`, `ai_assistant_service.dart:607-640, 719-754`). **Fix:** speak a warning sentence when `hasAnyWarnings`; require a second affirmation for hard blocks. |
| E13 | MED | **Assumption engine copies time/duration/enforcement mode off a single shared word.** One common >2-char word = similarity 0.7; the completed-task boost lifts it to exactly the 0.80 copy threshold — "add a call with mom" inherits the investor call's 07:30, 60 min, and strict enforcement mode (`ai_assumption_engine.dart:110-125`). The card's reasonLabel doesn't say which fields were guessed. **Fix:** require ≥0.9 similarity for the boost to reach the threshold, or exclude `modeRefId`; mark assumed values on the card. |
| E14 | MED | **Auto-committed forget/update resolves ambiguous memory refs by first containment match.** "Forget what I said about work" with two work-related facts tombstones whichever is newest, announced only as "Forgotten." (`ai_action_executor.dart:831-849`). **Fix:** on multiple matches, ask; always echo the affected fact's content; prefer `[mem:<id>]` refs the model already receives. |
| E15 | LOW | Reminder collision detector ignores dates and exempts exact-time collisions (`diffMinutes.abs() > 0` — two 09:00 reminders never warn; a months-old 09:02 does) (`ai_conflict_detector.dart:114-133`). Conflict detector's override-window math also breaks across midnight (`:221-233`). |
| E16 | LOW | `addReminder` onto an existing task bypasses the free-tier reminder cap (`:1174-1228` — no `ensureCanAddReminder`); `_editTask`'s create path bypasses the task cap. Latent until `TierLimits.enforced` flips true, then chat becomes the paywall sidestep. Related: `tier_limits.dart:53-55` claims a server-side per-day AI-instruction cap that **does not exist** — `functions/src/index.ts` has only the flat 40/hr with no tier lookup, so the free/pro AI differentiation the monetization PRD counts on is documented but unimplemented. |
| E17 | LOW | Unknown model actionType silently coerces to `createTask` (`ai_action.dart:96-104`) — a mis-emitted "completeTask" becomes a plausible-looking create card. Return null/throw and let the existing per-entry catch drop it into the repair round. Also: `pruneOld()` on the batch repo is dead code (snapshots of personal data retained forever), and coordinator notifications always carry placeholder entity ids (`'ai-task'`) because nothing writes `_resolvedTaskId` back. |

### 8.2 Honesty & the failure story — the Telegram model is not implemented here

| # | Sev | Finding |
|---|-----|---------|
| H1 | MED ✓ verified (downgraded from HIGH) | **Failed turns have no error state and no retry; the composer already cleared.** `AiChatMessage` has no error field; no error styling or per-message retry exists anywhere in the surface; the input was cleared before send (`ai_assistant_screen.dart:1019-1023`); the auto-commit failure path has the same gap despite its own doc comment claiming "errors surface honestly, per-item, Telegram-style" (`ai_assistant_service.dart:645, 664-679`). Verification corrected the mechanism: offline/rate-limit/server failures don't reach the service's outer catch — the parser catches them and returns *network-honest copy* as a followUpQuestion (`ai_intent_parser.dart:170-199`), so the words are honest but render as an ordinary bubble. Recovery = retype by reading your own bubble. CLAUDE.md principle 3 mandates per-item error with retry for exactly this surface; chat implements the optimistic half only. **Fix:** `isError` + originating input on the message, error styling, a Retry chip re-invoking the parse — and reuse the same `turnId` with `loopIndex>0` so the retry is quota-free (the server already supports this; today a retry double-charges). |
| H2 | MED ✓ verified (downgraded from HIGH) | **confirmPlan has no error guard — a throw leaves the chat dead.** `_setLoading(true); await execute(); await markConfirmed/markExecuted` with no try/catch/finally (`ai_assistant_service.dart:752-757, :787`) — the same call is wrapped in try/catch on the auto-commit path precisely because it throws. An escaping throw = `_isLoading` stuck true, SEND/dictation/card buttons all disabled, thinking dots forever; only closing the sheet (which wipes the conversation) recovers. A throw in markConfirmed/markExecuted lands *after* actions applied — user told nothing. Verification narrowed the trigger set: `_captureSnapshot` and `_rollbackBatch` swallow their own errors, and the "DB closed on logout" trigger doesn't exist (no `Isar.close()` in lib/); what remains is the unguarded Isar transactions (`findByBatchId`/`createBatch`/`updateState`/`markConfirmed`/`markExecuted`) on genuine DB faults — latent robustness gap on the most sensitive path, violating the project's own "failure story named" rule. **Fix:** try/catch/finally with an honest failure bubble; leave the card confirmable. Cheap. |
| H3 | MED | **Slow turns are blamed on the user being offline, and the abandoned turn still bills.** `deadline-exceeded` is classified as a network error (`ai_proxy_client.dart:33-35`) → "You're offline — I need a connection…" on a live connection (the developer's own slow-network norm); the server charged the turn at start, and the retype charges a second unit. **Fix:** split the copy ("That took too long…"); reuse turnId for retries. |
| H4 | MED | **Quota is charged with no refund when OpenAI fails.** The transaction deliberately runs concurrently with the fetch, but there is no compensating decrement on fetch failure / non-200 / empty content (`functions/src/index.ts:490-546`, same on the stream). During an OpenAI outage every retry burns one of 40 hourly turns delivering nothing, then the user is told they hit *their* limit. **Fix:** best-effort `increment(-1)` + clear lastTurnId on upstream failure. |
| H5 | MED | **Truncated streamed replies are presented — and persisted — as complete.** The server's SSE pipe loop ignores error events and `finish_reason` and emits `{"done":true}` on any clean upstream end (`index.ts:727-746`); on a mid-pipe throw it ends with *no* error line; and the Dart client treats stream-end-without-done as success anyway (`voice_reply_stream.dart:52-75`). A half-sentence coach reply is spoken and saved as a normal answer. The 500-token voice cap makes `finish_reason: length` cuts routine, silently. **Fix:** surface finish_reason and an error line server-side; make the client require the done marker. |
| H6 | MED ✓ verified (summary half downgraded from HIGH) | **The AI kill switch fabricates.** Flipping `ai_enabled` off routes production to test mocks. Chat: `MockAiOperatingLayerClient` answers *any* command with a confident "Morning Workout tomorrow 06:00" plan that really executes on confirm (`ai_operating_layer_client.dart:866-932`). Analytics: the card renders "[mock] Coaching summary for focus: streak_risk." cached as a genuine (isFallback:false) summary for up to 18h, bypassing the `DeterministicCoachingRenderer` that exists precisely for this situation (`ai_summary_providers.dart:27-33`, `coaching_ai_client.dart:226-242`). Verification narrowed the summary's reach: the only trigger of `recomputeAiSummaryProvider` is the **ungated "Test AI coaching summary" AppBar button on the production Progress screen** (`analytics_progress_screen.dart:98-102`) — the default kill-switch path falls back to the deterministic trace line once the cache expires; mock text reaches whoever taps that test button, then persists 18h. During exactly the incidents where trust matters most, the coach lies. **Fix:** honest unavailable copy in release for chat; make the disabled path throw so the deterministic renderer takes over; gate or remove the test button; reserve mocks for tests. |
| H7 | **HIGH** ✓ verified | **The "goal behind pace" card fabricates a specific accusation.** `_estimateGoalProgress` hardcodes 0 (`proactive_suggestion_engine.dart:431-438` — the comment admits it), so `behindPct` equals the *elapsed* percentage: a fully-on-track goal at day 27/30 reads "~90% behind the expected pace", at confidence 0.80 (second of five rules under the top-3 cap — it nearly always shows), daily, from ~20% of any goal's period. Meanwhile the goals surface computes real progress from the same synced GoalCheckIns (`goals_providers.dart`) and can show the goal *ahead* of pace simultaneously — cross-surface incoherence a coach cannot afford. **Fix:** feed real GoalCheckIn progress, or drop the number and downgrade the copy. |
| H8 | MED | **"You had a pending plan" banner false-positives after purely informational chats.** Every turn saves `confirmed=false` including informational answers; `getMostRecentUnconfirmed` filters only on confirmed+timestamp — asking "what's on my plan today?", closing, and reopening shows "You had a pending plan — want to continue?" whose Resume re-sends the question and burns a quota turn (`ai_interaction_history_repository.dart:47,147-159`). **Fix:** filter to entries with non-empty parsedActions. |
| H9 | MED | **Circle pulse collapses four different outcomes into "Nothing new yet".** Cooldown, empty feed, AI failure, and save failure all return null → the same copy (`circle_ai_pulse_service.dart:38-71`); a paid AI result whose save throws is silently discarded. The awaited raw Firestore write also evades the architecture tripwire (it matches only `await FirebaseFirestore.instance`). **Fix:** outcome enum with honest copy + retry; extend the guard regex. |
| H10 | LOW | **Error copy is recycled as a follow-up question**, so the next turn's prompt claims the model asked the user about being offline, clarify-rate analytics count error events, and the next voice turn is forced off the fast path (`ai_intent_parser.dart:184-198`, `ai_assistant_service.dart:292-308`). **Fix:** dedicated error responseType. |

### 8.3 Races & state lifecycle

| # | Sev | Finding |
|---|-----|---------|
| R1 | **HIGH** ✓ verified | **Closing the sheet mid-turn races startNewSession.** The sheet's `whenComplete` unconditionally rotates the session and clears the thread while `_parseAndRespond` is still awaiting (turns run up to ~80s); the late reply then lands as the first message of the *next* empty session, can arm a pending plan whose context is gone, and is persisted under the wrong sessionId — escaping its own session's memory extraction and pre-polluting the next conversation's history (`ai_assistant_screen.dart:105-113`, `ai_assistant_service.dart:386-412, 916-930`). **Fix:** generation counter captured at turn start; bail out of all state mutation + history save on mismatch (same guard for the streamed-voice settle path). |
| R2 | MED | **Double-tap on Confirm executes the plan twice.** The button disables only via build-time isLoading; `confirmPlan` has no reentrancy check; the executor's idempotency guard can never fire (fresh batchId per call) — two taps inside one frame window = duplicate tasks/reminders (`ai_assistant_screen.dart:1476`, `ai_assistant_service.dart:719-754`, `ai_action_executor.dart:144,176-182`). **Fix:** `if (_isLoading) return` at entry, or derive batchId from plan identity so the guard is real. |
| R3 | MED | **Concurrent turns via proactive-card auto-send.** `sendMessage` has no in-flight guard and loading is a bool: two auto-sends interleave, replies append in completion order, pending-plan state is clobbered by whichever finishes last, and in voice mode the wrong turn's reply can be spoken (`ai_assistant_screen.dart:466-490`, `ai_assistant_service.dart:117, 1121-1124`). **Fix:** guard/queue sends. |
| R4 | MED | **Opening Coach can wait up to 10s on a Remote Config fetch** before the composer exists (cold start, >1h since last fetch, slow network — `ai_remote_config_service.dart:26-49`): a user gesture waiting on the network, against principle 1. Related: if the provider chain ever errors, the raw exception renders with no retry and caches for the app session (`ai_assistant_screen.dart:1105-1116`). **Fix:** serve the last-activated value synchronously, fetch in background; retry button that invalidates the chain. |
| R5 | MED | **One oversized paste poisons the session.** userInput is persisted uncapped and replayed verbatim in the last-10-turn history; above the server's 120k-char cap every subsequent turn can fail until the sheet closes (`ai_interaction_history_repository.dart:36-43`, `index.ts:50,129`), with the generic "Something went wrong". **Fix:** cap at send time + truncate at persist; name the too-long failure. |
| R6 | MED | **Every notifyListeners rebuilds the whole screen — and the FAB on every tab.** `resolvedAiAssistantProvider` watches the ChangeNotifier family, so each notify refreshes the FutureProvider chain (the comment at `ai_assistant_providers.dart:216-218` claims the opposite); zero `select()` in the feature; during voice streaming this fires per delta batch (`:268-273`, `coach_ai_fab.dart:29-35`). **Fix:** narrow providers (messages/isLoading/pendingPlan) + a scoped ListenableBuilder. |
| R7 | MED | **Latent notifyListeners-during-build crash on the guest auto-send path** — armed the moment the suggestions panel (U2) is fixed: `_handlePendingCoachLaunch` runs in build and the anonymous branch reaches notifyListeners synchronously (`ai_assistant_screen.dart:485-489,866-867`, `ai_assistant_service.dart:127-150`). **Fix:** dispatch auto-send post-frame like the startVoiceMode branch already does. |
| R8 | LOW | **Single `lastTurnId` slot server-side double-charges interleaved turns.** A voice stream turn (which always clobbers the slot with `undefined`) or a second device mid-agent-loop makes the in-flight loop's follow-up charge as a fresh turn and clobber back (`index.ts:328-359, 654`); each interleaving can burn 2-4 extra units of the 40/hr. Related LOW: the per-instance over-quota marker rejects the *free* follow-ups of an already-charged 40th turn (`:479-484`). **Fix:** small map of recent turnIds; gate the marker to `loopIndex == 0`. |
| R9 | LOW | Assembler session cache grows unboundedly (evicted only on mutation, never on session end); schedule slice can be 30s stale after out-of-chat edits; `Duration`-based day arithmetic breaks on DST-change days (`ai_payload_assembler.dart:67-72, 396-407`). Thinking-loop day/hash prefs aren't uid-scoped (`thinking_loop_service.dart:75-76`). Maintenance that exists but is never wired: `pruneOldSummaries`, batch `pruneOld`, history `purgeBefore` (dead), and `IsarAiPulseCache` is registered but never read or written — no offline pulse despite the collection existing for exactly that. |

### 8.4 Voice / live conversation

| # | Sev | Finding |
|---|-----|---------|
| V1 | **HIGH** ✓ verified | **STT status/error callbacks freeze to the first initializer — every later voice session runs without them.** `SpeechToText` is a process singleton whose `initialize()` early-returns once `_initWorked` without re-registering listeners (`speech_to_text-7.4.0/speech_to_text.dart:313-319`); the app creates a fresh adapter per voice-mode entry (`voice_mode_adapters.dart:15-38`, `ai_assistant_screen.dart:566-567`) and the dictation mic registers its own handlers on the same singleton. From the second session per launch (or the first, if dictation ran earlier): the `'listening'` status never arrives so the new connecting phase never ends (the 2026-08-26 fix only works in session #1); silent listens never self-finalize on `'done'` and fall to the 7s stall watchdog, ending in the false "The microphone stalled" after ~21s instead of the gentle pause at ~4s; plugin errors never surface. Reverse direction: after voice mode, the dictation button's lit state never resets. Invisible to the suite (fake adapters). **Fix:** assign the plugin's public `statusListener`/`errorListener` fields before each listen, or hold one process-wide adapter that multiplexes to the active controller. |
| V2 | MED | **Tap-to-interrupt during a TTS fetch records a false failure and puts the good voice on a 60s cooldown.** `stop()` closes the keep-alive client → in-flight clip fetch throws → the catch stamps `_lastPrimaryFailureAt` without checking generation (`voice_tts_resilience.dart:61-75,117-129`) — an interrupt-happy user is semi-permanently stuck on the robotic fallback. And in degraded mode, `await deltas.forEach(...)` is uncancellable: interrupts stop nothing while the orb claims SPEAKING silently (`:90-97`). **Fix:** check generation before recording failure; cancellable subscription in the buffered branch. |
| V3 | MED | **No lifecycle/audio-interruption handling.** No WidgetsBindingObserver, no interruption/becomingNoisy listeners anywhere in the voice path: backgrounding, a phone call, or an AirPods disconnect mid-clip strands `speaking` (just_audio pauses; `completed` never fires) until an orb tap; backgrounded-while-listening keeps cycling the watchdog; `SyncService.voiceModeActive` stays true suppressing sync throughout. **Fix:** observer → `pauseToIdle()` with honest copy. |
| V4 | MED | **Every streamed chat turn pays a fresh TCP+TLS handshake, and the warmup's warm socket is discarded.** `new http.Client()` per stream, closed after (`voice_reply_stream.dart:30,81-95`); Dart keep-alive sockets die with their client — the TTS adapter measured exactly this on-device and moved to a session-lifetime client; the chat transport never adopted it, and `voice_warmup.dart`'s "leaves the connection warm" claim is void for the same reason (~100-300ms avoidable on every first token). **Fix:** one lazily-created keep-alive client for the voice session, shared with the warmup GET. |
| V5 | LOW | Buffered replies whose tail exceeds 2000 chars speak only the first sentence — the tail clip 400s and is swallowed by design (`voice_tts_streaming.dart:231-246`, `speech_rules.ts:10`). Chunk the tail. |
| V6 | LOW | Two residual endpointing races post-08-26 fix: `_listenStartedAt` is stamped before `listen()` resolves (slow native spin-up lets a stale `done` pass the 600ms guard and finalize an empty listen), and a stale `done` after a genuine first partial forces an extra stitch-restart (`voice_mode_controller.dart:132-138, 457-517`). Bounded; noted so a future "orb restarted mid-word" report has a known cause. |
| V7 | LOW | The streamed-voice day-reference gate misses "weekend", "next week", "day after tomorrow", and explicit dates — those turns stream to the tool-less endpoint whose addendum makes the model decline and ask to rephrase, when the agent path could have answered (`ai_assistant_service.dart:431-437`). Gate on the router's focusDate instead of a parallel regex. |
| V8 | LOW | The streaming TTS adapter configures the audio session once and never re-asserts the speaker route the fallback adapter documents as mandatory to re-assert per turn (`voice_tts_streaming.dart:199-218` vs `voice_mode_adapters.dart:121-149`) — the two adapters encode contradictory beliefs about the same session; latent earpiece regression. |
| V9 | INFO | Aborted voice turns still bill one chat + one speech unit (deliberate spend-control trade; upstream OpenAI billing *is* aborted — recorded so it isn't re-litigated). On interrupt the thread keeps all received deltas, a superset of what was spoken; `[mem:]` markers are visible in the live bubble until settle sanitizes. |

### 8.5 Server, cost & abuse surface

| # | Sev | Finding |
|---|-----|---------|
| S1 | **HIGH** ✓ verified | **The proxy is a general-purpose OpenAI API per account: no server-owned system prompt, request-count quota, 120k-char payloads.** The server never constructs or verifies the system prompt — `validateMessages` accepts a client `system` role verbatim and forwards it (`index.ts:82-133, 450-459`); quota counts requests, not tokens: 40 turns/hr × up to 3 free follow-ups × ~30k input tokens ≈ millions of tokens/hr per free-to-create account (≈$15-20/day of gpt-4o-mini), multiplied by farmed accounts while App Check remains unenforced — plus arbitrary content generated under the app's key (OpenAI ToS liability). Distinct from the fixed anonymous-uid half of §7 S2. **Fix:** server-owned per-purpose system prompts (reject/replace client `system` messages); a token-based daily budget (the code already receives `usage.total_tokens`); finish the App Check TODO — noting `aiChatStream`/`aiSpeechStream` are onRequest and need *manual* header verification, so flipping `enforceAppCheck` on the callables alone leaves them open. |
| S2 | MED | Purpose strings are client-invented free text; each distinct value becomes a permanent `byPurpose` field on the shared aiUsage doc — cycling random purposes bloats it toward the 1MiB doc limit, at which point the quota transaction on the same doc starts failing: self-DoS (`index.ts:414-415, 258-277`). Allow-list purposes; bucket the rest. |
| S3 | LOW | Error taxonomy conflates user quota, system budget, and upstream OpenAI 429 into one `resource-exhausted` (`index.ts:370-377, 243-247, 508-510`) — the client cannot offer a countdown vs an immediate retry. Attach a machine-readable `details` payload. |
| S4 | LOW | `aiChatStream` telemetry runs after `res.end()` — CPU-throttled on Cloud Run, so the voice purpose's usage counts are systematically unreliable (`index.ts:744-748`); pair fixing it with `stream_options: {include_usage: true}` for token-accurate voice accounting. Also INFO: purpose kill switches can revive on cold start during an RC outage (fresh instances have no last-known template, `:192-212`); no upstream inactivity timeout on the stream (platform 120s cap mitigates). |
| S5 | MED | **Circle pulse is a cross-user prompt-injection surface with no confirm gate on output.** Member-authored task titles flow verbatim into the shared prompt (`circle_ai_pulse_service.dart:188-231`), the parsed `memberLines` are never validated against real members, and the result renders to every member attributed by name — user-to-user content spoofing on a trust-sensitive surface, with a hostile `suggestedChallenge` getting a Start button. **Fix:** quote/cap/strip event titles, instruct data-not-instructions, validate userIds against the member list. |
| S6 | LOW | **The auto-commit relaxation quietly retracted §7 S8's injection mitigation for memory/intentions.** Text reaching the model can now cause a persistent write (`rememberFact`) whose content re-feeds every future prompt — a self-sustaining channel — or a deletion (`forgetFact`), with no gate. Low today (payload text is the user's own); becomes HIGH the day any shared/circle content enters the payload. **Fix:** decision-log the invariant ("no non-user-authored text in the Coach payload while these auto-commit"), keep the auto-commit set frozen. |
| S7 | INFO | `coaching_summary` and `circle_pulse` charge the user's 40/hr chat quota — a heavy chatter silently degrades their own analytics card to the deterministic fallback (and vice versa), sitting awkwardly against ai_routing's own "never a quota error for a call they didn't make" philosophy. Consider system-class for the summary (it already silent-skips to a fallback). |

### 8.6 Memory & context quality — what the model is told

| # | Sev | Finding |
|---|-----|---------|
| M1 | **HIGH** ✓ verified | **`markExecuted` stamps the whole session — "Already applied this session" then lies to the model.** One confirm flips `executed=true` on *every* prior entry, including declined suggestions and follow-up questions (`ai_interaction_history_repository.dart:105-117`); from the next turn all their summaries inject under "Already applied this session (do NOT repeat)" (`ai_payload_assembler.dart:718-736`). Decline a study plan, confirm a workout, then say "actually let's do that study plan" — the payload claims it was already applied, so the model refuses or pretends it exists. Poisoning compounds per confirm, session-long. **Fix:** mark only the entry whose plan executed. |
| M2 | MED | **Chat-path `rememberFact` stores the model's paraphrase as userStated truth at confidence 1.0, unverified** — bypassing the extraction pipeline's own quote-verify-or-demote safety idea; the ack bubble may be just "Noted — I'll remember that." without echoing what was stored, so a misheard "prefers evening workouts" is asserted plainly in every future conversation and the user never sees it to undo it (`ai_action_executor.dart:736-777`). **Fix:** run the quote check and demote on mismatch, and/or always echo the stored content next to Undo — the missing verification UI at zero cost. |
| M3 | MED | **A malformed or token-truncated `extract_memory` response marks the session extracted — memory silently lost, then raw turns purge.** Any jsonDecode failure yields an empty ParsedExtraction indistinguishable from "nothing durable"; the 900-token cap makes truncation plausible; the server strips `finish_reason` so it's undetectable (`memory_extraction_service.dart:208-211`, `memory_extraction_parser.dart:104-111`) — against the module's own "continuity is never silently lost" contract. **Fix:** invalid response = failure (stay pending); pass finish_reason; add the reflection parser's fence-stripping. |
| M4 | MED | **Merely mentioning a person resets their interaction clock** — "I miss Sarah, I haven't seen her in months" suppresses the relationship-gap nudge for another 21 days and tells the next prompt "Sarah — interacted today", inviting exactly the wrong coaching (`memory_extraction_service.dart:225-229` vs `relationship_care_service.dart:153-165`). **Fix:** separate `lastMentionedAtMs` from real interactions (completed intentions). |
| M5 | MED | **The 7-day truncation fallback copies the first three raw user turns verbatim into a permanent, synced MemoryFact** — raw utterances (possibly health/relationship disclosures) escape the 48h privacy boundary indefinitely and keep flowing to OpenAI, while also being the lowest-quality summary possible (openers are greetings) (`memory_extraction_service.dart:329-352`). **Fix:** build from assistantSummary lines / last substantive turns; give truncation summaries their own TTL. |
| M6 | MED | **Memory injection is strictly newest-20 — foundational facts fall out of the prompt.** After ~3 chatty sessions, "has type-1 diabetes" is evicted by newer trivia; the coach's amnesia looks like a model failure while the fact still shows in "What SidePal knows". The carefully-engineered `lastReferencedAtMs` "ranking hint" is read by nothing (`ai_payload_assembler.dart:179-210`). **Fix:** score selection (kind/provenance floor + recency + reference stamps + person-mention match). |
| M7 | INFO | **A bare "hi" ships the user's entire memory, people list, week, goals, and ~28 Isar reads to OpenAI** (~2.5-3k tokens): §7 P3 confirmed unfixed and wider than described — `assemble()` builds every section unconditionally; the router's classification gates nothing (`ai_payload_assembler.dart:74-133`). Cost, latency, and unnecessary sensitive-data egress on the most common turn shape. (Device context is exemplary — coarse labels only; memory/people have no equivalent minimization.) |
| M8 | LOW | Keyword router misroutes: "What should I add tomorrow?" contains " add " → MUTATE with a return-structured-actions hint; "add a task to explain X to Sam" contains "explain" → QUERY told *not* to return actions; "when's my next task" matches nothing → MUTATE default (`ai_intent_router.dart:31-135`). Downstream guardrails soften impact to degraded steering. Check question-shape before mutate verbs. |
| M9 | LOW | The `capabilities` payload section is assembled every turn and never rendered — the model never sees the capability table; the prompt's hand-written Boundaries prose is the only (drifting) source of truth (`ai_payload_assembler.dart:115`, dead `formatForPrompt`). Extraction observation titles are uncapped (reflection caps the identical field at 80 chars) and become unbounded intention titles in every future prompt. The `direct` coaching-style branch in the schedule-answer formatter is dead — the enum says disciplined/intense (`ai_schedule_answer_formatter.dart:54-58`). |
| M10 | MED | **The coaching summary ignores the user's coaching style when deriving framing** — `deriveCoachingFraming` is called without the style argument, so the prompt then demands assertive protection framing *and* "be warm, avoid guilt" simultaneously, and the tone validator enforces the wrong tone (`ai_summary_providers.dart:127-131` vs the documented FR-D-12 matrix in `coaching_ai_payload.dart:43-57`). Chat honors style; the two coach surfaces speak with different personas. One-line fix. |

### 8.7 Chat surface UX vs the "ChatGPT-level" bar

| # | Sev | Finding |
|---|-----|---------|
| U1 | **HIGH** | **No cancellation, no queueing: the composer locks for up to ~80s.** SEND is dead while a turn is in flight (20s/round × 4 rounds); voice's orb tap during `thinking` is explicitly a no-op. Only the streamed voice path is cancellable. The opposite of "act instantly, never lock input". **Fix:** Stop affordance on the loading bubble via a turn generation; let typed input queue. |
| U2 | **HIGH** ✓ verified | **The proactive suggestions panel, first-time card, and Coach help button are unreachable in production.** They live behind `if (!widget.sheetMode)` and the sheet is the only presentation since the Coach tab retired (`ai_assistant_screen.dart:243, 903-916`) — yet four live entry points still promise them: the FAB's accent dot ("a tap lands on the suggestions panel"), the Home morning-brief snackbar Open, and the push tap all pass `openSuggestionsPanel: true` and land on a sheet with no suggestions anywhere. The engine still runs and recomputes on every task mutation — pure waste feeding a dot that points at nothing; the entire ProactiveSuggestionCard UX ("Let's do it"/"Not now", dismissal capping) is dead code. Verification frames it precisely: the FAB advertising (2026-08-23) post-dates the tab retirement (2026-07-16) — an incomplete migration, not a retired feature; the morning-brief paths at least prefill the composer via `preDraftedText`. **Fix:** move the panel + help into the sheet body (empty-state and `_openSuggestionsPanel`), re-home the first-time card — and fix R7 first. |
| U3 | MED | **Forced scroll-to-bottom on every rebuild** — `_scrollToBottom` fires on every body build with messages (not on new-message), so during streaming/thinking the user is yanked back within 350ms of scrolling up to reread (`ai_assistant_screen.dart:893-897`). Gate on message-count growth + near-bottom heuristic. |
| U4 | MED | **Two ThinkingIndicators stack on every typed turn** — the loading bubble renders dots *and* `isLoading` appends a trailing dots row (`:1268-1272` + `:1461`). |
| U5 | MED | **Undo/dictation snackbars render behind the modal sheet.** All feedback goes to the root ScaffoldMessenger under the barrier: "AI changes have been undone", "cannot be undone", and the mic-permission error are invisible at 60%/full — for the mic case the user taps and *nothing* visibly happens (`:1696-1752, 1867-1872`, `ai_input_card.dart:251-255`). Wrap the sheet in its own ScaffoldMessenger or use inline banners. |
| U6 | MED | **An accidental downward fling destroys the visible conversation, irreversibly.** Session-boundary-on-close is intentional (P1-04), but one fast fling anywhere on the header wipes thread + pending plan; the only recovery re-*sends* the last unconfirmed input (fresh AI round-trip, everything else lost). **Fix:** keep boundary semantics, soften the loss — retain the last thread and offer "Restore conversation" on reopen within minutes. |
| U7 | LOW | The safety-critical color coding (blocked/conflict/high-risk) uses raw `Colors.red/redAccent` throughout the coach surface instead of the palette-switched `AppColors.danger` — materially worse contrast in light mode; CLAUDE.md mandates AppColors-only (`planned_changes_card.dart` ×8, `_ConflictSummaryBanner`, FAB dot). The history sheet also hand-rolls a 17px header where `SectionHeader` is the rule. |
| U8 | LOW | No message timestamps anywhere (relevant because of the 30-min undo window); chat bubbles are not selectable/copyable (and copying your own failed message is currently the only cheap resend); no insertion animation ("nothing snaps" is the house motion rule); a11y: unlabeled orb whose action changes by phase, no liveRegion announcements for thinking/speaking, sub-44pt bare-GestureDetector targets, directives row clips at large text scales. |
| U9 | LOW | Sheet auto-grow fights a deliberate 60% park while a reply streams (content ticks count as message events, and 0.6 is above the 0.54 respect-threshold — `:366-388, 428-444`). Suppress growth after a user drag until the next count increase. |
| U10 | INFO | **The visible thread does not survive relaunch** — by design cross-device continuity rides extracted memory, a defensible privacy lean; but every launch presents an empty thread seconds after a rich conversation, and the data to rehydrate the last session (userInput + assistantSummary per turn) already sits in Isar. See 8.9. |

### 8.8 Verified OK — what is genuinely strong

- **Server discipline:** model pinning with an allow-list (config typos cannot
  select expensive models); temperature/token caps only lower; quota in
  Firestore transactions with the aiUsage collection unreadable by clients;
  anonymous uids rejected on all endpoints; free-follow-up farming closed
  (turnId + 3-min window + cap mirrored client/server); interrupts genuinely
  abort upstream OpenAI billing; system-vs-user budget separation with
  silent-skip semantics; RC outage serves last-known template; no message
  content in logs; the OpenAI key via Secret Manager, never near a client.
- **Pipeline robustness:** the malformed-model-output ladder (double-encoded
  arrays, per-entry drops, tool-error repair rounds, prose-plan nudge) is
  real engineering; the agent loop is bounded both ends; no awaited Firestore
  on any chat interaction path (tripwire-tested); the clarify-loop defenses
  (deterministic local merge, carry-forward, verbatim-title gating) hold
  together as a system with dedicated tests.
- **Safety topology:** the confirm-gate is structurally airtight for schedule
  mutations in both modalities (voice rides the same sendMessage; streamed
  voice is tool-less with a no-claiming addendum; stale/cancelled cards are
  inert); the unrequested-delete guard genuinely closes the "no thank you →
  delete plan" class; auto-commit undo is precise per batch with pre-assigned
  ids and exact fact restore.
- **Memory architecture:** summarize-then-purge is well built (extraction-
  gated purge, 7-day deferral, retry-not-skip on transport failure, legacy
  adoption); quote-verification demotes unverified claims to inferred; the
  reflection pipeline (grounding-or-drop, caps, re-fetch-before-write LWW
  protection, inputs-hash gating) is the strongest LLM surface in the app;
  tombstone-aware dedupe stops deleted promises resurrecting; "What SidePal
  knows" gives full user control; `markReferenced` is deliberately local-only
  so reference stamps can never LWW-stomp user edits.
- **Voice engineering:** the endpointing invariant now holds with margin and
  its failure history is documented on both constants; generation-counter
  discipline is consistent across controller and TTS adapters (491-line test
  suite); transcript fidelity is exact; the streamed-turn fallback ladder
  always leaves the loop something honest to speak; speech quota's clip
  ladder converges head+tail on one charge.
- **Offline honesty:** airplane-mode promise capture works through the same
  executor path with per-item failure copy; guests get a local sign-in nudge
  instead of a server error; the sheet's keyboard engineering (pixel-anchored
  peek, TextFieldTapRegion mic fix) is careful and correct.

### 8.9 The road to "a ChatGPT-level assistant that does what it's supposed to do"

Ordered; each tier is shippable alone.

1. **Make every advertised verb real (E1, E2).** Implement move/delete task,
   modify/delete goal, remove reminder, and true edit — the single highest-
   leverage change in the entire AI surface. The right shape: resolve entity
   references to concrete ids at *preview* time (EntityNormaliser similarity
   already exists), stash `_resolvedTaskId`/`_resolvedGoalId` on the action,
   render what was matched on the card ("Move "Gym" — today 9:00 →
   tomorrow"), and ask when zero/multiple candidates match. That one change
   makes the stubs implementable by id, kills hallucinated-title execution,
   fixes the coordinator's placeholder ids, and makes the preview honest.
   Until each verb is real: remove it from the tools, the capability prompt,
   and the quick-directive chips.
2. **Make failure honest (H1-H5, E6).** `isError` + retry chip on the bubble
   (reusing the turnId so retries are quota-free — the server already
   supports it); try/catch/finally around confirmPlan; per-action outcomes in
   the confirm summary instead of all-or-nothing rollback; the done/finish
   contract on the stream; split "slow" from "offline" copy; refund quota on
   upstream failure. This is the Telegram model the project already mandates.
3. **Make undo real (E3, E4, E5, E7, E8).** Inverse-operation log per
   dispatched action (deletes creations by construction, covers goals/
   reminders/time blocks); dry-run before the warning dialog; watch-stream
   providers so the Undo chip appears the instant a batch completes; boot
   sweep for stranded `executing` batches.
4. **Stop the two kill-switch fabrications (H6)** and the behind-pace
   fabrication (H7) — cheap, and they are the moments users decide whether
   the coach lies.
5. **Fix the context poisoners (M1-M6, R1).** Per-entry markExecuted; the
   sheet-close generation guard; echo remembered content next to Undo;
   disambiguate forgets; extraction failure ≠ empty extraction; scored memory
   selection so foundational facts never fall out of the prompt.
6. **Voice reliability (V1-V4).** One process-wide STT adapter multiplexing
   callbacks (V1 silently undoes the 08-26 connecting-phase fix from session
   #2 onward — it is the top voice bug); generation-checked cooldown stamps;
   a lifecycle observer; a session-lifetime keep-alive client shared with
   warmup.
7. **Latency & cost.** Stream typed query turns through the existing
   aiChatStream seam (the single biggest perceived-speed win — the
   infrastructure is already built); route-conditioned payload trimming (a
   greeting needs none of the 28-read context block); order messages for
   OpenAI automatic prompt caching (stable prefix ≥1024 tokens ≈ half input
   cost); pre-assemble the payload while the user is still speaking;
   parallelize voice start(); speak canned prompts on-device.
8. **Server hardening (S1, S2, R8).** Server-owned system prompts per
   purpose; token-based daily budget; App Check on callables *and* manual
   header verification on the onRequest streams; turnId registry; purpose
   allow-list. Implement (or honestly un-document) the tier-aware AI
   instruction cap (E16).
9. **Product warmth.** Restore-conversation on reopen (U6) and rehydrate the
   last session's turns on launch (U10) — the thread data already sits in
   Isar; per-item accept/reject on the plan card; personalized empty-state
   chips seeded from real goals; timestamps, copyable bubbles, insertion
   animation; suggestions panel re-homed into the sheet (U2) with R7 fixed
   first; snackbars inside the sheet (U5); real GoalCheckIn progress feeding
   the behind-pace rule, the coaching payload, and chat alike — the single
   best cross-surface coherence fix.

### 8.10 Priority order

1. **Now (trust-critical):** E1+E2 (or at minimum de-advertise the broken
   verbs — a one-hour change that stops the lying), E4 (fake Cancel), H7
   (the false accusation every goal-holder sees daily).
2. **This sprint:** H1 retry surface + H2 guard (cheap), E3+E5+E6 (undo that
   undoes), R1+R2 (mid-turn races), V1 (undoes the 08-26 voice fix from
   session #2), M1 (session poisoning), U2+R7, H6.
3. **Next:** tier 5-7 above (context poisoners, voice reliability,
   latency/cost), S1 server hardening before any public beta, S5 before
   circles scale.
4. **Scheduled debt:** the LOW tables above, a11y pass (U8, extends §7 H3),
   dead-code deletions (parseOperatingLayerJsonMap, weekly pulse, capability
   payload section, batch pruning wiring).

## 9) Notifications, reminders & enforcement modes — deep audit (2026-08-30)

_Report-only; no notification code, configuration, tests, or product behavior
was changed. Static scope: task and goal reminder persistence, Flexible /
Disciplined / Extreme mode resolution, adaptive cadence, attention
orchestration, notification ledger and reconciliation, lifecycle re-arming,
timezone handling, iOS/Android setup, push rescue, settings UX, relevant PRDs,
and existing tests._

### 9.1 Verdict

The reported symptom is real and has a direct code-level explanation:
**Disciplined and Extreme currently collapse to one notification when the user
does nothing.** Flexible's one-shot behavior is consistent with its policy, but
the other two modes are not delivering their advertised persistence.

The system contains two partially joined designs:

1. `AdaptiveReminderPolicy` still defines automatic staged repeat plans for
   Disciplined and Extreme (`adaptive_reminder_policy.dart:76-198`).
2. Phase C replaced pre-scheduled chains with one reactive OS slot
   (`reminder_sync_service.dart:68-75, 202-228`; PRD FR-C-17 through FR-C-22).

The reactive state transition that should join those designs was never
completed. A normal first OS delivery does not set `pendingAction`, does not
stamp `lastTriggeredAtMs`, and is not marked delivered in the ledger. Therefore
the 15-minute ignored check cannot see it and no second reminder is produced.
The only production writer of `pendingAction: true` is the explicit **Later /
Snooze** path (`reminder_sync_service.dart:126-163`).

Current mode behavior is therefore:

| Mode | What is actually mode-aware | What happens after passive ignore |
|---|---|---|
| Flexible | Initial interruption level `low`; long snooze after **Later**; eligible for batching/suppression | Stops after one reminder — consistent with `autoRepeatEnabled: false` |
| Disciplined | Initial level `medium`; shorter snooze after **Later** | Stops after one reminder; the encoded staged repeats are unused |
| Extreme | Initial level `high`; becomes `critical` only after persisted escalation; **Done** cannot bypass the timer contract | Stops after one reminder; “Follow up until I act” is not implemented |

There is no server rescue for task reminders. FCM re-planning only calls the
intention nudge service (`push_messaging_service.dart:253-266`), so the one
local OS slot is the complete closed-app reliability floor for tasks.

### 9.2 Root-cause findings

#### N1 — [CRITICAL] The first delivered reminder never enters the ignored/escalation state machine

- New reminders are persisted with `pendingAction: false`, escalation 0, and no
  `lastTriggeredAtMs` (`add_task_reminder_persistence.dart:77-90`).
- `_nextReminderTime` returns the original future timestamp only while
  `pendingAction` is false; once that timestamp is past it returns `null`
  (`reminder_sync_service.dart:236-271`).
- `checkIgnoredTimeouts` requires both `pendingAction == true` and a
  `lastTriggeredAtMs` older than 15 minutes
  (`attention_orchestrator_service.dart:350-374`).
- Scheduled OS delivery has no callback that mutates `ReminderConfig`.
  `markDelivered` is called only for immediate `showNow`, not for
  `zonedSchedule` deliveries (`attention_orchestrator_service.dart:420-459`).
- Consequently, doing nothing after the first notification is indistinguishable
  from a reminder that has not entered escalation. No follow-up is scheduled.

This is the primary cause of “it reminds once and then nothing happens.”

#### N2 — [CRITICAL] Cold-start reconciliation mistakes every future pending alarm for a missing/dismissed notification

- The plugin exposes separate APIs for delivered tray notifications and future
  pending requests. The app wraps both separately
  (`local_notifications_service.dart:252-278`).
- Reconciliation reads only `getActiveNotifications()` (the delivered tray),
  then compares it with ledger rows in `scheduled` state
  (`notification_reconciliation_service.dart:57-83`).
- A legitimate reminder scheduled for later is not in the delivered tray, so
  reconciliation marks it cancelled and immediately calls
  `reEvaluateIfAppropriate`, which creates a due-now follow-up
  (`attention_orchestrator_service.dart:313-348`).
- Reconciliation is launched unawaited, then `scheduleFromCache` later
  cancels/re-arms reminders (`app_bootstrap.dart:64-78`). The two operations
  can race.

User-visible outcomes include a future reminder appearing immediately when the
app opens, a later alarm being replaced or left alongside an immediate
delivery depending on platform ordering, and inconsistent ledger state. This is
the strongest verified explanation for reminders that appear at the wrong time
around app launch.

The existing reconciliation test actually encodes the faulty assumption:
“scheduled but not in OS tray = cancelled”
(`notification_reconciliation_service_test.dart:72-95`). It has no pending
queue case.

#### N3 — [HIGH] The mode cadence exists as tested policy math, not as a production delivery loop

- Disciplined defines 3 nudges over 10 minutes, 3 over the next 30, then hourly;
  Extreme defines 3 + 5 then an hourly tail
  (`adaptive_reminder_policy.dart:76-141`).
- `autoRepeatOffsets()` is referenced by policy tests but has no production
  caller (`adaptive_reminder_policy.dart:173-198`;
  `adaptive_reminder_policy_test.dart:55-75`).
- The PRD correctly requires a reactive single-next implementation, but the
  implementation only applies mode cadence on explicit snooze
  (`reminder_sync_service.dart:126-163`).
- The ignored follow-up path instead uses a fixed 15 minutes and does not
  persist the incremented escalation or a new trigger timestamp
  (`attention_orchestrator_service.dart:546-575`). If it is reached, every
  later resume can re-process the same stale config.
- `AdaptiveReminderPolicy.nextStep` clamps escalation at
  `maxEscalationLevel` (`adaptive_reminder_policy.dart:201-221`), while the
  Extreme tail branch requires `escalationLevel > maxEscalationLevel`
  (`reminder_sync_service.dart:248-260`). The tail is unreachable through the
  normal snooze path.

The unchecked manual QA still promises the removed pre-scheduled chains
(`tasks/manual-qa-v2.md:22-29`), while the newer PRD promises reactive
follow-ups (`tasks/prd-phase-c-attention-orchestration.md:207-247`). Neither
promise matches the shipped no-action behavior.

#### N4 — [HIGH] Reminder sync cancels valid alarms before knowing replacement scheduling will succeed

- `_applyReminders` calls `cancelForEntity` before checking whether the
  reminder is enabled, has a next time, passes attention policy/budget, or can
  be scheduled by the OS (`reminder_sync_service.dart:202-228`).
- The orchestrator itself intentionally checks budget before cancelling the
  existing slot (`attention_orchestrator_service.dart:394-418`), but the
  earlier adapter cancellation defeats that safety.
- If the replacement is suppressed, budget-denied, has a past timestamp, or
  throws during platform scheduling, the old valid alarm has already gone.
- `syncForTaskIds` hydrates the requested tasks but then loads and reapplies
  **all** reminders (`reminder_sync_service.dart:98-101`). Editing one reminder
  can therefore cancel/reschedule every other task reminder and expose all of
  them to this failure path.

Goal reminders explicitly avoid this pre-cancel pattern so budget/suppression
leaves the old slot intact (`goal_reminder_sync_service.dart:94-120`); task
reminders do not.

#### N5 — [HIGH] Task reminders have no normal roll-forward after their one timestamp passes

- A non-pending past task reminder returns no next time
  (`reminder_sync_service.dart:266-271`).
- App resume schedules the unified notification step, but that step re-arms
  goals and intentions only (`app_lifecycle_task_refresh.dart:120-129`;
  `unified_recompute_graph.dart:141-171`).
- Goals have an explicit `rearmIfStale`; tasks do not
  (`goal_reminder_sync_service.dart:131-140`).
- Reminder rows are read on demand; there is no Isar reminder watch stream that
  automatically reschedules OS state (`isar_reminder_repository.dart:34-59`).

This is intentional for a one-time task timestamp only if no mode follow-up is
expected. It is incompatible with Disciplined/Extreme persistence and means a
missed task reminder becomes a permanently enabled but inert config.

#### N6 — [HIGH] Android scheduled reminders are not wired for current plugin requirements

The project uses `flutter_local_notifications` 19.5.0 and always requests
`AndroidScheduleMode.exactAllowWhileIdle`
(`local_notifications_service.dart:174-211`). The app manifest lacks:

- `SCHEDULE_EXACT_ALARM` plus the corresponding runtime
  `requestExactAlarmsPermission()` flow;
- `RECEIVE_BOOT_COMPLETED`;
- `ScheduledNotificationReceiver`;
- `ScheduledNotificationBootReceiver`.

The plugin's own 19.5.0 README requires those entries for scheduled/exact
notifications, while the project manifest contains none
(`android/app/src/main/AndroidManifest.xml:1-52`). Scheduling errors are caught
inside the orchestrator and only sent to `debugPrint`
(`attention_orchestrator_service.dart:418-483`); release mode disables
`debugPrint` (`main.dart:25-31`), so this fails silently to both user and
Crashlytics. Reboot also removes the reliability floor because nothing
re-registers alarms.

Correction to the older §4 audit: `POST_NOTIFICATIONS` is supplied by the
plugin's own merged manifest in v19.5.0, and the app does request it at runtime
(`local_notifications_service.dart:158-171`). That specific permission is not
the current manifest defect; exact-alarm permission and scheduling/boot
receivers are.

#### N7 — [HIGH] Suppressed reminders are queued but never released when an override ends

- Flexible starts `low`, Disciplined `medium`, and Extreme `high`
  (`interruption_level_resolver.dart:20-41`).
- Meeting/focus suppress low and medium; sleep/vacation suppress through high;
  DND suppresses everything (`override_attention_policy.dart:20-42`).
- Retryable suppression stores the intent only in the service's in-memory map
  (`attention_orchestrator_service.dart:109-118, 485-493`).
- `onOverrideEnded` contains re-delivery logic
  (`attention_orchestrator_service.dart:218-288`), but there is no caller.
  Manual and timed override ending return the Phase B empty review directly
  (`context_override_service.dart:110-145, 178-194`;
  `context_override_expiry_poller.dart:36-44`).

Thus a Flexible/Disciplined reminder due during a meeting/focus window, or any
non-critical first reminder due during sleep/vacation, can be suppressed and
then lost for the process lifetime. Because N4 already cancelled the old slot,
there is no fallback alarm.

### 9.3 Why reminder times sometimes look miscalculated

#### [HIGH] Boot re-evaluation can convert a future time to “now”

N2 is a real scheduling error, not a timezone display issue. Reconciliation
uses the wrong OS collection and explicitly builds a follow-up at `_now()`.

#### [MEDIUM] Collision spacing delays whichever reminder is evaluated later, not the lower-importance one

The policy promises that the lower-importance reminder is delayed, but
`_computeCollisionDelay` never compares importance. It always delays the
currently evaluated intent to the earlier slot plus three minutes
(`attention_orchestrator.dart:196-229`). Since all reminders are reapplied in
repository iteration order, close reminders can move by three minutes based on
iteration order rather than mode or urgency.

#### [MEDIUM] Reminder timestamps have no timezone identity

- The picker constructs a local `DateTime`
  (`add_task_reminder_section.dart:81-121`).
- Persistence uses local `toIso8601String()` with no zone id/offset
  (`add_task_reminder_persistence.dart:80-89`).
- Scheduling parses that string and converts the resulting instant to the
  single `tz.local` configured at app initialization
  (`local_notifications_service.dart:39-47, 117-127, 174-212`).

This produces inconsistent travel/cross-device semantics. A pending OS request
keeps the zone/instant from when it was armed; after reopening in another zone,
`scheduleFromCache` reparses the zone-less value as the new device's local wall
time and replaces it. The same reminder can therefore shift by the timezone
difference depending on whether the app was reopened. Another synced device
also interprets the value in its own local zone. No product rule says whether a
task time is fixed to its creation zone or should follow the user.

`tz.local` is also configured only once per process, with no resume/timezone
change refresh. However, `TZDateTime.from` preserves the input instant, so the
UTC fallback comment in `local_notifications_service.dart:43-46` should not by
itself be treated as proof of the observed offset for current one-shot task
times. The missing timezone semantics and re-arm behavior are the verified
risks. There are no DST, travel, or cross-device timezone tests.

#### [LOW] A near-now scheduling race can move a request forward by a full day

`_normalizeScheduleTime` repeatedly adds 24 hours when the timestamp is no
longer in the future (`local_notifications_service.dart:510-517`). The
orchestrator bypasses this for requests already due, which prevents the common
case, but a barely-future request can become stale while asynchronous budget
and cancellation work runs. That edge becomes “tomorrow,” not a small delay.

### 9.4 Mode behavior that is calculated but not delivered

#### [MEDIUM] Escalation copy and hard-gate messaging are dead on the task delivery path

`ReminderSyncService.bodyForReminder` builds distinct app-open and logical
reason copy as escalation rises (`reminder_sync_service.dart:314-342`), but the
orchestrator never calls it. Task notifications always use the generic
`"Time to start: …"` body (`attention_orchestrator_service.dart:525-538`).
The Extreme hard-gate flag therefore changes neither notification text nor OS
actions. Only the separate **Done** handler prevents an Extreme task from being
completed without entering the timer flow (`notification_task_actions.dart:20-47`).

#### [MEDIUM] “Silent” and priority decisions do not reach the OS

The pure orchestrator can return `silent: true` for a non-focus low-level
reminder (`attention_orchestrator.dart:180-194`), but
`AttentionOrchestratorService` never reads `decision.silent`.
`LocalNotificationsService` always schedules the task channel at
`Importance.max` / `Priority.high` on Android and uses default Darwin sound
behavior (`local_notifications_service.dart:187-209`). Flexible is therefore
not gentler at actual delivery; it is only easier to suppress.

Focus `priorityBoosted` is likewise logged but does not alter platform
notification priority (`attention_orchestrator_service.dart:466-476`).

#### [LOW] Missing/legacy modes resolve differently across layers

`EnforcementMode.fromModeRefId(null)` falls back to Disciplined
(`enforcement_mode.dart:18-32`), while `AdaptiveReminderPolicy` and
`ReminderSyncService` fall back to Flexible
(`adaptive_reminder_policy.dart:223-228`;
`reminder_sync_service.dart:283-299`). Old reminder rows without a mode can
therefore be treated as different modes by different features.

Extension reminder updates also preserve the old reminder mode rather than
copying the task's current mode (`auto_next_task_flow.dart:693-719`).

### 9.5 Ledger, permissions, and observability gaps

#### [MEDIUM] Ledger states do not represent what actually happened

- `notificationDelivered` analytics is logged immediately after an OS request
  is scheduled, not after it fires (`attention_orchestrator_service.dart:438-476`).
- Future scheduled deliveries stay in `scheduled`; only immediate `showNow`
  calls become `delivered` (`:455-458`).
- Ignored and expired ledger states are declared but never written
  (`notification_ledger_state.dart:1-22`).
- **Wrong time** records only an interaction string; it does not transition or
  cancel the scheduled ledger state
  (`notification_response_handler.dart:473-486`;
  `notification_ledger_repository.dart:61-74`). On a later cold start,
  reconciliation can treat that row as missing and re-deliver it, contradicting
  the “no follow-up escalation” comment.
- Snooze scheduling uses the mode cadence, but the ledger always records
  `snoozedUntilMs = now + 15 minutes`
  (`attention_orchestrator_service.dart:578-588`).

These mismatches make adaptive back-off and production diagnosis unreliable.

#### [MEDIUM] The iOS notification budget's fail-closed contract fails open in production

`NotificationBudget` correctly denies when its source throws
(`notification_budget.dart:31-52`), and its unit test covers a throwing fake.
The real source catches every platform error and returns an empty list
(`local_notifications_service.dart:269-278`). The budget therefore sees zero
pending notifications and allows scheduling when the queue is actually
unknown. On iOS this recreates the silent-overflow risk the 56-slot guard was
written to prevent.

The active-tray wrapper has the same catch-and-empty behavior
(`local_notifications_service.dart:252-266`), which makes a query failure look
like “all notifications disappeared” to the already-unsafe reconciliation.

#### [MEDIUM] Permission state and scheduling health are invisible to the user

`DarwinInitializationSettings` is created without disabling its three default
permission requests (`local_notifications_service.dart:52-109`), so iOS asks
automatically during deferred startup rather than only after the user enables a
reminder. If denied, the reminder toggle later shows a snackbar but save still
persists an enabled reminder and attempts to schedule it
(`add_task_reminder_persistence.dart:10-22, 77-93`).

The Notifications & Reminders settings page exposes coaching and sleep/override
preferences, but no OS authorization state, exact-alarm state, pending-reminder
health, or route to system settings
(`notification_settings_screen.dart:7-32`). A reminder can look enabled in the
app while being impossible to deliver.

#### [LOW] Phase C persistence fields are decorative

`ReminderConfig.activeNotificationId` and `evaluationTrace` are serialized to
Firestore but are absent from the Isar schema conversion
(`reminder_config.dart:35-44, 53-96`;
`isar_reminder.dart:20-66`). The orchestrator never writes either field. This
removes the documented restart fallback and the promised explanation trail.

### 9.6 Test audit

The existing tests are strongest around pure policy and routing, but they do
not exercise the failure boundary that users experience:

- `adaptive_reminder_policy_test.dart` proves repeat offsets that production
  never calls.
- `reminder_sync_service_test.dart` uses an orchestrator that only records
  intents and a notification scheduler that does nothing
  (`reminder_sync_service_test.dart:60-110`). Its default fixture starts with
  `pendingAction: true` (`:169-193`), bypassing the real creation state that
  causes N1.
- `attention_orchestrator_test.dart` tests pure decisions, not execution into
  platform notification details.
- `notification_reconciliation_service_test.dart` has no future pending queue
  and codifies the active-tray mistake.
- `notification_budget_test.dart` proves fail-closed with a throwing fake, but
  not with the real catch-and-empty adapter.
- Notification response tests verify tap navigation and action routing, not
  delivery, recurrence, or closed-app escalation.
- There is no test for `checkIgnoredTimeouts`, ignored follow-up persistence,
  Extreme tail exhaustion, task re-arm on resume, `decision.silent` reaching
  the OS, schedule failure after pre-cancel, timezone/DST/travel, Android
  manifest requirements, or fire → ignore → next notification.
- The device QA checklist for automatic Disciplined/Extreme follow-ups remains
  entirely unchecked (`tasks/manual-qa-v2.md:22-29`).

No tests or device scenarios were executed for this report, consistent with
the requested audit-only scope.

### 9.7 Verified working

- Add Task resolves explicit task mode → routine mode → profile-scaled default
  and persists the resolved string on both task and reminder
  (`add_task_mode_resolution.dart:110-168`;
  `add_task_reminder_persistence.dart:77-90`).
- **Later / Snooze** does schedule one new follow-up and uses the mode-aware
  shortening interval (`reminder_sync_service.dart:126-163`).
- Starting the timer, completing a task through an allowed notification action,
  or providing a logical reason disables/cancels that task reminder
  (`reminder_sync_service.dart:108-122, 167-188`).
- Extreme's notification **Done** action cannot silently bypass its timer
  contract (`notification_task_actions.dart:20-47`).
- Goal reminder recurrence has an explicit next-occurrence computation and
  app-activity re-arm. Its known limitation is that later occurrences do not
  continue while the app remains unopened
  (`goal_reminder_sync_service.dart:63-140`; decision log
  `documentation/GUIDELINES.md:603-612`).
- Notification route IDs/payloads and cold-start tap draining are centralized;
  this audit found the delivery-state machine broken, not the basic task tap
  routing.

### 9.8 Priority if remediation is authorized later

1. Correct the delivery state model: distinguish pending OS requests from
   delivered tray items, and make first-fire ignore detectable.
2. Complete one coherent Disciplined/Extreme reactive cadence, including
   persisted escalation/tail state and closed-app guarantees.
3. Remove task pre-cancel/global reapply behavior so a failed replacement
   cannot destroy a valid alarm.
4. Wire override-end queue flushing.
5. Complete Android exact-alarm, receiver, reboot, and inexact-fallback setup.
6. Define timezone/travel semantics and store enough information to implement
   them consistently.
7. Make permission, pending queue, ledger state, and scheduling failures
   observable; then add device/integration tests across all three modes.

## 10) Notifications, reminders & modes — independent deep audit (Claude, 2026-08-30)

_Audited on branch `feat/ux-fixes-and-stake-surrender`, independently of §9
(code re-read from scratch; every claim carries a file:line reference).
Scope: local_notifications_service.dart, notification_budget / ledger /
reconciliation, reminder_sync_service.dart, attention_orchestrator(.+_service),
adaptive_reminder_policy.dart, interruption_level_resolver.dart,
notification_route_resolver.dart, goal_reminder_sync_service/schedule,
goal_intensity_mode.dart, routine_mode.dart, effective_task_mode.dart,
coaching_style_delivery_policy.dart, override_attention_policy.dart,
sleep_window_util.dart, context_override_service/poller, app_bootstrap.dart,
app_lifecycle_task_refresh.dart, notification_response_handler.dart,
add_task_reminder_persistence.dart, reminder repositories, remote_isar_merge
(reminder phase), unified_recompute_graph (notifications step),
functions/src/intentions/sweep.ts. Report-only; no fixes applied._

### 10.0 How the pipeline actually works (orientation)

Producers (task `ReminderConfig`s, goal reminders, intention nudge ladder,
stake invites, coach insights) each build a `ReminderIntent` and hand it to
`AttentionOrchestratorService.evaluate` (`attention_orchestrator_service.dart:123`).
A pure policy (`attention_orchestrator.dart:53`) decides approve / delay /
batch / suppress, then `_executeDecision` (`attention_orchestrator_service.dart:379`)
either `showNow`s (due now) or `zonedSchedule`s (future) exactly ONE OS
notification per entity slot, and records it in an Isar ledger.

Mode plumbing: a task's `modeRefId` (flexible/disciplined/extreme, resolved by
`EffectiveTaskMode`) selects a cadence from `AdaptiveReminderPolicy.cadenceFor`
and an `InterruptionLevel` from `InterruptionLevelResolver`; goal intensity 1–5
maps onto the same three modes (`goal_intensity_mode.dart:16`). A global
`CoachingStyle` adds a back-off rule on follow-ups.

The critical structural fact: **everything is client-side one-shot
scheduling.** There is no OS-side repeat for tasks or goals anymore (the
Phase 0 reroute retired the repeating matchers — `goal_reminder_sync_service.dart:17-24`),
no delivery callback when a scheduled notification fires, and the server
rescue-net covers only intentions (`functions/src/intentions/sweep.ts`).
Every "next" reminder exists only if some app-open code path re-arms it.
That single design property produces most of the symptoms below.

### 10.1 Why a reminder fires once and then goes silent

#### C1 — [CRITICAL] The mode escalation machine only starts if the user taps "Later"
- `pendingAction: true` is written in exactly one place in the entire app:
  `ReminderSyncService.requestSnooze` (`reminder_sync_service.dart:145`).
- The only thing that detects an ignored notification,
  `checkIgnoredTimeouts` (`attention_orchestrator_service.dart:355-375`),
  skips every reminder with `!reminder.pendingAction` (line 362).
- There is no delivery callback for a fired scheduled notification (iOS
  doesn't provide one; nothing polls the tray for it), so a notification the
  user simply ignores — the exact case escalation exists for — leaves no
  trace that starts the ladder.
- Net: for all three modes, one notification fires and the disciplined/
  extreme cadence never engages unless the user *opts into* escalation by
  pressing Snooze. "It reminds once and then nothing happens" is the
  designed-in outcome of this wiring, not an edge case.

#### C2 — [CRITICAL] The per-mode repeat plans are dead code
- `AdaptiveReminderPolicy.cadenceFor` defines rich per-mode plans — extreme:
  3 nudges/10 min + 5/30 min + hourly tail ×5; disciplined: tail ×24
  (`adaptive_reminder_policy.dart:75-171`) — and `autoRepeatOffsets`
  materializes them (lines 176-199).
- `autoRepeatOffsets` has **zero callers in `lib/`**; its only references are
  `test/features/reminders/adaptive_reminder_policy_test.dart:61,72`. The
  fields `autoRepeatEnabled`, `repeatPlan`, `maxFutureNudges` are read by
  nothing in production.
- So the difference the modes are supposed to make in *delivery pressure*
  exists as tested policy math with no execution path. The tests pass while
  the behavior is absent — a test-suite blind spot worth naming: no test
  walks "scheduled → fired → ignored → escalate per mode" through the
  service layer against a fake clock/tray.

#### C3 — [HIGH] One-shot task reminders with no roll-forward
- `_nextReminderTime` for a non-pending reminder: parse `scheduledAtIso`,
  return it if future, else `null` (`reminder_sync_service.dart:266-270`).
  A fired (or missed) reminder's config stays `enabled` with a past
  timestamp forever; every later sync computes `null` and arms nothing.
- Habit-style tasks that recur daily therefore remind exactly once in their
  life unless the user edits the reminder time again
  (`add_task_reminder_persistence.dart:80-92` is the only writer of
  `scheduledAtIso`).

#### C4 — [HIGH] Goal reminders only survive as long as the user keeps opening the app
- Per the Phase 0 reroute each goal has ONE armed occurrence, re-armed by
  bootstrap, goal saves, and the recompute graph's notifications step
  (`goal_reminder_sync_service.dart:131-140`,
  `unified_recompute_graph.dart:140-155`).
- All re-arm triggers are app-activity. If the phone sits untouched over a
  weekend, Saturday's goal reminder fires and Sunday's is never scheduled.
  For a daily goal this is precisely "reminds once, then silence until I
  happen to open the app."
- Bootstrap's re-arm additionally waits up to 30 s for a signed-in user and
  is skipped when none appears (`app_bootstrap.dart:126-142`), so a
  signed-out/offline cold boot re-arms nothing until a later resume.

#### C5 — [HIGH] Suppressed reminders are queued into a void
- Suppression with `retryAllowed: true` (active override) parks the intent in
  the in-memory `_suppressedQueue` (`attention_orchestrator_service.dart:485-494`).
- The flush, `onOverrideEnded` (line 222), has **zero production callers** —
  `ContextOverrideService._doEnd` ends overrides with
  `suppressedItems: const [], // Phase C will populate this`
  (`context_override_service.dart:184`), and the expiry poller only sets the
  review-card flag (`context_override_expiry_poller.dart:38-45`).
- The queue is also process-lifetime only, so even a wired flush would lose
  contents on kill. Combined with C6 below, evaluating a reminder due within
  30 min while a meeting/sleep/DND override is active *permanently deletes*
  it: cancel first, suppress, never retry.

#### C6 — [HIGH] Task re-sync destroys the armed alarm before knowing a replacement will exist
- `_applyReminders` cancels the entity's live slot up front
  (`reminder_sync_service.dart:208`) and only then evaluates. If the
  evaluation ends in suppression (override, coaching back-off), budget
  denial, or a null intent (blank title), the user's previously armed
  notification is already gone.
- The orchestrator itself was explicitly fixed to avoid this — budget check
  *before* cancel (`attention_orchestrator_service.dart:395-418`) — and the
  goal path leans on that ordering on purpose
  (`goal_reminder_sync_service.dart:95-99`). The task path defeats the guard
  from the caller side. Every `syncForTaskIds`/`scheduleFromCache` run
  re-rolls this dice for every reminder.

#### C7 — [HIGH] The ignored-detector inflates the back-off counter and can silence a task permanently
- When `checkIgnoredTimeouts` does fire (post-snooze), nothing updates
  `lastTriggeredAtMs` or clears `pendingAction` on the ignored path
  (`attention_orchestrator_service.dart:201-215` mutates only the ledger),
  so **every** foreground resume past the 15-min window re-fires "ignored"
  for the same reminder: ledger `ignoredCount` climbs once per app-open
  without any new delivery having occurred.
- Under `CoachingStyle.supportive`, `shouldBackOff` trips at 2
  (`coaching_style_delivery_policy.dart:25-32`) and the follow-up intent is
  suppressed with `retryAllowed: false` (`attention_orchestrator.dart:71-83`)
  — the task goes permanently quiet after two app opens.
- Under other styles the follow-up is re-scheduled to `now + 15 min` on
  every resume (`_scheduleFollowUp`, line 566), so a user actively using
  their phone keeps sliding the follow-up in front of themselves and it
  fires only after they stop.
- Meanwhile the incremented escalation level is put on the intent but never
  persisted back to the config (see M2), so the ladder that IS reachable
  never actually climbs.

#### C8 — [MEDIUM] Saving a task awaits a remote read before arming the reminder
- `syncForTaskIds` awaits `hydrateFromRemoteForTasks` — a Firestore
  `whereIn` `.get()` (`reminder_sync_service.dart:98-99`,
  `isar_reminder_repository.dart:55-61`, `reminder_repository.dart:65-72`) —
  before the notification is ever evaluated. On a slow connection the
  reminder for a just-saved task isn't armed until the fetch resolves; kill
  the app in that window and it is never armed. This is a straight
  offline-first violation on the save path (CLAUDE.md rule 1/2).
- Same LWW merge means another device's stale config (older escalation
  state, old time) can overwrite live local state whenever its
  `updatedAtMs` is newer by wall clock; a config pulled by
  `RemoteIsarMerge._pullReminders` is not re-applied to the OS until the
  next cold start (the recompute graph's notifications step covers goals
  and intentions only — `unified_recompute_graph.dart:147-171`).

### 10.2 Why the times look miscalculated

#### T1 — [CRITICAL] Boot reconciliation confuses "not yet fired" with "dismissed" and fires reminders early
- `NotificationReconciliationService` compares ledger rows in
  `scheduled`/`delivered` state against `getActiveNotifications()` — the
  **delivered tray** (`notification_reconciliation_service.dart:57-84`). A
  future-scheduled notification lives in the *pending queue*
  (`pendingNotificationRequests`), never the tray, so on **every cold start
  every correctly armed future reminder** is marked cancelled and pushed to
  `reEvaluateIfAppropriate`.
- `reEvaluateIfAppropriate` ignores the config's `scheduledAtIso` *and*
  `enabled` flag and builds a follow-up with `proposedAt: _now()`
  (`attention_orchestrator_service.dart:320-349`); `_executeDecision` treats
  a non-future `deliverAt` as immediate (line 394) and calls `showNow` —
  i.e. the "9 PM" reminder fires the moment the user opens the app at 2 PM,
  and the immediate `show` with the same deterministic id replaces the real
  pending 9 PM request.
- Whether the user actually sees it depends on a race: `reconcile()` is
  launched `unawaited` (`app_bootstrap.dart:67-73`) concurrently with
  `scheduleFromCache` (line 78), whose `cancelForEntity` may remove the
  spurious tray item and re-arm the real time — or run first and be undone.
  Nondeterministic interleaving is why the misfires feel random. This is
  the strongest single explanation for "sometimes it miscalculates the
  times."
- The same pass also cancels "phantoms": any tray notification whose ledger
  row is not currently `scheduled`/`delivered` (lines 86-103). A row a
  snooze race left in `snoozed` state (see L2) gets its visible
  notification deleted from the tray at next launch.

#### T2 — [HIGH] Collision spacing silently moves user-chosen times, using future "deliveries" and ignoring importance
- `_executeDecision` records every schedule under `RecentDelivery` with
  `deliveredAtMs = deliverAt` — including times hours or a day in the
  future (`attention_orchestrator_service.dart:463-471`).
- `_computeCollisionDelay` then delays any other entity's intent proposed
  within ±3 min of that future time to it + 3 min
  (`attention_orchestrator.dart:201-230`). Two reminders set for 9:00 always
  land 3 minutes apart; a third at 9:02 lands at 9:06.
- Which one moves is whatever `_applyReminders` evaluates later (Isar
  iteration order), and each full re-sync can re-roll the order — so the
  shifted reminder can change between runs. The docstring says the
  lower-importance intent is delayed (lines 199-200); `importance` is never
  consulted in the implementation.

#### T3 — [MEDIUM] Timezone resolution failure silently shifts every reminder by the UTC offset
- `_configureLocalTimeZone` falls back to leaving `tz.local` = UTC on any
  `FlutterTimezone` failure with only a debugPrint
  (`local_notifications_service.dart:117-128`). Every `zonedSchedule` then
  interprets the wall-clock DateTime as UTC — for a UTC+3 device all
  reminders fire 3 hours late. Nothing surfaces or retries this; the app
  runs an entire session in the shifted state.
- Stored times have no timezone identity anywhere (`scheduledAtIso` /
  `nextPromptAtIso` are offset-less `toIso8601String()` local strings), so
  travel across zones re-interprets them in the new local zone by design —
  unstated but at least self-consistent; the silent-UTC case is the harmful
  one.

#### T4 — [MEDIUM] The schedule normalizer moves a just-missed time a full DAY forward
- `_normalizeScheduleTime` advances a non-future `when` by +1 day until it
  is future (`local_notifications_service.dart:510-518`). `_executeDecision`
  checks `immediate` before calling `schedule`, but any delay between that
  check and the plugin call (awaits on budget/ledger/cancel sit in between)
  turns a due-in-seconds reminder into *tomorrow at the same time* with a
  ledger row still claiming today. Narrow window, whole-day error, matches
  a "sometimes wildly wrong" report.

#### T5 — [MEDIUM] Two different snooze tables answer "how long is Later?" per mode
- `RoutineModePolicy.baseSnoozeMinutes`: flexible 15 / disciplined 10 /
  extreme 5 (`routine_mode.dart:131-160`).
- `AdaptiveReminderPolicy` cadence `initialSnoozeMinutes` (used by the
  notification's Snooze action): flexible 12→8 / disciplined 8→5 /
  extreme 5→3 by urgency, then decayed −2/level
  (`adaptive_reminder_policy.dart:75-171`, `:201-222`).
- The same gesture produces different delays depending on which surface
  handled it — perceived as time miscalculation.

#### T6 — [LOW] Suppression is evaluated at scheduling time, not delivery time
- Override suppression applies only to intents *evaluated* while the
  override is active and due within 30 min (`attention_orchestrator.dart:96-106`).
  A reminder armed at 22:00 for 23:30 rings mid-sleep-window because local
  notifications fire unconditionally once scheduled; a reminder evaluated
  at 23:00 for 23:20 is suppressed (then lost, per C5). Identical settings,
  opposite outcomes, decided by when the scheduler happened to run.

### 10.3 What the modes actually change today

Intended per the policy tables: cadence + repeat pressure, escalation
ceiling, hard gate, interruption level, batching exemption. Actual:

#### M1 — [HIGH] InterruptionLevel never reaches the OS
- `local_notifications_service.dart` contains zero references to
  `InterruptionLevel`; iOS `DarwinNotificationDetails` sets only
  `categoryIdentifier` (line 207) and Android uses fixed max-importance
  channels (lines 193-206, 232-239). An extreme-mode `critical` and a
  flexible `low` render identically. The level's only real effect is the
  override suppression matrix (`override_attention_policy.dart:22-44`) —
  i.e. modes today change *when a reminder is dropped*, not how it sounds.
- `AttentionDecision.silent` (focus-silence path,
  `attention_orchestrator.dart:109-116`) is likewise never read by
  `_executeDecision` — "silent" deliveries are delivered loud.

#### M2 — [HIGH] Escalation level never persists on the ignored path
- `_scheduleFollowUp` computes `escalation = config.escalationLevel + 1`
  into the intent but never writes it back
  (`attention_orchestrator_service.dart:546-576`); only `requestSnooze`
  advances the stored level (`reminder_sync_service.dart:138-152`).
- Consequences: extreme's tail-phase logic
  (`reminder_sync_service.dart:250-261`, `kExtremeMaxTailFollowUps`) is
  unreachable via ignores; `InterruptionLevelResolver`'s ≥2 escalation
  bumps rarely trigger; and the escalation copy —
  "start now or submit a logical reason", "Please open SidePal…"
  (`bodyForReminder`, `reminder_sync_service.dart:315-342`) — has **no
  caller on the orchestrator delivery path**. `_buildNotificationBody`
  always renders "Time to start: X" (`attention_orchestrator_service.dart:526-539`)
  regardless of mode, level, or hard-gate state.

#### M3 — [MEDIUM] Unknown or custom mode ids silently degrade to flexible
- `RoutineModeConfig` explicitly supports custom mode ids
  (`routine_mode.dart:89-129`), but every resolver hard-codes the three
  built-ins and defaults everything else to flexible
  (`adaptive_reminder_policy.dart:224-229`, `effective_task_mode.dart:19-44`,
  `interruption_level_resolver.dart:22-41`). A future custom "strict-ish"
  mode would quietly get the *weakest* cadence. Today's practical risk is
  a legacy/typo id doing the same.

#### M4 — [LOW] Batched notifications would show raw intent ids
- The batch body joins `decision.batchedWith` — which carries intent ids
  (`ri_…` StableIds), not titles
  (`attention_orchestrator.dart:133-141`,
  `attention_orchestrator_service.dart:530-534`). Batching partners come
  only from the (never-flushed, usually empty) suppressed queue, so this
  is nearly unreachable — which is itself the finding: FR-C-15/16 semantic
  batching is effectively inert, and the one visible artifact it could
  produce is user-facing debug ids.

### 10.4 Ledger & interaction integrity

#### L1 — [MEDIUM] The ledger never learns that a scheduled notification fired
- `markDelivered` is called only on the `showNow` path
  (`attention_orchestrator_service.dart:455-459`); a `zonedSchedule`d
  notification that fires keeps state `scheduled` forever. Reconciliation
  therefore cannot distinguish "fired and sits in tray" / "fired and
  user-dismissed" / "never fired" — feeding T1 — and
  `getDeliveryClaimsByKindInRange`'s "reached the user" heuristic
  (`notification_ledger_repository.dart:109-126`) undercounts real
  deliveries for the intention caps.

#### L2 — [MEDIUM] Snooze writes race and can corrupt the new slot's state
- The response handler fires `onInteractionReceived(snoozed)` **unawaited**
  and immediately awaits `requestSnooze`
  (`notification_response_handler.dart:460-471`). `_recordSnooze` looks up
  the entity's latest ledger row (`attention_orchestrator_service.dart:578-598`);
  when it loses the race it stamps the *newly scheduled* row
  `state = snoozed`. That row then falls out of reconciliation's pending
  set, and its fired notification is cancelled as a phantom at next launch
  (T1, step 4).

#### L3 — [LOW] Phase C persistence fields are decorative
- `ReminderConfig.activeNotificationId` and `evaluationTrace` are never
  written by any reminder-path code (repo-wide grep; the `evaluationTrace`
  hits are the unrelated analytics focus feature). The doc comments on
  `reminder_config.dart:36-44` describe behavior that does not exist.

#### L4 — [LOW] `copyWith` cannot clear nullable fields
- `ReminderConfig.copyWith` uses `?? this.x` for every nullable
  (`reminder_config.dart:99-132`), so `_resolveReminder`'s
  `nextPromptAtIso: null` (`reminder_sync_service.dart:179`) silently keeps
  the stale value. Harmless today only because the pending flag is cleared
  alongside; it is a trap under any future fix that consults
  `nextPromptAtIso` independently.

#### L5 — [LOW] Zero user-facing health signals
- Permission loss surfaces once as an add-task snackbar
  (`add_task_reminder_persistence.dart:13-23`); budget exhaustion, UTC
  fallback, reconciliation churn, and schedule failures are debugPrints.
  There is no "your reminders can't fire" state anywhere in Settings.

### 10.5 Platform notes

- [HIGH] Android is structurally behind iOS here: `exactAllowWhileIdle`
  needs the exact-alarm permission flow and a boot receiver to survive
  restarts (cross-ref §4 "Android notification scheduling will not survive
  release conditions" — still true on this branch). Failures land in
  `_executeDecision`'s catch as a log line.
- [MEDIUM] iOS Focus/DND: without time-sensitive/critical entitlements and
  with interruption levels unmapped (M1), the app-side suppression matrix
  is the *only* politeness layer, and the OS one applies uniformly on top.
- [INFO] The 64-pending cap is well-guarded in principle
  (`notification_budget.dart`, fail-closed), but the practical inventory
  (1 slot/task + 3/intention + 1/goal + coach insight) sits far below 56 —
  budget denial is unlikely to be the everyday failure the user sees.

### 10.6 Verified working (genuinely solid pieces)

- Timezone init in the normal case: `flutter_timezone` → `tz.setLocalLocation`
  with the root-cause comment (`local_notifications_service.dart:43-47`).
- Local-first storage of configs: Isar + outbox replication + LWW merge
  (`isar_reminder_repository.dart`), no awaited Firestore *writes* on
  interaction paths (C8's awaited *read* is the exception).
- Sleep-window math including midnight crossover
  (`sleep_window_util.dart:10-27`) and the 30-minute suppression horizon
  protecting tomorrow's reminders from tonight's window
  (`attention_orchestrator.dart:17-23,96-99`).
- Deterministic notification ids mirrored between route resolver and
  service, with a test enforcing the mirror; slot-scoped cancel for
  intention ladders vs entity-scoped for single-slot kinds
  (`attention_orchestrator_service.dart:411-418`).
- The goal path's budget-safe swap ordering (cancel only after approval —
  `goal_reminder_sync_service.dart:95-99`).
- Tap handling: payload prefixes, id-map + reminder-scan fallback,
  cold-start launch drain with dedupe signature, queue-then-flush
  navigation (`notification_response_handler.dart`), and the strict/extreme
  "Done falls through to the focus flow" contract
  (`notification_task_actions.dart:43-46`).
- Mode → cadence/level *tables* themselves are coherent and unit-tested;
  the failure is that production never executes most of them.

### 10.7 Priority order (if remediation is authorized later)

1. **T1** — reconcile against `pendingNotificationRequests() ∪ tray`, and
   make `reEvaluateIfAppropriate` respect `enabled` + `scheduledAtIso`.
   Stops the at-launch misfires immediately.
2. **C1/C2** — since iOS gives no fire callback, the only way disciplined/
   extreme can keep nudging with the app closed is to pre-schedule the
   cadence's repeat plan (`autoRepeatOffsets`, within budget) and cancel
   the tail on interaction. This is what the dead policy was written for.
3. **C3/C4** — roll `scheduledAtIso` forward for recurring tasks and give
   goals more than one armed occurrence (or a repeating OS matcher as the
   closed-app floor).
4. **C6** — move the task path's cancel after approval, matching goals.
5. **C5** — wire `onOverrideEnded` from `_doEnd`/poller and persist the
   suppressed queue.
6. **C7/M2** — persist escalation on every follow-up; advance
   `lastTriggeredAtMs` when an ignore is recorded so a resume can't
   double-count.
7. **M1** — map InterruptionLevel to per-level Android channels and iOS
   interruption levels so the modes become audible, not just droppable.
8. **C8** — make `syncForTaskIds` schedule from local state first and
   hydrate remotely in the background.
