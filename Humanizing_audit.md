# Humanizing Implementation Audit

**Audit date:** 2026-07-24  
**Baseline:** `feat/humanizing-phase0` at `ff287fb`  
**Scope:** Humanizing Phases 0–7 against
`PRD/humanizing_feature/humanizing_implementation_PRD.md`, `CLAUDE.md`, and
the settled decisions in `documentation/GUIDELINES.md`.  
**Constraint:** Audit only. No implementation fixes were made.

## Executive assessment

The Humanizing implementation is broad and materially functional. The core
architecture is generally correct:

- intentions, memory facts, people, and scheduled time blocks use Isar-first
  writes, outbox replication, watch-based reads, and LWW pull merges;
- opportunity plans remain local-only derived data;
- ordinary intention nudges pass through `AttentionOrchestrator`;
- memory extraction enforces quote-backed provenance;
- Voice Mode reuses the Coach conversation path;
- calendar, activity, and location signals are deliberately coarse and
  device-local;
- server AI purposes and system quota routing exist;
- the Thinking Loop produces proposals rather than directly executing work.

The feature is **not ready to be called PRD-complete or production-ready**.
The highest-risk findings are cross-account push/geofence state, Phase 5
pagination starvation, delayed memory extraction, missing nudge-learning and
notification caps, ignored dependency semantics, and Thinking Loop proposals
escaping their intended trust and presentation boundaries.

No universal P0 defect was verified. There are multiple P1 defects that should
block a production declaration for the Humanizing roadmap.

## Severity

- **P0:** critical, universal release blocker or direct destructive failure.
- **P1:** urgent correctness, privacy, or core-product contract failure.
- **P2:** material defect or incomplete contract with a narrower scenario.
- **P3:** lower-impact gap, observability issue, or residual risk.

## Findings

### P1-01 — Push registration survives logout and is not re-scoped to the next account

`AuthSessionPolicy.clearLocalSession()` clears Isar, the outbox, cursors, and
ordinary local notifications, but it never deletes the current device-token
document from the outgoing user's Firestore tree
(`lib/features/auth/application/auth_session_policy.dart:65-92`).

`PushMessagingService` is a process singleton. It sets `_wired = true` before
registration and only writes the token during first initialization or an FCM
token refresh (`lib/core/push/push_messaging_service.dart:47-78`). It has no
Firebase Auth listener and no logout/account-switch cleanup. The Phase 5 sweep
later reads every token still stored under the old user
(`functions/src/intentions/sweep.ts:145-174`).

Concrete effects:

1. User A can log out while their still-valid installation token remains under
   `users/A/deviceTokens`. User A's rescue or morning-brief push can then appear
   on the device while User B is using it. Rescue copy can contain User A's
   intention title.
2. User B is not guaranteed to receive a token registration until the app
   process restarts or FCM rotates the token.
3. Bootstrap calls push initialization before `_awaitSignedInUser()`
   (`lib/core/bootstrap/app_bootstrap.dart:77-84,111-115`). A signed-out boot
   can therefore enqueue a token write under the fallback path
   (`lib/core/firebase/firestore_paths.dart:9-15`); after sign-in,
   `SyncService` drops that null/foreign-uid operation
   (`lib/core/sync/sync_service.dart:257-285`).
4. The once-per-day heartbeat preference can suppress a same-day retry after
   the account changes (`lib/core/push/push_messaging_service.dart:87-104`).

This is both a privacy defect and a delivery defect.

### P1-02 — Logout does not disarm the native home-exit geofence

Native cleanup exists: `clearHome()` removes the stored coordinates, removes
the armed-intention list, and stops the monitored region
(`ios/Runner/GeofenceSignal.swift:163-170`). The authentication cleanup path
never invokes it (`lib/features/auth/application/auth_session_policy.dart:65-92`).

The armed list contains prerendered user text and can fire independently of
Flutter when Core Location reports an exit
(`ios/Runner/GeofenceSignal.swift:208-248`). Therefore:

1. User A arms an intention.
2. User A logs out while still at home.
3. The app is backgrounded.
4. Leaving home can produce User A's intention notification after logout.

