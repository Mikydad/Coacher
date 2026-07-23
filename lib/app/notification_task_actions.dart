import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/providers.dart';
import '../core/runtime/mutation_request.dart';
import '../core/runtime/schedule_mutation_coordinator.dart';
import '../core/utils/date_keys.dart';
import '../core/utils/stable_id.dart';
import '../features/analytics/application/feature_builder_recompute_service.dart';
import '../features/analytics/domain/models/analytics_event.dart';
import '../features/planning/application/planned_task_collect.dart';
import '../features/planning/domain/models/task_item.dart';
import '../features/scoring/application/scoring_controller.dart';

/// Completes [taskId] from a notification "Done" action — the
/// container-based sibling of Home's `_completeTaskFromHome` sequence
/// (Isar-first upsert → analytics → reminder cleanup → 100% score →
/// mutation pipeline).
///
/// Returns false when the task can't (or must not) be completed here:
/// unknown task, or an enforcement contract that requires the focus/timer
/// flow (`extreme` mode / strictModeRequired). The caller then falls back
/// to the normal tap behavior so discipline features are never silently
/// defeated by a notification button.
Future<bool> completeTaskFromNotification(
  String taskId,
  ProviderContainer container,
) async {
  try {
    final planning = container.read(planningRepositoryProvider);
    PlannedTask? task;
    final rows = await collectTodayPlannedRows(planning);
    for (final r in rows) {
      if (r.task.id == taskId) {
        task = r.task;
        break;
      }
    }
    if (task == null) {
      debugPrint('[NotifTap] done: task not in today rows -> fallback');
      return false;
    }
    if (task.strictModeRequired || task.modeRefId == 'extreme') {
      debugPrint('[NotifTap] done: strict/extreme task -> focus flow');
      return false;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final updated = PlannedTask(
      id: task.id,
      routineId: task.routineId,
      blockId: task.blockId,
      title: task.title,
      durationMinutes: task.durationMinutes,
      priority: task.priority,
      orderIndex: task.orderIndex,
      reminderEnabled: task.reminderEnabled,
      reminderTimeIso: task.reminderTimeIso,
      status: TaskStatus.completed,
      createdAtMs: task.createdAtMs,
      updatedAtMs: nowMs,
      category: task.category,
      planDateKey: task.planDateKey,
      notes: task.notes,
      sequenceIndex: task.sequenceIndex,
      isHabitAnchor: task.isHabitAnchor,
      strictModeRequired: task.strictModeRequired,
      modeRefId: task.modeRefId,
    );
    await planning.upsertTask(updated);

    // Analytics: fireAndForgetAnalyticsEvent needs a WidgetRef, so replicate
    // the container-friendly pattern from attention_orchestrator_providers.
    try {
      final ts = DateTime.now();
      final event = AnalyticsEvent(
        id: StableId.generate('an_evt'),
        type: AnalyticsEventType.taskCompleted,
        entityId: taskId,
        entityKind: 'task',
        dateKey: DateKeys.todayKey(ts),
        timestampLocalIso: ts.toIso8601String(),
        sourceSurface: 'notification_action',
        idempotencyKey: 'task_completed_${taskId}_$nowMs',
        createdAtMs: nowMs,
        updatedAtMs: nowMs,
      );
      await container.read(analyticsRepositoryProvider).logEvent(event);
      container
          .read(featureBuilderRecomputeServiceProvider)
          .onAnalyticsEventLogged(event);
    } catch (e) {
      debugPrint('[NotifTap] done: analytics log failed: $e');
    }

    // Clears the reminder config and cancels the OS notification.
    try {
      await container.read(reminderSyncServiceProvider).markTaskStarted(taskId);
    } catch (e) {
      debugPrint('[NotifTap] done: reminder cleanup failed: $e');
    }

    // An explicit "Done" from the notification means fully complete.
    try {
      await container
          .read(scoringControllerProvider)
          .submit(taskId: taskId, completionPercent: 100);
      final scores = {...container.read(scoredTaskStatusesProvider)};
      scores[taskId] = 100;
      container.read(scoredTaskStatusesProvider.notifier).state = scores;
    } catch (e) {
      debugPrint('[NotifTap] done: scoring failed: $e');
    }

    await ScheduleMutationCoordinator.instance.run(
      TaskCompletedMutation(
        entityId: taskId,
        sourceContext: 'notification_action.done',
        dateStr: task.planDateKey ?? DateKeys.todayKey(),
      ),
      commitOverride: () async {}, // upsertTask above already committed
    );
    debugPrint('[NotifTap] done: task completed taskId=$taskId');
    return true;
  } catch (e, st) {
    debugPrint('[NotifTap] done: failed, falling back to tap flow: $e\n$st');
    return false;
  }
}
