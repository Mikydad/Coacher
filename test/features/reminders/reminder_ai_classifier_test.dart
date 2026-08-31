import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/reminders/application/reminder_ai_classifier.dart';
import 'package:sidepal/features/reminders/application/reminder_occurrence_service.dart';
import 'package:sidepal/features/reminders/data/reminder_occurrence_repository.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

/// FR-R-22 (background upgrade), FR-R-60 (tier gate), FR-R-65 (guardrails in
/// code, not prompts), FR-R-71 (silent degradation).

class _Reminders implements ReminderRepository {
  _Reminders(List<ReminderConfig> seed) : rows = [...seed];
  final List<ReminderConfig> rows;

  @override
  Future<List<ReminderConfig>> listAllReminders() async => rows;

  @override
  Future<void> upsertReminder(ReminderConfig r) async {
    final i = rows.indexWhere((x) => x.id == r.id);
    if (i >= 0) {
      rows[i] = r;
    } else {
      rows.add(r);
    }
  }

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> ids) async =>
      rows.where((r) => ids.contains(r.taskId)).toList();

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}

  @override
  Future<void> deleteRemindersForTask(String taskId) async {}
}

class _Occurrences implements ReminderOccurrenceRepository {
  final Map<String, ReminderOccurrence> rows = {};

  @override
  Future<ReminderOccurrence?> findByKey({
    required String entityKind,
    required String entityId,
    required String dateKey,
  }) async => rows[ReminderOccurrence.keyFor(entityKind, entityId, dateKey)];

  @override
  Future<void> upsert(ReminderOccurrence o) async => rows[o.occurrenceKey] = o;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<List<ReminderOccurrence>>.value(const []);
}

ReminderConfig _config({
  String id = 'r1',
  String taskId = 't1',
  String? title = 'Team meeting',
  ClassificationSource source = ClassificationSource.heuristic,
  ReminderTaxonomy taxonomy = ReminderTaxonomy.flexible,
  int criticality = 1,
  bool enabled = true,
}) => ReminderConfig(
  id: id,
  taskId: taskId,
  taskTitle: title,
  enabled: enabled,
  scheduledAtIso: DateTime(2026, 8, 31, 14, 0).toIso8601String(),
  modeRefId: 'disciplined',
  taxonomy: taxonomy,
  criticality: criticality,
  classificationSource: source,
  createdAtMs: 1,
  updatedAtMs: 1,
);

