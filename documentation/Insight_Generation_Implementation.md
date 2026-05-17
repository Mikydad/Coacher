# Insight Generation Implementation

This document describes the complete behavioral insight pipeline: how raw user
activity is transformed into a single, AI-personalized coaching focus shown on
the home screen. The pipeline has four deterministic layers followed by an AI
summarization step.

---

## Architecture overview

```
Analytics Events  (user completes tasks, timers, goals)
        │
        ▼
┌───────────────────┐
│  Layer 1          │  Feature Builder
│  BehaviorFeature  │  Computes per-entity behavioral metrics
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Layer 2          │  Pattern Detection
│  DetectedBehavior │  Detects behavioral patterns from metrics
│  Pattern          │  9 canonical pattern codes, deterministic scoring
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Layer 3          │  Insight Generation
│  GeneratedInsight │  Maps patterns → structured coaching insights
│                   │  16 insight types across 6 families
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Layer 4          │  Focus Engine
│  CurrentCoaching  │  Selects one highest-leverage focus
│  Focus            │  Anti-thrash logic, full provenance
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  AI-1             │  Coaching Summarizer
│  AiSummaryResponse│  GPT-4o mini personalizes the phrasing
│                   │  Deterministic fallback always available
└────────┬──────────┘
         │
         ▼
   Home screen card / Analytics screen card
```

**Key design principle:** every coaching decision is made deterministically
by the engine. The AI only personalizes the *phrasing* — it never chooses
what to focus on, what tone to use, or what action to recommend.

---

## Layer 1 — Feature Builder

### What it does

Reads raw analytics events stored in Isar and computes a `BehaviorFeatureObject`
for each entity (habit, goal, routine). This is the metric layer — no
interpretation happens here.

### Key files

| File | Role |
|------|------|
| `lib/features/analytics/application/feature_builder_orchestrator.dart` | Coordinates per-entity computation |
| `lib/features/analytics/application/feature_builder_assembler.dart` | Assembles the feature object from raw event streams |
| `lib/features/analytics/application/feature_builder_metrics.dart` | Metric calculation functions |
| `lib/features/analytics/application/feature_builder_input_adapters.dart` | Adapts Isar data to the feature builder input format |
| `lib/features/analytics/domain/models/behavior_feature_object.dart` | Data model |
| `lib/features/analytics/data/feature_cache_repository.dart` | Isar persistence |
| `lib/core/local_db/isar_collections/isar_behavior_feature_cache.dart` | Isar schema |

### Key metrics computed

```
streakMetrics
  ├── currentStreak          (days)
  ├── missedLast2Days        (bool)
  └── missedCount7d          (int)

timeMetrics
  ├── lateCompletionRate7d   (0–1)
  ├── avgCompletionDelayMinutes
  ├── scheduledOccurrences7d
  ├── flexCompletionFrequency7d
  └── missedScheduledCount7d

effortMetrics
  └── avgSnoozeCount

goalMetrics
  ├── progress               (0–1)
  ├── expectedProgress       (0–1)
  └── gap                    (signed delta)

contextFeatures
  └── bestTimeBlock          (morning/afternoon/evening/lateNight)

layer1
  └── completionSignal7d     (0–1 composite)
```

### Recompute trigger

`FeatureBuilderRecomputeService` is invoked by `layer34RecomputeNowProvider`
whenever the user taps the refresh button on the analytics screen, or at
scheduled intervals in the background.

---

## Layer 2 — Pattern Detection

### What it does

Reads `BehaviorFeatureObject` records and applies deterministic threshold logic
to detect which behavioral patterns are active for each entity. The output is a
`DetectedBehaviorPattern` — a canonical, stable record with severity, confidence,
and metric evidence.

### Pattern taxonomy

There are **9 canonical pattern codes** organized in 5 families:

