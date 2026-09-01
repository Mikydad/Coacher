# PRD — Public Commitment Cards (`soloPublic` stake)

**Date:** 2026-08-31 · **Status:** Approved for implementation (decisions settled with Miko, see §10)
**Related:** `PRD/Accountability_feature/prd-accountability-stakes.md` (stake engine), `documentation/GUIDELINES.md` decision log

---

## 1. Introduction / Overview

A new **solo stake type with zero payment infrastructure**: instead of risking money
or a photo, the user risks their **public word**. At commitment time the app renders
a shareable **pledge card** ("I COMMIT — finish my portfolio by September 1") that the
user posts to Instagram/WhatsApp/etc. via the native share sheet. At resolution the
app renders a **result card** — a gold "I DID IT." crown card on success, or a
dignified, progress-led "I DIDN'T." card on failure — closing the public loop.

Why this exists:

- **Replaces the money stake** as the reachable "against yourself" option. Real-money
  stakes are payment-complicated and risk App Store gambling classification
  (guideline 5.3). Nothing of monetary value enters or leaves this system.
- **The pressure is social**, created outside the app at posting time. The app's job
  is to make the cards so good they get posted.
- **Every shared card is organic marketing** — a branded SidePal card in a feed.

The card images are generated entirely on-device by Flutter (widget →
`RepaintBoundary` capture → PNG → share sheet). No server rendering, no AI image
generation at runtime, fully offline.

## 2. Goals

1. Ship a fifth stake choice, **Public commitment**, in the accountability create
   flow — available in release builds (unlike the debug-only money stake).
2. Generate three card designs (pledge / success / failure) locally, in 9:16 and
   1:1, sharp enough for Instagram (1080×1920 / 1080×1080 PNG).
3. Reuse the existing solo stake lifecycle end-to-end: server-owned resolution,
   `pending_verification` grace, terminal mirror statuses — no new resolution
   machinery.
4. Zero payment/escrow/charity code paths touched; zero new App Store review risk.
5. Card generation and sharing work in airplane mode (product principle 1–2).

## 3. User Stories

- As a user who wants accountability but has no points saved and doesn't want a
  photo stake, I pick **Public commitment**, get a beautiful pledge card, and post
  it to my story so my friends hold me to it.
- As a user who completed my challenge, I'm offered a crown card the moment the win
  is confirmed, and I post it as proof I called my shot.
- As a user who fell short, I get a card that leads with what I *did* do
  ("22 / 30 km"), owns the miss without humiliating me, and lets me recommit with a
  new date in two taps.
- As a user who quits mid-challenge, deleting the goal counts as a miss — I'm told
  so before confirming, and the failure card is offered.
- As a user browsing an old challenge, I can re-open its card any time and share it
  again.

## 4. Functional Requirements

### A. Stake type & lifecycle (client domain + Cloud Functions)

- **FR-1** Add `soloPublic` to `StakeChallengeType`
  (`lib/features/accountability/domain/models/stake_challenge.dart`) with storage
  string `'solo_public'`, and add `'solo_public'` to `ChallengeType` in
  `functions/src/stakes/types.ts`. `isMultiParty` stays false for it.
- **FR-2** Add `'public'` to the participant `StakeKind` union on both sides. A
  public participant carries **no** `stakeAmount`, `photoStoragePath`,
  `revealWindowMins`, or charity fields. Escrow/payment modules are not touched.
- **FR-3** Server create validation (`callables.ts`): `solo_public` must reject any
  amount/charity/photo payload; solo → status goes `draft → active` immediately
  (no `pending_accept`).
- **FR-4** Resolution is identical to other solo stakes and server-decided
  (settled: Q2=A): existing sweep/outcome engine, `UNIT_MERCY_PERCENT` and mode
  math apply unchanged, deadline → `pending_verification` (12 h late-sync
  window) → `completed_success` / `completed_forfeit`. Verify the sweep's type
  filters include `solo_public`.
- **FR-5** The mercy veto does **not** apply (nothing to veto); no
  `StakeDonationReceipt` is ever written for this type.

### B. Create flow (`accountability_create_flow.dart`)

- **FR-6** Add `public` to `_StakeChoice` and render it as a fifth card in
  `_availableStakes`, visible in **release** builds. Working copy: title
  "Public commitment", subtitle "Post your promise. Let everyone hold you to it."
- **FR-7** Stake-specific config step: no extra inputs. Instead show a compact
  explainer of the three-card arc (pledge card now → crown card or missed card at
  the deadline), so the user knows what they're signing up for.
