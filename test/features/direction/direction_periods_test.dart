import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/direction/domain/direction_periods.dart';

void main() {
  group('current', () {
    test('month key is zero-padded and local-calendar bounded', () {
      final p = DirectionPeriods.current(
        DirectionHorizon.month,
        DateTime(2026, 9, 11, 21, 57),
      );
      expect(p.key, '2026-09');
      expect(p.label, 'September');
      expect(p.startMs, DateTime(2026, 9, 1).millisecondsSinceEpoch);
      expect(p.endMs, DateTime(2026, 10, 1).millisecondsSinceEpoch);
      expect(p.contains(DateTime(2026, 9, 30, 23, 59, 59)), isTrue);
      expect(p.contains(DateTime(2026, 10, 1)), isFalse);
    });

    test('quarter edges', () {
      String q(int m) =>
          DirectionPeriods.keyFor(DirectionHorizon.quarter, DateTime(2026, m));
      expect(q(1), '2026-Q1');
      expect(q(3), '2026-Q1');
      expect(q(4), '2026-Q2');
      expect(q(6), '2026-Q2');
      expect(q(7), '2026-Q3');
      expect(q(9), '2026-Q3');
      expect(q(10), '2026-Q4');
      expect(q(12), '2026-Q4');
      final q4 = DirectionPeriods.current(
        DirectionHorizon.quarter,
        DateTime(2026, 12, 31, 23, 59),
      );
      expect(q4.label, 'Q4 2026');
      expect(q4.endMs, DateTime(2027, 1, 1).millisecondsSinceEpoch);
    });

    test('year boundary: Dec 31 23:59 vs Jan 1 00:00', () {
      final dec = DateTime(2026, 12, 31, 23, 59);
      final jan = DateTime(2027, 1, 1);
      for (final h in DirectionHorizon.values) {
        expect(
          DirectionPeriods.keyFor(h, dec),
          isNot(DirectionPeriods.keyFor(h, jan)),
        );
      }
      expect(DirectionPeriods.keyFor(DirectionHorizon.year, jan), '2027');
      expect(DirectionPeriods.keyFor(DirectionHorizon.month, jan), '2027-01');
    });

    test('leap February ends on Mar 1', () {
      final feb = DirectionPeriods.current(
        DirectionHorizon.month,
        DateTime(2028, 2, 29),
      );
      expect(feb.key, '2028-02');
      expect(feb.endMs, DateTime(2028, 3, 1).millisecondsSinceEpoch);
    });
  });

  group('previous', () {
    test('crosses year boundaries', () {
      final jan = DirectionPeriods.current(
        DirectionHorizon.month,
        DateTime(2026, 1, 15),
      );
      expect(DirectionPeriods.previous(jan).key, '2025-12');

      final q1 = DirectionPeriods.current(
        DirectionHorizon.quarter,
        DateTime(2026, 2, 1),
      );
      expect(DirectionPeriods.previous(q1).key, '2025-Q4');

      final year = DirectionPeriods.current(
        DirectionHorizon.year,
        DateTime(2026, 6, 1),
      );
      expect(DirectionPeriods.previous(year).key, '2025');
    });

    test('is contiguous with the current period', () {
      final sep = DirectionPeriods.current(
        DirectionHorizon.month,
        DateTime(2026, 9, 11),
      );
      final aug = DirectionPeriods.previous(sep);
      expect(aug.key, '2026-08');
      expect(aug.endMs, sep.startMs);
    });
  });

  group('parseKey', () {
    test('round-trips every horizon', () {
      for (final h in DirectionHorizon.values) {
        final p = DirectionPeriods.current(h, DateTime(2026, 9, 11));
        final parsed = DirectionPeriods.parseKey(p.key);
        expect(parsed, isNotNull);
        expect(parsed!.horizon, h);
        expect(parsed.key, p.key);
        expect(parsed.startMs, p.startMs);
        expect(parsed.endMs, p.endMs);
        expect(parsed.label, p.label);
      }
    });

    test('rejects malformed keys', () {
      for (final bad in ['', '2026-13', '2026-9', '2026-Q5', '26', 'x']) {
        expect(DirectionPeriods.parseKey(bad), isNull, reason: bad);
      }
    });
  });

  test('keys sort lexicographically within a horizon', () {
    final keys = [
      for (var m = 1; m <= 12; m++)
        DirectionPeriods.keyFor(DirectionHorizon.month, DateTime(2026, m)),
    ];
    final sorted = [...keys]..sort();
    expect(sorted, keys);
  });
}