| Family | Pattern Code | Trigger condition |
|--------|-------------|-------------------|
| `streakConsistency` | `streakRisk` | Recent gaps + low 7d adherence |
| `streakConsistency` | `strongStreak` | Current streak above strong threshold |
| `streakConsistency` | `inconsistentBehavior` | 7d completion signal below low band |
| `timeBehavior` | `lateBehavior` | Late-completion rate above threshold |
| `timeBehavior` | `timeMisalignment` | Observed time block ≠ scheduled time block |
| `effortDifficulty` | `tooHard` | Very low completion + elevated snooze pressure |
| `effortDifficulty` | `lowEngagement` | Elevated snooze + weak completion |
| `goalAlignment` | `goalProgressDrift` | Goal progress lags expected trajectory |
| `behavioralStability` | `scheduleRhythmVolatile` | High ratio of missed scheduled days |

### Scoring

All scoring is **deterministic** — no randomness, no ML. Two values are
computed for each detected pattern:

- **severity** (0–1): how bad/strong is the signal?
- **confidence** (0–1): how reliable is the evidence?

Both are computed by `computeHybridSeverity` / `computeHybridConfidence` in
`pattern_scoring.dart` using threshold-based rules tagged with stable rule IDs
(`layer2_hybrid_v1`, `layer2_hybrid_confidence_v1`).

### Global snapshot

At the end of each Layer 2 run, a `GlobalBehaviorPatternSnapshot` is emitted
summarizing patterns across all entities. This feeds Layer 3's global insight
types (`overloadTrend`, `improvingConsistency`, `unstableRoutinePattern`).

### Key files

| File | Role |
|------|------|
| `lib/features/analytics/application/pattern_detection_engine.dart` | Core threshold logic per entity |
| `lib/features/analytics/application/pattern_detection_orchestrator.dart` | Cross-entity orchestration |
| `lib/features/analytics/application/pattern_scoring.dart` | Deterministic severity/confidence functions |
| `lib/features/analytics/application/pattern_aggregate_builder.dart` | Builds `GlobalBehaviorPatternSnapshot` |
| `lib/features/analytics/domain/models/detected_behavior_pattern.dart` | Canonical model |
| `lib/features/analytics/domain/models/pattern_taxonomy.dart` | `PatternTaxonomySpec` registry |
| `lib/features/analytics/data/pattern_detection_repository.dart` | Isar persistence |

### Compatibility layer

`pattern_layer2_compatibility.dart` provides adapters that convert
`DetectedBehaviorPattern` (Phase 2) into the legacy `DetectedPattern` format
(Phase 1) so older Layer 3 consumers continue to work during migration.

---

## Layer 3 — Insight Generation

### What it does

Maps `DetectedBehaviorPattern` records into `GeneratedInsight` objects — the
structured coaching signal. Each insight has a type, bucket (risk/neutral/
reinforcement), priority, message, recommended action, and lifecycle state.

### Insight types (16 total)

**Risk / warning insights** (bucket: `risk`)
| Type | Trigger |
|------|---------|
| `streakRiskWarning` | `streakRisk` pattern |
| `habitTooHard` | `tooHard` pattern |
| `timingMisalignment` | `timeMisalignment` pattern |
| `goalAtRisk` | `goalProgressDrift` pattern |
| `latePattern` | `lateBehavior` pattern |
| `inconsistencyNotice` | `inconsistentBehavior` pattern |
| `lowEngagementNotice` | `lowEngagement` pattern |
| `fragileStreakAlert` | `streakRisk` + urgency signal |

**Reinforcement / praise insights** (bucket: `reinforcement`)
| Type | Trigger |
|------|---------|
| `strongStreakPraise` | `strongStreak` pattern |
| `consistentBehaviorPraise` | High 7d completion signal |
| `goalProgressSuccess` | Goal progress on or ahead of trajectory |
| `improvingConsistency` | Global: completion trending up |

**Focus-oriented insights** (bucket: `neutral`)
| Type | Trigger |
|------|---------|
| `highestMomentumLeverage` | Best leverage opportunity across entities |
| `bestRecoveryOpportunity` | Entity with highest recovery potential |

**Global coaching insights** (bucket: `neutral`)
| Type | Trigger |
|------|---------|
| `overloadTrend` | Multiple entities showing `tooHard`/`lowEngagement` |
| `unstableRoutinePattern` | Multiple entities with `scheduleRhythmVolatile` |

### Insight model fields

