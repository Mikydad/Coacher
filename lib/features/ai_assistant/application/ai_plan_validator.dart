import '../../../core/utils/date_keys.dart';
import '../domain/models/ai_action.dart';
import '../domain/models/ai_planned_changes.dart';

/// Re-checks a plan at CONFIRM time (AI chat fix plan Phase 2.2). The
/// preview card was built from the world as it was when the model answered;
/// by the time the user taps Confirm the clock has moved, sometimes past
/// midnight, sometimes past the proposed time. Pure — no I/O, fully testable.
class AiPlanValidation {
  const AiPlanValidation({this.hardBlocks = const [], this.notes = const []});

  /// Reasons the plan must NOT execute as-is (the user sees them, the card
  /// stays live so they can Edit or re-request).
  final List<String> hardBlocks;

  /// Advisory notes carried into the outcome message.
  final List<String> notes;

  bool get isBlocked => hardBlocks.isNotEmpty;
}

abstract final class AiPlanValidator {
  /// [proposedOnDateKey] is the local day the proposal was made on; when the
  /// day has changed since, relative dates ("today", "tomorrow") would land
  /// on a different day than the card promised.
  static AiPlanValidation validate(
    AiPlannedChanges plan, {
    required DateTime now,
    String? proposedOnDateKey,
  }) {
    final hard = <String>[];
    final notes = <String>[];
    final todayKey = DateKeys.todayKey(now);
    final nowMinute = now.hour * 60 + now.minute;

    final dayChanged =
        proposedOnDateKey != null && proposedOnDateKey != todayKey;

    for (final action in plan.actions) {
      if (!_schedulesTime(action)) continue;
      final rawDate = action.parameters['date'] as String?;
      final relative =
          rawDate == null || rawDate.isEmpty || rawDate == 'today' || rawDate == 'tomorrow';
      final title = _title(action);

      if (dayChanged && relative) {
        hard.add(
          '"$title" was planned for ${rawDate ?? 'today'} on a day that has '
          'since ended — ask again so it lands on the right day.',
        );
        continue;
      }

      final dateKey = resolveDateKey(rawDate, now);
      if (dateKey == null) continue; // the executor reports unparseable dates
      if (dateKey != todayKey) continue;

      final time = action.parameters['time'] as String?;
      final minute = _parseMinute(time);
      if (minute == null) continue;
      if (minute < nowMinute) {
        hard.add(
          '"$title" is set for $time today, which has already passed — pick '
          'a later time or a different day.',
        );
      }
    }

    return AiPlanValidation(hardBlocks: hard, notes: notes);
  }

  /// today / tomorrow / YYYY-MM-DD → date key; null when unrecognised.
  static String? resolveDateKey(String? raw, DateTime now) {
    if (raw == null || raw.isEmpty || raw == 'today') {
      return DateKeys.todayKey(now);
    }
    if (raw == 'tomorrow') return DateKeys.tomorrowKey(now);
    try {
      DateKeys.parseLocalDateKey(raw);
      return raw;
    } catch (_) {
      return null;
    }
  }

  static bool _schedulesTime(AiAction action) =>
      action.actionType == ActionType.createTask ||
      action.actionType == ActionType.editTask ||
      action.actionType == ActionType.moveTask;

  static String _title(AiAction action) =>
      action.parameters['title']?.toString() ??
      action.parameters['taskTitle']?.toString() ??
      action.actionType.name;

  static int? _parseMinute(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}
