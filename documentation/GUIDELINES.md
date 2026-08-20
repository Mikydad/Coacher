# SidePal Guidelines

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
  The SidePal logo appears only on Home. *Considered:* big-bold page titles
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

- **2026-07-20 · The app is named SidePal everywhere.** Renamed from
  PathPal / "Coach for Life": launcher name (iOS `CFBundleDisplayName`,
  Android `android:label`), splash word, app-bar title, onboarding copy,
  AI system prompt, reminder texts, export subject, MethodChannel
  prefixes (`sidepal/…`, updated on both Dart and native sides), and all
  docs. In a follow-up the internal names went too: Dart package
  `coach_for_life` → `sidepal` (all imports rewritten), Android
  namespace/applicationId `com.example.coach_for_life` → `io.sidepal.app`
  (safe: no google-services.json existed yet, nothing shipped to Play),
  macOS/Linux/Windows/web product names, and desktop binary names.
  Still untouched: the Firebase project id (`coach4life-afaaa`) and the
  repo folder name `Coach_for_life` — both invisible to users.

- **2026-07-20 · Two payment rails, split by Apple's rules, sharing one
  server-side backbone.** Digital entitlements (Pro subscription, points
  packs) go through Apple/Google IAP via RevenueCat; real-money stakes go
  through Stripe (Apple prohibits charitable donations via IAP — Stripe is
  the compliant rail, not a workaround). The rails never mix. Entitlement
  flow: RevenueCat webhook → Cloud Function → `entitlements` on the user
  doc → `RemoteIsarMerge` → Isar watch provider, so premium *checks* are
  offline-first even though the purchase moment is inherently online
  (grace window covers a lapsed cache). Points packs are consumable IAPs
  credited to the ledger by the webhook (`iap_purchase` source), never by
  the client. Build order: subscriptions first (points IAP rides the same
  RevenueCat install behind the existing RC flag), money stakes last
  (gated on LLC/Stripe). *Considered:* raw `in_app_purchase`/StoreKit 2
  (rejected: renewals, refunds, and cross-platform receipt validation are
  weeks of edge cases RevenueCat solves).

- **2026-07-20 · Money challenges carry a transparent Challenge Fee:
  greater of $2 or 7% of the stake, per participant, shown as its own
  checkout line.** The fee is separate from the stake and non-refundable
  once the challenge is active, win or lose: winners get their full stake
  back, losers' full stake is donated — SidePal keeps only the fee either
  way, so revenue is identical regardless of outcome (the business never
  profits from failure). The 7% floor exists because Stripe's cut
  (~2.9% + $0.30, not returned on refunds) is taken on the total charge —
  a flat $2 goes underwater above a ~$58 stake. *Considered:* flat $2
  (rejected: negative margin at higher stakes); flat $2 + $50 stake cap
  (rejected: caps the product to save a pricing rule).

- **2026-07-20 · Challenge Fee is fully refunded if a challenge never
  activates.** Opponent declines, invite expires, or the account-deletion
  cancel path fires before activation → refund stake + fee (full refund
  of the single Stripe charge). Only activation starts the no-refund
  clock. *Considered:* keeping the fee on declined invites (rejected:
  users paying $2 for nothing breeds chargebacks and support load).

- **2026-07-20 · Money challenges are a SidePal Pro feature.** Free tier
  keeps the full core loop: tasks, habits, limited AI planning, photo
  stakes, and points challenges. Pro adds money challenges, unlimited AI,
  advanced analytics, community features, unlimited goals, and future
  premium accountability features. *Why:* money challenges are the
  highest-value accountability tier, the subscription absorbs their
  operating costs (Stripe margins, verification, support), and it gives a
  clear upgrade reason without making the free app feel crippled. Gating
  a Stripe-paid feature behind an IAP subscription is App Store-compliant
  (the subscription sells digital feature access; the stake is a
  real-world transaction).

- **2026-07-20 · Free/Pro tier matrix fixed; full table in
  `PRD/Monetization/prd-monetization-tiers.md`.** Free: 5 tasks, 5 goals
  (challenge-created goals count), 5 active habits, 5 active reminder
  configurations (recurring = 1), 5 actionable AI instructions/day,
  3 photo stakes/month (activated only), membership in 1 circle (max 5
  members), practice challenges, points earning, streaks/notifications/
  widgets/education, basic analytics (streaks, weekly %, calendar, task
  history). Pro ($9.99/mo, $79.99/yr, 7-day trial, store price tiers for
  regions): everything unlimited, 8-member circles, money challenges,
  points H2H/team creation, buy + spend points, advanced analytics +
  export. Mercy veto is free for everyone (1/month; Pro 3/month) — it's
  a safety valve, and paywalling it puts the users who most need it
  without it. *Supersedes:* the earlier same-day call that point buying
  is free-tier — free users had no point sinks, making it a dead SKU;
  buying and spending are now both Pro.

- **2026-07-20 · Only the challenge creator needs Pro (the virality
  rule).** H2H and team challenges, points and money alike: creator must
  have Pro; invitees need only an account (+ verified payment method for
  money) — an invitee is never shown "buy Pro first". A 4v4 needs
  exactly one Pro user. *Why:* the invite-accept flow is the acquisition
  loop; requiring Pro from all 8 turns every challenge into a sales
  call. The Pro trial unlocks points H2H/team but NOT money challenges —
  real charges require an active paid subscription (prevents
  stake-then-cancel abuse; no financial liability on points).

- **2026-07-20 · Downgrade and limit-introduction never destroy user
  state.** Active challenges always run to completion (money is
  escrowed). Over-limit tasks/goals/habits/reminders remain usable;
  creating new ones over the limit requires Pro. Circles: the user
  chooses which one stays active, the rest go read-only. Existing users
  at limits-launch are grandfathered (keep all 12 goals; can't add a
  13th; after deleting down to the cap it binds). Bought points are
  never confiscated — balance persists through downgrade and reactivates
  on upgrade. *Considered:* auto-picking the surviving circle (rejected:
  could silently take the group the user cares about most).

- **2026-07-20 · Free AI quota counts server-classified actionable
  instructions only.** The backend AI tags each user message (greeting /
  chat / action / planning / coaching); only actionable ones consume the
  5/day. Clarify-then-confirm = 1 instruction. Onboarding demo and
  AI-initiated check-ins never count. At 5/5 the conversation does NOT
  hard-stop — action features stop with a soft upgrade line, chat
  continues. Reset at midnight in the user's configured timezone,
  server-side (device-clock changes can't bypass it). Pro "unlimited"
  is a generous internal fair-use token budget, never literally
  unlimited.

- **2026-07-20 · Every tier limit lives in one Remote Config parameter
  (`tier_limits_v1`), not in code.** Single JSON blob holds all caps,
  quotas, fee constants (min $2 / 7%), veto counts. Compiled-in defaults
  + cached RC keep limits resolving offline; Cloud Functions read the
  same parameter via the Admin SDK so client and server never drift —
  anything touching money/stakes/quotas/AI is enforced server-side,
  client checks are UI politeness. Per-user `limitOverrides` on the user
  doc (checked before RC) carries comps, promos, and grandfather flags
  through the same mechanism. Changing any limit = one console edit, no
  release. Extends the existing D9 "RC-tunable launch constant" pattern
  to the whole monetization surface.

- **2026-07-22 · Challenge creation is 3 pages: choose-&-configure →
  promise → review.** Supersedes the 2026-07-17 six-step order (category
  → commitment → details → consent → pledge → review). Category still
  leads — but the chosen card now docks and expands into EVERYTHING:
  stake setup (dropdown-first: circle, reveal window, opponent,
  charities) then the full commitment (title/target/duration/schedule),
  with strictness as a collapsed tile that expands to the three compact
  mode cards (Add-Task pattern) and, for photo stakes, the upload as a
  compact coral tile at the end that grows when the collateral lands.
  Unchosen cards collapse to switch-pills; switching preserves each
  card's typed state. Page 2 "Your Promise" merges pledge + consent:
  write why → read consequences → check boxes → hold ("Before you
  commit" is the human framing; the red card keeps its P-1 severity).
  Practice survives as the fourth, quieter card. Zero system change —
  same state, payloads, callables, gates. *Why:* the six steps read as
  configure/configure/consent/reason/review; three pages tell a story —
  what's on the line → the promise → look it in the eye. (Assessed from
  a ChatGPT proposal; its commitment-first ordering was rejected to keep
  the category-leads decision, its practice-card deletion rejected as an
  onboarding regression.)

- **2026-07-22 · Challenge commitments are goal-shaped: real linked Goal,
  full schedule, future starts.** The accountability commitment step now
  uses the goal editor's own sections (title, target+unit, duration
  range, Daily/Weekly/Monthly schedule with picked days + every-N,
  reminder) and MINTS a real UserGoal (staked badge in the hub via
  `frozenGoal.linkedGoalId`, reminders through the goal machinery,
  counts toward the future goal cap, same tier gate). Challenge units
  became ACTION DAYS: `totalUnits` = action days in the picked range,
  target is per action day, `unitIndexAt` returns -1 on off days (today
  actions hide naturally), day 0 = the picked start date, which may be
  in the future (server allows up to 60 days out, 36h back-grace for tz
  skew). Server measurement stayed pure index math — only creation
  validation and the client calendar→index mapping changed; legacy docs
  (no schedule fields) behave byte-identically to days-since-creation.
  Repeat=Off is rejected for challenges (a stake needs a rhythm to hold
  you to). *Considered:* per-cycle targets for weekly challenges
  (rejected: "3 sessions each picked day" is the product's mental model
  and keeps per-unit mercy intact); staking an EXISTING goal (deferred,
  anticipated by the tier decisions).

