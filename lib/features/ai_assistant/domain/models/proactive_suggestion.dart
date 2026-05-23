/// Types of proactive suggestions the engine can generate.
enum ProactiveSuggestionType {
  /// A recurring task that appeared ≥4/7 days is missing from today.
  recurringTaskMissing,

  /// A ≥90-min free time slot exists alongside an active goal.
  scheduleGap,

  /// High-priority tasks are ordered after low-priority ones.
  optimiseOrder,

  /// An active goal is ≥20% behind its expected pace.
  goalBehindPace,

  /// Fatigue stacking / reminder noise optimisation.
  lowEnergySlot,
}

/// A lightweight suggestion the Proactive Engine surfaces on the Home screen.
///
/// Requires user confirmation — tapping "Let's do it" only pre-fills the
/// Coach AI input; no data is changed automatically.
class ProactiveSuggestion {
  const ProactiveSuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.preDraftedInput,
    required this.confidence,
    required this.generatedAt,
    this.dismissed = false,
    this.optimisationRuleCode,
  });

  final String id;
  final ProactiveSuggestionType type;

  /// Short headline shown on the card (e.g. "You usually schedule a workout").
  final String title;

  /// One-sentence explanation for why this is being suggested.
  final String description;

  /// Text pre-filled in the Coach AI input when the user taps "Let's do it".
  final String preDraftedInput;

  /// 0.0–1.0 confidence score; used to rank suggestions.
  final double confidence;

  final DateTime generatedAt;

  /// True once the user taps "Not now".
  final bool dismissed;

  /// Set when this card came from [ScheduleOptimisationService] (A/B/C).
  /// Used for `scheduleOptimisationSuggested` analytics only.
  final String? optimisationRuleCode;

  ProactiveSuggestion copyWith({bool? dismissed}) {
    return ProactiveSuggestion(
      id: id,
      type: type,
      title: title,
      description: description,
      preDraftedInput: preDraftedInput,
      confidence: confidence,
      generatedAt: generatedAt,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  @override
  String toString() =>
      'ProactiveSuggestion(type: ${type.name}, title: $title, '
      'confidence: $confidence)';
}
