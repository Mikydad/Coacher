import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_block.dart';
import '../../../core/local_db/isar_collections/isar_routine.dart';
import '../../../core/local_db/isar_collections/isar_task.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/stable_id.dart';
import '../domain/models/accountability_log.dart';
import '../domain/models/block.dart';
import '../domain/models/flow_transition_event.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_mode.dart';
import '../domain/models/task_item.dart';
import 'planning_repository.dart';

/// Local-first planning: reads/writes [Routine], [TaskBlock], [PlannedTask] via Isar,
/// then enqueues Firestore sync. Firestore-only APIs delegate to [_remote].
class IsarPlanningRepository implements PlanningRepository {
  IsarPlanningRepository(this._remote);

  final PlanningRepository _remote;

  Isar get _isar => OfflineStore.instance.isar!;

  Future<void> _enqueueUpsert({
    required String entityType,
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await FirebaseFirestore.instance.doc(path).set(payload, SetOptions(merge: true));
    } catch (_) {
      await SyncService.instance.enqueueUpsert(
        entityType: entityType,
        documentPath: path,
        payload: payload,
      );
    }
  }

  Future<void> _enqueueDelete({
    required String entityType,
    required String path,
  }) async {
    try {
      await FirebaseFirestore.instance.doc(path).delete();
    } catch (_) {
      await SyncService.instance.enqueueDelete(
        entityType: entityType,
        documentPath: path,
      );
    }
  }

  @override
  Future<List<RoutineModeConfig>> getRoutineModeConfigs({GetOptions? getOptions}) {
    return _remote.getRoutineModeConfigs(getOptions: getOptions);
  }

  @override
  Future<void> upsertRoutineModeConfig(RoutineModeConfig config) {
    return _remote.upsertRoutineModeConfig(config);
  }

  @override
  Future<void> logFlowTransitionEvent(FlowTransitionEvent event) {
    return _remote.logFlowTransitionEvent(event);
  }

  @override
  Future<void> logAccountability(AccountabilityLog log) {
    return _remote.logAccountability(log);
  }

  @override
  Future<List<AccountabilityLog>> getAccountabilityLogs({
    int? fromCreatedAtMs,
    int? toCreatedAtMs,
    String? modeRefId,
    OverrideReasonCategory? reasonCategory,
  }) {
    return _remote.getAccountabilityLogs(
      fromCreatedAtMs: fromCreatedAtMs,
      toCreatedAtMs: toCreatedAtMs,
      modeRefId: modeRefId,
      reasonCategory: reasonCategory,
    );
  }

  @override
  Future<void> deleteAccountabilityLog(String id) {
    return _remote.deleteAccountabilityLog(id);
  }

  @override
  Future<void> deleteAccountabilityLogsInRange({
    required int fromCreatedAtMs,
    required int toCreatedAtMs,
  }) {
    return _remote.deleteAccountabilityLogsInRange(
      fromCreatedAtMs: fromCreatedAtMs,
      toCreatedAtMs: toCreatedAtMs,
    );
  }

  @override
  Future<int> pruneOldAccountabilityLogs({int retentionDays = 30, int? nowMs}) {
    return _remote.pruneOldAccountabilityLogs(retentionDays: retentionDays, nowMs: nowMs);
  }

