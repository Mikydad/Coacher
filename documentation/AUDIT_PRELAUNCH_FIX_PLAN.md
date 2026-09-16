# Pre-launch audit — verification + fix plan

**Source:** `AUDIT_PRELAUNCH_2026-09-15.md` (external, ChatGPT-generated, against
revision `cd90962` = merge-base of `feat/home-light-redesign` and `main`).
**Verified:** 2026-09-15 against `feat/home-light-redesign` @ `b9d426a` by seven
parallel read-only passes over rules, Functions, and `lib/`.
**Result:** 32 findings → 28 CONFIRMED, 4 PARTIALLY CONFIRMED, 0 rejected.
Seven additional defects found that the audit missed (§2).

Status legend for the batches below: `[ ]` not started · `[~]` in progress ·
`[x]` done · `[-]` deferred (decision logged).

---

## 1. Verdict table (current-checkout evidence)

| ID | Verdict | Where (current checkout) | Size |
|---|---|---|---|
| C1 | CONFIRMED | `firestore.rules:17-31` exists-only membership + `circleIds` under owner wildcard (`:68-71`); members self-create/update `:120-123`; `storage.rules:18-23`; `functions/src/stakes/callables.ts:124-129`. Decision log already calls this "standing rules debt" (`GUIDELINES.md:2135`). | L |
| H1 | CONFIRMED | `nsfw_screen.ts:156-163` keys verdict on `challengeId` only; `:96-133` applies to any pending challenge; `sweep.ts:72-96` re-applies every 15 min. Attacker's image never becomes the staked photo (`callables.ts:296` pins path), so harm = unscreened activation or spurious cancel. | S |
| H2 | CONFIRMED | `remote_isar_merge.dart:132-135` `_uidStillCurrent` can't fire during logout (A still current); 21 unguarded `writeTxn`; `clearLocalSession` never drains `_activeRemotePullFuture`. | M |
| H3 | CONFIRMED (worse) | `memory_extraction_service.dart:165-220` no uid capture; `firestore_paths.dart:10-20` resolves uid at write. **Logout triggers it**: invalidating `aiAssistantServiceProvider` → `dispose()` → `_finalizeStashedSession()` → extraction starts, wipe runs, persist lands under next uid. | S–M |
| H4 | CONFIRMED | `timer_runtime_cache.dart:11-14`, `focus_resume_store.dart:16-19`, `strategist_proposals_store.dart:20`, `announced_insight_store.dart:59` (+ `recovery_triage_count_v1`, `reminder_cache_store.dart`) — none cleared in `auth_session_policy.dart:69-117`. | S |
| H5 | CONFIRMED | `plan_tomorrow_providers.dart:12-83` non-autoDispose, `ref.read`, date captured once; `invalidateTomorrowProviders` exists (`:85`) but isn't called from `user_scoped_invalidation.dart`. | S (patch) / M (proper) |
| H6 | PARTIAL | Four circle families + `stakeCreateReplicatorProvider` not auth-scoped nor invalidated; repos use `FirebaseFirestore.instance` directly so `firestoreClientProvider` re-scoping doesn't apply. Lower severity: circle-scoped data, `myCircleIdsProvider` gates navigation. | S |
| H7 | CONFIRMED | `ledger.ts:101-133` no artifact read; 110 pts/day mintable. Bounded: win bonus only when someone loses (`sweep.ts:275`), removal 300. Doc-existence check is near-worthless because those docs are client-writable anyway. | S (honest) / L (real) |
| H8 | CONFIRMED | `firestore.rules:255-276` any unitIndex<90, amount≤100000; `measurement.ts:46-89` sums, 75% pass. Units ≥ `totalUnits` discarded; backfill flag only. | S (rules) / M (callable) |
| H9 | CONFIRMED | `index.ts:675-696` dispatch concurrent with quota tx; marker only for `loopIndex===0`; daily/follow-up/token-budget/clip rejections never set marker; `speech_stream.ts:104-145` same. `aiSpeech` callable is sequential (fine). | S–M |
| H10 | CONFIRMED (understated) | No `firebase_app_check` in pubspec; flag `index.ts:197` off; speech endpoints have zero App Check code; manual streams send no header. Flipping the flag would also break the **callable** path (plugin attaches no token without app-check). Rollout order was deliberate (`GUIDELINES.md:2315`). | M + device |
| H11 | PARTIAL | Facts hold (`tier_providers.dart:9,85-93`, no RevenueCat), but `setEntitled` has **zero callers** and enforcement is off → no live exploit. Real risk: onboarding `PremiumStep` shows "Start Free Trial" with no IAP behind it (App Review). | S (ship free) / L (RevenueCat) |
| H12 | CONFIRMED | `auth_repository.dart:406-419` bare `delete()`; `account_purge.ts:33-111` stakes-only; no `recursiveDelete` anywhere; photo failures `.catch(logger.warn)`. Plus: deviceTokens dereg runs **after** auth delete so it is rejected → orphan token stays in `morningBrief`'s collectionGroup. | L |
| H13 | CONFIRMED | `authorizationCode` never read; `revokeTokenWithAuthorizationCode` absent (SDK 5.7.0 has it); reauth only email/password (`account_settings_screen.dart:42-45,151-155,258-336`). | M |
| H14 | CONFIRMED | `account_settings_screen.dart:157-173` delete → `if(!mounted) return` → wipe; no provider invalidation, no landing barrier. **Masked today**: guest re-sign-in triggers AuthGate's uid-change wipe. Unmasked once `REQUIRE_REGISTERED_AUTH=true`. | S–M |
| H15 | CONFIRMED | Planning hard-deletes + `outboxDelete`; pull upsert-only; `initialize()` runs flush and pull concurrently (`sync_service.dart:74-84`). `active:false` tombstone pattern already exists for intentions/facts/people/activity — reuse it. | M |
| H16 | CONFIRMED | `sync_service.dart:304-307` `set(merge:true)`, no rule guard on `updatedAtMs`. Payloads already carry `updatedAtMs`. | S |
| H17 | CONFIRMED (worse) | `account_purge.ts:52-66` cancels without ledger write; nothing ever releases a `cancelled` lock. **Plus**: only the deleted user's escrows refund; surviving participants' `held` money escrows on team challenges are stranded. | S–M |
| M1 | CONFIRMED | `firestore.rules:183-190` any member rewrites `memberProgress`/`teamTotal`/`status`; client vote() flips status client-side. | M |
| M2 | CONFIRMED | `firestore.rules:45-55,106-108` ±1 with no membership/bounds; server join trusts stored count (`circles/callables.ts:206`) → DoS a circle by pushing it to 8. | S |
| M3 | CONFIRMED | `offline_sync_queue.dart:29-33` truncate-in-place, unserialised; `load()` no try/catch; awaited in bootstrap (`app_bootstrap.dart:87`). | S |
| M4 | PARTIAL | No classification/backoff (`:312-316`); `clearQueue` race (`:203` vs `:321-324`) real. Overlap prevented by `_isSyncing`. **Missed**: Firestore persistence is on, so an offline `set()` never throws → flush hangs, amber line never shows on network loss. | M |
| M5 | CONFIRMED | `points_providers.dart:14-22` captures `activeUid`; run-once boolean. Staleness (B sees 0), not leakage. | S |
| M6 | CONFIRMED | `triggers.ts:31-32` `Date.now()`; `firestore_layout.ts:47-48` drops rows without stamp. Cutoff is deadline+12h, so real risk = failed trigger voids on-time evidence. | S |
| M7 | CONFIRMED | `remote_isar_merge.dart:126,128-130,190-192` strict `>` on device clocks; acknowledged in code header. | S |
| M8 | CONFIRMED (worse) | `voice_tts_streaming.dart:491-513` catch attached after latch → rejection reaches zone handler → **recorded as fatal**; orb stuck until tapped. | S |
| M9 | CONFIRMED | `voice_mode_controller.dart:201-241` no try/timeout, no generation capture; `pauseToIdle` leaves `_active`; only `paused` observed. | M |
| M10 | CONFIRMED (corrected) | `swallowedAsyncError` (25 sites) + sync/analytics only `debugPrint`; sole nonfatal `recordError` is the tester smoke test. Correction: Firebase-init failure is a **white-screen boot abort** (`main.dart:57` throws), not silent proceed. | M |
| M11 | PARTIAL | Facts hold, but Reminder Debug is read-only, crash is self-inflicted behind 7-tap + long-press + confirm, and the design was logged 2026-09-12 (rejected `kDebugMode`). Real exposure: tester gate is client-only and also unlocks a billed AI recompute. | S–M |
| M12 | CONFIRMED | Waitlist unauth create (no app writer); `storage.rules:63-65,83-85` anonymous can upload unlimited photos at free-form challengeIds; every upload → paid SafeSearch. | M |
| L1 | CONFIRMED | `profile_providers.dart:67-75`, `quick_directives_provider.dart:51-98` one-shot. | S |
| L2 | CONFIRMED | `firestore.rules:134-144` whole-map replace; client depends on it (`circle_message_repository.dart:47-57`). | M |

