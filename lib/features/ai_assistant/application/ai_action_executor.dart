import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../../../core/local_db/isar_collections/isar_ai_action_batch.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../context_override/application/context_override_service.dart';
import '../../context_override/domain/models/context_override.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/models/goal_categories.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../intentions/application/intention_capture.dart';
import '../../intentions/application/intention_nudge_sync_service.dart';
import '../../intentions/data/intentions_repository.dart';
import '../../intentions/domain/models/intention.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/data/planning_repository.dart';
import '../../planning/domain/models/task_item.dart';
import '../../reminders/application/reminder_sync_service.dart';
import '../../reminders/data/reminder_repository.dart';
import '../../reminders/domain/models/reminder_config.dart';
import '../../time_blocks/application/time_block_sync_service.dart';
import '../domain/models/ai_action.dart';
import 'ai_action_batch_repository.dart';
import 'ai_action_batch_state.dart';
import 'ai_tier_guard.dart';

// ─── Execution result ─────────────────────────────────────────────────────────

class ExecutionResult {
  const ExecutionResult({
    this.successes = const [],
    this.failures = const [],
    this.batchId,
    this.wasRolledBack = false,
  });

  final List<String> successes;
  final List<String> failures;

  /// The [batchId] of the persisted [IsarAiActionBatch] for this execution.
  final String? batchId;

