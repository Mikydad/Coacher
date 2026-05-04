## Relevant Files

- `PRD/prd-habit-task-analytics-coaching-v1-v4.md` - Source PRD for analytics/coaching roadmap.
- `lib/features/planning/domain/models/task_item.dart` - Planned task model fields (`isHabitAnchor`, status, reminder fields).
- `lib/features/planning/application/habit_anchor_aggregator.dart` - Unified habit anchor and overlap utility.
- `lib/features/goals/domain/models/user_goal.dart` - Goal reminder source for habit anchors.
- `lib/features/goals/application/goals_providers.dart` - Active/today goals provider wiring.
- `lib/features/reminders/domain/models/reminder_config.dart` - Reminder schedule source-of-truth fields.
- `lib/features/reminders/application/reminder_sync_service.dart` - Reminder scheduling/update behavior.
- `lib/features/planning/application/planned_task_providers.dart` - Today/home task snapshots and stream refresh.
- `lib/features/planning/application/task_prioritizer.dart` - Task ordering layers and tie-break behavior.
- `lib/features/planning/application/auto_next_task_flow.dart` - Runtime next-task prompt and overlap notices.
- `lib/features/home/presentation/home_screen.dart` - Home coaching card and next action surface.
- `lib/features/add_task/presentation/add_task_screen.dart` - Add/edit flow and overlap warning dialog.
- `lib/core/local_db/isar_collections/` - Isar schema/entities for local analytics data.
- `lib/core/sync/` - Sync queue + remote merge behavior for hybrid analytics persistence.
- `test/features/planning/` - Planning analytics/streak/overlap tests.
- `test/features/reminders/` - Reminder regression tests.
- `test/core/sync/` - Sync correctness tests for hybrid data.

### Notes

- Keep V1 intentionally lean: event log + streak + completion + risk + one chart + deterministic insights.
- All canonical metric computations must be deterministic and test-backed.
- AI layer should explain computed insights only; never compute canonical KPI values.
- Preserve offline-first behavior and avoid regressions in existing reminder/timer flows.

## Tasks

- [ ] 1.0 Create analytics foundation (Hybrid data contract)
  - [ ] 1.1 Define analytics event schema contract (types, required metadata, dedupe/idempotency keys).
  - [ ] 1.2 Add local-first analytics storage model(s) for events and lightweight stats cache.
  - [ ] 1.3 Add Firestore mirror paths/DTOs for `analytics_events` and `stats` documents.
  - [ ] 1.4 Implement sync strategy (enqueue/push/pull/merge) for analytics entities.
  - [ ] 1.5 Add schema/version marker for forward-compatible metric upgrades.

- [ ] 2.0 Build canonical streak engine (single source of truth)
  - [ ] 2.1 Define streak rules (day boundaries, timezone-local date key, missed-day semantics).
  - [ ] 2.2 Implement current streak and longest streak calculators from event log.
  - [ ] 2.3 Handle edge cases (same-day duplicates, backfilled events, DST/daylight transitions).
  - [ ] 2.4 Expose streak API/provider for Home + habit surfaces.

- [ ] 3.0 Implement V1 KPI calculators
  - [ ] 3.1 Completion rate calculators: today + rolling 7-day.
  - [ ] 3.2 Risk level heuristic: missed yesterday => medium, missed 2+ => high.
  - [ ] 3.3 Include deterministic fallback when data is sparse/empty.
  - [ ] 3.4 Persist cached KPI snapshot for fast UI load (local first, sync mirror optional in V1).

- [ ] 4.0 Instrument event logging across key user actions
  - [ ] 4.1 Habit events: completed/skipped/snoozed/missed_window.
  - [ ] 4.2 Task behavior events: started/completed/deferred/overlap_override/auto_next_started.
  - [ ] 4.3 Ensure each event carries `timestampLocal`, `dateKey`, `sourceSurface`, entity id, optional reason.
  - [ ] 4.4 Ensure logging does not block critical UX flows (fire-and-forget + retry queue).

- [ ] 5.0 Deliver V1 visualization + coaching surfaces
  - [ ] 5.1 Add one weekly consistency chart (heatmap or bar) in a single designated screen.
  - [ ] 5.2 Add Home coaching summary card (streak + completion + risk + next action).
  - [ ] 5.3 Avoid dashboard sprawl: keep out-of-scope chart surfaces disabled in V1.

- [ ] 6.0 Implement deterministic insight engine (pre-AI)
  - [ ] 6.1 Add insight template contract: observation -> evidence -> recommendation.
  - [ ] 6.2 Implement initial insight rules:
    - [ ] 6.2.1 Morning completion bias insight.
    - [ ] 6.2.2 Repeat skips this week insight.
    - [ ] 6.2.3 Streak at risk insight.
  - [ ] 6.3 Add urgency/confidence prioritization for which insight is shown first.
  - [ ] 6.4 Ensure each insight maps to a user action.

- [ ] 7.0 Phase-3 scalability layer (post-V1 but in this PRD roadmap)
  - [ ] 7.1 Add daily materialized snapshots for performance/backfill.
  - [ ] 7.2 Add richer behavior metrics (overlap rate, defer trend, recovery latency).
  - [ ] 7.3 Add migration/backfill strategy when formulas are updated.

- [ ] 8.0 Phase-4 AI explanation layer (future-gated)
  - [ ] 8.1 Define strict AI input contract from computed deterministic insights only.
  - [ ] 8.2 Add AI output safety contract (no KPI mutation, confidence tags, grounded references).
  - [ ] 8.3 Add fallback behavior when AI is unavailable or low-confidence.
  - [ ] 8.4 Add explicit privacy/consent controls for remote AI usage.

- [ ] 9.0 Testing and validation
  - [ ] 9.1 Unit tests for streak formulas and KPI calculators.
  - [ ] 9.2 Unit tests for analytics event dedupe/idempotency.
  - [ ] 9.3 Unit tests for deterministic insight rules and ranking.
  - [ ] 9.4 Integration tests for Home/Focus/Tasks/auto-next consistency with analytics updates.
  - [ ] 9.5 Sync tests for local-first + Firestore mirror convergence.
  - [ ] 9.6 Run `flutter analyze` and fix new diagnostics.
  - [ ] 9.7 Run focused tests, then full `flutter test`.

- [ ] 10.0 Manual QA and release gates
  - [ ] 10.1 Verify streak correctness across normal, skipped, and recovery days.
  - [ ] 10.2 Verify chart consistency with raw event history.
  - [ ] 10.3 Verify overlap/defer actions update metrics and insights correctly.
  - [ ] 10.4 Verify offline usage + reconnect sync does not duplicate events or skew KPIs.
  - [ ] 10.5 Verify each analytics surface provides a clear “what to do next” action.