### Additional defects found during verification (not in the audit)
1. **approveJoin writes the *other* user's `circleIds`** (`user_circle_membership_service.dart:214-245`) — owner-only rule denies it → approved members never get their index (latent bug; fixed by moving approve server-side).
2. **Offline flush hangs instead of failing** (M4 above) — contradicts "stuck writes show the amber line".
3. **Logout actively fires memory extraction** (H3 above).
4. **Surviving participants' money escrows stranded on deletion** (H17 above).
5. **deviceTokens dereg on deletion is unauthenticated** (H12 above).
6. **Firebase-init failure = white screen** (M10 above).
7. **TTS play() rejection recorded as a fatal crash** (M8 above).

### Test coverage gaps
- `rules-tests/` has zero circle/member/memberCount/challenge/reaction/waitlist tests and **no Storage rules tests at all**.
- Functions: no tests for `nsfw_screen` trigger, `grantPoints`, `stakeEvidenceArrived`, `stakeAccountPurge`, or the quota/dispatch ordering.
- Flutter: `test/core/sync/*` harness (fake firestore + Isar harness) can host every sync case; no test for pause-during-voice-start or a rejecting audio player.

---

## 2. Fix batches (ordered by risk and dependency)

Each batch is one branch-scoped unit of work with its own analyze + test run.
Server batches end with a deploy checklist (rules / functions / indexes) that
Miko runs.

