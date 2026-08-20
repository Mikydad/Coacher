import '../domain/models/ai_action.dart';

/// Canonicalizes model-emitted action parameters at ingestion.
///
/// The app's contract is exact keys and formats — createTask needs
/// `title`, `time` ("HH:mm" 24-hour), `duration` (minutes int) — but LLMs
/// drift: `startTime`, `"2 pm"`, `"14:00–15:00"`, `durationMinutes`.
/// Before this pass existed, drift fell through to AiMissingFieldDetector,
/// which asked "What time should I schedule it?" even when the user had
/// just said "at 2 pm" — the clarify-loop bug (deep check 2026-08-20).
/// Normalizing once here keeps the detector and the executor contract
/// stable no matter how the model words its payload.
abstract final class AiActionParamNormaliser {
  /// Alias keys per canonical key, per action type. The canonical key wins
  /// when already present and non-blank; aliases only FILL, never stomp.
  static const Map<ActionType, Map<String, List<String>>> _aliases = {
    ActionType.createTask: _taskAliases,
    ActionType.editTask: _taskAliases,
    ActionType.moveTask: {
      'taskTitle': ['title', 'task', 'name', 'taskName'],
      'destinationDate': ['date', 'day', 'destination', 'newDate', 'toDate'],
    },
    ActionType.deleteTask: {
      'taskTitle': ['title', 'task', 'name', 'taskName'],
    },
    ActionType.createGoal: {
      'title': ['name', 'goal', 'goalTitle'],
      'target': ['goalTarget'],
      'deadline': ['dueDate', 'due', 'by'],
    },
    ActionType.modifyGoal: {
      'goalTitle': ['title', 'goal', 'name'],
      'newValue': ['value'],
    },
    ActionType.deleteGoal: {
      'goalTitle': ['title', 'goal', 'name'],
    },
    ActionType.addReminder: _reminderAliases,
    ActionType.rescheduleReminder: _reminderAliases,
    ActionType.removeReminder: {
      'taskTitle': ['title', 'task', 'name', 'taskName'],
    },
  };

  static const Map<String, List<String>> _taskAliases = {
    'title': ['task', 'name', 'taskName', 'taskTitle'],
    'time': [
      'startTime',
      'start_time',
      'start',
      'at',
      'when',
      'scheduledTime',
      'scheduled_time',
    ],
    'duration': [
      'durationMinutes',
      'duration_minutes',
      'durationMins',
      'minutes',
      'lengthMinutes',
      'estimatedMinutes',
    ],
    'date': ['day', 'dateKey', 'planDate'],
  };

  static const Map<String, List<String>> _reminderAliases = {
    'taskTitle': ['title', 'task', 'name', 'taskName'],
    'reminderTime': ['time', 'at', 'when', 'startTime'],
  };

  /// Keys whose values are clock times and get canonicalized to "HH:mm".
  static const _timeKeys = {'time', 'reminderTime'};

  /// Returns [action] with parameters canonicalized. Original alias keys
  /// are left in place (harmless extras); only missing canonical keys are
  /// filled and time/duration values reformatted.
  static AiAction normalise(AiAction action) {
    final aliasMap = _aliases[action.actionType];
    final p = Map<String, dynamic>.from(action.parameters);
    var changed = false;

    if (aliasMap != null) {
      aliasMap.forEach((canonical, aliases) {
        if (_isBlank(p[canonical])) {
          for (final alias in aliases) {
            if (!_isBlank(p[alias])) {
              p[canonical] = p[alias];
              changed = true;
              break;
            }
          }
        }
      });
    }

    for (final key in _timeKeys) {
      final raw = p[key];
      if (raw is! String || raw.trim().isEmpty) continue;
      final range = _splitTimeRange(raw);
      final canonical = canonicaliseTime(range?.$1 ?? raw);
      if (canonical != null && canonical != raw) {
        p[key] = canonical;
        changed = true;
      }
      // A "14:00–15:00" style value carries the duration too — derive it
      // when the model didn't send one separately.
      if (range != null && key == 'time' && _isBlank(p['duration'])) {
        final start = canonicaliseTime(range.$1);
        final end = canonicaliseTime(range.$2);
        if (start != null && end != null) {
          final minutes = _minutesOfDay(end) - _minutesOfDay(start);
          if (minutes > 0) {
            p['duration'] = minutes;
            changed = true;
          }
        }
      }
    }

    final duration = p['duration'];
    if (duration is String) {
      final parsed = parseDurationMinutes(duration);
      if (parsed != null) {
        p['duration'] = parsed;
        changed = true;
      }
    } else if (duration is double) {
      p['duration'] = duration.round();
      changed = true;
    }

    return changed ? action.copyWith(parameters: p) : action;
  }

  static bool _isBlank(dynamic v) =>
      v == null || (v is String && v.trim().isEmpty);

  // ─── Time parsing ───────────────────────────────────────────────────────────

  static final _timeToken = RegExp(
    r'^(\d{1,2})(?:[:.](\d{2}))?\s*(a\.?m\.?|p\.?m\.?)?$',
    caseSensitive: false,
  );

