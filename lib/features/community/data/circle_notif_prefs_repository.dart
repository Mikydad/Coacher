import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/models/circle_notif_prefs.dart';

abstract class CircleNotifPrefsRepository {
  Future<CircleNotifPrefs> getPrefs(String circleId);
  Future<void> savePrefs(CircleNotifPrefs prefs);
}

class FirestoreCircleNotifPrefsRepository
    implements CircleNotifPrefsRepository {
  FirestoreCircleNotifPrefsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Future<CircleNotifPrefs> getPrefs(String circleId) async {
    if (_uid.isEmpty) return CircleNotifPrefs(circleId: circleId);
    final doc = await _firestore
        .doc(FirestorePaths.userCircleNotifPrefsDoc(_uid, circleId))
        .get();
    if (!doc.exists || doc.data() == null) {
      return CircleNotifPrefs(circleId: circleId);
    }
    return CircleNotifPrefs.fromMap(doc.data()!);
  }

  @override
  Future<void> savePrefs(CircleNotifPrefs prefs) async {
    if (_uid.isEmpty) return;
    await _firestore
        .doc(FirestorePaths.userCircleNotifPrefsDoc(_uid, prefs.circleId))
        .set(prefs.toMap());
  }
}
