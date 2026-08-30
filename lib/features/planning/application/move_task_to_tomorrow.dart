import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../reminders/application/reminder_sync_service.dart';
import 'planned_task_collect.dart';
import '../domain/models/task_item.dart';

/// Headless "move this task to tomorrow" (AUDIT A1).
///
/// The Recovery Card's Reschedule used to collect a reason, resolve the
/// occurrence — and move nothing: the task kept its day, its reminder kept
/// its old date, and the "reschedule" existed only as a ledger entry. This
/// does what the word says, mirroring Plan-Tomorrow's move: the SAME task id
/// lands in tomorrow's default plan, its reminder's date shifts with it
/// (time of day kept — the C3 rule), and status resets to not-started.
///
/// The reminder-config half (occurrence resolution, config date, re-arm) is
/// [ReminderSyncService.shiftToDate], which the caller runs after this.
Future<void> moveTaskRowToTomorrow(WidgetRef ref, PlannedTaskRow row) async {
  final planning = ref.read(planningRepositoryProvider);
  final tomorrowKey = DateKeys.tomorrowKey();
  final tomorrow = DateTime.now().add(const Duration(days: 1));

  final day = await planning.ensureDefaultDayPlan(tomorrowKey);
  final existing = await planning.getTasks(
    routineId: day.routineId,
    blockId: day.blockId,
  );
  final orderIndex = existing.isEmpty
      ? 0
      : existing.map((t) => t.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

  final t = row.task;
  await planning.deleteTask(
    routineId: row.routineId,
    blockId: row.blockId,
    taskId: t.id,
  );
  await planning.upsertTask(
    PlannedTask(
      id: t.id,
      routineId: day.routineId,
      blockId: day.blockId,
      title: t.title,
      durationMinutes: t.durationMinutes,
      priority: t.priority,
      orderIndex: orderIndex,
      reminderEnabled: t.reminderEnabled,
      reminderTimeIso:
          ReminderSyncService.shiftIsoToDate(
            t.reminderTimeIso,
            tomorrow,
          )?.toIso8601String() ??
          t.reminderTimeIso,
      status: TaskStatus.notStarted,
      createdAtMs: t.createdAtMs,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      category: t.category,
      planDateKey: tomorrowKey,
      notes: t.notes,
      sequenceIndex: t.sequenceIndex,
      isHabitAnchor: t.isHabitAnchor,
      strictModeRequired: t.strictModeRequired,
      modeRefId: t.modeRefId,
    ),
  );

  await ScheduleMutationCoordinator.instance.run(
    TaskUpdatedMutation(
      entityId: t.id,
      sourceContext: 'recovery_card.move_to_tomorrow',
      dateStr: tomorrowKey,
    ),
    commitOverride: () async {},
  );
}
