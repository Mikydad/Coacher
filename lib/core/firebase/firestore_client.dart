import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';

class FirestoreClient {
  /// Construct a client scoped to the current auth user.
  ///
  /// The uid is **captured once at construction time** so that all collection
  /// references built from the same client instance always use the same uid,
  /// even if the auth state changes mid-flight (e.g. during a long sync loop).
  /// Callers that need the latest uid should create a new [FirestoreClient].
  FirestoreClient({FirebaseFirestore? firestore, String? uid})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uid = uid ??
            FirebaseAuth.instance.currentUser?.uid ??
            AppConfig.localUserId;

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> userCollection(String collection) {
    return _firestore.collection('users').doc(_uid).collection(collection);
  }
}
