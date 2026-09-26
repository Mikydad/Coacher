/// The context payload sent to the AI model for intent parsing.
///
/// Design rules (from PRD §4.12):
/// - All values are human-readable strings or simplified maps.
/// - No raw Firestore document IDs.
/// - No internal object references or schema field names.
class AiOperatingLayerPayload {
  AiOperatingLayerPayload({
    required this.userInput,
    this.activeTasks = const [],
    this.goals = const [],
    this.todaySchedule = const [],
    this.tomorrowTasks = const [],
    this.tomorrowSchedule = const [],
    this.weekOverview = const [],
    this.focusState = const {},
    this.contextOverride,
    this.behaviorPreferences = const {},
    this.sessionHistory = const [],
    this.recentPatterns = const [],
    this.conversationHistory = const [],
    this.completedInSession = const [],
    this.goalProgress = const [],
    this.capabilities = const {},
    this.intentHint,
    this.intentKind,
    this.proactiveContext,
    this.previousPlan,
    this.todayFreeWindows = const [],
    this.tomorrowFreeWindows = const [],
    this.featureGuide,
    this.memoryFacts = const [],
    this.peopleDigest = const [],
    this.episodicSummaries = const [],
    this.openPromises = const [],
    this.deviceContext = const [],
    this.direction = const [],
    this.todayActivityLog = const [],
    this.voiceMode = false,
    this.retryTurnId,
    this.todayCalendarAvailable,
    this.tomorrowCalendarAvailable,
    this.wakingWindow,
    this.taskHandles = const {},
    this.goalHandles = const {},
  });

  /// Calendar signal availability per day (fix plan Phase 3.2): true =
  /// busy intervals merged into that day's free windows; false = the
  /// signal was unavailable (denied, no channel, failed) and the windows
  /// come from the plan alone; null = the app has no calendar bridge.
  final bool? todayCalendarAvailable;
  final bool? tomorrowCalendarAvailable;

  /// "07:00–22:00" — the waking bounds the free windows were computed in
  /// (per user from the sleep window when set, D3).
  final String? wakingWindow;

  /// Opaque per-turn handles (D2): "t1" → the task it stands for. Never
  /// persisted, never a database id; the resolver maps a `taskRef` back.
  final Map<String, AiTaskHandle> taskHandles;
  final Map<String, AiGoalHandle> goalHandles;

  /// Set by [AiIntentParser] when this turn RETRIES a failed one: the
  /// client reuses this turnId (rounds at loopIndex >= 1) so the server's
  /// same-turn window makes the retry quota-free (fix-wave Phase 3).
  /// Mutable by design — the payload is assembled before the parser knows
  /// whether the turn is a retry.
  String? retryTurnId;

  /// The raw user input for this turn.
  final String userInput;

  /// Today's tasks — each entry: { title, time, duration, status }.
  final List<Map<String, dynamic>> activeTasks;

  /// Active goals — each entry: { title, target, deadline }.
  final List<Map<String, dynamic>> goals;

  /// Today's time blocks — each entry: { title, startTime, endTime }.
  final List<Map<String, dynamic>> todaySchedule;

  /// Tomorrow's tasks — same shape as [activeTasks].
  final List<Map<String, dynamic>> tomorrowTasks;

  /// Tomorrow's scheduled blocks — same shape as [todaySchedule].
  final List<Map<String, dynamic>> tomorrowSchedule;

  /// Next 7 days — each entry: { date, label, taskCount, scheduledCount }.
  final List<Map<String, dynamic>> weekOverview;

  /// Current focus/flow state.
  final Map<String, dynamic> focusState;

  /// Active context override (null if none active).
  final Map<String, dynamic>? contextOverride;

  /// Coaching style, default enforcement mode, preferences.
  final Map<String, dynamic> behaviorPreferences;

  /// Last ≤10 user↔AI exchanges for multi-turn context.
  final List<Map<String, dynamic>> sessionHistory;

  /// Top 5 recurring activity patterns from the last 14 days.
  final List<Map<String, dynamic>> recentPatterns;

  /// Full session conversation history as OpenAI-compatible role/content pairs.
  final List<Map<String, dynamic>> conversationHistory;

  /// Human-readable summaries of changes already confirmed in this session.
  final List<String> completedInSession;

  /// Active goals with progress in their CURRENT evaluation window, in the
  /// goal's own units (fix plan Phase 3.1). Each entry: { ref, title,
  /// logged, target, unit, window, daysLogged, daysElapsed, daysInWindow,
  /// behindPace, cadence, category, stepsDueToday }.
  final List<Map<String, dynamic>> goalProgress;

  /// Supported / unsupported capability lists for the model.
  final Map<String, dynamic> capabilities;

  /// Router hint — QUERY, SUGGEST, or MUTATE with optional focus date.
  final String? intentHint;

  /// Router classification name ("query" | "suggest" | "mutate") — used to
  /// pick the model temperature per turn.
  final String? intentKind;

  /// Proactive suggestion that led the user into this session (if any).
  final Map<String, dynamic>? proactiveContext;

  /// The previous plan when the user is refining an earlier intent.
  final String? previousPlan;

  /// Human-readable free windows for today, e.g. "14:00–16:30 (2h 30m)".
  final List<String> todayFreeWindows;

