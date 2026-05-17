🧠 PHASE 4 — FOCUS ENGINE + DELIVERY INTELLIGENCE
Goal

Build a deterministic behavioral prioritization system that selects the highest-leverage coaching focus for the user in real time.

Phase 4 should transform:

many insights
→ one intentional coaching focus.
Input

Consume:

Layer 1 metrics
Layer 2 patterns
Layer 3 coaching insights
realtime behavioral context
Output

CurrentCoachingFocus

Requirements
1. Build Focus Scoring Engine

Implement deterministic focus scoring.

Each candidate insight/entity must receive:

focusScore (0–1)
urgencyScore
momentumScore
feasibilityScore
riskScore
recoveryScore

Final score must be deterministic and explainable.

2. Build Candidate Evaluation Pipeline

Evaluate:

overdue state
streak risk
timing fit
user priority
current momentum
schedule proximity
behavioral recovery opportunity

Goal:
determine highest-leverage action right now.

3. Build Focus Selector

Select:

1 primary focus
optional 1 secondary focus

Prevent:

rapid switching
focus thrashing
low-value replacements

Add cooldown + persistence logic.

4. Build Focus Lifecycle

Support states:

candidate
active
reinforced
resolved
stale
replaced

Persist lifecycle state across recompute cycles.

5. Add Delivery Intelligence

Determine:

home surface routing
notification eligibility
suppression windows
silent delivery behavior

Rules:

avoid spam
avoid duplicate recommendations
prioritize high-confidence/high-impact focus
6. Add Explainability

Every focus decision must preserve:

why selected
contributing patterns
score breakdown
suppression reasons for rejected candidates

Goal:
future AI summarization + developer debugging.

7. Add Deterministic Tests

Test:

same inputs → same focus
cooldown behavior
priority replacement
momentum tie-breaking
lifecycle persistence
notification suppression
Important Rules

Phase 4 must:

prioritize behavioral leverage
reduce decision fatigue
preserve user autonomy

Phase 4 must NOT:

force behavior
spam reminders
use AI decision-making
randomly rotate focus
Success Criteria

Phase 4 is complete when:

the app consistently knows what matters most right now
coaching feels intentional
focus recommendations feel stable
delivery avoids noise
users feel guided, not controlled

---

# 🧠 AFTER PHASE 4

Only AFTER this phase should you add:

---

# 🟣 PHASE 5 — AI Coaching Layer

AI will:
- summarize
- personalize
- explain
- adapt tone
- synthesize focus context

NOT replace deterministic focus logic.

---

# 🔥 Final honest opinion

Phase 4 is where your app becomes:
> genuinely differentiated.

Because THIS is the layer that transforms:
- analytics
- habits
- tasks
- goals

into:
> a real-time behavioral execution coach.