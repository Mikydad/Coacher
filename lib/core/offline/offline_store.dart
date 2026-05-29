import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../local_db/isar_collections/isar_schemas.dart';
import '../storage/app_storage_dir.dart';

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
    final dir = await getAppStorageDirectory();
    _isar = await Isar.open(
      isarSchemaList,
      directory: dir.path,
      name: 'coach_isar',
    );
    debugPrint('OfflineStore: Isar opened at ${dir.path}');
  }

  /// Wipe all Isar collections in a single write transaction.
  ///
  /// Called by [AuthSessionPolicy.clearLocalSession] on sign-out or when a
  /// different user account signs in. Safe to call when [isar] is null
  /// (no-op, e.g. before first [initialize]).
  Future<void> clearAll() async {
    final db = isar;
    if (db == null) return;
    await db.writeTxn(() => db.clear());
    debugPrint('OfflineStore: all collections cleared (session wipe)');
  }
}
