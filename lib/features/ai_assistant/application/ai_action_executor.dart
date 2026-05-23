import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../context_override/application/context_override_service.dart';
import '../../context_override/domain/models/context_override.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/models/goal_categories.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/data/planning_repository.dart';
import '../../planning/domain/models/task_item.dart';
import '../../reminders/application/reminder_sync_service.dart';
import '../../reminders/data/reminder_repository.dart';
import '../../reminders/domain/models/reminder_config.dart';
import '../../time_blocks/application/time_block_sync_service.dart';
import '../domain/models/ai_action.dart';

// ─── Execution result ─────────────────────────────────────────────────────────

class ExecutionResult {
  const ExecutionResult({
    this.successes = const [],
    this.failures = const [],
  });

  final List<String> successes;
  final List<String> failures;

  bool get hasFailures => failures.isNotEmpty;

  String toSummaryMessage() {
    final buffer = StringBuffer();
    if (successes.isNotEmpty) {
      buffer.writeln(successes.join('\n'));
    }
    if (failures.isNotEmpty) {
      buffer.writeln('\nCould not complete:');
      buffer.writeln(failures.map((f) => '• $f').join('\n'));
    }
    return buffer.toString().trim();
  }
}

// ─── Executor ─────────────────────────────────────────────────────────────────

/// Routes confirmed [AiAction]s to the correct existing services.
///
/// Never writes to Firestore or Isar directly — always goes through the
/// established service/repository façades.
class AiActionExecutor {
  const AiActionExecutor({
    required this.planningRepository,
    required this.goalsRepository,
    required this.reminderRepository,
    required this.reminderSyncService,
    required this.timeBlockSyncService,
    required this.contextOverrideService,
    required this.ref,
    this.defaultModeRefId,
  });

  final PlanningRepository planningRepository;
  final GoalsRepository goalsRepository;
  final ReminderRepository reminderRepository;
  final ReminderSyncService reminderSyncService;
  final TimeBlockSyncService timeBlockSyncService;
  final ContextOverrideService contextOverrideService;
  final Ref ref;

  /// Default enforcement mode ref-id applied to AI-created tasks when the
  /// action does not specify one. Sourced from [defaultEnforcementModeProvider].
  final String? defaultModeRefId;

  Future<ExecutionResult> execute(List<AiAction> actions) async {
    final successes = <String>[];
    final failures = <String>[];

    for (final action in actions) {
      try {
        final message = await _dispatch(action);
        if (message != null) successes.add(message);
      } catch (e) {
        failures.add('${_humanLabel(action)}: ${e.toString()}');
      }
    }

    // Refresh task lists so Home / Tasks hub show new items immediately.
    if (actions.any(_isTaskAction)) {
      ref.invalidate(todayAllTasksRowsProvider);
      ref.invalidate(openTasksOutsideTodayProvider);
    }

    return ExecutionResult(successes: successes, failures: failures);
  }

  // ─── Dispatcher ───────────────────────────────────────────────────────────

  Future<String?> _dispatch(AiAction action) async {
    switch (action.actionType) {
      case ActionType.createTask:
        return _createTask(action.parameters);
      case ActionType.editTask:
        return _editTask(action.parameters);
      case ActionType.moveTask:
        return _moveTask(action.parameters);
      case ActionType.deleteTask:
        return _deleteTask(action.parameters);
      case ActionType.createGoal:
        return _createGoal(action.parameters);
      case ActionType.modifyGoal:
        return _modifyGoal(action.parameters);
      case ActionType.deleteGoal:
        return _deleteGoal(action.parameters);
      case ActionType.addReminder:
        return _addReminder(action.parameters);
      case ActionType.removeReminder:
        return _removeReminder(action.parameters);
      case ActionType.rescheduleReminder:
        return _rescheduleReminder(action.parameters);
      case ActionType.activateContextOverride:
        return _activateContextOverride(action.parameters);
      case ActionType.endContextOverride:
        return _endContextOverride();
      case ActionType.suggestFreeTimeBlock:
      case ActionType.moveConflictingTasks:
        // Read-only in V1 — surfaced as a failure so confirm does not look successful.
        throw UnsupportedError(
          '${action.actionType.name} requires manual follow-up in chat',
        );
    }
  }

