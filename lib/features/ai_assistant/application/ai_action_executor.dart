import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../../../core/local_db/isar_collections/isar_ai_action_batch.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/friendly_date.dart';
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
import '../../memory/application/memory_extraction_parser.dart';
import '../../memory/data/memory_facts_repository.dart';
import '../../memory/data/people_repository.dart';
import '../../memory/domain/models/memory_fact.dart';
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

/// NOTHING has been rolled back yet: tasks the AI touched have since been
/// completed by the user, and undoing would revert those completions. The
/// caller must ask the user first, then re-invoke undo with `force: true`
/// targeting [batchId]. (Fix-wave Phase 0: the old shape rolled back BEFORE
/// warning, which made the dialog's Cancel button a lie — §8 E4.)
class UndoNeedsConfirmation extends UndoResult {
  const UndoNeedsConfirmation(this.batchId, this.completedTitles);
  final String batchId;
  final List<String> completedTitles;
}

/// The rollback ran but hit an error — some changes may not have been
/// restored. Honest failure instead of the old swallowed-then-UndoSuccess.
class UndoFailed extends UndoResult {
  const UndoFailed();
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
    this.memoryFactsRepository,
    this.peopleRepository,
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

  /// Memory (humanizing Phase 2). Null in legacy tests — memory actions
  /// then fail loudly instead of silently no-oping.
  final MemoryFactsRepository? memoryFactsRepository;
  final PeopleRepository? peopleRepository;

  // ─── Public execute ────────────────────────────────────────────────────────

