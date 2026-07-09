import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../features/analytics/domain/models/current_coaching_focus.dart';

part 'isar_coaching_focus.g.dart';

@collection
class IsarCoachingFocus {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String focusId;

  @Index()
  late String lifecycleState;

  @Index()
  late int detectedAtMs;

  @Index()
  late int activeUntilMs;

  late String primaryInsightId;
  late String payloadJson;
  late int schemaVersion;

  static IsarCoachingFocus fromDomain(CurrentCoachingFocus focus) {
    return IsarCoachingFocus()
      ..focusId = focus.focusId
      ..lifecycleState = focus.lifecycleState.name
      ..detectedAtMs = focus.detectedAtMs
      ..activeUntilMs = focus.activeUntilMs
      ..primaryInsightId = focus.primaryInsightId
      ..payloadJson = jsonEncode(focus.toMap())
      ..schemaVersion = focus.schemaVersion;
  }

  CurrentCoachingFocus toDomain() {
    final payload = _decodePayload(payloadJson);
    return CurrentCoachingFocus.fromMap(payload);
  }
}

Map<String, dynamic> _decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (e) {
    debugPrint('isar_coaching_focus: swallowed error: $e');
  }
  return const <String, dynamic>{};
}