- **2026-07-22 · Today's Goals/Habits % scores goals fractionally, per
  cadence (analytics schema v3).** Daily goals contribute proportionally
  (45/60 min → 0.75× weight, judged over the evaluation window so far);
  weekly/monthly goals count only on their action days (mirroring Home's
  Today membership) and are binary "did anything today" (any logged value
  or met cycle → 1.0); repeat-off passive goals contribute their overall
  period progress every day; habit-anchor tasks stay binary. Weighted
  fields became doubles; `completedCount` still means fraction ≥ 1. The
  old formula (goal counts only when the whole CYCLE target's
  metCommitment fired that day) read 0% mid-cycle for weekly goals and
  was never actually specified anywhere. Streak qualification
  (`isStreakQualifyingDay` on weightedCompletionRate) is unchanged and
  now follows the new rates. *Why:* users completing everything Home
  asked still saw "0% today"; the number must reflect what the Today
  surfaces asked of them.

- **2026-07-22 · Goals whose period has ended stay EXCLUDED from
  analytics; the UI stops offering to log them.** The bug behind "old
  goals don't count": analytics filtered by `isDateKeyInPeriod` while
  goal cards used the period-blind `UserGoal.allowsLoggingOn` — an ended
  goal kept a live quick-add card whose check-ins counted nowhere. Now
  cards/counter-sheet use the period-aware helper, ended cards show
  "Ended" instead of their repeat summary, and the detail screen's
  toggle explains ("extend the period from Edit to continue").
  *Considered:* counting active goals past their period end (rejected: a
  30-day challenge that ended should end); auto-archiving at period end
  (rejected for now: silently moving user goals is worse than labeling).
  Also: the analytics bundle's background refresh now LOGS swallowed
  errors — a throwing fresh compute silently freezes the visible numbers
  at the cached snapshot, which is how this class of bug hides.

- **2026-07-21 · Accountability tab badge uses SEEN semantics, not
  done-semantics.** The badge counts badge-worthy items (invite to
  accept, today's evidence due, their-word confirm) the user has not yet
  LOOKED at; opening the challenge's detail screen marks its current
  state seen and drops the count — acting is not required. New state =
  new marker key (`invite_{id}` / `evidence_{id}_{unit}` /
  `confirm_{id}`), so the badge re-arms on genuinely new events,
  including each new day's due evidence. Seen markers are device-local
  per uid (`stake_seen_v1_{uid}`, notification-tray model — a fresh
  install shows pending items as new again). *Considered:* action-based
  clearing (built first; rejected — the badge nagged about things the
  user had consciously deferred); tab-visit clears all (rejected: zeroes
  the badge without the user seeing what was in it).

- **2026-07-20 · Free task cap is per-day; "habits" are Habit Anchor
  tasks.** Tasks in this codebase are per-day planned items, so "5 tasks"
  = 5 tasks planned per day (5 total would be hit in the first session).
  There is no habit entity: "5 active habits" = 5 Habit Anchor tasks per
  day (anchors are their own Tasks-hub section — the closest product
  match). *Considered:* goals in the Habits category (rejected: already
  count against the 5-goal cap, a second cap would be redundant).
  Implementation note: gates are creation-time count checks behind the
  `tier_limits_v1.enforced` kill switch (ships false — never enforce
  limits before the paywall gives an upgrade path); grandfathering falls
  out for free since existing over-limit data is never touched.

- **2026-07-23 · Humanizing feature: product decisions settled in the PRD.**
  The full decision set for the humanizing feature (intentions, memory,
  people, voice) lives in `PRD/humanizing_feature/humanizing_implementation_PRD.md`
  §10/§16 — settled with Miko 2026-07-22/23. Load-bearing ones: intentions
  are a new first-class synced entity (planner output stays in a local-only
  cache — never churn synced records with derived data); LLM proposes /
  deterministic engine disposes (no live LLM call on any delivery path);
  nudges are suggestions phrased as questions, confirmation happens at
  delivery, not capture; inferred memories auto-save labeled (not
  confirm-gated) with hedged phrasing; iOS-first — Android deferred
  (PRD Appendix A has the manifest fix); voice L2 before Siri; system AI
  budget separate from the user's chat quota. *Why:* one pointer entry
  keeps this log readable; the PRD is the source of truth.

- **2026-07-23 · Phase 0: all notification producers route through the
  AttentionOrchestrator.** Goal reminders and stake-invite announcements no
  longer schedule OS notifications directly — they build `ReminderIntent`s
  (entityKind `goal` / `stake_invite`) evaluated by the orchestrator, so
  every notification respects override suppression, collision spacing,
  batching, ignore back-off, and lands in the notification ledger.
  Id/payload/category mapping is centralized in
  `notification_route_resolver.dart` (the orchestrator must never hardcode
  the task shape). Passive (repeat=off) goals still get NO reminders —
  guard unchanged in `goalShouldScheduleDailyReminder`. *Considered:*
  leaving producers direct (rejected: three parallel notification brains,
  and un-ledgered notifications get cancelled as phantoms by boot
  reconciliation).

- **2026-07-23 · Goal reminders are next-occurrence-only (no OS repeat
  matchers).** Each goal pins ONE pending notification (was up to 39: 7
  weekday + 31 month-day + 1 base slots); bootstrap, goal saves, and the
  recompute graph's notification step (throttled `rearmIfStale`, 5 min)
  roll it forward — the pattern interval repeats always used. Trade-off
  accepted: if the app isn't opened for multiple days, later occurrences
  don't fire until next open (the Phase 5 server sweep is the real fix;
  Android was already non-functional). *Why:* the ledger models one active
  notification per entity, and multi-slot repeats alone could exhaust
  iOS's 64-pending cap.

- **2026-07-23 · iOS notification categories are versioned; all actions
  open the app.** Category `sidepalTaskReminder.v1` ships Done / Later /
  Wrong time / Open Coach. iOS treats a shipped category's actions as
  immutable per install — changing them requires a NEW identifier (bump
  `.v1`). Every action carries `foreground` (mirrors Android snooze's
  `showsUserInterface: true`) so responses arrive in the normal foreground
  handler — no background isolate (which has no Isar/Riverpod).
  "Done" respects enforcement: strict/extreme tasks fall through to the
  focus/timer flow instead of completing silently; completions score 100%.
  "Wrong time" is ledgered as `dismissed` (no escalation follow-up) —
  the Phase 1 opportunity planner reads it as timing feedback.

- **2026-07-23 · NotificationBudget guards the iOS 64-pending cap.**
  The orchestrator consults `NotificationBudget` (safety cap 56) before
  scheduling any future notification; exhaustion is an explicit, logged,
  analytics-tracked skip — never the OS silently discarding an arbitrary
  pending reminder. Immediate `showNow` announcements bypass the budget
  (tray, not pending queue). Cap is a code constant for now — it is a
  platform guard, not a user-facing tier limit (those stay Remote Config).

- **2026-07-23 · Phase 1 (Intentions v1): planner output is a local-only
  cache; delivery is slot-scoped.** `IsarIntention` ships the full sync
  set (outbox + pull, soft tombstone `active=false` for LWW-safe deletes);
  `IsarOpportunityPlan` deliberately does NOT sync — it's derived data,
  recomputed per device, keyed by `inputsHash` so unchanged plans never
  churn the OS queue. Each intention gets a ladder of ≤3 slots (0 primary,
  1 deadline-eve safety, 2 optional fallback ≥2h apart; slot 2 only when
  the notification budget allows). Notif ids hash
  `intention:{id}:{slot}` so one fired/cancelled slot doesn't kill its
  siblings; "Done" cancels all slots. `ScheduledTimeBlock` was promoted
  to a full sync set in the same change (planner inputs must agree across
  devices). *Considered:* syncing plans (rejected — free windows are
  device-local reads anyway and syncing derived data churns Firestore).