### Batch A — Server access control (C1, M2, M1, L2, H1, M6, M12-uploads)  `[x]` built 2026-09-15, deploy pending
Must land client + rules + functions together (client self-join must stop before rules deny it).
1. `isCircleMember` → `get(member).data.status == 'active'` in firestore.rules, storage.rules, `stakes/callables.ts:124`. Drop `hasCircleIndex` from `canAccessCircleContent`; add `circleIds` to the owner-wildcard exclusion list (server-owned, owner-read).
2. New callables (template = `circleJoinWithInvite`): `circleCreate`, `circleJoinOpen`, `circleRequestJoin`, `circleApproveJoin`, `circleRemoveMember`/`leave`. Each writes member + memberCount + `circleIds` atomically. Client `user_circle_membership_service.dart` switches to them (optimistic-then-honest: local circle list update + callable + per-item retry).
3. Members rules: create denied (server-only); self-update `hasOnly(['displayName','updatedAtMs'])`; moderator update limited to role/status.
4. memberCount: standalone client update denied (bounds 0..8 kept as defence in depth).
5. M1: progress update must satisfy `memberProgress.diff().affectedKeys().hasOnly([uid])` and not touch `status`; status via an `onWrite(votes)` tally trigger.
6. L2: reactions keyed by uid (`reactions.{uid}: [emoji]`), rule `diff().affectedKeys().hasOnly([uid])`; client aggregates.
7. H1: trigger parses uid from filename, ignores non-`{challengeId}/{uid}.jpg`, stores `{status,reasons,uid,path,generation}`; `applyVerdictToChallenge`, `applyPendingScreens`, and create-tx act only when `verdict.path == participant.photo.storagePath`.
8. M6: stamp `snap.createTime` in trigger; `evidenceFromSnap` falls back to `createTime` when missing.
9. M12-uploads: storage.rules require non-anonymous for `stake_photos`/`stake_evidence`; `stake_evidence` requires `firestore.exists(stake_challenges/$id)` and uid in participants; `stake_photos` requires a `stake_photo_reservations/{challengeId}` doc (written by a tiny callable before upload); skip SafeSearch when no reservation; bucket lifecycle rule 1 day for unreserved photos.
10. Tests: `rules-tests/circles.rules.test.js` (stranger self-join, circleIds self-write, pending/removed access, memberCount, challenge progress, reactions) + first Storage emulator suite; `nsfw_screen` binding test.
Deploy: rules + storage rules + functions, same release as the client.

