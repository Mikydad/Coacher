import '../domain/models/ai_action.dart';

/// Removes actions that duplicate tasks already on today's schedule.
///
/// The model often re-suggests earlier reminders when [activeTasks] already
/// lists them. This keeps each turn to net-new changes only.
class AiPlanDeduplicator {
  const AiPlanDeduplicator._();

  static List<AiAction> filter(
    List<AiAction> actions,
    List<Map<String, dynamic>> activeTasks,
    String userInput, {
    bool isRefiningPreviousPlan = false,
  }) {
    if (isRefiningPreviousPlan || actions.isEmpty) {
      return actions;
    }

    // Within-plan dedupe first: the model has proposed the same task twice
    // in one plan under cosmetically different titles ("Create Flutter
    // to-do list" + "create flutter todo list").
    final kept = <AiAction>[];
    final seenCreateTitles = <String>[];
    for (final a in actions) {
      if (a.actionType == ActionType.createTask) {
        final title = _actionTitle(a);
        if (title != null && title.isNotEmpty) {
          final squashed = _squash(title);
          if (seenCreateTitles.any((s) => _fuzzyEquals(s, squashed))) {
            continue;
          }
          seenCreateTitles.add(squashed);
        }
      }
      kept.add(a);
    }

    if (activeTasks.isEmpty) return kept;
    return kept.where((a) => !_isRedundant(a, activeTasks, userInput)).toList();
  }

  static bool _isRedundant(
    AiAction action,
    List<Map<String, dynamic>> activeTasks,
    String userInput,
  ) {
    switch (action.actionType) {
      case ActionType.createTask:
      case ActionType.addReminder:
      case ActionType.rescheduleReminder:
        break;
      default:
        return false;
    }

    final title = _actionTitle(action);
    if (title == null || title.isEmpty) return false;

    if (_userExplicitlyTargetsTask(userInput, title)) return false;

    final existing = _findActiveTask(activeTasks, title);
    if (existing == null) return false;

    switch (action.actionType) {
      case ActionType.createTask:
        return true;
      case ActionType.addReminder:
      case ActionType.rescheduleReminder:
        final requestedTime = _actionTime(action);
        final existingTime = _normalizeTime(existing['time'] as String?);
        if (existingTime == null || existingTime == 'no time set') {
          return false;
        }
        if (requestedTime == null) return true;
        return _timesMatch(existingTime, requestedTime);
      default:
        return false;
    }
  }

  static Map<String, dynamic>? _findActiveTask(
    List<Map<String, dynamic>> activeTasks,
    String title,
  ) {
    final needle = _squash(title);
    for (final t in activeTasks) {
      final taskTitle = t['title'] as String?;
      if (taskTitle != null && _fuzzyEquals(_squash(taskTitle), needle)) {
        return t;
      }
    }
    return null;
  }

  /// Punctuation/spacing-insensitive title identity with a small typo
  /// budget: "Create Flutter to-do list" ≡ "create flutter todo list",
  /// "finish the app erros" ≡ "Finish the app errors". Exact matching
  /// missed all of these and duplicates sailed through (2026-08-22).
  static bool _fuzzyEquals(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.length < 8 || b.length < 8) return false;
    if ((a.length - b.length).abs() > 2) return false;
    return _editDistance(a, b) <= 2;
  }

  static int _editDistance(String a, String b) {
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final substitution = prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
        current[j] = [
          prev[j] + 1,
          current[j - 1] + 1,
          substitution,
        ].reduce((x, y) => x < y ? x : y);
      }
      prev = current;
    }
    return prev[b.length];
  }

  /// Lowercase alphanumerics only — spacing, hyphens, and punctuation are
  /// exactly the cosmetic differences duplicate titles arrive with.
  static String _squash(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static String? _actionTitle(AiAction action) {
    final p = action.parameters;
    return (p['taskTitle'] as String?)?.trim().isNotEmpty == true
        ? (p['taskTitle'] as String).trim()
        : (p['title'] as String?)?.trim().isNotEmpty == true
        ? (p['title'] as String).trim()
        : null;
  }

  static String? _actionTime(AiAction action) {
    final p = action.parameters;
    final raw = p['reminderTime'] as String? ?? p['time'] as String?;
    return _normalizeTime(raw);
  }

  static String? _normalizeTime(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'no time set') return null;
    return raw.trim();
  }

  static bool _timesMatch(String a, String b) {
    final na = _normalizeTime(a);
    final nb = _normalizeTime(b);
    if (na == null || nb == null) return false;
    if (na == nb) return true;
    // 15:00 vs 3:00 pm style — compare hour:minute when parseable
    final pa = _parseHm(na);
    final pb = _parseHm(nb);
    if (pa != null && pb != null) {
      return pa.$1 == pb.$1 && pa.$2 == pb.$2;
    }
    return false;
  }

  static (int, int)? _parseHm(String s) {
    final lower = s.toLowerCase();
    var hour = int.tryParse(lower.split(':').first) ?? -1;
    var minute = 0;
    final parts = lower.split(':');
    if (parts.length > 1) {
      final minPart = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
      minute = int.tryParse(minPart) ?? 0;
    }
    if (hour < 0) return null;
    if (lower.contains('pm') && hour < 12) hour += 12;
    if (lower.contains('am') && hour == 12) hour = 0;
    return (hour, minute);
  }

  static bool _userExplicitlyTargetsTask(String userInput, String title) {
    final hay = _normalize(userInput);
    final needle = _normalize(title);
    if (needle.isEmpty) return false;
    if (hay.contains(needle)) return true;
    // "meeting" in "the meeting reminder"
    final words = needle.split(RegExp(r'\s+'));
    if (words.length == 1 && words.first.length >= 4) {
      return hay.contains(words.first);
    }
    return false;
  }

  static String _normalize(String s) => s.toLowerCase().trim();
}
