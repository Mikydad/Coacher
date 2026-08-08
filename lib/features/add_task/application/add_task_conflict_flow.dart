import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../planning/application/habit_anchor_aggregator.dart';
import '../../planning/domain/add_task_duration.dart';
import '../../planning/domain/models/task_item.dart';
import '../../time_blocks/application/conflict_entity_title_resolver.dart';
import '../../time_blocks/application/scheduling_conflict_analytics.dart';
import '../../time_blocks/application/time_block_providers.dart';
import '../../time_blocks/domain/models/conflict_resolution_outcome.dart';
import '../../time_blocks/domain/models/time_conflict.dart';
import '../../time_blocks/presentation/scheduling_conflict_sheet.dart';

/// Pre-save gates and post-save sync for Add Task scheduling conflicts.
///
/// Schedule adjustments flow back through a single
/// `onAdjustSchedule(DateTime? start, int? durationMinutes)` seam: the
/// conflict sheet can adjust live while it is still open AND return an
/// adjusted outcome after it closes, so a callback (not a result object) is
/// required — the caller's State applies the fields via `setState` and owns
/// the scroll-to-schedule GlobalKey.

/// Habit-anchor overlap confirm. True = proceed with save.
Future<bool> confirmAddTaskHabitOverlap(
  BuildContext context,
  WidgetRef ref, {
  required PlannedTask task,
  required String planDateKey,
  required bool isEdit,
}) async {
  if (!task.reminderEnabled || task.reminderTimeIso == null) return true;
  final anchors = await readHabitAnchorsForDate(ref, dateKey: planDateKey);
  if (!context.mounted) return false;
  final conflicts = findOverlappingHabitAnchorsForTask(
    task,
    anchors,
    ignoredTaskId: isEdit ? task.id : null,
  );
  if (conflicts.isEmpty) return true;
  final proceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Overlaps habit time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This task overlaps one or more habit anchors. Are you sure you want to continue?',
          ),
          const SizedBox(height: 10),
          for (final c in conflicts.take(3))
            Text(
              '• ${c.label} (${_timeLabel(ctx, c.startLocal)}-${_timeLabel(ctx, c.endLocal)})'
              ' ${c.source == HabitAnchorSource.goal ? '[Goal]' : '[Task Habit]'}',
              style: TextStyle(fontSize: 12, color: AppColors.fg70),
            ),
          if (conflicts.length > 3)
            Text(
              '• +${conflicts.length - 3} more',
              style: TextStyle(fontSize: 12, color: AppColors.fg54),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Change time'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Save anyway'),
        ),
      ],
    ),
  );
  if (proceed == true) {
    fireAndForgetAnalyticsEvent(
      ref,
      type: AnalyticsEventType.overlapOverride,
      entityId: task.id,
      entityKind: 'task',
      sourceSurface: isEdit ? 'add_task_edit' : 'add_task_create',
      idempotencyKey:
          'overlap_override_${task.id}_${task.reminderTimeIso ?? 'na'}_${conflicts.length}',
      modeRefId: task.modeRefId,
      reason: 'save_anyway_after_overlap_warning',
    );
  }
  return proceed == true;
}

/// Pre-save time-block conflict gate. True = proceed with save. Minor
/// conflicts show only a snackbar; major ones open the resolution sheet.
Future<bool> checkAddTaskTimeBlockConflicts(
  BuildContext context,
  WidgetRef ref, {
  required PlannedTask task,
  required bool isRigid,
  required bool isEdit,
  required void Function(DateTime? start, int? durationMinutes)
  onAdjustSchedule,
}) async {
  if (!taskHasFocusDuration(task.durationMinutes)) return true;
  final reminderIso = task.reminderTimeIso;
  if (reminderIso == null) return true;
  final startAt = DateTime.tryParse(reminderIso);
  if (startAt == null) return true;

  final service = ref.read(timeBlockSyncServiceProvider);
  final proposed = service.deriveBlock(
    entityId: task.id,
    entityKind: 'task',
    startAt: startAt,
    durationMinutes: task.durationMinutes,
    modeRefId: task.modeRefId,
    isRigid: isRigid,
  );
  if (proposed == null) return true;

  final repo = ref.read(timeBlockRepositoryProvider);
  final overlapping = await repo.listOverlappingBlocks(proposed);
  final entityTitles = await buildSchedulingConflictEntityTitles(
    ref,
    overlapping: overlapping,
  );

  final result = await service.checkConflicts(
    proposed,
    entityTitles: entityTitles,
  );
  if (!result.hasConflicts) {
    // Still log overlapCreated = false (no event needed — clean save).
    return true;
  }

  if (!context.mounted) return false;

  // Minor conflicts: show inline banner only (no bottom sheet).
  if (result.worstSeverity == ConflictSeverity.minor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Minor time overlap with ${result.conflicts.first.conflictingEntityTitle}. '
          'Saved anyway.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    _logOverlapCreated(ref, task, overridden: true, isEdit: isEdit);
    return true;
  }

  final planDay = DateTime(
    proposed.startAt.year,
    proposed.startAt.month,
    proposed.startAt.day,
  );

  final outcome = await SchedulingConflictSheet.show(
    context: context,
    proposedTitle: task.title,
    proposedKind: 'task',
    proposedBlock: proposed,
    conflicts: result.conflicts,
    resolutionPort: ref.read(conflictResolutionServiceProvider),
    loadEntityTitles: () async {
      final overlapping = await ref
          .read(timeBlockRepositoryProvider)
          .listOverlappingBlocks(proposed);
      return buildSchedulingConflictEntityTitles(ref, overlapping: overlapping);
    },
    planDay: planDay,
    ignoreEntityIds: {task.id},
    onEntityMoved: () => ScheduleMutationCoordinator.instance.run(
      // migrated to coordinator
      TimeBlockChangedMutation(
        entityId: task.id,
        sourceContext: 'add_task_screen.conflict_resolution',
        dateStr: DateKeys.todayKey(planDay),
      ),
      commitOverride: () async {}, // move already done by conflict resolution
    ),
    onAdjustProposedSchedule: (start, durationMinutes) =>
        onAdjustSchedule(start, durationMinutes),
    onOverlapResolvedInline:
        ({
          required movedEntity,
          required suggestionIndex,
          conflictingEntityId,
        }) => _logOverlapResolvedInline(
          ref,
          taskId: task.id,
          movedEntity: movedEntity,
          suggestionIndex: suggestionIndex,
          conflictingEntityId: conflictingEntityId,
          isEdit: isEdit,
        ),
  );

  return _handleOutcome(
    ref,
    task,
    outcome,
    isEdit: isEdit,
    onAdjustSchedule: onAdjustSchedule,
  );
}