void main() {
  ({
    ReminderAiClassifier svc,
    _Reminders repo,
    List<List<Map<String, dynamic>>> calls,
    List<int> rearms,
  })
  harness(
    List<ReminderConfig> seed, {
    String Function(List<Map<String, dynamic>>)? reply,
    bool tierEnabled = true,
  }) {
    final repo = _Reminders(seed);
    final calls = <List<Map<String, dynamic>>>[];
    final rearms = <int>[];
    final svc = ReminderAiClassifier(
      reminders: repo,
      occurrences: ReminderOccurrenceService(
        occurrences: _Occurrences(),
        reminders: repo,
      ),
      chat: (messages) async {
        calls.add(messages);
        if (reply == null) throw Exception('endpoint down');
        return reply(messages);
      },
      isAiTierEnabled: () => tierEnabled,
      rearmLadders: () async => rearms.add(1),
    );
    return (svc: svc, repo: repo, calls: calls, rearms: rearms);
  }

  String replyWith(Map<String, Object> perId) => jsonEncode({
    'items': [
      for (final e in perId.entries)
        {
          'id': e.key,
          'class': (e.value as List)[0],
          'criticality': (e.value as List)[1],
        },
    ],
  });

  group('upgrade path', () {
    test('a heuristic row is upgraded and the ladder re-arms', () async {
      final h = harness(
        [_config()],
        reply: (_) => replyWith({'r1': ['timesensitive', 2]}),
      );

      final applied = await h.svc.sweep();

      expect(applied, 1);
      final row = h.repo.rows.single;
      expect(row.taxonomy, ReminderTaxonomy.timeSensitive);
      expect(row.criticality, 2);
      expect(row.classificationSource, ClassificationSource.ai);
      expect(row.classifierVersion, kAiClassifierVersion);
      expect(h.rearms, hasLength(1));
    });

    test('agreement with the heuristic writes nothing', () async {
      final h = harness(
        [_config()],
        reply: (_) => replyWith({'r1': ['flexible', 1]}),
      );

      expect(await h.svc.sweep(), 0);
      expect(h.repo.rows.single.classificationSource,
          ClassificationSource.heuristic);
      expect(h.rearms, isEmpty);
    });

    test('N eligible rows travel in ONE call (FR-R-22 batching)', () async {
      final h = harness(
        [
          _config(id: 'r1', taskId: 't1'),
          _config(id: 'r2', taskId: 't2', title: 'Take meds'),
          _config(id: 'r3', taskId: 't3', title: 'Water plants'),
        ],
        reply: (_) => replyWith({
          'r1': ['timesensitive', 2],
          'r2': ['timesensitive', 2],
          'r3': ['routine', 0],
        }),
      );

      expect(await h.svc.sweep(), 3);
      expect(h.calls, hasLength(1));
    });

    test('one attempt per config version per session', () async {
      final h = harness([_config()]); // endpoint throws
      expect(await h.svc.sweep(), 0);
      expect(await h.svc.sweep(), 0);
      expect(h.calls, hasLength(1), reason: 'no retry without an edit');

      // A material edit changes updatedAtMs → eligible again.
      h.repo.rows[0] = h.repo.rows[0].copyWith(updatedAtMs: 999);
      await h.svc.sweep();
      expect(h.calls, hasLength(2));
    });
  });

  group('guardrails (FR-R-65) — enforced in code, not prompts', () {
    test('a user classification is never overwritten', () async {
      final h = harness(
        [_config(source: ClassificationSource.user,
            taxonomy: ReminderTaxonomy.routine, criticality: 0)],
        reply: (_) => replyWith({'r1': ['timesensitive', 2]}),
      );

      expect(await h.svc.sweep(), 0);
      // Not even called: user rows are filtered before the batch is built.
      expect(h.calls, isEmpty);
      expect(h.repo.rows.single.taxonomy, ReminderTaxonomy.routine);
    });

    test('the AI cannot grant criticality 3', () {
      final parsed = ReminderAiClassifier.parseResponse(
        jsonEncode({'items': [
          {'id': 'r1', 'class': 'timesensitive', 'criticality': 3},
          {'id': 'r2', 'class': 'timesensitive', 'criticality': 99},
        ]}),
        validIds: {'r1', 'r2'},
      );
      expect(parsed['r1']!.criticality, 2);
      expect(parsed['r2']!.criticality, 2);
    });

    test('classification cannot disable a reminder or move its time', () async {
      final h = harness(
        [_config()],
        reply: (_) => replyWith({'r1': ['timesensitive', 2]}),
      );
      await h.svc.sweep();
      final row = h.repo.rows.single;
      expect(row.enabled, isTrue);
      expect(row.scheduledAtIso,
          DateTime(2026, 8, 31, 14, 0).toIso8601String());
    });

    test('an already-AI row is not re-sent', () async {
      final h = harness(
        [_config(source: ClassificationSource.ai)],
        reply: (_) => replyWith({'r1': ['routine', 0]}),
      );
      expect(await h.svc.sweep(), 0);
      expect(h.calls, isEmpty);
    });
  });

  group('silent degradation (FR-R-71)', () {
    test('endpoint down → heuristic stands, no throw', () async {
      final h = harness([_config()]);
      expect(await h.svc.sweep(), 0);
      expect(h.repo.rows.single.classificationSource,
          ClassificationSource.heuristic);
    });

    test('malformed JSON → nothing applied', () async {
      final h = harness([_config()], reply: (_) => 'not json at all');
      expect(await h.svc.sweep(), 0);
    });

    test('a bad item is dropped without poisoning the batch', () {
      final parsed = ReminderAiClassifier.parseResponse(
        jsonEncode({'items': [
          {'id': 'r1', 'class': 'no-such-class', 'criticality': 1},
          {'id': 'unknown-id', 'class': 'flexible', 'criticality': 1},
          {'id': 'r2', 'class': 'flexible'},
        ]}),
        validIds: {'r1', 'r2'},
      );
      expect(parsed.keys, ['r2']);
      expect(parsed['r2']!.criticality, 1);
    });

    test('free tier → no call at all (FR-R-60)', () async {
      final h = harness(
        [_config()],
        reply: (_) => replyWith({'r1': ['timesensitive', 2]}),
        tierEnabled: false,
      );
      expect(await h.svc.sweep(), 0);
      expect(h.calls, isEmpty);
    });
  });

  test('the prompt pins the heuristic\'s own semantics', () {
    final messages = ReminderAiClassifier.buildMessages([
      (id: 'r1', title: 'Study', durationMinutes: 30, category: 'Study',
          isHabitAnchor: false),
    ]);
    final system = messages.first['content'] as String;
    expect(system, contains('timesensitive'));
    expect(system, contains('Never exceed 2'));
    expect(messages.last['content'], contains('"id":"r1"'));
  });
}