`LocalNotificationsService.cancelAll()` only cancels notification requests
that already exist; it does not stop `CLLocationManager` from creating a new
request after the next exit. A later replan may overwrite the native armed
list, but logout itself leaves a real exposure window, and a signed-out device
may never run that replan.

### P1-03 — Phase 5 global batch limits can permanently starve users

Both server crons query only one fixed page:

- rescue sweep: global `collectionGroup('intentions')`, limit 200
  (`functions/src/intentions/sweep.ts:56-61`);
- morning brief: global `collectionGroup('deviceTokens')`, limit 500
  (`functions/src/intentions/morning_brief.ts:38-42`).

Neither query paginates or advances a cursor. Processed documents remain
eligible because rescue/brief bookkeeping is stored in separate state
documents. Consequently:

- with 501 opted-in device documents, the same first 500 can be selected on
  every run and the tail device can be omitted indefinitely;
- with more than 200 closing intentions, covered, already-rescued, or otherwise
  skipped rows continue occupying the first page while later intentions can
  expire without being examined.

The 15-minute schedule does not rotate a stable Firestore result set. This is a
deterministic production-scale failure, not merely a throughput concern.

### P1-04 — Conversation extraction is not triggered when a Coach session ends

The intended lifecycle exists but is not wired:

- every turn marks the current session pending
  (`lib/features/ai_assistant/application/ai_assistant_service.dart:103-108`);
- `MemoryExtractionService.onSessionEnded()` is explicitly intended for Coach
  sheet close/session reset
  (`lib/features/memory/application/memory_extraction_service.dart:79-90`);
- the only caller is `AiAssistantService.startNewSession()`
  (`lib/features/ai_assistant/application/ai_assistant_service.dart:646-652`);
- `startNewSession()` has no production call site;
- `runMaintenance()` is invoked only during deferred cold bootstrap
  (`lib/core/bootstrap/app_bootstrap.dart:86-90`).

The non-auto-disposed Coach service therefore keeps one session across sheet
closures. Facts, people, dormant observations, and timeline summaries are not
extracted at the documented conversation boundary; they generally wait for a
later cold launch after the inactivity gate. If the process remains alive,
the 48-hour purge and seven-day raw-turn ceiling are not periodically enforced.

The previously suspected "new turns purged from an already-extracted live
session" is not currently reachable because maintenance only runs at cold
bootstrap, which creates a new service/session id. The primitives remain
fragile: `markPending()` refuses to reopen an `extracted` session
(`lib/features/memory/data/memory_session_state_repository.dart:24-27`) while
`purgeSessions()` deletes every row sharing the session id
(`lib/features/ai_assistant/data/ai_interaction_history_repository.dart:196-207`).

### P1-05 — The confirm-at-delivery learning loop is not implemented

The response handler claims that Done corroborates and Later/Wrong time decays
the signals used for timing
(`lib/app/notification_response_handler.dart:353-355`). Runtime actions only
change the intention status/snooze count and replan
(`lib/app/notification_intention_actions.dart:14-76`).

There is no delivery-response path that:

- raises or lowers `MemoryFact.confidence`;
- adjusts or removes `Intention.aiHintsJson`;
- records which hints influenced the selected slot;
- calls `MemoryFactsRepository.registerContradiction()`;
- increments `Intention.nudgeCount`;
- transitions an intention to `IntentionStatus.nudged`.

The relevant repository methods and fields exist, but searches show no runtime
callers for `registerContradiction`, `bumpNudgeCount`, or
`IntentionStatus.nudged` outside definitions/read-only payload code
(`lib/features/memory/data/memory_facts_repository.dart:90-101`;
`lib/features/intentions/data/intentions_repository.dart:67-85`).

This leaves a load-bearing PRD promise inert: SidePal does not learn whether
its inferred timing was good, and its "avoidance truth" is incomplete.

### P1-06 — Per-intention and global daily nudge caps are absent

The planner can emit primary, safety, and fallback slots
(`lib/features/intentions/application/opportunity_planner.dart:52-55,108-156`),
and the sync service schedules every retained slot
(`lib/features/intentions/application/intention_nudge_sync_service.dart:216-224,254-279`).

`NotificationBudget` protects only the total pending OS queue. There is no
Remote Config value or runtime policy enforcing:

