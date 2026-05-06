as explained in the 'Insight_generation_plan.md' file here we're working on the layer 1 of the 5 layers.

LAYER 1 — FEATURE BUILDER (SPEC)
Goal

Convert raw app data (events, tasks, goals, analytics stats) into a normalized “Behavior Feature Object” per entity (task/habit/goal).

This layer does NO insights, NO AI, NO decisions.

It only answers:

“What is the user behavior numerically?”

📦 INPUT SOURCES

Feature builder must consume:

1. Analytics Event Stream
habitCompleted
taskCompleted
taskDeferred
taskStarted/Stopped
habitCheckIn
2. Task Data
duration, priority, schedule, status
completion / partial / defer actions
timer sessions
habit anchor flag
3. Goal/Habit Data
target, intensity, frequency
check-ins (metCommitment)
milestone progress
4. Cached Analytics Stats
daily/weekly/monthly completion %
streak values
weighted completion metrics
🧾 OUTPUT (CRITICAL)

For EACH entity (habit/task/goal), produce a single Feature Object:

{
  "entityId": "string",
  "entityKind": "task | habit | goal",

  "timeMetrics": {
    "completionRate7d": 0.0,
    "completionRate30d": 0.0,
    "avgDelayMinutes": 0,
    "lateRate": 0.0
  },

  "streakMetrics": {
    "currentStreak": 0,
    "longestStreak": 0,
    "missedLast2Days": false,
    "missedCount7d": 0
  },

  "effortMetrics": {
    "avgSnoozeCount": 0.0,
    "avgSessionDuration": 0,
    "plannedVsActualRatio": 0.0
  },

  "goalMetrics": {
    "progress": 0.0,
    "expectedProgress": 0.0,
    "gap": 0.0
  },

  "contextFeatures": {
    "bestTimeBlock": "morning | afternoon | evening",
    "isHabitAnchor": true,
    "priority": 1
  }
}
⚙️ COMPUTATION RULES
1. Completion Rate (7d / 30d)
based on taskCompleted + habitCompleted events
weighted if available
2. Late Rate
lateRate = lateCompletions / totalCompletions

Late = completionTime > scheduledTime

3. Missed Logic
missedLast2Days → no completion in last 2 calendar days
missedCount7d → count of days with no completion
4. Avg Snooze Count

From:

taskDeferred events
reminder interactions
5. Planned vs Actual Ratio
actualDuration / plannedDuration

From timer sessions

6. Goal Gap
gap = expectedProgress - actualProgress
7. Best Time Block

Derived from:

completion timestamps clustering
bucket into:
morning (5–11)
afternoon (11–17)
evening (17–23)

Pick highest success rate window.

🔁 PROCESS FLOW

For each entity:

1. Fetch events (by entityId)
2. Aggregate per time window (7d, 30d)
3. Compute metrics
4. Normalize into Feature Object
5. Store in cache (optional)
🧠 IMPORTANT DESIGN RULES
❌ Do NOT:
generate insights here
rank behaviors
apply thresholds for “good/bad”
use AI or heuristics for meaning
✅ DO:
compute pure numbers
ensure consistency across all entities
make output deterministic and repeatable
⚡ PERFORMANCE RULE
batch compute per user (not per entity call)
cache results daily in:
users/{userId}/feature_cache/{entityId}
🧱 WHY THIS LAYER EXISTS

This layer ensures:

Insight engine is simple
AI gets clean structured input
Debugging is easy
Metrics are consistent across app
🧠 FINAL DEFINITION

Feature Builder = a deterministic system that transforms raw behavioral data into structured, time-based, normalized behavioral metrics per entity.