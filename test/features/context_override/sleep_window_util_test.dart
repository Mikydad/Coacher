import 'package:sidepal/features/context_override/application/sleep_window_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isWithinSleepWindow', () {
    // ─── Null / empty guards ─────────────────────────────────────────────
    test('returns false when both fields are null', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 2, 0), null, null), isFalse);
    });
    test('returns false when start is null', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 2, 0), null, '07:00'), isFalse);
    });
    test('returns false when end is null', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 2, 0), '23:00', null), isFalse);
    });
    test('returns false for empty strings', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 2, 0), '', ''), isFalse);
    });

    // ─── Same-day window: 01:00–07:00 ────────────────────────────────────
    test('inside same-day window', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 3, 30), '01:00', '07:00'), isTrue);
    });
    test('at start boundary of same-day window', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 1, 0), '01:00', '07:00'), isTrue);
    });
    test('just before same-day window', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 0, 59), '01:00', '07:00'), isFalse);
    });
    test('at end boundary of same-day window (exclusive)', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 7, 0), '01:00', '07:00'), isFalse);
    });
    test('after same-day window', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 9, 0), '01:00', '07:00'), isFalse);
    });

    // ─── Midnight crossover: 23:00–07:00 ─────────────────────────────────
    test('inside crossover window — evening before midnight', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 23, 30), '23:00', '07:00'), isTrue);
    });
    test('inside crossover window — after midnight', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 3, 0), '23:00', '07:00'), isTrue);
    });
    test('at start of crossover window', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 23, 0), '23:00', '07:00'), isTrue);
    });
    test('just before start of crossover window', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 22, 59), '23:00', '07:00'), isFalse);
    });
    test('at end of crossover window (exclusive)', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 7, 0), '23:00', '07:00'), isFalse);
    });
    test('outside crossover window — midday', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 12, 0), '23:00', '07:00'), isFalse);
    });
  });

  group('vacationWindowContains', () {
    // These are tested in context_override_service_test.dart via the full
    // service. This file focuses on the utility function in isolation
    // through the streak engine tests.
  });
}
