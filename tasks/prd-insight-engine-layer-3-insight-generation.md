# PRD: Insight Engine Layer 3 - Insight Generation Engine

## 1) Introduction/Overview

This PRD defines Layer 3 of the AI Coach Insight Engine: the **Insight Generation Engine**.

Layer 3 consumes Layer 2 detected patterns (plus a small Layer 1 context subset) and transforms them into deterministic, prioritized, actionable **Insight** objects.

This layer answers **"What does this mean for the user right now?"** and does not compute metrics, detect raw patterns, or call AI.

The core problem this solves is converting technical pattern signals into structured coaching meaning that downstream UI and later AI phrasing layers can safely consume.

## 2) Goals

- Convert pattern outputs into structured, deterministic insight units for coaching.
- Use a clear 3-bucket model for V1 insight taxonomy:
  - Risk insights (negative)
  - Neutral insights (diagnostic)
  - Reinforcement insights (positive)
- Emit both `message_key` and deterministic fallback `message` in Layer 3 output.
- Merge related patterns into fewer, more meaningful insights.
- Prioritize and cap output volume for user clarity:
  - max 1-3 insights per entity
  - max 3 global/day insights.
- Persist Layer 3 outputs in dedicated Isar collection(s) for local-first reads.
- Support initial UI consumption on **Home** only for V1.

## 3) User Stories

- As a user, I want simple coaching insights instead of technical pattern codes so I know what to do next.
- As a user, I want only a few high-value insights so I do not feel overwhelmed.
- As a user, I want urgent risk signals to appear first when consistency is at risk.
- As a developer, I want deterministic insight generation so behavior is predictable and testable.
- As a product owner, I want Layer 3 to stay separate from AI wording so we can scale safely in later layers.

## 4) Functional Requirements

1. The system must accept only Layer 2 pattern outputs and approved context subset as Layer 3 inputs:
   - per-entity patterns
   - global/day patterns
   - limited context fields (for example: streak summary, 7d completion, entity label/title).

2. The system must define a canonical `GeneratedInsight` schema with at least:
   - `insightId`
   - `scopeType` (`entity | global`)
   - `scopeId` (entity ID or day/global key)
   - `insightType`
   - `insightBucket` (`risk | neutral | reinforcement`)
   - `priority` (`high | medium | low`)
   - `messageKey`
   - `message` (deterministic fallback text)
   - `action` (structured action enum)
   - `linkedPatternCodes`
   - `confidence`
   - `detectedAtMs`
   - `sourceWindowStartDateKey`
   - `sourceWindowEndDateKey`
   - `schemaVersion`.

3. The system must implement V1 insight buckets and mapped insight types:
   - **Risk**:
     - `streak_risk_warning`
     - `habit_too_hard`
     - `timing_misalignment`
     - `goal_at_risk`
   - **Neutral**:
     - `late_pattern`
     - `inconsistency_notice`
     - `low_engagement_notice`
   - **Reinforcement**:
     - `strong_streak_praise`
     - `consistent_behavior_praise`
     - `goal_progress_success`.

4. The system must map one or more pattern combinations to one insight using deterministic rule logic.

5. The system must support merge/deduplicate behavior so related patterns do not produce redundant insight spam.

6. The system must assign deterministic priority with V1 policy:
   - high: risk-critical items (`streak_risk_warning`, `goal_at_risk`)
   - medium: timing/diagnostic issues
   - low: reinforcement and non-urgent diagnostics.

7. The system must rank emitted insights per scope by priority and tie-break deterministically.

8. The system must enforce output caps:
   - entity scope: max 1-3 insights
   - global/day scope: max 3 insights.

9. The system must emit structured actions for each insight from a controlled enum (e.g., `do_now`, `reschedule`, `reduce_intensity`, `focus`, `reduce_load`, `keep_going`).

10. The system must clamp confidence values to `[0.0, 1.0]` and preserve deterministic output order.

11. The system must persist Layer 3 outputs in dedicated Isar storage with migration-safe schema versioning.

12. The system must expose read APIs/providers for:
    - per-entity insights
    - global/day insights
    - latest run metadata (timestamp, counts, schema version).

13. The system must include provider wiring for Home surface consumption in V1 (no Progress integration in this PRD scope).

14. The system must include telemetry for:
    - entities processed
    - insights emitted
    - merge/dedupe counts
    - skipped/errored rules
    - elapsed time.

15. The system must fail safely:
    - malformed pattern payloads do not crash full batch
    - one entity failure is isolated from others.

## 5) Non-Goals (Out of Scope)

- Computing raw behavior metrics (Layer 1 responsibility).
- Detecting base behavior patterns (Layer 2 responsibility).
- AI-generated narrative wording or LLM calls.
- Multi-surface rollout beyond Home in V1.
- Final recommendation execution automation (insights provide action suggestions only).

## 6) Design Considerations

- Insight output should be concise and coach-like, but still deterministic.
- `messageKey` is primary for localization and copy control; `message` is fallback-safe for rendering and debugging.
- Home UI should display top prioritized insight(s) with visible action hint.
- Reinforcement insights should be lower priority unless no risk insight exists.

## 7) Technical Considerations

- Reuse Layer 2 providers/repository interfaces as upstream source contracts.
- Keep mapping rules pure and centralized (no scattered hard-coded conditions).
- Create dedicated Isar collections for Layer 3 insight rows and optional run metadata row(s).
- Add schema constants and compatibility parsing for future Layer 4/5 expansion.
- Maintain deterministic tie-break keys (priority, confidence, severity proxy, stable IDs).
- Ensure local-first performance is preserved for daily refresh and touched-entity recompute paths.

## 8) Success Metrics

1. Determinism:
   - Same input pattern set produces identical insight outputs across repeated runs (100% parity in tests).

2. Insight quality coverage:
   - All configured V1 risk/neutral/reinforcement mappings trigger correctly under expected fixtures.

3. Output clarity:
   - Cap rules always respected (entity and global limits).
   - Duplicate/redundant insight emission reduced by merge policy in test scenarios.

4. Reliability:
   - Rule exceptions are isolated and logged; batch run continues.
   - No regressions in existing analytics and Layer 2 consumers.

5. Performance:
   - Insight generation remains within local-first budget on emulator/dev dataset (target validated in QA, comparable to Layer 2 batch constraints).

## 9) Open Questions

- Should multiple reinforcement insights be allowed together when no risk insights exist, or should one reinforcement winner be enforced?
- Should `goal_progress_success` require a minimum confidence threshold distinct from other reinforcement insights?
- For Home V1, should global/day insights be mixed with entity insights in one ranked list, or shown in separate slots?
- Should `message` fallback text be versioned alongside `messageKey` to avoid copy drift across app versions?
