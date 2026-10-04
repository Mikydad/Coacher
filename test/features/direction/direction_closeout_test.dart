import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/context_override/domain/models/interruption_level.dart';
import 'package:sidepal/features/direction/application/direction_closeout.dart';
import 'package:sidepal/features/direction/domain/direction_periods.dart';
import 'package:sidepal/features/direction/domain/models/direction_entry.dart';

/// End-of-period close-out (Miko, 2026-09-19): one quiet notice on the
/// period's last evening for a written, unanswered direction; nothing for
/// answered, cleared or past ones.
DirectionEntry _entry(
  DirectionHorizon h,
  DateTime at,
  String text, {
  DirectionOutcome? outcome,
}) {
  final e = DirectionEntry.forPeriod(
    DirectionPeriods.current(h, at),
    text: text,
    nowMs: at.millisecondsSinceEpoch,
  );
  return outcome == null
      ? e
      : e.copyWith(outcome: outcome, outcomeAtMs: at.millisecondsSinceEpoch);
}

void main() {
  final sept = DateTime(2026, 9, 11, 22);

  group('fireTimeFor', () {
    test('month → last day of the month at 19:00 local', () {
      expect(
        DirectionCloseout.fireTimeFor(
          DirectionPeriods.current(DirectionHorizon.month, sept),
        ),
        DateTime(2026, 9, 30, 19),
      );
    });
    test('quarter → last day of the quarter', () {
      expect(
        DirectionCloseout.fireTimeFor(
          DirectionPeriods.current(DirectionHorizon.quarter, sept),
        ),
        DateTime(2026, 9, 30, 19),
      );
    });
    test('year → Dec 31', () {
      expect(
        DirectionCloseout.fireTimeFor(
          DirectionPeriods.current(DirectionHorizon.year, sept),
        ),
        DateTime(2026, 12, 31, 19),
      );
    });
  });

  group('shouldSchedule', () {
    test('written + unanswered + ahead → yes', () {
      expect(
        DirectionCloseout.shouldSchedule(
          _entry(DirectionHorizon.month, sept, 'Ship it'),
          sept,
        ),
        isTrue,
      );
    });
    test('answered → no', () {
      expect(
        DirectionCloseout.shouldSchedule(
          _entry(
            DirectionHorizon.month,
            sept,
            'Ship it',
            outcome: DirectionOutcome.partly,
          ),
          sept,
        ),
        isFalse,
      );
    });
    test('cleared → no', () {
      expect(
        DirectionCloseout.shouldSchedule(
          _entry(DirectionHorizon.month, sept, ''),
          sept,
        ),
        isFalse,
      );
    });
    test('moment already past → no (the page asks instead)', () {
      expect(
        DirectionCloseout.shouldSchedule(
          _entry(DirectionHorizon.month, sept, 'Ship it'),
          DateTime(2026, 9, 30, 20),
        ),
        isFalse,
      );
    });
  });

  test('notification id is stable and in its own namespace', () {
    final a = DirectionCloseout.notificationId('dir_month_2026-09');
    expect(a, DirectionCloseout.notificationId('dir_month_2026-09'));
    expect(a, isNot(DirectionCloseout.notificationId('dir_month_2026-10')));
    expect(
      DirectionCloseout.payloadFor('dir_month_2026-09'),
      'direction:dir_month_2026-09',
    );
  });

  test('rearm schedules the due ones and cancels the rest', () async {
    final scheduled = <int, DateTime>{};
    final cancelled = <int>[];
    final scheduler = DirectionCloseoutScheduler(
      schedule:
          ({
            required int id,
            required String title,
            required String body,
            required DateTime when,
            required String payload,
            required InterruptionLevel level,
          }) async {
            scheduled[id] = when;
            expect(level, InterruptionLevel.low);
            expect(payload, startsWith('direction:'));
          },
      cancel: (id) async => cancelled.add(id),
      now: () => sept,
    );
    final open = _entry(DirectionHorizon.month, sept, 'Ship it');
    final done = _entry(
      DirectionHorizon.quarter,
      sept,
      'Launch',
      outcome: DirectionOutcome.achieved,
    );
    final august = _entry(DirectionHorizon.month, DateTime(2026, 8, 5), 'Rest');

    await scheduler.rearm([open, done, august]);

    expect(scheduled.keys, [DirectionCloseout.notificationId(open.id)]);
    expect(scheduled.values.single, DateTime(2026, 9, 30, 19));
    expect(
      cancelled,
      unorderedEquals([
        DirectionCloseout.notificationId(done.id),
        DirectionCloseout.notificationId(august.id),
      ]),
    );
  });
}
