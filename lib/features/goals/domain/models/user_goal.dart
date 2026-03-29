import '../../../../core/validation/model_validators.dart';
import 'goal_categories.dart';
import 'goal_enums.dart';

/// Outcome-oriented goal (`prd-goals.md`). Period is always
/// `[periodStartMs, periodEndMs]` inclusive by **local calendar day**
/// (see [GoalPeriodHelpers]).
class UserGoal {
  const UserGoal({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.horizon,
    required this.status,
    required this.measurementKind,
    required this.targetValue,
    this.customLabel,
    required this.intensity,
    required this.periodStartMs,
    required this.periodEndMs,
    this.periodMode = GoalPeriodMode.calendar,
    this.durationDays,
    this.reminderEnabled = false,
    this.reminderMinutesFromMidnight,
    this.reminderStyle = GoalReminderStyle.dailyOnce,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String title;
  final String categoryId;
  final GoalHorizon horizon;
  final GoalStatus status;
  final MeasurementKind measurementKind;
  final double targetValue;
  final String? customLabel;
  /// 1–5 (`prd-goals.md` §4.2).
  final int intensity;
  final int periodStartMs;
  final int periodEndMs;
  /// [durationDays] is set when [periodMode] is [GoalPeriodMode.durationDays].
  final GoalPeriodMode periodMode;
  final int? durationDays;
  /// Local wall time as minutes since midnight (0–1439). Meaningful when [reminderEnabled].
  final int? reminderMinutesFromMidnight;
  final bool reminderEnabled;
  /// V1 schedules only [GoalReminderStyle.dailyOnce]; other values are stored for future work.
  final GoalReminderStyle reminderStyle;
  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'goal.id');
    ModelValidators.requireNotBlank(title, 'goal.title');
    ModelValidators.requireNotBlank(categoryId, 'goal.categoryId');
    ModelValidators.requireRange(
      value: intensity,
      min: 1,
      max: 5,
      fieldName: 'goal.intensity',
    );
    if (periodEndMs < periodStartMs) {
      throw ArgumentError('goal.periodEndMs must be >= periodStartMs');
    }
    if (reminderEnabled) {
      final m = reminderMinutesFromMidnight;
      if (m == null || m < 0 || m > 1439) {
        throw ArgumentError('goal.reminderMinutesFromMidnight must be 0..1439 when reminderEnabled');
      }
    }
  }

  UserGoal copyWith({
    String? id,
    String? title,
    String? categoryId,
    GoalHorizon? horizon,
    GoalStatus? status,
    MeasurementKind? measurementKind,
    double? targetValue,
    String? customLabel,
    int? intensity,
    int? periodStartMs,
    int? periodEndMs,
    GoalPeriodMode? periodMode,
    int? durationDays,
    bool? reminderEnabled,
    int? reminderMinutesFromMidnight,
    GoalReminderStyle? reminderStyle,
    int? createdAtMs,
    int? updatedAtMs,
  }) {
    return UserGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      horizon: horizon ?? this.horizon,
      status: status ?? this.status,
      measurementKind: measurementKind ?? this.measurementKind,
      targetValue: targetValue ?? this.targetValue,
      customLabel: customLabel ?? this.customLabel,
      intensity: intensity ?? this.intensity,
      periodStartMs: periodStartMs ?? this.periodStartMs,
      periodEndMs: periodEndMs ?? this.periodEndMs,
      periodMode: periodMode ?? this.periodMode,
      durationDays: durationDays ?? this.durationDays,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesFromMidnight: reminderMinutesFromMidnight ?? this.reminderMinutesFromMidnight,
      reminderStyle: reminderStyle ?? this.reminderStyle,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'categoryId': categoryId,
    'horizon': horizon.storageValue,
    'status': status.storageValue,
    'measurementKind': measurementKind.storageValue,
    'targetValue': targetValue,
    if (customLabel != null) 'customLabel': customLabel,
    'intensity': intensity,
    'periodStartMs': periodStartMs,
    'periodEndMs': periodEndMs,
    'periodMode': periodMode.storageValue,
    if (durationDays != null) 'durationDays': durationDays,
    'reminderEnabled': reminderEnabled,
    if (reminderMinutesFromMidnight != null) 'reminderMinutesFromMidnight': reminderMinutesFromMidnight,
    'reminderStyle': reminderStyle.storageValue,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static UserGoal fromMap(Map<String, dynamic> map) {
    final tv = map['targetValue'];
    return UserGoal(
      id: map['id'] as String,
      title: map['title'] as String,
      categoryId: map['categoryId'] as String? ?? GoalCategories.study,
      horizon: GoalHorizonStorage.fromStorage(map['horizon'] as String?),
      status: GoalStatusStorage.fromStorage(map['status'] as String?),
      measurementKind: MeasurementKindStorage.fromStorage(map['measurementKind'] as String?),
      targetValue: (tv is num) ? tv.toDouble() : double.tryParse('$tv') ?? 0,
      customLabel: map['customLabel'] as String?,
      intensity: (map['intensity'] as num?)?.toInt() ?? 3,
      periodStartMs: (map['periodStartMs'] as num?)?.toInt() ?? 0,
      periodEndMs: (map['periodEndMs'] as num?)?.toInt() ?? 0,
      periodMode: GoalPeriodModeStorage.fromStorage(map['periodMode'] as String?),
      durationDays: (map['durationDays'] as num?)?.toInt(),
      reminderEnabled: map['reminderEnabled'] as bool? ?? false,
      reminderMinutesFromMidnight: (map['reminderMinutesFromMidnight'] as num?)?.toInt(),
      reminderStyle: GoalReminderStyleStorage.fromStorage(map['reminderStyle'] as String?),
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}
