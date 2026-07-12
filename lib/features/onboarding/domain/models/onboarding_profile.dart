import '../../../../core/validation/model_validators.dart';

const int kOnboardingProfileSchemaVersion = 1;
const String kOnboardingProfileId = 'onboarding_profile';

/// Stable keys for the "Which of these do you struggle with?" selections
/// (ONBOARDING_PRD.md Screen 2). Stored keys, never display text.
abstract final class OnboardingStruggles {
  static const forgetting = 'forgetting_things';
  static const planningNoAction = 'planning_no_action';
  static const procrastination = 'procrastination';
  static const difficultyFocusing = 'difficulty_focusing';
  static const gettingDistracted = 'getting_distracted';
  static const losingMotivation = 'losing_motivation';
  static const overplanning = 'overplanning';
  static const notKnowingNext = 'not_knowing_next';
  static const neverFinishing = 'never_finishing';
  static const needAccountability = 'need_accountability';

  static const all = [
    forgetting,
    planningNoAction,
    procrastination,
    difficultyFocusing,
    gettingDistracted,
    losingMotivation,
    overplanning,
    notKnowingNext,
    neverFinishing,
    needAccountability,
  ];
}

/// Stable keys for the "What do you want to achieve first?" goal categories
/// (ONBOARDING_PRD.md Screen 10). Interest tags, NOT auto-created goals —
/// the AI / goal-creation flows consume them later (decision log 2026-07-12).
abstract final class OnboardingInterests {
  static const buildBusiness = 'build_business';
  static const improveHealth = 'improve_health';
  static const learnSkills = 'learn_skills';
  static const getOrganized = 'get_organized';
  static const makeMoney = 'make_money';
  static const betterHabits = 'better_habits';
  static const moreDisciplined = 'more_disciplined';

  static const all = [
    buildBusiness,
    improveHealth,
    learnSkills,
    getOrganized,
    makeMoney,
    betterHabits,
    moreDisciplined,
  ];
}

/// Single-record model holding what the user told us during onboarding:
/// struggle selections (Screen 2) and goal-category interests (Screen 10),
/// plus completion metadata. Same `id + payloadJson` single-record pattern
/// as [UserProfilePreference], but fully synced (outbox + merge phase).
class OnboardingProfile {
  const OnboardingProfile({
    required this.id,
    this.struggles = const <String>[],
    this.interests = const <String>[],
    this.skippedOnboarding = false,
    this.registeredDuringOnboarding = false,
    this.completedAtMs = 0,
    this.dayOnePhotoLocalPath,
    this.dayOnePhotoTakenAtMs,
    required this.updatedAtMs,
    this.schemaVersion = kOnboardingProfileSchemaVersion,
  });

  /// Always [kOnboardingProfileId] — single-record pattern.
  final String id;

  /// Selected [OnboardingStruggles] keys, in selection order.
  final List<String> struggles;

  /// Selected [OnboardingInterests] keys, in selection order.
  final List<String> interests;

  /// True when the user exited via the flow-level Skip (straight to the
  /// anonymous account) — no record is written in that case today, but the
  /// field exists so a later partial-write policy can express it.
  final bool skippedOnboarding;

  /// True when the account was created on the onboarding registration step
  /// (as opposed to logging into an existing account or guest mode).
  final bool registeredDuringOnboarding;

  /// 0 until the user reaches "Start My Journey".
  final int completedAtMs;

  /// Absolute path of the "Day One" photo ON THE DEVICE THAT TOOK IT
  /// (Screen 8). The file itself does not sync in v1 — other devices must
  /// treat a non-existent path as "no photo".
  final String? dayOnePhotoLocalPath;

  /// When the Day One photo was captured; survives sync even though the
  /// file does not, so future devices can still say "your journey started
  /// on …".
  final int? dayOnePhotoTakenAtMs;

  final int updatedAtMs;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(id, 'onboardingProfile.id');
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'onboardingProfile.schemaVersion',
    );
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'struggles': struggles,
    'interests': interests,
    'skippedOnboarding': skippedOnboarding,
    'registeredDuringOnboarding': registeredDuringOnboarding,
    'completedAtMs': completedAtMs,
    if (dayOnePhotoLocalPath != null)
      'dayOnePhotoLocalPath': dayOnePhotoLocalPath,
    if (dayOnePhotoTakenAtMs != null)
      'dayOnePhotoTakenAtMs': dayOnePhotoTakenAtMs,
    'updatedAtMs': updatedAtMs,
    'schemaVersion': schemaVersion,
  };

  static OnboardingProfile fromMap(Map<String, dynamic> map) =>
      OnboardingProfile(
        id: map['id'] as String? ?? kOnboardingProfileId,
        struggles: _parseStringList(map['struggles']),
        interests: _parseStringList(map['interests']),
        skippedOnboarding: map['skippedOnboarding'] as bool? ?? false,
        registeredDuringOnboarding:
            map['registeredDuringOnboarding'] as bool? ?? false,
        completedAtMs: (map['completedAtMs'] as num?)?.toInt() ?? 0,
        dayOnePhotoLocalPath: map['dayOnePhotoLocalPath'] as String?,
        dayOnePhotoTakenAtMs: (map['dayOnePhotoTakenAtMs'] as num?)?.toInt(),
        updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
        schemaVersion:
            (map['schemaVersion'] as num?)?.toInt() ??
            kOnboardingProfileSchemaVersion,
      );

  OnboardingProfile copyWith({
    List<String>? struggles,
    List<String>? interests,
    bool? skippedOnboarding,
    bool? registeredDuringOnboarding,
    int? completedAtMs,
    String? dayOnePhotoLocalPath,
    int? dayOnePhotoTakenAtMs,
    int? updatedAtMs,
    int? schemaVersion,
  }) => OnboardingProfile(
    id: id,
    struggles: struggles ?? this.struggles,
    interests: interests ?? this.interests,
    skippedOnboarding: skippedOnboarding ?? this.skippedOnboarding,
    registeredDuringOnboarding:
        registeredDuringOnboarding ?? this.registeredDuringOnboarding,
    completedAtMs: completedAtMs ?? this.completedAtMs,
    dayOnePhotoLocalPath: dayOnePhotoLocalPath ?? this.dayOnePhotoLocalPath,
    dayOnePhotoTakenAtMs: dayOnePhotoTakenAtMs ?? this.dayOnePhotoTakenAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
}

List<String> _parseStringList(Object? raw) {
  if (raw is! List) return const <String>[];
  return raw.map((e) => '$e').toList(growable: false);
}