- at most one opportunity nudge per intention per day;
- a global daily intention-nudge cap.

An ignored intention can therefore fire multiple ladder notifications in one
day, and several open intentions can produce a burst. This contradicts PRD
§4.4 and the settled "One. Perfect. Notification." policy.

### P1-07 — Dependency fields are stored but never affect planning

`dependsOnText` and `anchorEntityId` are modeled as "dormant until resolvable"
(`lib/features/intentions/domain/models/intention.dart:86-88`). In practice,
`isPlannable` checks only `active && status == open`
(`lib/features/intentions/domain/models/intention.dart:108-111`).

The capture draft cannot carry either field
(`lib/features/intentions/application/intention_capture.dart:7-27`), and
`OpportunityPlanner`/`IntentionNudgeSyncService` never resolve or suppress on
them. If such a record is imported or created later, it is scheduled like any
other open intention.

The worked example "buy flowers before visiting my parents" therefore does not
have the PRD's dependency behavior. The geofence can react to leaving home, but
the underlying anchor remains unused.

### P1-08 — Reflection observations escape the radar-only surface (severity revised to P2 in second-pass validation)

The settled Phase 7 decision places standing observations in the quiet
collapsed "On your radar" row, not the Coach panel, so they do not compete with
open promises.

`ThinkingLoopService` stores the observation as an ordinary entity-scoped
Layer-3 insight (`lib/features/thinking/application/thinking_loop_service.dart:239-267`).
The shared delivery loader then merges every active entity insight with no
`reflectionObservation` exclusion
(`lib/features/analytics/application/insight_generation_providers.dart:22-41`).

That merged list feeds coaching-focus selection
(`lib/features/analytics/application/focus_providers.dart:74-77,114-123`) and
the Home/Progress coaching surfaces. On a quiet day, a reflection can therefore
become the coaching focus card instead of remaining in the radar row — a
violation of the placement decision.

**Corrected in second-pass validation:** a reflection can NOT become the OS
"Coach Insight Ready" notification, contrary to this finding's original claim.
Reflection insights are emitted at `InsightPriority.low`
(`lib/features/analytics/application/insight_generation_policy.dart:330-342`)
and `passesNotificationGate()` rejects low priority unconditionally
(`lib/features/analytics/application/layer4_delivery_policy.dart:114-126`), so
`DeliveryDecision.shouldNotify` is always false when a reflection is the
selected primary, and Home's notification dispatch
(`lib/features/home/presentation/home_screen.dart:961-985`) is gated on that
flag. The no-notification promise for standing understanding holds; the
violation is in-app placement only, which is why the severity was revised from
P1 to P2.

### P1-09 — Thinking Loop hint updates bypass grounding-or-drop

The reflection prompt requires every proposal, including `hintUpdates`, to
carry valid `basedOn` ids
(`lib/features/thinking/application/thinking_loop_service.dart:306-329`).
The parser verifies grounding for dormant intentions and observations, but the
hint loop reads only `intentionId` and `preferredTimeBlock`
(`lib/features/thinking/application/reflection_parser.dart:97-115`).

An ungrounded model response can therefore alter
`Intention.aiHintsJson.preferredTimeBlock`, which then influences real planner
scoring. The deterministic planner still validates that a real free slot
exists, but the provenance/trust boundary "the model may connect only our
dots" is broken.

### P2-01 — Multi-slot notification feedback is written to the wrong ledger row

Intention slots receive distinct OS notification ids but share an entity-only
payload (`lib/features/reminders/application/notification_route_resolver.dart:59-69`).
The response contains `response.id`, yet the intention handler forwards only
the intention id (`lib/app/notification_response_handler.dart:353-410`).

`AttentionOrchestratorService.onInteractionReceived()` then calls
`findByEntityId()`, which returns the most recently updated row
(`lib/features/reminders/application/attention_orchestrator_service.dart:147-176`;
`lib/core/notifications/notification_ledger_repository.dart:87-94`).

Responding to slot 0 can therefore mark slot 1/2 as opened, snoozed, or
dismissed. An opened response can also cancel the wrong future sibling. The
intention's terminal status still targets the correct entity, but the timing
feedback and ledger history are corrupted.

### P2-02 — Transient push failures are recorded as successful sends

