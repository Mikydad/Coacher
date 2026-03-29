# V2 Release Readiness Gates

## Stability
- No analyzer errors in touched V2 modules.
- No failing tests in planning/reminders/execution suites.
- No startup crashes with stale reminder cache data.

## Reminder Reliability
- Adaptive cadence policy validated for all modes and urgency bands.
- Escalation transitions validated (persistent -> app-open -> gated path eligibility).
- Safety guardrail validated: emergency bypass disables hard-gate path.

## Data Integrity + Migration
- Legacy docs load without crashes for routine/task/reminder/accountability models.
- Accountability retention worker runs on bootstrap and prunes logs older than 30 days.
- Delete/export controls produce expected outputs without malformed payloads.

## UX Flow
- Home shows current block + next recommended task quick action.
- Tasks Hub supports next-task suggestion and plans-changed logging path.
- Plan Tomorrow supports per-slot mode control and preserves mode on reorder/rename.

## Telemetry Baseline (Manual/Operational)
- Daily completion trend is observable with no regression from previous baseline.
- "I don't know what to do next" self-report prompt available for post-release sampling.
- Accountability export reviewed for support/debug use in first production week.
