/// The context payload sent to the AI model for intent parsing.
///
/// Design rules (from PRD §4.12):
/// - All values are human-readable strings or simplified maps.
/// - No raw Firestore document IDs.
/// - No internal object references or schema field names.
class AiOperatingLayerPayload {
  const AiOperatingLayerPayload({
    required this.userInput,
    this.activeTasks = const [],
    this.goals = const [],
    this.todaySchedule = const [],
    this.focusState = const {},
    this.contextOverride,
    this.behaviorPreferences = const {},
    this.sessionHistory = const [],
  });

  /// The raw user input for this turn.
  final String userInput;

  /// Today's tasks — each entry: { title, time, duration, status }.
  final List<Map<String, dynamic>> activeTasks;

  /// Active goals — each entry: { title, target, deadline }.
  final List<Map<String, dynamic>> goals;

  /// Today's time blocks — each entry: { title, startTime, endTime }.
  final List<Map<String, dynamic>> todaySchedule;

  /// Current focus/flow state.
  final Map<String, dynamic> focusState;

  /// Active context override (null if none active).
  final Map<String, dynamic>? contextOverride;

  /// Coaching style, default enforcement mode, preferences.
  final Map<String, dynamic> behaviorPreferences;

  /// Last ≤10 user↔AI exchanges for multi-turn context.
  /// Each entry: { role: 'user'|'assistant', content: String }.
  final List<Map<String, dynamic>> sessionHistory;

  Map<String, dynamic> toJson() => {
        'userInput': userInput,
        'activeTasks': activeTasks,
        'goals': goals,
        'todaySchedule': todaySchedule,
        'focusState': focusState,
        if (contextOverride != null) 'contextOverride': contextOverride,
        'behaviorPreferences': behaviorPreferences,
        'sessionHistory': sessionHistory,
      };
}
