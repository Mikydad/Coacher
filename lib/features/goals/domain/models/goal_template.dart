import 'goal_enums.dart';

/// Pre-filled values for the goal editor — maps directly to existing form fields.
class GoalTemplate {
  const GoalTemplate({
    required this.id,
    required this.label,
    required this.emoji,
    this.suggestedTitle = '',
    this.categoryId,
    this.repeatCadence,
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

  /// Suggested repeat setting; also defines the target's measuring window.
  final GoalRepeatCadence? repeatCadence;
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