```dart
GeneratedInsight {
  insightId             // stable UUID
  insightType           // one of the 16 types above
  insightBucket         // risk | neutral | reinforcement
  priority              // high | medium | low
  urgency               // 0–1 time-sensitivity
  coachingImportance    // 0–1 strategic significance
  confidence            // 0–1 evidence reliability
  lifecycleState        // generated → active → reinforced → resolved/archived
  message               // human-readable coaching message
  action                // doNow | reschedule | reduceIntensity | focus | ...
  linkedPatternCodes    // which Layer 2 patterns triggered this
  supportingMetrics     // key evidence for explainability
}
```

### Cooldown and resolution

`InsightCooldownPolicy` defines how long after an insight fires before it can
re-fire for the same entity. `InsightResolutionRule` defines when an insight
auto-resolves (e.g. streak recovered, goal back on track).

`InsightPostProcessor` applies lifecycle transitions during each recompute pass.

### Key files

| File | Role |
|------|------|
| `lib/features/analytics/application/insight_generation_orchestrator.dart` | Main entry point |
| `lib/features/analytics/application/insight_mapping_engine.dart` | Pattern → insight mapping rules |
| `lib/features/analytics/application/insight_generation_policy.dart` | Cooldown + resolution config |
| `lib/features/analytics/application/insight_post_processor.dart` | Lifecycle transitions |
| `lib/features/analytics/domain/models/generated_insight.dart` | Model + enums |
| `lib/features/analytics/domain/models/coaching_insight_taxonomy.dart` | Policy registry |
| `lib/features/analytics/data/insight_cache_repository.dart` | Isar persistence |
| `lib/core/local_db/isar_collections/isar_generated_insight.dart` | Isar schema |

---

## Layer 4 — Focus Engine

### What it does

Takes all active `GeneratedInsight` records and selects exactly **one**
`CurrentCoachingFocus` — the single behavioral area that deserves the user's
attention right now. This is not just "pick the highest-scored insight": it
considers realtime context, anti-thrash logic, and full provenance.

### Scoring engine

Each insight becomes a `FocusCandidate` enriched with realtime context signals:

```
FocusCandidate {
  insight              // GeneratedInsight
  realtimeContext {
    currentTimeBlock   // morning | afternoon | evening | lateNight
    upcomingItemsCount // items due in next 60–120 min
    overdueCount
    isInFocusSession   // avoids conflicting recommendations
  }
}
```

`FocusScoringEngine` computes five sub-scores for each candidate:

| Sub-score | What it measures |
|-----------|-----------------|
| `urgencyScore` | How time-sensitive is this coaching signal? |
| `momentumScore` | Is the user in a positive behavioral momentum phase? |
| `feasibilityScore` | Is action realistic right now (timing, session state)? |
| `riskScore` | How much does inaction cost (streak/goal at risk)? |
| `recoveryScore` | How much recovery leverage does this offer? |

The weighted composite `focusScore` (0–1) is used for candidate ranking.

### Anti-thrash logic

`FocusSelector` enforces stability rules so the focus doesn't flip every recompute:

- **Minimum active duration:** once selected, a focus cannot be replaced for at
  least **2 hours** (`activeUntilMs`), unless an emergency override occurs.
- **Score delta threshold:** a challenger must exceed the current focus score
  by a meaningful margin before replacement is allowed.
- **Replacement reason:** every transition records a `FocusReplacementReason`
  (`scoreSurpassed | minDurationExpired | focusBecameStale | forcedByPolicy | manualOverride`).

### Focus model fields

```dart
CurrentCoachingFocus {
  focusId               // stable UUID
  focusReason           // why this was selected (10 canonical reasons)
  focusScore            // 0–1 composite
  focusConfidence       // 0–1 confidence in the prioritization decision itself
  scoreBreakdown        // all 5 sub-scores
  evaluationTrace       // ordered list of human-readable evidence strings
  contextSnapshot       // durable coaching context for AI and history
  lifecycleState        // candidate → active → reinforced → resolved/stale/replaced
  activeUntilMs         // min persistence timestamp
  suppressedCandidates  // all runners-up with rejection reasons
}
```

### Focus reasons (10 canonical values)

