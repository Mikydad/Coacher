🧠 PHASE 3 — COACHING INSIGHT ENGINE
Goal

Transform canonical Layer 2 behavioral patterns into structured coaching insights.

Phase 3 should produce:

meaningful
actionable
explainable
deterministic coaching outputs

without using AI or recomputing behavior logic.

Input

Canonical Layer 2 artifacts:

DetectedBehaviorPattern
GlobalBehaviorPatternSnapshot
Output

GeneratedCoachingInsight

Requirements
1. Create Insight Taxonomy

Define stable insight families:

RiskInsights
TimingInsights
MomentumInsights
ReinforcementInsights
FocusInsights

Each insight type must include:

stable insightType ID
description
required pattern combinations
priority rules
cooldown rules
resolution rules
2. Build Insight Mapping Engine

Implement deterministic mapping:

patterns
→ coaching meaning

Rules:

no AI
no randomization
no metric recomputation
no motivational filler text

Each insight must:

reference evidence patterns
contain one clear coaching meaning
contain one suggested action
3. Add Prioritization Metadata

Each insight must include:

priority (0–1)
confidence
urgency
coaching importance

Derived ONLY from:

underlying patterns
canonical severity/confidence
timing context
4. Add Lifecycle Support

GeneratedCoachingInsight must support:

generated
active
reinforced
resolved
archived

Insights should persist across recompute cycles unless resolution conditions are met.

5. Add Evidence References

Each insight must preserve:

linkedPatternCodes
supporting metrics
reasoning evidence

Goal:
explainability + future AI summarization support.

6. Add Focus-Oriented Insights

Support V1 focus coaching:

Examples:

highest momentum leverage
most fragile streak
best recovery opportunity
strongest completion window

These are deterministic recommendations only.

7. Add Global Coaching Insights

Generate global/day-level coaching summaries:

Examples:

overload trend
improving consistency
unstable routine pattern
8. Add Tests

Add deterministic tests:

same patterns → same insights
lifecycle persistence
deduplication correctness
priority ordering
cooldown behavior
resolution transitions
Important Rules

Phase 3 must:

explain behavior
guide attention
suggest focus

Phase 3 must NOT:

directly notify users
decide UI routing
use LLMs
generate emotional persuasion
invent behavioral truth
Success Criteria

Phase 3 is complete when:

insights feel coherent
insights are stable
insights explain patterns clearly
insights can drive a future Focus Engine
same inputs always produce same coaching outputs

---

# 🧠 MOST IMPORTANT THING NEXT

After Phase 3:

You’ll finally have:
```text id="brain"
Behavior
→ Patterns
→ Coaching Meaning

THEN:

Focus Engine
AI summarizer
adaptive coaching

become powerful.