  /// Human-readable free windows for tomorrow — same shape as
  /// [todayFreeWindows].
  final List<String> tomorrowFreeWindows;

  /// Compact app documentation for the ONE feature the user asked about
  /// (see FeatureGuides.matchTopic) — grounds "what is X?" teaching answers.
  final String? featureGuide;

  /// Long-term memory facts, prerendered as grounded lines:
  /// `[mem:<id>|<label>] content`. The mem-id is the ONE deliberate
  /// exception to the "no raw IDs" rule — it is the grounding contract
  /// (PRD §5.3): the model cites it, the app renders the citation as a
  /// tappable "from your memory" affordance.
  final List<String> memoryFacts;

  /// People in the user's life — e.g. "Sarah (sister) — last interaction
  /// 12 days ago".
  final List<String> peopleDigest;

  /// Latest episodic summaries (summarize-then-purge output), newest first.
  final List<String> episodicSummaries;

  /// Open + dormant intentions, so the Coach never re-captures a promise
  /// it already holds.
  final List<String> openPromises;

  /// Coarse ContextSnapshot labels (Phase 4b, PRD §9): "free_25m",
  /// "next_calendar_event_14:00", "mode_focus", "offline". NEVER raw
  /// signals — no event contents, no locations, no identifiers.
  final List<String> deviceContext;

  /// The user's Direction (PRD/Direction, 2026-09-11): what they say
  /// matters this year / quarter / month, in their own words, e.g.
  /// "This month (September): Get SidePal ready for launch". CURRENT
  /// periods only — a previous period is never sent as context (history
  /// ≠ current direction). Empty when nothing is set. Context, not a
  /// command: the prompt tells the model to reason with it quietly.
  final List<String> direction;

  /// Today's Time Tracker timeline (V1.1): what the user actually did,
  /// recorded not planned — e.g. "10:03–10:09 Scrolling · 6m",
  /// "? · 3h 51m untracked", tail "Logged 8h 42m · untracked 3h 51m".
  /// Per-turn, max 25 rows. Empty when nothing was logged today.
  final List<String> todayActivityLog;

  /// This turn arrived by voice and the reply will be spoken aloud
  /// (latency batch 2026-08-07): the client routes it through the
  /// `coach_agent_voice` purpose and adds the short-spoken-reply prompt
  /// addendum. Never serialized — it shapes the call, not the context.
  final bool voiceMode;

  Map<String, dynamic> toJson() => {
    'userInput': userInput,
    'activeTasks': activeTasks,
    'goals': goals,
    'todaySchedule': todaySchedule,
    'tomorrowTasks': tomorrowTasks,
    'tomorrowSchedule': tomorrowSchedule,
    if (weekOverview.isNotEmpty) 'weekOverview': weekOverview,
    'focusState': focusState,
    if (contextOverride != null) 'contextOverride': contextOverride,
    'behaviorPreferences': behaviorPreferences,
    'sessionHistory': sessionHistory,
    if (recentPatterns.isNotEmpty) 'recentPatterns': recentPatterns,
    if (conversationHistory.isNotEmpty)
      'conversationHistory': conversationHistory,
    if (completedInSession.isNotEmpty) 'completedInSession': completedInSession,
    if (goalProgress.isNotEmpty) 'goalProgress': goalProgress,
    if (capabilities.isNotEmpty) 'capabilities': capabilities,
    if (intentHint != null) 'intentHint': intentHint,
    if (intentKind != null) 'intentKind': intentKind,
    if (proactiveContext != null) 'proactiveContext': proactiveContext,
    if (previousPlan != null) 'previousPlan': previousPlan,
    if (todayFreeWindows.isNotEmpty) 'todayFreeWindows': todayFreeWindows,
    if (tomorrowFreeWindows.isNotEmpty)
      'tomorrowFreeWindows': tomorrowFreeWindows,
    if (featureGuide != null) 'featureGuide': featureGuide,
    if (memoryFacts.isNotEmpty) 'memoryFacts': memoryFacts,
    if (peopleDigest.isNotEmpty) 'peopleDigest': peopleDigest,
    if (episodicSummaries.isNotEmpty) 'episodicSummaries': episodicSummaries,
    if (openPromises.isNotEmpty) 'openPromises': openPromises,
    if (deviceContext.isNotEmpty) 'deviceContext': deviceContext,
    if (direction.isNotEmpty) 'direction': direction,
    if (todayActivityLog.isNotEmpty) 'todayActivityLog': todayActivityLog,
    if (todayCalendarAvailable != null)
      'todayCalendarAvailable': todayCalendarAvailable,
    if (tomorrowCalendarAvailable != null)
      'tomorrowCalendarAvailable': tomorrowCalendarAvailable,
    if (wakingWindow != null) 'wakingWindow': wakingWindow,
  };
}

/// What a per-turn task handle stands for — enough for the resolver to
/// stamp the action without a lookup.
class AiTaskHandle {
  const AiTaskHandle({
    required this.taskId,
    required this.routineId,
    required this.blockId,
    required this.dateKey,
    required this.title,
  });

  final String taskId;
  final String routineId;
  final String blockId;
  final String dateKey;
  final String title;
}

class AiGoalHandle {
  const AiGoalHandle({required this.goalId, required this.title});

  final String goalId;
  final String title;
}
