# Add Task refactor notes (2026-08-08)

Companion to the GUIDELINES.md decision-log entry of the same date. The
2,184-line `add_task_screen.dart` was split into `add_task/application/`
flows and `presentation/sections/` widgets under a pure-code-motion
discipline: behavior moves, it does not change. This file records the two
kinds of exceptions so nobody rediscovers them as mysteries later.

## Latent typo carried over on purpose (open)

- **Accountability picker sheet title renders at `fontSize: 5`.**
  `lib/features/add_task/presentation/add_task_accountability_picker_sheet.dart`
  (`Text('Accountability', style: TextStyle(fontSize: 5, ...))`). This came
  verbatim from the original `_showAccountabilityPicker` in
  `add_task_screen.dart` — almost certainly meant to be ~15, but fixing it
  mid-refactor would have been a silent visual change, so it was preserved.
  **TODO:** fix deliberately (one-line change + eyeball the sheet on device).

## Declared micro-changes (intentional, reviewed, shipped with the split)

None of these change net behavior a user can observe; each is written down
because the diff is not literally byte-identical to the old code.

1. **Conflict schedule adjustments unified into one seam.**
   `SchedulingConflictSheet` can adjust the proposed schedule *live* while
   the sheet is open (`onAdjustProposedSchedule`) and *again* via the
   resolution outcome after it closes. Both paths now funnel through a single
   `onAdjustSchedule(DateTime? start, int? durationMinutes)` callback →
   `_applyAdjustedSchedule` in the screen State. The old inline path wrote
   `_reminder`/`_reminderTime`/`_duration` in ONE `setState`; the unified
   shape uses TWO (start fields, then duration) — identical net state within
   a single frame, and the draft-autosave `markDirty` hook is idempotent, so
   nothing observable differs. A result object was rejected because it cannot
   express the live mid-sheet mutation.

2. **Draft restore cancels the autosave debounce earlier.**
   Old order on "Restore": apply draft → await delete stored draft → cancel
   debounce. New order: apply draft + cancel debounce → await delete. This
   closes a (harmless but real) window where the 10s debounce could fire
   during the async delete and re-persist the just-restored content.
   Strictly safer, same user-visible behavior.

3. **`use_build_context_synchronously` handling in `_onSave`.**
   The extracted flows take `context` as a parameter, which surfaces four
   lint infos the old instance methods hid by reading `State.context`
   internally. Pre-upsert gates got `if (!mounted) return;` (matches the old
   abort-before-upsert behavior when the sheet is dismissed mid-save). The
   two post-upsert calls (`applyAddTaskSleepSideEffects`,
   `persistAddTaskReminder`) carry `// ignore:` comments instead — the task
   is already saved at that point and the original ran them regardless of
   mount state; both callees guard every context use with `context.mounted`.

4. **`_nextOrderIndex` dedup.** The max-orderIndex-plus-one block was
   copy-pasted three times inside the old `_onSave` (edit-moved-day, slot
   create, plain create); `add_task_save_target.dart` has it once as a
   private helper. Same arithmetic, same call sites.

5. **`debugPrint` tags renamed.** Swallowed-error logs moved with their code
   and now name the new files (`add_task_mode_resolution: swallowed error:`,
   `add_task_reminder_persistence: ...`) instead of `add_task_screen:`.
   Grep for the old tag finds fewer hits by design.

## The invariant to preserve in future add_task work

Every section widget mutates form state ONLY via callbacks whose bodies run
the screen State's `setState` — the overridden `setState` is what marks the
form draft dirty. A section that writes state any other way silently breaks
draft autosave. (Allowed verbatim exceptions, same as pre-refactor:
`_existingReminderId ??=`, `_suppressDraftDirty`, `_draftRestoreOffered`,
`_draftInitialized`, `_draftClearedOnSuccessfulSave`.)
