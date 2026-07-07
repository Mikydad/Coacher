# Audit Fix Plan — executable spec for AUDIT.md §7 (written 2026-07-06)

This document is a **self-contained implementation spec** for the findings in
`AUDIT.md §7`. It was written by a session that had the full investigation in
context, so an executor session does NOT need to re-audit — every fix lists
the exact files, the change, the verification, and the traps. Work top to
bottom; each numbered fix is one commit.

**Global rules for the executor:**
- Run `flutter analyze` (baseline: 105 issues, 0 errors) and `flutter test`
  (baseline: 1000 passing) after each fix. Do not accept new analyzer issues.
- Deploy commands are listed per fix; rules and indexes deploy together:
  `firebase deploy --only firestore --project coach4life-afaaa`.
- NEVER re-add `.orderBy(...)` to a Firestore query that also has `.where(...)`
  equality filters unless you also add the composite index to
  `firestore.indexes.json` in the same commit (see AUDIT.md §7 / errors.md #16/#18).
- The tests in `test/` use fakes with `noSuchMethod`; when you add methods to
  an abstract repo interface, add explicit no-op overrides to affected fakes
  (returning `null` via noSuchMethod breaks `Future<void>` awaits).

---

## Fix 1 (S1 — HIGH): lock down `weeklyCommitments` writes

**File:** `firestore.rules` (~line 127).

**Replace:**
```
      // ── Weekly commitments ────────────────────────────────────────────────
      match /weeklyCommitments/{commitmentId} {
        allow read, write: if canAccessCircleContent(circleId);
      }
```
**With:**
```
      // ── Weekly commitments ────────────────────────────────────────────────
      // Docs carry userId + weekKey (see WeeklyCommitment.toMap). Only the
      // owner may create/delete; updates are owner-only too EXCEPT that the
      // owner's own progress taps go through markProgress (completedCount +
      // updatedAtMs only). Reads stay circle-wide.
      match /weeklyCommitments/{commitmentId} {
        allow read: if canAccessCircleContent(circleId);
        allow create: if isCircleMember(circleId)
          && request.resource.data.userId == request.auth.uid;
        allow update: if isCircleMember(circleId)
          && resource.data.userId == request.auth.uid
          && request.resource.data.userId == resource.data.userId;
        allow delete: if isCircleMember(circleId)
          && resource.data.userId == request.auth.uid;
      }
```

**Client compatibility check (no code change expected):**
- `lib/features/community/data/weekly_commitment_repository.dart`
  `setCommitments` batch-deletes the CURRENT user's docs then writes docs with
  `userId = current uid` → passes.
  `markProgress` transaction updates `completedCount`/`updatedAtMs` on a doc —
  **verify who calls it**: `weekly_commitments_view.dart:77` calls it on `c.id`
  from the "mine" list only. If you find any call site passing another user's
  commitment, STOP and report instead of loosening the rule.

**Verify:** deploy, then in-app: create commitments, mark progress on your own
(works), and confirm the Rules Playground denies an update where
`resource.data.userId != request.auth.uid`.

---

## Fix 2 (S2 — HIGH): stop anonymous OpenAI cost abuse

**File:** `functions/src/index.ts`.

**Change A — reject anonymous accounts in `aiChat`** (insert right after the
`if (!request.auth)` block, ~line 204):
```ts
    // Guest (anonymous) accounts cannot call the paid AI proxy — creating
    // fresh anonymous uids is free, so per-uid quotas don't bound spend.
    const signInProvider = request.auth.token?.firebase?.sign_in_provider;
    if (signInProvider === "anonymous") {
      throw new HttpsError(
        "permission-denied",
        "Sign in with an account to use Coach AI.",
      );
    }
```
TypeScript note: `request.auth.token` is typed `DecodedIdToken`; access via
`(request.auth.token as Record<string, any>).firebase?.sign_in_provider` if
the compiler complains.

**Change B — client-side gating** so guests get a friendly nudge instead of an
error bubble:
- File: `lib/features/ai_assistant/application/ai_assistant_service.dart`,
  top of `sendMessage` (after the empty-input guard):
```dart
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.user,
        content: userInput.trim(),
        timestamp: DateTime.now(),
      ));
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content:
            'Coach AI needs a registered account. Create a free account in '
            'Profile → Sign in and your data comes with you.',
        timestamp: DateTime.now(),
      ));
      notifyListeners();
      return;
    }
```
  Import `package:firebase_auth/firebase_auth.dart`. **Trap:** VM tests
  construct `AiAssistantService` without Firebase — guard with
  `Firebase.apps.isNotEmpty` before touching `FirebaseAuth.instance`, i.e.
  `final user = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;`
  (import `package:firebase_core/firebase_core.dart`). Existing tests must
  stay green.

**Change C — App Check (config, not code):** enable App Check in the Firebase
console for the iOS app (App Attest / DeviceCheck), then set
`enforceAppCheck: true` in the `onCall` options once the app ships a version
that attests. Do NOT enforce before the client is updated — it bricks AI chat.
This step can land as console-only + a TODO comment in `index.ts`.

**Deploy:** `cd functions && npm run build && firebase deploy --only functions --project coach4life-afaaa`.

**Verify:** `flutter test test/features/ai_assistant/` all green; in-app as a
guest → nudge message, as registered → normal flow.

---

## Fix 3 (H1 — trivial): gitignore build artifacts

**File:** `.gitignore` — add two lines:
```
ios/build/
/package-lock.json
```
Then `git rm --cached -r` is NOT needed (both are untracked). Delete the stray
root `package-lock.json` file.

---

## Fix 4 (S6 + R7): reactions rule + AI pulse write rule

**File:** `firestore.rules` messages block. Replace the `allow update` rule:
```
        // Sender edits their own message; ANY member may toggle reactions —
        // but a reactions-only update may touch nothing but `reactions`.
        allow update: if isCircleMember(circleId)
          && (
            (resource.data.senderId == request.auth.uid
              && request.resource.data.senderId == resource.data.senderId)
            || request.resource.data.diff(resource.data)
                 .affectedKeys().hasOnly(['reactions'])
          );
```
This unbreaks reacting to other members' messages (currently
permission-denied) while keeping message bodies sender-only. Rules cannot
cheaply validate "only your own uid added/removed" inside the map — accepted
residual risk, note it in the rule comment.

