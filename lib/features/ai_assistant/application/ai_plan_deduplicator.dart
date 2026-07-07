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
    if (isRefiningPreviousPlan || actions.isEmpty || activeTasks.isEmpty) {
      return actions;
    }

    return actions
        .where((a) => !_isRedundant(a, activeTasks, userInput))
        .toList();
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
    final needle = _normalize(title);
    for (final t in activeTasks) {
      final taskTitle = t['title'] as String?;
      if (taskTitle != null && _normalize(taskTitle) == needle) {
        return t;
      }
    }
    return null;
  }

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
