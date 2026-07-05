import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/models/weekly_commitment.dart';

abstract class WeeklyCommitmentRepository {
  /// Live stream of all commitments in a circle for the given week.
  /// Defaults to the current ISO week if [weekKey] is null.
  Stream<List<WeeklyCommitment>> watchCommitments(
    String circleId, {
    String? weekKey,
  });

  /// Replaces the current user's commitments for the given week.
  Future<void> setCommitments({
    required String circleId,
    required String userId,
    required String weekKey,
    required List<WeeklyCommitment> commitments,
  });

  /// Increments [completedCount] by 1, capped at [targetCount].
  Future<void> markProgress(String circleId, String commitmentId);
}

class FirestoreWeeklyCommitmentRepository
    implements WeeklyCommitmentRepository {
  FirestoreWeeklyCommitmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String circleId) =>
      _firestore
          .collection(FirestorePaths.circleWeeklyCommitments(circleId));

  static WeeklyCommitment _fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return WeeklyCommitment.fromMap(data);
  }

  @override
  Stream<List<WeeklyCommitment>> watchCommitments(
    String circleId, {
    String? weekKey,
  }) {
    final key = weekKey ?? DateKeys.isoWeekKey(DateTime.now());
    // No `.orderBy` on top of the equality filter — that combination needs a
    // Firestore composite index (deploy-time config that silently breaks the
    // whole commitments tab when missing). Sort client-side instead; a
    // circle's commitments for one week are a handful of rows.
    return _col(circleId)
        .where('weekKey', isEqualTo: key)
        .snapshots()
        .map((s) {
      final list = s.docs.map(_fromDoc).toList()
        ..sort((a, b) => a.updatedAtMs.compareTo(b.updatedAtMs));
      return list;
    });
  }

  @override
  Future<void> setCommitments({
    required String circleId,
    required String userId,
    required String weekKey,
    required List<WeeklyCommitment> commitments,
  }) async {
    final batch = _firestore.batch();

    // Delete existing commitments for this user+week first.
    final existing = await _col(circleId)
        .where('userId', isEqualTo: userId)
        .where('weekKey', isEqualTo: weekKey)
        .get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    // Write new ones.
    for (final c in commitments) {
      c.validate();
      batch.set(_col(circleId).doc(c.id), c.toMap());
    }

    await batch.commit();
  }

  @override
  Future<void> markProgress(String circleId, String commitmentId) async {
    await _firestore.runTransaction((tx) async {
      final ref = _col(circleId).doc(commitmentId);
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) return;

      final commitment = _fromDoc(snap);
      if (commitment.completedCount >= commitment.targetCount) return;

      tx.update(ref, {
        'completedCount': commitment.completedCount + 1,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }
}
