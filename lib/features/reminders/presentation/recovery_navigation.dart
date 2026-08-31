import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/domain/models/accountability_log.dart';
import '../../planning/application/move_task_to_tomorrow.dart';
import '../../planning/presentation/override_reason_dialog.dart';
import '../application/attention_orchestrator_providers.dart';
import '../application/recovery_view.dart';
import '../application/reminder_state_machine.dart';
import '../domain/models/reminder_occurrence_enums.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../goals/presentation/goal_detail_screen.dart';
import '../../tasks_hub/presentation/task_detail_screen.dart';
import '../../tasks_hub/presentation/tasks_hub_screen.dart';
import 'recovery_card.dart';

/// "Do now" on a Recovery Card row.
///
/// An occurrence knows only its entity id, so the task's routine/block/day
/// are resolved from today's rows. If the task is not in today's plan (it was
/// moved, or the row is from an earlier day), the Tasks Hub is the honest
/// fallback — better than a dead button.
Future<void> openRecoveryTask(
  BuildContext context,
  WidgetRef ref,
  String entityId, {
  String entityKind = 'task',
}) async {
  // A goal occurrence's "Do now" opens the goal itself (C2: goal misses can
  // reach the card now) — the task-row lookup below would never find it.
  if (entityKind == 'goal') {
    await Navigator.pushNamed(
      context,
      GoalDetailScreen.routeName,
      arguments: entityId,
    );
    return;
  }
  final rows = ref.read(todayAllTasksRowsProvider).valueOrNull;
  final row = rows?.where((r) => r.task.id == entityId).firstOrNull;

  if (row == null) {
    await Navigator.pushNamed(context, TasksHubScreen.routeName);
    return;
  }
  await Navigator.pushNamed(
    context,
    TaskDetailScreen.routeName,
    arguments: TaskDetailArgs.fromRow(row),
  );
}

/// Resolve a Recovery Card row the way its mode demands (FR-R-40…42).
///
/// The modes' real difference is what Overdue DEMANDS, not how loudly it
/// arrives. Flexible needs nothing. Disciplined asks for a disposition but
/// accepts any of them. Extreme will not take "skip" or "reschedule" without
/// a reason, and that reason goes into the accountability log — the same log,
/// validated by the same rule, as every other logical-reason path in the app.
///
/// D4's "staked → Surrender" branch has no subject here: stakes attach to
/// GOALS in this codebase (`goal_actions.dart` owns liveStake and the
/// surrender callable), not to task occurrences. A staked goal keeps its
/// existing surrender flow; a task in Extreme mode gets D4's unstaked
/// contract — Do now, or reschedule with a reason.
Future<void> resolveRecoveryRow(
  BuildContext context,
  WidgetRef ref,
  RecoveryRow row,
  ReminderResolutionKind kind,
) async {
  final service = ref.read(reminderOccurrenceServiceProvider);
  String? reason;

  if (ReminderStateMachine.requiresResolutionReason(row.occurrence, kind)) {
    final answer = await promptOverrideReason(context);
    // Backing out of the reason dialog leaves the row exactly as it was —
    // that is the contract working, not a failure.
    if (answer == null) return;
    reason = answer.note;

    try {
      await ref
          .read(planningRepositoryProvider)
          .logAccountability(
            AccountabilityLog(
              id: StableId.generate('acct'),
              taskId: row.occurrence.entityId,
              action: kind == ReminderResolutionKind.skipped
                  ? AccountabilityAction.skip
                  : AccountabilityAction.defer,
              reasonCategory: answer.reason,
              reasonNote: answer.note,
              modeRefId: row.occurrence.modeRefId,
              createdAtMs: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    } catch (e) {
      // The resolution itself is local and must not be held hostage by the
      // log write (CLAUDE.md rule 1).
      debugPrint('[Recovery] accountability log failed: $e');
    }
  }

  await service.resolveForEntity(
    row.occurrence.entityId,
    kind: kind,
    reason: reason,
  );

  // Any resolution silences the rest of the ladder (FR-R-13/FR-R-35).
  await ref
      .read(attentionOrchestratorServiceProvider)
      .cancelForEntity(row.occurrence.entityId);

  if (kind == ReminderResolutionKind.rescheduled) {
    // AUDIT A1: "reschedule" has to actually move something. The task row
    // lands in tomorrow's plan (same id, time of day kept, status reset) and
    // shiftToDate moves the reminder config with it — creating tomorrow's
    // occurrence and re-arming its ladder. If the row is not in today's plan
    // (an occurrence from an older day), only the reminder side moves; the
    // carry-forward section owns the stale row.
    final rows = ref.read(todayAllTasksRowsProvider).valueOrNull;
    final row0 = rows
        ?.where((r) => r.task.id == row.occurrence.entityId)
        .firstOrNull;
    if (row0 != null) {
      try {
        await moveTaskRowToTomorrow(ref, row0);
      } catch (e) {
        debugPrint('[Recovery] task-row move failed: $e');
      }
    }
    await ref
        .read(reminderSyncServiceProvider)
        .shiftToDate(
          row.occurrence.entityId,
          targetDay: DateTime.now().add(const Duration(days: 1)),
        );
    if (context.mounted) {
      await _maybeSuggestDemoteOrDrop(context, ref, row);
    }
  }
}

/// D4: after three consecutive reschedules, say something once.
///
/// Extreme's contract is "resolve it", and reschedule-with-reason is a valid
/// resolution — which means the contract could become a reschedule-forever
/// treadmill with a paper trail. This is the release valve, and it is a
/// SUGGESTION: the user decides, SidePal does not demote anything on its own.
Future<void> _maybeSuggestDemoteOrDrop(
  BuildContext context,
  WidgetRef ref,
  RecoveryRow row,
) async {
  final count = await ref
      .read(reminderOccurrenceServiceProvider)
      .consecutiveReschedules(row.occurrence.entityId);
  if (count < 3 || !context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 8),
      content: Text(
        '"${row.title}" has moved $count times. Worth easing its mode, '
        'or letting it go?',
      ),
      action: SnackBarAction(
        label: 'Edit task',
        onPressed: () => openRecoveryTask(context, ref, row.occurrence.entityId),
      ),
    ),
  );
}

/// The strongest recovery moment (§3.6): a focus session just ended.
///
/// Shows the same content as the Home card, as a sheet, and only when there
/// is genuinely something open. Returns immediately when the card would be
/// empty, so finishing a session with a clear plate is never interrupted.
Future<void> showRecoveryPromptIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  final view = ref.read(recoveryViewProvider).valueOrNull;
  if (view == null || view.isEmpty) return;
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RecoveryCard(
              onOpenTask: (entityId, entityKind) async {
                Navigator.pop(sheetContext);
                if (!context.mounted) return;
                await openRecoveryTask(
                  context,
                  ref,
                  entityId,
                  entityKind: entityKind,
                );
              },
              onResolve: (row, kind) async {
                Navigator.pop(sheetContext);
                if (!context.mounted) return;
                await resolveRecoveryRow(context, ref, row, kind);
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    ),
  );
}
