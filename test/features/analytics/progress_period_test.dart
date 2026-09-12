import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/analytics/domain/progress_period.dart';

void main() {
  group('ProgressPeriod.forDate', () {
    test('day: single day, weekday label', () {
      final p = ProgressPeriod.forDate(ProgressHorizon.day, DateTime(2026, 9, 12));
      expect(p.key, '2026-09-12');
      expect(p.startDateKey, '2026-09-12');
      expect(p.endDateKey, '2026-09-12');
      expect(p.dayCount, 1);
      expect(p.label, 'Sat, 12 Sep');
    });

    test('week: Monday → Sunday ISO, any weekday resolves to the same week', () {
      final sat = ProgressPeriod.forDate(ProgressHorizon.week, DateTime(2026, 9, 12));
      final mon = ProgressPeriod.forDate(ProgressHorizon.week, DateTime(2026, 9, 7));
      final sun = ProgressPeriod.forDate(ProgressHorizon.week, DateTime(2026, 9, 13));
      expect(sat.key, '2026-W37');
      expect(sat, mon);
      expect(sat, sun);
      expect(sat.startDateKey, '2026-09-07');
      expect(sat.endDateKey, '2026-09-13');
      expect(sat.dayCount, 7);
      expect(sat.dateKeys.first, '2026-09-07');
      expect(sat.dateKeys.last, '2026-09-13');
      expect(sat.label, '7 – 13 Sep');
    });

    test('week across a year boundary keeps ISO numbering and labels both years', () {
      final p = ProgressPeriod.forDate(ProgressHorizon.week, DateTime(2027, 1, 1));
      expect(p.key, '2026-W53');
      expect(p.startDateKey, '2026-12-28');
      expect(p.endDateKey, '2027-01-03');
      expect(p.label, '28 Dec 2026 – 3 Jan 2027');
      expect(p.next.key, '2027-W01');
      expect(p.next.startDateKey, '2027-01-04');
      expect(p.previous.key, '2026-W52');
    });

    test('week across a month boundary labels both months', () {
      final p = ProgressPeriod.forDate(ProgressHorizon.week, DateTime(2026, 9, 30));
      expect(p.label, '28 Sep – 4 Oct');
    });

    test('month: full calendar month incl. leap February', () {
      final p = ProgressPeriod.forDate(ProgressHorizon.month, DateTime(2028, 2, 10));
      expect(p.key, '2028-02');
      expect(p.endDateKey, '2028-02-29');
      expect(p.dayCount, 29);
      expect(p.label, 'February 2028');
    });

    test('quarter bounds match DirectionPeriods keys', () {
      final p = ProgressPeriod.forDate(ProgressHorizon.quarter, DateTime(2026, 9, 12));
      expect(p.key, '2026-Q3');
      expect(p.startDateKey, '2026-07-01');
      expect(p.endDateKey, '2026-09-30');
      expect(p.dayCount, 92);
      expect(p.label, 'Q3 2026');
      expect(p.previous.key, '2026-Q2');
      expect(p.next.key, '2026-Q4');
      expect(p.next.next.key, '2027-Q1');
    });

    test('year bounds', () {
      final p = ProgressPeriod.forDate(ProgressHorizon.year, DateTime(2026, 9, 12));
      expect(p.key, '2026');
      expect(p.startDateKey, '2026-01-01');
      expect(p.endDateKey, '2026-12-31');
      expect(p.dayCount, 365);
      expect(p.previous.key, '2025');
      expect(p.next.key, '2027');
    });
  });

  group('navigation', () {
    test('previous/next round-trip for every horizon', () {
      for (final h in ProgressHorizon.values) {
        final p = ProgressPeriod.forDate(h, DateTime(2026, 3, 31));
        expect(p.previous.next, p, reason: h.name);
        expect(p.next.previous, p, reason: h.name);
        expect(p.previous.endDateKey.compareTo(p.startDateKey) < 0, isTrue);
      }
    });

    test('month previous from a 31st does not skip a month', () {
      final p = ProgressPeriod.forDate(ProgressHorizon.month, DateTime(2026, 3, 31));
      expect(p.previous.key, '2026-02');
      expect(p.previous.previous.key, '2026-01');
      expect(p.previous.previous.previous.key, '2025-12');
    });

    test('contains / isCurrent / startsAfterToday', () {
      final now = DateTime(2026, 9, 12);
      final week = ProgressPeriod.current(ProgressHorizon.week, now);
      expect(week.contains('2026-09-12'), isTrue);
      expect(week.contains('2026-09-14'), isFalse);
      expect(week.isCurrent(now), isTrue);
      expect(week.startsAfterToday(now), isFalse);
      expect(week.next.startsAfterToday(now), isTrue);
      expect(week.previous.isCurrent(now), isFalse);
    });
  });

  group('scopeLabel', () {
    final now = DateTime(2026, 9, 12);
    test('current periods say THIS …, past ones just name the period', () {
      expect(ProgressPeriod.current(ProgressHorizon.day, now).scopeLabel(now), 'TODAY');
      expect(ProgressPeriod.current(ProgressHorizon.day, now).previous.scopeLabel(now), 'FRI, 11 SEP');
      expect(ProgressPeriod.current(ProgressHorizon.week, now).scopeLabel(now), 'THIS WEEK · 7 – 13 SEP');
      expect(ProgressPeriod.current(ProgressHorizon.week, now).previous.scopeLabel(now), 'WEEK · 31 AUG – 6 SEP');
      expect(ProgressPeriod.current(ProgressHorizon.month, now).scopeLabel(now), 'THIS MONTH · SEPTEMBER 2026');
      expect(ProgressPeriod.current(ProgressHorizon.month, now).previous.scopeLabel(now), 'AUGUST 2026');
      expect(ProgressPeriod.current(ProgressHorizon.quarter, now).scopeLabel(now), 'THIS QUARTER · Q3 2026');
      expect(ProgressPeriod.current(ProgressHorizon.year, now).previous.scopeLabel(now), '2025');
    });
  });
}
