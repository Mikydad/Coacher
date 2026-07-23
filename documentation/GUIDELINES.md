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
