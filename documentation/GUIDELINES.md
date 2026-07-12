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
