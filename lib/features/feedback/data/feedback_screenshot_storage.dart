import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads feedback screenshots (tester captures are PNG; gallery
/// attachments are usually JPEG) to Firebase Storage.
class FeedbackScreenshotStorage {
  FeedbackScreenshotStorage({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static String _extensionFor(String contentType) {
    switch (contentType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      case 'image/heic':
        return 'heic';
      case 'image/heif':
        return 'heif';
      default:
        return 'png';
    }
  }

  /// Uploads image [bytes] and returns the download URL.
  ///
  /// Path shape is enforced by storage.rules (`/feedback/{uid}/{fileName}`):
  /// uid-scoped, uid-prefixed filename, create-only, image/*, < 5MB.
  Future<String> upload(
    Uint8List bytes,
    String uid,
    String reportId, {
    String contentType = 'image/png',
  }) async {
    final ext = _extensionFor(contentType);
    final objectRef = _storage.ref('feedback/$uid/${uid}_$reportId.$ext');
    await objectRef.putData(bytes, SettableMetadata(contentType: contentType));
    return objectRef.getDownloadURL();
  }
}
