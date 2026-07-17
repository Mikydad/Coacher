import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Local cache for the owner's own stake photo preview.
///
/// The photo is picked ON this device at creation, so the creator never
/// needs to download it back — [seed] copies it at create time, and the
/// detail screen reads the cache before touching Storage (slow links made
/// the network-only preview take minutes). Files are small (≤1600px q85)
/// and are cleaned opportunistically when a challenge's preview is gone.
class StakePhotoCache {
  StakePhotoCache._();

  static Future<File> _fileFor(String challengeId) async {
    final dir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${dir.path}/stake_photo_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/$challengeId.jpg');
  }

  static Future<void> seed(String challengeId, File original) async {
    try {
      await original.copy((await _fileFor(challengeId)).path);
    } catch (_) {
      // Cache is best-effort; the network path still works.
    }
  }

  static Future<Uint8List?> read(String challengeId) async {
    try {
      final file = await _fileFor(challengeId);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String challengeId, Uint8List bytes) async {
    try {
      await (await _fileFor(challengeId)).writeAsBytes(bytes, flush: true);
    } catch (_) {
      // Best-effort.
    }
  }

  static Future<void> evict(String challengeId) async {
    try {
      final file = await _fileFor(challengeId);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort.
    }
  }
}
