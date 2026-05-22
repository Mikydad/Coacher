# PRD: Phase A — Time Block Foundation

## 1. Introduction / Overview

Currently, tasks and habits in Coach for Life are treated as floating reminders
with a scheduled time but no concept of occupied duration. This means two
90-minute habits can be "scheduled" at the same time with no warning, the app
has no idea when a time window is actually free, and early completions produce
no useful information.

Phase A builds the foundational data layer that treats every scheduled
task/habit as an **occupied time window** — a `ScheduledTimeBlock`. It adds a
**conflict detection engine** that identifies real scheduling overlaps, and a
**soft-interruption UI flow** that informs the user without hard-blocking them.
It also captures reclaimed time when a task finishes early.

This phase is purely foundational — it does not change notification delivery,
escalation behavior, or the mode system. Those are Phase B, C, and D.

---

## 2. Goals

1. Give every scheduled task/habit a concrete occupied time window in the local
   store.
2. Detect real scheduling conflicts before they are saved, using a smart combined
   threshold (not binary).
3. Inform the user via a non-blocking soft-interruption flow when conflicts exist.
4. Track reclaimed time when tasks complete early and surface a passive suggestion.
5. Log time-block-related analytics events through the existing event system.
6. Keep the system fully local-first and offline-safe. No Firestore sync of time
   blocks yet.

---

## 3. User Stories

- As a user scheduling a new task, I want to see a warning if it overlaps with
  something I already have planned, so I can decide whether to adjust or proceed.
- As a user, I want to be able to override a conflict and save anyway, because
  some overlaps are intentional.
- As a user who finishes a task earlier than expected, I want the app to notice
  and optionally suggest using the freed time productively.
- As a developer/coach engine, I want to query which time windows are occupied
  for a given date range, so future phases can make smarter scheduling decisions.

---

## 4. Functional Requirements

### 4.1 ScheduledTimeBlock model

**FR-A-01** — The system must define a `ScheduledTimeBlock` model with the
following fields:

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Stable UUID |
| `entityId` | `String` | ID of the owning task or habit |
| `entityKind` | `String` | `"task"` or `"habit"` |
| `startAt` | `DateTime` | Scheduled start time |
| `expectedDurationMinutes` | `int` | Planned duration in minutes |
| `computedEndAt` | `DateTime` | Derived: `startAt + expectedDurationMinutes` |
| `flexibilityType` | `FlexibilityType` | `flexible` or `rigid` — set per entity |
| `allowOverlapOverride` | `bool` | Whether the user explicitly allowed this overlap |
| `importance` | `int` | 0–100 importance score (used for conflict severity weighting) |
| `createdAtMs` | `int` | Epoch ms |
| `updatedAtMs` | `int` | Epoch ms |
| `schemaVersion` | `int` | Schema version (starts at 1) |

**FR-A-02** — `FlexibilityType` must be an enum with values `flexible` and
`rigid`. Both tasks and habits can be set to either value individually.

**FR-A-03** — A block is considered a **hard block** if `flexibilityType ==
rigid`. Hard blocks escalate conflict severity (see FR-A-09).

### 4.2 Time block creation

**FR-A-04** — When a task or habit is saved with a scheduled time AND a
duration, the system must automatically derive and upsert a `ScheduledTimeBlock`
from it. No separate user action is required.

**FR-A-05** — When a task or habit has no scheduled time or no duration, no
`ScheduledTimeBlock` is created for it.

**FR-A-06** — When a task or habit is deleted or its schedule is cleared, the
corresponding `ScheduledTimeBlock` must be deleted.

### 4.3 TimeBlockRepository

**FR-A-07** — The system must implement a `TimeBlockRepository` backed by Isar
(local-first, no Firestore sync in this phase) with the following operations:

- `upsertBlock(ScheduledTimeBlock block)` — insert or update
- `deleteBlock(String id)` — delete by block ID
- `deleteBlockForEntity(String entityId)` — delete all blocks for an entity
- `listBlocksForDateRange(DateTime start, DateTime end)` — return all blocks
  whose time window intersects the range
- `listOverlappingBlocks(ScheduledTimeBlock proposed)` — return all existing
  blocks that overlap with the proposed block (using the conflict threshold rule,
  see FR-A-08)

### 4.4 Conflict detection engine

