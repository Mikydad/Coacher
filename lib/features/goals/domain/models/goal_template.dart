import 'goal_enums.dart';

/// Pre-filled values for the goal editor — maps directly to existing form fields.
class GoalTemplate {
  const GoalTemplate({
    required this.id,
    required this.label,
    required this.emoji,
    this.suggestedTitle = '',
    this.categoryId,
    this.horizon,
    this.periodMode,
    this.measurement,
    this.targetValue,
    this.intensity,
    this.reminderEnabled,
    this.reminderMinutesFromMidnight,
    this.setupSteps = const [],
    this.customLabel,
  });

  final String id;
  final String label;
  final String emoji;
  final String suggestedTitle;
  final String? categoryId;
  final GoalHorizon? horizon;
  final GoalPeriodMode? periodMode;
  final MeasurementKind? measurement;
  final double? targetValue;
  final int? intensity;
  final bool? reminderEnabled;
  final int? reminderMinutesFromMidnight;
  final List<String> setupSteps;
  final String? customLabel;

  bool get isBlank => id == 'custom';
}
