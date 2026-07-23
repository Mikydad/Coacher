# SidePal Humanizing Features — Implementation PRD (DRAFT v0.3)

> Status: **product decisions settled (Miko, 2026-07-22/23 — `humanizing_answer_1.md` + follow-ups); awaiting final review before implementation.**
> Sources: `humanizing_features_PRD.md` (the three pillars), `humanizing_architecture_suggestion.md`
> (the three-brain vision), a six-agent codebase reconnaissance, a three-architect design panel
> with a three-judge review, and Miko's directives + answers of 2026-07-22/23.
> v0.2 changes vs v0.1: LLM-proposes/engine-disposes timing model, expanded AI role,
> **People & Relationships entity**, labeled (not confirm-gated) inferred memories,
> frictionless intention capture, Siri moved one phase after Voice, the
> "reason continuously" principle, and the Thinking Loop roadmap.
> v0.3 changes: **suggestion-voice nudges** ("what do you think?"), **confirm-at-the-end**
> (delivery suggestion IS the confirmation; responses corroborate/decay inferred hints),
> and explicit network-honesty for AI/chat (network-inherent, per CLAUDE.md principle 3).

## Executive Summary

Turn SidePal's existing deterministic coaching machinery into a humane assistant that
**manages intentions instead of reminders, knows the people in the user's life, remembers,
and can be talked to** — without breaking the app's core contracts: offline-first, one
Coach surface, quiet notifications, and "AI never invents reality."

The design maps the vision's three brains onto seams that already exist:

