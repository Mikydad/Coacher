import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../features/profile/domain/models/user_profile_preference.dart';

part 'isar_user_profile_preference.g.dart';

@collection
class IsarUserProfilePreference {
  Id id = Isar.autoIncrement;

  /// Fixed string ID — single-record pattern.
  @Index(unique: true)
  late String profileId;

  late String displayName;
  late String defaultEnforcementMode;
  late int updatedAtMs;
  late int schemaVersion;

  /// Full payload for safe round-trip deserialization.
  late String payloadJson;

  static IsarUserProfilePreference fromDomain(UserProfilePreference pref) {
    return IsarUserProfilePreference()
      ..profileId = pref.id
      ..displayName = pref.displayName
      ..defaultEnforcementMode = pref.defaultEnforcementMode.toStorage()
      ..updatedAtMs = pref.updatedAtMs
      ..schemaVersion = pref.schemaVersion
      ..payloadJson = jsonEncode(pref.toMap());
  }

  UserProfilePreference toDomain() {
    final payload = _decodePayload(payloadJson);
    return UserProfilePreference.fromMap(payload);
  }
}

Map<String, dynamic> _decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (_) {}
  return const <String, dynamic>{};
}
