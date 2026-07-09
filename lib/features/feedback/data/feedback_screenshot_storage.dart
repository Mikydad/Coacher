import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads tester bug-report screenshots to Firebase Storage.
class FeedbackScreenshotStorage {
  FeedbackScreenshotStorage({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads PNG [bytes] and returns the download URL.
  ///
  /// Path shape is enforced by storage.rules (`/feedback/{uid}/{fileName}`):
  /// uid-scoped, uid-prefixed filename, create-only, image/png, < 5MB.
  Future<String> upload(Uint8List bytes, String uid, String reportId) async {
    final objectRef = _storage.ref('feedback/$uid/${uid}_$reportId.png');
    await objectRef.putData(
      bytes,
      SettableMetadata(contentType: 'image/png'),
    );
    return objectRef.getDownloadURL();
  }
}
