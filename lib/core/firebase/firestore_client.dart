import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';

class FirestoreClient {
  FirestoreClient({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String get _activeUid =>
      FirebaseAuth.instance.currentUser?.uid ?? AppConfig.localUserId;

  CollectionReference<Map<String, dynamic>> userCollection(String collection) {
    return _firestore.collection('users').doc(_activeUid).collection(collection);
  }
}
