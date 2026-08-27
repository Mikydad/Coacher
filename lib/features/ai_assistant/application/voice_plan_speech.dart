import '../../../core/utils/friendly_date.dart';
import '../domain/models/ai_action.dart';
import '../domain/models/ai_planned_changes.dart';

/// Spoken rendering of a plan (Voice Mode confirm-by-voice, 2026-08-21).
///
/// On the orb-only voice stage the preview card is invisible, so the voice
/// IS the preview: the plan must be read aloud with enough detail that a
/// spoken "confirm" is informed consent. Pure functions — unit-tested
/// without any plugin.
String formatPlanForSpeech(AiPlannedChanges plan) {
  final parts = plan.actions.map(_describeAction).toList();
  if (parts.isEmpty) return '';
  const cap = 3;
  final String listing;
  if (parts.length == 1) {
    listing = parts.single;
  } else if (parts.length <= cap) {
    listing =
        '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
  } else {
    listing =
        '${parts.take(cap).join(', ')}, and ${parts.length - cap} more '
        '${parts.length - cap == 1 ? 'step' : 'steps'}';
  }
  // The voice IS the preview — it must speak the same risk surface the
  // card shows (fix-wave Phase 4, §8 E12): a plan inside the sleep/DND
  // window used to read aloud with no mention of the red hard-block the
  // sighted user would see.
  return "I'll $listing.${_warningSentence(plan)}";
}

String _warningSentence(AiPlannedChanges plan) {
  if (plan.isBlockedByContext) {
    return ' Heads-up — that overlaps a protected window like sleep or '
        'do-not-disturb.';
  }
  if (plan.hasConflicts) {
    final n = plan.conflicts.length;
    return n == 1
        ? ' One heads-up: it clashes with something already scheduled.'
        : ' $n heads-ups: it clashes with things already scheduled.';
  }
  return '';
}

String _describeAction(AiAction action) {
  final p = action.parameters;
  String s(String key) => p[key]?.toString().trim() ?? '';
  switch (action.actionType) {
    case ActionType.createTask:
      final at = speakableTime(s('time'));
      final duration = _speakableDuration(p['duration']);
      final date = _speakableDate(s('date'));
      return 'add ${_orA(s('title'), 'a task')}'
          '${at.isNotEmpty ? ' at $at' : ''}'
          '${duration.isNotEmpty ? ' for $duration' : ''}'
          '${date.isNotEmpty ? ' $date' : ''}';
    case ActionType.editTask:
      return 'update ${_orA(s('title'), 'the task')}';
    case ActionType.moveTask:
      final dest = s('destinationDate');
      return 'move ${_orA(s('taskTitle'), 'the task')}'
          '${dest.isNotEmpty ? ' to ${_speakableDate(dest, bare: true)}' : ''}';
    case ActionType.deleteTask:
      return 'delete ${_orA(s('taskTitle'), 'the task')}';
    case ActionType.createGoal:
      return 'create the goal ${_orA(s('title'), '')}'.trim();
    case ActionType.modifyGoal:
      return 'update the goal ${_orA(s('goalTitle'), '')}'.trim();
    case ActionType.deleteGoal:
      return 'remove the goal ${_orA(s('goalTitle'), '')}'.trim();
    case ActionType.addReminder:
      final at = speakableTime(s('reminderTime'));
      return 'set a reminder for ${_orA(s('taskTitle'), 'the task')}'
          '${at.isNotEmpty ? ' at $at' : ''}';
    case ActionType.rescheduleReminder:
      final at = speakableTime(s('reminderTime'));
      return "move the reminder for ${_orA(s('taskTitle'), 'the task')}"
          '${at.isNotEmpty ? ' to $at' : ''}';
    case ActionType.removeReminder:
      return 'remove the reminder for ${_orA(s('taskTitle'), 'the task')}';
    case ActionType.activateContextOverride:
      return 'turn on ${_orA(s('overrideType'), 'focus')} mode';
    case ActionType.endContextOverride:
      return 'end the active mode';
    case ActionType.createIntention:
      return 'note your promise to ${_orA(s('title'), '')}'.trim();
    case ActionType.rememberFact:
    case ActionType.updateFact:
    case ActionType.forgetFact:
      return 'update what I remember about you';
    case ActionType.suggestFreeTimeBlock:
    case ActionType.moveConflictingTasks:
      return 'reshuffle your schedule';
  }
}

String _orA(String value, String fallback) => value.isEmpty ? fallback : value;

/// "14:00" → "2 PM", "14:30" → "2:30 PM", "09:05" → "9:05 AM".
/// Anything that isn't colon-form HH:mm is returned as-is (already prose).
String speakableTime(String raw) {
  final m = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(raw.trim());
  if (m == null) return raw.trim();
  var hour = int.parse(m.group(1)!);
  final minute = int.parse(m.group(2)!);
  final meridiem = hour >= 12 ? 'PM' : 'AM';
  hour = hour % 12;
  if (hour == 0) hour = 12;
  return minute == 0
      ? '$hour $meridiem'
      : '$hour:${minute.toString().padLeft(2, '0')} $meridiem';
}

String _speakableDuration(dynamic raw) {
  final minutes = raw is num ? raw.toInt() : int.tryParse('$raw');
  if (minutes == null || minutes <= 0) return '';
  if (minutes == 60) return 'an hour';
  if (minutes % 60 == 0) return '${minutes ~/ 60} hours';
  return '$minutes minutes';
}

String _speakableDate(String raw, {bool bare = false}) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return '';
  if (s == 'today' || s == 'tomorrow') return s;
  // YYYY-MM-DD reads badly aloud. Within the coming week it humanizes to
  // a bare weekday ("Sunday") — speak that; beyond, say nothing rather
  // than spell digits (2026-08-25).
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
    final friendly = friendlyDateKey(s);
    if (!RegExp(r'\d').hasMatch(friendly)) return friendly.toLowerCase();
    return bare ? s : '';
  }
  return s;
}
