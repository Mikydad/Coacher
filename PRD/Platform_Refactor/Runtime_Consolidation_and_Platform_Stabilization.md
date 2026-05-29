# Runtime Consolidation & Platform Stabilization PRD

# Overview

The app has evolved beyond a simple productivity tracker. It now contains:

* AI assistant execution
* TimeBlock scheduling
* conflict detection
* inline conflict resolution
* proactive coaching
* layered analytics (L1–L4)
* reminders
* context overrides
* notification orchestration
* AI summaries
* streak systems
* local-first persistence
* planning intelligence

The architecture is now entering a critical transition point:

```text
feature expansion
→
runtime orchestration consolidation
```

The primary engineering problem is no longer missing features.

The primary problem is:

```text
multiple authoritative systems
without a unified mutation/recompute pipeline
```

This phase focuses on consolidating runtime behavior into a coherent platform before scaling to:

* multi-device
* subscriptions
* community
* advanced AI automation
* production-scale notifications

---

# Core Problems Identified

## 1. Distributed Side Effects

Current mutations manually trigger:

* provider invalidations
* reminder reschedules
* overlap syncs
* analytics refreshes
* suggestion recomputes

in inconsistent ways.

Result:

* stale coaching
* stale focus
* inconsistent reminders
* stale overlaps
* duplicated recomputes
* UI disagreement

---

## 2. Split Schedule Authority

Authority currently split between:

* PlannedTask
* ScheduledTimeBlock
* ReminderConfig
* AttentionOrchestrator
* Goal reminder systems

No single runtime authority exists.

---

## 3. AI Execution Safety Risks

Current risks:

* partial writes
* stub actions
* no rollback
* no transaction boundary
* reminder/task divergence
* overlap validation inconsistencies

---

## 4. Notification Authority Fragmentation

Task reminders:

* orchestrated

Goal reminders:

* direct local notifications

Coaching notifications:

* separate Layer4 path

This creates:

* inconsistent suppression
* inconsistent fatigue handling
* collision risks

---

# Phase Goal

Create a unified runtime architecture where:

```text
all mutations
→
flow through one controlled pipeline
→
produce deterministic recompute behavior
→
reconcile notifications consistently
```

---

# PHASE 1 — Runtime Consolidation Core

# 1. ScheduleMutationCoordinator

## Purpose

Single authoritative mutation pipeline.

All schedule-affecting changes MUST flow through this system.

Examples:

* manual task edit
* AI edit
* drag/drop
* overlap resolution
* snooze escalation
* task completion
* context override changes
* reminder edits

---

## Current Problem

Today:

* mutations directly trigger side effects
* invalidations are scattered
* recomputes are inconsistent

---

## New Architecture

```text
Mutation Request
        ↓
Validation
        ↓
Atomic Commit
        ↓
Derived Recompute
        ↓
Notification Reconciliation
        ↓
Event Publish
```

---

## Responsibilities

Coordinator owns:

* mutation sequencing
* transaction boundaries
* invalidation orchestration
* recompute graph triggering
* notification reconciliation
* event publishing

---

## Required API

```dart
scheduleMutationCoordinator.run(
   mutation: ...
)
```

---

# 2. Domain Event System

# Purpose

Replace:

* random provider invalidations
* manual cross-system triggers

with:

* predictable runtime events

---

# Required Events

```dart
TaskCreated
TaskUpdated
TaskDeleted

TaskCompleted
TaskDeferred

TimeBlockChanged

ReminderChanged

ContextOverrideChanged

FocusChanged

ScheduleConflictResolved
```

---

# Subscriber Examples

Analytics:

* recompute streaks
* recompute momentum

Suggestions:

* recompute proactive cards

Attention:

* reconcile notifications

AI:

* refresh summaries

---

# Goal

```text
systems subscribe to events
instead of manually invalidating each other
```

---

# 3. Unified Recompute Graph

# Current Problem

Some systems recompute automatically.
Others require manual invalidation.

Examples:

* focus stale after edits
* suggestions refresh separately
* coaching refresh manual

---

# Goal

Central recompute authority.

---

# Required Recompute Flow

After schedule mutation:

```text
1. overlaps
2. analytics bundle
3. streaks
4. coaching focus
5. proactive suggestions
6. layer3 insights
7. layer4 delivery
8. AI summaries
9. notification reconciliation
```

---

# Requirements

* debounce recomputes
* coalesce duplicate requests
* generation-based stale protection
* background-safe execution

---

# 4. Notification Ledger

# Purpose

Persist notification authority.