- **FR-8** Promise step: the existing 280-char pledge field doubles as the card's
  **motivation note**. Add 3–5 suggestion chips above it (canned notes, e.g. "I'm
  putting in the work today for the future I want tomorrow.") that fill the field
  when tapped; always user-editable. No consent checkboxes (those are money/photo
  concerns).
- **FR-9** Entry points: everywhere the photo stake is reachable today — goal
  detail, accountability hub, stake detail, circle challenges view (settled:
  Q1=A, "add it to goals just like photo stake"). Same goal-linking behavior as
  the other stakes.

### C. Pledge card & sharing

- **FR-10** After the hold-to-commit submit succeeds locally (optimistic mirror
  written), navigate to the **Card Preview screen** showing the pledge card. The
  challenge is already active — the preview must never wait on the network.
- **FR-11** Preview screen: 9:16 shown first, a toggle flips to 1:1; primary
  button **Share** → capture → temp PNG → `share_plus` sheet; a quiet
  "Not now" always exits. No gate on posting (settled: Q3=A) — but the copy
  nudges: e.g. "Share it. Show how much you care about your goals." A skipped
  share changes nothing about the challenge.
- **FR-12** Capture spec: card widget laid out at fixed logical size (360×640
  story, 360×360 square) inside a `RepaintBoundary`, captured with
  `toImage(pixelRatio: 3.0)` → 1080×1920 / 1080×1080 PNG, `textScaler` pinned to
  1.0 inside the card, PNG written to the temp dir and handed to
  `Share.shareXFiles`.

### D. Result cards

- **FR-13** When the Isar mirror's status transitions to a terminal state, the
  challenge detail screen shows a prominent "Your card is ready" CTA →
  Card Preview with the matching result card:
  - `completed_success` → **success card**
  - `completed_forfeit` → **failure card**
  - `completed_surrendered` → **failure card, surrender copy variant** (FR-16)
- **FR-14** Card content (settled: Q4):
  - **Pledge**: "I COMMIT." headline · user display name · goal as "I will
    〈title〉" · "by 〈deadline date〉" · motivation note · "I'm sharing this —
    hold me accountable." footer · SidePal mark.
  - **Success**: "I DID IT." headline · name · "I said: 〈goal〉" (called-shot
    proof) · completion date · stats row: final units `X / Y`, days taken,
    streak (only when it flatters — threshold in OQ-6) · SidePal mark.
  - **Failure**: hero stat first — big `unitsPassed / unitsRequired` — then
    "I didn't finish 〈goal〉", honest-but-dignified line ("A setback, not the
    end."), optional "New date: 〈recommit date〉" (FR-17), SidePal mark.
    **Zero-progress variant**: no stat hero; pure recommit framing ("I said
    〈goal〉. I didn't start. Round two: 〈date〉.").
- **FR-15** Resolution detection is local: the existing watch stream on the
  mirror; on transition to terminal, surface the CTA (push/local notification is
  OQ-1, not v1).

### E. Surrender / goal delete (settled: Q7=B)

- **FR-16** Deleting a goal with a live public stake routes through the existing
  staked-delete dialog (`goal_actions.dart`) with copy: quitting counts as a
  miss. On confirm, `stakeSurrender` is called; the server allows public
  surrender unconditionally (no veto consumed, no money moved), terminal status
  `completed_surrendered`. The failure card (surrender variant) is offered from
  the challenge detail like any result card.

### F. Recommit

- **FR-17** The failure/surrender preview screen carries a **Recommit** CTA →
  reopens the create flow pre-filled (same title, target, measurement kind,
  cadence; fresh date range; public stake preselected). It creates a brand-new
  challenge whose pledge card carries the new date; the old challenge and card
  remain in history untouched.

### G. Card rendering engine

- **FR-18** One `CommitmentCardWidget` with `CardState {pledge, success,
  failure}` (surrender is a copy variant of `failure`, not a fourth state) and
  `CardAspect {story, square}`. The card has **one fixed visual identity per
  state** — it does not follow the user's light/dark theme (it lives on social
  feeds, not in the app). Colors defined once as card tokens built on
  `AppColors` values.
- **FR-19** Backgrounds resolve through a single provider —
  `cardPlate(state, aspect)` — returning a decoration/painter. **v1 ships
  programmatic Flutter-drawn plates** (settled: Q6=B): warm light gradient
  (pledge), deep green/gold (success), near-black/red (failure), matching the
  approved mockups' direction. The AI-art plates (text-free exports of the
  mockups) later replace them as bundled assets — an asset swap behind the same
  provider, no widget changes. Remote/seasonal plates are a further additive
  step, with bundled plates as the permanent offline fallback.
- **FR-20** Text auto-sizes within fixed slots: a 5-word goal and a 280-char
  note must both fit both aspects without overflow. Headlines use a bundled
  condensed display font (e.g. Archivo Black — card-only); everything else uses
  app fonts.

### H. Card history (settled: Q8)

- **FR-21** Cards are **derived, never stored**: the challenge detail screen
  always offers "View card", regenerating the appropriate card from challenge
  data (pledge while active, result once terminal). Re-share works forever, at
  zero storage cost.

## 5. Non-Goals (out of scope)

1. No money, points, escrow, or charity involvement of any kind.
2. No verification that the user actually posted (no social API integration,
   no auto-posting) — the share sheet is the boundary.
3. No h2h/team public variant (solo only in v1).
4. No mid-challenge progress cards (v2 candidate).
5. No stored card images or gallery screen — cards regenerate on demand.
6. No plate marketplace / seasonal art / remote plate delivery in v1
   (architecture leaves the door open via FR-19).
7. No server-side or AI image generation at runtime.

## 6. Design Considerations

- Approved art direction: Miko's three mockups (2026-08-31) — parchment/sunset
  pledge, dark-green + gold crown success, cracked-black + red failure. v1
  approximates them with gradients; final AI plates are text-free re-exports of
  those designs (commercial-use terms of the generator to be confirmed before
  the asset swap ships).
- The three cards are one visual family: same layout skeleton (headline / name /
  goal / date / footer box / SidePal mark), three palettes. Recognizability in
  feeds is the brand asset — the skeleton stays stable across future redesigns.
- Failure card leads with the stat, never the confession — the word "didn't" is
  present but is not the hero when progress exists.
- Preview screen follows the design system (PageTitle chrome, AnimatedSwitcher
  for the aspect toggle ~260 ms); the card itself is deliberately outside the
  theme system (FR-18).

## 7. Technical Considerations

- **Dependencies:** `share_plus ^13.1.0` already in pubspec — no new packages
  for v1. (Save-to-Photos would add `gal` + iOS `NSPhotoLibraryAddUsageDescription`
  — OQ-2.)
- **Local-first compliance:** creation stays optimistic via the existing
  `stakeCreateReplicator` path with the Storage-upload step skipped (no photo).
  Card render + share are 100 % local. No awaited Firestore on any interaction
  path — the architecture guard test must stay green.
- **Server touch points:** `functions/src/stakes/types.ts` (two unions),
  `callables.ts` (create + surrender validation), sweep/outcome type filters.
  The pure outcome engine (measurement/decisions/state_machine) should need no
  logic changes — public resolves like a photo stake with no consequence
  payload. New unit tests prove `solo_public` traverses
  active → pending_verification → both terminals + surrender.
- **Firestore rules/indexes:** none expected (same mirror collection, no new
  queries). Confirm against `documentation/errors.md` before adding any query.
- **Deploy dependency:** functions changes ride the already-pending
  `firebase deploy --only functions` train (see reminder-v2 log entry).
- **Testing:** golden tests for 3 states × 2 aspects (fixed seed data, pinned
  textScaler); widget test for the zero-progress failure variant and surrender
  copy variant; capture smoke test (non-null PNG bytes at expected dimensions).
- **Definition of done (per CLAUDE.md):** create + pledge card + share verified
  in airplane mode; resolution path verified with functions emulator or deployed
  backend; `flutter analyze` clean; full suite passes.

### Suggested implementation phases

1. **P1 — Type plumbing:** FR-1…FR-5 (domain enum, server unions, validation,
   sweep coverage, unit tests). Ships dark — nothing reachable in UI.
2. **P2 — Create flow + pledge card:** FR-6…FR-12, FR-18…FR-20 (fifth card,
   suggestion chips, card widget + programmatic plates, preview screen, share).
3. **P3 — Resolution loop:** FR-13…FR-17, FR-21 (result cards, surrender
   variant, recommit CTA, view-card from detail).
4. **P4 — Art swap & polish:** text-free AI plates as bundled assets, final
   copy pass, OQ-1/OQ-2 if approved.

## 8. Success Metrics

- ≥ 50 % of public-stake creators tap Share on the pledge card preview.
- Success-card share rate exceeds pledge-card share rate (the trophy effect).
- ≥ 25 % of failed public challenges use the Recommit CTA within 7 days.
- Public commitment becomes the most-selected stake type for first-time stake
  users within a month of release.

## 9. Open Questions

- **OQ-1** ~~Local notification when a result card is ready?~~ **RESOLVED
  2026-09-01 (Miko: yes):** `stake_card` intents ride the
  AttentionOrchestrator from the tab shell — once per challenge, only for
  outcomes decided in the last 48 h (fresh installs never replay history),
  `stake:` tap payload lands on Accountability.
- **OQ-2** ~~"Save to Photos" button?~~ **RESOLVED 2026-09-01 (Miko: yes):**
  `gal` + `NSPhotoLibraryAddUsageDescription` + legacy Android write
  permission; Save button beside Share on the preview screen.
- **OQ-3** Final card copy pass + whether cards localize or stay English-only.
- **OQ-4** Display name source: profile display name — fallback when empty
  (first name? omit the name line?).
- **OQ-5** Final list of motivation-note suggestion chips.
- **OQ-6** Streak display threshold on the success card (show only when ≥ N?).

## 10. Settled decisions (do not relitigate)

| # | Decision | Answer (Miko, 2026-08-31) |
|---|----------|---------------------------|
| Q1 | Stake type vs add-on | New `soloPublic` stake type; reachable from goals like the photo stake |
| Q2 | Who resolves | Server, identical to other solo stakes |
| Q3 | Posting gate | None — encourage sharing with copy, never block |
| Q4 | Card content | Name + commitment + motivation note (suggested or user-written) + app-provided date/status/stats |
| Q5 | Formats | 9:16 and 1:1, toggle on preview |
| Q6 | Backgrounds | Programmatic v1, AI-art asset plates later behind same provider |
| Q7 | Surrender/delete | Counts as failure; failure card offered |
| Q8 | Card history | Derived on demand, re-share from challenge detail, nothing stored |
