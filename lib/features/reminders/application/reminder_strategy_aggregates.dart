import '../../../core/local_db/isar_collections/isar_notification_ledger_entry.dart';
import '../domain/models/reminder_config.dart';
import '../domain/models/reminder_occurrence.dart';
import '../domain/models/reminder_occurrence_enums.dart';

/// Locally pre-computed reminder aggregates for the strategist (FR-R-61).
///
/// The Thinking Loop's reflect pass gets ONE compact object, never raw
/// ledger rows: per-task interaction counts, an engagement-by-hour
/// histogram, and each task's recent overdue/reschedule history. Everything
/// here is arithmetic over data that already lives in Isar — computing it
/// costs nothing and sending it costs a few hundred tokens, which is what
/// lets the strategist ride the existing daily budgeted pass instead of
/// owning a call (FR-R-64).
abstract final class ReminderStrategyAggregates {
  /// Cap so a power user's task list cannot balloon the reflect payload.
  static const int maxTasks = 12;

  static Map<String, dynamic> build({
    required List<ReminderConfig> configs,
    required List<ReminderOccurrence> occurrences,
    required List<IsarNotificationLedgerEntry> ledgerEntries,
  }) {
    // Engagement-by-hour: when do interactions actually happen?
    final byHour = List<int>.filled(24, 0);
    final perEntity = <String, Map<String, int>>{};
    for (final e in ledgerEntries) {
      final counts = perEntity.putIfAbsent(
        e.entityId,
        () => {'delivered': 0, 'opened': 0, 'ignored': 0, 'snoozed': 0},
      );
      if (e.deliveredAtMs != null) counts['delivered'] = counts['delivered']! + 1;
      final interaction = e.interactionType;
      if (interaction == 'opened') counts['opened'] = counts['opened']! + 1;
      if (interaction == 'snoozed') counts['snoozed'] = counts['snoozed']! + 1;
      counts['ignored'] = counts['ignored']! + e.ignoredCount;
      final at = e.interactedAtMs ?? e.deliveredAtMs;
      if (at != null) {
        byHour[DateTime.fromMillisecondsSinceEpoch(at).hour]++;
      }
    }

    final overdueCount = <String, int>{};
    final rescheduleCount = <String, int>{};
    for (final o in occurrences) {
      if (o.overdueSinceMs != null) {
        overdueCount[o.entityId] = (overdueCount[o.entityId] ?? 0) + 1;
      }
      if (o.resolutionKind == ReminderResolutionKind.rescheduled) {
        rescheduleCount[o.entityId] = (rescheduleCount[o.entityId] ?? 0) + 1;
      }
    }

    // Most-troubled tasks first: the strategist should spend its few tokens
    // on what actually slips.
    final enabled = configs.where((c) => c.enabled).toList()
      ..sort((a, b) {
        int trouble(ReminderConfig c) =>
            (overdueCount[c.taskId] ?? 0) * 2 +
            (perEntity[c.taskId]?['ignored'] ?? 0) +
            (rescheduleCount[c.taskId] ?? 0);
        return trouble(b).compareTo(trouble(a));
      });

    final tasks = [
      for (final c in enabled.take(maxTasks))
        {
          'id': c.taskId,
          'title': c.taskTitle ?? '',
          'mode': c.modeRefId ?? 'flexible',
          'class': c.taxonomy.toStorage(),
          'timeIso': c.scheduledAtIso,
          ...?perEntity[c.taskId],
          if ((overdueCount[c.taskId] ?? 0) > 0)
            'overdueDays': overdueCount[c.taskId],
          if ((rescheduleCount[c.taskId] ?? 0) > 0)
            'reschedules': rescheduleCount[c.taskId],
        },
    ];

    return {
      'tasks': tasks,
      // Sparse encoding: only hours with activity, as "hour:count".
      'activeHours': [
        for (var h = 0; h < 24; h++)
          if (byHour[h] > 0) '$h:${byHour[h]}',
      ],
    };
  }
}
