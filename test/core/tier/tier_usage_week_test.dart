import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/tier/tier_usage.dart';

void main() {
  group('promise week (Mon–Sun, decision 2026-09-27)', () {
    test('any day resolves to Monday 00:00 of its week', () {
      // 2026-09-27 is a Sunday → Monday 2026-09-21.
      expect(
        TierUsage.promiseWeekStart(DateTime(2026, 9, 27, 23, 59)),
        DateTime(2026, 9, 21),
      );
      expect(
        TierUsage.promiseWeekStart(DateTime(2026, 9, 21, 0, 0)),
        DateTime(2026, 9, 21),
      );
      expect(
        TierUsage.promiseWeekStart(DateTime(2026, 9, 23, 12)),
        DateTime(2026, 9, 21),
      );
    });

    test('a Monday starts a fresh week, across a month boundary', () {
      expect(
        TierUsage.promiseWeekStart(DateTime(2026, 9, 28, 8)),
        DateTime(2026, 9, 28),
      );
      expect(
        TierUsage.promiseWeekStart(DateTime(2026, 10, 1)),
        DateTime(2026, 9, 28),
      );
    });
  });
}
