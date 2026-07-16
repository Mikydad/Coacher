# PRD — Accountability Stakes System

**Status:** Confirmed with product owner (2026-07-16) after three rounds of
semantic clarification. This document supersedes ambiguous parts of
[`Pathpal accountability spec.md`](Pathpal%20accountability%20spec.md); where
the two disagree, THIS document wins. The original spec remains the source
for background rationale (legal model, Apple compliance research, payments
rails).

**Audience:** implementer (assume junior developer). Every requirement is
explicit; every phase names the files it touches.

---

## 1. Introduction / Overview

PathPal users set goals but abandon them without consequences. This feature
adds **accountability stakes**: something real is on the line — an
embarrassing photo, or money — and a server-authoritative engine decides
outcomes so nobody can dodge a forfeit.

Three user-facing features on one shared **Challenge Core**:

1. **Photo Stakes (solo)** — fail your goal and a pre-approved embarrassing
   photo of you posts to your circle for a short window.
2. **Opposing-Charity Stakes (solo, money)** — fail and your stake is donated
   to an organization you'd hate to fund.
3. **Head-to-Head & Team Challenges** — 1v1 or team-vs-team inside a circle;
   losers' stakes fund the winners' chosen charity.

Plus a **points economy** (earn now, IAP later) and a **psychology/honesty
layer** (pledges, attestation, honesty streaks, placed quotes).

### 1.1 The legal foundation (never violate)

> **No user ever receives another user's money. Winners get only their own
> stake back. Losers' stakes go to verified charities.**

This is what makes the system a commitment contract (StickK model) and not
gambling. Every payment path in this document preserves it. Related hard
rules: points can never be cashed out; donations never flow through Apple
IAP (Apple prohibits it — Stripe is the compliant rail).

---

## 2. The Confirmed Model (decision record)

All semantics below were explicitly confirmed by the product owner. Do not
relitigate them; a change requires a superseding decision-log entry in
`documentation/GUIDELINES.md`.