`sendToTokens()` swallows non-dead-token FCM errors and returns only a count of
pruned tokens (`functions/src/intentions/push_send.ts:22-46`). Its comment says
a later sweep will retry.

Both callers nevertheless write successful bookkeeping unconditionally:

- rescue state is stamped after `sendToTokens()`
  (`functions/src/intentions/sweep.ts:104-124`);
- morning brief increments `sent` and stamps `lastBriefDayKey`
  (`functions/src/intentions/morning_brief.ts:123-130`).

If the only token receives a transient `server-unavailable` response, the
notification was not sent but the rescue is suppressed for the rest of its
window and the brief for the rest of the day. Data pushes are suppressed for
six hours, which can exceed the remaining deadline window.

### P2-03 — Client rules can overwrite server-owned rescue state

The Phase 5 design calls `rescueState` and `briefState` server-owned. Current
rules grant a user read/write access to every subcollection below their user
document (`firestore.rules:57-67`).

A client, stale test build, or accidental outbox operation can overwrite:

- `users/{uid}/rescueState/{intentionId}`;
- `users/{uid}/briefState/morning`.

This can suppress or duplicate server sends by corrupting idempotency state.
It does not grant cross-user access, but it contradicts the server-authority
boundary.

### P2-04 — Geofence readiness treats `whenInUse` as sufficient

The native implementation states that dead-app region exits require Always
authorization and tries to escalate from When In Use
(`ios/Runner/GeofenceSignal.swift:65-77`). If that escalation remains
`whenInUse`, Dart still stores the feature as enabled and `isLive()` returns
true (`lib/features/intentions/application/geofence_arming.dart:101-122`).

The native armed list can therefore appear healthy while the headline
background/dead-app use case is unavailable. The time-based ladder remains a
fallback, but the location opt-in is not honest about its effective capability.

### P2-05 — Native geofence notification taps have no routing path

The native notification stores generic `userInfo`
`{"sidepal":"geofence","intentionId":...}` and has no plugin payload/category
(`ios/Runner/GeofenceSignal.swift:236-243`).

The Dart notification handler aborts when `response.payload` is empty
(`lib/app/notification_response_handler.dart:272-290`). Its id fallback knows
only task reminder ids and cannot resolve the native `geofence_{id}` identifier
(`lib/app/notification_response_handler.dart:607-641`).

The notification can open the application, but it has no explicit route to the
promise, Coach, or Home's Promises strip and records no interaction.

### P2-06 — One home exit can fire every armed intention

`fireArmedIntents()` loops over the full armed list and immediately presents
every intention whose window and polite-hour checks pass
(`ios/Runner/GeofenceSignal.swift:219-248`).

Three opted-in errands can therefore produce three notifications on one exit.
The native path is intentionally allowed to bypass the Dart orchestrator, but
the resulting multi-fire behavior still conflicts with the quiet-notification
policy.

### P2-07 — Intentions are not linked to known people during capture

`Intention.personId` exists, but:

- `IntentionDraft` has no `personId`
  (`lib/features/intentions/application/intention_capture.dart:7-27`);
- the AI prompt does not request `personName` for `createIntention`
  (`lib/features/ai_assistant/application/ai_operating_layer_client.dart:118-127`);
- `_createIntention()` does not resolve a person
  (`lib/features/ai_assistant/application/ai_action_executor.dart:662-703`).

"Call cousin Sara" therefore remains title text instead of a first-class
relationship link. Relationship care compensates by matching names/aliases
inside completed intention titles, but the PRD's person-linked intention model
and success metric are not implemented.

### P2-08 — Learned memory patterns do not participate in planner weight w7

`MemoryFact.structuredJson` is documented as the machine shape read by the
planner (`lib/features/memory/domain/models/memory_fact.dart:85-87`).
`OpportunityPlanner` reads only `Intention.aiHintsJson`
(`lib/features/intentions/application/opportunity_planner.dart:169-217,253-267`).

A quote-verified or inferred memory such as
`{"preferredTimeBlock":"morning"}` never affects timing unless another path
duplicates it onto the intention. This leaves the memory-to-opportunity bridge
incomplete.

### P2-09 — Online intention enrichment and `phrase_nudge` are unused

