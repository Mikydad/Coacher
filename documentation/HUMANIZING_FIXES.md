# Humanizing Fix Pass — what broke, why, and what we did about it

**Date:** 2026-07-24
**Source:** `Humanizing_audit.md` (two-pass audit of Humanizing Phases 0–7),
fix scope settled with Miko: every defect-class finding, plus a minimal
P1-05 learning loop and P1-07 dependency gating. Deferred as feature work,
not defects: P2-07 (person linking at capture), P2-08 (memory patterns in
planner weight w7), P2-09 (online enrichment / `phrase_nudge`), P3-02
(success-metric instrumentation).

**Verification (all green):** `flutter analyze` — 96 issues, identical to
the pre-fix baseline, zero errors; `flutter test` — 1,411 passing;
`npm --prefix functions test` — 204 passing; `rules-tests` `npm test` —
31 passing (21 stakes + 10 new user-tree).

Each entry below answers the same four questions: what was broken, how it
happened (root cause), why it mattered, and what changed.

---

## A. Account boundary

### P1-01 — Push registration survived logout

- **Broken:** logging out left the device's FCM token registered under the
  old uid (`users/{uid}/deviceTokens/...`), and the once-per-day heartbeat
  gate meant the next account's token registration could be delayed by up
  to a day.
- **Root cause:** `PushMessagingService` was written for the happy path —
  registration on init, heartbeat on resume. Logout lives in
  `AuthSessionPolicy`, a different module, and nothing connected the two.
  The heartbeat day-gate (`push_last_heartbeat_day_v1`) was keyed to the
  calendar day, not the account.
- **Why it mattered:** the previous user's account kept a live push route
  to a device they no longer own the session on — rescue pushes and
  morning briefs for account A could land on a phone now signed into
  account B.
- **What changed:** `deregisterDevice()` — a best-effort, ~3s-timeout,
  swallow-on-failure **direct** Firestore delete of the token doc, called
  from `clearLocalSession()`. This is deliberately not an outbox write:
  the outbox queue is itself wiped at logout, and a queued delete under a
  signed-out uid would be unsendable — the logout boundary is
  network-inherent, so the file is allowlisted in
  `local_first_guard_test.dart` with that reason. An auth listener in
  `initialize()` now re-runs `getToken()` + registration and resets the
  heartbeat gate whenever the uid changes, so the next account is
  reachable immediately.
- **Verified by:** rules test "owner can delete own deviceTokens doc";
  architecture guard still passes with the scoped allowlist entry.

### P1-02 — Logout did not disarm the native geofence

- **Broken:** armed home-exit intents, the saved home location, and the
  opt-in choice prefs all survived logout.
- **Root cause:** geofence state lives on the native side
  (`GeofenceSignal.swift`) plus device-local prefs — none of it is in
  Isar, so the Isar wipe in `clearLocalSession()` never touched it.
- **Why it mattered:** a new user on the same device inherits the previous
  user's home coordinates and could receive their promise nudges on
  leaving *their* home — a privacy hole, not just a bug.
- **What changed:** `GeofenceArmingService.clearForLogout()` (arms → `[]`,
  home cleared, choice/opt-in prefs reset — reusing the existing decline
  path), called from `clearLocalSession()`.
- **Verified by:** `geofence_arming_test.dart` clearForLogout case.

### P2-10a — Thinking Loop cadence prefs were not account-scoped

- **Broken:** `thinking_loop_last_day_v1` / `thinking_loop_inputs_hash_v1`
  survived account switches, so user B's first reflection could be
  suppressed by user A's "already reflected today" marker.
- **Root cause:** device-local SharedPreferences keyed by day only —
  the account dimension was missed when the cadence gate was added.
- **What changed:** both keys are removed in `clearLocalSession()`.

## B. Thinking Loop containment

### P1-08 (revised P2) — Reflection observations escaped the radar-only surface

- **Broken:** `InsightType.reflectionObservation` rows flowed through the
  general Layer-3 delivery loader into Home/Progress coaching-focus
  surfaces. (Second-pass validation showed they could NOT become OS
  notifications — `InsightPriority.low` never passes the notification
  gate — hence the severity downgrade.)
