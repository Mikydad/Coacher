# PRD — Layered Task Prioritization (V1)

## 1. Introduction / Overview

This PRD defines a deterministic, user-friendly task prioritization system for daily execution.

The app should present tasks in four clear layers:

1. Overdue scheduled tasks  
2. Upcoming scheduled tasks  
3. "Do Now" (quick wins)  
4. Flexible tasks (sorted by score)

Goal: improve follow-through and reduce decision friction by showing users what to do next in a predictable order.

---

## 2. Goals

1. Ensure time-bound tasks are never hidden behind flexible tasks.
2. Reduce user hesitation with a small "Do Now" quick-win set.
3. Keep prioritization explainable and stable (no opaque black-box ranking in V1).
4. Integrate with existing Focus/Home/Tasks flows without breaking current behavior.
5. Prepare data/logic for future adaptive scoring (streak risk, behavior learning).

---

## 3. User Stories

- As a user, I want overdue scheduled tasks shown first so I can recover my day quickly.
- As a user, I want upcoming timed tasks ordered by nearest time so I can stay on schedule.
- As a user, I want a small "Do Now" list so I can act immediately without overthinking.
- As a user, I want remaining flexible tasks ordered sensibly so I still see what matters.
- As a user, I want this ordering to be consistent across Home, Focus, and Tasks views.

---

## 4. Functional Requirements

### 4.1 Definitions

1. **Scheduled task**: a task with a valid scheduled time (`reminderTimeIso` for today).
2. **Flexible task**: a task without a scheduled time.
3. **Overdue scheduled**: scheduled time is earlier than "now" and task is still open.
4. **Upcoming scheduled**: scheduled time is now or later and task is still open.
5. **Open task statuses**: `notStarted`, `inProgress`, `partial`.
6. Completed tasks are excluded from prioritization lists.

### 4.2 Four-Layer Ordering

7. The app must build one ordered list using this layer sequence:
   - L1: overdue scheduled tasks
   - L2: upcoming scheduled tasks
   - L3: do-now quick wins (subset of flexible)
   - L4: remaining flexible tasks
8. L1 and L2 tasks must always appear before L3 and L4.
9. L1 and L2 are ordered by scheduled time ascending (earliest first).
10. L1 "overdue" status should be based on local device time.

### 4.3 "Do Now" Quick Wins (Layer 3)

11. "Do Now" can include up to 3 flexible tasks.
12. Candidate pool is flexible open tasks not already in L1/L2.
13. Do-now ranking should prefer:
   - shorter duration (`durationMinutes` ascending),
   - higher priority (`priority` ascending, where `1` is highest),
   - then stable fallback by `orderIndex`, then `id`.
14. Do-now tasks must be removed from L4 to avoid duplicates.

### 4.4 Flexible Score Ordering (Layer 4)

15. Remaining flexible tasks should use a transparent V1 score:

```
score = (priorityWeight * priorityScore) + (urgencyWeight * urgencyScore) + (easeWeight * easeScore)
```

16. V1 score inputs:
   - `priorityScore`: derived from task `priority` (1 highest).
   - `urgencyScore`: derived from block urgency (or default mid value if unavailable).
   - `easeScore`: inverse of `durationMinutes` (shorter task = higher ease).
17. Suggested default weights in V1:
   - priorityWeight = 0.5
   - urgencyWeight = 0.3
   - easeWeight = 0.2
18. If score ties, fallback order must be deterministic: `orderIndex`, then `id`.

### 4.5 Output Shape

19. Prioritization should expose task rows plus a layer label:
   - `overdueScheduled`
   - `upcomingScheduled`
   - `doNow`
   - `flexible`
20. Consumers (Home/Focus/Tasks) may render as grouped sections or a flattened ordered list.
21. V1 may keep current UI while using flattened ordered output first; sectioned UI is optional in this phase.

### 4.6 Integration Points

22. Integrate prioritization in:
   - Home "What next" / task order source.
   - Focus task selection list.
   - Tasks page "Today" ordering (unless user manually reorders).
23. Next-task suggestion (`NextTaskRanker`) should align with new layer order logic.
24. Existing auto-next flow behavior remains unchanged; only candidate ranking source changes.

### 4.7 Manual Reorder Compatibility

25. If user manually reorders in Tasks Hub, app should preserve user intent for equal-priority/untimed ties.
26. Scheduled-time precedence still applies over flexible tasks in V1.

### 4.8 Time Parsing and Validation

27. Invalid or unparsable scheduled times must be treated as flexible.
28. Date mismatch (scheduled time not on today) should not place task into scheduled layers for today's ranking.

---

## 5. Non-Goals (Out of Scope)

- Fully adaptive AI ranking based on historical completion behavior.
- Streak break prediction model in V1.
- Cross-day reprioritization optimization.
- New backend schema migrations beyond existing fields.
- Complex per-user weight tuning UI in V1.

---

## 6. Design Considerations

- Prioritization should feel obvious to users ("time first, then quick wins, then rest").
- Overdue tasks should be visually distinct when sectioned UI is added.
- Keep "Do Now" list small (max 3) to avoid cognitive overload.
- Avoid abrupt order jitter on minor state updates.

---

## 7. Technical Considerations

- Implement a dedicated prioritizer utility/service in planning application layer (e.g. `task_prioritizer.dart`).
- Reuse existing `PlannedTaskRow`, `NextTaskRanker`, and `planned_task_providers` data pipelines.
- Parse `reminderTimeIso` safely with timezone-aware assumptions aligned to existing reminder logic.
- Keep ordering deterministic and testable with pure functions.
- Preserve local-first behavior (Isar source + reactive providers).

---

## 8. Implementation Sequence

### Phase 1: Prioritizer Core

1. Add pure prioritization module for layered ordering.
2. Add typed output model including layer kind.
3. Add time parsing helpers and overdue/upcoming classification.

### Phase 2: Wire to Providers

4. Apply layered ordering in providers used by Home/Focus/Tasks.
5. Keep current UI rendering, but consume new sorted output.

### Phase 3: Do-Now + Flexible Score

6. Implement do-now subset extraction (max 3).
7. Implement flexible scoring and deterministic tie breaks.

### Phase 4: Ranker Alignment

8. Align `NextTaskRanker` candidate ordering with layered output (or replace internally with layered selection).

### Phase 5: Validation

9. Add unit tests for each layer and edge cases.
10. Add widget/integration checks for Home/Focus/Tasks ordering consistency.

---

## 9. Success Metrics

1. Higher rate of users starting a task within 60s of opening Focus/Home.
2. Reduced skipped/abandoned overdue scheduled tasks.
3. Increased completion of short "Do Now" tasks.
4. Lower user confusion about "what should I do next?".
5. No regressions in timer, scoring, reminder, and auto-next flows.

---

## 10. Open Questions

1. Should overdue scheduled tasks always appear before a currently in-progress flexible task, or should active task remain pinned first?
2. Should manually reordered flexible tasks override score completely, or only for tie-breaks?
3. Should "Do Now" show as its own section in V1 UI or remain internal ordering only?
4. Should priority weight values be constants or remote-configurable for quick tuning?
