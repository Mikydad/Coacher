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

- **2026-07-15 · Insights are gated by data maturity; cold start shows an
  honest warm-up card.** Problem: on a fresh device the pipeline phrased
  day-one data with full authority ("100% consistent!") — it read as
  guessing and burned trust. `DataMaturityEvaluator`
  (`analytics/application/data_maturity.dart`) counts distinct active days
  + events from the analytics log. Thresholds (user decision): entity
  leaves `observing` at ≥3 active days AND ≥5 events, `established` at ≥7
  active days; global `established` at ≥5 active days. Gate lives in
  `InsightGenerationRecomputeService`: observing → no user-facing
  insights; calibrating → only {streakRiskWarning, fragileStreakAlert,
  goalAtRisk} with confidence ≥0.55; global trend insights require global
  established. Survivors are stamped `supportingMetrics.dataMaturity`.
  When Layer 3 yields nothing and global maturity isn't established,
  Layer 4 emits a `FocusReason.learningYourRhythm` warm-up focus (stable
  id `warmup-<dateKey>`, no AI call, no summary cache) whose card says
  "Day X of 5 — I'm learning your rhythm"; X counts *active days with
  data*, not calendar days — honest by design. Warm-up never triggers
  notifications (dispatch keys off insight ids, which are empty).
  *Considered:* silence during warm-up (rejected: blank card reads as
  broken); calendar-days counter (rejected: 5 idle days would "unlock"
  insights with no data).

- **2026-07-15 · Coaching tone is a deterministic framing × style matrix
  (FR-D-13), enforced end-to-end.** `expectedToneFor(framing, style)` in
  `ai_summary_response.dart` replaces the framing-only tone rule: intense →
  assertive everywhere; supportive softens protection/stabilization to
  supportive and consistency to encouraging; disciplined keeps recovery
  informative; the balanced column is exactly the old behavior. The same
  matrix drives the AI prompt's TONE RULE, the response validator (AI
  output contradicting the user's mode is rejected → deterministic
  fallback), and the fallback renderer's tone — the fallback *copy* was
  already style-shifted because the framing × style matrix
  (`deriveCoachingFraming`, FR-D-12) picks which template is looked up.
  Also fixed: `recomputeAiSummaryProvider` derived framing for TTL/summary
  type WITHOUT the user's style while the payload derived it WITH — cache
  freshness and prompt could disagree; both now use the style. The focus
  card's fallback framing (no summary yet) is style-fed too.