- **Root cause:** the observation was deliberately routed through the
  standard Layer-3 policy for dedupe/cooldown machinery, but the shared
  delivery loader had no concept of "radar-only" — every insight type it
  knew was implicitly a delivery-surface insight.
- **Why it mattered:** the settled design ("no reminders yet, just
  understanding", radar row as the one home for reflections) leaked: an
  AI-inferred observation could show up dressed as a deterministic
  coaching focus.
- **What changed:** one choke point — `isDeliverySurfaceEligible` filters
  reflection observations out of `loadLayer3DeliveryInsightsForDay`. The
  radar row reads `layer3EntityInsightsProvider('reflection')` directly
  and is unaffected.
- **Verified by:** `insight_generation_providers_test.dart` filter cases.

### P1-09 — Hint updates bypassed grounding-or-drop

- **Broken:** of the three reflection proposal types, `hintUpdates` was
  the only one whose `basedOn` provenance was not validated against the
  snapshot ids we actually sent the model.
- **Root cause:** an omission — dormant intentions and observations got
  the check; hints shipped without it and nothing failed loudly.
- **Why it mattered:** grounding-or-drop is the Thinking Loop's core
  safety contract ("the model may connect dots, but only OUR dots");
  a hallucinated hint would silently steer nudge timing.
- **What changed:** `ReflectionHintUpdate` carries `basedOn`; the parser
  validates it against `knownIds` and drops ungrounded hints, same as the
  other proposal types. `mergeHints` persists the provenance — which the
  P1-05 wrong-time contradiction loop now consumes.
- **Verified by:** `reflection_parser_test.dart` ungrounded-hint-drop case;
  `reflection_payload_test.dart` mergeHints provenance case.

### P2-10b — Stale-inputs hash missed person edits; empty snapshot burned the day

- **Broken:** editing a person did not change `reflectionInputsHash`, so
  reflection could skip a genuinely changed life; separately, an empty
  snapshot marked the day done, so data arriving later that day never got
  reflected on.
- **What changed:** `person.updatedAtMs` joined the hash; an empty
  snapshot now returns *without* marking the day (the extraction
  service's stay-pending pattern).
- **Verified by:** `reflection_payload_test.dart` hash-sensitivity case.

### P2-11 — No in-flight guard on `reflectIfDue()`

- **Broken:** bootstrap + resume could race two concurrent reflections —
  two AI calls, double proposals.
- **What changed:** a `Future<void>? _inFlight` latch; concurrent callers
  await the running pass.

## C. Notification correctness

### P1-06 — Daily nudge caps were absent

- **Broken:** nothing bounded how many intention nudges could land in one
  day — N promises × 3-slot ladders could legally deliver a dozen pushes.
- **Root cause:** the per-intention ladder had a budget (2–3 slots), but
  no cross-intention, per-day politeness ceiling was ever specified in
  code — the audit surfaced it as a design gap.
- **Why it mattered:** politeness is the product's core promise; a heavy
  week of promises turning into notification spam is exactly the failure
  mode SidePal exists to avoid.
- **What changed:** cap values settled with Miko: **2 nudges per intention
  per day, 4 intention nudges per day globally.** A pure policy
  (`intention_nudge_cap_policy.dart`, `applyIntentionDailyCaps`) walks the
  proposed ladder against per-day counts seeded from the ledger
  (`getDeliveryClaimsByKindInRange` — scheduled + delivered rows count;
  the intention's own *pending* rows don't, because they are the ladder's
  previous incarnation about to be replaced). Enforced in
  `_cappedLadder()` before slot evaluation; fails open on ledger errors
  (caps are politeness, not correctness).
- **Verified by:** `intention_nudge_cap_policy_test.dart` (per-intention
  cap, global cap, existing-claim seeding);
  `notification_ledger_repository_test.dart` day-range query case.

### P2-01 — Feedback landed on the wrong ledger row (and reschedules silently failed)

- **Broken:** interaction feedback (`onInteractionReceived`) looked rows
  up by entityId, so with multi-slot ladders the feedback could land on a
  different slot's row than the one tapped. Investigating this exposed a
  worse defect: rescheduling wrote a *new* ledger row with the same
  `notifId`, violating the unique index — the write silently failed and
  the ledger kept stale state.
- **Root cause:** the ledger was designed around one-row-per-notification
  but `upsertEntry` was called with fresh Isar objects on reschedule;
  the unique-index violation surfaced as a swallowed exception, not a
  crash.
- **What changed:** `_executeDecision` reuses the existing row by
  `notifId` (preserving `deliveredAtMs`, `snoozeCount`, `ignoredCount` —
  the behavioral memory); `onInteractionReceived` accepts `notifId` and
  the response handler threads `response.id` through, so feedback lands
  on the exact tapped slot.
- **Verified by:** orchestrator/ledger tests in
  `test/features/reminders/` + `test/core/notifications/`.

### P2-12 — Notification budget failed open

- **Broken:** if the pending-queue read threw, `canSchedule()` answered
  "yes", risking scheduling into a full 64-slot iOS queue where the OS
  silently drops the newest notifications.
- **What changed:** fail closed — on a plugin error the answer is "no".
  Missing one nudge is recoverable; invisibly losing the queue tail is
  not.
- **Verified by:** `notification_budget_test.dart` fail-closed case.

### V-01 — The Layer-4 insight push bypassed the orchestrator

- **Broken:** Home's "coach insight ready" bridge scheduled directly via
  `flutter_local_notifications` with its own private budget — no
  politeness policy, no ledger row, invisible to the caps.
- **Root cause:** the bridge predates the orchestrator's single-brain
  design (likely pre-Humanizing) and was never migrated.
- **What changed:** `ReminderEntityKinds.coachInsight` + a route-resolver
  case (fixed id `kCoachingInsightNotificationId`, payload
  `layer4:<insightId>` — tap routing unchanged); the bridge now builds a
  `ReminderIntent` and calls `orchestrator.evaluate()`. It keeps its
  3/day + 4h producer-side budget and *gains* politeness + ledger memory.
- **Verified by:** `notification_route_resolver_test.dart` coachInsight
  case.

### P2-04 — Geofence treated `whenInUse` as live

- **Broken:** `isLive()` accepted `whenInUse` authorization, but iOS only
  delivers region-exit events to backgrounded/killed apps with `always` —
  the feature looked armed and never fired.
- **What changed:** `isLive()`/`enable()` require `always`; the opt-in
  flow copy tells the user the truth about the degraded state and what to
  grant.
- **Verified by:** `geofence_arming_test.dart` authorization cases.

### P2-05 — Native geofence notification taps routed nowhere

- **Broken:** the Swift-side exit notification carried no payload, so a
  tap opened the app cold — no intention detail, no actions.
- **What changed:** `GeofenceSignal.swift` sets
  `userInfo["payload"] = "intention:<id>"` (the key
  flutter_local_notifications surfaces as `response.payload`) and the
  intention category id, so the existing routing and action handlers work
  unchanged. **Device verification still pending** — simulator can't
  exercise real region exits.

### P2-06 — One home exit fired every armed intention

- **Broken:** `fireArmedIntents` looped over the whole armed list — three
  armed promises meant three simultaneous notifications on stepping out.
- **What changed:** one exit fires the single best candidate (soonest
  deadline). The others keep their time-based ladders — the correctness
  floor.

## D. Session-end extraction (P1-04)

- **Broken:** memory extraction ran only on a 30-minute idle timer
  *inside* the Coach session — the normal chat-then-close-the-sheet flow
  never hit the documented "conversation boundary", raw turns piled up
  and raced the purge ceilings.
- **Root cause:** the extraction design named "conversation end" as its
  trigger, but nothing in the UI layer ever *declared* a conversation
  end; the idle timer was a stand-in that only worked if the sheet stayed
  open.
- **What changed:** closing the Coach sheet IS the boundary —
  `showCoachAiSheet(...).whenComplete` calls `startNewSession()` on the
  resolved service (extraction fires, session id rotates; each sheet
  open is a fresh conversation). Long-lived processes get a throttled
  `runMaintenance()` on app resume (once per ~6h) so purge ceilings are
  enforced even if the app never restarts.
- **Verified by:** existing extraction-service tests; sheet-close path is
  a thin provider read (resolved-or-skip, null-safe when the sheet closes
  before AI boots).

## E. Minimal learning loop (P1-05)

- **Broken:** the PRD's confirm-at-delivery loop had storage
  (`nudgeCount`, `snoozeCount`, `IntentionStatus.nudged`, `aiHintsJson`)
  but no behavior: notification responses didn't transition status, and
  "Wrong time" taught the planner nothing.
- **Root cause:** the fields shipped with the Phase 1 schema; the loop
  that would write them was scheduled for "later" and later never came.
- **Why it mattered:** without a learning loop, SidePal keeps making the
  same timing mistake forever — the opposite of the humanizing brief.
- **What changed (minimal semantics, settled with Miko):**
  - Any intention response on an `open` intention first records
    `nudged` — the nudge demonstrably reached the user.
  - `nudged` is **live**: a new `Intention.isLive` getter
    (`open || nudged`) backs `isPlannable` and every live surface
    (planner, Promises strip, Coach payload, geofence), so the status
    change is observational, never behavioral. The server mirrors this:
    the rescue sweep and morning-brief promise count treat `nudged` as
    live too.
  - **Done** → `updateStatus(done, bumpNudgeCount: true)`.
    **Later** → existing snooze + nudge-count bump.
    **Wrong time** → `applyWrongTimeStrike` (pure helper): increments
    `wrongTimeStrikes` in `aiHintsJson`; at 2 strikes removes
    `preferredTimeBlock` and registers a contradiction on any `basedOn`
    fact ids — the hint's provenance (P1-09) feeding memory's
    contradiction machinery. Then the existing replan.
- **Verified by:** `intention_learning_loop_test.dart` (isLive semantics
  + strike accounting); functions test "nudged intentions stay live and
  keep the safety net".

## F. Server crons + rules

### P1-03 — Global batch limits could permanently starve users

- **Broken:** `intentionSweep` read `.limit(200)` closing intentions and
  `morningBrief` read `.limit(500)` opted-in devices — with **no cursor**.
  Once the population crossed the limit, everything past it was invisible
  on *every* run, forever, silently.
- **Root cause:** the limits were written as safety bounds for a small
  early user base; without `orderBy` + `startAfter` they became a hard
  population cap rather than a page size.
- **Why it mattered:** the rescue net and the brief are the "alive while
  closed" promises — failing them silently and permanently for user 201+
  is the worst kind of failure: invisible in tests, invisible in logs.
- **What changed:** cursor pagination on both crons — sweep:
  `orderBy(windowEndMs) + startAfter(lastDoc)`, 10 pages × 200/run;
  brief: `orderBy(documentId()) + startAfter(lastDoc)`, 6 pages × 500/run
  (device docs collected across pages *before* grouping by user, so a
  user straddling a page boundary is still seen whole). Anything beyond
  a run's page bound is picked up by the next 15-minute run — the
  day-key/window bookkeeping makes re-visits idempotent. Index note:
  both queries are served by the existing declared fieldOverrides
  (single-field collection-group indexes carry `__name__` as tiebreaker);
  no composite needed.

### P2-02 — Transient push failures were recorded as successful sends

- **Broken:** `sendToTokens` returned only the pruned-token count; callers
  stamped `rescueState`/`briefState` ("already rescued/briefed") whether
  or not any message reached FCM. A transient FCM outage consumed the
  user's one polite rescue for that window.
- **Root cause:** the return value was designed around token hygiene
  (pruning), and the success dimension was simply never plumbed.
- **What changed:** `sendToTokens` returns `{delivered, pruned}` (with
  injectable `send`/`removeToken` test seams); both crons stamp their
  state **only when `delivered > 0`**, so transient failures retry on the
  next run while the window/polite-hours gates still apply. New
  `sendFailures` counter in both crons' logs.
- **Verified by:** `push_send.test.ts` — delivered counting, dead-token
  pruning without delivery credit, transient-failure → `delivered: 0`,
  empty token list.

### P2-03 — Clients could overwrite server-owned rescue/brief state

- **Broken:** the `users/{uid}` recursive wildcard granted the owner
  write access to *everything* under their doc — including
  `rescueState`/`briefState`, the bookkeeping that exists precisely so
  client writes can't clobber it. A buggy client (or a user with a
  console) could clear "already rescued today" and re-trigger pushes, or
  forge it and suppress them.
- **Root cause:** overlapping `allow` statements in Firestore rules are
  OR'd — adding a `write: if false` match for the two collections would
  NOT have revoked what the wildcard already granted. The exclusion has
  to live *inside* the wildcard's own condition, which is easy to miss.
- **What changed:** the users block is restructured:
  `match /{collection}/{document=**}` allows the owner only when
  `!(collection in ['rescueState', 'briefState'])`, plus explicit
  owner-read-only matches for the two carved-out trees.
- **Verified by:** new `rules-tests/user_tree.rules.test.js` (10 tests):
  owner keeps full access to normal + deeply nested subcollections and
  deviceTokens deletes (the P1-01 logout path); rescue/brief state is
  owner-readable but not writable/deletable; strangers and guests denied
  everywhere. Note for future rules tests: each test file needs its own
  emulator project id — `node --test` runs files in parallel against one
  emulator and `clearFirestore()` is project-scoped, so sharing an id
  lets one suite wipe another's seed mid-test (this bit us during
  verification).

