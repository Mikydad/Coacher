import '../../../../core/validation/model_validators.dart';
import 'coaching_style.dart';

const int kUserCoachingProfileSchemaVersion = 1;
const String kUserCoachingProfileId = 'user_coaching_profile';
const int kStyleChangeHistoryMaxEntries = 10;

// ─── StyleChangeEntry ─────────────────────────────────────────────────────────

/// A log entry recording a change from one [CoachingStyle] to another.
class StyleChangeEntry {
  const StyleChangeEntry({
    required this.previousStyle,
    required this.newStyle,
    required this.changedAtMs,
  });

  final CoachingStyle previousStyle;
  final CoachingStyle newStyle;
  final int changedAtMs;

  Map<String, dynamic> toMap() => {
    'previousStyle': previousStyle.toStorage(),
    'newStyle': newStyle.toStorage(),
    'changedAtMs': changedAtMs,
  };

  static StyleChangeEntry fromMap(Map<String, dynamic> map) => StyleChangeEntry(
    previousStyle: CoachingStyle.fromStorage(map['previousStyle'] as String?),
    newStyle: CoachingStyle.fromStorage(map['newStyle'] as String?),
    changedAtMs: (map['changedAtMs'] as num?)?.toInt() ?? 0,
  );
}

// ─── UserCoachingProfile ──────────────────────────────────────────────────────

/// Single-record model holding the user's global [CoachingStyle] and its
/// change history. Persisted to Isar; no Firestore sync in Phase D.
class UserCoachingProfile {
  const UserCoachingProfile({
    required this.id,
    required this.coachingStyle,
    required this.lastChangedAtMs,
    this.onboardingCompletedAtMs,
    this.styleChangeHistory = const [],
    required this.updatedAtMs,
    this.schemaVersion = kUserCoachingProfileSchemaVersion,
  });

  /// Always [kUserCoachingProfileId] — single-record pattern.
  final String id;

  final CoachingStyle coachingStyle;

  /// Epoch ms when [coachingStyle] was last changed.
  final int lastChangedAtMs;

  /// Epoch ms when the user set their style during onboarding. Null if the
  /// user skipped onboarding or style was set programmatically.
  final int? onboardingCompletedAtMs;

  /// Ordered log of past style changes (newest last), capped at
  /// [kStyleChangeHistoryMaxEntries].
  final List<StyleChangeEntry> styleChangeHistory;

  final int updatedAtMs;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(id, 'userCoachingProfile.id');
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'userCoachingProfile.schemaVersion',
    );
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  /// Returns a new profile with [newStyle] applied and a [StyleChangeEntry]
  /// appended. History is trimmed to [kStyleChangeHistoryMaxEntries].
  UserCoachingProfile withStyleChange(CoachingStyle newStyle, int nowMs) {
    final entry = StyleChangeEntry(
      previousStyle: coachingStyle,
      newStyle: newStyle,
      changedAtMs: nowMs,
    );
    final updated = [...styleChangeHistory, entry];
    if (updated.length > kStyleChangeHistoryMaxEntries) {
      updated.removeRange(0, updated.length - kStyleChangeHistoryMaxEntries);
    }
    return copyWith(
      coachingStyle: newStyle,
      lastChangedAtMs: nowMs,
      styleChangeHistory: updated,
      updatedAtMs: nowMs,
    );
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'coachingStyle': coachingStyle.toStorage(),
    'lastChangedAtMs': lastChangedAtMs,
    if (onboardingCompletedAtMs != null)
      'onboardingCompletedAtMs': onboardingCompletedAtMs,
    'styleChangeHistory':
        styleChangeHistory.map((e) => e.toMap()).toList(growable: false),
    'updatedAtMs': updatedAtMs,
    'schemaVersion': schemaVersion,
  };

  static UserCoachingProfile fromMap(Map<String, dynamic> map) {
    final rawHistory = map['styleChangeHistory'];
    final history = <StyleChangeEntry>[];
    if (rawHistory is List) {
      for (final entry in rawHistory) {
        if (entry is Map) {
          history.add(StyleChangeEntry.fromMap(entry.cast<String, dynamic>()));
        }
      }
    }
    return UserCoachingProfile(
      id: map['id'] as String? ?? kUserCoachingProfileId,
      coachingStyle: CoachingStyle.fromStorage(map['coachingStyle'] as String?),
      lastChangedAtMs: (map['lastChangedAtMs'] as num?)?.toInt() ?? 0,
      onboardingCompletedAtMs:
          (map['onboardingCompletedAtMs'] as num?)?.toInt(),
      styleChangeHistory: history,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kUserCoachingProfileSchemaVersion,
    );
  }

  UserCoachingProfile copyWith({
    CoachingStyle? coachingStyle,
    int? lastChangedAtMs,
    int? onboardingCompletedAtMs,
    List<StyleChangeEntry>? styleChangeHistory,
    int? updatedAtMs,
    int? schemaVersion,
  }) => UserCoachingProfile(
    id: id,
    coachingStyle: coachingStyle ?? this.coachingStyle,
    lastChangedAtMs: lastChangedAtMs ?? this.lastChangedAtMs,
    onboardingCompletedAtMs:
        onboardingCompletedAtMs ?? this.onboardingCompletedAtMs,
    styleChangeHistory: styleChangeHistory ?? this.styleChangeHistory,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
}
