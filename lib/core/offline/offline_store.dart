import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';

class OfflineStore {
  OfflineStore._();

  static final OfflineStore instance = OfflineStore._();
  Isar? _isar;

  Isar? get isar => _isar;

  Future<void> initialize() async {
    if (_isar != null) return;
    // Isar requires at least one generated collection schema to open.
    // We postpone opening until schemas are added in later tasks.
    debugPrint('OfflineStore initialized without Isar collections yet.');
  }
}
