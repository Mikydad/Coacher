🧠 LAYER 2 — PATTERN DETECTION ENGINE (RULE SYSTEM)
🎯 Purpose

Convert feature objects (Layer 1 output) into:

behavior patterns (signals of what is happening)

Not insights yet. Not messages. Just detected behavioral states.

🧩 INPUT

Layer 2 ONLY consumes:

FeatureObject (from Layer 1)

Example:

{
  "completionRate7d": 0.55,
  "missedLast2Days": true,
  "lateRate": 0.7,
  "avgSnoozeCount": 2.1,
  "goalGap": 0.3
}
🧠 OUTPUT (IMPORTANT)

Layer 2 outputs raw patterns, not advice:

[
  {
    "pattern": "streak_risk",
    "severity": 0.9,
    "confidence": 1.0
  },
  {
    "pattern": "late_behavior",
    "severity": 0.7,
    "confidence": 0.85
  }
]
⚙️ CORE DESIGN PRINCIPLE

Layer 2 = “What is happening?”
NOT “What should we do?”

🔍 PATTERN CATEGORIES (your full system)

You should define patterns in 5 groups:

1. 🔥 Streak & Consistency Patterns
🧨 streak_risk
if (missedLast2Days == true)
📈 strong_streak
if (currentStreak >= 7)
📉 inconsistent_behavior
if (completionRate7d < 0.6)
2. ⏰ Time Behavior Patterns
🕒 late_behavior
if (lateRate > 0.6)
🌙 time_misalignment
if (bestTimeBlock != scheduledTimeBlock)
3. ⚡ Effort & Difficulty Patterns
💀 too_hard
if (completionRate7d < 0.4 && avgSnoozeCount > 2)
💤 low_engagement
if (avgSnoozeCount > 2 && completionRate7d < 0.5)
4. 🎯 Goal Alignment Patterns
🎯 goal_gap_risk
if (goalGap > 0.25)
📊 off_track_goal
if (expectedProgress - actualProgress > 0.2)
5. 🔁 Behavior Stability Patterns
🔄 habit_instability
if (missedCount7d >= 3)
🧱 stable_behavior
if (completionRate7d > 0.85)
🧠 SEVERITY MODEL (VERY IMPORTANT)

Each pattern must include severity:

0.0 → no issue
1.0 → critical issue

Example mapping:

Pattern	Severity
streak_risk	0.9
too_hard	0.8
late_behavior	0.6
stable_behavior	0.1
⚖️ CONFIDENCE RULE

Confidence depends on:

data consistency
sample size (7d vs 1d)
signal strength

Example:

high consistency → 0.9–1.0
weak trend → 0.5–0.7
🔁 EXECUTION FLOW
Feature Object
   ↓
Run pattern rules (deterministic checks)
   ↓
Emit raw patterns
   ↓
Attach severity + confidence
   ↓
Send to Layer 3
🚫 STRICT RULES

Layer 2 MUST NOT:

❌ generate messages
❌ give advice
❌ rank insights
❌ call AI

Only:

detect + label + score behavior

🧠 WHY THIS LAYER EXISTS

Because it solves 3 big problems:

1. Separation of logic
analytics ≠ behavior interpretation ≠ messaging
2. AI safety

AI never touches raw data → only patterns

3. Consistency

Same behavior always produces same pattern

⚡ SIMPLE MENTAL MODEL
Layer	Meaning
Layer 1	What happened (metrics)
Layer 2	What pattern exists
Layer 3	What it means (insight)
AI	How to say it
🔥 EXAMPLE FULL FLOW
Input (Layer 1)
completionRate7d = 0.55
missedLast2Days = true
lateRate = 0.7
Layer 2 Output
[
  {
    "pattern": "streak_risk",
    "severity": 0.9
  },
  {
    "pattern": "late_behavior",
    "severity": 0.7
  }
]

👉 Then Layer 3 turns this into:

“You’re close to breaking your streak and often complete this late.”

🎯 FINAL DEFINITION

Layer 2 is a deterministic rule engine that transforms feature metrics into labeled behavioral patterns with severity and confidence scores.