- **2026-07-23 · Intention capture is auto-commit + undo, not
  preview-confirm.** `createIntention` is the one AI action that skips
  the preview card: the executor pre-assigns the intention id, commits
  immediately, and the chat bubble carries [View] [Undo] (undo deletes
  the intention and cancels its slots via the batch rollback path).
  Offline, `IntentionHeuristicParser` handles "lead-in + action + time
  phrase" utterances through the SAME executor path; anything it can't
  parse opens the 3-field quick-add sheet (what / when-ish / kind — never
  a clock time). *Why:* capture friction kills the habit; a promise is
  low-risk and trivially reversible, unlike schedule mutations.

- **2026-07-23 · Nudge copy is prerendered at planning time.**
  `OpportunityPlanner` is pure Dart (no clock reads, no I/O, no LLM):
  AI hints participate only as persisted `aiHintsJson` with advisory
  weight — a hint can tilt between real candidates, never fabricate a
  slot. Question-form bodies ("…now's a good time to X. What do you
  think?") are rendered into the plan rows, so delivery is 100% network-
  and token-free. Quiet hours are derived from the notification ledger
  (hours with ≥3 ignores and ignores > 2× positive interactions score
  zero responsiveness). Weights are compile-time constants — promote to
  Remote Config only if tuning demands it.

- **2026-07-23 · Phase 2a (Memory & People): provenance is enforced by
  quote verification, not trust.** `IsarMemoryFact` + `IsarPerson` ship as
  full sync sets (outbox + pull, LWW, soft tombstones). A fact or person
  claiming `userStated` must carry a sourceQuote that string-matches the
  transcript (normalized for whitespace/smart quotes only) or the parser
  DEMOTES it to `aiInferred` before it is saved — the model cannot promote
  its own inferences. Unknown stored provenance also reads as `aiInferred`
  (never promote by accident). Explicit "remember this" in chat is
  `userStated` by definition; edits promote to `userConfirmed`. Extraction
  is the only path that creates people; `rememberFact` only links existing
  ones. Local-only `IsarMemorySessionState` tracks per-session extraction
  bookkeeping (derived per-device state — not synced, same reasoning as
  opportunity plans).

- **2026-07-23 · Summarize-then-purge replaces the blind 48h chat delete.**
  Bootstrap now runs `MemoryExtractionService.runMaintenance()` instead of
  `purgeBefore(48h)`: sessions are distilled (facts + people + dormant
  observations + episodic summary, ≤1 extract_memory call per session end)
  before their raw turns purge. If extraction can't run (offline, AI down,
  budget out) the purge DEFERS for that session up to 7 days, then a
  deterministic truncation summary ("Talked about: …",
  `derivedDeterministic`) is written and the turns purge — continuity is
  never silently lost, raw turns never outlive the ceiling. LLM episodic
  summaries are `aiInferred`; only the truncation fallback is
  `derivedDeterministic` (no LLM in that loop). Weekly compression of
  90-day-old summaries is deferred to a later slice.

- **2026-07-23 · aiChat purposes route server-side; system calls never
  touch the user's quota.** The Cloud Function resolves every call's
  `purpose` through a routing table (compile-time defaults in
  `functions/src/ai_routing.ts`, overridable per-field via Remote Config
  `ai_purpose_routes`, models allow-listed so a config typo can't select
  an expensive model). Only user-facing purposes (`coach_agent`, `chat`,
  `coaching_summary`, `circle_pulse`, unknown/legacy) charge the 40/hr
  quota; system purposes (`extract_memory`, `parse_intention`,
  `phrase_nudge`, `summarize`) draw from a separate RC-capped per-user
  daily budget (`ai_system_daily_budget`, default 20/day, UTC window) with
  silent-skip semantics — clients run deterministic fallbacks and the user
  never sees a quota error for a call they didn't make. Per-purpose kill
  switches (`enabled` in the routes JSON) and per-purpose `aiUsage`
  telemetry (`byPurpose.<purpose>.count/tokens`) ship with the phase.
  Remote Config failure falls back to compiled defaults — config can
  degrade the table, never break the proxy.

- **2026-07-23 · Phase 2b: mem-id markers are the ONE exception to
  "no raw IDs in the payload".** Memory facts inject as
  `[mem:<id>|<label>] content` lines; the label collapses provenance to
  what the model needs (`stated` = assert, `observed` = assert as
  pattern, `inferred` = hedge or ask). The model cites `[mem:<id>]` at
  the end of any sentence that uses a fact; the renderer strips markers
  and shows one quiet "From your memory" chip that opens the fact in
  "What SidePal knows". Stored message content keeps the markers (so the
  model sees its own citations in history); only display strips them.
  Memory sections are per-turn, never in the 30s session cache — an
  auto-committed rememberFact must be visible on the very next turn.
  `lastReferencedAtMs` stamping is throttled to 6h per fact so a chatty
  session doesn't spam the outbox. Open + dormant intentions also inject
  ("do NOT create these again") to stop duplicate capture.

- **2026-07-23 · "What SidePal knows" lives under Profile, three tabs,
  all actions Isar-first.** Facts (provenance-badged: STATED/CONFIRMED
  cyan, OBSERVED neutral, INFERRED amber — the label is the trust UI),
  People (name/relationship editable; saving is the strongest correction
  signal → `userConfirmed`), Timeline (episodic summaries, newest
  first). ✓ Correct shows only on non-asserted facts and promotes to
  `userConfirmed` @ 1.0 confidence; ✏ Edit does the same with new
  content; 🗑 Forget is the soft tombstone. "Forget everything" (confirm
  dialog) tombstones every fact AND every person. The chat chip
  deep-links here with the factId as route argument and auto-opens that
  fact's sheet.

- **2026-07-23 · Relationship care is a deterministic Layer-2 addition,
  not a new pipeline.** `RelationshipCareService` (memory feature) runs
  from the recompute graph's layer34 step (6h internal throttle): first
  it derives `Person.lastInteractionAtMs` from COMPLETED intentions whose
  title references the person (monotonic, never LLM-estimated), then for
  family/partner people with a ≥21-day gap it emits
  `PatternCode.relationshipGap` (new `BehaviorEntityKind.person` +
  `PatternGroup.relationshipCare`; deliberately OUTSIDE
  `kLayer2V1PatternCodes` and the hybrid scoring config — it has its own
  deterministic severity: 0.4 at threshold, +0.01/day) and maps it
  through the standard policy (`relationship_care_gap` rule, policy
  version 2→3, `kLayer3V3InsightTypes`). The service personalizes the
  copy ("It's been 4 weeks since you last connected with Sarah (your
  sister)…") and caches it under the person's entity scope — the
  delivery-day loader already merges entity insights, so Layer 4 picks it
  up with zero delivery changes. People with NO recorded interaction emit
  nothing (no baseline → no claim); a completed "Call Sarah" intention
  clears the nudge on the next recompute. *Considered:* wiring people
  into the BehaviorFeatureObject engine (rejected — people have no
  feature cache and the engine's Layer-1 metric contract doesn't apply).

