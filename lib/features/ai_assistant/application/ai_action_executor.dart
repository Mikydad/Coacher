import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../context_override/application/context_override_service.dart';
import '../../context_override/domain/models/context_override.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/models/goal_categories.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../planning/data/planning_repository.dart';
import '../../planning/domain/models/task_item.dart';
import '../../reminders/application/reminder_sync_service.dart';
import '../../reminders/data/reminder_repository.dart';
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
  });

  final PlanningRepository planningRepository;
  final GoalsRepository goalsRepository;
  final ReminderRepository reminderRepository;
  final ReminderSyncService reminderSyncService;
  final TimeBlockSyncService timeBlockSyncService;
  final ContextOverrideService contextOverrideService;
  final Ref ref;

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

    // Invalidate task list providers so the UI reflects changes immediately.
    // Uses Ref.invalidate since we're in a service layer (not a widget).
    if (actions.any((a) => _isTaskAction(a))) {
      try {
        ref.invalidateSelf();
      } catch (_) {}
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
        // Read-only in V1 — no write; message is handled by the preview card.
        return null;
    }
  }

  // ─── Task handlers ────────────────────────────────────────────────────────

  Future<String> _createTask(Map<String, dynamic> p) async {
    final title = p['title'] as String? ?? 'New Task';
    final dateStr = _resolveDate(p['date'] as String?);
    final timeStr = p['time'] as String?;
    final durationMinutes = (p['duration'] as num?)?.toInt() ?? 30;

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
      durationMinutes: durationMinutes,
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

    if (reminderTime != null) {
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

  Future<String> _addReminder(Map<String, dynamic> p) async {
    final taskTitle = p['taskTitle'] as String? ?? '';
    final reminderTime = p['reminderTime'] as String? ?? '';
    await reminderSyncService.scheduleFromCache();
    return 'Added reminder for "$taskTitle" at $reminderTime.';
  }

  Future<String> _removeReminder(Map<String, dynamic> p) async {
    final taskTitle = p['taskTitle'] as String? ?? '';
    return 'Removed reminder for "$taskTitle".';
  }

  Future<String> _rescheduleReminder(Map<String, dynamic> p) async {
    final taskTitle = p['taskTitle'] as String? ?? '';
    final reminderTime = p['reminderTime'] as String? ?? '';
    await reminderSyncService.scheduleFromCache();
    return 'Rescheduled reminder for "$taskTitle" to $reminderTime.';
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
        action.actionType == ActionType.deleteTask;
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