**AI pulse (R7):** in the `aiPulse` block change
`allow write: if isCircleModerator(circleId);` →
`allow write: if isCircleMember(circleId);`
Rationale: `CircleAiPulseService` (client-side, `circle_ai_pulse_service.dart`)
generates pulses from ANY member's device; the moderator-only rule silently
breaks the banner for everyone else. Pulses are non-sensitive coaching text
scoped to the circle.

**Verify:** react to another member's message on a second account (or Rules
Playground: update changing only `reactions` as non-sender → allow; update
changing `content` as non-sender → deny).

---

## Fix 5 (S3 + S5): challenge updates + proof upload namespacing

**A — `firestore.rules` challenges block**, replace `allow update`:
```
        // Creator or moderator may edit challenge metadata. (Progress lives
        // in votes/ and challenge_proofs storage, not on this doc.)
        allow update: if isCircleMember(circleId)
          && (resource.data.creatorId == request.auth.uid
              || isCircleModerator(circleId));
```
**Client check first:** grep `lib/features/community` for `.update(` /
`upsert` calls on the challenges collection from non-creator flows (e.g.
status auto-transitions when voting). If any non-creator write path exists,
whitelist just those fields with an `affectedKeys().hasOnly([...])` OR-branch
instead of blocking — report what you found in the commit message.

**B — `storage.rules` chat proofs**, make uploads uid-prefixed AND create-only:
```
    // Circle chat proof images — uid-prefixed (spoof/overwrite-proof) and
    // immutable once written.
    match /circles/{circleId}/proofs/{fileName} {
      allow read: if isCircleMember(circleId);
      allow create: if isCircleMember(circleId)
        && isValidImageUpload()
        && fileName.matches(request.auth.uid + '_.*');
    }
```
**Client change required:** `lib/features/community/data/circle_proof_storage.dart`
`uploadChatProof` currently names files `${StableId.generate('proof')}.$ext`.
Change to `'${userId}_${StableId.generate('proof')}.$ext'` and add a
`required String userId` parameter; caller is `circle_chat_view.dart`
(`_pickAndSendImage`, has `user.uid` in scope).
**Trap:** existing proof images keep their old names — reads still work (read
rule unchanged); only NEW uploads need the prefix.
**Deploy:** `firebase deploy --only storage --project coach4life-afaaa`.

---

## Fix 6 (P1 — HIGH): incremental sync cursors