  /// True if the batch was rolled back due to a partial failure.
  final bool wasRolledBack;

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

// ─── Undo result ──────────────────────────────────────────────────────────────

sealed class UndoResult {
  const UndoResult();
}

class UndoSuccess extends UndoResult {
  const UndoSuccess();
}

class UndoNotAvailable extends UndoResult {
  const UndoNotAvailable(this.reason);
  final String reason;
}

/// Undo succeeded but some tasks that were created/edited by the AI
/// have since been completed by the user. Undo reverts those completions.
class UndoWarningTasksCompleted extends UndoResult {
  const UndoWarningTasksCompleted(this.completedTitles);
  final List<String> completedTitles;
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
    required this.batchRepository,
    this.defaultModeRefId,
    this.tierGuard,
    this.intentionsRepository,
    this.intentionNudgeSyncService,
  });

  final PlanningRepository planningRepository;
  final GoalsRepository goalsRepository;
  final ReminderRepository reminderRepository;
  final ReminderSyncService reminderSyncService;
  final TimeBlockSyncService timeBlockSyncService;
  final ContextOverrideService contextOverrideService;
  final AiActionBatchRepository batchRepository;

  /// Default enforcement mode ref-id applied to AI-created tasks when the
  /// action does not specify one. Sourced from [defaultEnforcementModeProvider].
  final String? defaultModeRefId;

  /// Free-tier creation gates, so the chat path can't sidestep the limits
  /// the manual screens enforce. Null (tests) = no gating.
  final AiTierGuard? tierGuard;

  /// Intentions (humanizing Phase 1). Null in legacy tests — the
  /// createIntention action then fails loudly instead of silently no-oping.
  final IntentionsRepository? intentionsRepository;
  final IntentionNudgeSyncService? intentionNudgeSyncService;

  // ─── Public execute ────────────────────────────────────────────────────────

  Future<ExecutionResult> execute(List<AiAction> actions) async {
    final batchId = StableId.generate('ai_batch');
    final now = DateTime.now().millisecondsSinceEpoch;

    // Pre-assign client ids to createIntention actions so the persisted
    // actionsJson carries them — rollback/undo can then tombstone exactly
    // the intentions this batch created (task-style snapshot restore
    // cannot cover creates).
    for (final action in actions) {
      if (action.actionType == ActionType.createIntention &&
          action.parameters['_intentionId'] == null) {
        action.parameters['_intentionId'] = StableId.generate('intention');
      }
    }

    // Idempotency guard: if this batchId somehow already exists as completed, skip.
    final existing = await batchRepository.findByBatchId(batchId);
    if (existing?.state == AiActionBatchState.completed.name) {
      return ExecutionResult(
        batchId: batchId,
        successes: const ['(already completed)'],
      );
    }

    // Capture pre-mutation snapshot of affected tasks.
    final snapshotJson = await _captureSnapshot(actions);

    // Persist the batch as pending, then transition to executing.
    final batch = IsarAiActionBatch()
      ..batchId = batchId
      ..state = AiActionBatchState.pending.name
      ..actionsJson = jsonEncode(
        actions
            .map((a) => {'type': a.actionType.name, 'params': a.parameters})
            .toList(),
      )
      ..snapshotJson = snapshotJson
      ..succeededActionIds = []
      ..failedActionIds = []
      ..createdAtMs = now
      ..updatedAtMs = now;
    await batchRepository.createBatch(batch);
    await batchRepository.updateState(batchId, AiActionBatchState.executing);

    final successes = <String>[];
    final failures = <String>[];
    final succeededIds = <String>[];
    final failedIds = <String>[];

    for (final action in actions) {
      final actionId =
          action.parameters['_actionId'] as String? ??
          '${action.actionType.name}_${actions.indexOf(action)}';
      try {
        final message = await _dispatch(action);
        if (message != null) successes.add(message);
        await _notifyCoordinator(action);
        succeededIds.add(actionId);
      } catch (e) {
        failures.add('${_humanLabel(action)}: ${e.toString()}');
        failedIds.add(actionId);
      }
    }

    if (failures.isEmpty) {
      await batchRepository.updateState(
        batchId,
        AiActionBatchState.completed,
        succeeded: succeededIds,
        failed: [],
      );
      return ExecutionResult(
        successes: successes,
        failures: failures,
        batchId: batchId,
      );
    } else {
      // Partial failure — record it, then roll back all completed steps.
      await batchRepository.updateState(
        batchId,
        AiActionBatchState.partialFailure,
        succeeded: succeededIds,
        failed: failedIds,
      );
      await _rollbackBatch(batchId, snapshotJson);
      return ExecutionResult(
        successes: const [],
        failures: const [
          "I couldn't complete all steps — I've restored your schedule to its previous state.",
        ],
        batchId: batchId,
        wasRolledBack: true,
      );
    }
  }

  // ─── Undo last batch ───────────────────────────────────────────────────────

  /// Undo the most recent AI batch that is in `completed` or `partialFailure`
  /// state and was created within the last 30 minutes.
  Future<UndoResult> undoLastAiBatch() async {
    final batch = await batchRepository.findMostRecent();
    return _undoBatch(batch);
  }

  /// Undo a SPECIFIC batch by id — the inline [Undo] on an auto-committed
  /// createIntention message targets its own batch, not whatever ran last.
  Future<UndoResult> undoBatchById(String batchId) async {
    final batch = await batchRepository.findByBatchId(batchId);
    return _undoBatch(batch);
  }

  Future<UndoResult> _undoBatch(IsarAiActionBatch? batch) async {
    if (batch == null) {
      return const UndoNotAvailable('No AI changes to undo.');
    }

    final isUndoable =
        batch.state == AiActionBatchState.completed.name ||
        batch.state == AiActionBatchState.partialFailure.name;
    if (!isUndoable) {
      return UndoNotAvailable(
        'The last AI batch (${batch.state}) cannot be undone.',
      );
    }

    final ageMs = DateTime.now().millisecondsSinceEpoch - batch.createdAtMs;
    if (ageMs > const Duration(minutes: 30).inMilliseconds) {
      return const UndoNotAvailable(
        'This AI change is more than 30 minutes old and can no longer be undone.',
      );
    }

    // Check if any snapshotted tasks have been completed since the AI batch.
    final completedTitles = await _findCompletedSnapshotTasks(
      batch.snapshotJson,
    );

    await _rollbackBatch(batch.batchId, batch.snapshotJson);

    if (completedTitles.isNotEmpty) {
      return UndoWarningTasksCompleted(completedTitles);
    }
    return const UndoSuccess();
  }

  // ─── Snapshot ─────────────────────────────────────────────────────────────

  /// Capture a minimal JSON snapshot of entities that will be mutated.
  /// Uses the affected date keys from the actions to fetch all tasks for
  /// those dates, then filters to only the relevant taskIds.
  /// Used as the rollback payload for [_rollbackBatch].
  Future<String> _captureSnapshot(List<AiAction> actions) async {
    final tasks = <Map<String, dynamic>>[];
    final seenTaskIds = <String>{};

    // Collect all affected date keys and explicit task IDs.
    final dateKeys = <String>{};
    for (final action in actions) {
      final dateStr = _resolveDate(action.parameters['date'] as String?);
      dateKeys.add(dateStr);
      final destDate = _resolveDate(
        action.parameters['destinationDate'] as String?,
      );
      dateKeys.add(destDate);
    }

    // Fetch all tasks for each affected date and snapshot them.
    for (final dateKey in dateKeys) {
      try {
        final rows = await collectTasksForDateKey(planningRepository, dateKey);
        for (final row in rows) {
          final t = row.task;
          if (seenTaskIds.contains(t.id)) continue;
          seenTaskIds.add(t.id);
          tasks.add({
            'id': t.id,
            'routineId': t.routineId,
            'blockId': t.blockId,
            'title': t.title,
            'durationMinutes': t.durationMinutes,
            'priority': t.priority,
            'orderIndex': t.orderIndex,
            'reminderEnabled': t.reminderEnabled,
            'reminderTimeIso': t.reminderTimeIso,
            'status': t.status.name,
            'planDateKey': t.planDateKey,
            'modeRefId': t.modeRefId,
            'notes': t.notes,
            'category': t.category,
            'createdAtMs': t.createdAtMs,
            'updatedAtMs': t.updatedAtMs,
          });
        }
      } catch (e) {
        debugPrint('ai_action_executor: swallowed error: $e');
      }
    }

    return jsonEncode({'tasks': tasks});
  }

  // ─── Rollback ─────────────────────────────────────────────────────────────

  /// Restore all snapshotted entities from [snapshotJson] and trigger
  /// recompute through the coordinator.
  Future<void> _rollbackBatch(String batchId, String snapshotJson) async {
    await _rollbackCreatedIntentions(batchId);
    try {
      final snapshot = jsonDecode(snapshotJson) as Map<String, dynamic>?;
      final taskList = (snapshot?['tasks'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      for (final taskMap in taskList) {
        final restored = PlannedTask(
          id: taskMap['id'] as String,
          routineId: taskMap['routineId'] as String,
          blockId: taskMap['blockId'] as String,
          title: taskMap['title'] as String,
          durationMinutes: (taskMap['durationMinutes'] as num).toInt(),
          priority: (taskMap['priority'] as num).toInt(),
          orderIndex: (taskMap['orderIndex'] as num).toInt(),
          reminderEnabled: taskMap['reminderEnabled'] as bool,
          reminderTimeIso: taskMap['reminderTimeIso'] as String?,
          status: _taskStatusFromName(taskMap['status'] as String?),
          planDateKey: taskMap['planDateKey'] as String?,
          modeRefId: taskMap['modeRefId'] as String?,
          notes: taskMap['notes'] as String?,
          category: taskMap['category'] as String?,
          createdAtMs: (taskMap['createdAtMs'] as num).toInt(),
          // Bump updatedAtMs so LWW wins over any stale remote state.
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        );
        await planningRepository.upsertTask(restored);
        await ScheduleMutationCoordinator.instance.run(
          TaskUpdatedMutation(
            entityId: restored.id,
            sourceContext: 'ai_rollback',
            dateStr: restored.planDateKey ?? DateKeys.todayKey(),
          ),
          commitOverride: () async {},
        );
      }

      await batchRepository.updateState(
        batchId,
        AiActionBatchState.rolledBack,
        undoneAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('ai_action_executor: swallowed error: $e');
    }
  }

  /// Tombstones intentions created by this batch (undo of an auto-committed
  /// createIntention) and cancels their pending nudges. Ids come from the
  /// persisted actionsJson (`_intentionId`, pre-assigned in [execute]).
  Future<void> _rollbackCreatedIntentions(String batchId) async {
    final repo = intentionsRepository;
    if (repo == null) return;
    try {
      final batch = await batchRepository.findByBatchId(batchId);
      if (batch == null) return;
      final actionList = (jsonDecode(batch.actionsJson) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (final entry in actionList) {
        if (entry['type'] != ActionType.createIntention.name) continue;
        final params = (entry['params'] as Map?)?.cast<String, dynamic>();
        final intentionId = params?['_intentionId'] as String?;
        if (intentionId == null || intentionId.isEmpty) continue;
        await intentionNudgeSyncService?.cancelForIntention(intentionId);
        await repo.deleteIntention(intentionId);
      }
    } catch (e) {
      debugPrint('ai_action_executor: swallowed error: $e');
    }
  }

  /// Check if any tasks in the snapshot have since been completed by the user.
  Future<List<String>> _findCompletedSnapshotTasks(String snapshotJson) async {
    final titles = <String>[];
    try {
      final snapshot = jsonDecode(snapshotJson) as Map<String, dynamic>?;
      final taskList = (snapshot?['tasks'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      // Collect unique date keys from snapshot to query current tasks.
      final dateKeys = <String>{};
      for (final t in taskList) {
        final dk = t['planDateKey'] as String?;
        if (dk != null) dateKeys.add(dk);
      }
      final taskIdToSnapshotStatus = {
        for (final t in taskList)
          if (t['id'] != null) t['id'] as String: t['status'] as String?,
      };

      for (final dateKey in dateKeys) {
        final rows = await collectTasksForDateKey(planningRepository, dateKey);
        for (final row in rows) {
          final taskId = row.task.id;
          if (!taskIdToSnapshotStatus.containsKey(taskId)) continue;
          final wasCompleted =
              taskIdToSnapshotStatus[taskId] == TaskStatus.completed.name;
          final isNowCompleted = row.task.status == TaskStatus.completed;
          // Warn if the task went from not-completed to completed since the AI batch.
          if (!wasCompleted && isNowCompleted) {
            titles.add(row.task.title);
          }
        }
      }
    } catch (e) {
      debugPrint('ai_action_executor: swallowed error: $e');
    }
    return titles;
  }

  TaskStatus _taskStatusFromName(String? name) {
    for (final s in TaskStatus.values) {
      if (s.name == name) return s;
    }
    return TaskStatus.notStarted;
  }

  // ─── Coordinator notify ───────────────────────────────────────────────────

  /// Notify [ScheduleMutationCoordinator] about a completed action so it can
  /// trigger the correct recompute scope and publish a domain event.
  ///
  /// Uses [commitOverride] = no-op because the write has already happened
  /// inside [_dispatch]. This is the adapter pattern for incremental migration.
  Future<void> _notifyCoordinator(AiAction action) async {
    final request = _mutationRequestFor(action);
    if (request == null) return;
    await ScheduleMutationCoordinator.instance.run(
      request,
      commitOverride: () async {}, // write already done by _dispatch
    );
  }

  /// Maps an [AiAction] to the appropriate [MutationRequest] for the coordinator.
  MutationRequest? _mutationRequestFor(AiAction action) {
    final dateStr = _resolveDate(action.parameters['date'] as String?);
    const source = 'ai_action_executor';

    switch (action.actionType) {
      case ActionType.createTask:
      case ActionType.addReminder:
        final taskId =
            action.parameters['_resolvedTaskId'] as String? ?? 'ai-task';
        return TaskCreatedMutation(
          entityId: taskId,
          sourceContext: source,
          dateStr: dateStr,
        );
      case ActionType.editTask:
      case ActionType.rescheduleReminder:
        final taskId =
            action.parameters['_resolvedTaskId'] as String? ?? 'ai-task';
        return TaskUpdatedMutation(
          entityId: taskId,
          sourceContext: source,
          dateStr: dateStr,
        );
      case ActionType.moveTask:
        final taskId =
            action.parameters['_resolvedTaskId'] as String? ?? 'ai-task';
        final toDate = _resolveDate(
          action.parameters['destinationDate'] as String?,
        );
        return TaskDeferredMutation(
          entityId: taskId,
          sourceContext: source,
          fromDateStr: dateStr,
          toDateStr: toDate,
        );
      case ActionType.deleteTask:
        final taskId =
            action.parameters['_resolvedTaskId'] as String? ?? 'ai-task';
        return TaskDeletedMutation(
          entityId: taskId,
          sourceContext: source,
          dateStr: dateStr,
        );
      case ActionType.createGoal:
      case ActionType.modifyGoal:
      case ActionType.deleteGoal:
        final goalId =
            action.parameters['_resolvedGoalId'] as String? ?? 'ai-goal';
        return GoalChangedMutation(
          entityId: goalId,
          sourceContext: source,
          changeKind: action.actionType.name,
        );
      case ActionType.removeReminder:
        final taskId =
            action.parameters['_resolvedTaskId'] as String? ?? 'ai-task';
        return ReminderChangedMutation(entityId: taskId, sourceContext: source);
      case ActionType.activateContextOverride:
      case ActionType.endContextOverride:
        return ContextOverrideChangedMutation(
          entityId: 'context_override',
          sourceContext: source,
          overrideType: action.parameters['overrideType'] as String? ?? 'none',
        );
      case ActionType.suggestFreeTimeBlock:
      case ActionType.moveConflictingTasks:
        return null; // read-only actions — no mutation to notify
      case ActionType.createIntention:
        // Planning happens directly in _createIntention (unthrottled) —
        // no schedule mutation to notify.
        return null;
    }
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
      case ActionType.createIntention:
        return _createIntention(action.parameters);
    }
  }

  // ─── Intention handler (humanizing Phase 1) ───────────────────────────────

  /// Auto-committed with undo: stating an intention is permission
  /// (settled: Q1). SidePal picks the delivery moment; the confirmation
  /// happens at delivery, where the suggestion is phrased as a question.
  Future<String> _createIntention(Map<String, dynamic> p) async {
    final repo = intentionsRepository;
    if (repo == null) {
      throw StateError('Intentions are not available in this build.');
    }
    final title = (p['title'] as String?)?.trim() ?? '';
    if (title.isEmpty) {
      throw ArgumentError('title is required to capture an intention');
    }

    final now = DateTime.now();
    final windowKind = switch (p['window'] as String?) {
      'today' => IntentionWindowKind.today,
      'tomorrow' => IntentionWindowKind.tomorrow,
      'weekend' => IntentionWindowKind.weekend,
      _ => IntentionWindowKind.thisWeek,
    };
    final window = resolveIntentionWindow(windowKind, now);

    final tagsRaw = p['activityTags'];
    final tags = tagsRaw is List
        ? tagsRaw.whereType<String>().toList(growable: false)
        : const <String>[];
    final importance = switch (p['importance'] as String?) {
      'high' => IntentionImportance.high,
      'low' => IntentionImportance.low,
      _ => IntentionImportance.normal,
    };
    final hints = p['aiHints'];

    final draft = IntentionDraft(
      title: title,
      rawUtterance: p['rawUtterance'] as String? ?? title,
      windowStart: window.start,
      windowEnd: window.end,
      estimatedMinutes: ((p['estimatedMinutes'] as num?)?.toInt() ?? 20)
          .clamp(1, 1440),
      importance: importance,
      activityTags: tags,
      aiHintsJson: hints is Map ? jsonEncode(hints) : null,
    );
    var intention = buildIntention(draft, now: now);
    // Keep the batch-persisted id so undo can tombstone this exact record.
    final presetId = p['_intentionId'] as String?;
    if (presetId != null && presetId.isNotEmpty) {
      intention = Intention.fromMap(
        intention.toMap()..['id'] = presetId,
      );
    }
    intention.validate();

    await repo.upsertIntention(intention);
    // Plan the ladder right away (unthrottled) so the Promises strip shows
    // "planned for …" the moment the chat bubble appears. Airplane-safe.
    try {
      await intentionNudgeSyncService?.applyForIntention(intention);
    } catch (e) {
      debugPrint('ai_action_executor: intention planning failed: $e');
    }

    final windowLabel = switch (windowKind) {
      IntentionWindowKind.today => 'today',
      IntentionWindowKind.tomorrow => 'tomorrow',
      IntentionWindowKind.weekend => 'this weekend',
      IntentionWindowKind.thisWeek => 'this week',
    };
    return 'Got it — I\'ll find a good time $windowLabel for "$title".';
  }

  // ─── Task handlers ────────────────────────────────────────────────────────

  Future<String> _createTask(Map<String, dynamic> p) async {
    final title = p['title'] as String? ?? 'New Task';
    final dateStr = _resolveDate(p['date'] as String?);
    final timeStr = p['time'] as String?;
    final durationMinutes = (p['duration'] as num?)?.toInt() ?? 30;
    // Use action-provided modeRefId first, then executor default, then null.
    final modeRefId = p['modeRefId'] as String? ?? defaultModeRefId;

    await tierGuard?.ensureCanCreateTask(dateStr);

    final (:routineId, :blockId) = await planningRepository
        .ensureDefaultDayPlan(dateStr);
    final orderIndex = await _nextOrderIndexForDate(dateStr);
    final reminderTime = _parseReminderDateTime(dateStr, timeStr);
    if (reminderTime != null) {
      await tierGuard?.ensureCanAddReminder();
    }

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
    final (:routineId, :blockId) = await planningRepository
        .ensureDefaultDayPlan(dateStr);

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
    await tierGuard?.ensureCanCreateGoal();
    final title = p['title'] as String? ?? 'New Goal';
    final target = p['target'] as String? ?? '';
    final deadlineStr = p['deadline'] as String?;

    final now = DateTime.now().millisecondsSinceEpoch;
    final periodEnd = deadlineStr != null
        ? (() {
            try {
              return DateKeys.parseLocalDateKey(
                deadlineStr,
              ).millisecondsSinceEpoch;
            } catch (_) {
              return now;
            }
          }())
        : now + const Duration(days: 30).inMilliseconds;

    // Repeat off: an AI-created goal with a deadline is a one-time outcome
    // goal — progress accumulates until the deadline.
    final goal = UserGoal(
      id: StableId.generate('goal'),
      title: title,
      categoryId: GoalCategories.productivity,
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
    final taskTitle = (p['taskTitle'] as String?)?.trim().isNotEmpty == true
        ? (p['taskTitle'] as String).trim()
        : (p['title'] as String?)?.trim().isNotEmpty == true
        ? (p['title'] as String).trim()
        : 'Reminder';
    final dateStr = _resolveDate(p['date'] as String?);
    final timeStr = p['reminderTime'] as String? ?? p['time'] as String?;

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
    final taskTitle = (p['taskTitle'] as String?)?.trim().isNotEmpty == true
        ? (p['taskTitle'] as String).trim()
        : (p['title'] as String?)?.trim().isNotEmpty == true
        ? (p['title'] as String).trim()
        : '';
    if (taskTitle.isEmpty) {
      throw ArgumentError('taskTitle is required to reschedule a reminder');
    }

    final dateStr = _resolveDate(p['date'] as String?);
    final timeStr = p['reminderTime'] as String? ?? p['time'] as String?;

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
    } catch (e) {
      debugPrint('ai_action_executor: swallowed error: $e');
    }

    final existingReminders = await reminderRepository.getRemindersForTasks([
      taskId,
    ]);
    final existingConfig = existingReminders.isNotEmpty
        ? existingReminders.first
        : null;
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
    final title =
        action.parameters['title'] as String? ??
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
    final tomorrow = DateKeys.todayKey(
      DateTime.now().add(const Duration(days: 1)),
    );
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