  @override
  Future<String> exportAccountabilityLogs({String format = 'json'}) {
    return _remote.exportAccountabilityLogs(format: format);
  }

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async {
    final rows = await _isar.isarRoutines.filter().dateKeyEqualTo(dateKey).findAll();
    final list = rows.map((e) => e.toDomain()).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async {
    final rows = await _isar.isarBlocks.filter().routineIdEqualTo(routineId).findAll();
    final list = rows.map((e) => e.toDomain()).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async {
    final rows = await _isar.isarTasks
        .filter()
        .routineIdEqualTo(routineId)
        .blockIdEqualTo(blockId)
        .findAll();
    final list = rows.map((e) => e.toDomain()).toList()
      ..sort((a, b) {
        final c = a.orderIndex.compareTo(b.orderIndex);
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });
    return list;
  }

  @override
  Future<void> upsertRoutine(Routine routine) async {
    routine.validate();
    final id = routine.id.isEmpty ? StableId.generate('routine') : routine.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final stored = Routine(
      id: id,
      title: routine.title,
      dateKey: routine.dateKey,
      orderIndex: routine.orderIndex,
      modeId: routine.modeId,
      mode: routine.mode,
      createdAtMs: routine.createdAtMs,
      updatedAtMs: now,
    );
    await _isar.writeTxn(() async {
      await _isar.isarRoutines.putByRoutineId(IsarRoutine.fromDomain(stored));
    });
    final payload = {
      ...stored.toMap(),
      'id': id,
      'updatedAtMs': now,
    };
    await _enqueueUpsert(
      entityType: 'routine',
      path: '${FirestorePaths.routines}/$id',
      payload: payload,
    );
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    await _isar.writeTxn(() async {
      final tasks = await _isar.isarTasks.filter().routineIdEqualTo(routineId).findAll();
      for (final t in tasks) {
        await _isar.isarTasks.delete(t.id);
      }
      final blocks = await _isar.isarBlocks.filter().routineIdEqualTo(routineId).findAll();
      for (final b in blocks) {
        await _isar.isarBlocks.delete(b.id);
      }
      await _isar.isarRoutines.deleteByRoutineId(routineId);
    });
    await _enqueueDelete(
      entityType: 'routine',
      path: '${FirestorePaths.routines}/$routineId',
    );
  }

  @override
  Future<void> upsertBlock(TaskBlock block) async {
    block.validate();
    final id = block.id.isEmpty ? StableId.generate('block') : block.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final stored = TaskBlock(
      id: id,
      routineId: block.routineId,
      title: block.title,
      orderIndex: block.orderIndex,
      startMinutesFromMidnight: block.startMinutesFromMidnight,
      endMinutesFromMidnight: block.endMinutesFromMidnight,
      urgencyScore: block.urgencyScore,
      modeRefId: block.modeRefId,
      createdAtMs: block.createdAtMs,
      updatedAtMs: now,
    );
    await _isar.writeTxn(() async {
      await _isar.isarBlocks.putByBlockId(IsarBlock.fromDomain(stored));
    });
    final path = FirestorePaths.blocks(stored.routineId);
    final payload = {
      ...stored.toMap(),
      'id': id,
      'updatedAtMs': now,
    };
    await _enqueueUpsert(
      entityType: 'block',
      path: '$path/$id',
      payload: payload,
    );
  }

  @override
  Future<void> deleteBlock({
    required String routineId,
    required String blockId,
  }) async {
    await _isar.writeTxn(() async {
      final tasks = await _isar.isarTasks
          .filter()
          .routineIdEqualTo(routineId)
          .blockIdEqualTo(blockId)
          .findAll();
      for (final t in tasks) {
        await _isar.isarTasks.delete(t.id);
      }
      await _isar.isarBlocks.deleteByBlockId(blockId);
    });
    final path = FirestorePaths.blocks(routineId);
    await _enqueueDelete(entityType: 'block', path: '$path/$blockId');
  }

  @override
  Future<void> upsertTask(PlannedTask task) async {
    task.validate();
    final id = task.id.isEmpty ? StableId.generate('task') : task.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final stored = PlannedTask(
      id: id,
      routineId: task.routineId,
      blockId: task.blockId,
      title: task.title,
      durationMinutes: task.durationMinutes,
      priority: task.priority,
      orderIndex: task.orderIndex,
      reminderEnabled: task.reminderEnabled,
      reminderTimeIso: task.reminderTimeIso,
      status: task.status,
      createdAtMs: task.createdAtMs,
      updatedAtMs: now,
      category: task.category,
      planDateKey: task.planDateKey,
      notes: task.notes,
      sequenceIndex: task.sequenceIndex,
      strictModeRequired: task.strictModeRequired,
      modeRefId: task.modeRefId,
    );
    await _isar.writeTxn(() async {
      await _isar.isarTasks.putByTaskId(IsarTask.fromDomain(stored));
    });
    final path = FirestorePaths.tasks(stored.routineId, stored.blockId);
    final payload = {
      ...stored.toMap(),
      'id': id,
      'updatedAtMs': now,
    };
    await _enqueueUpsert(
      entityType: 'task',
      path: '$path/$id',
      payload: payload,
    );
  }

  @override
  Future<void> deleteTask({
    required String routineId,
    required String blockId,
    required String taskId,
  }) async {
    await _isar.writeTxn(() async {
      await _isar.isarTasks.deleteByTaskId(taskId);
    });
    final path = FirestorePaths.tasks(routineId, blockId);
    await _enqueueDelete(entityType: 'task', path: '$path/$taskId');
  }

  @override
  Future<({String routineId, String blockId})> ensureDefaultDayPlan(String dateKey) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final routines = await getRoutinesForDate(dateKey);
    late final String routineId;
    if (routines.isEmpty) {
      routineId = StableId.generate('routine');
      await upsertRoutine(
        Routine(
          id: routineId,
          title: 'Daily plan',
          dateKey: dateKey,
          orderIndex: 0,
          createdAtMs: now,
          updatedAtMs: now,
        ),
      );
    } else {
      routineId = routines.first.id;
    }

    final blocks = await getBlocks(routineId);
    late final String blockId;
    if (blocks.isEmpty) {
      blockId = StableId.generate('block');
      await upsertBlock(
        TaskBlock(
          id: blockId,
          routineId: routineId,
          title: 'Main',
          orderIndex: 0,
          createdAtMs: now,
          updatedAtMs: now,
        ),
      );
    } else {
      blockId = blocks.first.id;
    }

    return (routineId: routineId, blockId: blockId);
  }
}