Current orchestrator state is partially in-memory.

This creates:

* stale alarms
* lost orchestration state
* reconciliation problems

---

# Required Model

```dart
class NotificationLedger {

String entityId;

String notificationId;

DateTime scheduledFor;

String source;

String status;

DateTime reconciledAt;

}
```

---

# Required Behavior

On:

* boot
* resume
* sync
* override changes
* task edits

Run:

* notification reconciliation

---

# Goal

```text
OS alarms
==
ledger
==
reminder configs
==
orchestrator state
```

---

# 5. AI Executor Hardening

# Current Problems

* partial writes
* no rollback
* inconsistent validation
* no transaction grouping

---

# Required Architecture

## AiChangeSet

All AI operations become:

```dart
AiChangeSet
```

containing:

* intended mutations
* validation results
* preview snapshot
* rollback snapshot

---

# Execution Flow

```text
AI Parse
      ↓
ChangeSet Build
      ↓
Validation
      ↓
Conflict Check
      ↓
Dry Run Preview
      ↓
User Confirmation
      ↓
Atomic Commit
      ↓
Recompute Graph
      ↓
Notification Reconcile
```

---

# Required Validation

Validate:

* overlap conflicts
* reminder collisions
* invalid times
* duplicate tasks
* sleep conflicts
* impossible schedules
* stale entities

---

# Required Features

* rollback support
* undo support
* idempotency keys
* retry-safe execution

---

# PHASE 2 — Identity & Multi-Device Foundation

# Goal

Transition from:

```text
single-device tolerant
```

to:

```text
identity-based platform
```

---

# 1. Firebase Auth

Required:

* anonymous auth
* email/password
* Google Sign-In

Future:

* Apple Sign-In

---

# 2. UID-scoped Isar

Current:

* global local database

Required:

* per-user local isolation

---

# Goal

Prevent:

* account leakage
* reminder leakage
* analytics mixing
* wrong schedule ownership

---

# 3. Sync Integrity Layer

Required:

* revision/version fields
* merge strategy
* delete propagation
* stale cleanup
* reminder reconciliation
* sync conflict handling

---

# Current Problem

Current sync is:

```text
eventually consistent
+
LWW
```

but lacks:

* user-visible conflict handling
* stronger integrity guarantees

---

# 4. Session Management

Required:

* logout
* account switching
* guest upgrade
* cloud restore

---

# PHASE 3 — Subscription Infrastructure

# Goal

Introduce monetization after:

* runtime stable
* sync stable
* identity stable

---

# 1. RevenueCat Integration

Required:

* trial support
* entitlement sync
* restore purchases

---

# 2. EntitlementService

Capabilities:

```dart
canUseAI

canUseCloudSync

canUseCommunity

canUseAdvancedAnalytics
```

---

# Requirement

No scattered paywall logic.

All premium gating flows through:

```dart
EntitlementService
```

---

# 3. Trial System

Recommended:

* 7–14 day full access trial

---

# PHASE 4 — Attention Intelligence

# Goal

Improve:

* notification quality
* fatigue prevention
* batching
* suppression
* dynamic escalation

---

# Required Systems

* notification batching
* fatigue scoring
* delivery prioritization
* collision grouping
* intelligent suppression

---

# PHASE 5 — Community / Accountability Circles

Build:

* groups
* challenges
* proof posts
* AI group pulse
* moderation
* shared goals

Only AFTER:

* identity stable
* sync stable
* notification orchestration stable

---

# PHASE 6 — Advanced AI

Expand:

* proactive AI
* adaptive planning
* predictive scheduling
* autonomous suggestions
* advanced personalization

---

# Engineering Rules Going Forward

# 1. No direct cross-system invalidations

Everything must flow through:

* coordinator
* events
* recompute graph

---

# 2. No direct notification scheduling

All notifications must flow through:

```text
AttentionOrchestrator
```

---

# 3. No direct AI mutations

AI only creates:

```text
AiChangeSet
```

Execution handled centrally.

---

# 4. No duplicated schedule authority

Schedule truth must eventually consolidate around:

* tasks
* time blocks
* orchestrator
* notification ledger

with deterministic ownership.

---

# Branch Strategy

Create dedicated branch:

```text
runtime-consolidation
```

This phase is too large and cross-cutting for direct main branch work.

---

# Final Assessment

Current phase:

```text
pre-scale orchestration consolidation
```

The app already contains many advanced systems.

The next challenge is not feature quantity.

The next challenge is:

```text
making all systems behave as one coherent runtime platform
```
