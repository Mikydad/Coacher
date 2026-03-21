import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_client.dart';
import '../../../core/firebase/firestore_paths.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/domain/models/block.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/domain/models/task_item.dart';

abstract class PlanningRepository {
  /// [getOptions] e.g. [GetOptions(source: Source.server)] avoids stale offline cache.
  Future<List<Routine>> getRoutinesForDate(
    String dateKey, {
    GetOptions? getOptions,
  });
  Future<void> upsertRoutine(Routine routine);
  Future<void> deleteRoutine(String routineId);

  Future<List<TaskBlock>> getBlocks(String routineId, {GetOptions? getOptions});
  Future<void> upsertBlock(TaskBlock block);
  Future<void> deleteBlock({
    required String routineId,
    required String blockId,
  });

  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
    GetOptions? getOptions,
  });
  Future<void> upsertTask(PlannedTask task);
  Future<void> deleteTask({
    required String routineId,
    required String blockId,
    required String taskId,
  });

  /// Ensures a [Routine] for [dateKey] and a default [TaskBlock] exist; returns their ids.
  Future<({String routineId, String blockId})> ensureDefaultDayPlan(
    String dateKey, {
    GetOptions? getOptions,
  });
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
  Future<void> deleteTask({
    required String routineId,
    required String blockId,
    required String taskId,
  }) async {
    final path = FirestorePaths.tasks(routineId, blockId);
    await _deleteWithQueue(entityType: 'task', path: '$path/$taskId');
  }

  @override
  Future<List<TaskBlock>> getBlocks(
    String routineId, {
    GetOptions? getOptions,
  }) async {
    final path = FirestorePaths.blocks(routineId);
    final q = FirebaseFirestore.instance.collection(path).orderBy('orderIndex');
    final snap = getOptions != null ? await q.get(getOptions) : await q.get();
    return snap.docs.map((d) => TaskBlock.fromMap(d.data())).toList();
  }

  @override
  Future<List<Routine>> getRoutinesForDate(
    String dateKey, {
    GetOptions? getOptions,
  }) async {
    final routines = _client.userCollection('routines');
    // Single-field filter only — avoids composite index (dateKey + orderIndex).
    final q = routines.where('dateKey', isEqualTo: dateKey);
    final snap = getOptions != null ? await q.get(getOptions) : await q.get();
    final list = snap.docs.map((d) => Routine.fromMap(d.data())).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
    GetOptions? getOptions,
  }) async {
    final path = FirestorePaths.tasks(routineId, blockId);
    final q = FirebaseFirestore.instance.collection(path).orderBy('orderIndex');
    final snap = getOptions != null ? await q.get(getOptions) : await q.get();
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
  Future<({String routineId, String blockId})> ensureDefaultDayPlan(
    String dateKey, {
    GetOptions? getOptions,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final routines = await getRoutinesForDate(dateKey, getOptions: getOptions);
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

    final blocks = await getBlocks(routineId, getOptions: getOptions);
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