  Future<ExecutionResult> execute(List<AiAction> requested) async {
    final batchId = StableId.generate('ai_batch');
    final now = DateTime.now().millisecondsSinceEpoch;

    // Work on copies: the pre-pass below annotates parameters with
    // bookkeeping keys (_intentionId/_factId/_prevGoalJson/…), and mutating
    // the caller's live maps leaked those keys into the preview card
    // message and history — and broke outright on unmodifiable maps
    // (§8 E17-adjacent INFO, verified by test).
    final actions = [
      for (final a in requested)
        a.copyWith(parameters: Map<String, dynamic>.from(a.parameters)),
    ];

    // Pre-assign client ids to createIntention actions so the persisted
    // actionsJson carries them — rollback/undo can then tombstone exactly
    // the intentions this batch created (task-style snapshot restore
    // cannot cover creates).
    for (final action in actions) {
      if (action.actionType == ActionType.createIntention &&
          action.parameters['_intentionId'] == null) {
        action.parameters['_intentionId'] = StableId.generate('intention');
      }
      if (action.actionType == ActionType.rememberFact &&
          action.parameters['_factId'] == null) {
        action.parameters['_factId'] = StableId.generate('memfact');
      }
      // update/forget mutate an EXISTING fact: resolve the target and stash
      // its pre-mutation state in the persisted params so rollback/undo can
      // restore it exactly (the task snapshot cannot cover facts).
      if (action.actionType == ActionType.updateFact ||
          action.actionType == ActionType.forgetFact) {
        try {
          final target = await _resolveFactRef(
            action.parameters['factRef'] as String?,
          );
          if (target != null) {
            action.parameters['_targetFactId'] = target.id;
            action.parameters['_prevFactJson'] = jsonEncode(target.toMap());
          }
        } on ArgumentError {
          // Ambiguous ref — the handler re-resolves and surfaces the
          // disambiguation question as its per-action failure.
        }
      }
      // modify/delete goal: same pattern — stash the pre-mutation goal so
      // rollback/undo can restore it (the task snapshot cannot cover
      // goals; fix-wave Phase 1).
      if (action.actionType == ActionType.modifyGoal ||
          action.actionType == ActionType.deleteGoal) {
        final goalId = action.parameters['_resolvedGoalId'] as String?;
        if (goalId != null) {
          try {
            final goals = await goalsRepository.fetchGoalsOnce();
            for (final g in goals) {
              if (g.id == goalId) {
                action.parameters['_prevGoalJson'] = jsonEncode(g.toMap());
                break;
              }
            }
          } catch (e) {
            debugPrint('ai_action_executor: goal stash failed: $e');
          }
        }
      }
    }

    // Persist the batch as pending, then transition to executing. The
    // snapshot is an inverse-operation log (fix-wave Phase 2): each handler
    // records the EXACT inverse of what it did, so undo can never touch
    // unrelated data — the old date-wide task snapshot restored every task
    // on the affected days (GPT-5.6 G3: undoing a "remember this" could
    // revert today's completions and LWW-push that to other devices).
    final inverseOps = <Map<String, dynamic>>[];
    final batch = IsarAiActionBatch()
      ..batchId = batchId
      ..state = AiActionBatchState.pending.name
      ..actionsJson = jsonEncode(
        actions
            .map((a) => {'type': a.actionType.name, 'params': a.parameters})
            .toList(),
      )
      ..snapshotJson = jsonEncode({'inverseOps': inverseOps})
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
        final message = await _dispatch(action, inverseOps);
        if (message != null) successes.add(message);
        await _notifyCoordinator(action);
        succeededIds.add(actionId);
      } catch (e) {
        failures.add('${_humanLabel(action)}: ${e.toString()}');
        failedIds.add(actionId);
      }
      // Persist the log after EVERY action — a crash mid-batch leaves a
      // rollback-able record for the boot sweep (§8 E8).
      await batchRepository.updateSnapshot(
        batchId,
        jsonEncode({'inverseOps': inverseOps}),
      );
    }

    // Per-item outcomes (settled Q4): independent actions succeed and fail
    // independently — the old all-or-nothing rollback destroyed the user's
    // confirmed work over one failed step, and couldn't even revert creates
    // while claiming it had (§8 E3/E6). Undo of a partialFailure batch
    // reverts exactly the succeeded actions: their ops are the only ones in
    // the log.
    await batchRepository.updateState(
      batchId,
      failures.isEmpty
          ? AiActionBatchState.completed
          : AiActionBatchState.partialFailure,
      succeeded: succeededIds,
      failed: failedIds,
    );
    return ExecutionResult(
      successes: successes,
      failures: failures,
      batchId: batchId,
    );
  }

  // ─── Undo last batch ───────────────────────────────────────────────────────

  /// Undo the most recent AI batch that is in `completed` or `partialFailure`
  /// state and was created within the last 30 minutes.
  ///
  /// [force] skips the completed-tasks confirmation gate — pass it only
  /// after the user explicitly chose "Undo anyway" on a
  /// [UndoNeedsConfirmation] result.
  Future<UndoResult> undoLastAiBatch({bool force = false}) async {
    final batch = await batchRepository.findMostRecent();
    return _undoBatch(batch, force: force);
  }

  /// Undo a SPECIFIC batch by id — the inline [Undo] on an auto-committed
  /// createIntention message targets its own batch, not whatever ran last.
  Future<UndoResult> undoBatchById(String batchId, {bool force = false}) async {
    final batch = await batchRepository.findByBatchId(batchId);
    return _undoBatch(batch, force: force);
  }

  Future<UndoResult> _undoBatch(
    IsarAiActionBatch? batch, {
    bool force = false,
  }) async {
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

    // Dry-run gate: when tasks the batch touched were completed since, ask
    // BEFORE mutating anything — Cancel must actually cancel (§8 E4).
    if (!force) {
      final completedTitles = await _findCompletedSnapshotTasks(
        batch.snapshotJson,
      );
      if (completedTitles.isNotEmpty) {
        return UndoNeedsConfirmation(batch.batchId, completedTitles);
      }
    }

    final ok = await _rollbackBatch(batch.batchId, batch.snapshotJson);
    return ok ? const UndoSuccess() : const UndoFailed();
  }

  // ─── Inverse-op log (fix-wave Phase 2) ─────────────────────────────────────

  /// Full serialization of a task row for a `restoreTask` inverse op.
  static Map<String, dynamic> _taskRowMap(PlannedTask t) => {
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
    'sequenceIndex': t.sequenceIndex,
    'isHabitAnchor': t.isHabitAnchor,
    'strictModeRequired': t.strictModeRequired,
    'createdAtMs': t.createdAtMs,
    'updatedAtMs': t.updatedAtMs,
  };

  PlannedTask _taskFromRowMap(Map<String, dynamic> m) => PlannedTask(
    id: m['id'] as String,
    routineId: m['routineId'] as String,
    blockId: m['blockId'] as String,
    title: m['title'] as String,
    durationMinutes: (m['durationMinutes'] as num).toInt(),
    priority: (m['priority'] as num).toInt(),
    orderIndex: (m['orderIndex'] as num).toInt(),
    reminderEnabled: m['reminderEnabled'] as bool,
    reminderTimeIso: m['reminderTimeIso'] as String?,
    status: _taskStatusFromName(m['status'] as String?),
    planDateKey: m['planDateKey'] as String?,
    modeRefId: m['modeRefId'] as String?,
    notes: m['notes'] as String?,
    category: m['category'] as String?,
    sequenceIndex: (m['sequenceIndex'] as num?)?.toInt(),
    isHabitAnchor: m['isHabitAnchor'] as bool? ?? false,
    strictModeRequired: m['strictModeRequired'] as bool? ?? false,
    createdAtMs: (m['createdAtMs'] as num).toInt(),
    // Bump updatedAtMs so LWW wins over any stale remote state.
    updatedAtMs: DateTime.now().millisecondsSinceEpoch,
  );

  /// Captures the pre-mutation reminder configs for [taskId] as a
  /// `restoreReminderConfigs` op — appended by every handler that changes
  /// or removes a task's reminder state, so undo restores the config rows
  /// AND re-schedules the OS notifications (§8 E7: undo used to leave
  /// armed notifications and stale configs behind).
  Future<Map<String, dynamic>> _reminderConfigsOp(String taskId) async {
    List<Map<String, dynamic>> configs = const [];
    try {
      final existing = await reminderRepository.getRemindersForTasks([taskId]);
      configs = [for (final c in existing) c.toMap()];
    } catch (e) {
      debugPrint('ai_action_executor: config capture failed: $e');
    }
    return {'op': 'restoreReminderConfigs', 'taskId': taskId,
        'configs': configs};
  }

  // ─── Rollback ─────────────────────────────────────────────────────────────

  /// Applies the batch's inverse-operation log in reverse order — each op
  /// individually guarded, nothing swallowed into a false success. Legacy
  /// batches (pre-Phase-2 `{"tasks": …}` snapshots, still inside the 30-min
  /// undo window across an app update) take the old restore path. Returns
  /// false when any op failed — the batch state is then left untouched so
  /// undo stays available for a retry.
  Future<bool> _rollbackBatch(String batchId, String snapshotJson) async {
    Map<String, dynamic>? snapshot;
    try {
      snapshot = jsonDecode(snapshotJson) as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('ai_action_executor: unreadable snapshot: $e');
      return false;
    }

    final bool allOk;
    if (snapshot != null && snapshot['inverseOps'] is List) {
      final ops = (snapshot['inverseOps'] as List)
          .cast<Map<String, dynamic>>();
      allOk = await _applyInverseOps(ops);
    } else {
      allOk = await _legacyRollback(batchId, snapshot);
    }

    if (allOk) {
      await batchRepository.updateState(
        batchId,
        AiActionBatchState.rolledBack,
        undoneAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    }
    return allOk;
  }

  Future<bool> _applyInverseOps(List<Map<String, dynamic>> ops) async {
    var allOk = true;
    for (final op in ops.reversed) {
      try {
        switch (op['op'] as String?) {
          case 'deleteTask':
            final taskId = op['taskId'] as String;
            await planningRepository.deleteTask(
              routineId: op['routineId'] as String,
              blockId: op['blockId'] as String,
              taskId: taskId,
            );
            await reminderSyncService.removeForDeletedTask(taskId);
            await timeBlockSyncService.removeBlockForEntity(taskId);
          case 'restoreTask':
            final restored = _taskFromRowMap(
              (op['row'] as Map).cast<String, dynamic>(),
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
          case 'restoreReminderConfigs':
            final taskId = op['taskId'] as String;
            final configs = (op['configs'] as List? ?? const [])
                .cast<Map>()
                .map((m) => ReminderConfig.fromMap(m.cast<String, dynamic>()))
                .toList();
            if (configs.isEmpty) {
              // The action ADDED reminder state where none existed.
              await reminderSyncService.removeForDeletedTask(taskId);
            } else {
              for (final c in configs) {
                await reminderRepository.upsertReminder(
                  c.copyWith(
                    updatedAtMs: DateTime.now().millisecondsSinceEpoch,
                  ),
                );
              }
              await reminderSyncService.syncForTaskIds([taskId]);
            }
          case 'deleteGoal':
            await goalsRepository.deleteGoal(op['goalId'] as String);
          case 'restoreGoal':
            final restored = UserGoal.fromMap(
              (op['goal'] as Map).cast<String, dynamic>(),
            ).copyWith(updatedAtMs: DateTime.now().millisecondsSinceEpoch);
            await goalsRepository.upsertGoal(restored);
          case 'deleteIntention':
            final id = op['intentionId'] as String;
            await intentionNudgeSyncService?.cancelForIntention(id);
            await intentionsRepository?.deleteIntention(id);
          case 'deleteFact':
            await memoryFactsRepository?.deleteFact(op['factId'] as String);
          case 'restoreFact':
            final restored = MemoryFact.fromMap(
              (op['fact'] as Map).cast<String, dynamic>(),
            ).copyWith(updatedAtMs: DateTime.now().millisecondsSinceEpoch);
            await memoryFactsRepository?.upsertFact(restored);
          default:
            debugPrint('ai_action_executor: unknown inverse op ${op['op']}');
            allOk = false;
        }
      } catch (e) {
        debugPrint('ai_action_executor: inverse op ${op['op']} failed: $e');
        allOk = false;
      }
    }
    return allOk;
  }

  /// Pre-Phase-2 rollback: the date-wide task snapshot plus the actionsJson
  /// sub-rollbacks. Kept only for batches persisted before the update.
  Future<bool> _legacyRollback(
    String batchId,
    Map<String, dynamic>? snapshot,
  ) async {
    await _rollbackCreatedIntentions(batchId);
    await _rollbackMemoryActions(batchId);
    await _rollbackGoalActions(batchId);
    try {
      final taskList = (snapshot?['tasks'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      for (final taskMap in taskList) {
        final restored = _taskFromRowMap(taskMap);
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
      return true;
    } catch (e) {
      debugPrint('ai_action_executor: legacy rollback failed: $e');
      return false;
    }
  }

  /// Rolls back batches a crash left stranded in pending/executing (§8 E8)
  /// — their per-action-persisted inverse logs are exactly the repair
  /// record. Called from the bootstrap maintenance block.
  Future<void> sweepStrandedBatches() async {
    try {
      final stranded = await batchRepository.findStranded();
      for (final batch in stranded) {
        debugPrint(
          'ai_action_executor: sweeping stranded batch ${batch.batchId} '
          '(${batch.state})',
        );
        await _rollbackBatch(batch.batchId, batch.snapshotJson);
      }
    } catch (e) {
      debugPrint('ai_action_executor: stranded sweep failed: $e');
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

  /// Undo of memory actions: created facts are tombstoned; updated or
  /// forgotten facts are restored from the pre-mutation state stashed in
  /// the persisted actionsJson (`_prevFactJson`).
  Future<void> _rollbackMemoryActions(String batchId) async {
    final repo = memoryFactsRepository;
    if (repo == null) return;
    try {
      final batch = await batchRepository.findByBatchId(batchId);
      if (batch == null) return;
      final actionList = (jsonDecode(batch.actionsJson) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (final entry in actionList) {
        final params = (entry['params'] as Map?)?.cast<String, dynamic>();
        if (entry['type'] == ActionType.rememberFact.name) {
          final factId = params?['_factId'] as String?;
          if (factId != null && factId.isNotEmpty) {
            await repo.deleteFact(factId);
          }
        } else if (entry['type'] == ActionType.updateFact.name ||
            entry['type'] == ActionType.forgetFact.name) {
          final prevJson = params?['_prevFactJson'] as String?;
          if (prevJson == null) continue;
          final restored = MemoryFact.fromMap(
            (jsonDecode(prevJson) as Map).cast<String, dynamic>(),
          ).copyWith(updatedAtMs: DateTime.now().millisecondsSinceEpoch);
          await repo.upsertFact(restored);
        }
      }
    } catch (e) {
      debugPrint('ai_action_executor: swallowed error: $e');
    }
  }

  /// Undo of goal actions: modified or deleted goals are restored from the
  /// pre-mutation state stashed in the persisted actionsJson
  /// (`_prevGoalJson`, fix-wave Phase 1 — mirrors [_rollbackMemoryActions]).
  /// A deleted goal's check-in history is not restorable here (the
  /// repository purges it); the Phase 2 inverse-op log will cover it.
  Future<void> _rollbackGoalActions(String batchId) async {
    try {
      final batch = await batchRepository.findByBatchId(batchId);
      if (batch == null) return;
      final actionList = (jsonDecode(batch.actionsJson) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (final entry in actionList) {
        if (entry['type'] != ActionType.modifyGoal.name &&
            entry['type'] != ActionType.deleteGoal.name) {
          continue;
        }
        final params = (entry['params'] as Map?)?.cast<String, dynamic>();
        final prevJson = params?['_prevGoalJson'] as String?;
        if (prevJson == null) continue;
        final restored = UserGoal.fromMap(
          (jsonDecode(prevJson) as Map).cast<String, dynamic>(),
        ).copyWith(updatedAtMs: DateTime.now().millisecondsSinceEpoch);
        await goalsRepository.upsertGoal(restored);
      }
    } catch (e) {
      debugPrint('ai_action_executor: goal rollback failed: $e');
    }
  }

  /// Tasks this batch touched that the user has COMPLETED since — undoing
  /// would revert (restoreTask) or delete (created-task deleteTask op)
  /// those completions, so the caller asks first. Reads the inverse-op log;
  /// the legacy `{"tasks": …}` snapshot format is still understood for
  /// batches persisted before Phase 2.
  Future<List<String>> _findCompletedSnapshotTasks(String snapshotJson) async {
    final titles = <String>[];
    try {
      final snapshot = jsonDecode(snapshotJson) as Map<String, dynamic>?;

      // (taskId, dateKey, wasCompleted) triples the batch touched.
      final touched = <String, ({String? dateKey, bool wasCompleted})>{};
      final ops = snapshot?['inverseOps'] as List<dynamic>?;
      if (ops != null) {
        for (final raw in ops.cast<Map>()) {
          final op = raw.cast<String, dynamic>();
          switch (op['op']) {
            case 'restoreTask':
              final row = (op['row'] as Map).cast<String, dynamic>();
              touched[row['id'] as String] = (
                dateKey: row['planDateKey'] as String?,
                wasCompleted:
                    row['status'] == TaskStatus.completed.name,
              );
            case 'deleteTask':
              // A task this batch CREATED — it did not exist before, so
              // any completion since is the user's work.
              touched[op['taskId'] as String] = (
                dateKey: op['dateKey'] as String?,
                wasCompleted: false,
              );
          }
        }
      } else {
        final taskList = (snapshot?['tasks'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final t in taskList) {
          if (t['id'] == null) continue;
          touched[t['id'] as String] = (
            dateKey: t['planDateKey'] as String?,
            wasCompleted: t['status'] == TaskStatus.completed.name,
          );
        }
      }

      final dateKeys = <String>{
        for (final v in touched.values)
          if (v.dateKey != null) v.dateKey!,
      };
      for (final dateKey in dateKeys) {
        final rows = await collectTasksForDateKey(planningRepository, dateKey);
        for (final row in rows) {
          final entry = touched[row.task.id];
          if (entry == null) continue;
          if (!entry.wasCompleted &&
              row.task.status == TaskStatus.completed) {
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
      case ActionType.rememberFact:
      case ActionType.updateFact:
      case ActionType.forgetFact:
        return null; // memory writes never touch the schedule
    }
  }

  // ─── Dispatcher ───────────────────────────────────────────────────────────

  Future<String?> _dispatch(
    AiAction action,
    List<Map<String, dynamic>> ops,
  ) async {
    switch (action.actionType) {
      case ActionType.createTask:
        return _createTask(action.parameters, ops);
      case ActionType.editTask:
        return _editTask(action.parameters, ops);
      case ActionType.moveTask:
        return _moveTask(action.parameters, ops);
      case ActionType.deleteTask:
        return _deleteTask(action.parameters, ops);
      case ActionType.createGoal:
        return _createGoal(action.parameters, ops);
      case ActionType.modifyGoal:
        return _modifyGoal(action.parameters, ops);
      case ActionType.deleteGoal:
        return _deleteGoal(action.parameters, ops);
      case ActionType.addReminder:
        return _addReminder(action.parameters, ops);
      case ActionType.removeReminder:
        return _removeReminder(action.parameters, ops);
      case ActionType.rescheduleReminder:
        return _rescheduleReminder(action.parameters, ops);
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
        return _createIntention(action.parameters, ops);
      case ActionType.rememberFact:
        return _rememberFact(action.parameters, ops);
      case ActionType.updateFact:
        return _updateFact(action.parameters, ops);
      case ActionType.forgetFact:
        return _forgetFact(action.parameters, ops);
    }
  }

  // ─── Intention handler (humanizing Phase 1) ───────────────────────────────

  /// Auto-committed with undo: stating an intention is permission
  /// (settled: Q1). SidePal picks the delivery moment; the confirmation
  /// happens at delivery, where the suggestion is phrased as a question.
  Future<String> _createIntention(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
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
    ops.add({'op': 'deleteIntention', 'intentionId': intention.id});
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

  // ─── Memory handlers (humanizing Phase 2) ─────────────────────────────────

  /// "Remember this" — auto-committed with undo. Explicit remembering is
  /// userStated by definition: the utterance IS the statement.
  Future<String> _rememberFact(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
    final repo = memoryFactsRepository;
    if (repo == null) {
      throw StateError('Memory is not available in this build.');
    }
    final content = (p['content'] as String?)?.trim() ?? '';
    if (content.isEmpty) {
      throw ArgumentError('content is required to remember something');
    }
    final capped = content.length > 200 ? content.substring(0, 200) : content;

    var kind = MemoryFactKind.semanticFact;
    final rawKind = p['kind'] as String?;
    if (rawKind != null) {
      final parsed = memoryFactKindFromStorage(rawKind);
      if (parsed != MemoryFactKind.episodicSummary) kind = parsed;
    }

    // Link to a known person when the fact names one — never create people
    // from this path (extraction owns quote-verified person creation).
    String? personId;
    final personName = (p['personName'] as String?)?.trim();
    if (personName != null && personName.isNotEmpty) {
      personId = (await peopleRepository?.findByReference(personName))?.id;
    }

    // Verify the model's paraphrase against the user's own words (fix-wave
    // Phase 6, §8 M2): the extraction pipeline demotes unverified claims to
    // aiInferred, but this chat path stored the paraphrase as userStated
    // truth at confidence 1.0 — a mishearing became a fact the system
    // prompt asserts plainly in every future conversation. Unsupported
    // content demotes so the Coach hedges, and the ack always ECHOES what
    // was stored so a wrong write is visible next to its Undo.
    final rawUtterance = (p['rawUtterance'] as String?)?.trim();
    final supported =
        rawUtterance != null && _utteranceSupports(capped, rawUtterance);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final fact = MemoryFact(
      id: (p['_factId'] as String?) ?? StableId.generate('memfact'),
      kind: kind,
      content: capped,
      personId: personId,
      provenance: supported
          ? MemoryProvenance.userStated
          : MemoryProvenance.aiInferred,
      confidence: supported ? 1.0 : 0.6,
      sourceQuote: rawUtterance,
      createdAtMs: nowMs,
      updatedAtMs: nowMs,
    );
    fact.validate();
    await repo.upsertFact(fact);
    ops.add({'op': 'deleteFact', 'factId': fact.id});
    return 'Noted — I\'ll remember: "$capped".';
  }

  /// True when every meaningful word of [content] is anchored in the
  /// user's [utterance] (shared 4-char prefix tolerates inflection:
  /// "prefers" ↔ "prefer"). Deterministic — a paraphrase that invents
  /// words the user never said fails.
  static bool _utteranceSupports(String content, String utterance) {
    final normalize = MemoryExtractionParser.normalizeForMatch;
    final utteranceTokens = normalize(utterance)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 4)
        .map((t) => t.substring(0, 4))
        .toSet();
    final contentTokens = normalize(content)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 4)
        .toList();
    if (contentTokens.isEmpty) return utteranceTokens.isNotEmpty;
    return contentTokens.every(
      (t) => utteranceTokens.contains(t.substring(0, 4)),
    );
  }

  /// Edit an existing fact. The user correcting the record is confirmation
  /// (provenance promotes to userConfirmed, PRD §5.3).
  Future<String> _updateFact(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
    final repo = memoryFactsRepository;
    if (repo == null) {
      throw StateError('Memory is not available in this build.');
    }
    final newContent = (p['newContent'] as String?)?.trim() ?? '';
    if (newContent.isEmpty) {
      throw ArgumentError('newContent is required to update a memory');
    }
    final targetId = p['_targetFactId'] as String?;
    var target = targetId != null ? await repo.getFact(targetId) : null;
    // Unstashed (ambiguous or unresolved at pre-pass): resolve here so an
    // ambiguity question reaches the user as this action's failure copy.
    target ??= await _resolveFactRef(p['factRef'] as String?);
    if (target == null) {
      throw ArgumentError(
        'I couldn\'t find that memory — check "What SidePal knows".',
      );
    }
    final capped = newContent.length > 200
        ? newContent.substring(0, 200)
        : newContent;
    ops.add({'op': 'restoreFact', 'fact': target.toMap()});
    await repo.upsertFact(
      target.copyWith(
        content: capped,
        provenance: MemoryProvenance.userConfirmed,
        confidence: 1.0,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    return 'Updated — "$capped".';
  }

  /// Forget a fact — soft tombstone (kept for LWW, gone from every surface).
  Future<String> _forgetFact(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
    final repo = memoryFactsRepository;
    if (repo == null) {
      throw StateError('Memory is not available in this build.');
    }
    final targetId = p['_targetFactId'] as String?;
    var target = targetId != null ? await repo.getFact(targetId) : null;
    target ??= await _resolveFactRef(p['factRef'] as String?);
    if (target == null) {
      throw ArgumentError(
        'I couldn\'t find that memory — check "What SidePal knows".',
      );
    }
    ops.add({'op': 'restoreFact', 'fact': target.toMap()});
    await repo.deleteFact(target.id);
    // Name the casualty (§8 E14): a bare "Forgotten." never revealed WHICH
    // memory a fuzzy match deleted.
    return 'Forgotten: "${target.content}".';
  }

  /// Resolves a model-provided fact reference to a live fact:
  /// a `[mem:<id>]` marker or bare id first (the payload hands the model
  /// exact ids — the most reliable ref), then exact normalized content,
  /// then containment. AMBIGUOUS containment throws a question naming the
  /// candidates (fix-wave Phase 6, §8 E14): "forget what I said about the
  /// gym" used to silently tombstone whichever gym-fact was newest.
  /// Null when nothing matches — the handler surfaces the failure.
  Future<MemoryFact?> _resolveFactRef(String? factRef) async {
    final repo = memoryFactsRepository;
    if (repo == null || factRef == null || factRef.trim().isEmpty) {
      return null;
    }
    final facts = await repo.fetchFactsOnce();

    final idMatch = RegExp(r'mem:([A-Za-z0-9_\-]+)').firstMatch(factRef);
    final refId = idMatch?.group(1) ?? factRef.trim();
    for (final f in facts) {
      if (f.id == refId) return f;
    }

    final needle = MemoryExtractionParser.normalizeForMatch(factRef);
    if (needle.isEmpty) return null;
    for (final f in facts) {
      if (MemoryExtractionParser.normalizeForMatch(f.content) == needle) {
        return f;
      }
    }
    final contained = [
      for (final f in facts)
        if (MemoryExtractionParser.normalizeForMatch(
              f.content,
            ).contains(needle) ||
            needle.contains(MemoryExtractionParser.normalizeForMatch(f.content)))
          f,
    ];
    if (contained.length > 1) {
      final listed = contained
          .take(3)
          .map((f) => '"${f.content}"')
          .join(' or ');
      throw ArgumentError(
        'I know a few memories like that — which one: $listed?',
      );
    }
    return contained.isEmpty ? null : contained.single;
  }

  // ─── Task handlers ────────────────────────────────────────────────────────

  Future<String> _createTask(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
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
    p['_resolvedTaskId'] = task.id;
    ops.add({
      'op': 'deleteTask',
      'taskId': task.id,
      'routineId': routineId,
      'blockId': blockId,
      'dateKey': dateStr,
      'title': title,
    });

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

  /// Loads the task row a resolver-stamped action targets. The resolver
  /// (AiEntityResolver, fix-wave Phase 1) matched the entity BEFORE the
  /// preview card; execution never guesses by title. Throws loudly when
  /// the stamp is missing (legacy plan, resolver disabled) or the row is
  /// gone (deleted between preview and confirm).
  Future<PlannedTaskRow> _requireResolvedTaskRow(
    Map<String, dynamic> p,
  ) async {
    final id = p['_resolvedTaskId'] as String?;
    final dateKey = p['_resolvedDateKey'] as String?;
    if (id == null || dateKey == null) {
      throw ArgumentError(
        "I couldn't match that task to your plan — ask me again with its "
        'name.',
      );
    }
    final rows = await collectTasksForDateKey(planningRepository, dateKey);
    for (final row in rows) {
      if (row.task.id == id) return row;
    }
    throw ArgumentError(
      'That task is no longer on ${_friendlyDate(dateKey)} — it may have '
      'been changed since I suggested this.',
    );
  }

  /// True edit (fix-wave Phase 1, §8 E2): updates the SAME task row —
  /// time, duration, and/or day — preserving id, status, notes, category,
  /// priority, order, and enforcement mode. The old handler upserted a
  /// brand-new task, duplicating the schedule.
  Future<String> _editTask(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
    final row = await _requireResolvedTaskRow(p);
    final task = row.task;
    ops.add({'op': 'restoreTask', 'row': _taskRowMap(task)});
    ops.add(await _reminderConfigsOp(task.id));
    final timeStr = p['time'] as String?;
    final durationMinutes = (p['duration'] as num?)?.toInt();
    final dateParam = p['date'] as String?;
    final newDateKey = dateParam != null && dateParam.trim().isNotEmpty
        ? _resolveDate(dateParam)
        : (task.planDateKey ?? row.dateKey);

    if (timeStr == null && durationMinutes == null &&
        newDateKey == (task.planDateKey ?? row.dateKey)) {
      throw ArgumentError(
        'Tell me what to change about "${task.title}" — its time, '
        'duration, or day.',
      );
    }

    var routineId = task.routineId;
    var blockId = task.blockId;
    if (newDateKey != (task.planDateKey ?? row.dateKey)) {
      final ids = await planningRepository.ensureDefaultDayPlan(newDateKey);
      routineId = ids.routineId;
      blockId = ids.blockId;
    }

    // New time wins; otherwise an existing reminder follows the (possibly
    // new) day at its old clock time.
    DateTime? reminderTime;
    if (timeStr != null) {
      reminderTime = _parseReminderDateTime(newDateKey, timeStr);
    } else if (task.reminderTimeIso != null) {
      final old = DateTime.tryParse(task.reminderTimeIso!)?.toLocal();
      if (old != null) {
        final day = DateKeys.parseLocalDateKey(newDateKey);
        reminderTime = DateTime(
          day.year, day.month, day.day, old.hour, old.minute,
        );
      }
    }

    final updated = PlannedTask(
      id: task.id,
      routineId: routineId,
      blockId: blockId,
      title: task.title,
      durationMinutes: durationMinutes ?? task.durationMinutes,
      priority: task.priority,
      orderIndex: task.orderIndex,
      reminderEnabled: reminderTime != null && task.reminderEnabled ||
          (timeStr != null),
      reminderTimeIso: reminderTime?.toIso8601String(),
      status: task.status,
      createdAtMs: task.createdAtMs,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      category: task.category,
      planDateKey: newDateKey,
      notes: task.notes,
      sequenceIndex: task.sequenceIndex,
      isHabitAnchor: task.isHabitAnchor,
      strictModeRequired: task.strictModeRequired,
      modeRefId: task.modeRefId,
    );
    await planningRepository.upsertTask(updated);

    if (updated.reminderEnabled && reminderTime != null) {
      await _upsertReminderForTask(
        taskId: task.id,
        taskTitle: task.title,
        routineId: routineId,
        blockId: blockId,
        reminderTime: reminderTime,
        modeRefId: task.modeRefId,
        existingCreatedAtMs: task.createdAtMs,
      );
      final block = timeBlockSyncService.deriveBlock(
        entityId: task.id,
        entityKind: 'task',
        startAt: reminderTime,
        durationMinutes: updated.durationMinutes,
        modeRefId: updated.modeRefId,
      );
      if (block != null) await timeBlockSyncService.syncBlock(block);
    } else {
      await reminderSyncService.syncForTaskIds([task.id]);
    }

    final changes = <String>[
      if (timeStr != null) 'time → $timeStr',
      if (durationMinutes != null) 'duration → $durationMinutes min',
      if (newDateKey != row.dateKey) 'day → ${_friendlyDate(newDateKey)}',
    ];
    return 'Updated "${task.title}" (${changes.join(', ')}).';
  }

  /// Real move (fix-wave Phase 1, §8 E1): same task id lands on the
  /// destination day; an existing reminder keeps its clock time on the new
  /// day; the derived time block follows.
  Future<String> _moveTask(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
    final destRaw = p['destinationDate'] as String?;
    if (destRaw == null || destRaw.trim().isEmpty) {
      throw ArgumentError('Where should I move it to — today, tomorrow, '
          'or a date?');
    }
    final row = await _requireResolvedTaskRow(p);
    final destKey = _resolveDate(destRaw);
    final sourceKey = row.task.planDateKey ?? row.dateKey;
    if (destKey == sourceKey) {
      return '"${row.task.title}" is already on ${_friendlyDate(destKey)}.';
    }
    return _editTask({
      ...p,
      'title': row.task.title,
      'date': destKey,
    }, ops).then((_) =>
        'Moved "${row.task.title}" to ${_friendlyDate(destKey)}.');
  }

  /// Real delete (fix-wave Phase 1, §8 E1): the 2026-08-23 deletion set —
  /// task row, reminder configs + armed OS notifications, derived time
  /// block. (Entity coaching caches self-heal on the next daily refresh —
  /// the clear helper is WidgetRef-bound and unreachable from here.)
  Future<String> _deleteTask(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
    final row = await _requireResolvedTaskRow(p);
    ops.add({'op': 'restoreTask', 'row': _taskRowMap(row.task)});
    ops.add(await _reminderConfigsOp(row.task.id));
    await planningRepository.deleteTask(
      routineId: row.routineId,
      blockId: row.blockId,
      taskId: row.task.id,
    );
    await reminderSyncService.removeForDeletedTask(row.task.id);
    await timeBlockSyncService.removeBlockForEntity(row.task.id);
    return 'Deleted "${row.task.title}".';
  }

  // ─── Goal handlers ────────────────────────────────────────────────────────

  Future<String> _createGoal(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
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

    // Honor the model's target when it carries a number: "20 km" →
    // targetValue 20, customLabel "km" (fix-wave Phase 1 — every AI goal
    // used to be hard-coded to count-of-1, so "run 20km a week" became a
    // count-of-1 goal regardless of what the user asked).
    final parsedTarget = target.isNotEmpty
        ? _parseLeadingNumber(target)
        : null;
    final targetLabel = parsedTarget != null
        ? target
              .replaceFirst(RegExp(r'\d+(?:\.\d+)?'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim()
        : target;

    // Repeat off: an AI-created goal with a deadline is a one-time outcome
    // goal — progress accumulates until the deadline.
    final goal = UserGoal(
      id: StableId.generate('goal'),
      title: title,
      categoryId: GoalCategories.productivity,
      status: GoalStatus.active,
      measurementKind: MeasurementKind.count,
      targetValue: parsedTarget != null && parsedTarget > 0
          ? parsedTarget
          : 1,
      customLabel: targetLabel.isNotEmpty ? targetLabel : null,
      intensity: 3,
      periodStartMs: now,
      periodEndMs: periodEnd,
      createdAtMs: now,
      updatedAtMs: now,
    );

    await goalsRepository.upsertGoal(goal);
    ops.add({'op': 'deleteGoal', 'goalId': goal.id});
    return 'Created goal "$title".';
  }

  /// Loads the goal a resolver-stamped action targets — same contract as
  /// [_requireResolvedTaskRow].
  Future<UserGoal> _requireResolvedGoal(Map<String, dynamic> p) async {
    final id = p['_resolvedGoalId'] as String?;
    if (id == null) {
      throw ArgumentError(
        "I couldn't match that goal — ask me again with its name.",
      );
    }
    final goals = await goalsRepository.fetchGoalsOnce();
    for (final g in goals) {
      if (g.id == id) return g;
    }
    throw ArgumentError('That goal no longer exists.');
  }

  /// Real goal edit (fix-wave Phase 1, §8 E1): title, target, deadline, or
  /// intensity on the SAME goal id. Anything else fails loudly instead of
  /// pretending.
  Future<String> _modifyGoal(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
    final goal = await _requireResolvedGoal(p);
    final field = (p['field'] as String? ?? '').trim().toLowerCase();
    final newValue = p['newValue'];
    if (field.isEmpty || newValue == null) {
      throw ArgumentError(
        'Tell me what to change about "${goal.title}" — its title, '
        'target, deadline, or intensity.',
      );
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    UserGoal updated;
    String describe;
    switch (field) {
      case 'title':
      case 'name':
        final title = newValue.toString().trim();
        if (title.isEmpty) throw ArgumentError('The new title is empty.');
        updated = goal.copyWith(title: title, updatedAtMs: now);
        describe = 'renamed to "$title"';
      case 'target':
      case 'targetvalue':
        final target = _parseLeadingNumber(newValue.toString());
        if (target == null || target <= 0) {
          throw ArgumentError(
            'I couldn\'t read "$newValue" as a target number.',
          );
        }
        updated = goal.copyWith(targetValue: target, updatedAtMs: now);
        describe = 'target → ${_trimNum(target)}';
      case 'deadline':
      case 'enddate':
        final key = _resolveDate(newValue.toString());
        updated = goal.copyWith(
          periodEndMs: DateKeys.parseLocalDateKey(key)
              .add(const Duration(hours: 23, minutes: 59))
              .millisecondsSinceEpoch,
          updatedAtMs: now,
        );
        describe = 'deadline → ${_friendlyDate(key)}';
      case 'intensity':
        final intensity = (num.tryParse(newValue.toString()))?.round();
        if (intensity == null || intensity < 1 || intensity > 5) {
          throw ArgumentError('Intensity is a number from 1 to 5.');
        }
        updated = goal.copyWith(intensity: intensity, updatedAtMs: now);
        describe = 'intensity → $intensity';
      default:
        throw ArgumentError(
          'I can change a goal\'s title, target, deadline, or intensity — '
          'not "$field".',
        );
    }
    ops.add({'op': 'restoreGoal', 'goal': goal.toMap()});
    await goalsRepository.upsertGoal(updated);
    return 'Updated goal "${goal.title}" ($describe).';
  }

  /// Real goal delete (fix-wave Phase 1, §8 E1). The pre-mutation state is
  /// stashed as `_prevGoalJson` in [execute] so rollback/undo can restore
  /// the goal itself (check-in history is deleted by the repository and is
  /// NOT restored — the Phase 2 inverse-op log will cover it).
  Future<String> _deleteGoal(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
    final goal = await _requireResolvedGoal(p);
    ops.add({'op': 'restoreGoal', 'goal': goal.toMap()});
    await goalsRepository.deleteGoal(goal.id);
    return 'Removed goal "${goal.title}".';
  }

  static double? _parseLeadingNumber(String raw) {
    final m = RegExp(r'\d+(?:\.\d+)?').firstMatch(raw);
    return m == null ? null : double.tryParse(m.group(0)!);
  }

  static String _trimNum(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  // ─── Reminder handlers ────────────────────────────────────────────────────

  /// Adds or updates a reminder. If no matching task exists for [dateStr], creates
  /// a new task first (AI often returns addReminder instead of createTask).
  Future<String> _addReminder(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
    final taskTitle = (p['taskTitle'] as String?)?.trim().isNotEmpty == true
        ? (p['taskTitle'] as String).trim()
        : (p['title'] as String?)?.trim().isNotEmpty == true
        ? (p['title'] as String).trim()
        : 'Reminder';
    final dateStr = _resolveDate(p['date'] as String?);
    final timeStr = p['reminderTime'] as String? ?? p['time'] as String?;

    final existing = await _findTaskRowByTitle(taskTitle, dateStr);
    if (existing != null) {
      ops.add({'op': 'restoreTask', 'row': _taskRowMap(existing.task)});
      ops.add(await _reminderConfigsOp(existing.task.id));
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
    }, ops);
  }

  /// Real reminder removal (fix-wave Phase 1, §8 E1): cancels the armed OS
  /// notification, deletes the ReminderConfig (the load-bearing half —
  /// boot reconciliation re-arms from surviving configs), clears the
  /// task row's reminder fields, and removes the derived time block.
  Future<String> _removeReminder(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
    final row = await _requireResolvedTaskRow(p);
    final task = row.task;
    ops.add({'op': 'restoreTask', 'row': _taskRowMap(task)});
    ops.add(await _reminderConfigsOp(task.id));
    await reminderSyncService.removeForDeletedTask(task.id);
    if (task.reminderEnabled || task.reminderTimeIso != null) {
      await planningRepository.upsertTask(
        PlannedTask(
          id: task.id,
          routineId: task.routineId,
          blockId: task.blockId,
          title: task.title,
          durationMinutes: task.durationMinutes,
          priority: task.priority,
          orderIndex: task.orderIndex,
          reminderEnabled: false,
          reminderTimeIso: null,
          status: task.status,
          createdAtMs: task.createdAtMs,
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          category: task.category,
          planDateKey: task.planDateKey ?? row.dateKey,
          notes: task.notes,
          sequenceIndex: task.sequenceIndex,
          isHabitAnchor: task.isHabitAnchor,
          strictModeRequired: task.strictModeRequired,
          modeRefId: task.modeRefId,
        ),
      );
    }
    await timeBlockSyncService.removeBlockForEntity(task.id);
    return 'Removed the reminder for "${task.title}".';
  }

  Future<String> _rescheduleReminder(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> ops,
  ) async {
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
      }, ops);
    }

    ops.add({'op': 'restoreTask', 'row': _taskRowMap(existing.task)});
    ops.add(await _reminderConfigsOp(existing.task.id));
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
    // The normaliser canonicalises dates at ingestion; anything else must
    // be a valid YYYY-MM-DD key. An unparseable value used to flow into
    // planDateKey verbatim — a task on a day no screen queries, invisible
    // everywhere, while its reminder fired today (§8 E9). Fail loudly as a
    // per-action failure instead of writing to a phantom day.
    try {
      DateKeys.parseLocalDateKey(raw);
    } catch (_) {
      throw ArgumentError('Unrecognized date "$raw"');
    }
    return raw;
  }

  // Full humanizer since 2026-08-25 — weekday names for the coming week,
  // "Mon, Sep 1" beyond, never a raw date key.
  String _friendlyDate(String dateKey) => friendlyDateKey(dateKey);

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