/// Post-save: create/refresh the derived time block, or remove it when the
/// task no longer has a focus duration or a start time.
Future<void> syncAddTaskTimeBlock(
  WidgetRef ref, {
  required PlannedTask task,
  required bool isRigid,
}) async {
  if (!taskHasFocusDuration(task.durationMinutes)) {
    await ref.read(timeBlockSyncServiceProvider).removeBlockForEntity(task.id);
    return;
  }
  final reminderIso = task.reminderTimeIso;
  if (reminderIso == null) {
    await ref.read(timeBlockSyncServiceProvider).removeBlockForEntity(task.id);
    return;
  }
  final startAt = DateTime.tryParse(reminderIso);
  if (startAt == null) return;

  final service = ref.read(timeBlockSyncServiceProvider);
  final block = service.deriveBlock(
    entityId: task.id,
    entityKind: 'task',
    startAt: startAt,
    durationMinutes: task.durationMinutes,
    modeRefId: task.modeRefId,
    isRigid: isRigid,
  );
  if (block != null) {
    await service.syncBlock(block);
  }
}

String _timeLabel(BuildContext context, DateTime dt) {
  final tod = TimeOfDay.fromDateTime(dt);
  return tod.format(context);
}

bool _handleOutcome(
  WidgetRef ref,
  PlannedTask task,
  ConflictResolutionOutcome? outcome, {
  required bool isEdit,
  required void Function(DateTime? start, int? durationMinutes)
  onAdjustSchedule,
}) {
  if (outcome == null) return false;
  switch (outcome.kind) {
    case ConflictResolutionKind.proceedToSave:
      if (outcome.overlapOverridden) {
        _logOverlapCreated(ref, task, overridden: true, isEdit: isEdit);
        fireAndForgetAnalyticsEvent(
          ref,
          type: AnalyticsEventType.overlapOverridden,
          entityId: task.id,
          entityKind: 'task',
          sourceSurface: isEdit ? 'add_task_edit' : 'add_task_create',
          idempotencyKey:
              'overlap_overridden_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
          modeRefId: task.modeRefId,
        );
      }
      return true;
    case ConflictResolutionKind.stayOnForm:
      return false;
    case ConflictResolutionKind.proposedScheduleAdjusted:
      onAdjustSchedule(outcome.adjustedStart, outcome.adjustedDurationMinutes);
      return false;
  }
}

void _logOverlapCreated(
  WidgetRef ref,
  PlannedTask task, {
  required bool overridden,
  required bool isEdit,
}) {
  fireAndForgetAnalyticsEvent(
    ref,
    type: AnalyticsEventType.overlapCreated,
    entityId: task.id,
    entityKind: 'task',
    sourceSurface: isEdit ? 'add_task_edit' : 'add_task_create',
    idempotencyKey:
        'overlap_created_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
    modeRefId: task.modeRefId,
    reason: overridden ? 'override' : 'detected',
  );
}

void _logOverlapResolvedInline(
  WidgetRef ref, {
  required String taskId,
  required String movedEntity,
  required Object suggestionIndex,
  String? conflictingEntityId,
  required bool isEdit,
}) {
  fireAndForgetAnalyticsEvent(
    ref,
    type: AnalyticsEventType.overlapResolvedInline,
    entityId: taskId,
    entityKind: 'task',
    sourceSurface: isEdit ? 'add_task_edit' : 'add_task_create',
    idempotencyKey:
        'overlap_resolved_inline_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
    reason: inlineConflictResolutionReason(
      movedEntity: movedEntity,
      suggestionIndex: suggestionIndex,
      conflictingEntityId: conflictingEntityId,
    ),
  );
}
