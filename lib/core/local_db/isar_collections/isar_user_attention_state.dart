import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../features/context_override/domain/models/user_attention_state.dart';

part 'isar_user_attention_state.g.dart';

@collection
class IsarUserAttentionState {
  Id id = Isar.autoIncrement;

  /// Fixed string ID — single-record pattern.
  @Index(unique: true)
  late String stateId;

  @Index()
  late String activeOverride;

  late bool manuallyMuted;
  late int updatedAtMs;
  late int schemaVersion;

  /// Full payload for safe round-trip deserialization.
  late String payloadJson;

  static IsarUserAttentionState fromDomain(UserAttentionState state) {
    return IsarUserAttentionState()
      ..stateId = state.id
      ..activeOverride = state.activeOverride.name
      ..manuallyMuted = state.manuallyMuted
      ..updatedAtMs = state.updatedAtMs
      ..schemaVersion = state.schemaVersion
      ..payloadJson = jsonEncode(state.toMap());
  }

  UserAttentionState toDomain() {
    final payload = _decodePayload(payloadJson);
    return UserAttentionState.fromMap(payload);
  }
}

Map<String, dynamic> _decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (e) {
    debugPrint('isar_user_attention_state: swallowed error: $e');
  }
  return const <String, dynamic>{};
}
