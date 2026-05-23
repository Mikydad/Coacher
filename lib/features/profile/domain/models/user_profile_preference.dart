import '../../../../core/validation/model_validators.dart';
import '../../../coaching/domain/models/enforcement_mode.dart';

const int kUserProfilePreferenceSchemaVersion = 1;
const String kUserProfilePreferenceId = 'user_profile_preference';

/// Single-record model holding lightweight user profile preferences:
/// display name and default [EnforcementMode] for new entities.
///
/// Persisted to Isar using the same `id + payloadJson` pattern as
/// [UserCoachingProfile]. No Firestore sync in Phase E.
class UserProfilePreference {
  const UserProfilePreference({
    required this.id,
    required this.displayName,
    required this.defaultEnforcementMode,
    required this.updatedAtMs,
    this.morningBriefEnabled = false,
    this.schemaVersion = kUserProfilePreferenceSchemaVersion,
  });

  /// Always [kUserProfilePreferenceId] — single-record pattern.
  final String id;

  /// Human-readable name the user has chosen for themselves. Defaults to
  /// an empty string; callers should fall back to a suitable placeholder.
  final String displayName;

  /// Default [EnforcementMode] applied to new tasks/habits when the user
  /// has not explicitly chosen one.
  final EnforcementMode defaultEnforcementMode;

  /// When true, Coach AI shows a subtle "suggestions for today" banner on the
  /// first app open between 06:00–10:00 if the Coach screen hasn't been opened.
  final bool morningBriefEnabled;

  final int updatedAtMs;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(id, 'userProfilePreference.id');
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'userProfilePreference.schemaVersion',
    );
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'defaultEnforcementMode': defaultEnforcementMode.toStorage(),
    'morningBriefEnabled': morningBriefEnabled,
    'updatedAtMs': updatedAtMs,
    'schemaVersion': schemaVersion,
  };

  static UserProfilePreference fromMap(Map<String, dynamic> map) =>
      UserProfilePreference(
        id: map['id'] as String? ?? kUserProfilePreferenceId,
        displayName: map['displayName'] as String? ?? '',
        defaultEnforcementMode: EnforcementMode.fromStorage(
          map['defaultEnforcementMode'] as String?,
        ),
        morningBriefEnabled: map['morningBriefEnabled'] as bool? ?? false,
        updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
        schemaVersion:
            (map['schemaVersion'] as num?)?.toInt() ??
            kUserProfilePreferenceSchemaVersion,
      );

  UserProfilePreference copyWith({
    String? displayName,
    EnforcementMode? defaultEnforcementMode,
    bool? morningBriefEnabled,
    int? updatedAtMs,
    int? schemaVersion,
  }) => UserProfilePreference(
    id: id,
    displayName: displayName ?? this.displayName,
    defaultEnforcementMode:
        defaultEnforcementMode ?? this.defaultEnforcementMode,
    morningBriefEnabled: morningBriefEnabled ?? this.morningBriefEnabled,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
}
