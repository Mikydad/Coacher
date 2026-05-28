import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/utils/stable_id.dart';

/// File extension for a circle proof upload (defaults to jpg).
String imageExtensionFromPath(String path, {String? mimeType}) {
  final fromMime = _extensionFromMime(mimeType);
  if (fromMime != null) return fromMime;

  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  if (dot != -1 && dot < name.length - 1) {
    final ext = name.substring(dot + 1).toLowerCase();
    if (_knownImageExtensions.contains(ext)) {
      return ext == 'jpeg' ? 'jpg' : ext;
    }
  }
  return 'jpg';
}

const _knownImageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'heic',
  'heif',
};

String? _extensionFromMime(String? mimeType) {
  if (mimeType == null || mimeType.isEmpty) return null;
  switch (mimeType.toLowerCase()) {
    case 'image/jpeg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/gif':
      return 'gif';
    case 'image/webp':
      return 'webp';
    case 'image/heic':
      return 'heic';
    case 'image/heif':
      return 'heif';
    default:
      return null;
  }
}

String contentTypeForImageExtension(String ext) {
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    case 'heif':
      return 'image/heif';
    default:
      return 'image/jpeg';
  }
}

/// Uploads proof images to Firebase Storage for circle chat.
class CircleProofStorage {
  CircleProofStorage({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadChatProof({
    required String circleId,
    required File file,
    String? mimeType,
    String? sourcePath,
  }) async {
    final path = sourcePath ?? file.path;
    final ext = imageExtensionFromPath(path, mimeType: mimeType);
    final objectRef = _storage.ref(
      'circles/$circleId/proofs/${StableId.generate('proof')}.$ext',
    );
    await objectRef.putFile(
      file,
      SettableMetadata(contentType: contentTypeForImageExtension(ext)),
    );
    return objectRef.getDownloadURL();
  }

  Future<void> uploadChallengeProof({
    required String challengeId,
    required String userId,
    required File file,
  }) async {
    final ext = imageExtensionFromPath(file.path);
    final objectRef = _storage.ref(
      'challenge_proofs/$challengeId/${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await objectRef.putFile(
      file,
      SettableMetadata(contentType: contentTypeForImageExtension(ext)),
    );
  }
}

/// User-facing message for storage upload failures.
String circleProofUploadErrorMessage(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'Upload blocked. Sign in again or ask a circle moderator.';
      case 'unauthenticated':
        return 'Sign in to upload images.';
      case 'canceled':
        return 'Upload canceled.';
      default:
        break;
    }
  }
  return 'Failed to upload image. Check your connection and try again.';
}
