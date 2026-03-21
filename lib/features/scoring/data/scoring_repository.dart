import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/models/task_score.dart';

abstract class ScoringRepository {
  Future<TaskScore?> getScoreForTask(String taskId);
  Future<void> upsertScore(TaskScore score);
}

class FirestoreScoringRepository implements ScoringRepository {
  @override
  Future<TaskScore?> getScoreForTask(String taskId) async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestorePaths.taskScores)
        .where('taskId', isEqualTo: taskId)
        .orderBy('updatedAtMs', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return TaskScore.fromMap(snap.docs.first.data());
  }

  @override
  Future<void> upsertScore(TaskScore score) async {
    score.validate();
    final path = '${FirestorePaths.taskScores}/${score.id}';
    final payload = score.toMap();
    try {
      await FirebaseFirestore.instance.doc(path).set(payload, SetOptions(merge: true));
    } catch (_) {
      await SyncService.instance.enqueueUpsert(
        entityType: 'taskScore',
        documentPath: path,
        payload: payload,
      );
    }
  }
}
