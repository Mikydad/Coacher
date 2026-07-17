# PathPal Guidelines

The working companion to [`CLAUDE.md`](../CLAUDE.md) (which holds the short,
always-enforced rules). This file holds the fuller checklists and the
decision log. It is an index, not a bible — deep content lives where it
already exists:

| Topic | Source of truth |
|---|---|
| Codebase structure & conventions | `documentation/CODEBASE_GUIDE.md` |
| Offline-first architecture & rationale | `OPTIMISTIC_UPDATES_AUDIT.md` |
| Design language (Obsidian Pulse) | `PRD/DESIGN_PRD.md` + `lib/core/presentation/` (AppColors, page_headers) |
| PRD template / task generation | `PRD/create-prd.md`, `PRD/generate-tasks.md` |
| Known pitfalls (Firestore indexes, plugins…) | `documentation/errors.md` |
| Incidents & fixes journal | `documentation/2026-07_features_fixes_and_incidents.md` |
| Business setup (LLC/EIN/bank/Stripe/Apple) | `documentation/PHASE3_BUSINESS_SETUP.md` |

## Feature review checklist

Run through this before implementing anything user-facing:

1. **Problem** — which user problem does it solve, in one sentence?
2. **Principle fit** — which product principle (CLAUDE.md) does it serve?
   If it serves none, question it.
3. **Duplication** — does an existing feature/screen/component already do
   80% of this? Extend before adding.
4. **Offline class** — is it user-own-data (must pass the airplane-mode
   test) or network-inherent (needs the optimistic-then-honest treatment)?
   Decide before writing code.
5. **Consistency** — uses `AppColors`, `PageTitle`/`SectionHeader`, shared
   editor widgets, themed transitions. No new one-off styles.
6. **Navigation** — where does back go from every state it introduces?
7. **Failure story** — what does the user see when its network work fails?
8. **Maintenance cost** — new entity? Then the full local-first set (Isar +
   outbox + watch provider + pull phase) is part of the estimate, not an
   afterthought.
9. **Semantics confirmed** — ambiguous behavior (what a target means, what
   resets when, what carries over) confirmed with the product owner first.

## Decision log

Append-only. Format: date · decision · why · alternatives considered.
A future change that contradicts an entry needs a new entry superseding it —
not silent reversal.

---

- **2026-07-11 · Goal scheduling is a single Repeat system (Off / Daily /
  Weekly / Monthly).** The separate "Schedule" (evaluation period) selector
  was removed; `GoalHorizon` is derived from the repeat cadence, and the
  target is measured per repeat cycle (Off = accumulates over the whole
  goal). *Why:* users could not distinguish evaluation period from repeat
  recurrence — two selectors did "the same thing". *Considered:* separate
  Schedule + Repeat sections (built, then rejected as confusing); a Custom
  recurrence builder (rejected: interval fields cover the real cases).

- **2026-07-11 · Repeat = Off means a passive outcome goal.** No reminders,
  no time blocks, excluded from Home's "Today's goals"; loggable any period
  day from the Goals hub. *Why:* "Read 20 books" is not a routine; the app
  tracks it without scheduling the user's life.

- **2026-07-11 · Tester mode is per-account and registered-only.** Stored
  per uid, cannot be enabled from an anonymous session (anonymous→registered
  keeps the uid, so a device-wide or uid-only flag would leak).

- **2026-07-11 · Circles: browsing is open to guests; joining/creating
  requires a registered account** (`ensureRegisteredForCircleAction` prompt).

- **2026-07-12 · One header hierarchy app-wide.** Page titles are quiet
  small-caps AppBar chrome (`PageTitle`); section headers are the loudest
  in-page text (`SectionHeader`, 18px); micro-labels stay 11px uppercase.
  The PathPal logo appears only on Home. *Considered:* big-bold page titles
  (rejected: competed with content).

