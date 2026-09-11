import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';

void main() {
  final start = DateTime(2026, 9, 12, 22, 3).millisecondsSinceEpoch;

  test('create derives the local dateKey and trims text', () {
    final e = ActivityEvent.create(text: '  Scrolling ', startedAtMs: start, nowMs: 1);
    expect(e.text, 'Scrolling');
    expect(e.dateKey, '2026-09-12');
    expect(e.id, startsWith('act_'));
    expect(e.source, ActivitySource.manual);
    expect(() => e.validate(), returnsNormally);
  });

  test('a 2 AM entry belongs to the next calendar day', () {
    final lateMs = DateTime(2026, 9, 13, 2, 0).millisecondsSinceEpoch;
    final e = ActivityEvent.create(text: 'Sleep', startedAtMs: lateMs, nowMs: 1);
    expect(e.dateKey, '2026-09-13');
  });

  test('copyWith on start re-derives dateKey', () {
    final e = ActivityEvent.create(text: 'A', startedAtMs: start, nowMs: 1);
    final moved = e.copyWith(
      startedAtMs: DateTime(2026, 9, 13, 1).millisecondsSinceEpoch,
    );
    expect(moved.dateKey, '2026-09-13');
    expect(() => moved.validate(), returnsNormally);
  });

  test('toMap/fromMap round-trip', () {
    final e = ActivityEvent.create(
      text: 'Study Flutter',
      startedAtMs: start,
      nowMs: 5,
      endedAtMs: start + 45 * 60000,
      intendedMinutes: 30,
      source: ActivitySource.timer,
      sourceEntityId: 'task_1',
    );
    final back = ActivityEvent.fromMap(e.toMap());
    expect(back.id, e.id);
    expect(back.text, e.text);
    expect(back.startedAtMs, e.startedAtMs);
    expect(back.endedAtMs, e.endedAtMs);
    expect(back.intendedMinutes, 30);
    expect(back.dateKey, e.dateKey);
    expect(back.source, ActivitySource.timer);
    expect(back.sourceEntityId, 'task_1');
    expect(back.active, isTrue);
    expect(back.updatedAtMs, 5);
  });

  test('fromMap re-derives dateKey locally', () {
    final back = ActivityEvent.fromMap({
      'id': 'act_x',
      'text': 'A',
      'startedAtMs': start,
      'dateKey': '1999-01-01',
      'updatedAtMs': 1,
    });
    expect(back.dateKey, '2026-09-12');
  });

  group('validate', () {
    ActivityEvent base({
      String text = 'A',
      int? endedAtMs,
      int? intended,
      String? dateKey,
    }) => ActivityEvent(
      id: 'act_1',
      text: text,
      startedAtMs: start,
      endedAtMs: endedAtMs,
      intendedMinutes: intended,
      dateKey: dateKey ?? activityDateKeyFor(start),
      createdAtMs: 1,
      updatedAtMs: 1,
    );

    test('rejects blank and over-long text', () {
      expect(() => base(text: '   ').validate(), throwsArgumentError);
      expect(
        () => base(text: 'a' * (kActivityTextMaxChars + 1)).validate(),
        throwsArgumentError,
      );
      expect(() => base(text: 'a' * kActivityTextMaxChars).validate(),
          returnsNormally);
    });

    test('rejects an end at or before the start', () {
      expect(() => base(endedAtMs: start).validate(), throwsArgumentError);
      expect(() => base(endedAtMs: start - 1).validate(), throwsArgumentError);
      expect(() => base(endedAtMs: start + 1).validate(), returnsNormally);
    });

    test('rejects intended outside 1..720', () {
      expect(() => base(intended: 0).validate(), throwsArgumentError);
      expect(() => base(intended: 721).validate(), throwsArgumentError);
      expect(() => base(intended: 720).validate(), returnsNormally);
    });

    test('rejects a dateKey that disagrees with the start', () {
      expect(() => base(dateKey: '2026-09-11').validate(), throwsArgumentError);
    });
  });

  test('normalizeActivityText collapses case and whitespace', () {
    expect(normalizeActivityText('  Gym   Session '), 'gym session');
  });
}
