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
    required this.status,
    required this.measurementKind,
    required this.targetValue,
    this.customLabel,
    required this.intensity,
    required this.periodStartMs,
    required this.periodEndMs,
    this.periodMode = GoalPeriodMode.calendar,
    this.durationDays,
    this.repeatCadence = GoalRepeatCadence.off,
    this.repeatInterval = 1,
    this.scheduledWeekdays,
    this.repeatDaysOfMonth,
    this.reminderEnabled = false,
    this.reminderMinutesFromMidnight,
    this.reminderStyle = GoalReminderStyle.dailyOnce,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.colorHex,
  });

  final String id;
  final String title;
  final String categoryId;
  final GoalStatus status;

  /// Evaluation window, fully derived from the repeat setting — repeat is
  /// the only scheduling concept the user configures. Off = one-time goal
  /// whose target accumulates over the whole period.
  GoalHorizon get horizon => switch (repeatCadence) {
    GoalRepeatCadence.off => GoalHorizon.entireGoal,
    GoalRepeatCadence.daily => GoalHorizon.daily,
    GoalRepeatCadence.weekly => GoalHorizon.weekly,
    GoalRepeatCadence.monthly => GoalHorizon.monthly,
  };
  final MeasurementKind measurementKind;
  final double targetValue;
  final String? customLabel;

  /// Optional hex color string (e.g. `'FF5C35'`) chosen by the user.
  /// When null, the card uses the category's default color.
  final String? colorHex;

  /// 1–5 (`prd-goals.md` §4.2).
  final int intensity;
  final int periodStartMs;
  final int periodEndMs;

  /// [durationDays] is set when [periodMode] is [GoalPeriodMode.durationDays].
  final GoalPeriodMode periodMode;
  final int? durationDays;

  /// Execution recurrence. [GoalRepeatCadence.off] = passive outcome goal:
  /// no reminders/blocks/action days; progress can be logged any period day.
  final GoalRepeatCadence repeatCadence;

  /// "Every X" for the repeat cadence: X days / weeks / months. Min 1.
  final int repeatInterval;

  /// Weekdays acted on when [repeatCadence] is weekly
  /// ([DateTime.monday]=1 … [DateTime.sunday]=7).
  final List<int>? scheduledWeekdays;

  /// Days of month (1–31) acted on when [repeatCadence] is monthly.
  final List<int>? repeatDaysOfMonth;

  /// True when the goal generates planned action days at all.
  bool get hasRepeatSchedule => repeatCadence != GoalRepeatCadence.off;

  /// True when the weekly repeat restricts the goal to specific weekdays.
  bool get hasWeekdaySchedule {
    final days = scheduledWeekdays;
    return repeatCadence == GoalRepeatCadence.weekly &&
        days != null &&
        days.isNotEmpty &&
        days.length < 7;
  }

  /// Whether [day] (local) is a planned action day — drives reminders, time
  /// blocks, and Today's goals. Always false when repeat is off. Intervals
  /// anchor at the period start.
  bool isActionDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime.fromMillisecondsSinceEpoch(periodStartMs);
    final anchor = DateTime(start.year, start.month, start.day);
    switch (repeatCadence) {
      case GoalRepeatCadence.off:
        return false;
      case GoalRepeatCadence.daily:
        if (repeatInterval <= 1) return true;
        final days = d.difference(anchor).inDays;
        return days >= 0 && days % repeatInterval == 0;
      case GoalRepeatCadence.weekly:
        // Defensive: weekly with no weekdays behaves like every day.
        final days = scheduledWeekdays;
        final dayMatches =
            days == null || days.isEmpty || days.contains(d.weekday);
        return dayMatches && _weekIntervalMatches(d, anchor);
      case GoalRepeatCadence.monthly:
        final days = repeatDaysOfMonth;
        if (days == null || days.isEmpty || !days.contains(d.day)) {
          return false;
        }
        if (repeatInterval <= 1) return true;
        final months =
            (d.year - anchor.year) * 12 + (d.month - anchor.month);
        return months >= 0 && months % repeatInterval == 0;
    }
  }

  bool _weekIntervalMatches(DateTime d, DateTime anchor) {
    if (repeatInterval <= 1) return true;
    DateTime weekStart(DateTime x) =>
        DateTime(x.year, x.month, x.day).subtract(Duration(days: x.weekday - 1));
    final weeks = weekStart(d).difference(weekStart(anchor)).inDays ~/ 7;
    return weeks >= 0 && weeks % repeatInterval == 0;
  }

  /// Whether the user may log progress on [day]. Passive goals (repeat off)
  /// accept logs on any period day; repeating goals only on action days.
  bool allowsLoggingOn(DateTime day) =>
      !hasRepeatSchedule || isActionDay(day);

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
    final days = scheduledWeekdays;
    if (days != null) {
      if (days.any((d) => d < DateTime.monday || d > DateTime.sunday)) {
        throw ArgumentError('goal.scheduledWeekdays values must be 1..7');
      }
      if (days.toSet().length != days.length) {
        throw ArgumentError('goal.scheduledWeekdays must not repeat');
      }
    }
    final monthDays = repeatDaysOfMonth;
    if (monthDays != null) {
      if (monthDays.any((d) => d < 1 || d > 31)) {
        throw ArgumentError('goal.repeatDaysOfMonth values must be 1..31');
      }
      if (monthDays.toSet().length != monthDays.length) {
        throw ArgumentError('goal.repeatDaysOfMonth must not repeat');
      }
    }
    if (repeatInterval < 1) {
      throw ArgumentError('goal.repeatInterval must be >= 1');
    }
    if (reminderEnabled) {
      final m = reminderMinutesFromMidnight;
      if (m == null || m < 0 || m > 1439) {
        throw ArgumentError(
          'goal.reminderMinutesFromMidnight must be 0..1439 when reminderEnabled',
        );
      }
    }
  }

  UserGoal copyWith({
    String? id,
    String? title,
    String? categoryId,
    GoalStatus? status,
    MeasurementKind? measurementKind,
    double? targetValue,
    String? customLabel,
    int? intensity,
    int? periodStartMs,
    int? periodEndMs,
    GoalPeriodMode? periodMode,
    int? durationDays,
    GoalRepeatCadence? repeatCadence,
    int? repeatInterval,
    List<int>? scheduledWeekdays,
    List<int>? repeatDaysOfMonth,
    bool? reminderEnabled,
    int? reminderMinutesFromMidnight,
    GoalReminderStyle? reminderStyle,
    int? createdAtMs,
    int? updatedAtMs,
    String? colorHex,
  }) {
    return UserGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      measurementKind: measurementKind ?? this.measurementKind,
      targetValue: targetValue ?? this.targetValue,
      customLabel: customLabel ?? this.customLabel,
      intensity: intensity ?? this.intensity,
      periodStartMs: periodStartMs ?? this.periodStartMs,
      periodEndMs: periodEndMs ?? this.periodEndMs,
      periodMode: periodMode ?? this.periodMode,
      durationDays: durationDays ?? this.durationDays,
      repeatCadence: repeatCadence ?? this.repeatCadence,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      scheduledWeekdays: scheduledWeekdays ?? this.scheduledWeekdays,
      repeatDaysOfMonth: repeatDaysOfMonth ?? this.repeatDaysOfMonth,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesFromMidnight:
          reminderMinutesFromMidnight ?? this.reminderMinutesFromMidnight,
      reminderStyle: reminderStyle ?? this.reminderStyle,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'categoryId': categoryId,
    // Derived from repeat; still written for external readers.
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
    'repeatCadence': repeatCadence.storageValue,
    'repeatInterval': repeatInterval,
    if (scheduledWeekdays != null) 'scheduledWeekdays': scheduledWeekdays,
    if (repeatDaysOfMonth != null) 'repeatDaysOfMonth': repeatDaysOfMonth,
    'reminderEnabled': reminderEnabled,
    if (reminderMinutesFromMidnight != null)
      'reminderMinutesFromMidnight': reminderMinutesFromMidnight,
    'reminderStyle': reminderStyle.storageValue,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
    if (colorHex != null) 'colorHex': colorHex,
  };

  /// Repeat cadence for goals saved before repeat schedules existed: weekday
  /// goals were weekly routines, everything else was an implicit daily
  /// routine (reminders fired every day) — preserve that behavior.
  static GoalRepeatCadence legacyRepeatCadence(List<int>? weekdays) {
    if (weekdays != null && weekdays.isNotEmpty && weekdays.length < 7) {
      return GoalRepeatCadence.weekly;
    }
    return GoalRepeatCadence.daily;
  }

  static UserGoal fromMap(Map<String, dynamic> map) {
    final tv = map['targetValue'];
    final weekdays = (map['scheduledWeekdays'] as List?)
        ?.whereType<num>()
        .map((d) => d.toInt())
        .toList();
    return UserGoal(
      id: map['id'] as String,
      title: map['title'] as String,
      categoryId: map['categoryId'] as String? ?? GoalCategories.study,
      // 'horizon' is intentionally ignored: the window derives from repeat.
      status: GoalStatusStorage.fromStorage(map['status'] as String?),
      measurementKind: MeasurementKindStorage.fromStorage(
        map['measurementKind'] as String?,
      ),
      targetValue: (tv is num) ? tv.toDouble() : double.tryParse('$tv') ?? 0,
      customLabel: map['customLabel'] as String?,
      intensity: (map['intensity'] as num?)?.toInt() ?? 3,
      periodStartMs: (map['periodStartMs'] as num?)?.toInt() ?? 0,
      periodEndMs: (map['periodEndMs'] as num?)?.toInt() ?? 0,
      periodMode: GoalPeriodModeStorage.fromStorage(
        map['periodMode'] as String?,
      ),
      durationDays: (map['durationDays'] as num?)?.toInt(),
      repeatCadence: map['repeatCadence'] is String
          ? GoalRepeatCadenceStorage.fromStorage(map['repeatCadence'] as String)
          : legacyRepeatCadence(weekdays),
      repeatInterval: (map['repeatInterval'] as num?)?.toInt() ?? 1,
      scheduledWeekdays: weekdays,
      repeatDaysOfMonth: (map['repeatDaysOfMonth'] as List?)
          ?.whereType<num>()
          .map((d) => d.toInt())
          .toList(),
      reminderEnabled: map['reminderEnabled'] as bool? ?? false,
      reminderMinutesFromMidnight: (map['reminderMinutesFromMidnight'] as num?)
          ?.toInt(),
      reminderStyle: GoalReminderStyleStorage.fromStorage(
        map['reminderStyle'] as String?,
      ),
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
      colorHex: map['colorHex'] as String?,
    );
  }
}
