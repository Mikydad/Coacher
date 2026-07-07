import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/models/ai_pulse.dart';

abstract class AiPulseRepository {
  Stream<AiPulse?> watchLatestPulse(String circleId, AiPulseType type);
  Future<void> savePulse(AiPulse pulse);

  /// Returns true if a pulse was generated within the last [cooldownMinutes].
  Future<bool> isOnCooldown(
    String circleId,
    AiPulseType type, {
    int cooldownMinutes = 240,
  });
}

class FirestoreAiPulseRepository implements AiPulseRepository {
  FirestoreAiPulseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String circleId) =>
      _firestore.collection(FirestorePaths.circleAiPulse(circleId));

  static AiPulse _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return AiPulse.fromMap(data);
  }

  @override
  Stream<AiPulse?> watchLatestPulse(String circleId, AiPulseType type) {
    return _col(circleId)
        .where('type', isEqualTo: type.storageValue)
        .orderBy('generatedAtMs', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : _fromDoc(s.docs.first));
  }

  @override
  Future<void> savePulse(AiPulse pulse) async {
    await _col(pulse.circleId).doc(pulse.id).set(pulse.toMap());
  }

  @override
  Future<bool> isOnCooldown(
    String circleId,
    AiPulseType type, {
    int cooldownMinutes = 240,
  }) async {
    final snap = await _col(circleId)
        .where('type', isEqualTo: type.storageValue)
        .orderBy('generatedAtMs', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return false;
    final latest = _fromDoc(snap.docs.first);
    final cutoff =
        DateTime.now().millisecondsSinceEpoch - cooldownMinutes * 60 * 1000;
    return latest.generatedAtMs > cutoff;
  }
}