**As built (2026-09-15):**
- Functions: `circles/membership.ts` (pure policy + tests), `circles/callables.ts` (+`circleCreate`, `circleJoin`, `circleApproveJoin`, `circleDeclineJoin`, `circleLeave`, `circleRemoveMember`, `circleDelete`, `circleRepairIndex`; invite join now also enforces the per-account cap), `circles/challenge_votes.ts` (`circleChallengeVoteTally` trigger), `stakes/screen_verdict.ts` (`parseStakePhotoObject`, `verdictBindsTo`), `stakes/nsfw_screen.ts` (bound verdicts, reservation check, unreserved objects deleted), `stakes/callables.ts` (`isCircleMember` = active; create-tx consumes only a bound verdict; `stakeReservePhotoUpload`), `stakes/sweep.ts` (bound re-apply, `expirePhotoReservations`), `stakes/triggers.ts` + `firestore_layout.ts` (createTime receipt). Per-account cap reads the server-owned `users/{uid}/entitlements/pro` doc (Pro hook, D2).
- Rules: membership = active member doc; `circleIds` + `entitlements` carved out of the user wildcard (owner-read only); private circle docs readable by members only (discovery filters `visibility == public`; the client now watches circles per-document); member docs client-write-denied, list readable for public circles / members / own doc; circle create/delete/memberCount/creatorId server-owned; challenge `status` client-write-denied, member progress limited to own key; reactions moved to `reactionsByUser.{uid}` (legacy `reactions` read-only, merged for display); storage: registered-only uploads, stake photos need the caller's reservation, evidence needs an existing challenge the caller participates in, proofs need active membership, `challenge_proofs` is create-only.
- Client: `circle_functions.dart` typed client; `UserCircleMembershipService` is a thin wrapper (instant limit pre-check kept; server `reason` → typed exceptions, new `CirclePrivateException`); `CircleRepository.watchCircles` merges per-doc streams; `ChallengeRepository.vote` writes own vote only; `CircleMessage.reactionsByUser` + `setMyReactions`; create flow calls `reservePhotoUpload` before the upload.
- Tests: Functions 296 green; rules 78 green (`npm test` = `test:firestore` + `test:storage`, separate emulator projects — Storage cross-service lookups resolve against the emulator's default project); Flutter community suite + new membership-service suite green.
- Deploy checklist: `firebase deploy --only firestore:rules,storage,functions`. Rules and client must ship together: an older client's self-join/approve/leave writes are denied after the rules deploy (pre-launch, so no public build is affected). Nothing new in `firestore.indexes.json` (single-field filters only).
- Deferred inside A: waitlist stays unauthenticated (D7); legacy `reactions` entries can't be un-reacted (read-only by design); `challenge_progress_sync_service` still writes own progress via the same repo path (allowed).

### Batch B — Session teardown on the client (H2, H3, H4, H5, H6, M5, L1, H14)  `[x]` built 2026-09-15
1. `SessionScope` (`lib/core/session/`): `(uid, generation)`; generation bumped synchronously as the first line of `clearLocalSession` and AuthGate's uid-change branch.
2. Drain before wipe: `SyncService.drainInFlightPull()`, `MemoryExtractionService.drain()`; at logout **drop** the stashed AI session instead of finalizing it.
3. `RemoteIsarMerge`: capture scope at start; single `_write(fn)` helper wrapping the 21 `writeTxn` sites; abort when generation moved (H2).
4. Extraction captures scope, bails before persist on change; repo writes take explicit uid (H3).
5. `clearLocalSession` clears `timer_runtime.json`, `focus_resume.json`, strategist/insight/triage prefs, reminder cache; file clear runs **before** `executionControllerProvider` invalidation (H4).
6. Invalidation list additions: tomorrow providers, four circle families, replicator, `announcedInsightTodayProvider`, `pointsBalanceProvider`, `totalCompletionsCountProvider`, `quickDirectivesProvider`; each also `ref.watch(authUidProvider)` (H5, H6, M5, L1). Replicator ops bind to originating uid and refuse retry from another.
7. H14: `AccountDeletionCoordinator` (widget-independent): landing barrier → invalidate + deregister (while authed) → reauth/revoke/delete → `clearLocalSession()` unconditionally; `mounted` guards UI only.
8. Tests: A→B switch with a pending pull/extraction; deletion with auth emitting null before `delete()` returns.
Follow-up (post-launch, L): per-UID Isar directory + guarded-write funnel with an architecture test banning raw `writeTxn` (110 sites) — retires the hand-maintained list.

**As built (2026-09-15):**
- `lib/core/session/session_scope.dart`: `SessionScope` generation + `isTearingDown`, `SessionToken`, `StaleSessionError`. Bumped synchronously by `invalidateUserScopedProviders` / `invalidateUserScopedProvidersIn` and by `clearLocalSession` (which ends the teardown in `finally`).
- `AuthSessionPolicy.clearLocalSession`: begin teardown → release transports (skippable for deletion) → `SyncService.drainInFlightPull()` + `MemoryExtractionService.drainInFlight()` → cancel notifications → clear file caches (timer runtime, focus resume, legacy reminder cache) → Isar wipe → outbox → cursors → prefs (+ strategist proposals, announced insight, triage counter).
- `RemoteIsarMerge`: captures a `SessionToken`; all 21 write sites go through `_write()` which re-checks the token (and uid) before every `writeTxn`.
- `MemoryExtractionService`: `onSessionEnded` is a no-op while tearing down (the logout path's AI-service dispose fires it); each extraction captures a token and drops the model's answer if the session ended; in-flight registry + `drainInFlight()`.
- Owner-tagged caches: `TimerRuntimeCache` (`ownerUid`, foreign file deleted on load), `FocusResumeStore` (`_ownerUid` + static `deleteFile`), `StrategistProposalsStore` (`owner`), `AnnouncedInsightStore` (`ownerUid`, foreign key removed).
- Providers: `userScopedProviders` / `circleScopedProviders` are now lists (widget-free reset possible); added tomorrow slots/tasks, replicator, points balance, announced insight, completions count, quick directives; circle challenge/commitment/pulse families watch `authUidProvider`; `tomorrow*` watch the repository; `pointsBalanceProvider` watches the uid; `PointsEarnService` keys its sweep by `uid:day`; `totalCompletionsCountProvider` is a live Isar watch; replicator binds each op to its uid and refuses a retry from another account.
- H14: `AccountDeletionCoordinator.run` (landing barrier → provider reset + teardown → release transports while authenticated → delete → unconditional wipe; failure lifts the barrier). `account_settings_screen` calls it with the root container; `mounted` guards UI only.
- Tests: `test/core/session/session_scope_test.dart`, `owner_tagged_caches_test.dart`, `test/features/auth/account_deletion_coordinator_test.dart`, two stale-session cases in `remote_isar_merge_cursor_test.dart`. Not covered by a test: extraction drop (needs the five-repo harness) — reviewed by hand.
- Known pre-existing failure on the branch: `test/features/time_tracker/siri_log_activity_test.dart` "minutes become an intended duration and arm a reminder" (time-of-day dependent; fails on the untouched head too).

### Batch C — Account deletion, server side (H12, H13, H17)  `[x]` built 2026-09-15, deploy pending
1. H13 (client): reauth per provider — Apple: fresh `getAppleIDCredential` → `reauthenticateWithCredential` → `revokeTokenWithAuthorizationCode(authorizationCode)`; Google: `authenticate()` → reauth; password: existing dialog. Cancellation aborts silently. Console prerequisite: Apple provider must have Services ID / Team ID / Key configured.
2. H12 (functions): extend the onDelete purge — read `circleIds` first, delete each `circles/{cid}/members/{uid}`, then `db.recursiveDelete(users/{uid})`, delete `aiUsage/{uid}`, `circle_invites` where `createdBy==uid`, `feedback/{uid}/` storage; write `account_purges/{uid}` job doc with per-step status; `stakeSweep` re-drives failed steps. Retain (documented): `points_ledger`, `stake_escrows`, terminal `stake_challenges` events.
3. H17 (functions): in the cancel tx, `stake_release_{challengeId}` for every *other* participant on `h2h_points`/`team_points`; `refund_pending` on every other participant's `held` escrow for money types; harden `writeLedgerTxn` to `tx.create`.
4. Client copy: name what is retained.
5. Tests: emulator purge of a seeded uid; two-funded-user deletion from active + pending_verification.
Deploy: functions.

**As built (2026-09-15):**
- Functions: `stakes/purge_plan.ts` (pure: `settlementForCancellation`, step inventory, `purgeStatus`) + tests; `stakes/account_purge.ts` rewritten around `purgeAccount(uid, now)` — steps `stakes` (cancel + `stake_release` for every locked points side, held escrows → refund_pending, photos/evidence/screen docs), `memberships` (member docs deleted, memberCount −1 for active, moderatorIds pruned, index cleared), `user_tree` (`recursiveDelete(users/{uid})`), `ai_usage`, `feedback` (docs + `feedback/{uid}/` objects), `reservations`; job doc `account_purges/{uid}` records per-step status; `stakeSweep` re-drives `partial` jobs with a linear back-off. `writeLedgerTxn` uses `tx.create` (append-only for real). New collection-group field override for `members.userId` in `firestore.indexes.json`.
- Retained by decision D3: `points_ledger/{uid}`, `stake_escrows`, terminal `stake_challenges` + events; `circle_invites` stay with the circle.
- Client: `AuthRepositoryInterface.reauthenticateWithProvider(providerId)` — Apple: native sheet (fresh nonce) → `reauthenticateWithCredential` → authorization code kept; Google: account picker → reauth; cancellation → `AuthSignInCanceled`. `deleteAccount()` revokes the Apple token first (`revokeTokenWithAuthorizationCode`, failure logged, deletion proceeds). `deletion_reauth_strategy.dart` picks the path from `providerData` (Apple > Google > password > none); `account_settings_screen` uses it and the delete dialog names what is retained.
- Tests: Functions 284 green (`purge_plan.test.ts`); `deletion_reauth_strategy_test.dart`; auth screen fakes updated.
- Not automated: an emulator purge of a seeded account (Batch H); Apple revocation needs the Firebase console's Apple provider configured with Services ID / Team ID / Key — verify before release.

### Batch D — Sync integrity (H16, M3, M4, H15, M7)  `[x]` built 2026-09-15, rules deploy pending
1. H16: user-tree rule `request.resource.data.updatedAtMs >= resource.data.updatedAtMs` (or field absent); `processQueue` treats `permission-denied` on upsert as "lost the race → drop".
2. Ordering: `await processQueue()` before `syncFromRemote()` in `initialize()` and the connectivity handler.
3. M3: tmp-file + rename in `OfflineSyncQueue.save`; serialised save chain; tolerant `load()` (rename corrupt file, return `[]`); test with garbage JSON.
4. M4: `attempts`/`nextAttemptMs` on `OfflineOperation`; classify `FirebaseException.code` (permission-denied/invalid-argument/not-found → drop; unavailable/deadline → backoff); `_flushGeneration` bumped in `clearQueue` so a stale flush discards its `failed` list; per-write `.timeout(15s)` so offline flushes exit and flag `hasSyncIssue` honestly.
5. H15: `active` tombstone on `Routine`/`TaskBlock`/`PlannedTask` (build_runner), delete = tombstone + `outboxUpsert`, readers filter `active`, cascade in one txn, purge >30d at bootstrap. Then goals/reminders/timeBlocks.
6. M7: query `>= cursor − 5 min`, clamp `_noteSeen` to `now + 60 s`, daily force pull tracked in prefs.
7. Tests in the existing `test/core/sync/` harness: delete-vs-pull race, clearQueue race, stale-push rejection, cursor overlap.
Deploy: rules.

**As built (2026-09-15):**
- H15 as a **tombstone table, not soft-delete fields**: 14 files read `isarTasks`/`isarRoutines`/`isarBlocks` directly, so rows stay hard-deleted and readers are untouched. New synced set: `IsarDeletedEntity` (+ generated code, registered in `isar_schemas.dart`), `DeletedEntity` model, `users/{uid}/deletedEntities/{type}_{id}` path, planning deletes write local tombstones inside the same `writeTxn` and replicate them via `outboxUpsert` (children included on routine/block deletes), `RemoteIsarMerge._pullDeletedEntities` runs FIRST (applies remote tombstones locally, cascading), `_mergeRoutine/_mergeBlock/_mergeTask` skip rows a tombstone supersedes (tombstoned routines are not descended into), tombstones older than 30 days are purged locally. Goals/reminders/time blocks can adopt the same helper later.
- H16: user-tree `update` requires `updatedAtMs >= stored` (ties pass; docs without the field, creates and deletes unaffected); `processQueue` drops `permission-denied` upserts as "lost the race".
- M3: `OfflineSyncQueue.save` is temp-file + rename, `load` sets a corrupt file aside and returns empty; `SyncService._persistQueue` serialises writes.
- M4: `OfflineOperation.attempts/nextAttemptMs`; `isPermanentFailure` (permission-denied / invalid-argument / not-found / failed-precondition / already-exists → dropped) vs exponential back-off (5 s · 2ⁿ, cap 10 min, jitter); `_flushGeneration` discards a flush superseded by `clearQueue`; every write bounded by `writeTimeout` (15 s) so an offline flush ends and the amber line shows.
- Ordering: `flushThenPull()` replaces the concurrent flush + pull at init and on connectivity.
- M7: cursor queries re-read a 5-minute overlap, `_noteSeen` clamps future-dated stamps to now + 60 s, and a cursor-less full pull is promoted at least every 24 h (`sync_cursor_v1_last_full_pull`, cleared with the cursors).
- Tests: queue (classification, back-off, timeout, clear-during-flush), queue file (atomic, corrupt), planning delete tombstones, merge (local tombstone blocks resurrection, later edit wins, remote tombstone removes row, tombstoned routine skipped, overlap re-read), rules LWW guard (5 cases). Cursor tests moved to wall-clock timestamps.

### Batch E — AI proxy + tier (H9, H10, H11)  `[x]` built 2026-09-15, functions deploy + device check pending
1. H9: set the over-quota marker on **every** `resource-exhausted` throw (daily → midnight, follow-up → turn window, token budget, clip cap); apply `chatQuotaExhausted` for all `loopIndex` with a per-instance set of charged turnIds; for `loopIndex > 0` run the quota tx **before** dispatch. Extract `enforceRateLimit`/dispatch into a testable module; test asserts zero upstream fetches on hourly/daily/follow-up/clip/5-way-concurrent rejection.
2. H10: add `firebase_app_check`, activate in `FirebaseInitializer` (App Attest + DeviceCheck fallback in release, debug provider otherwise); send `X-Firebase-AppCheck` from `voice_reply_stream.dart` and `voice_tts_streaming.dart`; server `requireAppCheck` helper applied to `aiChat`, `aiChatStream`, `aiSpeech`, `aiSpeechStream` behind the one flag; reject `password` accounts without `email_verified`. Flag flip only after release-build adoption (RC).
3. H11 (ship free): remove/reword `PremiumStep` (no "Start Free Trial" without IAP); `TierLimits.fromJson` forces `enforced=false` until a paywall exists; `_recompute` uid guard; decision-log entry. RevenueCat integration is a separate post-launch PRD (design already logged 2026-07-20).
Deploy: functions; App Attest registration in Firebase console for the Elaris bundle.

**As built (2026-09-15):**
- H9: `functions/src/ai_quota_gate.ts` (pure, tested): `OverQuotaRegistry`, `ChargedTurnRegistry`, `gateBeforeDispatch`, `overQuotaUntilFor`, `verifiedAccountRejection`. `enforceRateLimit` now marks the uid over quota on EVERY rejection (hourly → window end, daily cap / token budget → midnight, follow-up cap → turn window) and records turns it charged; `aiChat` decides before dispatch: reject / fast path (first turn, or follow-up of a turn charged on this instance) / quota-first (follow-up of an unknown turn). Speech: clip-cap rejections mark `uid:turnId`; `aiSpeechStream` checks it before dispatch.
- H10: `firebase_app_check` added; `FirebaseInitializer` activates App Attest + DeviceCheck fallback in release (debug provider otherwise, best-effort, 4 s bound); `streamCoachReply` and `StreamingOpenAiTtsVoiceAdapter` send `x-firebase-appcheck` via `appCheckHeaderToken()` (injectable for tests). Server: `speech_shared.ts` exposes `appCheckHeaderOk` + `accountPolicyRejection`; `aiSpeech` checks `request.app`, `aiSpeechStream`/`aiChatStream` the header, all under the ONE `ai_enforce_app_check` key (also read by the speech RC template). New RC key `ai_require_verified_email` (default off) rejects unverified password accounts on all four endpoints when flipped.
- H11: `kPaywallAvailable = false`; `TierLimits.withLaunchLock()` applied to every remotely fetched value (parser stays faithful for gate tests); `ProEntitlementController._recompute` re-checks uid + session after the await; `setEntitled` inert until the paywall; `PremiumStep` reads "COMING SOON / Everything is free at launch / Continue / No purchase needed today".
- Tests: Functions 298 green (`ai_quota_gate.test.ts`); tier launch-lock test.
- Rollout: deploy functions; register App Attest for `com.elaristechnologies.sidepal` in the Firebase console and add the simulator debug token; ship the attested client; then flip `ai_enforce_app_check` (and, when announced, `ai_require_verified_email`) in Remote Config. Android needs Play Integrity with the pending Android migration.

### Batch F — Points/evidence honesty (H7, H8)  `[x]` built 2026-09-15, rules + functions deploy pending
1. H7: log the decision that earn sources are self-reported (already implicit in the 2026-07-16 entry); neutralise the consequential sink — photo removal (300) requires balance from `earn_challenge_win`/`signup_bonus`, or removal is disabled for launch. H2H stakes stay (symmetric self-report).
2. H8: rules gate `unitIndex <= (request.time − startAtMs) / unitMs` and `amount <= unitTarget × 2` (needs `startAtMs`/`unitMs`/`unitTarget` ints on the challenge doc); `outcome.evidenceSelfReported = true`; document that solo outcomes are self-attested, multi-party rely on dispute/vote. A `stakeAddEvidence` callable is the post-launch upgrade.
Deploy: rules (+ functions if the challenge doc gains fields at create).

**As built (2026-09-15):**
- H7: policy made explicit in `points.ts` / `ledger.ts` docs. New `trusted` counter on the balance doc, maintained by `writeLedgerTxn` via `trustedDelta` (signup bonus + challenge wins add; the removal spend subtracts; self-reported earnings and stake moves leave it alone). `stakeRemovePhoto` requires `trusted >= 300` on top of the balance check — 110 invented points/day can never unlock someone else's photo removal. Legacy balances start at trusted 0 (only wins/bonus after deploy count). The client still shows the removal action; the server's message names the trusted requirement (optimistic-then-honest).
- H8: rules `evidenceUnitWindowOk` (unit < totalUnits; unitIndex·1 day ≤ elapsed since `frozenGoal.startDateMs` + 1 day of grace; skipped for pre-startDateMs challenges) and `evidenceAmountOk` (amount ≤ 2 × unitTarget; recordedAtMs ≤ now + 5 min). `outcome.evidenceSelfReported: true` is written by the sweep on every decided record. A server evidence callable with session binding stays post-launch.
- Tests: Functions 303 green (`points.test.ts` trusted cases); rules 67 green (unit window, beyond-goal, amount, future timestamp).

### Batch G — Voice, observability, release surfaces (M8, M9, M10, M11)  `[x]` built 2026-09-15
1. M8: attach `play()` error handler before awaiting the latch; complete latch on `errorStream`; deadline = clip duration + slack; rethrow so the resilient wrapper falls back; player behind an interface + rejecting-fake test.
2. M9: `start()` captures a generation, `try/catch` + 8 s timeout around configure/initialize, re-checks after every await; caller `unawaited(...).catchError` and clears `voiceModeActive`; observe `inactive`/`hidden`; subscribe to `AudioSession.interruptionEventStream` → `pauseToIdle()`.
3. M10: `lib/core/telemetry/nonfatal.dart` `reportNonfatal(where, e, st)` — rate-limited, dedup by `where`, no payloads, guarded on `Firebase.apps.isNotEmpty`; route `swallowedAsyncError`, `syncFromRemote`, `_publishFresh`; `FirebaseInitializer.initialize()` returns `bool` and `main.dart` still `runApp`s Isar-only with retry on failure.
4. M11: tester mode becomes a server-assigned allowlist (`tester_allowlist/{uid}`, owner-read) — the 7-tap requests, doesn't grant; `crash()` and the Reminder Debug route compiled in only under `--dart-define=SIDEPAL_TESTER_BUILD=true` (TestFlight). Updates the 2026-09-12 entry.

**As built (2026-09-15):**
- M8: `_playClip` subscribes to `errorStream`, wires the `play()` rejection into the latch BEFORE waiting (`awaitClipPlayback`), and bounds playback (`playbackDeadlineFor`: 2× clip + 10 s, 90 s when unknown); failures propagate so `ResilientVoiceTtsAdapter` falls back. Pure helper tests.
- M9: `start()` returns `Future<bool>` and never throws; captures its own generation (a `pauseToIdle` mid-setup cancels the pending listen); configure/initialize bounded by `startupTimeout` (8 s); failure parks at idle with "Voice setup failed — tap the orb to try again"; `hidden` also pauses; `audioInterruptions` stream (audio_session `interruptionEventStream` via `voiceAudioInterruptions()`) pauses on begin; the screen calls `unawaited(start().then(...))` and clears `voiceModeActive` on failure. Four controller tests.
- M10: `lib/core/telemetry/nonfatal.dart` — `NonfatalReporter` (dedupe per site+type per 60 s, ≤20/session, sanitized `SanitizedNonfatal(where, type, code)` — messages never leave the device); wired into `swallowedAsyncError` (25 sites), the remote pull failure, permanent outbox drops, and the analytics refresh. `FirebaseInitializer.initialize()` returns bool; `main.dart` wires Crashlytics only when a Firebase app exists and otherwise boots local-only; `completeDeferred` retries Firebase init. Reporter tests.
- M11: `kTesterBuild` (`--dart-define=SIDEPAL_TESTER_BUILD=true`) compiles the crash trigger (VersionFooter `crashTriggerEnabled`) and the Reminder Debug route/row in; the App Store build omits them. Tester mode enable requires `tester_allowlist/{uid}` (rules: owner-read, write denied; `defaultTesterAllowlistCheck` passes without Firebase for VM tests); new outcome `notAllowlisted` with its snackbar. **Release process:** TestFlight-internal builds pass the define; the submission build must not (one binary cannot do both). Add each tester's uid as a doc in `tester_allowlist` in the console.

### Batch H — Release verification  `[~]` local checks done 2026-09-15; deploy + device checks are Miko's
Local (done on `fix/prelaunch-audit`):
- [x] `flutter analyze`: no errors; the remaining infos/warnings pre-date the branch.
- [x] Functions suite: 303 tests green. Rules suites: 68 Firestore + 10 Storage green.
- [x] Full Flutter suite: see the final run in the session summary (one pre-existing calendar-dependent failure in `siri_log_activity_test.dart`).

Deploy (one release, in this order):
1. `cd functions && npm run build && firebase deploy --only functions` — new callables (`circle*`, `stakeReservePhotoUpload`), triggers (`circleChallengeVoteTally`), purge/sweep changes, quota gate, App Check on speech.
2. `firebase deploy --only firestore:rules,firestore:indexes,storage` — membership = active, circleIds/entitlements carve-outs, LWW guard, evidence bounds, reactions, tester allowlist, `members.userId` collection-group index, reserved uploads.
3. Ship the client build from this branch (older clients' self-join/approve/leave/reaction writes are denied once rules deploy).
4. Remote Config: leave `ai_enforce_app_check` and `ai_require_verified_email` OFF; flip App Check only after the attested build is the installed base.
5. Console: register App Attest for `com.elaristechnologies.sidepal`; add the simulator debug token; add tester uids under `tester_allowlist/{uid}`; confirm the Apple provider has Services ID / Team ID / Key for token revocation.
6. Build flavours: internal TestFlight with `--dart-define=SIDEPAL_TESTER_BUILD=true`; App Store submission without it.

Device / emulator checks still open:
- [ ] Physical device: App Check token appears on the manual streams; Apple sign-in → delete → revoke completes; Crashlytics receives a nonfatal (any swallowed error) and the tester-build fatal; voice survives a phone-call interruption and a backgrounded start.
- [ ] Emulator: purge a seeded account and verify the inventory (`account_purges/{uid}` = done); delete one side of a funded h2h stake and confirm both `stake_release` rows.
- [ ] Two devices: offline delete + reconnect (no resurrection); cross-device delete converges; stale offline edit loses to a newer one.

---

## 3. Open decisions (need Miko's answer before the batch starts)

| # | Decision | Recommendation |
|---|---|---|
| D1 | H7/H8: honest self-report + neutralised sinks (Batch F) vs full server verification before launch | Honest path; server evidence callable post-launch |
| D2 | H11: ship free (remove PremiumStep trial CTA) vs build RevenueCat now | Ship free |
| D3 | H12 retention set | Keep `points_ledger`, `stake_escrows`, terminal stake events; delete everything else |
| D4 | H17: deletion = cancel-and-refund both sides vs deleted user forfeits | Cancel-and-refund |
| D5 | M11: tester allowlist + TestFlight-only crash trigger (overrides 2026-09-12 entry) | Yes |
| D6 | Session isolation depth for launch: Batch B only, or also per-UID Isar + guarded-write funnel | Batch B for launch; funnel post-launch |
| D7 | M12 waitlist: accept spam risk or move to rate-limited endpoint | Accept (log it) — no app code writes it |
| D8 | C1 client migration: full callables (recommended) vs rules-only tightening | Callables |
| D9 | Branch/base: new branch off `feat/home-light-redesign` (unmerged UI work) or off `main` | Off current branch, merge both to main together |
