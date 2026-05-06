🧠 1. The Insight Engine = 3 Layers

You should NOT go:

data → insight ❌

Instead:

Raw data → Feature builder → Pattern detector → Insight generator → Ranking engine
🧩 LAYER 1 — Feature Builder (MOST IMPORTANT)

This is where your current data becomes clean signals

You already have messy but rich data:

events
tasks
goals
analytics stats

Now convert everything into standard features per habit/task

🔹 Output of this layer (example)
{
  "entityId": "workout",

  "completionRate7d": 0.6,
  "completionRate30d": 0.72,

  "currentStreak": 5,
  "missedLast2Days": true,
  "missedCount7d": 3,

  "lateRate": 0.7,
  "avgDelayMinutes": 45,

  "avgSnooze": 2,

  "bestTimeBlock": "morning",

  "goalGap": 0.3
}

👉 THIS is your foundation
No insights yet—just truth

🔍 LAYER 2 — Pattern Detector (RULE ENGINE)

Now we detect behavior patterns

Each pattern = a function

🔥 Example patterns (your core engine)
1. Streak Risk
if (missedLast2Days == true) {
  emit("streak_risk");
}
2. Frequent Skipping
if (missedCount7d >= 3) {
  emit("frequent_skip");
}
3. Late Habit Pattern
if (lateRate > 0.6) {
  emit("late_pattern");
}
4. Too Hard
if (completionRate7d < 0.4 && avgSnooze > 2) {
  emit("too_hard");
}
5. Strong Habit (positive insight)
if (completionRate7d > 0.85) {
  emit("consistent_habit");
}
6. Goal Misalignment
if (goalGap > 0.25) {
  emit("goal_misalignment");
}

👉 Output of this layer = raw insights (not text yet)

🧠 LAYER 3 — Insight Generator (MEANING)

Now convert patterns → structured insights

Example:

Input:

"streak_risk"

Output:

{
  "type": "streak_risk",
  "priority": "high",
  "habitId": "workout",
  "data": {
    "missedDays": 2
  }
}
Another:
{
  "type": "late_pattern",
  "priority": "medium",
  "data": {
    "lateRate": 0.7,
    "avgDelayMinutes": 45
  }
}

👉 Now you have structured insights

NOT text yet.

⚖️ LAYER 4 — Ranking Engine (VERY IMPORTANT)

You don’t show everything.

You rank:

Score formula:
score =
  priorityWeight +
  severityWeight +
  recencyWeight
Example weights:
Priority	Score
high	3
medium	2
low	1
Severity:
streak risk → 1.0
frequent skip → 0.8
late pattern → 0.5

👉 Final:

sort by score DESC
take top 1–3
✂️ LAYER 5 — Filter Engine (VERY IMPORTANT)

Rules:

max 2 insights per habit
avoid duplicates
suppress low-value insights
Example:

❌ Don’t show:

“consistent habit”
AND “strong streak”
at same time