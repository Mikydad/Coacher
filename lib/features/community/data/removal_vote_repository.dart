import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../application/user_circle_membership_service.dart';
import '../domain/models/removal_vote.dart';

abstract class RemovalVoteRepository {
  Stream<List<RemovalVote>> watchActiveVotes(String circleId);
  Future<void> createVote(RemovalVote vote);
  Future<void> castVote({
    required String circleId,
    required String voteId,
    required String userId,
    required bool approve,
  });
}

class FirestoreRemovalVoteRepository implements RemovalVoteRepository {
  FirestoreRemovalVoteRepository({
    required UserCircleMembershipService membershipSvc,
    FirebaseFirestore? firestore,
  }) : _membershipSvc = membershipSvc,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final UserCircleMembershipService _membershipSvc;

  CollectionReference<Map<String, dynamic>> _col(String circleId) =>
      _firestore.collection(FirestorePaths.circleRemovalVotes(circleId));

  static RemovalVote _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return RemovalVote.fromMap(data);
  }

  @override
  Stream<List<RemovalVote>> watchActiveVotes(String circleId) {
    return _col(circleId)
        .where('status', isEqualTo: RemovalVoteStatus.pending.storageValue)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> createVote(RemovalVote vote) async {
    await _col(vote.circleId).doc(vote.id).set(vote.toMap());
  }

  @override
  Future<void> castVote({
    required String circleId,
    required String voteId,
    required String userId,
    required bool approve,
  }) async {
    final ref = _col(circleId).doc(voteId);
    final now = DateTime.now().millisecondsSinceEpoch;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data() == null) return;

      final removalVote = _fromDoc(snap);
      final updatedVotes = Map<String, bool>.from(removalVote.votes);
      updatedVotes[userId] = approve;

      // Only moderators vote (max 2). Majority = more than half of voters.
      final approvals = updatedVotes.values.where((v) => v).length;
      final total = updatedVotes.length;

      // With 1 moderator: 1 approval is majority. With 2: need 2.
      final majorityApprove = approvals > total / 2;

      if (majorityApprove) {
        // Resolve vote and remove the target member.
        tx.update(ref, {
          'votes': updatedVotes,
          'status': RemovalVoteStatus.resolved.storageValue,
          'updatedAtMs': now,
        });
      } else {
        tx.update(ref, {'votes': updatedVotes, 'updatedAtMs': now});
      }

      if (majorityApprove) {
        // Execute member removal outside the transaction to avoid nesting.
        Future.microtask(
          () => _membershipSvc.removeMember(circleId, removalVote.targetUserId),
        );
      }
    });
  }
}
