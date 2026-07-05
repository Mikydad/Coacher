import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/models/timer_session.dart';

abstract class ExecutionRepository {
  Future<List<TimerSession>> getSessionsForTask(String taskId);
  Future<List<TimerSession>> getSessionsForBlock(String blockId);
  Future<void> upsertSession(TimerSession session);
}

class FirestoreExecutionRepository implements ExecutionRepository {
  // NOTE: no `.orderBy('startedAtMs')` on these queries — combining it with
  // the equality filters requires a Firestore composite index (deploy-time
  // config that silently breaks task completion when missing). Sessions per
  // task/block are few, so we sort client-side instead.

  @override
  Future<List<TimerSession>> getSessionsForTask(String taskId) async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestorePaths.timerSessions)
        .where('targetType', isEqualTo: TimerSessionTargetType.task.storageValue)
        .where('taskId', isEqualTo: taskId)
        .get();
    final sessions =
        snap.docs.map((d) => TimerSession.fromMap(d.data())).toList()
          ..sort((a, b) => a.startedAtMs.compareTo(b.startedAtMs));
    return sessions;
  }

  @override
  Future<List<TimerSession>> getSessionsForBlock(String blockId) async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestorePaths.timerSessions)
        .where('targetType', isEqualTo: TimerSessionTargetType.block.storageValue)
        .where('blockId', isEqualTo: blockId)
        .get();
    final sessions =
        snap.docs.map((d) => TimerSession.fromMap(d.data())).toList()
          ..sort((a, b) => a.startedAtMs.compareTo(b.startedAtMs));
    return sessions;
  }

  @override
  Future<void> upsertSession(TimerSession session) async {
    session.validate();
    final path = '${FirestorePaths.timerSessions}/${session.id}';
    final payload = session.toMap();
    try {
      await FirebaseFirestore.instance.doc(path).set(payload, SetOptions(merge: true));
    } catch (_) {
      await SyncService.instance.enqueueUpsert(
        entityType: 'timerSession',
        documentPath: path,
        payload: payload,
      );
    }
  }
}
