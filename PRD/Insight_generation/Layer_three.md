🧠 LAYER 3 — INSIGHT GENERATION ENGINE
🎯 Purpose

Convert:

Patterns (Layer 2) → Actionable coaching insights

Not data. Not metrics. Not rules.

But:

“What does this mean for the user right now?”

🧩 INPUT

Layer 3 consumes ONLY:

1. Entity patterns
[
  { "pattern": "streak_risk", "severity": 0.9 },
  { "pattern": "late_behavior", "severity": 0.6 }
]
2. Global/day patterns
[
  { "pattern": "user_overloaded_day", "severity": 0.8 }
]
3. Feature context (small subset)
{
  "currentStreak": 5,
  "completionRate7d": 0.6,
  "habitName": "Workout"
}
🧠 OUTPUT (IMPORTANT)

Layer 3 outputs INSIGHTS = structured coaching units

NOT messages yet.

{
  "insights": [
    {
      "type": "streak_risk_warning",
      "priority": "high",
      "message_key": "streak_risk_1",
      "action": "do_now",
      "linkedPatterns": ["streak_risk"],
      "confidence": 0.9
    }
  ]
}
⚙️ CORE RESPONSIBILITY

Layer 3 = “What should the user understand?”

NOT:

❌ how to compute metrics
❌ raw pattern detection
❌ AI storytelling
🧠 DESIGN PRINCIPLE

Every insight must answer:

“What is happening + why it matters + what to do next”

BUT in STRUCTURED form.

🧩 INSIGHT TYPES (V1 CORE SET)

You should keep it small and powerful:

🔥 1. Streak Insights
streak_risk_warning

Triggered by:

streak_risk pattern

Meaning:

User is about to lose momentum

Action:

do_now
streak_recovery

Triggered by:

comeback after missed days
⏰ 2. Timing Insights
timing_misalignment

Triggered by:

late_behavior + low completion

Meaning:

Wrong time of day

Action:

reschedule
⚡ 3. Difficulty Insights
habit_too_hard

Triggered by:

low completion + high snooze

Action:

reduce intensity
🎯 4. Goal Insights
goal_at_risk

Triggered by:

goal_gap + low progress

Action:

focus
🌍 5. Daily Load Insights (GLOBAL)
overload_warning

Triggered by:

global pattern: user_overloaded_day

Action:

reduce load
🔁 INSIGHT GENERATION FLOW
Patterns (Layer 2)
   ↓
Pattern grouping
   ↓
Insight mapping rules
   ↓
Merge + deduplicate
   ↓
Rank by priority
   ↓
Output top 1–3 insights
🧠 STEP 1 — PATTERN GROUPING

Example:

streak_risk + late_behavior → “habit instability”
🧠 STEP 2 — INSIGHT MAPPING RULES

Each insight is a RULE:

if (streak_risk && severity > 0.7) {
  emit Insight("streak_risk_warning");
}
if (late_behavior && low_completion) {
  emit Insight("timing_misalignment");
}
if (too_hard_pattern) {
  emit Insight("habit_too_hard");
}
🧠 STEP 3 — MERGE LOGIC (VERY IMPORTANT)

If multiple patterns relate:

❌ Bad:
3 separate insights
✅ Good:
1 combined insight

Example:

streak_risk + late_behavior + low_completion
→ "You’re at risk of losing consistency and timing is off"
⚖️ STEP 4 — PRIORITY SYSTEM
high = streak risk, goal risk
medium = timing issues
low = positive reinforcement
✂️ STEP 5 — LIMIT OUTPUT

Always:

max 1–3 insights per entity
max 3 global insights per day
🧠 INSIGHT VS PATTERN (CRITICAL DISTINCTION)
Layer 2	Layer 3
“streak_risk”	“You’re about to lose momentum”
“late_behavior”	“You should move this earlier”
raw signal	interpretation
🔥 EXAMPLE FULL FLOW
Layer 2 output:
[
  { "pattern": "streak_risk", "severity": 0.9 },
  { "pattern": "late_behavior", "severity": 0.6 }
]
Layer 3 output:
{
  "insights": [
    {
      "type": "streak_risk_warning",
      "message": "You’re close to breaking your streak.",
      "action": "do_now",
      "priority": "high"
    },
    {
      "type": "timing_misalignment",
      "message": "You usually complete this late. Try moving it earlier.",
      "action": "reschedule",
      "priority": "medium"
    }
  ]
}
🧠 IMPORTANT DESIGN RULES
❌ Layer 3 must NOT:
compute metrics
detect patterns
use raw events
involve AI
✅ Layer 3 MUST:
map patterns → meaning
combine signals
prioritize insights
stay deterministic
🚀 WHY THIS LAYER EXISTS

Because it enables:

1. AI safety

AI never sees raw patterns directly

2. Consistency

Same patterns → same insights always

3. UX clarity

Users get meaningful coaching, not technical signals

🧠 FINAL DEFINITION

Layer 3 is a deterministic rule engine that converts behavioral patterns into prioritized, actionable coaching insights with structured messaging and actions.

🔥 SIMPLE MENTAL MODEL
Layer	Meaning
Layer 1	what happened
Layer 2	what pattern exists
Layer 3	what it means
AI	how to say it better