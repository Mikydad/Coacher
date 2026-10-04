import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/models/circle_message.dart';

abstract class CircleMessageRepository {
  Stream<List<CircleMessage>> watchMessages(String circleId, {int limit = 50});
  Future<void> sendMessage(CircleMessage message);

  /// Replaces the caller's OWN reaction list on a message
  /// (`reactionsByUser.{uid}` — the only key rules let a member touch).
  Future<void> setMyReactions(
    String circleId,
    String messageId,
    String uid,
    List<String> emojis,
  );

  /// Tombstones a message (2026-09-24): content and image go, the row stays
  /// so the thread shows the deletion in place. [byUid] is the sender or a
  /// moderator; the rules check which fields each may touch.
  Future<void> deleteMessage(
    String circleId,
    String messageId, {
    required String byUid,
    int? nowMs,
  });
}

class FirestoreCircleMessageRepository implements CircleMessageRepository {
  FirestoreCircleMessageRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _messages(String circleId) =>
      _firestore.collection(FirestorePaths.circleMessages(circleId));

  static CircleMessage _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return CircleMessage.fromMap(data);
  }

  @override
  Stream<List<CircleMessage>> watchMessages(String circleId, {int limit = 50}) {
    return _messages(circleId)
        .orderBy('createdAtMs', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> sendMessage(CircleMessage message) async {
    final map = message.toMap();
    await _messages(message.circleId).doc(message.id).set(map);
  }

  @override
  Future<void> setMyReactions(
    String circleId,
    String messageId,
    String uid,
    List<String> emojis,
  ) async {
    await _messages(circleId).doc(messageId).update({
      'reactionsByUser.$uid': List<String>.from(emojis),
    });
  }

  @override
  Future<void> deleteMessage(
    String circleId,
    String messageId, {
    required String byUid,
    int? nowMs,
  }) async {
    await _messages(circleId).doc(messageId).update({
      'content': FieldValue.delete(),
      'imageUrl': FieldValue.delete(),
      'deletedAtMs': nowMs ?? DateTime.now().millisecondsSinceEpoch,
      'deletedByUid': byUid,
    });
  }
}