| Reason | Meaning |
|--------|---------|
| `imminentStreakRisk` | A streak is about to break |
| `highestMomentumLeverage` | Best opportunity to accelerate positive momentum |
| `bestRecoveryOpportunity` | Highest-leverage recovery from a lapse |
| `overdueItemCritical` | Critical overdue item needs immediate attention |
| `scheduledWindowActive` | Optimal scheduled window is open now |
| `globalOverloadSignal` | User is overloaded across multiple habits/goals |
| `consistencyBreakdownAlert` | Consistency is degrading across the board |
| `goalDriftDetected` | A goal is materially off trajectory |
| `reinforcingActiveStreak` | An active streak should be celebrated and protected |
| `timingOpportunity` | The current time block is the user's best performance window |

### Persistence

`FocusRepository` persists up to **150 focus entries** in Isar, supporting:
- `getActiveFocus()` — current live focus
- `getRecentFocusHistory(limit)` — past focus transitions
- `upsertFocus()` — create or update
- `transitionFocus()` — lifecycle change with audit trail
- `archiveFocus()` — mark as stale/replaced

### Key files

| File | Role |
|------|------|
| `lib/features/analytics/application/focus_scoring_engine.dart` | 5-dimensional scoring |
| `lib/features/analytics/application/focus_selector.dart` | Selection + anti-thrash logic |
| `lib/features/analytics/application/focus_candidate.dart` | Candidate model with realtime context |
| `lib/features/analytics/application/focus_providers.dart` | Riverpod providers |
| `lib/features/analytics/domain/models/current_coaching_focus.dart` | Full model + enums |
| `lib/features/analytics/data/focus_repository.dart` | Isar persistence |
| `lib/core/local_db/isar_collections/isar_coaching_focus.dart` | Isar schema |

---

## AI-1 — Coaching Summarizer

### What it does

Takes the `CurrentCoachingFocus` and generates a short, personalized coaching
message via GPT-4o mini. The engine decides *what* to say; the AI decides *how*
to say it.

### Core principle

```
Deterministic engine  →  behavioral truth (what the focus is, why, urgency)
AI                    →  phrasing only (warm, context-aware language)
```

The AI never chooses framing, tone, or action. All of that is determined by the
engine and sent to the AI as instructions.

### Coaching framing

`CoachingFraming` is derived **deterministically** from `FocusReason` before
the AI is called. This ensures tone is always psychologically coherent:

| Framing | Derived from | AI tone |
|---------|-------------|---------|
| `momentum` | `highestMomentumLeverage`, `reinforcingActiveStreak` | `encouraging` |
| `recovery` | `bestRecoveryOpportunity` | `supportive` |
| `protection` | `imminentStreakRisk`, `consistencyBreakdownAlert` | `assertive` |
| `stabilization` | `globalOverloadSignal`, `goalDriftDetected` | `informative` |
| `consistency` | `scheduledWindowActive`, `timingOpportunity` (low score) | `informative` |

### Summary type

`SummaryType` is also derived deterministically from framing + insight type:

| Summary type | When used |
|-------------|-----------|
| `reinforcement` | Praise insights (strong streak, goal success, etc.) |
| `recovery` | Recovery framing |
| `focus` | Protection or momentum framing |
| `daily` | Stabilization or consistency framing |

### Staleness TTL (when to regenerate)

| Condition | TTL |
|-----------|-----|
| urgency ≥ 0.75 or focus score ≥ 0.85 | 1 hour |
| `reinforcement` summary type | 12 hours |
| `daily` + focus score < 0.45 | 18 hours |
| Default | 6 hours |

### AI payload (`CoachingAiPayload`)

The payload sent to the AI is strict and minimal — no raw insight lists:

```dart
CoachingAiPayload {
  focusId             // binds response to the focus
  focusReason         // why this was selected
  framing             // deterministic framing (AI must follow it)
  summaryType         // expected summary type
  primaryInsightType  // main coaching signal
  focusScore          // 0–1 strength of the signal
  urgencyScore        // 0–1 time-sensitivity
  evaluationTrace     // top 5 evidence strings
  keyPatternCodes     // top 3 pattern codes
  topEvidence         // top 6 key→value metric evidence pairs
  deliveryContext     // timingProfile, localDateKey, word limits
  promptVersion       // for regression tracking (current: v1.0.0)
}
```

### AI response (`AiSummaryResponse`)

