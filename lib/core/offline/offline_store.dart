import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../local_db/isar_collections/isar_schemas.dart';

class OfflineStore {
  OfflineStore._();

  static final OfflineStore instance = OfflineStore._();

  /// When set, [isar] returns this instance (tests).
  @visibleForTesting
  static Isar? debugIsarOverride;

  @visibleForTesting
  static void clearDebugIsarOverrideForTests() {
    debugIsarOverride = null;
  }

  Isar? _isar;

  Isar? get isar => debugIsarOverride ?? _isar;

  Future<void> initialize() async {
    if (_isar != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      isarSchemaList,
      directory: dir.path,
      name: 'coach_isar',
    );
    debugPrint('OfflineStore: Isar opened at ${dir.path}');
  }
}
