import '../../../core/utils/stable_id.dart';
import '../domain/models/intention.dart';

/// A parsed-but-not-yet-committed intention. Produced by the offline
/// heuristic parser, the quick-add sheet, or the AI `create_intention`
/// action — all three funnel through [buildIntention].
class IntentionDraft {
  const IntentionDraft({
    required this.title,
    required this.rawUtterance,
    required this.windowStart,
    required this.windowEnd,
    this.estimatedMinutes = 20,
    this.importance = IntentionImportance.normal,
    this.activityTags = const [],
    this.aiHintsJson,
  });

  final String title;
  final String rawUtterance;
  final DateTime windowStart;
  final DateTime windowEnd;
  final int estimatedMinutes;
  final IntentionImportance importance;
  final List<String> activityTags;
  final String? aiHintsJson;
}

/// Builds the synced record from a draft. IDs are client-generated,
/// `updatedAtMs` stamped at write (CLAUDE.md hard rules).
Intention buildIntention(IntentionDraft draft, {DateTime? now}) {
  final ts = (now ?? DateTime.now()).millisecondsSinceEpoch;
  return Intention(
    id: StableId.generate('intention'),
    title: draft.title,
    rawUtterance: draft.rawUtterance,
    windowStartMs: draft.windowStart.millisecondsSinceEpoch,
    windowEndMs: draft.windowEnd.millisecondsSinceEpoch,
    estimatedMinutes: draft.estimatedMinutes,
    importance: draft.importance,
    activityTags: draft.activityTags,
    aiHintsJson: draft.aiHintsJson,
    createdAtMs: ts,
    updatedAtMs: ts,
  );
}

/// Named deadline windows with waking-window defaults (PRD §4.1:
/// "tomorrow" → 08:00–21:00, never midnight edges).
enum IntentionWindowKind { today, tomorrow, thisWeek, weekend }

/// Resolves a window kind to concrete bounds from [now].
({DateTime start, DateTime end}) resolveIntentionWindow(
  IntentionWindowKind kind,
  DateTime now,
) {
  DateTime dayAt(DateTime d, int hour, [int minute = 0]) =>
      DateTime(d.year, d.month, d.day, hour, minute);
  switch (kind) {
    case IntentionWindowKind.today:
      final end = dayAt(now, 21);
      // Past 20:00 "today" honestly means tomorrow — never a midnight edge.
      if (now.isAfter(dayAt(now, 20))) {
        final t = now.add(const Duration(days: 1));
        return (start: dayAt(t, 8), end: dayAt(t, 21));
      }
      return (start: now, end: end);
    case IntentionWindowKind.tomorrow:
      final t = now.add(const Duration(days: 1));
      return (start: dayAt(t, 8), end: dayAt(t, 21));
    case IntentionWindowKind.thisWeek:
      final daysToSunday = DateTime.sunday - now.weekday;
      final sunday = now.add(Duration(days: daysToSunday <= 0 ? 7 : daysToSunday));
      return (start: now, end: dayAt(sunday, 21));
    case IntentionWindowKind.weekend:
      var daysToSaturday = DateTime.saturday - now.weekday;
      if (daysToSaturday < 0) daysToSaturday += 7;
      final saturday = now.add(Duration(days: daysToSaturday));
      final sunday = saturday.add(const Duration(days: 1));
      final start = daysToSaturday == 0 ? now : dayAt(saturday, 8);
      return (start: start, end: dayAt(sunday, 21));
  }
}

/// Offline heuristic parser (PRD §4.2): handles simple forms with a clear
/// action + time phrase; anything it can't parse returns null and the
/// caller opens the 3-field quick-add sheet. Never guesses a window.
class IntentionHeuristicParser {
  const IntentionHeuristicParser._();

  static final RegExp _leadIn = RegExp(
    r'^(i need to|i want to|i have to|i should|remind me to|'
    r"i'll|i will|don't let me forget to|i promised .{0,30}?(i'd|to))\s+",
    caseSensitive: false,
  );

  static IntentionDraft? parse(String utterance, {DateTime? clock}) {
    final now = clock ?? DateTime.now();
    final trimmed = utterance.trim();
    if (trimmed.isEmpty || trimmed.length > 200) return null;

    final windowKind = _windowKindOf(trimmed);
    if (windowKind == null) return null; // no time phrase → quick-add sheet

    var action = trimmed.replaceFirst(_leadIn, '');
    action = _stripTimePhrase(action).trim();
    if (action.isEmpty || action.split(' ').length < 2) return null;

    final tags = _tagsOf(action);
    final window = resolveIntentionWindow(windowKind, now);
    return IntentionDraft(
      title: _titleCase(action),
      rawUtterance: utterance,
      windowStart: window.start,
      windowEnd: window.end,
      estimatedMinutes: _estimateMinutes(tags),
      activityTags: tags,
    );
  }

  /// [parse] result as `createIntention` action parameters — the offline
  /// fallback in the Coach chat funnels through the same executor path the
  /// online AI uses.
  static Map<String, dynamic>? parseToActionParams(
    String utterance, {
    DateTime? clock,
  }) {
    final draft = parse(utterance, clock: clock);
    if (draft == null) return null;
    final kind = _windowKindOf(utterance)!; // parse() != null implies a kind
    return {
      'title': draft.title,
      'rawUtterance': utterance,
      'window': switch (kind) {
        IntentionWindowKind.today => 'today',
        IntentionWindowKind.tomorrow => 'tomorrow',
        IntentionWindowKind.thisWeek => 'this_week',
        IntentionWindowKind.weekend => 'weekend',
      },
      'estimatedMinutes': draft.estimatedMinutes,
      'activityTags': draft.activityTags,
    };
  }

  static IntentionWindowKind? _windowKindOf(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('tomorrow')) return IntentionWindowKind.tomorrow;
    if (lower.contains('tonight') || lower.contains('today')) {
      return IntentionWindowKind.today;
    }
    if (lower.contains('this weekend')) return IntentionWindowKind.weekend;
    if (lower.contains('this week')) return IntentionWindowKind.thisWeek;
    return null;
  }

  static String _stripTimePhrase(String text) {
    return text.replaceAll(
      RegExp(
        r'\b(tomorrow|tonight|today|this weekend|this week)\b',
        caseSensitive: false,
      ),
      '',
    ).replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<String> _tagsOf(String action) {
    final lower = action.toLowerCase();
    if (RegExp(r'\b(call|phone|ring)\b').hasMatch(lower)) return ['call'];
    if (RegExp(r'\b(send|email|message|text|reply)\b').hasMatch(lower)) {
      return ['message', 'quick'];
    }
    if (RegExp(r'\b(buy|pick up|get|grab)\b').hasMatch(lower)) {
      return ['errand'];
    }
    return const [];
  }

  static int _estimateMinutes(List<String> tags) {
    if (tags.contains('call')) return 15;
    if (tags.contains('message')) return 10;
    if (tags.contains('errand')) return 30;
    return 20;
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