- **2026-07-12 · Offline-first contract adopted app-wide** (see
  `OPTIMISTIC_UPDATES_AUDIT.md`): Isar is the source of truth the UI reads
  (watch streams); every write is local + outbox; `RemoteIsarMerge` pulls in
  the background (stale-while-revalidate — render local immediately, update
  when the pull lands); sync UX is silent/quiet/manual. Network-inherent
  features follow the Telegram model. *Considered:* not awaiting Firestore
  `set()` and relying on the SDK's offline queue (rejected: writes become
  invisible — no stuck-writes banner, no queue introspection).

- **2026-07-12 · The awaited-Firestore-write anti-pattern is banned by CI**
  (`test/architecture/local_first_guard_test.dart`). Allowlist contains only
  the outbox flusher (`sync_service.dart`).

- **2026-07-12 · First-launch onboarding sits ABOVE AuthGate; Skip = the
  anonymous account.** `OnboardingGate` (device-level
  `onboarding_completed_v1` prefs flag) shows the 15-step flow
  (`ONBOARDING_PRD.md` + registration step after Welcome) only on fresh
  installs; existing installs (`last_signed_in_uid` or `isar_seeded_v1`
  present) are auto-marked complete. The flow-level Skip just sets the flag
  and falls through — AuthGate's existing silent anonymous sign-in IS the
  skip path (zero new auth code). Registration is a hard gate to continue
  the tour ("for now"; when `REQUIRE_REGISTERED_AUTH` ships, the Skip
  button is what disappears). The flag survives logout on purpose —
  a marketing flow never replays; signed-out users get `AuthLandingScreen`.
  *Considered:* registration at the end of the flow (rejected: registering
  first means every answer lands under the real uid — no anon→registered
  migration); a per-account flag (rejected: replaying marketing at login).