```dart
AiSummaryResponse {
  focusId             // must match payload focusId
  summaryType         // type of summary produced
  tone                // tone the AI applied (cross-checked)
  dailySummary        // main coaching narrative (≤ 80 words)
  mainRecommendation  // one concrete action (≤ 40 words)
  framing             // framing the AI confirmed
  secondaryNote       // optional acknowledgment of secondary insight
  validationOutcome   // passed | contradictsFocus | toneMismatch | tooLong | ...
  isFallback          // true when produced by DeterministicCoachingRenderer
  promptVersion       // version that produced this response
}
```

### Semantic validation (`AiResponseValidator`)

After the AI responds, lightweight validation catches obvious problems:

| Check | Rejects when |
|-------|-------------|
| Missing fields | `dailySummary` or `mainRecommendation` is blank |
| Too long | Summary > 120 words or recommendation > 60 words |
| Too vague | Summary < 10 characters |
| Tone mismatch | AI-declared tone doesn't match expected tone for framing |
| Contradicts focus | Response contains contradiction keywords for the focus reason (e.g. "rest day" when framing is `protection`) |

If validation fails, the response is replaced by the deterministic fallback.

### Deterministic fallback (`DeterministicCoachingRenderer`)

The app **never shows empty content** if the AI fails. A template map keyed by
`FocusReason × CoachingFraming` produces a high-quality coaching message for
every possible focus state. Triggered by:

- AI timeout or network failure
- Invalid JSON from AI
- API quota exceeded
- Offline state
- Semantic validation failure
- No active focus (guard)

### API key management

The OpenAI API key is **never stored in source code**. It is fetched at runtime
from **Firebase Remote Config** via `AiRemoteConfigService`:

- Remote Config key: `openai_api_key`
- Remote Config key: `openai_model` (default: `gpt-4o-mini`)
- Debug builds: instant refresh on each app start
- Production builds: 1-hour fetch interval with in-memory cache
- If the key is missing or Remote Config fails: gracefully falls back to
  `MockCoachingAiClient` (no crash, no error shown to user)

### Key files

| File | Role |
|------|------|
| `lib/features/analytics/domain/models/coaching_ai_payload.dart` | Payload model + framing/TTL derivation |
| `lib/features/analytics/domain/models/ai_summary_response.dart` | Response model + validation outcome |
| `lib/features/analytics/application/coaching_ai_client.dart` | Abstract interface + `OpenAiCoachingClient` + `MockCoachingAiClient` |
| `lib/features/analytics/application/ai_response_validator.dart` | Lightweight semantic validation |
| `lib/features/analytics/application/deterministic_coaching_renderer.dart` | Template-based fallback |
| `lib/features/analytics/application/ai_summary_providers.dart` | Riverpod providers |
| `lib/features/analytics/data/ai_summary_repository.dart` | Isar persistence (capped at 50) |
| `lib/core/ai/ai_remote_config_service.dart` | Firebase Remote Config key fetching |
| `lib/core/local_db/isar_collections/isar_ai_summary.dart` | Isar schema |

---

## Riverpod providers

The full pipeline is wired together with Riverpod. Key providers:

| Provider | Type | Role |
|----------|------|------|
| `featureCacheProvider` | `StreamProvider` | Streams cached feature objects |
| `patternDetectionProvider` | `StreamProvider` | Streams detected patterns |
| `insightGenerationProvider` | `StreamProvider` | Streams active insights |
| `layer34RecomputeNowProvider` | `FutureProvider` | Triggers full L1–L3 recompute |
| `recomputeCoachingFocusProvider` | `FutureProvider` | Runs focus selection engine |
| `currentAiSummaryProvider` | `StreamProvider` | Streams the latest AI summary |
| `recomputeAiSummaryProvider` | `FutureProvider` | Regenerates AI summary if stale |
| `coachingAiClientProvider` | `FutureProvider` | Resolves real or mock AI client |

---

## UI integration

### `HomeCoachingFocusCard`

Shown on the home screen. Displays:
- Focus reason label (human-readable)
- AI summary text (`dailySummary`)
- Main recommendation (`mainRecommendation`)
- Score bar (visual focus strength)
- Framing color (each framing has a distinct color)
- Refresh button (invalidates `recomputeAiSummaryProvider`)

