import '../../../core/offline/offline_store.dart';
import '../../goals/application/goal_block_sync_service.dart';
import '../../goals/application/goal_reminder_sync_service.dart';
import '../../goals/data/goals_repository.dart';
import '../../../core/local_db/isar_collections/isar_task.dart';
import '../../planning/data/planning_repository.dart';
import '../../planning/domain/models/task_item.dart';
import '../../reminders/application/reminder_sync_service.dart';
import '../../reminders/data/reminder_repository.dart';
import '../../reminders/domain/models/reminder_config.dart';
import '../data/time_block_repository.dart';
import '../domain/models/scheduled_time_block.dart';
import '../domain/models/time_conflict.dart';
import 'conflict_resolution_port.dart';
import 'scheduling_slot_suggestions.dart';
import 'time_block_sync_service.dart';

/// Applies inline schedule moves for conflicting entities and re-checks blocks.
class ConflictResolutionService implements ConflictResolutionPort {
  ConflictResolutionService({
    required PlanningRepository planning,
    required GoalsRepository goals,
    required TimeBlockRepository timeBlocks,
    required TimeBlockSyncService timeBlockSync,
    required GoalBlockSyncService goalBlockSync,
    required ReminderRepository reminderRepository,
    required ReminderSyncService reminderSync,
    required GoalReminderSyncService goalReminderSync,
    required OfflineStore offlineStore,
  }) : _planning = planning,
       _goals = goals,
       _timeBlocks = timeBlocks,
       _timeBlockSync = timeBlockSync,
       _goalBlockSync = goalBlockSync,
       _reminderRepository = reminderRepository,
       _reminderSync = reminderSync,
       _goalReminderSync = goalReminderSync,
       _offlineStore = offlineStore;

  final PlanningRepository _planning;
  final GoalsRepository _goals;
  final TimeBlockRepository _timeBlocks;
  final TimeBlockSyncService _timeBlockSync;
  final GoalBlockSyncService _goalBlockSync;
  final ReminderRepository _reminderRepository;
  final ReminderSyncService _reminderSync;
  final GoalReminderSyncService _goalReminderSync;
  final OfflineStore _offlineStore;

  @override
  Future<ConflictCheckResult> recheckProposedBlock(
    ScheduledTimeBlock proposed, {
    Map<String, String> entityTitles = const {},
  }) {
    return _timeBlockSync.checkConflicts(proposed, entityTitles: entityTitles);
  }

  @override
  Future<List<ScheduledTimeBlock>> blocksForPlanDay(DateTime planDay) {
    final start = DateTime(planDay.year, planDay.month, planDay.day);
    final end = start.add(const Duration(days: 1));
    return _timeBlocks.listBlocksForDateRange(start, end);
  }

  @override
  Future<ScheduledTimeBlock?> blockForEntity(String entityId) {
    return _timeBlocks.getBlockForEntity(entityId);
  }

  /// Moves an existing task to [newStart] and syncs block + reminders.
  Future<String> moveExistingTask({
    required String taskId,
    required DateTime newStart,
    int? durationMinutes,
    bool isRigid = false,
  }) async {
    final task = await _loadTaskById(taskId);
    if (task == null) {
      throw StateError('Task not found: $taskId');
    }

    final duration = durationMinutes ?? task.durationMinutes;
    final updated = PlannedTask(
      id: task.id,
      routineId: task.routineId,
      blockId: task.blockId,
      title: task.title,
      durationMinutes: duration,
      priority: task.priority,
      orderIndex: task.orderIndex,
      reminderEnabled: true,
      reminderTimeIso: newStart.toIso8601String(),
      status: task.status,
      createdAtMs: task.createdAtMs,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      category: task.category,
      planDateKey: task.planDateKey,
      notes: task.notes,
      sequenceIndex: task.sequenceIndex,
      isHabitAnchor: task.isHabitAnchor,
      strictModeRequired: task.strictModeRequired,
      modeRefId: task.modeRefId,
    );

    await _planning.upsertTask(updated);

    final block = _timeBlockSync.deriveBlock(
      entityId: updated.id,
      entityKind: 'task',
      startAt: newStart,
      durationMinutes: duration,
      modeRefId: updated.modeRefId,
      isRigid: isRigid,
    );
    if (block != null) {
      await _timeBlockSync.syncBlock(block);
    }

    await _syncTaskReminder(updated, newStart);
    return '${updated.title} → ${formatMoveLabel(newStart, duration)}';
  }

  /// Moves an existing goal reminder to [newStart] on [planDay].
  Future<String> moveExistingGoal({
    required String goalId,
    required DateTime newStart,
    required DateTime planDay,
  }) async {
    final goal = await _goals.getGoal(goalId);
    if (goal == null) {
      throw StateError('Goal not found: $goalId');
    }

    final minutes = newStart.hour * 60 + newStart.minute;
    final updated = goal.copyWith(
      reminderEnabled: true,
      reminderMinutesFromMidnight: minutes,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    await _goals.upsertGoal(updated);
    await _goalBlockSync.syncBlockForGoal(updated, planDay);
    await _goalReminderSync.applyForGoal(updated);

    return '${updated.title} → ${formatMoveLabel(newStart, kGoalBlockDefaultDurationMinutes)}';
  }

  @override
  Future<String> moveConflictingEntity({
    required TimeConflict conflict,
    required DateTime newStart,
    required DateTime planDay,
    int? durationMinutes,
  }) async {
    final kind = conflict.conflictingEntityKind;
    if (kind == 'goal') {
      return moveExistingGoal(
        goalId: conflict.conflictingEntityId,
        newStart: newStart,
        planDay: planDay,
      );
    }
    return moveExistingTask(
      taskId: conflict.conflictingEntityId,
      newStart: newStart,
      durationMinutes: durationMinutes,
    );
  }

  Future<PlannedTask?> _loadTaskById(String taskId) async {
    final isar = _offlineStore.isar;
    if (isar == null) return null;
    final row = await isar.isarTasks.getByTaskId(taskId);
    return row?.toDomain();
  }

  Future<void> _syncTaskReminder(PlannedTask task, DateTime newStart) async {
    final existing = await _reminderRepository.getRemindersForTasks([task.id]);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (existing.isNotEmpty) {
      final r = existing.first;
      await _reminderRepository.upsertReminder(
        ReminderConfig(
          id: r.id,
          taskId: r.taskId,
          taskTitle: r.taskTitle ?? task.title,
          enabled: true,
          scheduledAtIso: newStart.toIso8601String(),
          modeRefId: r.modeRefId,
          blockUrgencyScore: r.blockUrgencyScore,
          createdAtMs: r.createdAtMs,
          updatedAtMs: now,
        ),
      );
    }
    await _reminderSync.syncForTaskIds([task.id]);
  }
}

String formatMoveLabel(DateTime start, int durationMinutes) {
  final end = start.add(Duration(minutes: durationMinutes));
  return formatSchedulingTimeRange(start, end);
}