## G. Dependency gating + honesty polish

### P1-07 — Dependency fields were stored but never affected planning

- **Broken:** `dependsOnText` ("before visiting parents") and
  `anchorEntityId` were captured and synced but every planner treated a
  dependency-gated intention as freely nudgeable — "I'll do X after Y"
  got nudged before Y.
- **Root cause:** the fields were carried in the Phase 1 schema for a
  later phase ("dormant until resolvable" per the model docs), and the
  gating logic was never scheduled.
- **What changed:**
  - `Intention.hasUnresolvedDependency` (either field non-blank) and
    `isNudgeable` (`isPlannable && !hasUnresolvedDependency`).
  - The nudge sync gates on `isNudgeable` — a gated promise behaves
    dormant: radar-visible, zero notifications. Geofence arming filters
    on it too (a home-exit fire is a nudge).
  - **Auto-promotion:** `IntentionsRepository.updateStatus(done)` finds
    live intentions anchored on the completed one and clears their
    dependency (`copyWith(clearDependency: true)`, re-stamped +
    replicated like any edit). The next replan pass (recompute graph /
    app resume, ≤5 min) picks them up. Free-text-only dependencies have
    no resolvable anchor and stay gated until the user edits them —
    that's the "standing understanding" contract, not a bug.
- **Verified by:** `intention_dependency_gating_test.dart` (gating
  getters, plannable-but-silent, promotion primitive).

