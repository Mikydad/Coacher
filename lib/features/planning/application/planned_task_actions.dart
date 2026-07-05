import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../time_blocks/application/time_block_providers.dart';
import '../domain/models/accountability_log.dart';
import '../domain/models/flow_transition_event.dart';
import '../domain/models/routine.dart';
import '../domain/models/task_item.dart';
import 'auto_next_task_flow.dart';
import 'effective_task_mode.dart';
import 'planned_task_collect.dart';
import 'planned_task_providers.dart';

/// Shared row-level task actions used by the tasks hub and the task detail
/// screen. Extracted from tasks_hub_screen.dart so the two surfaces cannot
/// drift apart in side effects (analytics, reminders, mutation coordinator).

/// Effective discipline mode ('flexible' / 'disciplined' / 'extreme') for a
/// task known only by id — used by surfaces like the timer screen that don't
/// hold the full row. Falls back to 'flexible' when the task isn't in
/// today's plan (e.g. deleted mid-session).
Future<String> effectiveModeRefIdForTaskId(WidgetRef ref, String taskId) async {
  final repo = ref.read(planningRepositoryProvider);
  final rows = await collectTodayPlannedRows(repo);
  for (final row in rows) {
    if (row.task.id != taskId) continue;
    Routine? routine;
    for (final r in await repo.getRoutinesForDate(row.dateKey)) {
      if (r.id == row.routineId) {
        routine = r;
        break;
      }
    }
    return EffectiveTaskMode.effectiveModeRefId(task: row.task, routine: routine);
  }
  return 'flexible';
}

/// Marks the task completed, logs analytics, syncs reminders, and runs the
/// schedule-mutation coordinator. When [runAutoNext] is true the auto
/// "what's next" flow is offered afterwards (hub behavior); detail-style
/// surfaces can pass false to stay on the page.
Future<void> completePlannedTaskRow(
  BuildContext context,
  WidgetRef ref,
  PlannedTaskRow row, {
  required String sourceSurface,
  required String sourceContext,
  bool runAutoNext = true,
}) async {
  final t = row.task;
  if (t.status == TaskStatus.completed) return;
  final planning = ref.read(planningRepositoryProvider);
  final now = DateTime.now().millisecondsSinceEpoch;
  await planning.upsertTask(
    PlannedTask(
      id: t.id,
      routineId: t.routineId,
      blockId: t.blockId,
      title: t.title,
      durationMinutes: t.durationMinutes,
      priority: t.priority,
      orderIndex: t.orderIndex,
      reminderEnabled: t.reminderEnabled,
      reminderTimeIso: t.reminderTimeIso,
      status: TaskStatus.completed,
      createdAtMs: t.createdAtMs,
      updatedAtMs: now,
      category: t.category,
      planDateKey: t.planDateKey,
      notes: t.notes,
      sequenceIndex: t.sequenceIndex,
      isHabitAnchor: t.isHabitAnchor,
      strictModeRequired: t.strictModeRequired,
      modeRefId: t.modeRefId,
    ),
  );
  fireAndForgetAnalyticsEvent(
    ref,
    type: AnalyticsEventType.taskCompleted,
    entityId: t.id,
    entityKind: 'task',
    sourceSurface: sourceSurface,
    idempotencyKey:
        'task_completed_${sourceSurface}_${t.id}_${DateTime.now().millisecondsSinceEpoch}',
    modeRefId: t.modeRefId,
  );
  await ref.read(reminderSyncServiceProvider).markTaskStarted(t.id);
  // migrated to coordinator
  await ScheduleMutationCoordinator.instance.run(
    TaskCompletedMutation(
      entityId: t.id,
      sourceContext: sourceContext,
      dateStr: t.planDateKey ?? DateKeys.todayKey(),
    ),
    commitOverride: () async {}, // upsertTask already called above
  );
  if (!context.mounted) return;
  invalidateTaskListProviders(ref);
  if (runAutoNext) {
    await runAutoNextTaskFlow(
      context,
      ref,
      completedTaskId: t.id,
      completionPercent: 100,
    );
  }
}

/// "Plans changed?" flow: pick a reason category, add a short note, log the
/// flow transition + accountability entries, and relax the task's reminder.
Future<void> promptPlansChangedForRow(
  BuildContext context,
  WidgetRef ref,
  PlannedTaskRow row,
) async {
  final reason = await showDialog<OverrideReasonCategory>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Plans changed?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in OverrideReasonCategory.values)
            ListTile(
              title: Text(option.label),
              onTap: () => Navigator.pop(ctx, option),
            ),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  final noteCtrl = TextEditingController();
  final note = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Short logical reason'),
      content: TextField(
        controller: noteCtrl,
        maxLines: 2,
        decoration: const InputDecoration(hintText: '1-2 sentences'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, noteCtrl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  noteCtrl.dispose();
  if (note == null || note.trim().isEmpty) return;
  final planning = ref.read(planningRepositoryProvider);
  await planning.logFlowTransitionEvent(
    FlowTransitionEvent(
      id: StableId.generate('flowev'),
      taskId: row.task.id,
      type: FlowTransitionType.moveWithReason,
      planChangeIntent: PlanChangeIntent.logical,
      reasonCategory: reason,
      reasonNote: note,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    ),
  );
  await planning.logAccountability(
    AccountabilityLog(
      id: StableId.generate('acct'),
      taskId: row.task.id,
      action: AccountabilityAction.defer,
      reasonCategory: reason,
      reasonNote: note,
      modeRefId: row.task.modeRefId,
      taskPriority: row.task.priority,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    ),
  );
  await ref.read(reminderSyncServiceProvider).markLogicalReasonProvided(row.task.id);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plans change logged.')),
    );
  }
}

/// Confirmation dialog + delete (task, its time block, coordinator run).
/// Returns true when the task was deleted.
Future<bool> confirmDeletePlannedTask(
  BuildContext context,
  WidgetRef ref,
  PlannedTaskRow row, {
  String sourceContext = 'tasks_hub.delete',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete task?'),
      content: Text('Remove "${row.task.title}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  await ref.read(planningRepositoryProvider).deleteTask(
        routineId: row.routineId,
        blockId: row.blockId,
        taskId: row.task.id,
      );
  // Phase A — remove the time block when the task is deleted.
  await ref
      .read(timeBlockSyncServiceProvider)
      .removeBlockForEntity(row.task.id);
  // migrated to coordinator
  await ScheduleMutationCoordinator.instance.run(
    TaskDeletedMutation(
      entityId: row.task.id,
      sourceContext: sourceContext,
      dateStr: row.task.planDateKey ?? DateKeys.todayKey(),
    ),
    commitOverride: () async {}, // delete already done above
  );
  return true;
}
