import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/features/reminders/application/recovery_triage_service.dart';
import 'package:sidepal/features/reminders/application/recovery_view.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

/// FR-R-62: an enhancement, never a gate — bounded, memoized, silent on
/// failure, and structurally unable to lose a row.
void main() {
  RecoveryRow row(String id) => RecoveryRow(
    occurrence: ReminderOccurrence(
      id: 'o-$id',
      entityId: id,
      entityKind: 'task',
      dateKey: '2026-08-31',
      scheduledAtMs: 1,
      windowMinutes: 30,
      entityTitle: id,
      modeRefId: 'disciplined',
      state: ReminderOccurrenceState.overdue,
      createdAtMs: 1,
      updatedAtMs: 1,
    ),
    insistence: RecoveryInsistence.persistent,
  );

  RecoveryView view(int n) =>
      RecoveryView(rows: [for (var i = 0; i < n; i++) row('t$i')]);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ({RecoveryTriageService svc, List<int> calls}) harness({
    String? reply,
    bool tier = true,
  }) {
    final calls = <int>[];
    return (
      svc: RecoveryTriageService(
        chat: (messages) async {
          calls.add(1);
          if (reply == null) throw Exception('down');
          return reply;
        },
        isAiTierEnabled: () => tier,
        now: () => DateTime(2026, 8, 31, 18, 0),
      ),
      calls: calls,
    );
  }

  test('fewer than 3 items never calls', () async {
    final h = harness(reply: '{"headline":"x","order":["t0"]}');
    expect(await h.svc.triage(view(2)), isNull);
    expect(h.calls, isEmpty);
  });

  test('3+ items get one bounded call with a validated result', () async {
    final h = harness(
      reply: jsonEncode({
        'headline': 'Start with t2 — the rest can move.',
        'order': ['t2', 't0', 'bogus-id', 't1'],
      }),
    );
    final result = await h.svc.triage(view(3));
    expect(result!.headline, contains('Start with'));
    expect(result.order, ['t2', 't0', 't1']); // bogus id dropped
  });

  test('the same pool never pays twice (memo)', () async {
    final h = harness(reply: '{"headline":"go","order":["t0"]}');
    await h.svc.triage(view(3));
    await h.svc.triage(view(3));
    expect(h.calls, hasLength(1));
  });

  test('two calls a day, persisted — the third pool is refused', () async {
    final h = harness(reply: '{"headline":"go","order":["t0"]}');
    await h.svc.triage(view(3));
    await h.svc.triage(view(4)); // different pool → second slot
    final third = await h.svc.triage(view(5));
    expect(third, isNull);
    expect(h.calls, hasLength(2));
  });

  test('failure is silent and the deterministic order stands', () async {
    final h = harness(); // throws
    expect(await h.svc.triage(view(3)), isNull);
  });

  test('free tier never calls (FR-R-60)', () async {
    final h = harness(reply: '{"headline":"go","order":["t0"]}', tier: false);
    expect(await h.svc.triage(view(3)), isNull);
    expect(h.calls, isEmpty);
  });

  group('applyOrder cannot lose a row', () {
    test('ranked ids lead, unmentioned rows keep their order', () {
      final rows = [row('a'), row('b'), row('c')];
      final out = RecoveryTriageService.applyOrder(
        rows,
        const RecoveryTriage(headline: 'x', order: ['c']),
      );
      expect(out.map((r) => r.occurrence.entityId), ['c', 'a', 'b']);
    });
  });

  group('parseResponse rejects garbage wholesale', () {
    test('non-JSON, oversize headline, empty order', () {
      expect(
        RecoveryTriageService.parseResponse('nope', validIds: {'a'}),
        isNull,
      );
      expect(
        RecoveryTriageService.parseResponse(
          '{"headline":"${'x' * 200}","order":["a"]}',
          validIds: {'a'},
        ),
        isNull,
      );
      expect(
        RecoveryTriageService.parseResponse(
          '{"headline":"ok","order":["unknown"]}',
          validIds: {'a'},
        ),
        isNull,
      );
    });
  });
}