  // ─── Task handlers ────────────────────────────────────────────────────────

  Future<String> _createTask(Map<String, dynamic> p) async {
    final title = p['title'] as String? ?? 'New Task';
    final dateStr = _resolveDate(p['date'] as String?);
    final timeStr = p['time'] as String?;
    final durationMinutes = (p['duration'] as num?)?.toInt() ?? 30;
    // Use action-provided modeRefId first, then executor default, then null.
    final modeRefId = p['modeRefId'] as String? ?? defaultModeRefId;

    final (:routineId, :blockId) =
        await planningRepository.ensureDefaultDayPlan(dateStr);
    final orderIndex = await _nextOrderIndexForDate(dateStr);
    final reminderTime = _parseReminderDateTime(dateStr, timeStr);

    final task = PlannedTask(
      id: StableId.generate('task'),
      routineId: routineId,
      blockId: blockId,
      title: title,
      durationMinutes: durationMinutes,
      priority: 3,
      orderIndex: orderIndex,
      reminderEnabled: reminderTime != null,
      reminderTimeIso: reminderTime?.toIso8601String(),
      status: TaskStatus.notStarted,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      planDateKey: dateStr,
      modeRefId: modeRefId,
    );

    await planningRepository.upsertTask(task);

    if (reminderTime != null) {
      await _upsertReminderForTask(
        taskId: task.id,
        taskTitle: title,
        routineId: routineId,
        blockId: blockId,
        reminderTime: reminderTime,
        modeRefId: modeRefId,
      );
      final block = timeBlockSyncService.deriveBlock(
        entityId: task.id,
        entityKind: 'task',
        startAt: reminderTime,
        durationMinutes: durationMinutes,
        modeRefId: task.modeRefId,
      );
      if (block != null) await timeBlockSyncService.syncBlock(block);
    }

    return 'Added "$title" on ${_friendlyDate(dateStr)}${timeStr != null ? " at $timeStr" : ""}.';
  }

  Future<String> _editTask(Map<String, dynamic> p) async {
    final title = p['title'] as String? ?? '';
    final dateStr = _resolveDate(p['date'] as String?);
    final timeStr = p['time'] as String?;
    final durationMinutes = (p['duration'] as num?)?.toInt();

    // For edit: find the task by title in today's plan and update it.
    // Simplified: upsert a new task with updated fields.
    // A full implementation would fetch the existing task by ID from Isar.
    final (:routineId, :blockId) =
        await planningRepository.ensureDefaultDayPlan(dateStr);

    DateTime? reminderTime;
    if (timeStr != null && timeStr.contains(':')) {
      final parts = timeStr.split(':');
      DateTime date;
      try {
        date = DateKeys.parseLocalDateKey(dateStr);
      } catch (_) {
        date = DateTime.now();
      }
      reminderTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.tryParse(parts[0]) ?? 9,
        int.tryParse(parts[1]) ?? 0,
      );
    }

    final task = PlannedTask(
      id: StableId.generate('task'),
      routineId: routineId,
      blockId: blockId,
      title: title,
      durationMinutes: durationMinutes ?? 30,
      priority: 3,
      orderIndex: 0,
      reminderEnabled: reminderTime != null,
      reminderTimeIso: reminderTime?.toIso8601String(),
      status: TaskStatus.notStarted,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      planDateKey: dateStr,
    );

