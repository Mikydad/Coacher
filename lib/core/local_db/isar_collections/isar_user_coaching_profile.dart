import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../features/coaching/domain/models/user_coaching_profile.dart';

part 'isar_user_coaching_profile.g.dart';

@collection
class IsarUserCoachingProfile {
  Id id = Isar.autoIncrement;

  /// Fixed string ID — single-record pattern.
  @Index(unique: true)
  late String profileId;

  @Index()
  late String coachingStyle;

  late int lastChangedAtMs;
  late int updatedAtMs;
  late int schemaVersion;

  /// Full payload for safe round-trip deserialization (includes history).
  late String payloadJson;

  static IsarUserCoachingProfile fromDomain(UserCoachingProfile profile) {
    return IsarUserCoachingProfile()
      ..profileId = profile.id
      ..coachingStyle = profile.coachingStyle.toStorage()
      ..lastChangedAtMs = profile.lastChangedAtMs
      ..updatedAtMs = profile.updatedAtMs
      ..schemaVersion = profile.schemaVersion
      ..payloadJson = jsonEncode(profile.toMap());
  }

  UserCoachingProfile toDomain() {
    final payload = _decodePayload(payloadJson);
    return UserCoachingProfile.fromMap(payload);
  }
}

Map<String, dynamic> _decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (e) {
    debugPrint('isar_user_coaching_profile: swallowed error: $e');
  }
  return const <String, dynamic>{};
}
