import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/direction/domain/direction_periods.dart';
import 'package:sidepal/features/direction/domain/models/direction_entry.dart';

void main() {
  final sep = DirectionPeriods.current(
    DirectionHorizon.month,
    DateTime(2026, 9, 11),
  );

  test('forPeriod builds the deterministic id and trims text', () {
    final e = DirectionEntry.forPeriod(
      sep,
      text: '  Get SidePal ready for launch  ',
      nowMs: 1000,
    );
    expect(e.id, 'dir_month_2026-09');
    expect(e.text, 'Get SidePal ready for launch');
    expect(e.periodKey, '2026-09');
    expect(e.createdAtMs, 1000);
    expect(e.updatedAtMs, 1000);
    expect(() => e.validate(), returnsNormally);
  });

  test('forPeriod carries createdAtMs from an existing row', () {
    final e = DirectionEntry.forPeriod(
      sep,
      text: 'x',
      nowMs: 2000,
      createdAtMs: 500,
    );
    expect(e.createdAtMs, 500);
    expect(e.updatedAtMs, 2000);
  });

  test('toMap/fromMap round-trip', () {
    final e = DirectionEntry.forPeriod(sep, text: 'Launch', nowMs: 42);
    final back = DirectionEntry.fromMap(e.toMap());
    expect(back.id, e.id);
    expect(back.horizon, e.horizon);
    expect(back.periodKey, e.periodKey);
    expect(back.text, e.text);
    expect(back.periodStartMs, e.periodStartMs);
    expect(back.periodEndMs, e.periodEndMs);
    expect(back.createdAtMs, e.createdAtMs);
    expect(back.updatedAtMs, e.updatedAtMs);
  });

  test('fromMap recovers horizon and bounds from the key when missing', () {
    final back = DirectionEntry.fromMap({
      'periodKey': '2026-Q3',
      'text': 'Launch SidePal',
      'updatedAtMs': 7,
    });
    expect(back.horizon, DirectionHorizon.quarter);
    expect(back.id, 'dir_quarter_2026-Q3');
    expect(back.periodStartMs, DateTime(2026, 7, 1).millisecondsSinceEpoch);
    expect(back.periodEndMs, DateTime(2026, 10, 1).millisecondsSinceEpoch);
  });

  test('empty text is allowed (cleared entry)', () {
    final e = DirectionEntry.forPeriod(sep, text: '   ', nowMs: 1);
    expect(e.isEmpty, isTrue);
    expect(() => e.validate(), returnsNormally);
  });

  test('validate rejects over-long text', () {
    final e = DirectionEntry.forPeriod(
      sep,
      text: 'a' * (kDirectionMaxChars + 1),
      nowMs: 1,
    );
    expect(() => e.validate(), throwsArgumentError);
  });

  test(
    'validate rejects a horizon/key mismatch and a non-deterministic id',
    () {
      final mismatch = DirectionEntry(
        id: 'dir_year_2026-09',
        horizon: DirectionHorizon.year,
        periodKey: '2026-09',
        text: 'x',
        periodStartMs: 1,
        periodEndMs: 2,
        createdAtMs: 1,
        updatedAtMs: 1,
      );
      expect(() => mismatch.validate(), throwsArgumentError);

      final randomId = DirectionEntry(
        id: 'direction_123abc',
        horizon: DirectionHorizon.month,
        periodKey: '2026-09',
        text: 'x',
        periodStartMs: 1,
        periodEndMs: 2,
        createdAtMs: 1,
        updatedAtMs: 1,
      );
      expect(() => randomId.validate(), throwsArgumentError);
    },
  );

  group('outcome (close-out, 2026-09-19)', () {
    final period = DirectionPeriods.current(
      DirectionHorizon.month,
      DateTime(2026, 9, 11),
    );
    final entry = DirectionEntry.forPeriod(period, text: 'Ship it', nowMs: 1);

    test('round-trips through the map, absent by default', () {
      expect(entry.outcome, isNull);
      expect(DirectionEntry.fromMap(entry.toMap()).outcome, isNull);
      final answered = entry.copyWith(
        outcome: DirectionOutcome.notYet,
        outcomeAtMs: 5,
      );
      final back = DirectionEntry.fromMap(answered.toMap());
      expect(back.outcome, DirectionOutcome.notYet);
      expect(back.outcomeAtMs, 5);
      expect(answered.toMap()['outcome'], 'not_yet');
    });

    test('needsCloseoutAt: written, unanswered, and the period has ended', () {
      final before = DateTime(2026, 9, 20);
      final after = DateTime(2026, 10, 1, 8);
      expect(entry.needsCloseoutAt(before), isFalse);
      expect(entry.needsCloseoutAt(after), isTrue);
      expect(
        entry
            .copyWith(outcome: DirectionOutcome.achieved, outcomeAtMs: 1)
            .needsCloseoutAt(after),
        isFalse,
      );
      expect(entry.copyWith(text: '').needsCloseoutAt(after), isFalse);
    });
  });
}