| Vision brain | Implementation |
|---|---|
| **Truth Engine** | Existing 33 Isar collections **+ three new synced entities**: `IsarIntention` (promises with soft deadline windows), `IsarMemoryFact` (provenance-tagged durable memory), `IsarPerson` (relationships — "Sarah is your sister", not Person #17) |
| **Context Engine** | New `ContextSnapshot` abstraction — starts with zero-permission app-derived signals (schedule, free windows, context modes, notification-engagement history), grows permission-gated signals later |
| **Reasoning AI** | The existing client agent loop through the `aiChat` proxy — extended with purpose routing. **The LLM proposes (with persisted, inspectable recommendations); the deterministic engine validates and decides** |

The flagship v1 moment: the user says *"I need to call my cousin tomorrow"* → SidePal
replies "Got it — I'll find a good time" (no form, no time picker) → the next day a nudge
lands in a genuinely free window with a visible reason ("20 free minutes before Dinner —
good moment to call") — **working end-to-end in airplane mode.**

Platform focus: **iOS-first** (Miko's directive). Android's notification substrate has a
pre-existing defect (Appendix A) and is deferred.

---

## 1. Current State Analysis (verified against the codebase)

### What already exists to build on

1. **A single AI proxy** — Cloud Function `aiChat` (`functions/src/index.ts`), OpenAI
   `gpt-4o-mini` pinned server-side, key in Secret Manager, 40 charged turns/hour/user,
   Remote Config kill switch `ai_enabled` with deterministic mock fallback. No streaming.
2. **A confirm-gated AI write path** — Coach agent loop (≤3 iterations) with
   `propose_changes` (14 action types) → preview card → `AiActionExecutor` → local repos,
   with undo snapshots (`IsarAiActionBatch`). The LLM never writes directly.
3. **A notification decision brain** — `ReminderIntent` → `AttentionOrchestrator.evaluate()`
   (pure Dart: override suppression, ignore back-off, focus boost, collision gap, batching)
   → movable `deliverAt` → OS scheduling + `IsarNotificationLedgerEntry` (per-notification
   delivered/opened/dismissed/snoozed/ignored — a rich engagement signal, currently local-only).
4. **A deterministic pattern pipeline** — Layers 1–4 in `lib/features/analytics/`:
   behavior features per entity incl. `bestTimeBlock` (stored, never yet used to time
   anything), pattern detection, insight generation, per-surface delivery with budgets
   (3/day, 4h gap). LLM only phrases; deterministic renderer as fallback.
5. **Free-window computation** — `AiPayloadAssembler` already computes today/tomorrow free
   windows (07:00–22:00) for the Coach prompt.
6. **Programmatic Coach entry** — `'/coach'` route + `CoachRouteArgs(preDraftedText,
   autoSendMessage, proactiveSuggestionId)`; notification cold-start pending-intent
   queue-then-flush template in `notification_response_handler.dart`.
7. **Voice input** — `speech_to_text` dictation in the Coach input; mic + speech permissions
   already declared on both platforms.
8. **Server cron precedent** — `stakeSweep` runs every 15 minutes in Cloud Functions.

### Issues identified (gaps the vision requires us to close)

1. **No long-term memory** — chat history purged at 48h by design; nothing durable is ever
   learned from conversations. No notes, no promises store, **no notion of people**.
2. **No intention entity** — tasks are schedule-bound, reminders are fixed-clock; neither
   fits "I'll find a good time."
3. **No opportunity-based timing** — every reminder is a user-set clock time.
4. **No background execution and no push** — no `firebase_messaging`, no APNs entitlement,
   no `admin.messaging`, no workmanager/BGTaskScheduler, no `UIBackgroundModes`. All
   intelligence is foreground-only.
5. **No device context** — context is manual (`ContextOverride`) + a daily sleep window.
   No location/activity/calendar/battery packages or permissions. No `permission_handler`.
6. **No voice output, no assistant entry** — no TTS, no App Intents, no shortcuts, no
   deep-link scheme.
7. **Known defects to absorb**: (a) Android manifest lacks every scheduled-notification
   declaration → Android reminders plausibly never fire (deferred — Appendix A);
   (b) `IsarScheduledTimeBlock` is device-local only (no outbox push AND no pull phase);
   (c) two notification producers bypass the orchestrator (goal reminders, stake-invite
   `showNow`; the layer-4 insight dispatch is a foreground Home widget, not a notification
   bypass); (d) the "actionable-message" tier quota semantics in the decision log are
   aspirational — the implementation is a flat 40/hr window.

---

## 2. Design Goals & Non-Negotiables

1. **Intentions over reminders** — the user states what; SidePal picks when. Stating an
   intention IS permission to schedule it (settled: Q1).
2. **Reason continuously, not merely react to commands** *(Miko's principle, added
   verbatim to the design philosophy)*. When the user mentions "visiting my parents this
   weekend," SidePal doesn't demand a command — it forms **standing understanding**
   (dormant observations: maybe flowers, maybe call beforehand) that materializes into a
   suggestion only when a real opportunity appears. No premature reminders; understanding
   first, action at the right moment.
3. **LLM proposes, engine disposes** (settled: Miko's timing model). The LLM has opinions —
   "this is a phone call; Mike usually calls family while walking" — expressed as
   **persisted, provenance-tagged recommendations** (activity tags, timing hints,
   priorities). The deterministic engine validates every recommendation against verified
   context (is he actually free? compatible? within budget?) and makes the final call.
   Recommendations are *data written in advance*, never live LLM calls on the delivery
   path — so timing stays reproducible, auditable, free, and **identical in airplane mode**.
4. **AI is not just a parser** (settled: Miko). The conversational assistant uses the LLM
   fully: coaching, planning, brainstorming, prioritization, conflict resolution, and
   **asking clarifying questions instead of guessing**. Deterministic code owns execution
   and timing; the LLM owns judgment, language, and opinion. SidePal must not become "a
   deterministic system with a friendly voice."
5. **"Don't let AI invent reality" is a mechanism, not a prompt wish** — provenance columns,
   verbatim-quote verification, mem-id grounding, visible labels (§5).
6. **Airplane-mode honest** — capture, planning, delivery, and voice output all work
   offline; AI enrichment is optimistic-then-honest background refinement.
7. **One Coach surface** — everything (voice mode, memory chat, nudge taps, Siri entry)
   lands in the existing three-stage Coach sheet. No new chat surfaces.
8. **Quiet by default** (settled: Q8 — "One. Perfect. Notification."). All new
   notifications flow through `AttentionOrchestrator`; conservative caps; every nudge
   carries a "why now"; one-tap "wrong time" feedback.
9. **Every limit is a Remote Config parameter** (existing decision-log rule) — system AI
   budgets, nudge caps, kill switches.
10. **iOS-first** — Android enablement is a documented, deferred task (Appendix A).

---

## 3. System Design Overview

```
                  ┌───────────────────────────────────────────────────┐
                  │                   TRUTH ENGINE                    │
                  │ existing collections + IsarIntention + IsarPerson │
                  │        + IsarMemoryFact (provenance-tagged)       │
                  └────────┬──────────────────────────┬───────────────┘
        watch streams      │        facts, hints, and │ people, labeled by provenance
                           ▼                          ▼
┌──────────────┐  ┌──────────────────────┐  ┌───────────────────────────────┐
│ CONTEXT      │  │ OpportunityPlanner   │  │ Reasoning AI (client agent    │
│ ENGINE       │─▶│ (pure Dart, runs in  │◀─│ loop via aiChat, purpose-     │
│ ContextSnap- │  │ UnifiedRecompute-    │  │ routed): converses, coaches,  │
│ shot service │  │ Graph) — VALIDATES   │  │ parses, extracts, PROPOSES    │
└──────────────┘  │ every AI proposal    │  │ (persisted hints) — never     │
                  └─────────┬────────────┘  │ executes or schedules         │
                            │               └───────────────────────────────┘
                            │ scored slots (local-only IsarOpportunityPlan)
                            ▼
                  ┌─────────────────────┐
                  │ ReminderIntent kind: │
                  │ intention →          │
                  │ AttentionOrchestrator│──▶ OS notification + ledger
                  └─────────────────────┘
```

**Reasoning locus (decision):** client-orchestrated, permanently, for interactive reasoning.
A thin **deterministic** server rescue-net (cron + push) arrives in Phase 5 solely for the
app-closed case — and its pushes are *advice*: the client re-runs every push through a fresh
`ContextSnapshot` + `AttentionOrchestrator.evaluate()` before anything is shown
(**push-as-advice double-gate**). No server-side LLM agent on the current horizon.

---

## 4. Pillar 1 — Intentions & Opportunity Nudges

### 4.1 The `IsarIntention` entity (new, full sync set)

Registered in `isar_schemas.dart`, outbox entity type `intention`, watch provider, pull
phase in `remote_isar_merge.dart`, LWW on `updatedAtMs`, client `StableId`, tombstone delete.

| Field | Notes |
|---|---|
| `intentionId` | StableId |
| `title` | normalized ("Call cousin Sara") |
| `rawUtterance` | verbatim capture — provenance + future re-parse |
| `personId?` | link to `IsarPerson` when the intention involves someone (§5.5) |
| `windowStartMs` / `windowEndMs` | soft deadline window. **Waking-window defaults**: "tomorrow" → 08:00–21:00, never midnight edges |
| `estimatedMinutes` | duration estimate (parsed or defaulted by kind) |
| `importance` | low/normal/high |
| `activityTags` | compatibility list, e.g. `[call, handsFree]` — may be AI-proposed, engine-validated |
| `aiHintsJson?` | **persisted LLM recommendations** (preferred context, timing hints, priority opinion) — advisory scoring inputs only, provenance-tagged |
| `dependsOnText` / `anchorEntityId` | "before visiting parents" — dormant until resolvable; **better silent than wrong** |
| `locationHintText` | carried but unused until a location phase |
| `status` | open / **dormant** (standing understanding, §2.2) / nudged / done / dismissed / expired |
| `pinnedAtMs?` | user-chosen exact time — **opts out of smart timing entirely; never second-guessed** (settled: Q4) |
| `completedAtMs`, `nudgeCount`, `snoozeCount`, `updatedAtMs` | lifecycle + LWW |

**Planner output does NOT live on this record.** Scored slots go to a **local-only**
`IsarOpportunityPlan` cache (intentionId → slots + `OpportunityReason` + prerendered copy).
Rationale: replans must never bump the synced record's `updatedAtMs`, or whole-record LWW
could clobber a genuine user edit from another device. Derived data stays local; Phase 5
syncs a minimal coarse projection as its own tiny record (§8).

### 4.2 Capture — frictionless (settled: Q1)

Stating an intention is permission. Capture is **auto-committed, not confirm-gated** —
**the confirmation moment moves to the END of the pipeline**: the delivery suggestion
(§4.4) is where the user confirms, by answering "what do you think?" with action,
Later, or "wrong time."

- **High-confidence parse** (clear person/action/window): the intention is written
  immediately; the Coach replies "Got it — I'll find a good time tomorrow" with an inline
  **[View] [Undo]** affordance (undo via the existing `IsarAiActionBatch` snapshot
  machinery). No preview card, no time picker. *(This intentionally relaxes the
  all-AI-writes-confirm-gated rule for the `create_intention` action type only —
  decision-log entry #2. All other action types keep the preview card.)*
- **Ambiguous parse**: the Coach **asks a clarifying question** ("This week or by Friday?")
  rather than guessing — per principle 4. One question max; then capture.
- **Offline**: capture never touches the network — a local heuristic parser handles simple
  forms; anything it can't parse opens the 3-field quick-add sheet (title / window chips /
  kind chips). Optimistic-then-honest: a later background AI refinement may **only fill
  fields the user left empty, re-checked against the current record at write time** —
  never overwrite user edits.
- Also capturable from a plain "+" on the Promises strip (no AI at all).
- **Dormant capture** (standing understanding): conversation extraction (§5.2) may create
  `status: dormant` intentions/observations ("visiting parents this weekend → maybe
  flowers") that generate **zero notifications** until the planner sees a concrete
  opportunity or the user engages them. Dormant items are visible in the Promises strip's
  "on your radar" section — understanding is transparent, never spooky.

### 4.3 The OpportunityPlanner (pure Dart, deterministic — the validator)

A new node in `UnifiedRecomputeGraph` (which finally gives the stubbed notification step a
job). For each open intention, score candidate slots inside the deadline window:

```
score(slot) = w1·freeWindowFit          // FreeWindowCalculator — extracted from
                                        // AiPayloadAssembler into a shared service
            + w2·durationFit            // estimatedMinutes vs window length
            + w3·activityCompatibility  // activityTags vs window type (gap-before-block
                                        // = "waiting", end-of-day = "wind-down", …)
            + w4·bestTimeBlockAffinity  // Layer-1 field finally earns its storage
            + w5·ledgerResponsiveness   // ignores-after-21:00 → penalty (notification ledger)
            + w6·deadlinePressure
            + w7·aiHintAffinity         // persisted LLM/memory hints (aiHintsJson,
                                        // learnedPattern facts) — ADVISORY weight only;
                                        // the engine validates the hint against real
                                        // context before it can influence the score
```

This is Miko's model made concrete: *LLM says "Mike usually calls family while walking" →
engine checks: walking-compatible window, 25 min free, budget OK → approved.* A hint can
tilt a decision; it can never fabricate a slot the deterministic signals don't support.
Every choice carries an explainable **`OpportunityReason`** (mirrors `FocusReason`) that
powers the nudge's "why now" line. Pinned intentions (`pinnedAtMs`) skip scoring entirely.

**Slot ladder & notification budget**: default **two pre-scheduled local alarms** per
intention — *primary* (best score) + *deadline-eve safety* — with a third *fallback* slot
only when the notification budget allows. A new `NotificationBudget` service counts pending
local notifications across ALL producers and keeps headroom under **iOS's hard cap of 64
pending local notifications** (beyond which iOS silently discards). Overflow is absorbed by
the Promises strip (§4.5). Engaged/completed primary cancels siblings via the existing
deterministic-id scheme. Replanning happens on every foreground recompute; staleness is
bounded by last app-open until Phase 5.

### 4.4 Delivery — the suggestion IS the confirmation (settled: Miko, 2026-07-23)

- Planner emits `ReminderIntent(kind: intention, deliverAt: slot)` through
  `AttentionOrchestrator.evaluate()` — inheriting suppression, quiet hours, collision
  spacing, batching, and back-off for free.
- **Nudge voice contract**: every nudge is a **suggestion phrased as a question, never a
  command** — *"I think now's a good time to call your cousin, Mike — what do you
  think?"* — with the "why now" reason available. Never "Reminder: Call cousin."
  The assistant proposes; the user disposes.
- **Confirm-at-the-end feedback loop**: the user's response to the suggestion is the
  confirmation signal. Acting on it (or Done) **corroborates** the signals that chose the
  slot — including any `aiInferred` hints, whose confidence ticks up (toward
  `userConfirmed`-grade trust); Later / "wrong time" / ignore **decays** them and feeds
  the ledger. The confirm chip removed from capture reappears here, at the one moment it
  costs the user nothing.
- **Nudge copy is pre-rendered at planning time** (purpose-routed `phrase_nudge` when
  online; deterministic question-form template otherwise) so the delivery path is 100%
  network- and token-free.
- Notification actions: **Done / Later / Open Coach**, plus one-tap **"wrong time"**
  feedback that writes to the ledger and feeds the planner. iOS notification categories
  are added for this (they don't exist today).
- Caps (all Remote Config): default ≤1 opportunity nudge per intention per day; global
  intention-nudge daily cap. "One. Perfect. Notification." is the bar (Q8).

### 4.5 Ambient surfaces (the no-notification floor)

- **Promises strip on Home**: open intentions with planned slot + reason, plus the
  "on your radar" dormant section. This is the delivery surface when notification
  permission is denied, budget is exhausted, or alarms misfire.
- **Seize-the-moment check on app open**: fresh `ContextSnapshot` → "You've got ~15 free
  minutes before Standup — want to send those photos now?" (in-app card, not a notification).
- **Expired/snoozed intentions become queryable avoidance-truth**: "What have I been
  avoiding?" → "You've pushed the photos to Sam three times." Zero invention.

---

## 5. Pillar 2 — Memory, People & the Conversational Assistant

### 5.1 `IsarMemoryFact` (new, full sync set)

One collection, `kind` enum: `semanticFact` / `preference` / `learnedPattern` /
`episodicSummary` / `promiseNote` / `observation` (standing understanding). Key fields:
`content` (≤200 chars), `structuredJson?`, `personId?`, `provenance`, `confidence`,
`sourceQuote?`, `sourceSessionId?`, `active` (tombstone/deactivate),
`lastReferencedAtMs`, `contradictionCount`, `updatedAtMs`.

**Provenance is the load-bearing column** (settled: Q2 — inferred memories are
**labeled, not confirm-gated**):

| Provenance | How it's written | How it's used |
|---|---|---|
| `userStated` | extraction **with verbatim-quote verification** — the fact must carry a `sourceQuote` that string-matches the transcript, or it is demoted to `aiInferred` | asserted as fact |
| `userConfirmed` | an `aiInferred` fact the user tapped ✓ Correct on (or edited) | asserted as fact |
| `derivedDeterministic` | written ONLY by the Layer-1/2 pattern engine (no LLM) | asserted as observed pattern |
| `aiInferred` | extraction inferences — **auto-saved silently but always labeled "Inferred"**; one tap → ✓ Correct / ✏ Edit / 🗑 Delete | **hedged in conversation** ("seems like you prefer mornings — right?"), **advisory-only in scheduling** (a w7 hint, never a hard constraint), never asserted as certain. **Corroborated or decayed by suggestion responses** (§4.4): acting on a nudge whose slot an inference helped choose raises its confidence; declines/ignores lower it |

*(Note: the design panel's judges preferred confirmation chips before any inferred fact is
saved; Miko explicitly chose labeled auto-save for smoothness. The remaining guardrails —
quote-verification, hedged phrasing, advisory-only scheduling weight, one-tap correction,
full visibility — are therefore mandatory, not optional.)*

**Grounding contract (in the Coach system prompt + renderer):** facts are injected as
`[mem:<id>|<provenance>]`; personal claims **must cite a mem-id**; `aiInferred` mem-ids
must be phrased with hedging or as questions; ungrounded personal claims must be phrased
as questions; grounded claims render with a tappable "from your memory" affordance
linking to the editable fact.

### 5.2 Extraction & retention (settled: Q2)

- Post-conversation, client-triggered, purpose-routed `extract_memory` (temp 0, strict
  JSON, ≤1 call per session end, system budget §7). Extraction also proposes `IsarPerson`
  records and links (§5.5) and dormant observations (§4.2).
- **Summarize-then-purge** replaces the blind 48h delete: raw turns are distilled into an
  episodic summary + fact candidates, then purged at 48h as today. **Failure story**: if
  extraction can't run (offline, AI down, budget out), purge defers up to 7 days, then
  writes a deterministic truncation summary — memory continuity is never silently lost.
- Explicit "remember this" in chat → `remember_fact` action (auto-commit with undo, like
  intentions). `update_fact` / `forget_fact` likewise.
- Contradiction decay: two contradictions deactivate a fact.
- Retention: facts until user-deleted; episodic summaries 90 days then compressed weekly.

### 5.3 "What SidePal knows about you" screen

Ships **in the same phase as extraction — never after** (decision-log entry). Per-fact:
content, provenance badge (with "Inferred" visually distinct), source quote, ✓ Correct
(promotes provenance), ✏ Edit, 🗑 Delete (tombstone). Tabs: **Facts / People / Timeline
(episodic)**. Plus "Forget everything."

### 5.4 Conversational payload changes

`AiPayloadAssembler` gains: active memory facts (provenance-labeled), people digest,
latest episodic summaries, open + dormant intentions. Combined with principle 4, the Coach
now truthfully coaches, prioritizes, and brainstorms over the user's real life — "What
should I work on tomorrow?" reasons over calendar + goals + memory + people.

### 5.5 People & Relationships — `IsarPerson` (new, full sync set; Miko's "big one")

The assistant should know **who** people are, not manage Person #17.

| Field | Notes |
|---|---|
| `personId` | StableId |
| `displayName` | "Sarah" |
| `relationship` | free-form + normalized kind ("sister" → family; "cofounder" → work) |
| `aliases` | "my sister", "Sar" |
| `notesJson?` | small structured facts (birthday if stated, timezone if stated) |
| `provenance` | same enum as memory facts — an inferred relationship is labeled |
| `lastInteractionAtMs` | **derived deterministically** from completed intentions/conversations referencing this person |
| `active`, `updatedAtMs` | tombstone + LWW |

- Created via extraction ("my sister Sarah…" → quote-verified) or explicitly in chat;
  intentions link via `personId` ("Call cousin Sara" → Sara).
- Editable in the People tab of the memory screen. Never synced to any external contacts
  API; an optional device-contact link, if ever added, stays local-only.
- **Relationship-care patterns become a deterministic Layer-2 addition**: "no interaction
  with `family` person in N weeks" → insight candidate → normal delivery machinery. This
  is how *"You haven't talked to your sister in a while"* happens — computed truth, warm
  phrasing, zero invention.

---

## 6. Pillar 3 — Voice

**Settled**: Q5 — voice conversation ships first; Siri entry follows one phase later.
No server transcription for now (on-device STT; revisit with real accuracy data).

- **L1 (exists, polish)**: `autoStartVoice` + auto-send on end-of-speech in the Coach sheet.
- **L2 (the commitment — Phase 3)**: a **Voice Mode state of the existing Coach sheet**
  (one-surface rule): auto-listen → auto-send → reply spoken via `flutter_tts` (on-device
  platform voices) → auto-relisten; tap-to-interrupt. **Sentence-chunked TTS playback**
  masks the non-streaming `aiChat` round-trip. Works offline for output — voice speaks
  even the deterministic mock when AI is down.
- **Siri entry (Phase 4)**: on iOS 16+, a launch-the-app **AppIntent compiled directly into
  the Runner target** — *no* extension target, *no* App Groups, *no* new signing surface
  (judge-verified platform correction). "Hey Siri, talk to SidePal" → cold-start-safe route
  to Coach in Voice Mode via the existing pending-intent template
  (`CoachRouteArgs.startVoiceMode`). Action Button support comes free.
- **L3 (real-time full-duplex streaming) is explicitly deferred** and decision-logged:
  it requires a streaming backend rewrite, realtime audio pipeline, and an
  order-of-magnitude cost jump. Re-evaluate with L2 usage data.
- Android voice entry (shortcuts.xml, widget): deferred with Android generally.

---

## 7. AI Transport, Cost & Quotas (settled: Q3)

- `aiChat` gains a **`purpose`** parameter: `chat` | `parse_intention` | `extract_memory` |
  `phrase_nudge` | `summarize` | *(later)* `reflect` (Thinking Loop, §12). A server-side
  routing table (Remote-Config-driven) maps purpose → model / temperature / max_tokens /
  quota class. Chat stays `gpt-4o-mini` (upgradeable per-purpose by config flip, no client
  release).
- **Only `purpose=chat` charges the user's 40/hr quota.** System purposes draw from a
  separate RC-capped per-user daily budget with **silent-skip** semantics: when exhausted,
  deterministic fallbacks run and *the user never sees a quota error for a call they
  didn't make*.
- Per-purpose kill switches beside `ai_enabled`; per-purpose `aiUsage` telemetry ships
  **with** Phase 2, not after; phrase/extract results cached by `(intentionId, windowHash)`.
- All limits are Remote Config parameters (existing decision-log rule).

---

## 8. Server Rescue-Net (Phase 5 — deferred until local phases prove demand)

- `firebase_messaging` + APNs entitlement; `intentionSweep` cron (15 min, cloned from
  `stakeSweep`) — **pure rules, no server LLM**: "open intention, window closing, no
  client-scheduled slot covers it, user hasn't checked in today" → push.
- **Platform honesty**: data-only pushes are NOT delivered to force-quit iOS apps and are
  throttled in Doze/Low Power — precisely the days-absent scenario the sweep targets. So
  the sweep sends a **notification-type push with a server-composed deterministic title**
  when the device hasn't checked in, with client-side dedupe against locally scheduled
  slots; when the app IS alive, data pushes trigger local replanning through the
  **double-gate** (fresh `ContextSnapshot` + `AttentionOrchestrator.evaluate()` — a push
  can never bypass the attention machinery or fire into a focus override).
- Server visibility comes from a **minimal coarse projection** — its own tiny synced record
  per intention (next planned slot + coverage flag), written only on material change
  (debounced, compared-before-write) so replans never churn the user-edited record.
- Morning brief as push, with the existing local snackbar as the no-push fallback.
- Local multi-slot alarms remain the permanent correctness floor; push only improves timing.

## 9. Context Engine ladder (settled: Q6 — progressive, never everything on day one)

| Tier | Signal | Permission | Phase |
|---|---|---|---|
| 0 | time, schedule blocks, free windows, ContextOverride, connectivity, ledger engagement-by-hour, battery (`battery_plus`, permissionless) | none | 1 |
| 1 | device calendar read-only — **ephemeral `ContextSnapshot` signal only; never merged into synced collections** (judge-rejected: calendar shadows in `IsarScheduledTimeBlock` would replicate calendar data to Firestore) | calendar | 4 |
| 2 | activity recognition snapshots (still/walking/driving) at app-open/decision-time — no background stream | motion | 6 |
| 3 | location: **home-exit geofence only, per-intention opt-in** at capture ("Want me to use your location for this one?"). **Florist honesty rule**: no POI claims until a Places API budget exists — copy says "flowers on the way?", never "you're near a florist" | location | 6 |

One immutable `ContextSnapshot` value object (every field nullable + freshness timestamp),
assembled by a `ContextSnapshotService`, consumed by planner, orchestrator, and
`AiPayloadAssembler`. Raw signals are never persisted and never leave the device — only
coarse labels ("walking", "free_25m") enter AI payloads. Permission asks are just-in-time
with the benefit named; denial is remembered and degradation is scripted copy.

---

## 10. Settled Product Decisions (Miko, 2026-07-22)

| # | Decision |
|---|---|
| Q1 | **Timing autonomy: full.** Stating an intention is permission; SidePal decides the time with no confirmation. Capture itself is auto-committed with undo (§4.2) |
| Q2 | **Memory**: raw chat purged at 48h (via summarize-then-purge); facts/summaries kept, synced, fully visible/editable. **Inferred memories: labeled + one-tap correct/edit/delete — NOT confirm-gated** |
| Q3 | **Separate system AI budget** — background intelligence never consumes chat quota |
| Q4 | **Augment, never replace**: explicit user-set times are never second-guessed (`pinnedAtMs` opts out of smart timing); fixed reminders untouched |
| Q5 | **Voice first, Siri one phase later** — voice conversation is 90% of the value |
| Q6 | **Progressive permissions**: calendar → activity → location; never everything on day one |
| Q7 | **Sign-in stays required** — memory, history, sync, and the assistant all depend on identity |
| Q8 | **Quiet philosophy stands** — "One. Perfect. Notification." |
| + | **LLM proposes, engine disposes** (timing opinions as validated, persisted hints) |
| + | **AI role is broad in conversation** (coach/plan/brainstorm/prioritize/clarify), deterministic in execution |
| + | **People/Relationships are first-class** (`IsarPerson`) |
| + | **"Reason continuously, not merely react to commands"** added as a design principle; standing understanding via dormant intentions/observations |
| + | **Thinking Loop** adopted as the long-term proactivity foundation (§12), post-V1 |
| + | **Nudge voice = suggestion-as-question** ("I think now's a good time… what do you think?"), never a command (2026-07-23) |
| + | **Confirm at the end**: no capture confirmation; the delivery suggestion is the confirmation, and responses corroborate/decay inferred hints (2026-07-23) |
| + | **AI/chat are network-inherent**: they require a connection and say so honestly (CLAUDE.md principle 3); only capture/planning/delivery must work offline (2026-07-23) |

## 11. Implementation Phases (iOS-first)

| Phase | Ships | The user feels |
|---|---|---|
| **0 — Notification bedrock (iOS)** | iOS notification categories (Done/Later/Open Coach + "wrong time"); route goal reminders & stake-invites through `AttentionOrchestrator` **with the passive-goals-get-no-reminders guard**; `NotificationBudget` service (64-cap headroom); implement the stubbed recompute notification step. *(Android → Appendix A, deferred)* | Notification actions work; every nudge respects the same politeness rules |
| **1 — Intentions v1** | `IsarIntention` full sync set; frictionless capture (auto-commit + undo, clarifying questions, offline quick-add); `FreeWindowCalculator` extraction; `OpportunityPlanner` + local-only `IsarOpportunityPlan`; slot ladder via orchestrator; Promises strip; seize-the-moment card; **complete the `IsarScheduledTimeBlock` sync set (outbox + pull phase — Miko directive)**; "why now" + "wrong time" feedback | *"Call my cousin tomorrow"* → "Got it — I'll find a good time" → a well-timed, explained nudge tomorrow — in airplane mode |
| **2 — Memory & People v1** | `IsarMemoryFact` + `IsarPerson` sync sets; purpose routing + system budget (server); quote-verified extraction incl. people + dormant observations; summarize-then-purge (+7-day deferral); labeled-inference UX (✓/✏/🗑); mem-id grounding + "from your memory" affordance; **"What SidePal knows" screen with Facts/People/Timeline (same phase, mandatory)**; payload injection; relationship-care Layer-2 pattern | The Coach remembers last week, knows Sarah is your sister, says "you haven't talked to her in a while" — and everything is inspectable |
| **3 — Voice L2** | Voice Mode on the Coach sheet (`flutter_tts`, sentence-chunked, auto-relisten, tap-to-interrupt); `CoachRouteArgs.startVoiceMode` | A spoken back-and-forth with the assistant that remembers you |
| **4 — Siri + real calendar context** | AppIntent in Runner target ("Hey Siri, talk to SidePal" + Action Button); cold-start routing; `ContextSnapshot` formalized; ephemeral device-calendar signal (in-context ask, nullable degradation); planner prefers pre-meeting micro-gaps | "Hey Siri, talk to SidePal" from anywhere; "a few free minutes before your 2:00 — send those photos now?" refers to your *real* calendar |
| **5 — Alive while closed** | FCM + APNs; `intentionSweep` cron; push-as-advice double-gate; notification-type fallback push; coarse plan projection; morning-brief push | Plans adapt while the phone sits in a pocket; a closing deadline gets one polite save |
| **6 — Rich context (opt-in)** | Activity snapshots; home-exit geofencing per-intention; provenance-honest phrasing ("you're walking"); L3 streaming spike (build/kill decision); Android enablement (Appendix A) when prioritized | "You're walking home with ~20 free minutes — good moment to call your cousin" |
| **7 — Thinking Loop** | §12 | SidePal notices things before you ask |

Every phase is independently shippable, feelable, and airplane-mode-honest (or carries a
named optimistic-then-honest story). Definition of done per CLAUDE.md applies throughout.

## 12. The Thinking Loop (roadmap — Miko's long-term proactivity foundation)

Every so often — locally, quietly — SidePal asks itself: *Given everything I know: did
Mike forget something? Is he avoiding something? Has something changed? Should an
intention move? Does a goal need attention? Has a better opportunity appeared?*

Implementation sketch (post-V1, Phase 7):

- The deterministic layer already "thinks" (UnifiedRecomputeGraph + planner + Layers 1–4);
  the Thinking Loop adds a **budgeted LLM reflection pass** (purpose `reflect`, system
  budget, cached, RC kill switch) over the full picture: facts + people + open/dormant
  intentions + patterns + avoidance history.
- Its output is never an action: it produces **labeled observations and proposals**
  (dormant intentions, hint updates, insight candidates) that flow through the exact same
  validation machinery — planner scoring, attention orchestration, quiet-app caps.
- Runs on foreground recompute at first; Phase 5's sweep/push extends it to app-closed
  moments. The morning brief becomes its natural voice.

This is the architectural seam where "reactive assistant" becomes "someone who quietly
helps run your life" — built on validated proposals, never autonomous action.

## 13. The Three Worked Examples (end-to-end)

1. **"Call my cousin tomorrow"** (Phase 1): parse → auto-commit ("Got it — I'll find a
   good time tomorrow" + Undo) → planner scores tomorrow's free windows (evening gap wins:
   free-window fit + `bestTimeBlock: evening` + ledger says responsive 17–19h + hint
   "prefers calls while walking" if such a fact exists) → primary nudge 17:40 *"You've got
   about 20 free minutes before Dinner — I think now's a good time to call your cousin.
   What do you think?"* + safety slot 20:30 → acting on it cancels the sibling and
   corroborates the hints; Later/"wrong time" decays them; ledger learns either way.
   From Phase 2, "your cousin" resolves to a real `IsarPerson`.
2. **"I promised my friend I'd send those photos this week"** (Phase 1; better at 4):
   window = this week; short duration prefers micro-gaps; from Phase 4, "a few free
   minutes before your 2:00 meeting" uses the real calendar. If it keeps slipping:
   expired/snoozed history makes "you've pushed this three times" a truthful Coach answer.
3. **"I'm visiting my parents this weekend"** (the continuous-reasoning example):
   extraction creates a dormant observation + possible dormant intentions (flowers?
   call beforehand?) — **no reminders yet, just understanding**, visible under "on your
   radar." If the user later says "remind me to buy flowers before visiting," it becomes
   an open intention with a dependency; until Phase 6 the nudge is time-based ("visiting
   your parents later — flowers on the way?"); with per-intention location opt-in it
   becomes a home-exit geofence. Copy never claims a signal we don't have.

## 14. Failure Stories (named, per the DoD)

| Failure | Behavior |
|---|---|
| Airplane mode | Capture via heuristic/quick-add; planning, delivery, TTS all local; AI refinement queues. **AI chat/extraction are network-inherent and honestly say so** — no offline AI emulation beyond the deterministic fallbacks (settled: Miko, 2026-07-23) |
| AI down / `ai_enabled` off | Deterministic parser + template nudges + mock Coach; voice still speaks |
| Ambiguous utterance | One clarifying question; then capture (never guess, never block) |
| System budget exhausted | Silent skip; deterministic fallbacks; never a user-visible quota error |
| User quota exhausted (chat) | Existing behavior unchanged |
| Notification permission denied | Promises strip + seize-the-moment cards carry the feature |
| Exact-alarm unavailable | Inexact delivery — orchestrator windows are minutes-wide anyway |
| Calendar/motion/location denied | Nullable `ContextSnapshot` fields → scoring downgrade, scripted copy, remembered denial |
| Push undeliverable / force-quit iOS | Local slot ladder is the correctness floor; sweep sends notification-type fallback |
| Extraction outage | Purge deferral ≤7 days → deterministic truncation summary |
| Wrong inferred memory | Labeled "Inferred"; hedged in conversation; one tap to correct/delete; contradiction decay |

## 15. Success Metrics

- **Nudge quality**: opportunity-nudge open/action rate vs. existing fixed-time reminders;
  "wrong time" taps per nudge (target < 15% after week 2); intention completion rate.
- **Memory trust**: inferred-fact correction/deletion rate (high deletion = extractor too
  aggressive); ✓-Correct rate; zero ungrounded personal claims in sampled transcripts.
- **People**: % of person-linked intentions; relationship-care nudge action rate.
- **Voice**: Voice Mode sessions/week; Siri-entry cold-start success (Phase 4); median
  round-trip to first spoken syllable.
- **Cost**: system-budget consumption per user/day; cache hit rate on phrase calls.
- **Trust guardrail**: notification-permission revocations and mute events do not rise.

## 16. Decision-Log Entries to Append (documentation/GUIDELINES.md)

1. Intentions are a first-class synced entity; planner output is local-only derived data.
2. Autonomy: stating an intention is permission — `create_intention` auto-commits with
   undo (relaxation of the confirm-gate for this action type only); SidePal moves nudge
   times freely; `pinnedAtMs` opts out; all other AI writes stay confirm-gated.
   **Confirmation happens at the end of the pipeline**: the delivery suggestion, phrased
   as a question ("I think now's a good time… what do you think?"), is the confirmation
   moment — never a command-style reminder.
3. Memory: provenance column + quote-verification; **inferred facts auto-save labeled**
   (not confirm-gated) with hedged phrasing + advisory-only scheduling weight; memory
   screen ships with extraction; summarize-then-purge replaces the 48h delete.
   Suggestion responses corroborate/decay inferred hints (the confirm signal lives at
   delivery, where it costs the user nothing).
4. LLM proposes, engine disposes: LLM timing/priority opinions are persisted hints
   validated by the deterministic planner; no live LLM call on any delivery path; timing
   identical offline.
5. People are first-class (`IsarPerson`), provenance-tagged, never exported.
6. Purpose routing server-side; system AI budget separate from chat quota, RC-configured,
   silent-skip.
7. Exact-alarm posture: `SCHEDULE_EXACT_ALARM` + runtime grant + inexact fallback; **never
   `USE_EXACT_ALARM`** (Play-policy risk).
8. iOS Siri entry = AppIntent in Runner target (no extension, no App Groups); ships one
   phase after Voice Mode.
9. Push is advice: every server push re-evaluated through the orchestrator client-side.
10. Device calendar is ephemeral context; never merged into synced collections.
11. Notification budget: keep pending local notifications under iOS's 64 cap across all
    producers.
12. Design principle: "The assistant should reason continuously, not merely react to
    commands" — standing understanding (dormant, no-notification) is a first-class state.
13. Voice L3 streaming deferred pending L2 usage data. No server transcription for now.
14. Thinking Loop is the long-term proactivity architecture: LLM reflection proposes,
    existing validation machinery disposes.

---

## Appendix A — Android Enablement Note (deferred by directive, 2026-07-22)

Android scheduled notifications are currently non-functional in all likelihood: the app
manifest declares none of the entries `flutter_local_notifications` requires. When Android
is prioritized:

1. Add to `android/app/src/main/AndroidManifest.xml`: `SCHEDULE_EXACT_ALARM` (runtime-grant
   flow on 12+; **do not** ship `USE_EXACT_ALARM` — Play restricts it to alarm/calendar
   apps), `RECEIVE_BOOT_COMPLETED`, and the plugin's three receivers
   (`ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`,
   `ActionBroadcastReceiver` — without them alarm broadcasts have no target).
2. Graceful inexact-alarm fallback when the exact grant is denied.
3. OEM battery-killer reality (Xiaomi/Samsung/Huawei): reconciliation-service audit of
   expected-vs-fired, one-time OEM settings prompt, device test matrix.
4. Then: Android voice entry (static shortcut + mic widget — Google sunset conversational
   App Actions) and `onNewIntent` extras routing (currently logged and dropped).

## Appendix B — Explicitly Rejected / Deferred

- Server-side LLM agent (rejected: duplicates client truth, violates offline-first economics).
- `workmanager`/`BGTaskScheduler` as a load-bearing mechanism (unreliable by design on both
  platforms; at most opportunistic refresh, indefinitely deferred).
- **Live** LLM calls in the timing/delivery path (rejected: timing must be identical
  offline/online — LLM opinions enter only as persisted, engine-validated hints).
- Confirmation chips as a gate on inferred memories (rejected by Miko: labeled auto-save
  with one-tap correction instead; guardrails in §5.1 are mandatory).
- Calendar shadow-merge into `IsarScheduledTimeBlock` (rejected: leaks calendar data into sync).
- Florist/POI geofencing claims (deferred until a Places API budget exists).
- Server transcription (`aiVoiceTranscribe`) — deferred; on-device STT until accuracy data says otherwise.
- L3 streaming voice — deferred pending L2 data.