Server routes exist for `parse_intention` and `phrase_nudge`
(`functions/src/ai_routing.ts:44-53`), but there are no client call sites for
either purpose.

Consequences:

- online nudge text is always the deterministic template
  (`lib/features/intentions/application/opportunity_planner.dart:293-324`);
- an offline/quick-add intention is never background-refined by filling only
  fields the user left empty;
- the promised `(intentionId, windowHash)` phrasing cache does not exist.

The deterministic path is the correct offline floor. The missing part is the
specified online enrichment, not delivery correctness.

### P2-10 — Thinking Loop cadence state is not account-scoped and can suppress fresh data

The day and input-hash SharedPreferences keys are global to the installation
(`lib/features/thinking/application/thinking_loop_service.dart:75-76`), and
`AuthSessionPolicy.clearLocalSession()` does not clear them.

User A running reflection can therefore make User B skip reflection for the
rest of that local day after an account switch. In addition, an empty initial
Isar snapshot marks the day complete
(`lib/features/thinking/application/thinking_loop_service.dart:93-101`).
If onboarding, capture, or remote merge adds facts/people/intentions later that
day, the new inputs are ignored until the next day.

The people portion of the durable hash uses only `lastInteractionAtMs`, not
`updatedAtMs` (`lib/features/thinking/application/reflection_payload.dart:108-123`).
Editing a person's name or relationship may therefore never re-arm reflection
until a separate interaction occurs.

### P2-11 — Thinking Loop has no in-flight guard

Reflection is launched unawaited from both bootstrap
(`lib/core/bootstrap/app_bootstrap.dart:92-95`) and app resume
(`lib/app/app_lifecycle_task_refresh.dart:118-123`).

`reflectIfDue()` has no mutex/in-flight future. Two overlapping calls can both
pass the day/hash checks before either writes preferences, consume two system
AI calls, and apply duplicate dormant proposals with different client ids.

### P2-12 — Notification budget fails open

When the plugin cannot return pending requests, `NotificationBudget` logs the
error and returns `true`
(`lib/core/notifications/notification_budget.dart:32-41`).

That failure mode recreates the exact condition the service is meant to avoid:
new schedules continue even though the app cannot establish headroom under
iOS's 64-pending limit. The platform-cap constant itself is intentionally
compile-time per the decision log; the issue is failure behavior, not Remote
Config.

### P2-13 — Network-inherent Coach failures are not network-honest

The offline intention heuristic is implemented correctly. For general Coach
requests, `AiIntentParser` collapses non-rate-limit proxy failures into
"Something went wrong" or "unexpected issue"
(`lib/features/ai_assistant/application/ai_intent_parser.dart:130-143`).

In airplane mode, the user is not told that the requested AI conversation
requires a connection, despite the settled optimistic-then-honest contract.

### P3-01 — Multiple memory citations expose only the first fact

The grounding renderer can parse multiple mem ids, but the chat chip routes
only `factIds.first` (`lib/features/ai_assistant/presentation/widgets/chat_bubbles.dart:50-74`).
A response grounded in several memories exposes only one editable source.

### P3-02 — Humanizing success metrics are mostly not instrumented

Server per-purpose AI usage exists, but no complete client instrumentation was
found for the PRD §15 measures: wrong-time rate, inferred-memory
correction/deletion rate, Voice Mode sessions, Siri cold-start success,
phrase-cache hit rate, and notification-permission revocations.

This does not break runtime behavior, but it prevents validating the product's
own trust and quality thresholds after release.

## Phase status

