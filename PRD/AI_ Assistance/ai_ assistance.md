AI App Manager (AI Operating Layer) — Full Engineering PRD V1
1. Problem Statement

Users currently interact with the app through multiple manual steps:

Create task
→ choose date
→ choose time
→ choose duration
→ choose reminders
→ save

Create meeting
→ repeat process

Modify schedule
→ open screen
→ edit

As the app grows (tasks, goals, reminders, focus modes, AI coaching, scheduling, accountability circles, context overrides), navigation friction increases.

Users think in intent, not in screens.

Example:

"Add a workout task at 5AM, at 9AM I have a meeting, remove all afternoon tasks and silence the app after that."

Users should be able to tell the app what they want, not manually navigate to accomplish it.

The goal is to create an AI Operating Layer that translates natural language (text or voice) into structured actions safely.

2. Product Goal

Build an AI assistant capable of:

understanding user intent
converting intent into app actions
asking questions when required
making safe assumptions when data exists
previewing actions before execution
preventing destructive actions

The AI does not directly modify databases.

Core principle:

Understand
↓
Validate
↓
Preview
↓
Confirm
↓
Execute

Never:

Voice/Text
↓
AI
↓
Direct database write
3. Supported Input Methods
Text

Examples:

Add workout at 5AM

Move study session to tomorrow

Delete afternoon tasks

Enable focus mode
Voice

Flow:

Voice
↓
Speech-to-text
↓
Intent parser
↓
Action generation

Voice and text use the same backend logic.

4. Core Architecture

System flow:

Voice/Text
      ↓
Intent Parser
      ↓
Missing Field Detector
      ↓
Assumption Engine
      ↓
Conflict Engine
      ↓
Preview Generator
      ↓
Confirmation
      ↓
Execution Engine
      ↓
Task/Goal/Reminder Services
5. Main Components
5.1 Intent Parser

Purpose:

Convert natural language into structured intents.

Example:

Input:

Add a workout at 5AM and silence app after meeting

Output:

[
 {
   "action":"createTask",
   "title":"Workout",
   "time":"05:00"
 },
 {
   "action":"activateContextOverride",
   "type":"silent"
 }
]
5.2 Missing Field Detector

Purpose:

Determine whether enough information exists.

Example:

Input:

Schedule meeting tomorrow

Missing:

time
duration

AI asks:

What time is the meeting?

How long will it last?
6. Missing Information Rules

Hybrid A + B model:

Rule:

Use assumptions only when the app already knows the answer.

Ask questions when the app does not know.
Level 1 — Infer values

Allowed only if:

confidence >= 80%

Sources:

previous tasks
previous goals
recurring patterns
preferred durations
schedule availability
conflict engine
user routines

Example:

User:

Schedule workout tomorrow

System already knows:

Previous workout time = 6AM
Duration = 30 minutes

AI:

Suggested:

Workout
6:00–6:30AM

Reason:
Based on previous workout schedule
Level 2 — Ask follow-up questions

Critical missing fields:

Tasks:

title
time
duration

Meetings:

time
duration

Goals:

goal target
deadline
Level 3 — Clarify ambiguity

Example:

Input:

Move tomorrow tasks

AI:

Move to when?
7. Assumption Engine (Updated)

Purpose:

Make suggestions using existing app history rather than AI reasoning.

Core rule:

Reuse the latest successful configuration of the same entity whenever possible.

Processing flow:

Extract entity
      ↓
Normalize entity/category
      ↓
Search existing task/goal/habit history
      ↓
Get latest matching configuration
      ↓
Reuse configuration
      ↓
Validate conflicts
      ↓
Generate preview

Allowed reused fields:

time
duration
reminder settings
enforcement mode
preferred schedule window
category
context preferences

Example:

Previous task:

Workout
6:00–6:45 AM
Extreme mode

User:

Plan workout tomorrow

AI output:

Suggested:

Workout
6:00–6:45 AM

Reason:
Based on your latest workout setup.

[Confirm]
[Edit]

Entity normalization examples:

Workout
Morning workout
Gym
Push day
Leg day

Normalize into:

fitness

Then:

Use latest successful fitness configuration

Rules:

If match exists:
    Suggest configuration

If no match exists:
    Ask follow-up questions

Never invent values from AI assumptions alone

That change makes the system much easier to maintain and debug.
8. Conflict Engine Integration

AI manager must use existing scheduling logic.

Checks:

Time overlap

Example:

Workout
5–5:30

Meeting
5:15–6

Detect:

Overlap detected
Reminder collisions

Example:

Two reminders within 3 minutes

Detect:

Potential notification collision
Context conflicts

Example:

Study session scheduled during sleep mode
9. Preview System

All actions require confirmation.

No direct execution.

Example:

User:

Add workout at 5AM, create meeting at 9AM and remove afternoon tasks

AI:

Planned changes:

➕ Create:
Workout
5:00–5:30AM

➕ Create:
Meeting
9:00–10:00AM

➖ Remove:
3 afternoon tasks

⚠ Conflict:
Workout overlaps morning routine

[Confirm]

[Edit]

[Cancel]
10. Risk Levels
Low Risk

Examples:

add task
enable focus mode
add reminder
Medium Risk

Examples:

move tasks
modify schedules
change reminders
High Risk

Examples:

delete tasks
remove goals
bulk actions

V1:

ALL actions require confirmation

Future:

Low-risk actions may auto-approve.

11. Execution Engine

Purpose:

Convert approved actions into actual service calls.

Never:

AI
↓
Firestore

Always:

AI
↓
ExecutionEngine
↓
TaskService
GoalService
ReminderService
ContextService

Example:

class AiAction{

String actionType;

Map<String,dynamic> parameters;

double confidence;

}
12. Supported Actions V1

Tasks:

create
edit
move
delete

Goals:

create
modify
delete

Reminders:

add
remove
reschedule

Context:

enable focus mode
enable sleep mode
activate meeting mode
enable do not disturb

Scheduling:

move conflicting tasks
suggest free time blocks
13. AI Prompt Payload

AI receives:

{
 "activeTasks":[],
 "goals":[],
 "todaySchedule":[],
 "focusState":{},
 "contextOverride":{},
 "behaviorPreferences":{},
 "recentPatterns":[]
}

Never send:

database IDs
raw schema
internal object references

Only:

Human-readable context

14. Persistence

Store:

AiInteractionHistory

{
id
userInput
parsedActions
confirmed
executed
timestamp
}

Purpose:

debugging
future learning
preference adaptation
15. Analytics

Track:

aiCommandSubmitted

aiCommandExecuted

aiCommandCanceled

aiFollowupQuestionAsked

aiSuggestionAccepted

aiSuggestionRejected
16. Implementation Phases
Phase 1

Foundation

Build:

AI chat UI
intent parser
action model
confirmation flow
Phase 2

Smart suggestions

Build:

assumption engine
task history integration
scheduling suggestions
Phase 3

Context awareness

Build:

conflict engine integration
behavior pattern integration
focus integration
Phase 4

Proactive AI

Build:

proactive suggestions
schedule optimization
predictive actions
17. Explicit V1 Exclusions

Not included:

direct execution without confirmation
autonomous AI behavior
deleting data automatically
long conversational memory
external integrations
calendar sync AI actions
self-modifying schedules