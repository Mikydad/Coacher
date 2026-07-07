import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/models/circle_message.dart';

abstract class CircleMessageRepository {
  Stream<List<CircleMessage>> watchMessages(String circleId, {int limit = 50});
  Future<void> sendMessage(CircleMessage message);
  Future<void> updateReactions(
    String circleId,
    String messageId,
    Map<String, List<String>> reactions,
  );
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
  Future<void> updateReactions(
    String circleId,
    String messageId,
    Map<String, List<String>> reactions,
  ) async {
    await _messages(circleId).doc(messageId).update({
      'reactions': reactions.map(
        (emoji, uids) => MapEntry(emoji, List<String>.from(uids)),
      ),
    });
  }
}
