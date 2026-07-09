import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

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
    // Boot breadcrumbs use print (debugPrint is silenced in release): the
    // storage lookup and Isar.open are the two known hang candidates on
    // new iOS versions in AOT builds.
    // ignore: avoid_print
    print('[boot] resolving storage dir');
    final dir = await getAppStorageDirectory();
    // ignore: avoid_print
    print('[boot] opening isar at ${dir.path}');
    // openSync, not open: the async variant's isolate/port handshake never
    // completes in AOT (profile/release) builds on iOS 26 — observed with
    // both stock Isar 3.1.0 and the community fork. The synchronous FFI
    // path avoids that machinery; boot-time blocking is a few ms.
    _isar = Isar.openSync(
      isarSchemaList,
      directory: dir.path,
      name: 'coach_isar',
      inspector: false,
    );
    // ignore: avoid_print
    print('[boot] isar open done');
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