- **2026-07-12 · Onboarding answers are interest TAGS, not auto-created
  goals.** Screen 10's categories + Screen 2's struggles persist in the
  synced `OnboardingProfile` singleton (Isar + outbox +
  `users/{uid}/onboarding/profile` + merge phase, LWW on `updatedAtMs`) for
  later AI/goal-flow consumption. Screen 12's "personalized dashboard" is a
  template render from those tags. The Day One photo stays device-local
  (path + takenAt sync, the file does not — v1). The AI demo (Screen 6) and
  Personalizing (Screen 11) are scripted animations — the whole tour passes
  airplane mode; only Firebase account creation itself needs network.
  *Considered:* seeding real Goal entities from Screen 10 (rejected:
  categories aren't goals — no target/period; vague rows pollute the hub).

- **2026-07-12 · Onboarding visuals: dark-only feature palette
  (`OnboardingColors` aliases `AppPalette.dark` directly).** The flow
  renders before any theme choice exists and DESIGN.md is premium-dark
  only. Premium screen (13) is UI-only — both CTAs advance; IAP is a
  future feature. Illustrations are gradient placeholders pending exported
  artwork.

- **2026-07-15 · Add Task is one page; category is an inline row under
  Notes.** The full-screen category-first bento step was folded into the
  details form: a single horizontally scrolling line of mini bento cards
  (same palette/icons) directly under Notes, tap-to-toggle (tapping the
  selected card clears it — no category is valid), trailing Custom card.
  *Why:* two steps for one optional field slowed the core "jot a task"
  path. *Considered:* keeping the two-step flow (previous implementation
  preserved verbatim in `backups/add_task_screen_category_flow.dart` for
  reversal); wrap-to-grid layout (rejected: one line keeps the form
  compact). The Skip action died with the step.

- **2026-07-15 · Add Task opens as a modal bottom sheet everywhere** —
  create, edit, and Plan Tomorrow slots all go through `showAddTaskSheet`
  (~93% height, drag handle, swipe-down / scrim-tap / X to dismiss). The
  `/add-task` route-table entry is gone; the sheet route keeps the name
  `'/add-task'` via `RouteSettings` so the guided tour and feedback route
  tracker are unaffected. Dismissing mid-entry is safe: the existing form
  draft autosave offers restore on next open. *Why:* task capture should
  feel like a light overlay, not a page navigation — enter, type, slide
  away. *Considered:* sheet for create only (rejected: two presentations
  of one form); half-height opening ~60% (rejected: most saves would need
  an extra drag).

- **2026-07-15 · The Home Coach FAB opens Coach AI as a 60% drag-expandable
  sheet** (`showCoachAiSheet`: opens 60%, snaps 60%/93%, drag below ~45% or
  fling down dismisses; slim grabber header replaces the AppBar in sheet
  mode). ONLY the FAB changed — the Coach bottom-nav tab, morning-brief
  snackbar, and "See all in Coach" still switch tabs (they pass
  `CoachRouteArgs`; the sheet takes none). Conversation state lives in
  providers, so sheet and tab show the same thread. The sheet route is
  named `'/coach'` for the feedback tracker. *Why:* quick AI access without
  leaving the current page. *Considered:* fixed 60% (rejected: cramped with
  keyboard up); full AppBar in the sheet (rejected: chrome eats the 60%).
  *Known trade-off:* snackbars raised from coach actions show on the root
  scaffold behind the sheet.

- **2026-07-15 · Goal template picker reads as a choice, not an info wall.**
  Header is "Pick a goal" (subtitle removed); Study is preselected on open
  (a visibly selected card is what signals "these are selectable"); the
  tapped card stays marked when backing out of the editor. Selection style
  after several iterations: card color untouched, inner white ring inset
  5px with a slow comet sweep (bright highlight + fading tail lapping the
  border every ~4.2s over a dim steady track, custom painter so the glow
  hugs the stroke), check chip top-right, siblings dimmed to 0.82.
  *Considered & rejected:* ink-inversion selected state (too dark), 15%
  ink tint (not visible enough), BoxShadow glow (hazes the whole card
  face), breathing pulse (read as blinking). The comet is angular-speed
  (sweep gradient), so it runs slightly faster on short edges — accepted.
  Animation runs only on the selected card.

- **2026-07-16 · Accountability Stakes: confirmed model locked** (full PRD:
  `PRD/Accountability_feature/prd-accountability-stakes.md`, supersedes
  ambiguities in the original spec). Key semantics, confirmed with the
  product owner over three rounds: two mercy layers (25% within-unit time
  mercy always; 1/month mercy veto, photo-only — **no mercy of any kind on
  money**); solo strictness reuses `RoutineMode` (Flexible ≥70% of units,
  Disciplined ≥85%, Extreme 100%); teams are unanimous-completion with no
  modes (one member's failure loses it — peer pressure is the product;
  both-teams-lose accepted as a common outcome); winners always refunded,
  losers' stakes fund the WINNING side's chosen charity, both-lose goes to
  a mutually-disliked charity picked at creation (app default fallback);
  all charities from the curated admin list, both directions, never free
  entry; photo reveals 5 min–24 h with a 30% hard exposure floor before
  point-based removal (~1–2 weeks of honest earning); screenshot
  enforcement is deter+punish (Android FLAG_SECURE blocks; iOS
  detect-only) — 12 h/3 d/1 wk join-ban ladder + public circle naming;
  evidence is in-app timer + in-app-camera only (no gallery — kills the
  AI/edit-fake vector instead of fighting a detection arms race).
  *Considered & rejected:* team score with 80% threshold (owner initially
  chose it, then deliberately reversed to unanimity); all-stakes-donated
  team pool (violates winner-gets-own-stake-back); free-entry charities;
  AI-image-fake detection at launch.

- **2026-07-16 · Stakes are the app's first sanctioned exception to
  local-first: server-authoritative outcomes.** Deadlines, forfeits, and
  every stake movement (photo reveal, points burn, refund, donation) are
  decided only by Cloud Functions on the server clock — a jailbroken or
  offline client must not dodge a forfeit. Challenge state transitions go
  through callables (optimistic-then-honest UI), NOT the outbox; reads
  stay watch-based via read-only Isar mirrors pulled by `RemoteIsarMerge`;
  evidence (timer sessions, capture metadata) remains normal user-own
  outbox data with a 12 h post-deadline sync-grace before decisions.
  Points ledger + challenge events are append-only and client-write-denied
  in rules. *Why:* stakes move other people's photos/points/money —
  network-inherent class per the feature checklist. *Considered:* outbox
  replication for challenge writes (rejected: fire-and-forget can't carry
  server validation or an authoritative answer).

- **2026-07-16 · Stakes safety set semantics (Phase 1.7).** Blocking is
  hide-from-me only (`users/{uid}/blocked/{buid}`, Isar + outbox + merge,
  LWW row with `active` flag so an unblock beats a stale block from another
  device — never a delete); it filters the circle feed and stake reveals,
  and never affects what others see. Account deletion (existing in-app
  flow) now fires `stakeAccountPurge` (v1 auth onDelete): photos and
  evidence images are deleted unconditionally, non-terminal challenges
  cancel, but terminal challenges KEEP their event history (audit trail,
  CC-3). Photo stakes are 18+ via in-flow attestation checkbox (P-9) —
  the app collects no birthdate; the 17+ store rating is the second layer.
  Support contact = the existing in-app feedback form surfaced as a
  "Contact support" row in Account Settings. *Considered:* full chat/
  message block filtering (deferred — feed + reveals are the stake
  surfaces); deleting blocked rows (rejected: LWW needs the tombstone).

- **2026-07-16 · Points economy semantics (Phase 2).** Ledger:
  `points_ledger/{uid}/txns` append-only, ALL writes via Cloud Functions,
  deterministic txn ids are the idempotency backbone (`earn_task_{id}_{day}`,
  `stake_release_{challengeId}`, …) so replays are structurally no-ops;
  denormalized balance maintained in the same transaction; daily caps live
  on the balance doc's per-day counters (UTC dayKey). Amounts are fixed
  server-side (checkin 5×1/day, task 2×20/day, goal 5×10/day, win 50,
  signup 50; removal 300; h2h stakes 50–1000). **Win bonus pays only when
  some side actually lost** — both-win is refunds-only, so colluding
  friends can't farm the bonus risk-free. Forfeited locks burn silently;
  a zero-amount `stake_forfeit` txn carries {burnedAmount, toCharityId}
  as the audit row for the quarterly charity conversion. H2H escrow locks
  BOTH stakes in the accept transaction (no one-sided commitment); ledger
  effects of a decision commit atomically WITH the status flip (a crashed
  sweep can't strand locked points). Earn wiring is a re-derivation sweep
  (scan today's completed artifacts, fire idempotent grants) instead of
  scattering grant calls through completion paths — offline completions
  self-heal on the next online sweep. *Considered:* client-passed amounts
  (rejected: cheating surface); per-completion grant hooks (rejected:
  N call sites, offline losses); Firestore count() for caps (rejected:
  needs indexes, counters are simpler). *Known softness:* earn sources
  ride on client-owned artifacts, so self-inflation is possible — bounded
  by caps, and points never cash out (§1.1).

- **2026-07-16 · Money layer ships SIMULATED behind a provider abstraction
  (Phase 4 pre-Stripe).** No Stripe account exists yet (see
  `PHASE3_BUSINESS_SETUP.md`), so `PaymentProvider` (charge/refund only —
  §1.1 is enforced by SHAPE: no user-to-user transfer is expressible) runs
  as `SimulatedPaymentProvider`: instant deterministic charges (amounts
  ending in ¢99 decline — the failure-drill hook), real escrow records
  (`stake_escrows/{challengeId}_{uid}`, client-write-denied), real status
  machine (held → refund_pending → refunded | held → disbursement_pending
  → disbursed). Money movement is two-phase everywhere: transactions
  record INTENT atomically with the decision; `processRefundQueue` drives
  provider calls afterwards, idempotently — a transaction retry can never
  double-refund, a crash never strands money. Disbursement is manual
  (admin sets status+receiptUrl on the escrow doc; a trigger posts the
  receipt onto the challenge). solo_money is live end-to-end on this rail;
  client UI is kDebugMode-gated with a SIMULATED banner until Stripe
  activates, at which point a StripePaymentProvider implements the same
  interface and PAYMENTS_PROVIDER=stripe flips it (unknown provider names
  THROW rather than silently simulating). *Considered:* waiting for
  Stripe before building (rejected: the escrow/receipt/refund machinery
  is provider-independent and testable now); provider calls inside the
  decision transaction (rejected: retried transactions + network calls =
  double refunds).

- **2026-07-16 · Progress leaves the bottom nav; Profile hosts it.** Seven
  tabs crowded the watermark nav after Accountability landed, so Progress
  is now a row at the top of Profile's settings card plus the pushed
  '/progress' route (Home's score tile and notification taps push it
  directly). Final tab order: Home, Coach, Goals, Accountability,
  Community, Profile. `feature_guides.dart` now uses `MainTabIndex`
  constants instead of raw ints — the raw 3/4/5 values had silently gone
  stale when the Accountability tab shifted everything, sending "try it"
  taps to the wrong tabs; named constants make the next renumbering a
  compile-time non-event. *Considered:* removing Coach from the nav
  (rejected: it's the product's face); a "More" overflow tab (rejected:
  buries features two taps deep).

- **2026-07-16 · Coach leaves the bottom nav; it's an omnipresent FAB +
  three-stage sheet.** Five tabs remain (Home, Goals, Accountability,
  Community, Profile). The Coach AI button (`CoachAiFab`) sits bottom-right
  on every tab — standalone on Home/Profile, mini satellite stacked above
  the page's own FAB on Goals/Community/Accountability — and carries the
  blocked-plan red dot the nav icon used to. Tapping opens the sheet at
  the ASK-BAR peek (18%: grabber + input, keyboard up — tap → type →
  send); sending from the peek auto-grows to 60%; drag snaps peek → 60% →
  full page (corners square off approaching full — the sheet BECOMES a
  page). Payload flows (morning brief, proactive cards, help sheet, the
  '/coach' route) open at 60% with `CoachRouteArgs` in RouteSettings;
  `openCoachAi()` delivers args in-place when the sheet is already up
  (via the existing coachTabArgsProvider listener) instead of stacking a
  second sheet. Profile also has a "Coach AI" row as the discoverable
  fallback. *Considered:* four stages with 85% (rejected: a thumb-flick
  from full, snaps feel mushy); keeping a full-screen Coach route
  (rejected: one surface, one mental model).

- **2026-07-17 · Coach sheet growth is content-aware.** On any message
  event (open-onto-history, user send, AI reply) the sheet rises to the
  stage the content needs: thread fits the 60% viewport → 60%; overflows
  it (measured via the message list's maxScrollExtent after layout, ~32px
  tolerance) → continue to full page in the same motion. Rise-only, never
  on drags/typing, and a manual drag between messages is respected until
  the next message. *Considered:* message-count heuristics (rejected: two
  long answers ARE "two pages"; five one-liners aren't).

- **2026-07-17 · Accountability creation opens on the category page.**
  Step order is now category (Photo stake / Challenge a friend / Money
  stake (simulated, debug) / Practice) → commitment (title, target,
  days, mode) → type-specific details (skipped for practice) → consent →
  pledge → review. Previously commitment came first with the stake choice
  buried second; the category IS the product decision, so it leads. The
  hub is unchanged: open challenges list when they exist, and Start
  Challenge slides the flow up starting on the categories. Money stays
  simulated/debug-gated until the Stripe adapter lands.

- **2026-07-17 · Optimistic mirror rows carry `updatedAtMs: 0`, never the
  client clock.** For SERVER-OWNED collections (stake_challenges), the
  client's optimistic insert exists only to render instantly; stamping it
  with the device clock let a phone running seconds ahead of the server
  outrank every later server write under LWW — the photo-screening result
  only appeared after a logout wipe. Rule: placeholder rows use 0 so the
  first server echo replaces them, and live snapshot listeners on
  server-owned docs apply unconditionally (no LWW — there is no
  legitimate competing client write). The general pull keeps LWW.
