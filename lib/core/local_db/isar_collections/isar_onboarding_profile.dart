import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../features/onboarding/domain/models/onboarding_profile.dart';

part 'isar_onboarding_profile.g.dart';

@collection
class IsarOnboardingProfile {
  Id id = Isar.autoIncrement;

  /// Fixed string ID — single-record pattern.
  @Index(unique: true)
  late String profileId;

  late int completedAtMs;
  late int updatedAtMs;
  late int schemaVersion;

  /// Full payload for safe round-trip deserialization.
  late String payloadJson;

  static IsarOnboardingProfile fromDomain(OnboardingProfile profile) {
    return IsarOnboardingProfile()
      ..profileId = profile.id
      ..completedAtMs = profile.completedAtMs
      ..updatedAtMs = profile.updatedAtMs
      ..schemaVersion = profile.schemaVersion
      ..payloadJson = jsonEncode(profile.toMap());
  }

  OnboardingProfile toDomain() {
    final payload = _decodePayload(payloadJson);
    return OnboardingProfile.fromMap(payload);
  }
}

Map<String, dynamic> _decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (e) {
    debugPrint('isar_onboarding_profile: swallowed error: $e');
  }
  return const <String, dynamic>{};
}
