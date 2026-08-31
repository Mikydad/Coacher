import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_notification_ledger_entry.dart';
import 'package:sidepal/features/reminders/application/reminder_strategy_aggregates.dart';
import 'package:sidepal/features/reminders/application/strategist_proposals_store.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';
import 'package:sidepal/features/thinking/application/reflection_parser.dart';

/// FR-R-61: aggregates in (never raw rows), validated proposals out,
/// day-scoped storage, suggestion-only by construction.
void main() {
  group('ReminderStrategyAggregates', () {
    ReminderConfig config(String taskId, {String? title}) => ReminderConfig(
      id: 'r-$taskId',
      taskId: taskId,
      taskTitle: title ?? taskId,
      enabled: true,
      scheduledAtIso: '2026-08-31T14:00:00.000',
      modeRefId: 'disciplined',
      createdAtMs: 1,
      updatedAtMs: 1,
    );

    IsarNotificationLedgerEntry entry(
      String entityId, {
      int ignored = 0,
      String? interaction,
      int? deliveredAtMs,
    }) => IsarNotificationLedgerEntry()
      ..notifId = entityId.hashCode
      ..entityId = entityId
      ..entityKind = 'task'
      ..state = 'delivered'
      ..ignoredCount = ignored
      ..interactionType = interaction
      ..deliveredAtMs = deliveredAtMs
      ..updatedAtMs = 1;

    test('per-task counts and hour histogram, no raw rows', () {
      final at = DateTime(2026, 8, 31, 14, 5).millisecondsSinceEpoch;
      final out = ReminderStrategyAggregates.build(
        configs: [config('t1', title: 'Study')],
        occurrences: const [],
        ledgerEntries: [
          entry('t1', deliveredAtMs: at, interaction: 'snoozed'),
          entry('t1', ignored: 2, deliveredAtMs: at),
        ],
      );

      final task = (out['tasks'] as List).single as Map;
      expect(task['title'], 'Study');
      expect(task['delivered'], 2);
      expect(task['snoozed'], 1);
      expect(task['ignored'], 2);
      expect(out['activeHours'], contains('14:2'));
      // Nothing row-shaped leaks.
      expect(out.keys, unorderedEquals(['tasks', 'activeHours']));
    });

    test('the most-troubled tasks lead, capped at 12', () {
      final configs = [
        for (var i = 0; i < 20; i++) config('t$i'),
      ];
      final out = ReminderStrategyAggregates.build(
        configs: configs,
        occurrences: [
          ReminderOccurrence(
            id: 'o',
            entityId: 't7',
            entityKind: 'task',
            dateKey: '2026-08-30',
            scheduledAtMs: 1,
            windowMinutes: 30,
            overdueSinceMs: 99,
            createdAtMs: 1,
            updatedAtMs: 1,
          ),
        ],
        ledgerEntries: [entry('t7', ignored: 3)],
      );

      final tasks = out['tasks'] as List;
      expect(tasks, hasLength(ReminderStrategyAggregates.maxTasks));
      expect((tasks.first as Map)['id'], 't7');
    });
  });

  group('ReflectionParser.reminderProposals', () {
    ParsedReflection parse(String json) => ReflectionParser.parse(
      json,
      knownIds: const {},
      openIntentionIds: const {},
      existingTitleKeys: const {},
      reminderTasks: const {'t1': 'Study', 't2': 'Gym'},
    );

    test('valid proposals pass with their titles attached', () {
      final parsed = parse(
        '{"reminderProposals":[{"kind":"reschedule","taskId":"t1",'
        '"suggestion":"Study keeps slipping past 2pm — try evenings?"}]}',
      );
      final p = parsed.reminderProposals.single;
      expect(p.kind, 'reschedule');
      expect(p.taskTitle, 'Study');
    });

    test('unknown kinds, unknown tasks and oversize prose are dropped', () {
      final parsed = parse(
        '{"reminderProposals":['
        '{"kind":"autoApply","taskId":"t1","suggestion":"x"},'
        '{"kind":"drop","taskId":"nope","suggestion":"x"},'
        '{"kind":"drop","taskId":"t1","suggestion":"${'y' * 200}"}]}',
      );
      expect(parsed.reminderProposals, isEmpty);
    });

    test('one proposal per task, capped at 3', () {
      final parsed = ReflectionParser.parse(
        '{"reminderProposals":['
        '{"kind":"drop","taskId":"a","suggestion":"1"},'
        '{"kind":"drop","taskId":"a","suggestion":"dupe"},'
        '{"kind":"drop","taskId":"b","suggestion":"2"},'
        '{"kind":"drop","taskId":"c","suggestion":"3"},'
        '{"kind":"drop","taskId":"d","suggestion":"4"}]}',
        knownIds: const {},
        openIntentionIds: const {},
        existingTitleKeys: const {},
        reminderTasks: const {'a': 'A', 'b': 'B', 'c': 'C', 'd': 'D'},
      );
      expect(parsed.reminderProposals, hasLength(3));
      expect(
        parsed.reminderProposals.map((p) => p.taskId),
        ['a', 'b', 'c'],
      );
    });
  });

  group('StrategistProposalsStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('round-trips within a day and reads empty across days', () async {
      final store = StrategistProposalsStore();
      await store.saveForDay('2026-08-31', const [
        ReminderStrategyProposal(
          kind: 'reschedule',
          taskId: 't1',
          taskTitle: 'Study',
          suggestion: 'Try evenings?',
        ),
      ]);

      final today = await store.loadForDay('2026-08-31');
      expect(today.single.suggestion, 'Try evenings?');
      // Yesterday's advice is not today's.
      expect(await store.loadForDay('2026-09-01'), isEmpty);
    });
  });
}
