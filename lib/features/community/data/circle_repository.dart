import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/models/accountability_circle.dart';
import '../domain/models/circle_enums.dart';

abstract class CircleRepository {
  Stream<AccountabilityCircle?> watchCircle(String circleId);
  Stream<List<AccountabilityCircle>> watchCircles(List<String> circleIds);
  Future<AccountabilityCircle?> getCircle(String circleId);
  Future<void> createCircle(AccountabilityCircle circle);
  Future<void> updateCircle(AccountabilityCircle circle);
  Future<void> deleteCircle(String circleId);
  Future<List<AccountabilityCircle>> searchCircles({
    String? query,
    String? category,
  });
}

class FirestoreCircleRepository implements CircleRepository {
  FirestoreCircleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _circles =>
      _firestore.collection(FirestorePaths.circles);

  static AccountabilityCircle _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return AccountabilityCircle.fromMap(data);
  }

  @override
  Stream<AccountabilityCircle?> watchCircle(String circleId) {
    return _circles
        .doc(circleId)
        .snapshots()
        .map((doc) => doc.exists ? _fromDoc(doc) : null);
  }

  @override
  Stream<List<AccountabilityCircle>> watchCircles(List<String> circleIds) {
    if (circleIds.isEmpty) {
      return Stream.value([]);
    }
    // V1 max members = 8, so circleIds.length ≤ 8 — no chunking needed.
    return _circles
        .where('id', whereIn: circleIds)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  @override
  Future<AccountabilityCircle?> getCircle(String circleId) async {
    final doc = await _circles.doc(circleId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDoc(doc);
  }

  @override
  Future<void> createCircle(AccountabilityCircle circle) async {
    circle.validate();
    final map = circle.toMap();
    // Store id in the document body so whereIn queries can match it.
    await _circles.doc(circle.id).set(map);
  }

  @override
  Future<void> updateCircle(AccountabilityCircle circle) async {
    circle.validate();
    await _circles.doc(circle.id).set(circle.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteCircle(String circleId) async {
    await _circles.doc(circleId).delete();
  }

  @override
  Future<List<AccountabilityCircle>> searchCircles({
    String? query,
    String? category,
  }) async {
    Query<Map<String, dynamic>> q = _circles
        .where('visibility', isEqualTo: CircleVisibility.public.storageValue);

    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }

    final snap = await q.get();
    final results = snap.docs.map(_fromDoc).toList();

    if (query != null && query.isNotEmpty) {
      final lower = query.toLowerCase();
      return results
          .where((c) => c.name.toLowerCase().contains(lower))
          .toList();
    }
    return results;
  }
}