| Phase | Status | Audit conclusion |
|---|---|---|
| 0 — Notification bedrock | Partial | Categories, routing, reconciliation, and queue budget exist. Daily caps and slot-accurate feedback do not. |
| 1 — Intentions | Partial | Full sync set, offline capture, deterministic planner, slot ladder, Promises strip, and seize-the-moment exist. Dependencies and the feedback-learning loop do not. |
| 2 — Memory & People | Partial | Sync sets, provenance, quote verification, memory UI, grounding markers, and relationship care exist. Session-end extraction, contradiction/response learning, person-linked intentions, and memory-driven planner hints are incomplete. |
| 3 — Voice L2 | Mostly implemented | Composer-state loop, shared send path, sentence TTS, interruption, and silence handling are present and unit-tested. Real STT/TTS remains device-only verification. |
| 4 — Siri + calendar | Mostly implemented | Runner AppIntent, cold/warm pending intent, nullable ContextSnapshot, coarse EventKit bridge, and JIT calendar UX match the decisions. Signed-device Siri and EventKit flows are unverified. |
| 5 — Alive while closed | Not production-ready | Projection and pure rules are present, but auth scoping, pagination, transient-send state, rules ownership, deployment, and production APNs verification remain. |
| 6 — Rich context | Partial | Activity snapshots and privacy boundaries are sound. Geofence account cleanup, authorization honesty, tap routing, and one-exit notification behavior are incomplete. |
| 7 — Thinking Loop | Partial | Reflection payload/parser, proposal caps, dormant writes, and radar actions exist. Hint grounding, radar-only placement, account/cadence state, and concurrency are incomplete. |

## Verified implementation strengths

1. **Local-first entity sets are complete.** Intentions, memory facts, people,
   and scheduled time blocks are registered in Isar, written locally before
   outbox replication, exposed through watch streams, and pulled through
   `RemoteIsarMerge` with LWW semantics.
2. **Derived plans stay local.** `IsarOpportunityPlan` does not enter the
   bidirectional sync set; Phase 5 writes a separate coarse projection only.
3. **Core capture works offline.** Clear intention phrases use the heuristic
   parser; ambiguous offline input falls back to the quick-add sheet; both use
   the same local executor and undo batch path.
4. **Planner delivery is deterministic.** Slot scoring has no clock read, I/O,
   or live LLM call, and ordinary slots go through `AttentionOrchestrator`.
5. **Memory provenance has real enforcement.** Claimed `userStated` facts and
   people are quote-checked; invalid claims are demoted to `aiInferred`.
   Unknown stored provenance also degrades to the weakest class.
6. **Memory is inspectable.** Facts, People, and Timeline ship together, with
   provenance badges, correction/edit/forget actions, and soft tombstones.
7. **Voice preserves one surface.** Voice Mode is a Coach composer state and
   sends through the same `sendMessage` path as typed input.
8. **Context privacy is constrained by data shape.** Calendar exposes busy
   intervals only, activity exposes coarse kind/confidence, and geofence
   coordinates remain in native device storage.
9. **Server AI routing is separated by purpose.** System purposes use a
   separate daily budget and model allow-list; pure routing tests pass.
10. **Thinking Loop writes remain proposals.** Dormant intentions do not
    schedule until promoted, and radar promotion/dismissal uses local-first
    repository paths.

## Verification performed

- `flutter test` — **1,382 tests passed**.
- `npm --prefix functions test` — **199 tests passed**.
- `flutter analyze` — **failed with 96 diagnostics** (warnings and infos).
  The repository therefore does not meet the workspace definition of done
  requiring clean analysis. Diagnostics include Humanizing-touched files such
  as `ai_payload_assembler.dart`, as well as pre-existing areas outside this
  feature.
- Working tree was clean before this audit.

Passing suites do not invalidate the findings above: the highest-risk paths are
not represented in the current tests.

## Material test gaps

No dedicated automated coverage was found for:

- logout/account-switch cleanup of FCM token documents;
- re-registration of push transport after an auth change;
- logout cleanup of native geofence region/armed state;
- `MemoryExtractionService` maintenance, inactivity, truncation, and purge
  lifecycle;
- `IntentionNudgeSyncService` end-to-end scheduling/projection behavior;
- intention notification actions with multiple slot ids;
- confirm-at-delivery hint/fact confidence changes;
- `ThinkingLoopService.reflectIfDue()` cadence, account switching, or
  concurrency;
- reflection exclusion from generic Layer-3/4 delivery surfaces;
- Firestore I/O shells for `runIntentionSweepOnce()` and
  `runMorningBriefOnce()`;
- push-send transient failures, pagination, and dead-token integration;
- Firestore rules protecting server-owned rescue/brief state;
- signed-device Siri phrase/cold-start behavior;
- native EventKit, Core Motion, and geofence exit/tap behavior;
- a complete flagship flow from natural-language capture through planned
  notification, response, learning, and later personalization.

## Operational and release gaps

