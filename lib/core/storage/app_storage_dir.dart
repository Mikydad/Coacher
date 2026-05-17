import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Returns a writable directory for app-local files.
///
/// On some iOS simulator/runtime combinations, path_provider_foundation can
/// fail to load native Objective-C symbols. In that case we fall back to a
/// deterministic folder under [Directory.systemTemp] so the app can continue.
Future<Directory> getAppStorageDirectory() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  } catch (error, stackTrace) {
    debugPrint(
      'Storage fallback: getApplicationDocumentsDirectory failed: $error',
    );
    debugPrint('Storage fallback stack: $stackTrace');
    final fallback = Directory('${Directory.systemTemp.path}/coach_for_life');
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    return fallback;
  }
}
