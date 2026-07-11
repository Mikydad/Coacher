import 'goal_categories.dart';
import 'goal_enums.dart';

class GoalEditorActionDraftRow {
  const GoalEditorActionDraftRow({
    this.id,
    required this.title,
    required this.completed,
    this.repeatWeekdays = const [],
  });

  final String? id;
  final String title;
  final bool completed;

  /// Weekdays (1=Mon…7=Sun) the step repeats on; empty = one-time step.
  final List<int> repeatWeekdays;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
    'repeatWeekdays': repeatWeekdays,
  };

  factory GoalEditorActionDraftRow.fromJson(Map<String, dynamic> json) {
    return GoalEditorActionDraftRow(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      repeatWeekdays:
          (json['repeatWeekdays'] as List?)
              ?.whereType<num>()
              .map((d) => d.toInt())
              .toList() ??
          const [],
    );
  }
}

/// Serializable snapshot of [GoalEditorScreen] field state.
class GoalEditorFormDraft {
  const GoalEditorFormDraft({
    required this.savedAtMs,
    required this.title,
    required this.target,
    required this.customLabel,
    required this.durationDays,
    required this.categoryId,
    required this.periodMode,
    required this.measurement,
    required this.intensity,
    required this.rangeStartMs,
    required this.rangeEndMs,
    required this.durationStartMs,
    this.repeatCadence = 'off',
    this.repeatInterval = '1',
    this.scheduledWeekdays = const [],
    this.repeatDaysOfMonth = const [],
    required this.reminderEnabled,
    required this.reminderMinutesFromMidnight,
    required this.actions,
  });

  final int savedAtMs;
  final String title;
  final String target;
  final String customLabel;
  final String durationDays;
  final String categoryId;
  final String periodMode;
  final String measurement;
  final double intensity;
  final int rangeStartMs;
  final int rangeEndMs;
  final int durationStartMs;

  /// [GoalRepeatCadence] name; 'off' = no repeat schedule.
  final String repeatCadence;

  /// Raw "every X" field text.
  final String repeatInterval;

  /// Weekdays (1=Mon…7=Sun) acted on when repeat is weekly.
  final List<int> scheduledWeekdays;

  /// Days of month (1–31) acted on when repeat is monthly.
  final List<int> repeatDaysOfMonth;
  final bool reminderEnabled;
  final int reminderMinutesFromMidnight;
  final List<GoalEditorActionDraftRow> actions;

  bool get hasMeaningfulContent {
    if (title.trim().isNotEmpty) return true;
    if (target.trim().isNotEmpty) return true;
    if (customLabel.trim().isNotEmpty) return true;
    for (final a in actions) {
      if (a.title.trim().isNotEmpty) return true;
    }
    if (reminderEnabled) return true;
    if (repeatCadence != 'off') return true;
    if (scheduledWeekdays.isNotEmpty) return true;
    if (repeatDaysOfMonth.isNotEmpty) return true;
    if (categoryId != GoalCategories.study) return true;
    return false;
  }

  Map<String, dynamic> toJson() => {
    'savedAtMs': savedAtMs,
    'title': title,
    'target': target,
    'customLabel': customLabel,
    'durationDays': durationDays,
    'categoryId': categoryId,
    'periodMode': periodMode,
    'measurement': measurement,
    'intensity': intensity,
    'rangeStartMs': rangeStartMs,
    'rangeEndMs': rangeEndMs,
    'durationStartMs': durationStartMs,
    'repeatCadence': repeatCadence,
    'repeatInterval': repeatInterval,
    'scheduledWeekdays': scheduledWeekdays,
    'repeatDaysOfMonth': repeatDaysOfMonth,
    'reminderEnabled': reminderEnabled,
    'reminderMinutesFromMidnight': reminderMinutesFromMidnight,
    'actions': actions.map((a) => a.toJson()).toList(),
  };

  factory GoalEditorFormDraft.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'];
    final actions = <GoalEditorActionDraftRow>[];
    if (rawActions is List) {
      for (final item in rawActions) {
        if (item is Map<String, dynamic>) {
          actions.add(GoalEditorActionDraftRow.fromJson(item));
        } else if (item is Map) {
          actions.add(
            GoalEditorActionDraftRow.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return GoalEditorFormDraft(
      savedAtMs: json['savedAtMs'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      target: json['target'] as String? ?? '',
      customLabel: json['customLabel'] as String? ?? '',
      durationDays: json['durationDays'] as String? ?? '30',
      categoryId: json['categoryId'] as String? ?? GoalCategories.study,
      periodMode: json['periodMode'] as String? ?? GoalPeriodMode.calendar.name,
      measurement:
          json['measurement'] as String? ?? MeasurementKind.minutes.name,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 3,
      rangeStartMs:
          json['rangeStartMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      rangeEndMs:
          json['rangeEndMs'] as int? ??
          DateTime.now().add(const Duration(days: 6)).millisecondsSinceEpoch,
      durationStartMs:
          json['durationStartMs'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
      repeatCadence: json['repeatCadence'] as String? ?? 'off',
      repeatInterval: json['repeatInterval'] as String? ?? '1',
      scheduledWeekdays:
          (json['scheduledWeekdays'] as List?)
              ?.whereType<num>()
              .map((d) => d.toInt())
              .toList() ??
          const [],
      repeatDaysOfMonth:
          (json['repeatDaysOfMonth'] as List?)
              ?.whereType<num>()
              .map((d) => d.toInt())
              .toList() ??
          const [],
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderMinutesFromMidnight:
          json['reminderMinutesFromMidnight'] as int? ?? 9 * 60,
      actions: actions,
    );
  }

  bool contentEquals(GoalEditorFormDraft other) {
    if (title != other.title ||
        target != other.target ||
        customLabel != other.customLabel ||
        durationDays != other.durationDays ||
        categoryId != other.categoryId ||
        periodMode != other.periodMode ||
        measurement != other.measurement ||
        intensity != other.intensity ||
        rangeStartMs != other.rangeStartMs ||
        rangeEndMs != other.rangeEndMs ||
        durationStartMs != other.durationStartMs ||
        reminderEnabled != other.reminderEnabled ||
        reminderMinutesFromMidnight != other.reminderMinutesFromMidnight) {
      return false;
    }
    if (repeatCadence != other.repeatCadence ||
        repeatInterval != other.repeatInterval) {
      return false;
    }
    if (!_intListEquals(scheduledWeekdays, other.scheduledWeekdays) ||
        !_intListEquals(repeatDaysOfMonth, other.repeatDaysOfMonth)) {
      return false;
    }
    if (actions.length != other.actions.length) return false;
    for (var i = 0; i < actions.length; i++) {
      final a = actions[i];
      final b = other.actions[i];
      if (a.id != b.id ||
          a.title != b.title ||
          a.completed != b.completed ||
          !_intListEquals(a.repeatWeekdays, b.repeatWeekdays)) {
        return false;
      }
    }
    return true;
  }

  static bool _intListEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