1. `documentation/GUIDELINES.md` records the Phase 2/5 Cloud Functions and
   Firestore-index deployment as pending. Source presence does not make the
   scheduled services live.
2. APNs authentication-key upload remains a manual pending step.
3. `ios/Runner/Runner.entitlements` currently contains
   `aps-environment = development`, and all Xcode configurations reference
   that file. A production-signed archive's final entitlements and actual APNs
   delivery have not been verified by this audit.
4. Real Siri, push, calendar, motion, TTS/STT, and region-monitoring behavior
   requires signed physical-device testing; unit tests and
   `--no-codesign` builds cannot prove those paths.
5. The analyzer gate is not clean.

## Intentional deferrals and accepted trade-offs

These were not counted as defects:

- Android scheduled-notification, voice-entry, calendar, activity, and
  geofence enablement;
- Voice L3 full-duplex streaming;
- server transcription;
- server-side LLM agent;
- `workmanager`/BGTaskScheduler as a correctness mechanism;
- live LLM calls on the delivery path;
- calendar shadow records in synced scheduled time blocks;
- Places/POI claims such as "near a florist";
- battery context until it has a consumer;
- weekly compression of 90-day episodic summaries;
- morning brief becoming the Thinking Loop's voice;
- a rolling 24-hour rescue freshness rule (settled in the Phase 5 decision
  log, despite looser "today" wording in the PRD);
- an empty background FCM handler with replan on foreground/resume;
- the native geofence path bypassing Dart's orchestrator when Flutter is not
  alive;
- a stale geofence fire between app opens;
- keeping the iOS pending-queue safety cap as a compile-time platform guard.

## Final verdict

The implementation has the right architectural spine and demonstrates every
major Humanizing pillar, but several of the feature's trust promises are still
descriptive rather than operative. In particular, account isolation at the
notification boundary, server sweep completeness, session-end memory
extraction, confirmation-driven learning, quiet-notification limits,
dependency-aware planning, and Thinking Loop containment are not yet satisfied.

The current state should be described as **feature-complete in breadth,
incomplete in behavioral closure and production hardening**.

---

## Second-pass validation (2026-07-24, independent re-audit)

A second, independent pass re-read every finding's cited file/line evidence
directly, re-traced the notification pipeline end-to-end (pure
`AttentionOrchestrator`, route resolver, ledger writes in
`_executeDecision`, Layer-4 selection engine and notify gate), re-read the
full `firestore.rules` file, and re-ran the verification commands. No code
was modified.

### Verdicts per finding

