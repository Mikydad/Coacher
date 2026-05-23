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
    this.recentPatterns = const [],
    this.conversationHistory = const [],
    this.completedInSession = const [],
    this.previousPlan,
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

  /// Top 5 recurring activity patterns from the last 14 days.
  /// Each entry: { category, lastUsedTime, lastUsedDuration, frequency }.
  /// Helps the model understand the user's schedule rhythm.
  final List<Map<String, dynamic>> recentPatterns;

  /// Full session conversation history as OpenAI-compatible role/content pairs.
  /// Each entry: { role: 'user'|'assistant', content: String }.
  /// Used by the client as preceding messages for multi-turn context.
  final List<Map<String, dynamic>> conversationHistory;

  /// Human-readable summaries of changes already confirmed in this session.
  /// Tells the model not to re-plan or re-ask about these items.
  final List<String> completedInSession;

  /// The previous plan when the user is refining an earlier intent.
  /// Serialised as a human-readable string for the AI prompt.
  final String? previousPlan;

  Map<String, dynamic> toJson() => {
        'userInput': userInput,
        'activeTasks': activeTasks,
        'goals': goals,
        'todaySchedule': todaySchedule,
        'focusState': focusState,
        if (contextOverride != null) 'contextOverride': contextOverride,
        'behaviorPreferences': behaviorPreferences,
        'sessionHistory': sessionHistory,
        if (recentPatterns.isNotEmpty) 'recentPatterns': recentPatterns,
        if (conversationHistory.isNotEmpty) 'conversationHistory': conversationHistory,
        if (completedInSession.isNotEmpty) 'completedInSession': completedInSession,
        if (previousPlan != null) 'previousPlan': previousPlan,
      };
}
