import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/models/activity_feed_item.dart';
import '../domain/models/circle_enums.dart';

abstract class ActivityFeedRepository {
  Stream<List<ActivityFeedItem>> watchFeed(String circleId, {int limit = 30});
  Future<void> postFeedItem(ActivityFeedItem item);

  /// Returns an existing item for idempotency check.
  /// Matches on userId + entityId + eventType + dateKey within the circle.
  Future<ActivityFeedItem?> findExistingItem({
    required String circleId,
    required String userId,
    required String? entityId,
    required ActivityEventType eventType,
    required String dateKey,
  });
}

class FirestoreActivityFeedRepository implements ActivityFeedRepository {
  FirestoreActivityFeedRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _feed(String circleId) =>
      _firestore.collection(FirestorePaths.circleActivityFeed(circleId));

  static ActivityFeedItem _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return ActivityFeedItem.fromMap(data);
  }

  @override
  Stream<List<ActivityFeedItem>> watchFeed(
    String circleId, {
    int limit = 30,
  }) {
    return _feed(circleId)
        .orderBy('createdAtMs', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> postFeedItem(ActivityFeedItem item) async {
    await _feed(item.circleId).doc(item.id).set(item.toMap());
  }

  @override
  Future<ActivityFeedItem?> findExistingItem({
    required String circleId,
    required String userId,
    required String? entityId,
    required ActivityEventType eventType,
    required String dateKey,
  }) async {
    Query<Map<String, dynamic>> q = _feed(circleId)
        .where('userId', isEqualTo: userId)
        .where('eventType', isEqualTo: eventType.storageValue)
        .where('dateKey', isEqualTo: dateKey);

    if (entityId != null) {
      q = q.where('entityId', isEqualTo: entityId);
    }

    final snap = await q.limit(1).get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }
}