| Finding | Verdict |
|---|---|
| P1-01 | **Confirmed.** `PushMessagingService` is referenced only from bootstrap (initialize + heartbeat), the resume heartbeat, and the Profile brief toggle — no auth listener, no logout cleanup. `clearLocalSession()` (`auth_session_policy.dart:65-93`) touches notifications, Isar, outbox, cursors, and three prefs keys only. |
| P1-02 | **Confirmed.** `syncArmed`/`clearHome` are reachable only through the nudge-sync `syncGeofence` callback (`intentions_providers.dart:190-191`, invoked from `applyAll`) and the opt-in/decline/quick-add flows. Nothing geofence-related runs at logout; the armed list survives until the next app-open replan. |
| P1-03 | **Confirmed**, with one refinement: brief starvation (equality filter → stable document-name ordering) is permanent at >500 opted-in device docs; sweep starvation (inequality on `windowEndMs` → soonest-expiring page) is burst-dependent — rows leave the page only by expiring, so the tail is examined at/after its own deadline under load. |
| P1-04 | **Confirmed.** `startNewSession()` has zero call sites in `lib/`; `onSessionEnded` is reachable only through it; `runMaintenance()` runs only in deferred bootstrap. |
| P1-05 | **Confirmed.** No runtime caller for `registerContradiction`, no `bumpNudgeCount: true` call site, and `IntentionStatus.nudged` appears only in the read-only reflection payload. |
| P1-06 | **Confirmed and strengthened.** The only per-entity throttle in the pure orchestrator (CoachingStyle back-off) applies solely to `reminderType != scheduled`, and intention intents use the default `ReminderType.scheduled` (`reminder_intent.dart:19`) — so no path caps intention nudges. Remaining politeness is the 3-minute collision gap, batching, override suppression, focus silence, and the pending-queue budget. |
| P1-07 | **Confirmed.** Dependency fields exist only in the model and serialization; no planner or sync reference. |
| P1-08 | **Partly confirmed — corrected in place.** The placement escape into Home/Progress coaching focus is real; the OS-notification vector was wrong (blocked by the low-priority notify gate). Severity revised to P2. |
| P1-09 | **Confirmed.** Hint updates apply `preferredTimeBlock` with no `basedOn` validation. |
| P2-01 | **Confirmed.** Per-slot ledger rows share `entityId` (`attention_orchestrator_service.dart:412-421`); interaction handling resolves `findByEntityId` → latest `updatedAtMs` row, so a tap on one slot is attributed to the most recently written sibling. |
| P2-02 | **Confirmed** (code re-read; bookkeeping is stamped unconditionally after `sendToTokens`). |
| P2-03 | **Confirmed.** The full 353-line rules file has no carve-out under the `users/{userId}` owner-write wildcard for `rescueState`, `briefState`, or `deviceTokens`. |
| P2-04 | **Confirmed.** |
| P2-05 | **Confirmed.** |
| P2-06 | **Confirmed.** |
| P2-07 | **Confirmed as scoped**, with a nuance: the executor's memory path (`_rememberFact`, `ai_action_executor.dart:753-766`) DOES resolve `personName` → `personId` via `findByReference`; the gap is specific to intention creation (`_createIntention`, `662-729`, which has no person parameter at all). |
| P2-08 | **Confirmed.** |
| P2-09 | **Confirmed** (no `parse_intention`/`phrase_nudge` client call sites). |
| P2-10 | **Confirmed** (global prefs keys at `thinking_loop_service.dart:75-76`; empty first snapshot marks the day at `98-102`; `clearLocalSession` does not clear them). |
| P2-11 | **Confirmed** (`reflectIfDue()` re-read in full: no in-flight guard; launched unawaited from bootstrap:95 and resume:123). |
| P2-12 | **Confirmed.** |
| P2-13 | **Confirmed.** |
| P3-01 | **Confirmed** (`MemoryReferenceChip(factId: grounded.factIds.first)`, `chat_bubbles.dart:71-75`). |
| P3-02 | **Consistent with repository searches**; an absence claim cannot be proven exhaustively. |

### Correction applied

P1-08 originally claimed a reflection observation could become an OS "Coach
Insight Ready" notification. That path is not reachable: reflection insights
are emitted at `InsightPriority.low` and `passesNotificationGate()` rejects
low priority unconditionally, so `shouldNotify` is always false when a
reflection is the selected primary. The finding body was corrected in place
and its severity revised to P2. Every other finding stands as written.

### Additional observation from this pass

- **V-01 (P2, likely pre-Humanizing) — the Layer-4 insight push bypasses the
  orchestrator.** Home's "Coach Insight Ready" dispatch schedules an OS
  notification directly (`lib/features/home/presentation/home_screen.dart:961-985`,
  fixed id `kCoachingInsightNotificationId`) under its own separate budget
  (3/day + 4-hour gap,
  `lib/features/analytics/application/coaching_insight_notification_policy.dart`)
  without passing `AttentionOrchestrator` or writing the notification ledger.
  The implementation PRD's reconnaissance describes this dispatch as "a
  foreground Home widget, not a notification bypass," which is inaccurate as
  written. It is not reachable by reflection insights (see corrected P1-08)
  but is reachable by medium/high-priority deterministic insights, making it
  a third notification producer outside the Phase 0 "one decision brain"
  contract alongside the documented native-geofence exception.

### Re-verification results

- `flutter test` — 1,382 tests passed (re-run in this pass).
- `npm --prefix functions test` — 199 tests passed (re-run in this pass).
- `flutter analyze` — 96 issues (re-run in this pass; unchanged).
- Working tree contains only this audit document.

### Validation verdict

`Humanizing_audit.md` is accurate after one material correction (P1-08's
OS-notification claim). Every cited file/line reference checked in this pass
resolved to the described code. The overall assessment — feature-complete in
breadth, incomplete in behavioral closure and production hardening — stands.