| # | Decision |
|---|----------|
| D1 | **Two mercy layers, both active.** (a) 25% within-unit time mercy: a unit (e.g. a day) passes at ≥75% of its target — 60 min goal passes at 45 min. Covers timer friction, forgotten starts. (b) **Mercy veto**: 1 per user per month, photo stakes only, applied at the moment of forfeit; blocks the photo from posting but the challenge still records as a loss (`vetoed`). |
| D2 | **Mercy aggregates per cadence unit.** Daily goal → each day is judged independently at target × 0.75. |
| D3 | **Solo strictness reuses the existing `RoutineMode`** (`flexible` / `disciplined` / `extreme`, `lib/features/planning/domain/models/routine_mode.dart`, mapped from goal intensity by `goal_intensity_mode.dart`). Units required to pass the challenge: Flexible ≥70% of units, Disciplined ≥85%, Extreme 100%. Percentages are Remote Config-tunable constants. |
| D4 | **Teams: unanimous completion, no modes.** Every member must pass every unit of their own goal (the 25% within-unit mercy still applies). One member's failure loses it for the whole team — the peer pressure is the product. Consequence accepted: both-teams-lose is a common outcome, not an edge case. |
| D5 | **Money routing (H2H & teams):** winners are always refunded their own stake; the losing side's stakes are donated to the **winning side's chosen charity** ("my rival's money funded MY cause"). Solo money: forfeit goes to the anti-charity the user picked at creation. **Stakes follow the SIDE outcome**: a personally-passing member of a losing team still forfeits (that's the D4 drag — "if I slack, all four of us lose to their cause"); their personal W/L record still shows the individual pass. "Winner" in §1.1 means the winning side. |
| D6 | **Both-lose recipient:** chosen at creation — participants pick a charity they all dislike from the curated list; if they don't, the app assigns a platform-default neutral charity. |
| D7 | **All charities come from the curated, admin-managed list. No free entry, ever.** Both the "charity I love" and "charity I hate" directions. Users can request additions; admin vets. No hate groups, no demographic targeting. |
| D8 | **Photo reveal window: 5 minutes – 24 hours**, chosen by the staker at creation. Deletion after expiry is guaranteed server-side. |
| D9 | **Point-based early removal** of a revealed photo: allowed only after a **hard exposure floor of 30% of the window** (launch constant, RC-tunable within the agreed 25–35% band); price ≈ **1–2 weeks of typical honest earning** (launch: 300 pts, RC-tunable). No amount of points shortcuts the floor. The loss stays on the record regardless. |
| D10 | **No mercy on money.** No veto, no removal, no undo. If you lose, the money moves. The only protections on money challenges are the measurement rules (D1a, D3). |
| D11 | **Screenshot enforcement is deter + punish, not prevent.** Android: block outright (`FLAG_SECURE`). iOS: detect and report. Ladder: 1st offense = 12-hour ban from joining challenges **+ public circle announcement naming the offender**; 2nd = 3-day ban; 3rd = 1-week ban. Announcement doubles as owner notification. Active challenges continue during a ban. |
| D12 | **Evidence = in-app timer sessions and/or in-app-camera photos only. No gallery uploads.** Kills the edit/AI-fake vector cheaply instead of fighting a detection arms race. Circle flag → circle vote (48h, majority; no quorum → no forfeit) is the human dispute layer. H2H adds opponent-confirms as the first verification step. |
| D13 | **The deepest verification layer is psychological**: honesty pledge at creation, attestation showing the user their own "why" at evidence time, neutral reporting language, honesty streaks, quotes at decision moments. Designed component, not decoration. |
| D14 | **Points**: append-only ledger, server-written only, earned via daily check-in / tasks / goals / streaks / challenge wins / signup bonus; purchasable later via IAP (Remote Config-gated); **never cashed out**. Earn rates are designed against the photo-removal price (a removal ≈ 1–2 weeks of honest use). |
| D15 | **Server-authoritative outcomes.** Deliberate, scoped exception to the app's local-first rule: deadlines and forfeits are decided by the server clock in Cloud Functions. Isar mirrors challenge state read-only for display. Offline ≠ dodge. |

---

## 3. Goals

1. A user can stake a photo or money on a goal and genuinely cannot weasel
   out — outcomes are server-decided, evidence is timestamped, mercy is
   bounded and explicit.
2. The system is legally a commitment contract: §1.1 invariant holds in
   every code path, including refund failures and account deletion.
3. Photo stakes pass Apple review: UGC safety set (report / block / delete /
   contact), explicit consent, NSFW screening, 17+ gating, account-deletion
   purge.
4. Phases 1–2 ship with **zero payment infrastructure** (photo + points);
   money arrives in Phase 4 behind the LLC/Stripe track without reworking
   the core.
5. The trust core (outcome engine) is tested before any UI exists.

## 4. Non-Goals (out of scope)

- No user-to-user money transfer of any kind, ever.
- No points cash-out, ever.
- No free-entry charity recipients.
- No screenshot prevention promise on iOS (impossible) — only deterrence.
- No automated AI-image-fake detection at launch (D12 replaces it).
- No donation API integration at launch — manual admin disbursement with
  posted receipts first.
- The existing casual circle `Challenge`
  (`lib/features/community/domain/models/challenge.dart`) is NOT being
  replaced, extended, or migrated. It stays as-is; the new entity is
  separate (see §7.2).

---

## 5. User Stories

- As a procrastinating student, I stake an embarrassing photo on "read 1h a
  day for a week" so the fear of my circle seeing it gets me reading. When I
  read only 45 min on Tuesday, the day still passes (mercy) — the app is
  strict, not cruel.
- As a Liverpool fan, I stake $20 on my gym goal knowing failure funds
  Manchester United's foundation. That specific pain works on me.
- As a circle member, I challenge my friend 1v1: whoever fails funds the
  winner's chosen charity. If we both fail, the money goes to a group we
  both can't stand — we agreed on it when we started, and it kept us both up
  at night.
- As a team of 4, we each stake $5 against another team of 4. I know that if
  I slack, all four of us lose $20 to their cause — so I don't slack.
- As someone whose photo just got revealed, I watch the timer: it stays up
  at least 30% of the window no matter what, then I can burn two weeks of
  points to take it down early. I earned those points; it still hurts.
- As a user who fell genuinely ill, I use my one monthly mercy veto — the
  loss is recorded but the photo never posts.
- As a circle member who screenshotted someone's forfeit photo, I get named
  publicly in the circle and banned from challenges for 12 hours. I don't do
  it again.

---

## 6. Functional Requirements

Numbered for traceability. "System" = client + Cloud Functions together;
"Server" = Cloud Functions only.

### 6.1 Challenge Core (CC)

- **CC-1** A `StakeChallenge` has: `type` (`solo_photo` | `solo_money` |
  `h2h_points` | `h2h_money` | `team_points` | `team_money` | `practice`),
  linked goal criteria (frozen copy, see CC-6), cadence + per-unit target,
  deadline, mode (solo only), stake descriptor, participants, charity
  selections, status, outcome.
- **CC-2** Status machine (server-enforced, transitions only via Cloud
  Functions):
  `draft → pending_accept (h2h/team) → active → pending_verification →
  completed_success | completed_forfeit | cancelled | vetoed`.
  Declining an invite: `pending_accept → cancelled`.
- **CC-3** Every state change appends an immutable event to
  `stake_challenges/{id}/events` (actor, type, timestamp, payload). Events
  are never mutated or deleted.
- **CC-4** A scheduled function sweeps every 15 min: `active` past
  `deadline` → `pending_verification`; evaluates evidence per §6.2; applies
  outcomes. All stake movements (photo reveal, points burn, refund,
  donation) originate ONLY here or in the dispute-resolution path.
- **CC-5** Offline evidence grace: at deadline the challenge enters
  `pending_verification`; the final success/forfeit decision runs
  **12 hours later** (RC-tunable) so evidence recorded offline can sync in.
  Evidence synced after the decision changes nothing. Server stamps arrival
  time on all evidence; bulk backfill (many units arriving in one sync
  minutes before decision) is flagged on the challenge for circle review
  but does not auto-fail.
- **CC-6** The goal criteria are **frozen into the challenge at creation**.
  Editing or deleting the linked goal/task in the app does not change what
  the challenge measures. The linked goal shows a "staked" badge and warns
  on edit/delete attempts.
- **CC-7** Practice challenges: `type = practice`, self-report, no stakes,
  no server sweep consequences — the onboarding loop.
- **CC-8** Client writes for challenge state go through **callable
  functions, not the outbox** (see §7.1 for why). UI treatment is
  optimistic-then-honest (Telegram model): show the pending item instantly,
  reconcile on server ack, per-item error + retry on failure.

### 6.2 Measurement & Mercy (M)

- **M-1** Unit pass: `loggedAmount ≥ unitTarget × 0.75` (25% within-unit
  mercy; constant across all modes and challenge types).
- **M-2** Solo challenge pass: `passedUnits ≥ ceil(totalUnits × modeFactor)`
  where modeFactor = 0.70 (flexible) / 0.85 (disciplined) / 1.00 (extreme).
  The mode is chosen at creation and displayed throughout.
- **M-3** Team member pass: every unit of that member's goal must pass
  (M-1 still applies inside each unit). Team pass: every member passes.
  No modes in team challenges (D4).
- **M-4** 1v1 H2H: challenger proposes the mode; the opponent sees it before
  accepting; both parties are judged under the same mode. (Flagged in §11
  as inferred — confirm before Phase 2 UI.)
- **M-5** Evidence sources per unit: (a) in-app timer sessions attributed to
  the challenge (existing timer feature gains persistence, §8 Phase 1);
  (b) photos taken with the **in-app camera only** — the evidence flow never
  opens the gallery; (c) check-in notes (non-authoritative, context only).
- **M-6** Mercy veto: callable `stakeApplyVeto`, valid only for photo stakes
  in `pending_verification`/at forfeit moment, only if the user's last veto
  was >30 days ago (server-tracked). Result status `vetoed` = a recorded
  loss with no photo reveal.

### 6.3 Verification & Disputes (V)

- **V-1** Solo: evidence auto-evaluated (M-1/M-2). Circle members can flag a
  challenge as suspicious during `active` or `pending_verification` → opens
  a circle vote.
- **V-2** H2H/team: at deadline each side confirms or disputes the other's
  completion within 24h; silence = confirm. Dispute → circle vote.
- **V-3** Circle vote: 48h window, majority of non-participant circle
  members; tie or no quorum → **no forfeit** (user-favorable default).
  One vote per member, recorded as events.
- **V-4** All confirmations, disputes, votes are callable functions writing
  events; the sweep applies the resulting outcome.

### 6.4 Photo Stakes (P)

- **P-1** Upload flow: pick/take photo → **explicit consent screen** stating
  exactly: failure by [deadline] posts this photo to [circle name], visible
  to its N members, for [window] — with attestation checkbox "this is a
  photo of me". Active confirm required; not buried in ToS.
- **P-2** Every stake photo is NSFW-screened server-side at upload (Cloud
  Vision SafeSearch via a Storage `onFinalize` trigger; same proxy pattern
  as `aiChat` in `functions/src/index.ts`). Reject adult/violence/
  likely-minor → challenge cannot activate; photo deleted.
- **P-3** Storage lifecycle (rules tested explicitly, §9):
  active → read/write owner only (write once);
  forfeit → read: circle members;
  success/veto/expiry/removal/account-deletion → object deleted.
- **P-4** Reveal: on forfeit the server flips access, creates a circle feed
  post + announcement, and schedules expiry (owner-chosen window, 5 min–24 h).
  Expiry deletes the object and the feed post payload (the event log keeps
  the fact, not the image).
- **P-5** Early removal: callable `stakeRemovePhoto`, valid only after 30%
  of the window has elapsed; burns the removal price (D9) from the points
  ledger atomically with the takedown; announcement in the circle records
  a removal happened ("removed early" — no shame copy beyond that).
- **P-6** Reveal viewer is a dedicated screen: Android sets `FLAG_SECURE`
  (captures come out black); iOS hides the photo while
  `UIScreen.isCaptured` (screen recording) and reports screenshots via
  `userDidTakeScreenshotNotification` → callable `stakeReportScreenshot`.
- **P-7** Screenshot strikes (server-tracked, per uid): 1st = 12h
  challenge-join ban + circle announcement naming the user; 2nd = 3 days;
  3rd+ = 1 week. Bans block `stakeCreateChallenge`/`stakeAcceptChallenge`,
  never disrupt active challenges.
- **P-8** UGC safety set: report any revealed photo (hidden pending admin
  review), block user, owner may delete a revealed photo after expiry
  anyway, published contact method, account deletion purges all stake
  photos and cancels (+ Phase 4: refunds) active challenges.
- **P-9** Photo stakes hidden for under-18 accounts; App Store rating 17+.

### 6.5 Money Stakes (\$) — Phase 4

- **\$-1** Stripe charge at creation (solo) or on final accept (h2h/team);
  challenge activates only after successful charge for every participant.
  Declined card = challenge never activates (invite expires).
- **\$-2** Escrow = server-side record; funds sit in the platform Stripe
  account flagged held. Refund on success; on forfeit, mark for
  disbursement to the routed charity (D5/D6).
- **\$-3** Disbursement manual at first: admin donates via the charity's own
  channel, uploads the receipt; the receipt posts in-app to the challenge
  ("Your $20 funded [X] 😬" / "[Rival]'s $20 funded YOUR cause").
- **\$-4** Edge handling: refund failure/expired card → retry queue +
  support flow; chargeback → challenge annotated, user flagged (repeat
  chargebacks = money-stake ban); account deletion mid-challenge → cancel +
  refund.
- **\$-5** Charity list: admin-managed `charities` collection { name,
  category, charityRegistration, donationMethod, logo, active, tags };
  user-facing request-an-addition flow writes to a moderated queue.

### 6.6 Points Economy (PT)

- **PT-1** Append-only ledger `points_ledger/{uid}/txns/{txnId}`: { amount
  (±), source, refId, serverTimestamp }. Sources: `signup_bonus`,
  `earn_checkin`, `earn_task`, `earn_goal`, `earn_streak`,
  `earn_challenge_win`, `stake_lock`, `stake_release`, `stake_forfeit`,
  `spend_photo_removal`, `iap_purchase` (Phase 4). Balance is always
  computed (server maintains a denormalized balance doc for display;
  ledger is truth).
- **PT-2** Firestore rules deny ALL client writes to the ledger; every
  entry is written by a Cloud Function. Client reads own ledger; Isar
  mirrors it read-only for offline display.
- **PT-3** Launch earn table (all RC-tunable; designed so typical honest
  use ≈ 150–200 pts/week): check-in 5/day (max 1), task completion 2 (cap
  20/day), goal unit completion 5, weekly streak bonus 15, challenge win
  50, signup 50. Photo removal price 300 (D9). H2H points stakes:
  suggested 100–500.
- **PT-4** Points H2H/team: `stake_lock` on accept, `stake_release` on win,
  `stake_forfeit` (burn) on loss. Burned points are recorded for the
  quarterly company-revenue charity conversion (published in-app; no user
  money moves).
- **PT-5** IAP purchase ships dark in Phase 4: RevenueCat (or
  `in_app_purchase`), server-side receipt validation, Remote Config flag,
  Small Business Program. Purchased and earned points are one currency.

### 6.7 Psychology / Honesty Layer (PSY)

- **PSY-1** Creation ends with an **honesty pledge**: the user types their
  name or holds-to-commit (≥1.5s) under the pledge text + their stated
  "why". Pledge recorded as the activating event.
- **PSY-2** Evidence submission shows the user's own "why" directly above
  the confirm button; confirm copy is an attestation ("This record is
  true.").
- **PSY-3** All self-report language is neutral recording, never boasting:
  "Record what happened", never "Claim success".
- **PSY-4** Honesty streak: count of evidence submissions never flagged or
  overturned — displayed on profile and challenge cards ("Verified honest
  ×14"). Broken only by an overturned dispute, not by losing a challenge.
- **PSY-5** Accountability quotes appear at exactly two moments — daily
  check-in and pre-evidence-submission — never as ambient filler. Quote
  pool curated in Remote Config.

---

## 7. Technical Design

### 7.1 The architecture exception, stated once

CLAUDE.md's local-first rules stay in force for everything else. Stakes are
**network-inherent** (GUIDELINES checklist #4): outcomes move other people's
photos/points/money, so the server must be authoritative.

- Challenge **state transitions**: callable Cloud Functions. NOT the outbox
  (the outbox is fire-and-forget replication of user-own data; a stake
  transition needs server validation + an authoritative answer). The
  `local_first_guard_test.dart` ban on awaited Firestore writes is not
  violated — callables are RPCs, not Firestore writes. UI is
  optimistic-then-honest per CC-8.
- Challenge/ledger **reads**: `RemoteIsarMerge` gains pull phases →
  read-only Isar mirrors → existing watch-stream providers. Airplane mode
  shows last-known state + honest "pending sync" chips on in-flight
  actions.
- **Evidence** (timer sessions, evidence photo metadata) IS user-own data:
  Isar + outbox as normal (`outboxUpsert`), evaluated server-side at
  decision time (CC-5 grace window).

### 7.2 Data model

New Isar collections (register in `isar_schemas.dart`, regenerate with
build_runner; all carry `updatedAtMs`, LWW merge):

| Isar collection | Mirrors / synced via |
|---|---|
| `StakeChallenge` | mirror of `stake_challenges/{id}` (pull-only) |
| `StakeChallengeEvent` | mirror of `stake_challenges/{id}/events` (pull-only) |
| `PointsTxn` + `PointsBalance` | mirror of ledger (pull-only) |
| `Charity` | mirror of `charities` (pull-only) |
| `TimerSession` | user-own: outbox → `users/{uid}/timer_sessions/{id}` |
| `StakeEvidence` | user-own: outbox → `stake_challenges/{id}/evidence/{uid}_{unit}` (metadata; photo binary → Storage) |

`StakeChallenge` core fields: `id` (StableId), `type`, `status`,
`creatorUid`, `participants[] { uid, teamId?, charityLovedId, stake
{ kind: photo|points|money, amount?, photoPath?, revealWindowMins?,
consentAt } }`, `bothLoseCharityId`, `circleId`, `frozenGoal { title,
cadence, unitTargetAmount, unitKind, totalUnits }`, `mode` (solo),
`deadlineMs` (server-set), `outcome { decidedAtMs, result, perParticipant
{ passed, unitsPassed, stakeResolution } }`, `createdAtMs`, `updatedAtMs`.

The existing casual `Challenge` (community) is untouched. UI copy calls the
new entity **"Stakes"** to avoid user-facing confusion with circle
challenges.

### 7.3 Cloud Functions inventory (`functions/src/`, TypeScript v2, same style as `aiChat`)

Callables — `stakes/` module:
`stakeCreateChallenge`, `stakeAcceptChallenge`, `stakeDeclineChallenge`,
`stakeCancelDraft`, `stakeSubmitEvidence` (metadata finalize; also
validates evidence photo came from the in-app camera path),
`stakeConfirmOutcome` (confirm/dispute), `stakeCastVote`, `stakeApplyVeto`,
`stakeRemovePhoto`, `stakeReportPhoto`, `stakeReportScreenshot`,
`charityRequestAddition`.
Phase 4 adds: `stakeCreatePaymentIntent`, Stripe webhook handler
(`onRequest`), `adminMarkDisbursed`.

Scheduled: `stakeSweep` every 15 min — one function, four jobs: deadline
transitions, post-grace decisions (CC-5), vote-window closes (V-3), photo
expiries (P-4).

Triggers: Storage `onFinalize` under `stake_photos/` → SafeSearch screen →
approve/reject event. Auth `onDelete` → purge photos, cancel challenges
(Phase 4: refund).

Points grants (`earn_checkin` etc.): server functions called from existing
completion paths — Phase 2 wires them behind a single
`grantPoints(uid, source, refId)` callable with server-side idempotency on
`refId` (one grant per task/day/goal-unit, enforced by deterministic txn
ids, e.g. `earn_checkin_2026-07-16`).

### 7.4 Security rules (treat as security-critical; emulator-tested in CI)

Firestore:
- `stake_challenges/**`: client **read** if participant or circle member
  (events: same); client **write: none** (everything via functions).
  Exception: `evidence` subcollection accepts participant writes matching
  strict shape validation (it flows through the outbox).
- `points_ledger/**`: read own; write none.
- `charities`: read `active == true`; write none (admin SDK only).
- `enforcement/{uid}` (screenshot strikes, veto timestamps): read own;
  write none.

Storage:
- `stake_photos/{challengeId}/…`: write once by owner at creation (content
  type + size limits); read owner while active; read circle members only
  while `revealed` (rules read a mirrored status doc); nobody after expiry
  (object deleted anyway).
- `stake_evidence/{challengeId}/{uid}/…`: write by that uid during active
  window only; read participants + circle.

### 7.5 Screenshot enforcement implementation

- Android: `FLAG_SECURE` on the reveal route via a small MethodChannel
  (set on route enter, cleared on exit). Blocks screenshots AND hides the
  app in recents while the route is up.
- iOS: reveal screen subscribes to `userDidTakeScreenshotNotification`
  (fires only while our screen is frontmost → we know who + which photo)
  → `stakeReportScreenshot`; and hides the image behind a blur overlay
  whenever `UIScreen.main.isCaptured` (recording/AirPlay).
- The circle announcement copy for a strike: "[Name] screenshotted a stake
  photo and is banned from challenges for [duration]."
- Second-phone photography is undetectable; the short reveal windows (D8)
  are the real mitigation. Never market "screenshots are impossible".

### 7.6 In-app camera evidence

Evidence capture uses the `camera` package directly inside
`EvidenceCaptureScreen` — no `image_picker`, no gallery intent anywhere in
the flow. Client stamps capture time + challenge id into the upload path;
`stakeSubmitEvidence` rejects metadata whose Storage object wasn't created
through the evidence path. (Not unbeatable — D13 and circle votes are the
deeper layers — but it removes the easy 90%.)

---

## 8. Step-by-Step Implementation Plan

Phases are strictly ordered; each has an exit gate. Estimates assume
current velocity.

### Phase 0 — Security gate (~1 week; BLOCKS everything)

Verify/complete the known blockers before any photo can exist:

1. Audit Firestore + Storage rules against `documentation/firebase-rules.md`;
   close every hole; add emulator rules tests to CI.
2. Confirm the OpenAI key lives only behind `aiChat` (no client key).
3. Fix account-switch `ref.read` uid re-scoping leak; verify provider
   invalidation on logout (no cross-account Isar/state bleed).
4. Crashlytics wired; debug screens stripped from release builds.

**Exit gate:** rules tests green in CI; a written pass over each item in
`documentation/2026-07_features_fixes_and_incidents.md`. An embarrassing-
photo leak through a rules hole is the one failure this feature cannot
survive — this gate is not ceremony.

### Phase 1 — Challenge Core + Photo Stakes (~2.5 weeks)

**Step 1.1 — Outcome engine first (server, no UI).**
`functions/src/stakes/`: state machine, `stakeSweep`, create/cancel/veto
callables, event log, mercy math (M-1/M-2), CC-5 grace logic. **Unit tests
before any client code** — table-driven tests over: every legal/illegal
transition; mercy boundaries (44/45/46 min on a 60-min unit); mode
thresholds on 7/30-unit challenges; offline-evidence grace; veto
eligibility windows. This is the trust core; it merges only at full
coverage of the outcome table.

**Step 1.2 — Data + sync layer (client).**
New feature folder `lib/features/accountability/` (domain/data/application/
presentation, matching existing feature layout). Isar collections (§7.2) +
`isar_schemas.dart` + build_runner; `RemoteIsarMerge` phases
`_pullStakeChallenges`, `_pullPointsLedger`, `_pullCharities` (LWW on
`updatedAtMs`, cursor pattern copied from `_pullGoals`); watch-stream
providers; callable-client wrappers with the optimistic-then-honest
pending/error/retry envelope.

**Step 1.3 — Timer persistence.**
`TimerSession` entity (start/end/duration/linked challenge+goal), written
by the existing timer feature (`lib/features/timer/`), Isar + outbox +
merge phase. Timer keeps working fully offline.

**Step 1.4 — Creation flow UI.**
Multi-step (PopScope step-back, AnimatedSwitcher ~260ms, no snaps):
link/define goal → cadence + unit target → mode (reuse intensity/mode
selector idiom) → photo capture/pick + reveal-window choice → consent
screen (P-1) → honesty pledge (PSY-1) → review → create (pending → active
on server ack + NSFW pass). Photo upload with owner-only rules.

**Step 1.5 — Tracking + evidence UI.**
Stakes hub (active/pending/history) + challenge detail (countdown, unit
grid with pass/fail/mercy states, evidence log, honest sync chips);
`EvidenceCaptureScreen` (in-app camera, §7.6); evidence attestation screen
(PSY-2/3).

**Step 1.6 — Forfeit path.**
Veto moment UX (notification + 24h-max decision window inside the CC-5
grace), reveal flip (server), circle feed post + announcement, reveal
viewer with screenshot enforcement (§7.5), expiry deletion, points-removal
action stubbed (enabled in Phase 2 when points exist).

**Step 1.7 — Safety set.**
Report (hide pending review) / block / owner-delete-after-expiry / account
deletion purge; support contact surfaced; practice-challenge mode (CC-7);
under-18 gating.

**Exit gate:** full loop in airplane-mode-where-applicable: create (online)
→ track offline → sync → server decides → reveal → expiry. `flutter
analyze` clean, suite green, rules tests green. Shippable alone.

### Phase 2 — Points + H2H/Teams (points variant) (~1.5 weeks)

**Step 2.1 — Ledger** (PT-1/2/3): functions (`grantPoints` + idempotency),
rules, Isar mirror, balance UI, grants wired into existing check-in/task/
goal completion paths.
**Step 2.2 — H2H 1v1**: invite/accept/decline callables + UI, dual points
escrow (lock/release/forfeit), opponent-confirm + dispute + circle vote
(V-2/3), charity-selection UI (loved + both-lose picks — list exists from
Phase 1 as static data; money routing itself is Phase 4).
**Step 2.3 — Teams**: teamId grouping, unanimous evaluation (M-3), pooled
announcement copy.
**Step 2.4 — Social layer**: W/L record, honesty streak (PSY-4), badges,
rematch, quotes placement (PSY-5). Photo removal price live (P-5).

**Exit gate:** two test accounts run a full 1v1 and a 2v2 to all four
outcome cells (win/win, win/lose, lose/win, lose/lose) with correct point
movements in the ledger.

### Phase 3 — Business setup (parallel, no code)

US LLC + EIN + business bank + Stripe activation; Apple Developer
enrollment continues. Tracked outside the repo.

### Phase 4 — Money layer (~2 weeks, gated on Stripe live)

**Step 4.1** Stripe integration: payment intents, webhook, escrow records;
outcome-engine hooks `onSuccess → refund`, `onForfeit → markForDisbursement`
(D5/D6 routing table).
**Step 4.2** Failure handling (\$-4): retry queue, support flow, chargeback
policy, account-deletion refunds.
**Step 4.3** Curated charity admin flow + request queue (\$-5).
**Step 4.4** Solo money UI, then money H2H/teams (same screens, stake step
swaps points→money).
**Step 4.5** Manual disbursement runbook + receipt posting.
**Step 4.6** IAP points purchase (PT-5) behind the Remote Config flag.

**Exit gate:** Stripe test-mode E2E of every routing row in D5/D6 including
both-lose; refund-failure drill; §1.1 invariant re-audited on the final
code.

---

## 9. Test Plan (minimum bar, from the cross-cutting checklist)

- Outcome-engine table tests (Step 1.1) — every transition, mercy boundary,
  mode threshold, grace window, veto window.
- Rules emulator tests: photo lifecycle (owner-only → circle-read →
  deleted), ledger write-denial, challenge write-denial, evidence shape
  validation.
- Offline dodging: deadline passes while device offline → forfeit stands;
  late evidence within grace counts, after grace doesn't.
- Veto abuse: second veto in 30 days rejected server-side.
- Photo-of-someone-else report flow hides pending review.
- H2H cells: both-win, both-lose, split — points (Phase 2) and money
  (Phase 4).
- Screenshot strike ladder: 1st/2nd/3rd offense durations + announcements;
  ban blocks join, not active play.
- Removal floor: removal attempt at 29% of window rejected; at 31% burns
  exactly the price and deletes.
- Account deletion mid-challenge: photos purged, challenge cancelled
  (+ refund in Phase 4).
- Architecture guard: no awaited Firestore writes introduced
  (`local_first_guard_test.dart` stays green).

## 10. Success Metrics

- ≥60% of started (non-practice) stakes reach a decided outcome (vs.
  silently abandoned goals today).
- Completion rate of staked goals ≥1.5× the same user's unstaked baseline.
- Mercy veto usage <10% of photo forfeits (higher = goals set too hard;
  revisit defaults, not the veto cap).
- Zero §1.1 invariant violations, zero photo-access rule breaches
  (monitored via rules tests + Storage audit logs).
- Screenshot strikes trending to ~zero repeat offenders.

## 11. Open Questions (small; none block Phase 0–1)

1. **M-4 inference** — 1v1 H2H uses one shared mode proposed by the
   challenger. Confirm before Phase 2 UI.
2. Exact earn-table values (PT-3) — launch defaults above; tune in RC
   during Phase 2 beta.
3. Platform-default neutral charity (D6 fallback) — needs an admin pick
   before Phase 2 ships team/H2H.
4. Reveal-window default suggestion in the picker (proposal: 1 hour).
5. Whether a veto should ALSO cost points on top of the monthly cap
   (spec offered either/or; current model: cap only, no cost).
