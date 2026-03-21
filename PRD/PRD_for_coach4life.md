Product Requirements Document (PRD) – AI Accountability Mobile App
1. Product Overview

Product Name: TBD (working name: AI Accountability Coach)
Platform: Mobile (iOS + Android) using Flutter
Backend: Firebase (Firestore, Auth, Cloud Messaging)

Purpose:
A mobile application designed to help users plan, execute, and track daily routines, work blocks, and tasks while providing AI-assisted accountability, scoring, and reflection. The app ensures consistency, prevents procrastination, and helps users retain knowledge through note-taking and revision reminders.

Target User:

Individuals aiming to improve productivity and consistency

Learners, developers, or professionals managing tasks, routines, and habits

Users who want AI accountability beyond traditional reminder apps

Key Differentiators:

AI-driven accountability and nudges

Multi-mode escalation system (Easy → Normal → Discipline → Extreme)

Routine → Block → Task hierarchy with timers

Notes & revision reminders integrated into task flow

Hard alarms for extreme wake-up accountability

2. User Stories & Flows
2.1 Night-Before Planning

As a user, I want to:

Create routines (Morning / Afternoon / Night)

Add weekly blocks with tasks and estimated durations

Prioritize tasks

Set alarms (normal or hard) for wake-up

Flow:

Open “Plan Tomorrow” screen

Add routines → Add blocks → Add tasks

Assign duration and priority for each task

Set alarm type

Save plan → stored in Firebase under users/{uid}/routines

2.2 Wake-Up / Morning Routine

As a user, I want to:

Wake up on time according to selected alarm type

Start my morning routine with clear guidance

Flow:

Alarm triggers (normal or hard escalation with embarrassing audio if snoozed)

User dismisses alarm

App shows first task of morning routine

Option: Plans Changed?

Prompts: Feeling vs Logical

AI evaluates if schedule adjustment is valid

2.3 Task Execution & Timer

As a user, I want to:

Start a task timer

Confirm completion

Get scoring feedback

Flow:

Tap “Start Task” → Timer begins

Upon completion, app asks: “Did you really do what you said?”

Score task based on:

Completion percentage

Time adherence

Notes/reason for partial completion

In Hard/Discipline Mode:

If incomplete → app re-prompts persistently

AI can provide reasoning/nudges until completion

2.4 Work Blocks

As a user, I want to:

See a block of tasks as a unit

Start and complete tasks sequentially

Review performance at the end of the block

Flow:

Open block → view task list

Start block → timer per task

Complete tasks → AI reflection stored

Block score calculated → suggestions for improvement

2.5 Notes & Revision

As a user, I want to:

Take notes during routines/blocks

Set review dates for notes

Receive reminders for revision at appropriate times

Flow:

Add note → topic, content, review date, optional block association

App triggers reminder → integrates into task/block workflow

2.6 Modes & Escalation
Mode	Description
Easy	Gentle reminders; user can skip tasks without penalty
Normal	Repeated reminders; scoring applied
Discipline	Persistent prompts until task completed or valid reason provided
Extreme	Hard alarms, embarrassing audio escalation, forced AI check-ins
3. Features / Modules

Routine Planner

Night-before planning

Routine → Block → Task hierarchy

Duration & priority assignment

Task Timer

Per-task timer with start/stop

Pomodoro mode optional for deep work

Alarm System

Normal alarms

Hard alarm escalation (embarrassing audio)

Repeat notifications

AI Accountability

Morning check-in / Evening reflection

Evaluates “Plans Changed?” decisions

Motivational nudges / scoring feedback

Modes / Escalation

Configurable modes (Easy → Extreme)

Persistent reminders & forced prompts in hard modes

Scoring System

Task-level scoring

Block-level performance

Daily summary

Notes & Revision

Note creation with topic & review date

Reminders for revision linked to task/block flow

4. Firebase Architecture

Collections & Documents:

users/{uid}
  ├─ routines/{routineId}
      ├─ blocks/{blockId}
          ├─ tasks/{taskId}
  ├─ notes/{noteId}
  ├─ alarms/{alarmId}
  ├─ aiReflections/{reflectionId}

Why:

Flat, predictable structure

Easy per-user security rules

Offline caching supported

5. Flutter App Architecture

Presentation Layer (UI)

Routine Dashboard

Block & Task Screens

Timer UI

Notes UI

Domain Layer (Logic)

Timer & Pomodoro

Scoring & completion rules

Mode escalation logic

AI integration & “Plans Changed?” reasoning

Data Layer

Firebase CRUD operations

Offline persistence

Synchronization & notifications

6. MVP Scope (V1–V3)

V1 – Execution Starter

Night-before planning

Task timer

Basic reminders

Score task completion manually

V2 – Structured Routines

Morning/Afternoon/Night routines

Auto-next-task flow

“Plans Changed?” option

Task duration & priority

V3 – Accountability

Modes (Easy → Extreme)

Persistent reminders

AI nudges (basic motivational messages)

Hard mode escalation

7. Future Versions (V4–V7)

V4: Adaptive AI Coach – reflection & planning suggestions

V5: Focus & deep work enhancements – Pomodoro, AI trend analysis

V6: Knowledge retention – notes linked to blocks & review reminders

V7: Hardcore Discipline – lock UI, forced completion, proof verification

8. Non-Functional Requirements

Offline-first: Timers, task completion, alarms work offline

Scalable: Firebase collections designed per-user

Cross-platform: Flutter UI responsive for iOS & Android

Extensible: Mode escalation and AI integration configurable

9. Success Metrics

Daily routine completion rate

Task/block completion percentage

Accuracy of self-reported completion vs timer logs

Frequency of plan changes and AI intervention

User engagement with notes/revision