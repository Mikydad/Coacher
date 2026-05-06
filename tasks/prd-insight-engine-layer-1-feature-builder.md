# PRD: Insight Engine Layer 1 - Feature Builder

## 1) Introduction/Overview

This PRD defines Layer 1 of the AI Coach Insight Engine: the **Feature Builder**.  
The Feature Builder transforms raw behavior data (events, tasks, goals, analytics stats) into deterministic, normalized **Behavior Feature Objects** per entity.

This layer does **not** generate insights, scoring, coaching text, ranking, or AI interpretation. Its job is only to produce reliable numeric truth that later layers can use.

The problem this solves: current behavior data is distributed across multiple sources and formats, which makes downstream insight generation inconsistent and hard to debug. Layer 1 creates a single canonical feature contract for each entity.

## 2) Goals

- Build a deterministic feature computation pipeline for all scoped entities:
  - all tasks
  - habit anchor tasks
  - goals/habits (check-in based)
  - goal entities (progress and gap)
  - non-habit goals
- Produce one normalized Feature Object per entity with required metrics and context fields.
- Persist Layer 1 outputs in **Isar local cache only** for V1.
- Support **hybrid recompute**:
  - event-driven recompute for touched entities
  - daily full refresh batch
- Establish measurable quality targets:
  - deterministic parity across repeated runs
  - latency target
  - coverage target for required fields

## 3) User Stories

- As a user, I want my behavior data to be analyzed consistently so that coaching insights are accurate.
- As a user, I want analytics to react quickly after I complete/defer tasks or check in on habits.
- As a developer, I want one canonical feature schema so I can build pattern detection without custom logic per screen.
- As a developer, I want deterministic outputs so debugging and testing are predictable.
- As a product owner, I want Layer 1 to be isolated from insight logic so we can scale safely across later layers.

## 4) Functional Requirements

1. The system must define a canonical `BehaviorFeatureObject` for each entity, with:
   - `entityId`
   - `entityKind` (`task | habit | goal`)
   - `timeMetrics`
   - `streakMetrics`
   - `effortMetrics`
   - `goalMetrics`
   - `contextFeatures`

2. The system must ingest data from all required sources:
   - analytics event stream (`habitCompleted`, `taskCompleted`, `taskDeferred`, timer/session events, habit check-ins)
   - task data (duration, priority, schedule, status, habit-anchor flag)
   - goal/habit data (target, intensity/frequency, check-ins, milestone/progress)
   - cached analytics stats (daily/weekly/monthly completion and streak fields where available)

3. The system must compute required time metrics:
   - `completionRate7d`
   - `completionRate30d`
   - `avgDelayMinutes`
   - `lateRate`

4. The system must compute required streak metrics:
   - `currentStreak`
   - `longestStreak`
   - `missedLast2Days`
   - `missedCount7d`

5. The system must compute required effort metrics:
   - `avgSnoozeCount`
   - `avgSessionDuration`
   - `plannedVsActualRatio`

6. The system must compute required goal metrics:
   - `progress`
   - `expectedProgress`
   - `gap` (expected - progress)

7. The system must compute required context features:
   - `bestTimeBlock` (`morning | afternoon | evening`)
   - `isHabitAnchor`
   - `priority`

8. The system must implement computation rules:
   - completion rates based on completion events and scheduled opportunities
   - late completion when `completionTime > scheduledTime`
   - missed-day logic across calendar days
   - snooze from defer/reminder interactions
   - planned-vs-actual from timer sessions
   - time-block clustering with fixed windows:
     - morning: 05:00-10:59
     - afternoon: 11:00-16:59
     - evening: 17:00-22:59

9. The system must compute features for all scoped entities in batch mode per user (not one-off isolated calls by default).

10. The system must persist feature objects in Isar cache for V1, with per-entity records keyed by entity ID and date window metadata.

11. The system must support hybrid recompute:
    - on relevant event mutation: recompute touched entity feature object(s)
    - daily batch: recompute all scoped entities to keep windows/streaks fresh

12. The system must expose read APIs/providers so downstream layers can fetch:
    - single entity feature object
    - scoped list of feature objects (by kind/date window)
    - last compute timestamp and version

13. The system must include schema/version metadata for feature objects so future layers can evolve without breaking compatibility.

14. The system must include deterministic test coverage for all major formulas and edge cases.

## 5) Non-Goals (Out of Scope)

- Generating insights, advice text, or recommendations.
- Rule thresholds like "good/bad behavior" evaluation.
- Ranking/prioritization of insights.
- AI/LLM prompting, summarization, or coaching responses.
- Multi-device remote merge logic for feature cache in V1.
- Full Firestore persistence for feature cache in V1 (explicitly deferred).

## 6) Design Considerations

- No new user-facing UI is required for Layer 1.
- Optional developer debug surface may be added later, but is not required for this PRD.
- Output schema should be easy to inspect in logs for debugging (human-readable JSON structure).

## 7) Technical Considerations

- Keep logic deterministic and side-effect minimal:
  - same inputs must always produce same feature outputs.
- Use existing analytics/event/task/goal repositories as source adapters.
- Normalize time handling with one canonical timezone/day-boundary strategy.
- Use incremental recompute where possible to reduce cost, but preserve correctness over optimization.
- Add feature schema version constant and migration-safe read behavior.
- Ensure architecture cleanly supports Layer 2 pattern detector input requirements.

## 8) Success Metrics

1. Determinism:
   - Re-running computation on unchanged input yields identical feature objects (100% parity in tests).

2. Latency:
   - Touched-entity recompute target: under 200ms median on emulator/dev hardware.
   - Full daily batch target: under 2s for typical local dataset.

3. Coverage:
   - 100% required fields populated for in-scope entities.
   - Null-safe defaults only where data is truly unavailable and explicitly defined.

4. Reliability:
   - No regression in existing analytics surfaces caused by Layer 1 computation path.

## 9) Open Questions

- Should "night" (23:00-04:59) be added as a fourth time block now or deferred?
- For entities with sparse history, should `completionRate30d` fall back to shorter-window confidence weighting in V1?
- Should partial completion semantics be normalized now (e.g., weighted completion < 1.0), or deferred to Layer 2+?
- What minimum event history is required before an entity becomes eligible for downstream insight generation?
