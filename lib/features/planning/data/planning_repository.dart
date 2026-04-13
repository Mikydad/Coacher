import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_client.dart';
import '../../../core/firebase/firestore_paths.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/stable_id.dart';
import '../application/accountability_log_codec.dart';
import '../../planning/domain/models/accountability_log.dart';
import '../../planning/domain/models/block.dart';
import '../../planning/domain/models/flow_transition_event.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/domain/models/routine_mode.dart';
import '../../planning/domain/models/task_item.dart';

abstract class PlanningRepository {
  Future<List<Routine>> getRoutinesForDate(String dateKey);
  Future<void> upsertRoutine(Routine routine);
  Future<void> deleteRoutine(String routineId);
  Future<List<RoutineModeConfig>> getRoutineModeConfigs({GetOptions? getOptions});
  Future<void> upsertRoutineModeConfig(RoutineModeConfig config);

  Future<List<TaskBlock>> getBlocks(String routineId);
  Future<void> upsertBlock(TaskBlock block);
  Future<void> deleteBlock({
    required String routineId,
    required String blockId,
  });

  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  });
  Future<void> upsertTask(PlannedTask task);
  Future<void> deleteTask({
    required String routineId,
    required String blockId,
    required String taskId,
  });
  Future<void> logFlowTransitionEvent(FlowTransitionEvent event);
  Future<void> logAccountability(AccountabilityLog log);
  Future<List<AccountabilityLog>> getAccountabilityLogs({
    int? fromCreatedAtMs,
    int? toCreatedAtMs,
    String? modeRefId,
    OverrideReasonCategory? reasonCategory,
  });
  Future<void> deleteAccountabilityLog(String id);
  Future<void> deleteAccountabilityLogsInRange({
    required int fromCreatedAtMs,
    required int toCreatedAtMs,
  });
  Future<int> pruneOldAccountabilityLogs({int retentionDays = 30, int? nowMs});
  Future<String> exportAccountabilityLogs({String format = 'json'});

  /// Ensures a [Routine] for [dateKey] and a default [TaskBlock] exist; returns their ids.
  Future<({String routineId, String blockId})> ensureDefaultDayPlan(String dateKey);
}

class FirestorePlanningRepository implements PlanningRepository {
  FirestorePlanningRepository(this._client);

  final FirestoreClient _client;

  Future<void> _upsertWithQueue({
    required String entityType,
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await FirebaseFirestore.instance
          .doc(path)
          .set(payload, SetOptions(merge: true));
    } catch (_) {
      await SyncService.instance.enqueueUpsert(
        entityType: entityType,
        documentPath: path,
        payload: payload,
      );
    }
  }

  Future<void> _deleteWithQueue({
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
  Future<void> deleteBlock({
    required String routineId,
    required String blockId,
  }) async {
    final path = FirestorePaths.blocks(routineId);
    await _deleteWithQueue(entityType: 'block', path: '$path/$blockId');
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    await _deleteWithQueue(
      entityType: 'routine',
      path: '${FirestorePaths.routines}/$routineId',
    );
  }

  @override
  Future<List<RoutineModeConfig>> getRoutineModeConfigs({
    GetOptions? getOptions,
  }) async {
    final q = FirebaseFirestore.instance
        .collection(FirestorePaths.routineModes)
        .orderBy('label');
    final snap = getOptions != null ? await q.get(getOptions) : await q.get();
    final configs = snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = data['id'] ?? d.id;
      return RoutineModeConfig.fromMap(data);
    }).toList();
    if (configs.isNotEmpty) return configs;
    return RoutineModeConfig.defaults();
  }

