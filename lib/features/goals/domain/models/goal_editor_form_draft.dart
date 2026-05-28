import 'goal_categories.dart';
import 'goal_enums.dart';

class GoalEditorActionDraftRow {
  const GoalEditorActionDraftRow({
    this.id,
    required this.title,
    required this.completed,
  });

  final String? id;
  final String title;
  final bool completed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
      };

  factory GoalEditorActionDraftRow.fromJson(Map<String, dynamic> json) {
    return GoalEditorActionDraftRow(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
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
    required this.horizon,
    required this.periodMode,
    required this.measurement,
    required this.intensity,
    required this.monthAnchorMs,
    required this.rangeStartMs,
    required this.rangeEndMs,
    required this.durationStartMs,
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
  final String horizon;
  final String periodMode;
  final String measurement;
  final double intensity;
  final int monthAnchorMs;
  final int rangeStartMs;
  final int rangeEndMs;
  final int durationStartMs;
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
        'horizon': horizon,
        'periodMode': periodMode,
        'measurement': measurement,
        'intensity': intensity,
        'monthAnchorMs': monthAnchorMs,
        'rangeStartMs': rangeStartMs,
        'rangeEndMs': rangeEndMs,
        'durationStartMs': durationStartMs,
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
          actions.add(GoalEditorActionDraftRow.fromJson(Map<String, dynamic>.from(item)));
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
      horizon: json['horizon'] as String? ?? GoalHorizon.monthly.name,
      periodMode: json['periodMode'] as String? ?? GoalPeriodMode.calendar.name,
      measurement: json['measurement'] as String? ?? MeasurementKind.minutes.name,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 3,
      monthAnchorMs: json['monthAnchorMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      rangeStartMs: json['rangeStartMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      rangeEndMs: json['rangeEndMs'] as int? ??
          DateTime.now().add(const Duration(days: 6)).millisecondsSinceEpoch,
      durationStartMs: json['durationStartMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderMinutesFromMidnight: json['reminderMinutesFromMidnight'] as int? ?? 9 * 60,
      actions: actions,
    );
  }

  bool contentEquals(GoalEditorFormDraft other) {
    if (title != other.title ||
        target != other.target ||
        customLabel != other.customLabel ||
        durationDays != other.durationDays ||
        categoryId != other.categoryId ||
        horizon != other.horizon ||
        periodMode != other.periodMode ||
        measurement != other.measurement ||
        intensity != other.intensity ||
        monthAnchorMs != other.monthAnchorMs ||
        rangeStartMs != other.rangeStartMs ||
        rangeEndMs != other.rangeEndMs ||
        durationStartMs != other.durationStartMs ||
        reminderEnabled != other.reminderEnabled ||
        reminderMinutesFromMidnight != other.reminderMinutesFromMidnight) {
      return false;
    }
    if (actions.length != other.actions.length) return false;
    for (var i = 0; i < actions.length; i++) {
      final a = actions[i];
      final b = other.actions[i];
      if (a.id != b.id || a.title != b.title || a.completed != b.completed) {
        return false;
      }
    }
    return true;
  }
}