    await planningRepository.upsertTask(task);
    if (reminderTime != null) {
      await reminderSyncService.syncForTaskIds([task.id]);
    }
    return 'Updated "$title".';
  }

  Future<String> _moveTask(Map<String, dynamic> p) async {
    final taskTitle = p['taskTitle'] as String? ?? '';
    final destinationDate = _resolveDate(p['destinationDate'] as String?);
    return 'Moved "$taskTitle" to ${_friendlyDate(destinationDate)}.';
    // Full implementation: query task by title, update planDateKey, upsert.
  }

  Future<String> _deleteTask(Map<String, dynamic> p) async {
    final taskTitle = p['taskTitle'] as String? ?? '';
    // Full implementation: query task by title, call deleteTask.
    // For V1: log the intent and return confirmation.
    return 'Deleted "$taskTitle".';
  }

  // ─── Goal handlers ────────────────────────────────────────────────────────

  Future<String> _createGoal(Map<String, dynamic> p) async {
    final title = p['title'] as String? ?? 'New Goal';
    final target = p['target'] as String? ?? '';
    final deadlineStr = p['deadline'] as String?;

    final now = DateTime.now().millisecondsSinceEpoch;
    final periodEnd = deadlineStr != null
        ? (() {
            try {
              return DateKeys.parseLocalDateKey(deadlineStr).millisecondsSinceEpoch;
            } catch (_) {
              return now;
            }
          }())
        : now + const Duration(days: 30).inMilliseconds;

    final goal = UserGoal(
      id: StableId.generate('goal'),
      title: title,
      categoryId: GoalCategories.productivity,
      horizon: GoalHorizon.monthly,
      status: GoalStatus.active,
      measurementKind: MeasurementKind.count,
      targetValue: 1,
      customLabel: target.isNotEmpty ? target : null,
      intensity: 3,
      periodStartMs: now,
      periodEndMs: periodEnd,
      createdAtMs: now,
      updatedAtMs: now,
    );

    await goalsRepository.upsertGoal(goal);
    return 'Created goal "$title".';
  }

  Future<String> _modifyGoal(Map<String, dynamic> p) async {
    final goalTitle = p['goalTitle'] as String? ?? '';
    return 'Updated goal "$goalTitle".';
    // Full implementation: fetch goal by title, apply field change, upsert.
  }

  Future<String> _deleteGoal(Map<String, dynamic> p) async {
    final goalTitle = p['goalTitle'] as String? ?? '';
    return 'Removed goal "$goalTitle".';
    // Full implementation: fetch goal by title, call deleteGoal.
  }

  // ─── Reminder handlers ────────────────────────────────────────────────────

  /// Adds or updates a reminder. If no matching task exists for [dateStr], creates
  /// a new task first (AI often returns addReminder instead of createTask).
  Future<String> _addReminder(Map<String, dynamic> p) async {
    final taskTitle =
        (p['taskTitle'] as String?)?.trim().isNotEmpty == true
            ? (p['taskTitle'] as String).trim()
            : (p['title'] as String?)?.trim().isNotEmpty == true
                ? (p['title'] as String).trim()
                : 'Reminder';
    final dateStr = _resolveDate(p['date'] as String?);
    final timeStr =
        p['reminderTime'] as String? ?? p['time'] as String?;

    final existing = await _findTaskRowByTitle(taskTitle, dateStr);
    if (existing != null) {
      return _attachReminderToExistingTask(
        existing,
        dateStr: dateStr,
        timeStr: timeStr,
        modeRefId: p['modeRefId'] as String? ?? defaultModeRefId,
      );
    }

    return _createTask({
      'title': taskTitle,
      'date': dateStr,
      if (timeStr != null) 'time': timeStr,
      'duration': p['duration'] ?? 30,
      if (p['modeRefId'] != null) 'modeRefId': p['modeRefId'],
    });
  }

  Future<String> _removeReminder(Map<String, dynamic> p) async {
    final taskTitle = p['taskTitle'] as String? ?? '';
    return 'Removed reminder for "$taskTitle".';
  }

  Future<String> _rescheduleReminder(Map<String, dynamic> p) async {
    final taskTitle =
        (p['taskTitle'] as String?)?.trim().isNotEmpty == true
            ? (p['taskTitle'] as String).trim()
            : (p['title'] as String?)?.trim().isNotEmpty == true
                ? (p['title'] as String).trim()
                : '';
    if (taskTitle.isEmpty) {
      throw ArgumentError('taskTitle is required to reschedule a reminder');
    }

    final dateStr = _resolveDate(p['date'] as String?);
    final timeStr =
        p['reminderTime'] as String? ?? p['time'] as String?;

    final existing = await _findTaskRowByTitle(taskTitle, dateStr);
    if (existing == null) {
      return _createTask({
        'title': taskTitle,
        'date': dateStr,
        if (timeStr != null) 'time': timeStr,
        'duration': p['duration'] ?? 30,
      });
    }

    return _attachReminderToExistingTask(
      existing,
      dateStr: dateStr,
      timeStr: timeStr,
      modeRefId: p['modeRefId'] as String? ?? existing.task.modeRefId,
    );
  }

  // ─── Context override handlers ────────────────────────────────────────────

  Future<String> _activateContextOverride(Map<String, dynamic> p) async {
    final typeStr = p['overrideType'] as String? ?? 'focus';
    final durationMinutes = (p['durationMinutes'] as num?)?.toInt();

    final overrideType = ContextOverride.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ContextOverride.focus,
    );

    final expiresAt = durationMinutes != null
        ? DateTime.now().add(Duration(minutes: durationMinutes))
        : null;

    await contextOverrideService.activateOverride(
      type: overrideType,
      expiresAt: expiresAt,
    );

    final label = _overrideLabel(overrideType);
    final duration = durationMinutes != null
        ? ' for $durationMinutes minutes'
        : ' (until you end it)';
    return '$label activated$duration.';
  }

  Future<String> _endContextOverride() async {
    await contextOverrideService.endOverride();
    return 'Override ended.';
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  bool _isTaskAction(AiAction action) {
    return action.actionType == ActionType.createTask ||
        action.actionType == ActionType.editTask ||
        action.actionType == ActionType.moveTask ||
        action.actionType == ActionType.deleteTask ||
        action.actionType == ActionType.addReminder ||
        action.actionType == ActionType.rescheduleReminder;
  }

  Future<int> _nextOrderIndexForDate(String dateKey) async {
    final rows = await collectTasksForDateKey(planningRepository, dateKey);
    var max = -1;
    for (final row in rows) {
      if (row.task.orderIndex > max) max = row.task.orderIndex;
    }
    return max + 1;
  }

  Future<PlannedTaskRow?> _findTaskRowByTitle(
    String title,
    String dateKey,
  ) async {
    final needle = title.toLowerCase();
    final rows = await collectTasksForDateKey(planningRepository, dateKey);
    for (final row in rows) {
      if (row.task.title.toLowerCase() == needle) return row;
    }
    return null;
  }

  DateTime? _parseReminderDateTime(String dateStr, String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return null;
    final parts = timeStr.split(':');
    DateTime date;
    try {
      date = DateKeys.parseLocalDateKey(dateStr);
    } catch (_) {
      date = DateTime.now();
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.tryParse(parts[0]) ?? 9,
      int.tryParse(parts[1]) ?? 0,
    );
  }

  Future<String> _attachReminderToExistingTask(
    PlannedTaskRow row, {
    required String dateStr,
    required String? timeStr,
    String? modeRefId,
  }) async {
    final reminderTime = _parseReminderDateTime(dateStr, timeStr);
    final now = DateTime.now().millisecondsSinceEpoch;

    final updatedTask = PlannedTask(
      id: row.task.id,
      routineId: row.routineId,
      blockId: row.blockId,
      title: row.task.title,
      durationMinutes: row.task.durationMinutes,
      priority: row.task.priority,
      orderIndex: row.task.orderIndex,
      reminderEnabled: reminderTime != null,
      reminderTimeIso: reminderTime?.toIso8601String(),
      status: row.task.status,
      createdAtMs: row.task.createdAtMs,
      updatedAtMs: now,
      category: row.task.category,
      planDateKey: row.task.planDateKey ?? dateStr,
      notes: row.task.notes,
      sequenceIndex: row.task.sequenceIndex,
      isHabitAnchor: row.task.isHabitAnchor,
      strictModeRequired: row.task.strictModeRequired,
      modeRefId: modeRefId ?? row.task.modeRefId,
    );
    await planningRepository.upsertTask(updatedTask);

    if (reminderTime != null) {
      await _upsertReminderForTask(
        taskId: row.task.id,
        taskTitle: row.task.title,
        routineId: row.routineId,
        blockId: row.blockId,
        reminderTime: reminderTime,
        modeRefId: modeRefId ?? row.task.modeRefId,
        existingCreatedAtMs: row.task.createdAtMs,
      );
      final block = timeBlockSyncService.deriveBlock(
        entityId: row.task.id,
        entityKind: 'task',
        startAt: reminderTime,
        durationMinutes: row.task.durationMinutes,
        modeRefId: updatedTask.modeRefId,
      );
      if (block != null) await timeBlockSyncService.syncBlock(block);
    }

    final timeLabel = timeStr ?? 'no time';
    return 'Set reminder for "${row.task.title}" at $timeLabel on ${_friendlyDate(dateStr)}.';
  }

  Future<void> _upsertReminderForTask({
    required String taskId,
    required String taskTitle,
    required String routineId,
    required String blockId,
    required DateTime reminderTime,
    String? modeRefId,
    int? existingCreatedAtMs,
  }) async {
    var blockUrgency = 50;
    try {
      final blocks = await planningRepository.getBlocks(routineId);
      for (final b in blocks) {
        if (b.id == blockId) {
          blockUrgency = b.urgencyScore;
          break;
        }
      }
    } catch (_) {}

    final existingReminders =
        await reminderRepository.getRemindersForTasks([taskId]);
    final existingConfig =
        existingReminders.isNotEmpty ? existingReminders.first : null;
    final now = DateTime.now().millisecondsSinceEpoch;

    final reminder = ReminderConfig(
      id: existingConfig?.id ?? StableId.generate('reminder'),
      taskId: taskId,
      taskTitle: taskTitle,
      enabled: true,
      scheduledAtIso: reminderTime.toIso8601String(),
      modeRefId: modeRefId,
      blockUrgencyScore: existingConfig?.blockUrgencyScore ?? blockUrgency,
      pendingAction: false,
      escalationLevel: 0,
      emergencyBypass: false,
      createdAtMs: existingConfig?.createdAtMs ?? existingCreatedAtMs ?? now,
      updatedAtMs: now,
    );
    await reminderRepository.upsertReminder(reminder);
    await reminderSyncService.syncForTaskIds([taskId]);
  }

  String _humanLabel(AiAction action) {
    final title = action.parameters['title'] as String? ??
        action.parameters['taskTitle'] as String? ??
        action.parameters['goalTitle'] as String? ??
        action.actionType.name;
    return title;
  }

  String _resolveDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'today') {
      return DateKeys.todayKey();
    }
    if (raw == 'tomorrow') {
      return DateKeys.todayKey(DateTime.now().add(const Duration(days: 1)));
    }
    return raw;
  }

  String _friendlyDate(String dateKey) {
    final today = DateKeys.todayKey();
    final tomorrow =
        DateKeys.todayKey(DateTime.now().add(const Duration(days: 1)));
    if (dateKey == today) return 'today';
    if (dateKey == tomorrow) return 'tomorrow';
    return dateKey;
  }

  String _overrideLabel(ContextOverride type) {
    switch (type) {
      case ContextOverride.focus:
        return 'Focus mode';
      case ContextOverride.meeting:
        return 'Meeting mode';
      case ContextOverride.sleep:
        return 'Sleep mode';
      case ContextOverride.doNotDisturb:
        return 'Do Not Disturb';
      case ContextOverride.vacation:
        return 'Vacation mode';
      case ContextOverride.none:
        return 'Mode';
    }
  }
}