  /// "2 pm" / "2.30pm" / "14:00" / "02:00 PM" → "HH:mm" (24-hour).
  /// A bare hour without am/pm is accepted only when it is unambiguously
  /// 24-hour (13–23) — "2" alone stays unparsed rather than guessed.
  static String? canonicaliseTime(String raw) {
    final m = _timeToken.firstMatch(raw.trim());
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = m.group(2) != null ? int.parse(m.group(2)!) : 0;
    final meridiem = m.group(3)?.toLowerCase().replaceAll('.', '');
    if (meridiem == 'pm' && hour < 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    if (meridiem == null && m.group(2) == null && hour < 13) return null;
    if (hour > 23 || minute > 59) return null;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  static final _rangeSeparator = RegExp(r'\s*(?:–|—|-|\bto\b)\s*');

  /// Splits "2-3pm" / "14:00–15:00" / "2 pm to 3 pm" into (start, end).
  /// When only the end carries am/pm, the start inherits it.
  static (String, String)? _splitTimeRange(String raw) {
    final parts = raw.trim().split(_rangeSeparator);
    if (parts.length != 2) return null;
    var start = parts[0].trim();
    final end = parts[1].trim();
    if (start.isEmpty || end.isEmpty) return null;
    final endMeridiem = RegExp(
      r'(a\.?m\.?|p\.?m\.?)$',
      caseSensitive: false,
    ).firstMatch(end);
    final startHasMeridiem = RegExp(
      r'(a\.?m\.?|p\.?m\.?)$',
      caseSensitive: false,
    ).hasMatch(start);
    if (endMeridiem != null && !startHasMeridiem) {
      start = '$start ${endMeridiem.group(1)}';
    }
    return (start, end);
  }

  static int _minutesOfDay(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// "90", "90 min", "1.5 hours", "1h" → minutes. Null when unparseable.
  static int? parseDurationMinutes(String raw) {
    final s = raw.trim().toLowerCase();
    final hours = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)$',
    ).firstMatch(s);
    if (hours != null) return (double.parse(hours.group(1)!) * 60).round();
    final minutes = RegExp(r'^(\d+)\s*(?:minutes?|mins?|m)?$').firstMatch(s);
    if (minutes != null) return int.parse(minutes.group(1)!);
    return null;
  }

  // ─── Free-text answer extraction (clarify-loop escape) ─────────────────────

  static final _timeInText = RegExp(
    r'\b(\d{1,2})(?:[:.](\d{2}))?\s*(a\.?m\.?|p\.?m\.?)\b'
    r'|\b([01]?\d|2[0-3])[:.]([0-5]\d)\b',
    caseSensitive: false,
  );

  /// Pulls a clock time out of a free-text reply ("at 2 pm", "14:30 works").
  static String? extractTimeAnswer(String input) {
    final m = _timeInText.firstMatch(input);
    if (m == null) return null;
    final token = m.group(0)!;
    return canonicaliseTime(token) ??
        // "14.30" second alternative: rebuild as colon form.
        (m.group(4) != null ? '${m.group(4)!.padLeft(2, '0')}:${m.group(5)}' : null);
  }

  /// Pulls a duration out of a free-text reply ("30 minutes", "an hour",
  /// or a bare number when [bareNumberIsMinutes] — the question literally
  /// asked "in minutes").
  static int? extractDurationAnswer(
    String input, {
    bool bareNumberIsMinutes = false,
  }) {
    final s = input.trim().toLowerCase();
    if (RegExp(r'\ban hour\b').hasMatch(s)) return 60;
    if (RegExp(r'\bhalf an hour\b').hasMatch(s)) return 30;
    final hours = RegExp(r'\b(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h)\b').firstMatch(s);
    if (hours != null) return (double.parse(hours.group(1)!) * 60).round();
    final minutes = RegExp(r'\b(\d+)\s*(?:minutes?|mins?)\b').firstMatch(s);
    if (minutes != null) return int.parse(minutes.group(1)!);
    if (bareNumberIsMinutes) {
      final bare = RegExp(r'^(\d{1,3})$').firstMatch(s);
      if (bare != null) return int.parse(bare.group(1)!);
    }
    return null;
  }

  /// "today"/"tonight"/"tomorrow" from a free-text reply. Weekday names are
  /// deliberately NOT resolved here — the model path handles those.
  static String? extractDateAnswer(String input) {
    final s = input.toLowerCase();
    if (s.contains('tomorrow')) return 'tomorrow';
    if (s.contains('today') || s.contains('tonight')) return 'today';
    return null;
  }
}

/// True when assistant prose DESCRIBES a concrete plan (times + plan/confirm
/// framing) — the shape that must always arrive as a confirmable card, never
/// as bare text. Deliberately strict so schedule ANSWERS ("You have Study at
/// 9:00.") never match: requires a time AND either confirm-framing or a
/// plan-with-bullets shape.
bool looksPlanShapedProse(String text) {
  final hasTime = RegExp(
    r'\b\d{1,2}[:.]\d{2}\b|\b\d{1,2}\s?(am|pm)\b',
    caseSensitive: false,
  ).hasMatch(text);
  if (!hasTime) return false;
  final lower = text.toLowerCase();
  final confirmFramed =
      lower.contains('confirm') || lower.contains('ready to');
  final bulletedPlan =
      lower.contains('plan') &&
      (text.contains('• ') || text.contains('\n- ') || text.contains('\n• '));
  return confirmFramed || bulletedPlan;
}
