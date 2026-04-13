import 'dart:io';

import 'package:coach_for_life/core/local_db/isar_collections/isar_schemas.dart';
import 'package:isar/isar.dart';

/// Loads Isar Core native library (required for `flutter test` VM, not only devices).
Future<void> ensureIsarCoreForVmTests() async {
  await Isar.initializeIsarCore(download: true);
}

/// Opens an isolated Isar database under a temp directory (for tests).
Future<({Isar isar, Directory dir})> openTempIsar() async {
  await ensureIsarCoreForVmTests();
  final dir = await Directory.systemTemp.createTemp('coach_isar_test_');
  final isar = await Isar.open(
    isarSchemaList,
    directory: dir.path,
    name: 'test_${DateTime.now().microsecondsSinceEpoch}',
  );
  return (isar: isar, dir: dir);
}

Future<void> closeTempIsar(Isar isar, Directory dir) async {
  await isar.close(deleteFromDisk: true);
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}