### `ProgressCoachingFocusCard`

Compact version shown on the analytics/progress screen.

### Debug AI test button (analytics screen)

The ✨ button on the analytics screen:
1. Runs the full L1–L4 pipeline
2. Triggers AI summary generation
3. Shows a bottom sheet with the full `AiSummaryResponse` fields including
   validation outcome, framing, tone, focus score, and whether it's a fallback.

---

## Data flow summary (end-to-end)

```
1. User completes a task / timer / goal
      │
      ▼
2. Analytics event logged to Isar

3. User taps Refresh (or background trigger fires)
      │
      ▼
4. Layer 1: FeatureBuilderOrchestrator computes BehaviorFeatureObject per entity
      │
      ▼
5. Layer 2: PatternDetectionOrchestrator detects active patterns, scores them,
            emits GlobalBehaviorPatternSnapshot
      │
      ▼
6. Layer 3: InsightGenerationOrchestrator maps patterns → GeneratedInsight,
            applies cooldown/resolution, runs InsightPostProcessor
      │
      ▼
7. Layer 4: FocusSelector scores all insights via FocusScoringEngine,
            applies anti-thrash logic, persists CurrentCoachingFocus
      │
      ▼
8. AI-1:  If no fresh summary exists:
            - Assemble CoachingAiPayload (framing derived deterministically)
            - Call OpenAiCoachingClient (GPT-4o mini)
            - Validate response (AiResponseValidator)
            - If invalid → DeterministicCoachingRenderer fallback
            - Persist AiSummaryResponse to Isar
      │
      ▼
9. UI: HomeCoachingFocusCard renders the coaching message
```

---

## Adding a new pattern or insight type

1. **New pattern code:** add to `PatternCode` enum in `detected_pattern.dart`
   and add a `PatternTaxonomySpec` entry in `kPatternTaxonomyByCode` in
   `pattern_taxonomy.dart`.
2. **Detection logic:** add a threshold rule in `pattern_detection_engine.dart`.
3. **Scoring rule:** add a hybrid rule in `pattern_scoring.dart` (use existing
   `layer2_hybrid_v1` rule ID unless the scoring logic is genuinely different).
4. **New insight type:** add to `InsightType` enum in `generated_insight.dart`
   and add a mapping rule in `insight_mapping_engine.dart`.
5. **Policy:** add cooldown/resolution config in `insight_generation_policy.dart`.
6. **Fallback template:** add a `_FallbackTemplate` entry in
   `deterministic_coaching_renderer.dart` for any new `FocusReason` that
   could be triggered.
7. **Tests:** add cases to the corresponding test files under
   `test/features/analytics/`.

---

## Testing

All layers have dedicated test files:

| Layer | Test file |
|-------|-----------|
| Layer 1 | `feature_builder_assembler_test.dart`, `feature_builder_metrics_test.dart`, `feature_builder_input_adapters_test.dart`, `feature_builder_recompute_service_test.dart`, `feature_cache_repository_test.dart` |
| Layer 2 | `pattern_detection_engine_test.dart`, `pattern_detection_orchestrator_test.dart`, `pattern_detection_pipeline_test.dart`, `pattern_scoring_test.dart`, `pattern_aggregate_builder_test.dart`, `pattern_detection_recompute_service_test.dart`, `pattern_detection_providers_test.dart`, `pattern_layer2_canonical_migration_test.dart` |
| Layer 3 | `insight_mapping_engine_test.dart`, `insight_generation_policy_test.dart`, `insight_generation_orchestrator_test.dart`, `insight_generation_providers_test.dart`, `insight_generation_recompute_service_test.dart`, `insight_post_processor_test.dart`, `generated_insight_model_test.dart`, `insight_cache_repository_test.dart` |
| Layer 4 | `focus_engine_test.dart` |
| AI-1 | `ai_summarization_test.dart` (framing derivation, TTL, payload, response, validator, fallback renderer, mock client) |
| Delivery | `delivery_orchestrator_test.dart`, `delivery_selection_engine_test.dart`, `delivery_providers_test.dart`, `layer4_delivery_policy_test.dart`, `delivery_repository_test.dart`, `delivery_decision_model_test.dart` |
