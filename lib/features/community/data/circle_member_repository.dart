import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/models/circle_member.dart';

abstract class CircleMemberRepository {
  Stream<List<CircleMember>> watchMembers(String circleId);
  Future<CircleMember?> getMember(String circleId, String userId);
  Future<void> setMember(CircleMember member);
  Future<void> deleteMember(String circleId, String userId);
}

class FirestoreCircleMemberRepository implements CircleMemberRepository {
  FirestoreCircleMemberRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _members(String circleId) =>
      _firestore.collection(FirestorePaths.circleMembers(circleId));

  static CircleMember _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['userId'] = doc.id;
    return CircleMember.fromMap(data);
  }

  @override
  Stream<List<CircleMember>> watchMembers(String circleId) {
    return _members(circleId)
        .orderBy('joinedAtMs', descending: false)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<CircleMember?> getMember(String circleId, String userId) async {
    final doc = await _members(circleId).doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDoc(doc);
  }

  @override
  Future<void> setMember(CircleMember member) async {
    final map = member.toMap();
    await _members(member.circleId).doc(member.userId).set(
          map,
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteMember(String circleId, String userId) async {
    await _members(circleId).doc(userId).delete();
  }
}