**Goal:** stop re-reading whole collections every pull.
**Files:** `lib/core/sync/remote_isar_merge.dart`, `lib/core/sync/sync_service.dart`.

Design (keep it this simple):
1. New prefs-backed cursor store (SharedPreferences), key per collection:
   `sync_cursor_v1_<collection>` → `int lastMaxUpdatedAtMs`.
2. In each `_pull*` method, change the Firestore query to
   `.where('updatedAtMs', isGreaterThan: cursor)` — **single-field range on
   `updatedAtMs` only, NO other where/orderBy** → no composite index needed.
   - routines/blocks/tasks: this replaces the *nested walk* — query the
     collection-group style per routine as today BUT skip a routine's
     blocks/tasks walk entirely when the routine itself AND its children are
     unchanged is NOT knowable → instead: keep the nested walk but add the
     cursor filter at each level (blocks and tasks subcollection queries get
     their own `.where('updatedAtMs', isGreaterThan: cursorTasks)` etc.).
     Cursors may be one shared value for simplicity.
   - analytics_events: THE big win — cursor mandatory here.
3. After a fully **successful** pull, advance the cursor to the max
   `updatedAtMs` seen (not `DateTime.now()` — client clocks differ).
4. Full-reconcile escape hatch: when `force == true` in
   `syncFromRemote(force: ...)` OR cursor key absent, pull with cursor 0.
   Account switch (`AuthSessionPolicy` wipe) must clear all cursor keys —
   hook where local data is wiped (grep `clearQueue()` call sites; the wipe
   path lives in AuthGate/auth session policy).
5. **Deletion caveat (accept + document):** cursor pulls cannot see remote
   deletions. Today's merge never deletes locally either (LWW upsert only),
   so behavior is unchanged. Note it in the class doc.

**Tests:** extend `test/core/sync/` — a fake/`fake_cloud_firestore` test that
(a) first pull reads all docs, (b) second pull with cursor reads only newer
docs, (c) force pull reads all again, (d) cursor advances to max updatedAtMs.

---

## Fix 7 (R2): the four async-context crashes

Add `if (!context.mounted) return;` (or capture messenger/navigator before the
await) at:
- `lib/features/add_task/presentation/add_task_screen.dart:1416` (guarded by
  wrong mounted check — use the ctx the lint names)
- `lib/features/focus/presentation/focus_selection_screen.dart:119`
- `lib/features/goals/presentation/goal_editor_screen.dart:695`
- `lib/features/home/presentation/home_screen.dart:2187`
Line numbers drift — locate by the `use_build_context_synchronously` entries
in `flutter analyze` output. Baseline drops from 105 → 101.

---

## Fix 8 (S7): silence debugPrint in release

**File:** `lib/main.dart`, first lines of `main()`:
```dart
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
```
Import `package:flutter/foundation.dart`. One test-visible trap: none —
`debugPrint` override is process-global but tests run in debug mode.

---

## Fix 9 (R1 — sweep, do LAST): stop swallowing errors silently

57 sites match `error: (_, _) =>`, `error: (_, __) =>`, or `catch (_) {}`.
Minimum bar for this pass (do NOT redesign UI):
- For `AsyncValue.when(error: ...)` handlers that ignore the error object:
  change to `error: (e, _) { debugPrint('<widget>: $e'); return <same UI>; }`.
- For `catch (_) {}`: add `debugPrint` with a stable prefix.
Skip test files. Mechanical, ~30 min. Keeps incident-#18-style failures
diagnosable from logs.

---

## Explicitly deferred (do not attempt in the Fable-high pass)
- P2 (check-in window cap), P3 (payload trimming by route) — need product
  decisions on windows.
- R5 (Firebase major upgrades) — its own branch + device test day.
- H3 (accessibility pass) — needs design input on type sizes/contrast.
- S4 (circle discovery privacy) — product decision, not a patch.

## Definition of done for the executor
- Each fix = one commit, message referencing the fix number and AUDIT §7 id.
- `flutter analyze` ≤ 105 issues (101 after Fix 7), 0 errors.
- `flutter test` — 1000+ passing, plus the new sync-cursor tests.
- Rules/functions/storage deploys run for Fixes 1, 2, 4, 5 and verified in
  Rules Playground as described.
- Update `AUDIT.md §7` table rows with `→ FIXED <commit>` annotations and add
  entries to `documentation/errors.md` ONLY if a fix uncovers a new incident.
