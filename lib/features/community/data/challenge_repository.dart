import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/models/challenge.dart';
import '../domain/models/challenge_vote.dart';

abstract class ChallengeRepository {
  Stream<List<Challenge>> watchChallenges(String circleId);
  Future<Challenge?> getChallenge(String circleId, String challengeId);
  Future<void> createChallenge(Challenge challenge);
  Future<void> updateChallenge(Challenge challenge);

  /// Safely increments `memberProgress[userId]` by [delta] and
  /// recalculates `teamTotal`.
  Future<void> updateProgress({
    required String circleId,
    required String challengeId,
    required String userId,
    required int delta,
  });

  /// Cast an approve/reject vote. Checks majority and flips status if reached.
  Future<void> vote({
    required String challengeId,
    required String circleId,
    required String userId,
    required bool approve,
    required int memberCount,
  });

  Future<List<ChallengeVote>> getVotes(String circleId, String challengeId);
}

class FirestoreChallengeRepository implements ChallengeRepository {
  FirestoreChallengeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _challenges(String circleId) =>
      _firestore.collection(FirestorePaths.circleChallenges(circleId));

  DocumentReference<Map<String, dynamic>> _challengeDoc(
    String circleId,
    String challengeId,
  ) => _firestore.doc(FirestorePaths.challengeDoc(circleId, challengeId));

  CollectionReference<Map<String, dynamic>> _votes(
    String circleId,
    String challengeId,
  ) => _firestore.collection(
    FirestorePaths.challengeVotes(circleId, challengeId),
  );

  static Challenge _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return Challenge.fromMap(data);
  }

  static ChallengeVote _voteFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    return ChallengeVote.fromMap(data);
  }

  @override
  Stream<List<Challenge>> watchChallenges(String circleId) {
    return _challenges(circleId)
        .orderBy('createdAtMs', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<Challenge?> getChallenge(String circleId, String challengeId) async {
    final doc = await _challengeDoc(circleId, challengeId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDoc(doc);
  }

  @override
  Future<void> createChallenge(Challenge challenge) async {
    challenge.validate();
    await _challenges(
      challenge.circleId,
    ).doc(challenge.id).set(challenge.toMap());
  }

  @override
  Future<void> updateChallenge(Challenge challenge) async {
    challenge.validate();
    await _challengeDoc(
      challenge.circleId,
      challenge.id,
    ).set(challenge.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateProgress({
    required String circleId,
    required String challengeId,
    required String userId,
    required int delta,
  }) async {
    await _firestore.runTransaction((tx) async {
      final ref = _challengeDoc(circleId, challengeId);
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) return;

      final challenge = _fromDoc(snap);
      final updatedProgress = Map<String, int>.from(challenge.memberProgress);
      updatedProgress[userId] = (updatedProgress[userId] ?? 0) + delta;

      final newTeamTotal = updatedProgress.values.fold(0, (sum, v) => sum + v);

      tx.update(ref, {
        'memberProgress': updatedProgress,
        'teamTotal': newTeamTotal,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  @override
  Future<void> vote({
    required String challengeId,
    required String circleId,
    required String userId,
    required bool approve,
    required int memberCount,
  }) async {
    final voteRef = _votes(circleId, challengeId).doc(userId);
    final challengeRef = _challengeDoc(circleId, challengeId);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Write this user's vote.
    await voteRef.set(
      ChallengeVote(
        challengeId: challengeId,
        userId: userId,
        approve: approve,
        createdAtMs: now,
      ).toMap(),
    );

    // Check totals and flip status if majority reached.
    final allVotes = await getVotes(circleId, challengeId);
    final approvals = allVotes.where((v) => v.approve).length;
    final rejections = allVotes.where((v) => !v.approve).length;
    final majority = memberCount / 2;

    if (approvals > majority) {
      await challengeRef.update({
        'status': ChallengeStatus.active.storageValue,
        'updatedAtMs': now,
      });
    } else if (rejections > majority) {
      await challengeRef.update({
        'status': ChallengeStatus.rejected.storageValue,
        'updatedAtMs': now,
      });
    }
  }

  @override
  Future<List<ChallengeVote>> getVotes(
    String circleId,
    String challengeId,
  ) async {
    final snap = await _votes(circleId, challengeId).get();
    return snap.docs.map(_voteFromDoc).toList();
  }
}
