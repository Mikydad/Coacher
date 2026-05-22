CURSOR IMPLEMENTATION ROADMAP (PHASE 2)
🟢 1. Create Pattern Taxonomy (FIRST STEP)

Tell Cursor:

Create a strict enum-based PatternTaxonomy for Phase 2.

Include ONLY:

1. StreakConsistencyPatterns
2. TimeBehaviorPatterns
3. EffortDifficultyPatterns
4. GoalAlignmentPatterns
5. BehavioralStabilityPatterns

Each pattern must have:
- patternCode (stable ID)
- description
- required metrics from Layer 1
- severity calculation rule (deterministic)
- confidence rule
🟢 2. Build Pattern Detection Engine
Build PatternDetectionEngine for Layer 2 Phase 2.

Requirements:

1. Input:
- BehaviorFeatureObject (Layer 1)

2. Output:
- List<DetectedBehaviorPattern>

3. Rules:
- no AI usage
- no heuristic text generation
- fully deterministic rules only
- same input must produce same output

4. Each pattern must:
- use ONLY Layer 1 metrics
- include severity + confidence
- include evidence list (metric references only)

5. Deduplicate patterns per entity:
- max 1 pattern per patternCode per entity per run
🟢 3. Add Pattern Scoring System
Implement deterministic scoring functions:

- severity (0–1):
  based on deviation from expected behavioral norms

- confidence (0–1):
  based on data stability (sample size, consistency of signal)

Ensure:
- no random values
- no LLM involvement
- fully reproducible
🟢 4. Add Pattern Aggregation Layer
Add GlobalPatternAggregator.

It should:

1. Aggregate patterns across all entities per dayKey
2. Produce:
- pattern frequency counts
- average severity per patternGroup
- system-level behavioral trends

Output:
GlobalBehaviorPatternSnapshot
🟢 5. Add Unit Tests (CRITICAL)
Add deterministic tests:

1. Same feature input → same pattern output
2. Late completion edge cases
3. Missing scheduled data handling
4. Low-sample confidence behavior
5. Pattern suppression correctness
6. Global aggregation correctness
🧠 PHASE 2 SUCCESS CRITERIA

You are DONE when:

✅ Patterns are stable (no randomness)
✅ Patterns are explainable purely from Layer 1
✅ No insight logic exists yet
✅ No prioritization exists yet
✅ Global + entity patterns both exist
✅ Layer 3 can consume patterns cleanly
🚨 CRITICAL DESIGN PRINCIPLE

Phase 2 MUST enforce:

Patterns = interpretation of behavior
NOT meaning
NOT advice
NOT recommendation

🧠 WHY THIS PHASE MATTERS (IMPORTANT)

Because without Phase 2:

AI will hallucinate meaning later
insights become inconsistent
focus engine becomes unreliable

With Phase 2:

everything becomes structured reasoning input
AI becomes optional, not required
🔥 FINAL HONEST SUMMARY

Phase 2 is where you build:

the “behavior language” of your app

Not intelligence
Not coaching
Not UX

Just:

structured behavioral interpretation