**FR-A-08** — A conflict exists between two blocks if **either** of the
following is true:
- Absolute overlap `≥ 5 minutes`
- Overlap `≥ 15%` of the shorter block's duration

*Examples:*

| Scenario | Conflict? |
|----------|-----------|
| 2 min overlap on two 60 min tasks | No |
| 6 min overlap on a 20 min task | Yes (> 5 min) |
| 15 min overlap on two 120 min tasks | Yes (> 12.5% of shorter) |
| 3 min overlap on a 10 min task | Yes (= 30% of shorter) |

**FR-A-09** — The `ConflictDetectionEngine` must compute a `severity` score
(0.0–1.0) for each conflict using a continuous formula:

```
severity = overlapRatio + hardnessMultiplier + importanceWeight

where:
  overlapRatio       = overlap_minutes / shorter_block_duration_minutes (clamped 0–1)
  hardnessMultiplier = 0.3 if either block is rigid, else 0.0
  importanceWeight   = max(blockA.importance, blockB.importance) / 100 * 0.2

final severity = min(severity, 1.0)
```

**FR-A-10** — The engine must classify conflicts into severity tiers for display:

| Score range | Label |
|-------------|-------|
| 0.0 – 0.35 | `minor` |
| 0.36 – 0.65 | `moderate` |
| 0.66 – 1.0 | `severe` |

**FR-A-11** — `ConflictDetectionEngine.detect()` must accept:
- `proposed: ScheduledTimeBlock` — the block being saved
- `existing: List<ScheduledTimeBlock>` — blocks in the overlap window

And must return `List<TimeConflict>`, where `TimeConflict` contains:

| Field | Type | Description |
|-------|------|-------------|
| `conflictingEntityId` | `String` | Entity ID of the conflicting block |
| `conflictingEntityKind` | `String` | `"task"` or `"habit"` |
| `overlapMinutes` | `int` | Duration of the overlap |
| `severity` | `double` | 0.0–1.0 continuous score |
| `severityLabel` | `ConflictSeverity` | `minor`, `moderate`, `severe` |
| `conflictType` | `ConflictType` | `partialOverlap`, `fullOverlap`, `contained` |

**FR-A-12** — The engine must be purely functional (no I/O, no Riverpod). It
takes lists and returns results. Persistence and querying are handled by
`TimeBlockRepository`.

### 4.5 Scheduling validation flow

**FR-A-13** — Before saving a task or habit with a scheduled time, the system
must:
1. Derive the proposed `ScheduledTimeBlock`
2. Query `TimeBlockRepository.listOverlappingBlocks(proposed)`
3. Run `ConflictDetectionEngine.detect(proposed, existing)`
4. If conflicts exist, return a structured `ConflictCheckResult` to the caller
5. NOT hard-block saving — the user decides what to do

**FR-A-14** — `ConflictCheckResult` must contain:
- `hasConflicts: bool`
- `conflicts: List<TimeConflict>`
- `worstSeverity: ConflictSeverity?`

**FR-A-15 (Soft-interruption UI flow)** — When `hasConflicts == true` and the
user attempts to save:
- Show a bottom sheet listing each conflict with its severity label and the name
  of the conflicting entity
- Provide the following action options:
  - **Save anyway** (sets `allowOverlapOverride = true` on the block)
  - **Adjust time** (closes the sheet and returns user to editing)
  - **Shorten duration** (closes the sheet and focuses the duration field)
- The user must be able to dismiss and still choose to save — this is never a
  hard block

**FR-A-16** — If the user saves with `allowOverlapOverride = true`, log an
`overlapOverridden` analytics event.

**FR-A-17** — Minor conflicts (`severity < 0.36`) may optionally show only an
inline banner rather than the full bottom sheet — this is a UI detail for the
implementing developer to decide based on feel.

### 4.6 Early completion — reclaimed time

**FR-A-18** — When a task completes before its `expectedDurationMinutes`, the
system must compute an `AvailableTimeWindow`:

| Field | Type | Description |
|-------|------|-------------|
| `entityId` | `String` | The task that completed early |
| `windowStartAt` | `DateTime` | Time of early completion |
| `windowEndAt` | `DateTime` | Originally scheduled end time |
| `durationMinutes` | `int` | Reclaimed minutes |
| `createdAtMs` | `int` | Epoch ms |

**FR-A-19** — The system must NOT automatically reschedule any other task into
the reclaimed window. It only computes and exposes the window.

