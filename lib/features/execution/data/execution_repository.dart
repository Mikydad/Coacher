import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/models/timer_session.dart';

abstract class ExecutionRepository {
  Future<List<TimerSession>> getSessionsForTask(String taskId);
  Future<void> upsertSession(TimerSession session);
}

class FirestoreExecutionRepository implements ExecutionRepository {
  @override
  Future<List<TimerSession>> getSessionsForTask(String taskId) async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestorePaths.timerSessions)
        .where('taskId', isEqualTo: taskId)
        .orderBy('startedAtMs')
        .get();
    return snap.docs.map((d) => TimerSession.fromMap(d.data())).toList();
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
