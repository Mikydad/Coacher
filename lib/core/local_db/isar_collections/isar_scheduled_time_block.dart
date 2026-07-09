import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../features/time_blocks/domain/models/scheduled_time_block.dart';

part 'isar_scheduled_time_block.g.dart';

@collection
class IsarScheduledTimeBlock {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String blockId;

  @Index()
  late String entityId;

  @Index()
  late String entityKind;

  @Index()
  late int startAtMs;

  @Index()
  late int computedEndAtMs;

  late int expectedDurationMinutes;
  late String flexibilityType;
  late bool allowOverlapOverride;
  late int importance;
  late int createdAtMs;
  late int updatedAtMs;
  late int schemaVersion;

  /// Full payload for safe round-trip deserialization.
  late String payloadJson;

  static IsarScheduledTimeBlock fromDomain(ScheduledTimeBlock block) {
    return IsarScheduledTimeBlock()
      ..blockId = block.id
      ..entityId = block.entityId
      ..entityKind = block.entityKind
      ..startAtMs = block.startAt.millisecondsSinceEpoch
      ..computedEndAtMs = block.computedEndAt.millisecondsSinceEpoch
      ..expectedDurationMinutes = block.expectedDurationMinutes
      ..flexibilityType = block.flexibilityType.name
      ..allowOverlapOverride = block.allowOverlapOverride
      ..importance = block.importance
      ..createdAtMs = block.createdAtMs
      ..updatedAtMs = block.updatedAtMs
      ..schemaVersion = block.schemaVersion
      ..payloadJson = jsonEncode(block.toMap());
  }

  ScheduledTimeBlock toDomain() {
    final payload = _decodePayload(payloadJson);
    return ScheduledTimeBlock.fromMap(payload);
  }
}

Map<String, dynamic> _decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (e) {
    debugPrint('isar_scheduled_time_block: swallowed error: $e');
  }
  return const <String, dynamic>{};
}