**FR-A-20** — When reclaimed time is ≥ 10 minutes, the system must show a
passive suggestion to the user (e.g. a snackbar or card):
> "You freed up 20 minutes. Want to tackle something from your list?"

The suggestion links to the task list. It does NOT auto-assign anything.

**FR-A-21** — Log a `reclaimedTimeGenerated` analytics event when an
`AvailableTimeWindow` is created.

**FR-A-22** — If the user taps the suggestion and opens the task list, log a
`reclaimedTimeUsed` analytics event.

### 4.7 Analytics signals

**FR-A-23** — Add the following new values to the existing `AnalyticsEventType`
enum:

- `overlapCreated` — a block was saved with a detected overlap (override or not)
- `overlapOverridden` — the user explicitly saved despite a conflict warning
- `reclaimedTimeGenerated` — an `AvailableTimeWindow` was computed
- `reclaimedTimeUsed` — the user acted on a reclaimed time suggestion

These events use the same `AnalyticsEvent` model and `analyticsRepositoryProvider`
as all other events.

---

## 5. Non-Goals (Out of Scope for Phase A)

- **No changes to notification scheduling, escalation, or cadences** — that is Phase C.
- **No Firestore sync** of `ScheduledTimeBlock` records — Isar only.
- **No auto-rescheduling** of other tasks when a conflict is detected.
- **No calendar integration** (no importing OS calendar events).
- **No collaborative scheduling** or multi-device coordination.
- **No UI redesign** of the task/habit editing screens beyond the conflict bottom sheet.
- **No suppression of reminders** based on occupied time — that is Phase B/C.
- **No changes to the mode system** (flexible/disciplined/extreme) — that is Phase D.

---

## 6. Design Considerations

- The conflict bottom sheet should follow the existing app bottom sheet pattern.
- Severity labels should be color-coded: minor = yellow, moderate = orange, severe = red.
- The reclaimed time suggestion should be a low-friction, dismissible snackbar or
  small card — not a modal. The user should never feel forced to act on it.
- `FlexibilityType` can be exposed on the task/habit edit screen as a simple
  toggle: "Fixed time" (rigid) vs "Flexible time" (flexible).

---

## 7. Technical Considerations

- `ScheduledTimeBlock` needs an Isar collection schema (`isar_scheduled_time_block.dart`).
- `ConflictDetectionEngine` must be a pure Dart class (no Flutter, no Isar,
  no Riverpod) to keep it unit-testable in isolation.
- `TimeBlockRepository` follows the same abstract + Isar implementation pattern
  used by `FocusRepository`, `InsightCacheRepository`, etc.
- The derivation of a `ScheduledTimeBlock` from a task/habit should happen inside
  a service layer (e.g. `TimeBlockSyncService`), not inside a widget or provider.
- `AvailableTimeWindow` does not need Isar persistence in Phase A — it can be
  computed in memory and passed to the UI via Riverpod state.
- The `ConflictCheckResult` should be returned from a Riverpod
  `FutureProvider.family` keyed by the proposed task/habit ID so the UI can
  reactively display conflicts.
- Isar schema list (`isar_schemas.dart`) must be updated to include
  `IsarScheduledTimeBlockSchema`.

---

## 8. Success Metrics

- Zero cases of overlapping tasks being saved silently (conflict detection
  coverage ≥ 99% of scheduled+duration task saves).
- Reclaimed time suggestions fire correctly for all early completions ≥ 10 min.
- `overlapOverridden` event logged consistently whenever the user proceeds
  through the conflict sheet.
- All new analytics event types are queryable in the existing analytics pipeline.
- `ConflictDetectionEngine` unit tests cover: no conflict, minor/moderate/severe,
  rigid vs flexible escalation, contained block, boundary edge cases.

---

## 9. Open Questions

- Should `importance` on `ScheduledTimeBlock` be manually set by the user, or
  derived from the task/habit's priority or enforcement mode? (Suggestion:
  derive from enforcement mode — extreme = 90, disciplined = 60, flexible = 30.)
- Should the reclaimed time suggestion appear immediately on task completion, or
  only after a short delay (e.g. 30 seconds) to avoid interrupting the completion
  celebration?
- When a task is edited (time changed), should the old `ScheduledTimeBlock` be
  deleted and replaced, or updated in-place? (Recommendation: upsert by `entityId`
  so there is always one block per entity.)