  @override
  Future<void> deleteTask({
    required String routineId,
    required String blockId,
    required String taskId,
  }) async {
    final path = FirestorePaths.tasks(routineId, blockId);
    await _deleteWithQueue(entityType: 'task', path: '$path/$taskId');
  }

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async {
    final path = FirestorePaths.blocks(routineId);
    final q = FirebaseFirestore.instance.collection(path).orderBy('orderIndex');
    final snap = await q.get();
    return snap.docs.map((d) => TaskBlock.fromMap(d.data())).toList();
  }

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async {
    final routines = _client.userCollection('routines');
    // Single-field filter only — avoids composite index (dateKey + orderIndex).
    final q = routines.where('dateKey', isEqualTo: dateKey);
    final snap = await q.get();
    final list = snap.docs.map((d) => Routine.fromMap(d.data())).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async {
    final path = FirestorePaths.tasks(routineId, blockId);
    final q = FirebaseFirestore.instance.collection(path).orderBy('orderIndex');
    final snap = await q.get();
    return snap.docs.map((d) => PlannedTask.fromMap(d.data())).toList();
  }

  @override
  Future<void> upsertBlock(TaskBlock block) async {
    block.validate();
    final path = FirestorePaths.blocks(block.routineId);
    final id = block.id.isEmpty ? StableId.generate('block') : block.id;
    final payload = {
      ...block.toMap(),
      'id': id,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    };
    await _upsertWithQueue(
      entityType: 'block',
      path: '$path/$id',
      payload: payload,
    );
  }

  @override
  Future<void> upsertRoutine(Routine routine) async {
    routine.validate();
    final id = routine.id.isEmpty ? StableId.generate('routine') : routine.id;
    final payload = {
      ...routine.toMap(),
      'id': id,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    };
    await _upsertWithQueue(
      entityType: 'routine',
      path: '${FirestorePaths.routines}/$id',
      payload: payload,
    );
  }

  @override
  Future<void> upsertRoutineModeConfig(RoutineModeConfig config) async {
    final id = config.id.isEmpty ? StableId.generate('mode') : config.id;
    final payload = {
      ...config.toMap(),
      'id': id,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    };
    await _upsertWithQueue(
      entityType: 'routineMode',
      path: '${FirestorePaths.routineModes}/$id',
      payload: payload,
    );
  }

  @override
  Future<void> upsertTask(PlannedTask task) async {
    task.validate();
    final path = FirestorePaths.tasks(task.routineId, task.blockId);
    final id = task.id.isEmpty ? StableId.generate('task') : task.id;
    final payload = {
      ...task.toMap(),
      'id': id,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    };
    await _upsertWithQueue(
      entityType: 'task',
      path: '$path/$id',
      payload: payload,
    );
  }

  @override
  Future<void> logFlowTransitionEvent(FlowTransitionEvent event) async {
    event.validate();
    final id = event.id.isEmpty ? StableId.generate('flowev') : event.id;
    final payload = {
      ...event.toMap(),
      'id': id,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    };
    await _upsertWithQueue(
      entityType: 'flowTransition',
      path: '${FirestorePaths.flowTransitionEvents}/$id',
      payload: payload,
    );
  }

  @override
  Future<void> logAccountability(AccountabilityLog log) async {
    log.validate();
    final id = log.id.isEmpty ? StableId.generate('acct') : log.id;
    final payload = {
      ...log.toMap(),
      'id': id,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    };
    await _upsertWithQueue(
      entityType: 'accountabilityLog',
      path: '${FirestorePaths.accountabilityLogs}/$id',
      payload: payload,
    );
  }

  @override
  Future<List<AccountabilityLog>> getAccountabilityLogs({
    int? fromCreatedAtMs,
    int? toCreatedAtMs,
    String? modeRefId,
    OverrideReasonCategory? reasonCategory,
  }) async {
    final q = FirebaseFirestore.instance
        .collection(FirestorePaths.accountabilityLogs)
        .orderBy('createdAtMs', descending: true);
    final snap = await q.get();
    final logs = snap.docs
        .map((d) => AccountabilityLog.fromMap(Map<String, dynamic>.from(d.data())))
        .where((l) {
          if (fromCreatedAtMs != null && l.createdAtMs < fromCreatedAtMs) return false;
          if (toCreatedAtMs != null && l.createdAtMs > toCreatedAtMs) return false;
          if (modeRefId != null && modeRefId.trim().isNotEmpty && l.modeRefId != modeRefId) {
            return false;
          }
          if (reasonCategory != null && l.reasonCategory != reasonCategory) return false;
          return true;
        })
        .toList();
    return logs;
  }

  @override
  Future<void> deleteAccountabilityLog(String id) async {
    if (id.trim().isEmpty) return;
    await _deleteWithQueue(
      entityType: 'accountabilityLog',
      path: '${FirestorePaths.accountabilityLogs}/$id',
    );
  }

  @override
  Future<void> deleteAccountabilityLogsInRange({
    required int fromCreatedAtMs,
    required int toCreatedAtMs,
  }) async {
    final logs = await getAccountabilityLogs(
      fromCreatedAtMs: fromCreatedAtMs,
      toCreatedAtMs: toCreatedAtMs,
    );
    for (final l in logs) {
      await deleteAccountabilityLog(l.id);
    }
  }

  @override
  Future<int> pruneOldAccountabilityLogs({int retentionDays = 30, int? nowMs}) async {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final cutOff = now - Duration(days: retentionDays).inMilliseconds;
    final oldLogs = await getAccountabilityLogs(toCreatedAtMs: cutOff);
    for (final l in oldLogs) {
      await deleteAccountabilityLog(l.id);
    }
    return oldLogs.length;
  }

  @override
  Future<String> exportAccountabilityLogs({String format = 'json'}) async {
    final logs = await getAccountabilityLogs();
    if (format.toLowerCase() == 'csv') {
      return AccountabilityLogCodec.toCsv(logs);
    }
    return AccountabilityLogCodec.toJson(logs);
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