- **2026-07-23 · Voice Mode (Phase 3) is a composer state, not a screen —
  and the loop is a plugin-free state machine.** Voice Mode swaps the
  Coach sheet's input card for an orb card (`VoiceModeCard`); the chat
  thread stays visible behind it (one-surface rule). The loop lives in
  `VoiceModeController` (listen → send → speak sentence-chunked →
  auto-relisten) behind two adapter seams (`VoiceSpeechAdapter` /
  `VoiceTtsAdapter`), so the whole state machine is unit-tested with
  fakes and the plugins (`speech_to_text`, `flutter_tts`) only appear in
  `voice_mode_adapters.dart`. A generation counter guards every async
  hop — interrupt/exit bumps it and in-flight listens/speaks abandon
  themselves instead of clobbering newer state. Utterances travel the
  EXACT same `sendMessage` path as typed text (memory extraction,
  auto-commit, purpose routing all come free); the spoken reply is
  whatever assistant bubble lands — including the deterministic mock and
  honest error copy, so voice output works in airplane mode (on-device
  platform voices, PRD §6). Replies pass through `sanitizeForSpeech`
  (strips `[mem:…]` markers, markdown-lite) then `splitIntoSentences` —
  chunked playback starts instantly and tap-to-interrupt lands between
  sentences. Entry: long-press the existing dictation mic (tap stays
  one-shot dictation) or `CoachRouteArgs.startVoiceMode` — the
  programmatic hook Phase 4's Siri AppIntent will use. Politeness: two
  consecutive silent listens pause the loop to idle ("Tap when you're
  ready") instead of holding the mic open forever; a plan-card reply is
  spoken as "take a look and confirm on screen" (plans stay visual).
  iOS audio: `playAndRecord` category + `defaultToSpeaker` +
  `duckOthers` so STT and TTS share one session. *Considered:* a
  dedicated voice screen (rejected — one-surface rule) and interrupting
  mid-request during `thinking` (rejected — nothing sensible to cancel;
  the reply lands and can be tapped away in one gesture).

- **2026-07-24 · Siri entry (Phase 4a) is an AppIntent in the Runner
  target, and cold start reuses the pending-intent template.** "Hey
  Siri, talk to SidePal" is a `TalkToSidePalIntent` +
  `SidePalAppShortcuts` compiled DIRECTLY into Runner
  (`ios/Runner/SiriVoiceEntry.swift`) — no extension target, no App
  Groups, no new signing surface (judge-verified PRD §6 correction);
  Action Button support comes free. The deployment target stays 13.0:
  everything AppIntents is behind `#if canImport` + `@available(iOS
  16.0, *)`, so older iOS simply has no shortcut. Handoff protocol:
  `perform()` (openAppWhenRun) stamps a UserDefaults pending flag AND
  posts a NotificationCenter event; AppDelegate forwards the event over
  the `sidepal/siri_voice_entry` channel (warm path), and Dart consumes
  the flag **idempotently** (native clears on read) from launch, resume,
  and the event — whichever fires first wins, so the cold-start race
  between `perform()` and Dart's startup consume is harmless. Navigation
  reuses the notification queue-then-flush template: a new
  `coachVoice` pending-intent variant carries
  `CoachRouteArgs(startVoiceMode: true)` through `/coach` →
  `_CoachTabRedirect` → Coach sheet → Phase 3's Voice Mode. *Considered:*
  a deep-link URL scheme (rejected — the pending-intent template already
  solves cold start and adds no new attack/registration surface).
  Verified: `flutter build ios --no-codesign` compiles the Swift +
  pbxproj registration; real-Siri phrase test needs a signed device
  build.

- **2026-07-24 · ContextSnapshot + ephemeral calendar signal (Phase 4b):
  busy intervals only, in-house EventKit, nullable degradation.** The
  Context Engine is formalized as `ContextSnapshot`
  (`lib/core/context/`): an immutable capture where EVERY signal field
  is nullable — null means "signal doesn't exist right now" and
  consumers degrade silently (PRD §9). Snapshots are never persisted;
  only `coarseLabels()` ("free_25m", "next_calendar_event_14:00",
  "mode_focus", "offline") may enter AI payloads (new `deviceContext`
  prompt section). The calendar feed is in-house EventKit
  (`ios/Runner/CalendarSignal.swift`, ~80 lines, same precedent as
  device_info) instead of the device_calendar plugin — the channel can
  ONLY return `{startMs, endMs, allDay}`, so the privacy contract
  (titles/locations/attendees never cross the bridge, never persist,
  never leave the device) holds by construction. iOS 17 write-only
  grants count as denied; all-day events are dropped (a birthday
  doesn't occupy time slots); Android returns "unavailable" and
  everything upstream plans without it. **Consumption:** calendar busy
  joins free-window math as pseudo-blocks titled with coarse time
  labels ("your 14:00") in the nudge planner, seize-the-moment, and
  `ContextSnapshotService.capture` — so nudge copy says "20 free
  minutes before your 14:00" without ever knowing what the meeting is.
  `FreeWindowCalculator` keeps 10–29-minute gaps ONLY when they end at
  a calendar event (pre-meeting micro-gaps); `OpportunityPlanner` adds
  `wPreMeetingGap = 2.5`, scaled by duration-fit, calibrated so a
  fitting quick task prefers the pre-meeting gap over a big open block
  but an ill-fitting one never does. **Ask UX (settled):**
  just-in-time — a one-time card under the Promises strip appears at
  the first open promise (the first nameable benefit), "Not now" is
  remembered forever (tri-state SharedPreferences, device-local BY
  DESIGN — a device permission must not sync); the persistent switch
  lives in Profile ("Calendar-aware timing"), and an OS-level denial
  routes to iOS Settings instead of re-prompting. Granting schedules a
  reminder-scope recompute so promises replan immediately.
  *Considered:* battery/charging in the snapshot (deferred — no
  consumer yet, and battery_plus adds a dep for an unread field);
  syncing the calendar choice (rejected — permission state is
  per-device truth). Verified: 21 new tests (channel-fake service
  semantics, micro-gap retention, planner preference both ways,
  snapshot label shapes), full suite 1,313 green, analyze clean in
  touched files, `flutter build ios --no-codesign` compiles the new
  Swift + Info.plist keys.

- **2026-07-24 · Push transport + coarse projection (Phase 5, slice a):
  the server can see coverage without the plan ever syncing, and a push
  never bypasses the attention gate.** Phase 5 ("alive while closed") is
  sliced three ways; slice (a) lays the transport + visibility floor with
  NO server behaviour yet. `firebase_messaging` added with the iOS
  `aps-environment` entitlement + `UIBackgroundModes: remote-notification`;
  `PushMessagingService` (singleton, every plugin call guarded so it
  no-ops without Firebase/APNs) registers a per-device token doc
  (`users/{uid}/deviceTokens/{deviceId}`, stable id in prefs) and stamps
  an **app-open heartbeat** (`lastSeenMs`, throttled once per local day) —
  the freshness signal the Phase 5b sweep will use to choose a quiet data
  push over a louder notification-fallback push (settled: check-in = app
  foregrounded today). The **coarse projection**
  (`users/{uid}/intentionProjections/{id}` = `{covered, nextSlotMs,
  windowEndMs}`) is the crux: the local `IsarOpportunityPlan` stays
  local-only (syncing it would churn Firestore + leak delivery
  internals), so this tiny mirror answers the ONE thing the server can't —
  *does a client already cover this closing window, and when?*
  Compared-before-write via a `signature` that deliberately excludes
  `updatedAtMs`/`windowEndMs` (those flow through the synced intention
  doc), persisted as `projectionSig` on the local plan row; mirrored only
  on material change, tombstoned on cancel ONLY when one was written
  (the common not-plannable path stays churn-free). A fired slot changes
  coverage without changing the inputs hash, so the projection is
  recomputed even on the plan-unchanged fast-path. Mirror hooks are
  injected (`writeProjection`/`clearProjection`, null in tests) — same
  seam as the Phase 4b calendar feed — so the planner stays framework-
  free. App-alive data push (`{type: intention_replan}`) → `applyAll()`,
  which reschedules through `AttentionOrchestrator.evaluate()`: the second
  gate (overrides, quiet hours, 64-cap) is reused, never bypassed. iOS
  force-quit gets no data push (platform reality) — the background
  handler is intentionally empty and the local alarm ladder remains the
  permanent correctness floor. *Considered:* making the projection a full
  bidirectional synced entity (rejected — it's derived + one-directional
  client→server; a pull phase would re-import stale coverage). APNs key
  upload is a manual console step (deferred by Miko): build/tests/iOS
  compile don't need it, a real device push does. Verified: 13 new pure
  tests (projection coverage/next-slot/signature, payload + heartbeat +
  rescue-detection helpers), full suite 1,326 green, analyze clean in
  touched files, `flutter build ios --no-codesign` compiles the new pod +
  entitlement + Info.plist key.

- **2026-07-24 · Rescue-net sweep (Phase 5, slice b): pure rules, one
  polite save, and the transport picked by platform honesty.** The
  `intentionSweep` cron (every 15 min, cloned from `stakeSweep`'s shape:
  `runIntentionSweepOnce(now)` testable, maxInstances 1) implements the
  PRD §8 rule verbatim — *open intention + window closing (≤24h) + no
  covering client slot + user hasn't checked in today* — with the entire
  policy in a pure module (`functions/src/intentions/rescue_rules.ts`),
  NO server LLM. **Transport choice (settled):** a device seen within
  24h gets a silent data push (`{type: intention_replan}`,
  `content-available`, throttled 6h/intention) — the app replans through
  the attention orchestrator; a days-absent device gets ONE
  notification-type push per window ("Your window to *action* is closing
  — is now a good moment?" — deterministic, question-form, the exact
  client deadline template incl. `asAction` lowercasing), because iOS
  never delivers data-only pushes to force-quit apps. **Politeness is
  server-side too:** clients now report `tzOffsetMinutes` in
  token/heartbeat payloads (refreshed on heartbeat — travel changes it),
  and notification rescues only send inside 09:00–21:00 LOCAL; an
  impolite pass simply retries on a later 15-minute tick. Bookkeeping
  lives in a **server-owned** doc (`users/{uid}/rescueState/{id}` =
  `{lastRescueAtMs, rescuedWindowEndMs, lastDataPushAtMs}`) — NOT on the
  projection, which client outbox upserts would clobber. **Index
  (errors.md #10/#16/#18 lesson):** the collection-group query ranges on
  a SINGLE field (`windowEndMs`, declared `fieldOverride` with
  COLLECTION_GROUP scope in `firestore.indexes.json`); status/active
  filter in memory — no composite. **Client-side dedupe:** foreground
  presentation is `alert: false` and a rescue arriving at (or tapped
  into) a live app just triggers `applyAll()` — the local plan, not the
  push, is truth; repeated rescues collapse via
  `apns-collapse-id: rescue_{intentionId}`; dead tokens are pruned on
  `registration-token-not-registered`. *Considered:* skipping
  checked-in-today users entirely (rejected — the silent data push is
  free and fixes a stale projection the moment the app is alive);
  storing tz as an IANA name (rejected — the offset is enough for an
  hour clamp and never identifies a location more precisely than the
  push token already does). Deploy note: needs `firebase deploy --only
  functions,firestore:indexes` — bundled with the already-pending
  Phase 2a functions deploy. Slice (c) — morning-brief push — remains.

- **2026-07-24 · Morning-brief push (Phase 5, slice c): the push owns
  absent mornings, the snackbar owns opened ones, and the opt-in flag
  rides the deviceTokens doc.** PRD §8's last line ("morning brief as
  push, with the existing local snackbar as the no-push fallback")
  ships as a second 15-minute cron (`morningBrief`, pure rules in
  `brief_rules.ts`, deterministic copy, no LLM): device opted in +
  local clock in **08:00–10:00** (narrower than the snackbar's 06:00 —
  a push at dawn is ruder than a snackbar) + **no app open today on ANY
  device** (`seen_today` skip — the moment a device checks in, the
  server goes quiet and Home's snackbar owns the morning) + **≥1 open
  promise** (a quiet app stays quiet: zero promises → no push) → ONE
  brief per local day ("Good morning — N open promises today — want a
  quick plan?", `apns-collapse-id: morning_brief`). **The flag
  placement is the decision:** `morningBriefEnabled` was Isar-local and
  never synced, so instead of building a whole sync set for one bool it
  is mirrored per-device onto the already-synced deviceTokens doc —
  which is MORE faithful, since the preference never synced between
  devices anyway. Heartbeats refresh it daily, and the Profile toggle
  mirrors immediately (`mirrorMorningBriefEnabled`, fire-and-forget via
  outbox) because waiting for tomorrow's heartbeat would mean a user
  who enables the brief and then doesn't open the app never gets one.
  The cron finds devices via a single collection-group equality on that
  flag (one `fieldOverride`, no composite — errors.md discipline);
  promise counts use a plain single-field equality on the user's own
  intentions (automatic index), active/window filtered in memory.
  Freshness reads ALL devices; the local clock follows the most
  recently seen opted-in device; state is server-owned
  (`users/{uid}/briefState/morning`). **Tap = snackbar parity:** the
  push opens Coach with the suggestions panel + the same pre-drafted
  "Give me a quick plan for today", cold-start-safe via a new
  `_PendingRouteIntent.coachBrief()` (the Phase 4a coachVoice
  template); FCM sends share one `sendToTokens` helper with dead-token
  pruning (extracted from the 5b sweep).   *Considered:* making the whole
  preference record a synced entity (rejected — one bool doesn't
  justify a sync set, and per-user semantics would be WRONG for a
  per-device notification opt-in); sending a contentless brief when no
  promises are open (rejected — nothing to say means silence). Phase 5
  is complete; deploy of functions + indexes remains bundled with the
  pending Phase 2a deploy.

- **2026-07-24 · Phase 6 scoping (settled with Miko) + activity
  snapshots (slice a): a decision-time motion reading that filters and
  phrases, never streams.** Phase 6 ships in two slices — (a) activity
  snapshots, (b) home-exit geofence — with the **L3 streaming spike and
  Android enablement both deferred** (Miko, 2026-07-24). Signals are
  **in-house Swift channels** (calendar-channel precedent), and the
  geofence's "home" anchor will be an **explicit one-time setup**
  stored device-local (inference rejected as magic-with-complexity;
  "current location as home" rejected as silently wrong when enabled
  away from home). Slice (a): `ActivitySignal.swift`
  (`sidepal/activity_signal`) wraps CMMotionActivityManager and can
  ONLY return coarse kind + confidence + query-time timestamp — the
  privacy contract holds by construction; there is NO background
  stream, a reading is taken at decision time. Platform quirk worth
  remembering: Core Motion has no standalone permission API — the
  first history query IS the prompt (`requestAccess` queries a 60s
  window); and `capturedAtMs` is the QUERY time, not the state's
  `startDate` (a 40-minute walk is still a current walk — startDate
  would flunk any freshness check). `ActivitySignalService` mirrors the
  calendar tri-state (undecided/enabled/declined, device-local prefs)
  and degrades to null on: undecided, declined, OS-denied, non-iOS,
  `low` confidence, `unknown` kind, or staler than 15 min — **fresh +
  confident or nothing; a wrong "you're driving" is worse than
  silence**. `ContextSnapshot.activity` (nullable) adds the
  `activity_walking` coarse label to AI payloads automatically.
  **Consumption is decision-time only** (`activity_moment_rules.dart`,
  pure): the planner's window-type compatibility is untouched (future
  slots have no motion); seize-the-moment filters candidates — null/
  still = pre-Phase-6 behavior, walking = only `call`/`handsFree`
  intentions, driving/cycling/running = card suppressed entirely — and
  the card copy says "Looks like you're walking with ~N min free" ONLY
  when a reading exists (provenance honesty). **Ask UX:** just-in-time
  card at the first CALL-shaped open promise (the first nameable
  benefit), gated to never show while the calendar ask is undecided
  (Q6 progressive ladder — permission cards never stack), plus a
  persistent "Motion-aware timing" Profile toggle; OS-level denial
  routes to iOS Settings > Motion & Fitness. Verified: 13 new tests
  (channel-fake service semantics incl. low-confidence/stale
  degradation, snapshot label, moment rules both ways), full suite
  1,342 green, analyze clean in touched files, `flutter build ios
  --no-codesign` compiles the new Swift + NSMotionUsageDescription.
  Slice (b) — home-exit geofence per-intention — is next.

- **2026-07-24 · Home-exit geofence (Phase 6b): ONE region, per-intention
  opt-in, native-fired copy — because the exit event may arrive with no
  Flutter engine alive.** The platform reality drives the whole shape:
  iOS relaunches a force-quit app into the background on a region
  crossing, so the nudge can't wait for Dart. `GeofenceSignal.swift`
  (`sidepal/geofence_signal`) monitors exactly one CLCircularRegion
  ("sidepal_home", 150 m, exit-only) and Dart writes an **armed list**
  (intention id + PRERENDERED copy + window + polite hours 08–22) to
  UserDefaults at arm time; on exit the native side filters (expired →
  dropped, not-yet/impolite → stays armed) and presents UNNotifications
  directly. **Each arm fires at most once**; Dart re-syncs the list on
  every replan (`applyAll` → injected `syncGeofence` hook, same seam
  pattern as `calendarBusy`), so done/expired promises disarm on the
  next app open at latest — a stale fire between opens is the accepted
  failure story, and the time-based ladder remains the correctness
  floor throughout. This native path deliberately bypasses the
  AttentionOrchestrator (it can't be consulted with the app dead); the
  window + polite-hour checks at fire time are the compensating gates.
  **Privacy by construction:** no POI regions, no tracking, no history;
  raw coordinates cross the bridge only during the one-shot home setup
  and live device-local in UserDefaults — never Isar, Firestore, or an
  AI payload. **Florist honesty rule:** copy is "Buy flowers on the
  way?" — a claim about the user's departure, which we measured — never
  "you're near a florist", a POI claim we can't make. **Opt-in is per
  intention and device-local** (prefs set, not the synced record — the
  geofence lives on this device): a "Remind me when I head out" row in
  quick-add for errand-shaped promises runs the enable → explicit
  set-home ladder (`ensureGeofenceReady`, shared with Profile); "Later"
  on home setup keeps the opt-in remembered so arming starts the moment
  home is set. The "Head-out nudges" Profile row completes the ladder
  (subtitle flags "home not set yet"), and **off means off**: decline
  clears the native region AND the armed list. iOS 13 note:
  `manager.authorizationStatus` (instance) is iOS 14+ — use the class
  method behind `#available`, and implement both delegate spellings of
  the authorization callback. Verified: 13 new tests (copy/payload,
  enable/decline, isLive   ladder, syncArmed filter/prune/opt-out), full
  suite 1,355 green, analyze clean in touched files, `flutter build ios
  --no-codesign` compiles the new Swift + both location usage keys.

- **2026-07-24 · Thinking Loop (Phase 7, slice a): one budgeted
  reflection pass per device-day; output is NEVER an action, only
  proposals that ride existing validation machinery.** Scoping settled
  with Miko: two slices — (a) reflection call + parser + proposal
  application, (b) "on your radar" surfacing UX (quiet collapsed row at
  the tail of Promises); all three proposal types allowed; cadence = at
  most once per local day AND only when the durable inputs changed
  ("fresh inputs"). Server: purpose `reflect` (system quota class,
  silent-skip, temperature 0.2, 700 tokens; `enabled:false` via Remote
  Config is the kill switch). Client: `ThinkingLoopService`
  (bootstrap + resume, extraction-service twin) assembles a capped
  snapshot of everything local (`reflection_payload.dart`: ≤30 facts,
  ≤15 people, ≤30 intentions incl. dormant and ≤14-day-expired ones as
  avoidance evidence) and skips via `reflectionInputsHash` — a hash of
  DURABLE identity (ids/status/updatedAt/snooze counts), deliberately
  not the rendered payload, so midnight-relative numbers don't force a
  re-reflection of an unchanged life. Failure = day left unmarked →
  retry next open (extraction's stay-pending pattern).
  **Grounding-or-drop** (`reflection_parser.dart`, the reflection
  sibling of quote verification): every proposal must cite `basedOn`
  ids from the snapshot we sent — the model may connect dots, but only
  OUR dots; ungrounded/malformed proposals drop, never repaired.
  Proposal → machinery mapping: dormant intentions (≤3, title-deduped
  via punctuation-stripped `titleKey` — plain `normalizeForMatch`
  keeps punctuation and let "Call Mom!" duplicate "call mom") become
  `IntentionStatus.dormant` (zero notifications until engaged); hint
  updates (≤5, open+unpinned targets only) merge
  `preferredTimeBlock` into `aiHintsJson`, the advisory input the
  planner already sanity-checks at weight wAiHintAffinity; exactly ≤1
  observation becomes `InsightType.reflectionObservation` (new enum
  ladder: `PatternCode.reflectionSignal`, `PatternGroup/Family
  .reflection`, `BehaviorEntityKind.reflection`, policy v3→4) through
  the standard Layer-3 policy under the synthetic entity scope
  `reflection`, severity 0.3 / confidence 0.6 so it can never outrank a
  deterministic insight, source window today..today so reflections
  don't linger past their day, message = validated AI text labeled
  `aiInferred` in metadata. Verified: 20 new Dart tests (parser
  grounding/caps/dedupe, snapshot relevance + hash semantics,
  mergeHints), 199 functions tests (incl. `reflect` route), full suite
  1,375 green, analyze clean in touched files. Slice (b) — radar row —
  is next; the morning brief becoming the loop's voice is post-slice-b.

- **2026-07-24 · "On your radar" (Phase 7, slice b): a collapsed tail
  row, because standing understandings must never compete with open
  promises.** `OnYourRadarSection` replaces Phase 1's read-only bullet
  list at the tail of Promises (placement settled with Miko: quiet
  collapsed row, not the Coach panel). Collapsed = just
  "ON YOUR RADAR · N" with a chevron; expanded (AnimatedSize, 260 ms
  per the design-system rule that nothing snaps) shows today's
  reflection observation and every dormant intention. Contents and
  their exits: the observation renders the AI message with an
  **INFERRED micro-label** (provenance honesty — same contract as
  memory facts) and an ✕ that clears the `reflection` insight scope;
  it can't linger past its day anyway because slice (a) scoped the
  source window today..today, and the row filters by
  `layer3InsightActiveOnDateKey`. Dormant intentions get exactly two
  quiet exits — **"Remind me"** promotes to `open` via the repo's
  `updateStatus` (synced, LWW) and immediately plans the nudge ladder
  with the returned updated record (Isar-only, airplane-safe), and
  **✕** retires to `dismissed` (synced, so it stays dismissed on every
  device). Zero notifications from anything in this section until the
  user wakes it — the PRD §13 "no reminders yet, just understanding"
  contract, now with the understanding actually actionable. Verified:
  7 new widget tests (hidden-when-empty, collapsed-by-default,
  expansion, yesterday's-observation exclusion, promote → open +
  applyForIntention, dismiss paths for both content kinds via
  noSuchMethod-fakes over the concrete repos), full suite 1,382 green,
  analyze clean. Phase 7 slice (b) closes the humanizing roadmap's
  implementation phases; deferred remainder: L3 streaming spike,
  Android (Appendix A), morning brief as the loop's voice.

- **2026-07-24 · Humanizing audit fix pass — the settled semantics (full
  rationale in `documentation/HUMANIZING_FIXES.md`).** Scope settled with
  Miko: every defect-class audit finding + minimal P1-05 learning loop +
  P1-07 dependency gating; P2-07/08/09 and P3-02 deferred as feature
  work. The decisions that must not be relitigated:
  - **Intention nudge caps: 2 per intention per local day, 4 intention
    nudges per day globally** (values chosen by Miko). Pure policy in
    `intention_nudge_cap_policy.dart`, seeded from ledger delivery claims
    (scheduled + delivered count; the intention's own pending rows don't —
    they're the ladder being replaced). Fails open: caps are politeness,
    not correctness.
  - **`nudged` is a live status.** `Intention.isLive = open || nudged`;
    every surface (planner, Promises, geofence, Coach payload, server
    sweep + brief count) treats the two identically — the distinction is
    observational fuel for reflection/learning, never a behavior change
    the user didn't ask for. Learning semantics: any notification
    response records `nudged` + nudgeCount; "Wrong time" strikes twice →
    drop `preferredTimeBlock` + `registerContradiction()` on the hint's
    `basedOn` facts.
  - **Logout cleanup boundary:** push token deregistration is a direct
    (non-outbox) best-effort Firestore delete — the outbox dies with the
    session, so the guard-test allowlist entry is correct, not a smell.
    Geofence state + thinking-loop cadence prefs are wiped in
    `clearLocalSession()`.
  - **Rules exclusion pattern:** overlapping Firestore allows are OR'd —
    server-owned subtrees (`rescueState`, `briefState`) are excluded
    INSIDE the users wildcard condition
    (`!(collection in [...])`), never via a parallel `write: if false`
    match (which would be dead code). Rules test files each use a
    distinct emulator project id (`node --test` runs files in parallel;
    `clearFirestore()` is project-scoped).
  - **Crons paginate with cursors** (sweep: `orderBy(windowEndMs)`,
    brief: `orderBy(documentId())`), bounded pages per run, next run
    continues — a bare `.limit(n)` is a population cap, not a page size.
    **Send bookkeeping is honest:** rescue/brief state is stamped only
    when `sendToTokens` reports `delivered > 0`.
  - **Reflection observations are radar-only** — filtered out of the
    shared Layer-3 delivery loader at one choke point
    (`isDeliverySurfaceEligible`); the radar row reads the `reflection`
    entity scope directly.
  - **Geofence: `always`-only and single-fire.** `whenInUse` cannot
    deliver background region exits, so it is honestly "not live"; one
    home exit fires only the soonest-deadline armed intent. Native
    notification carries `payload = intention:<id>` (device verification
    pending).
  - **Notification budget fails closed**; **every OS notification goes
    through the AttentionOrchestrator** (the Layer-4 home bridge was the
    last bypass — now `coachInsight` intents through `evaluate()`).
  - **Coach session boundary = sheet close** (`whenComplete` →
    `startNewSession()`); resume runs a ~6h-throttled `runMaintenance()`.
  - **Dependency gating:** non-blank `dependsOnText`/`anchorEntityId`
    ⇒ `isNudgeable == false` (radar-visible, silent); completing an
    anchor auto-promotes dependents by clearing the link in
    `updateStatus(done)`. Free-text dependencies stay gated until edited
    — that IS the standing-understanding contract.
  - **Network honesty:** `AiProxyException.isNetwork` →
    "You're offline…" copy, never generic blame.
  Verified: analyze at the 96-issue baseline (zero errors), 1,411 Flutter
  tests, 204 functions tests, 31 rules tests — all green.

- **2026-08-07 · Voice Mode voice upgrade: OpenAI TTS behind the adapter
  seam (Level 1 — turn-based stays; Realtime speech-to-speech is a
  separate future phase).** Settled with Miko; voice = **coral**.
  - **Transport:** new `aiSpeech` callable (`functions/src/speech.ts`)
    proxies `POST /v1/audio/speech`, model `gpt-4o-mini-tts` — the API
    key never ships in the app. Voice and kill switch are Remote Config
    (`ai_speech_voice`, `ai_speech_enabled`, defaults compiled in);
    unknown voice values degrade to the default (`speech_rules.ts`,
    pure + tested). Quota: speech-scoped sliding hour (90/h) on the
    shared `aiUsage` doc — a voice conversation can never eat the chat
    quota. Text capped at 2,000 chars (a reply is ≤800 tokens).
  - **`VoiceTtsAdapter.speak()` is per-reply now,** not per-sentence:
    chunking is each adapter's own business. flutter_tts chunks
    sentences internally (interrupt lands between sentences); the OpenAI
    adapter synthesizes first-sentence + remainder in parallel and plays
    sequentially, so time-to-first-audio ≈ one short synthesis. A
    tail-only synthesis failure is swallowed (the head was heard;
    falling back would double-speak). New `release()` lifecycle method
    disposes the audio player at session end.
  - **Degradation is silent and floor-guaranteed:**
    `ResilientVoiceTtsAdapter` (pure, tested) tries OpenAI, falls back
    to the on-device system voice on ANY failure, and skips the primary
    for a 60s cooldown after a failure so an offline stretch doesn't pay
    the synthesis timeout every turn. The system-voice floor (and the
    Phase 3 auto-voice-selection) stays — airplane mode still speaks.
  - **Audio session contract** (the earpiece lesson, 2026-07-24):
    audioplayers' global iOS context is set to `playAndRecord` +
    `defaultToSpeaker` + Bluetooth options, same as the flutter_tts
    adapter re-asserts per turn.

- **2026-08-08 · Add Task file split: flows to `add_task/application/`,
  sections to `presentation/sections/`.** `add_task_screen.dart` had grown
  to 2,184 lines (entry points + ~25 form fields + ~1,000 lines of flows +
  ~800 lines of section builders). Split following house idioms — no new
  patterns invented:
  - **Flows are top-level `(BuildContext, WidgetRef, {...})` functions**
    in `lib/features/add_task/application/` (the `planned_task_actions.dart`
    precedent): mode seeding/effective-mode resolution, draft-restore flow,
    edit loader, reminder persistence (+ permission notice), sleep
    side-effects, conflict flow (habit-overlap confirm, time-block check,
    block sync), tier gates, save-target resolution, pure duration-label
    helpers.
  - **Sections are stateless widgets** under `presentation/sections/`
    (values in / callbacks out): sleep extras, advanced, accountability
    row + accountability/deep-work pair, category, duration, reminder.
    Every mutation runs through a State-side `setState` closure, so the
    screen's `setState` override keeps marking the form draft dirty with
    zero changes — that invariant is the load-bearing design rule for any
    future section work.
  - **Deliberately kept in the State** (~915-line screen): `_onSave`
    orchestration (Isar-write → outbox sequencing stays visible in one
    place), `_captureDraft`/`_applyDraft`/`_buildPlannedTask` field
    marshalling, `_applySleepCategoryDefaults` (direct-mutate inside the
    caller's setState), both scroll `GlobalKey`s, seed/load/restore
    wrappers with their `_modeUserCustomized`/`mounted` guard pairs. No
    form controller/Notifier — loose State fields remain the form-state
    convention.
  - Entry points live in `add_task_args.dart` + `add_task_sheet.dart`
    (`AddTaskScreen.routeName` stays on the screen class — the guided tour
    compares `'/add-task'`); the custom-category dialog and accountability
    picker sheet got their own files mirroring `custom_duration_dialog.dart`.
    `add_task_ui.dart` untouched.
  - *Declared micro-changes:* conflict-sheet schedule adjustments (live
    and outcome paths) now funnel through one
    `onAdjustSchedule(DateTime?, int?)` → `_applyAdjustedSchedule` seam
    (two setStates instead of the inline path's one — identical net state
    within a frame, `markDirty` idempotent); draft-restore cancels the
    autosave debounce before (not after) the stored-draft delete;
    swallowed-error debugPrint tags name the new files; the thrice-repeated
    max-orderIndex block deduped into `_nextOrderIndex`.
  - **Safety net built first:** `add_task_screen_smoke_test.dart` (create
    renders, Sleep swaps layout, edit prefills, draft restore) written
    against the untouched screen, kept green through all 7 stages; analyzer
    held at the 96-issue baseline and the full suite (1,430) after every
    stage. Save path has no widget test (tier gates reach
    FirebaseAuth/static-Isar) — guarded by pure code motion + manual pass.

- **2026-08-07 · Voice-turn latency, batch 1: shorter silence window +
  `coach_agent_voice` purpose + warm function instances.** A spoken turn
  paid ~3s silence detection, a chat-length reply generation, and
  occasional 2-3s cold starts. Three cuts, no architecture change:
  (1) `pauseFor` 3s → 1.7s in the speech adapter (ChatGPT-voice pacing;
  `listenFor` 60s unchanged). (2) Spoken turns thread a `voiceMode` flag
  (screen → service → parser → assembler → payload) and go out as purpose
  `coach_agent_voice` with a system-prompt addendum — 1-3 spoken
  sentences, no lists/markdown, tools untouched. Server route caps it at
  500 tokens: the speed comes from the PROMPT (short prose = fewer
  generated tokens), the cap only guards runaways, and 500 keeps headroom
  so `propose_changes` tool JSON is never truncated mid-plan.
  (3) `minInstances: 1` on `aiChat` + `aiSpeech` (few $/month, felt every
  turn). *Why not a lower cap:* tool-call arguments count against
  `max_tokens`; a truncated plan is worse than a slow one. *Considered:*
  streaming/realtime API (deferred — that's the Level-2/3 conversation
  work, this batch is the cheap 40-50%).

- **2026-08-08 · Voice-turn latency, batch 2: streaming TTS
  (`aiSpeechStream` + progressive playback), spike-gated.** The buffered
  callable waited for the whole first-sentence clip before any sound.
  Now `aiSpeechStream` (onRequest) pipes OpenAI mp3 bytes through as they
  arrive and the client plays them from a `GrowingBufferAudioSource`
  (just_audio custom StreamAudioSource, pure and unit-tested) while the
  network is still appending. Device spike gate (Miky, warm turn):
  firstChunk=1072ms — transport PASSED; the remaining audible=3961ms was
  AVPlayer stall-avoidance pre-buffering an unmeasurable chunked stream,
  countered with `setAutomaticallyWaitsToMinimizeStalling(false)` (worst
  case on a bad link is a mid-sentence pause; the text is on screen).
  Contracts that held: POST body carries the text (reply text never in a
  URL — Cloud Run logs paths), client disconnect aborts the upstream
  OpenAI request (tap-to-interrupt stops server spend), same
  `VoiceTtsAdapter` interface so the system-voice floor is untouched,
  and ONE quota pool/RC surface for both transports (`speech_shared.ts`)
  — a voice turn costs the same on either wire. The warm instance moved
  from `aiSpeech` to `aiSpeechStream` (only pay for the critical path);
  the callable stays as fallback for older builds + the `_kStreamingTts`
  A/B flag. Reply-leg instrumentation added ([ai-timing]
  assemble/model/per-round-with-tool-names + [voice-timing]
  reply/firstChunk/audible) because the device numbers showed the AI leg
  (5.3s warm) now dominates — measure before cutting.   *Considered:*
  GET + AudioSource.uri (rejected: text in URL), keeping the buffered
  adapter as a middle fallback tier (rejected: a mid-turn failure should
  degrade instantly to the on-device voice, not retry the network).

- **2026-08-08 · Voice-turn latency, batch 3: keep-alive connection +
  overlapped player prep + server stage ledgers.** The post-fix device
  log had the tell: tts firstChunk tracked the reply leg almost 1:1
  (4061 vs 4197ms, 6503 vs 6707ms) — two unrelated endpoints don't
  coincide like that unless a shared per-request cost dominates. The
  streaming adapter was building a NEW http.Client per speak(), i.e. a
  full TCP+TLS handshake to us-central1 every turn. Now ONE keep-alive
  client lives configure()→release(); interrupts cancel the response
  subscription instead of closing the client (dart:io tears down a
  half-read request's socket on cancel, so the server still sees the
  disconnect and aborts its OpenAI request — the contract survives).
  Also: player prep (setAudioSource — local proxy + AVPlayerItem) now
  runs concurrently with the first-byte wait instead of after it; the
  first-bytes gate stays (a pre-audio failure must throw so the
  resilient wrapper falls back). Server side, aiChat and aiSpeechStream
  log stage ledgers (config/quota/openai ms) — client round time minus
  server total ≈ phone↔server network share, which is the datum for the
  "move regions closer to the user" decision.   *Rule reinforced:* measure
  before cutting; the region question stays open until the ledgers say
  network or OpenAI.

- **2026-08-19 · Voice-turn latency, batch 4: progressive playback was a
  lie — head/tail clips over keep-alive instead; quota runs concurrent;
  RC failures cache.** The batch-3 ledgers convicted the streaming
  playback: audible-minus-firstChunk tracked the server's pipeMs 1:1 on
  every turn (2021/2001, 2135/2114, 1703/1648) — AVPlayer buffers an
  unbounded chunked mp3 to EOF regardless of stall-avoidance, so
  "streaming" was download-then-play with extra steps. Batch 4 stops
  gambling on player internals: the reply splits into HEAD (first
  sentence) and TAIL (rest), both fetched immediately as complete clips
  over the ONE keep-alive connection through the streaming endpoint, and
  `GrowingBufferAudioSource.completed` answers like a file server
  (honest lengths + ranges) so playback starts instantly. Head synthesis
  is short → audible ≈ 1.5-2s warm; the tail downloads while the head
  plays; interrupt discards the tail via the generation counter (an
  interrupted turn wastes one small tail synthesis — accepted). Server:
  the ~0.5s/request quota transaction now runs CONCURRENTLY with the
  OpenAI call on interactive paths (speech + chat user class; system
  budget stays check-first — silent-skip semantics), and both Remote
  Config helpers cache FAILURES with the same TTL as successes (no
  server template is published, so every call had been re-fetching and
  re-failing for ~100-250ms). Warm-turn budget after batch 4 ≈ reply
  ~2.5-3s + audible ~1.5-2s. *Superseded:* batch 2's progressive-stream
  playback claim. *Still open:* Level 2 (streaming chat + sentence
  pipelining) is the remaining architectural cut; region move stays
  parked (network share ~0.9-1.5s/leg, meaningful but not dominant).

- **2026-08-20 · Voice Mode gets a full-screen immersive stage; still one
  Coach surface.** Entering Voice Mode snaps the Coach sheet to its full
  stage and presents orb-only (no transcript, ChatGPT-voice style);
  swiping down / the chevron demotes to the compact voice card at 60%
  with the thread visible — the voice loop keeps running across both
  presentations; X (or the keyboard button) ends Voice Mode back to the
  typed composer. *Why:* the immersive stage is a PRESENTATION of the
  sheet's existing full stage, so the one-surface rule (2026-07-16)
  holds — no new chat screen, same controller, same thread.
  *Considered:* a dedicated full-screen route (rejected: second Coach
  surface, breaks the sheet's drag continuity and CoachRouteArgs funnel).
  Note: Siri's "Open <app>" phrase is OS-owned and cannot launch straight
  into Voice Mode; the claimable phrases are "Talk to SidePal" /
  "Open SidePal voice (mode)" — phrase list lives in SiriVoiceEntry.swift
  and, unlike notification categories, may change freely across updates.

- **2026-08-20 · Voice Level 2 shipped: conversational turns stream
  (aiChatStream) and speak sentence-pipelined; everything else keeps the
  agent path.** Routing lives in `AiAssistantService.tryStreamVoiceReply`
  (the controller's `tryStreamReply` seam, flag `_kStreamingChat` beside
  `_kStreamingTts`): a voice turn streams ONLY when query-classified with
  no pending plan/clarification, no capability/education/unsupported
  fast-path match, no other-day reference (weekday names etc. — the
  stream endpoint has no `get_day_schedule`), and the user isn't a guest.
  The streamed system prompt swaps the tool-preserving voice addendum for
  an ANSWER-ONLY one so a misroute degrades honestly ("say it again as a
  direct request") instead of describing plans nothing will apply.
  The streamed turn owns a live thread bubble (deltas grow it; final text
  is sanitized and saved to interaction history as informational, so
  multi-turn context includes spoken turns). Failure semantics: an error
  BEFORE the first delta falls back internally to the buffered agent path
  and emits that reply as one chunk — the loop always speaks something,
  including honest offline copy; an error after deltas keeps the partial
  text as the reply (transport contract). Interrupt stops SPEECH
  immediately but lets the text reply finish arriving into the thread
  (Resilient tee awaits upstream done before cancelling — accepted: one
  reply's remaining tokens, bounded by the voice route's maxTokens, buys
  a complete bubble, ChatGPT-style). *Known residual:* a remote pull
  already in flight when Voice Mode starts is not aborted and can hit the
  60s RemoteIsarMerge timeout while competing with the first turn (seen
  on-device); the pause gate only defers NEW pulls.

- **2026-08-20 · Siri voice entry hang fixed: mic-open grace delay +
  dead-session listen watchdog.** "Hey Siri, open SidePal voice" opened
  the stage but sat in `listening` forever: Siri foregrounds the app while
  its OWN audio session is still releasing, and `speech_to_text` opened
  into it — a recognizer that hears nothing and emits neither results nor
  'done' (a HEALTHY silent listen self-closes at pauseFor ~1.7s, so
  infinite listening always means a dead session, not a quiet user).
  Fix, two layers: (1) externally-launched entries
  (`CoachRouteArgs.startVoiceMode` → `_enterVoiceMode(externalLaunch:
  true)`) delay the FIRST mic open 900ms (`VoiceModeController.start
  (listenDelay:)`) so Siri's session releases; the stage opens instantly,
  only the mic waits, an orb tap mid-delay listens early. (2) a per-listen
  stall watchdog (`listenStallTimeout` 7s): no result AND no end-of-speech
  → stop + re-listen (stop-triggered 'done' is guarded from finalizing an
  empty utterance), `maxListenStallRestarts` 2, then honest idle ("The
  microphone stalled — tap to try again."). 'listening'-type statuses
  deliberately do NOT disarm the watchdog — dead sessions still emit
  those; only real results do. Self-heals any dead-mic cause, not just
  Siri.

- **2026-08-20 · Clarify-loop + text-only-plan fix: exact param contract,
  ingestion normalization, deterministic clarify merge, degrade repair.**
  Deep check (multi-agent, adversarially verified) of the "What time
  should I schedule it?" infinite loop and plans arriving as prose with no
  Confirm card. THREE confirmed mechanisms, one contract gap underneath:
  (1) the propose_changes schema declared action `parameters` as a bare
  object — no key names anywhere — so the model emitted startTime/"2 pm"/
  "14:00–15:00"-style payloads the missing-field detector (which reads
  only `time`/`duration`/`title`) counted as missing; (2) clarify answers
  ("2 pm") were never merged client-side — merging was delegated 100% to
  the model via a prose block at the very END of a ~200-line prompt, so
  the identical question looped; (3) plan-bearing turns silently degraded
  to informational prose (no tool call / actions parsed empty / only the
  FIRST of two propose_changes calls read), leaving ZERO confirmable state
  — "confirm"/"Perfect" then re-parsed bare and restarted the loop.
  Fixes: exact per-action parameter keys documented in BOTH the tool
  schema and the system prompt; `AiActionParamNormaliser` canonicalizes at
  ingestion (alias keys, "2 pm"→"14:00", range→time+duration, executor
  needs colon-form 24h — "2:00 PM" used to parse as 2:00 AM); the parser
  merges follow-up answers deterministically (local short-circuit when the
  answer completes the plan — no model call — plus a post-model overlay so
  an answered field can never be re-asked); the client merges ALL
  propose_changes calls in a round, decodes double-encoded action arrays,
  answers empty/malformed calls with a tool-error repair round (follow-up
  question on budget exhaustion — NEVER informational plan prose), and
  nudges prose plans on mutate/suggest turns back into the tool call once;
  the service parks suggest-with-no-actions AND plan-shaped informational
  prose as refine context so affirmations always refine instead of
  re-parsing bare. *Refuted during verification:* "first propose_changes
  wins" as the CAUSE of these transcripts (real code fact, fixed as
  hardening, but the observed loops came from mechanisms 1–3).

- **2026-08-21 · Confirm-by-voice: the voice IS the preview card.** On the
  orb-only voice stage the Confirm/Edit/Cancel card is invisible, so plans
  were dead ends by voice ("take a look and confirm on screen"). Now
  `latestSpokenReplyText` reads a pending plan aloud
  (`voice_plan_speech.dart`: per-action prose, "14:00"→"2 PM", duration/
  date speech, 3-item cap) and closes with "Should I go ahead? Just say
  confirm — or no."; suggested drafts append "Want me to set it up?".
  The existing short-reply interceptors were ALREADY the confirm path
  (voice travels the same sendMessage as typing) — the changes are:
  `confirmPlan()` is now AWAITED inside the interceptors (local-first, so
  milliseconds) so the voice loop speaks the execution OUTCOME instead of
  the stale preview, and `_affirmationPattern` gained STT-flavored
  variants (confirmed / go for it / yes confirm). *Semantics preserved:*
  nothing auto-executes; the spoken "confirm" is the user pressing the
  button in the modality they're in — the confirm-gate (2026-07-23)
  stands. No new visual confirm UI on the immersive stage by design;
  the compact card still shows the tappable card.