### P2-13 — Coach failures were not network-honest

- **Broken:** offline, the Coach said "Something went wrong processing
  your request. Please try again." — blaming the request for a missing
  connection, against the optimistic-then-honest principle.
- **What changed:** `AiProxyException.isNetwork` (Cloud Functions
  `unavailable`/`deadline-exceeded` codes, plus
  `SocketException`/`TimeoutException`/`HttpException` in the generic
  catch), mirrored onto `AiOperatingLayerException`, and
  `ai_intent_parser.dart` shows "You're offline — I need a connection for
  this. Ask me again once you're back online." when the tag is set.

### P3-01 — Only the first memory citation got a chip

- **Broken:** a reply grounded in several `[mem:…]` facts rendered one
  chip (`factIds.first`) — the provenance-honesty contract says the user
  sees WHY the Coach knows *each* thing.
- **What changed:** `AssistantMessageBubble` renders one
  `MemoryReferenceChip` per distinct fact id in a `Wrap`.

---

## Deferred (feature work, tracked in the audit — not defects)

- **P2-07** — person linking at intention capture (`_createIntention` has
  no person parameter; the memory path already resolves `personName`).
- **P2-08** — learned memory patterns feeding planner weight w7.
- **P2-09** — online intention enrichment / `phrase_nudge` purpose.
- **P3-02** — Humanizing success-metric instrumentation.
- **P2-05 device pass** — real-device verification of the native
  geofence tap payload (simulator cannot exercise region exits).
