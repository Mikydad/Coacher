# V2 Manual QA Checklist

## Mode Coverage (Flexible / Disciplined / Extreme)
- [ ] **Task vs routine:** If a task has an explicit execution mode on Add Task / edit, that mode wins for Home extension, override confirmation, and mandatory timer; if the task has no stored mode, behavior follows the parent routine (then flexible).
- [ ] Create one routine per mode and verify mode badge appears in Plan Tomorrow slot header.
- [ ] Complete a normal priority task in each mode and verify expected prompts.
- [ ] Complete high-priority task in Disciplined/Extreme and verify timer requirement behavior.

## Next-Task + Override Flows
- [ ] Complete a task from Home and verify next-task prompt appears.
- [ ] Use "Need extra time" and verify extension options respect mode limits.
- [ ] Use "Move to later" with structured reason and verify flow + accountability logs are created.
- [ ] Open Tasks Hub and use "What next" quick action to launch timer for suggested task.
- [ ] Use "Plans Changed?" from Tasks Hub and confirm log entry appears in Accountability History.

## Accountability History
- [ ] Open history from Home and filter by date range, mode, and reason category.
- [ ] Delete a single entry and verify list updates.
- [ ] Delete by date range and verify affected entries are removed.
- [ ] Export JSON and CSV and verify clipboard contents are well-formed.

## iOS Notification Behavior
- [ ] Extreme/Disciplined no-action flow: after first reminder, verify automatic follow-up nudges continue without tapping Snooze (disciplined: 3 in 10m + 3 in next 30m + hourly; extreme: 3 in 10m + 5 in next 30m + hourly x5).
- [ ] Reminder body tap opens Timer screen with 10s auto-start countdown and a visible Cancel action; cancel keeps timer not-started.
- [ ] Grant notifications, create reminder, force-close app, relaunch, verify reminders re-schedule.
- [ ] Trigger stale pending reminder and verify adaptive future schedule recovery.
- [ ] Snooze repeatedly in Disciplined/Extreme and verify interval shortens as escalation increases.
- [ ] Confirm reminders stop after task start or logical reason submission.
- [ ] Confirm emergency bypass path prevents hard gating behavior.

## Inline scheduling conflicts & form drafts
- [ ] Create a task that overlaps an existing item (moderate/severe). Confirm **Scheduling conflict** sheet appears (not the old three-button-only sheet).
- [ ] Choose **Move [existing item]** → apply a suggested slot → confirmation chip → **Continue & save** without re-entering task fields.
- [ ] Choose **Move [your item]** → form scrolls to schedule; earlier slot may be suggested in SnackBar; save after adjusting.
- [ ] Choose **Allow overlap** → save succeeds.
- [ ] Minor overlap only → SnackBar, no sheet.
- [ ] Fill Add Task or Goal editor, back out within 60 minutes → **Restore draft** repopulates fields; **Start fresh** clears draft.
- [ ] Plan Tomorrow / future-day task: conflict suggestions use that plan day (not only today).

## Migration Safety
- [ ] Verify old routine docs without mode fields still load in Plan Tomorrow.
- [ ] Verify old reminder docs without escalation fields still schedule.
- [ ] Verify old accountability docs without priority/mode still load in history.
