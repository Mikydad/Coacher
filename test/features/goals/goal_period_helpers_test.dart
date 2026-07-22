import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/goals/application/goal_period_helpers.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/goal_categories.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:flutter_test/flutter_test.dart';

UserGoal _goalForMarch2025({
  GoalRepeatCadence? repeatCadence,
  int repeatInterval = 1,
  List<int>? scheduledWeekdays,
  List<int>? repeatDaysOfMonth,
}) {
  final b = GoalPeriodHelpers.localCalendarMonthBounds(2025, 3);
  return UserGoal(
    id: 'g1',
    title: 'Test',
    categoryId: GoalCategories.study,
    status: GoalStatus.active,
    measurementKind: MeasurementKind.minutes,
    targetValue: 30,
    intensity: 3,
    periodStartMs: b.startMs,
    periodEndMs: b.endMs,
    repeatCadence:
        repeatCadence ??
        (scheduledWeekdays != null
            ? GoalRepeatCadence.weekly
            : GoalRepeatCadence.off),
    repeatInterval: repeatInterval,
    scheduledWeekdays: scheduledWeekdays,
    repeatDaysOfMonth: repeatDaysOfMonth,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

const _mwf = [DateTime.monday, DateTime.wednesday, DateTime.friday];

void main() {
  test('March 2025 has 31 calendar days', () {
    final g = _goalForMarch2025();
    expect(GoalPeriodHelpers.totalCalendarDaysInPeriod(g), 31);
  });

  test('isDateKeyInPeriod for March boundaries', () {
    final g = _goalForMarch2025();
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-03-01'), true);
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-03-31'), true);
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-02-28'), false);
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-04-01'), false);
  });

  test('daysElapsedInPeriodThrough caps at period end', () {
    final g = _goalForMarch2025();
    final april = DateTime(2025, 4, 10);
    expect(GoalPeriodHelpers.daysElapsedInPeriodThrough(g, april), 31);
  });

  test('DateKeys.parseLocalDateKey round-trip', () {
    final d = DateTime(2025, 1, 5);
    final k = DateKeys.yyyymmdd(d);
    expect(DateKeys.parseLocalDateKey(k), DateTime(2025, 1, 5));
  });

  test('localDurationDayCount: 30 days from Mar 1 ends Mar 30 inclusive', () {
    final b = GoalPeriodHelpers.localDurationDayCount(DateTime(2025, 3, 1), 30);
    final g = UserGoal(
      id: 'g2',
      title: 'Test',
      categoryId: GoalCategories.study,
      status: GoalStatus.active,
      measurementKind: MeasurementKind.minutes,
      targetValue: 30,
      intensity: 3,
      periodStartMs: b.startMs,
      periodEndMs: b.endMs,
      periodMode: GoalPeriodMode.durationDays,
      durationDays: 30,
      createdAtMs: 0,
      updatedAtMs: 0,
    );
    expect(GoalPeriodHelpers.totalCalendarDaysInPeriod(g), 30);
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-03-30'), true);
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-03-31'), false);
  });

  group('repeat schedule — action days', () {
    test('isGoalActiveOnDateKey true only on action days in period', () {
      final g = _goalForMarch2025(scheduledWeekdays: _mwf);
      // 2025-03-03 is a Monday, 03-04 a Tuesday.
      expect(GoalPeriodHelpers.isGoalActiveOnDateKey(g, '2025-03-03'), true);
      expect(GoalPeriodHelpers.isGoalActiveOnDateKey(g, '2025-03-04'), false);
      // Scheduled weekday outside the period.
      expect(GoalPeriodHelpers.isGoalActiveOnDateKey(g, '2025-04-02'), false);
    });

    test('repeat-off goal has no action days but always allows logging', () {
      final g = _goalForMarch2025(); // repeat off
      expect(GoalPeriodHelpers.isGoalActiveOnDateKey(g, '2025-03-04'), false);
      expect(GoalPeriodHelpers.allowsLoggingOnDateKey(g, '2025-03-04'), true);
      // Outside the period nothing is loggable.
      expect(GoalPeriodHelpers.allowsLoggingOnDateKey(g, '2025-04-01'), false);
    });

    test('daily repeat covers every period day; repeating goal gates logging', () {
      final daily = _goalForMarch2025(repeatCadence: GoalRepeatCadence.daily);
      expect(GoalPeriodHelpers.isGoalActiveOnDateKey(daily, '2025-03-04'), true);
      final mwf = _goalForMarch2025(scheduledWeekdays: _mwf);
      expect(GoalPeriodHelpers.allowsLoggingOnDateKey(mwf, '2025-03-04'), false);
      expect(GoalPeriodHelpers.allowsLoggingOnDateKey(mwf, '2025-03-05'), true);
    });

    test('daily repeat with interval anchors at period start', () {
      // Period starts Sat 2025-03-01; every 3 days → 1, 4, 7, ...
      final g = _goalForMarch2025(
        repeatCadence: GoalRepeatCadence.daily,
        repeatInterval: 3,
      );
      expect(g.isActionDay(DateTime(2025, 3, 1)), isTrue);
      expect(g.isActionDay(DateTime(2025, 3, 2)), isFalse);
      expect(g.isActionDay(DateTime(2025, 3, 4)), isTrue);
      expect(g.isActionDay(DateTime(2025, 3, 7)), isTrue);
    });

    test('weekly repeat with interval skips alternate weeks', () {
      // Period starts Sat 2025-03-01 (week of Mon 2025-02-24).
      // Every 2 weeks on Monday → Mar 10 is week+2 (yes), Mar 3 week+1 (no).
      final g = _goalForMarch2025(
        repeatCadence: GoalRepeatCadence.weekly,
        repeatInterval: 2,
        scheduledWeekdays: const [DateTime.monday],
      );
      expect(g.isActionDay(DateTime(2025, 3, 3)), isFalse);
      expect(g.isActionDay(DateTime(2025, 3, 10)), isTrue);
      expect(g.isActionDay(DateTime(2025, 3, 17)), isFalse);
      expect(g.isActionDay(DateTime(2025, 3, 24)), isTrue);
    });

    test('monthly repeat matches selected days of month', () {
      final g = _goalForMarch2025(
        repeatCadence: GoalRepeatCadence.monthly,
        repeatDaysOfMonth: const [1, 15],
      );
      expect(g.isActionDay(DateTime(2025, 3, 1)), isTrue);
      expect(g.isActionDay(DateTime(2025, 3, 15)), isTrue);
      expect(g.isActionDay(DateTime(2025, 3, 14)), isFalse);
    });

    test('totalScheduledDaysInPeriod counts only Mon/Wed/Fri', () {
      final g = _goalForMarch2025(scheduledWeekdays: _mwf);
      // March 2025: Mondays 3,10,17,24,31 (5) + Wednesdays 5,12,19,26 (4)
      // + Fridays 7,14,21,28 (4) = 13.
      expect(GoalPeriodHelpers.totalScheduledDaysInPeriod(g), 13);
    });

    test('scheduledDaysElapsedThrough counts action days up to now', () {
      final g = _goalForMarch2025(scheduledWeekdays: _mwf);
      // Through Sat 2025-03-08: Mon 3, Wed 5, Fri 7 → 3.
      expect(
        GoalPeriodHelpers.scheduledDaysElapsedThrough(g, DateTime(2025, 3, 8)),
        3,
      );
      // Before the period starts.
      expect(
        GoalPeriodHelpers.scheduledDaysElapsedThrough(g, DateTime(2025, 2, 1)),
        0,
      );
      // After the period ends: same as total.
      expect(
        GoalPeriodHelpers.scheduledDaysElapsedThrough(g, DateTime(2025, 4, 10)),
        13,
      );
    });

    test('formatWeekdays renders sorted labels', () {
      expect(
        GoalPeriodHelpers.formatWeekdays(const [
          DateTime.friday,
          DateTime.monday,
          DateTime.wednesday,
        ]),
        'Mon · Wed · Fri',
      );
      expect(GoalPeriodHelpers.formatWeekdays(const []), '');
    });

    test('formatRepeatSummary covers cadences and intervals', () {
      expect(
        GoalPeriodHelpers.formatRepeatSummary(_goalForMarch2025()),
        '',
      );
      expect(
        GoalPeriodHelpers.formatRepeatSummary(
          _goalForMarch2025(repeatCadence: GoalRepeatCadence.daily),
        ),
        'Every day',
      );
      expect(
        GoalPeriodHelpers.formatRepeatSummary(
          _goalForMarch2025(
            repeatCadence: GoalRepeatCadence.daily,
            repeatInterval: 2,
          ),
        ),
        'Every 2 days',
      );
      expect(
        GoalPeriodHelpers.formatRepeatSummary(
          _goalForMarch2025(scheduledWeekdays: _mwf),
        ),
        'Every week on Mon · Wed · Fri',
      );
      expect(
        GoalPeriodHelpers.formatRepeatSummary(
          _goalForMarch2025(
            repeatCadence: GoalRepeatCadence.monthly,
            repeatDaysOfMonth: const [1, 15],
          ),
        ),
        'Every month on the 1st · 15th',
      );
    });

    test('repeat fields roundtrip through map', () {
      final g = _goalForMarch2025(
        scheduledWeekdays: _mwf,
        repeatInterval: 2,
      );
      final restored = UserGoal.fromMap(g.toMap());
      expect(restored.repeatCadence, GoalRepeatCadence.weekly);
      expect(restored.repeatInterval, 2);
      expect(restored.scheduledWeekdays, _mwf);
      final off = UserGoal.fromMap(_goalForMarch2025().toMap());
      expect(off.repeatCadence, GoalRepeatCadence.off);
      expect(off.scheduledWeekdays, isNull);
    });

    test('legacy maps derive a repeat cadence', () {
      // Pre-repeat goals: weekday list → weekly, otherwise daily.
      final legacyWeekly = _goalForMarch2025(scheduledWeekdays: _mwf).toMap()
        ..remove('repeatCadence')
        ..remove('repeatInterval');
      expect(
        UserGoal.fromMap(legacyWeekly).repeatCadence,
        GoalRepeatCadence.weekly,
      );
      final legacyPlain = _goalForMarch2025().toMap()
        ..remove('repeatCadence')
        ..remove('repeatInterval');
      expect(
        UserGoal.fromMap(legacyPlain).repeatCadence,
        GoalRepeatCadence.daily,
      );
    });

    test('validate rejects bad weekdays, month days, and intervals', () {
      expect(
        () => _goalForMarch2025(scheduledWeekdays: const [0]).validate(),
        throwsArgumentError,
      );
      expect(
        () => _goalForMarch2025(scheduledWeekdays: const [8]).validate(),
        throwsArgumentError,
      );
      expect(
        () => _goalForMarch2025(scheduledWeekdays: const [1, 1]).validate(),
        throwsArgumentError,
      );
      expect(
        () => _goalForMarch2025(
          repeatCadence: GoalRepeatCadence.monthly,
          repeatDaysOfMonth: const [0],
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => _goalForMarch2025(
          repeatCadence: GoalRepeatCadence.monthly,
          repeatDaysOfMonth: const [32],
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => _goalForMarch2025(
          repeatCadence: GoalRepeatCadence.daily,
          repeatInterval: 0,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => _goalForMarch2025(scheduledWeekdays: _mwf).validate(),
        returnsNormally,
      );
    });
  });

  group('evaluation window (derived from repeat)', () {
    test('daily repeat: window is today', () {
      final g = _goalForMarch2025(repeatCadence: GoalRepeatCadence.daily);
      final w = GoalPeriodHelpers.evaluationWindow(g, DateTime(2025, 3, 12));
      expect(w.start, DateTime(2025, 3, 12));
      expect(w.end, DateTime(2025, 3, 12));
    });

    test('every-3-days repeat: window is the 3-day block from the start', () {
      final g = _goalForMarch2025(
        repeatCadence: GoalRepeatCadence.daily,
        repeatInterval: 3,
      );
      // Blocks: Mar 1–3, 4–6, 7–9… Mar 5 falls in the second block.
      final w = GoalPeriodHelpers.evaluationWindow(g, DateTime(2025, 3, 5));
      expect(w.start, DateTime(2025, 3, 4));
      expect(w.end, DateTime(2025, 3, 6));
    });

    test('weekly repeat: window is Mon–Sun clamped to the period', () {
      final g = _goalForMarch2025(scheduledWeekdays: _mwf);
      // Wed 2025-03-12 → Mon 10 .. Sun 16.
      final w = GoalPeriodHelpers.evaluationWindow(g, DateTime(2025, 3, 12));
      expect(w.start, DateTime(2025, 3, 10));
      expect(w.end, DateTime(2025, 3, 16));
      // Sat 2025-03-01 → week starts Mon 02-24, clamped to period start.
      final clamped = GoalPeriodHelpers.evaluationWindow(
        g,
        DateTime(2025, 3, 1),
      );
      expect(clamped.start, DateTime(2025, 3, 1));
      expect(clamped.end, DateTime(2025, 3, 2));
    });

    test('every-2-weeks repeat: window is the 2-week block', () {
      final g = _goalForMarch2025(
        repeatCadence: GoalRepeatCadence.weekly,
        repeatInterval: 2,
        scheduledWeekdays: const [DateTime.monday],
      );
      // Anchor week: Mon 2025-02-24. Blocks: Feb 24–Mar 9, Mar 10–23…
      final w = GoalPeriodHelpers.evaluationWindow(g, DateTime(2025, 3, 12));
      expect(w.start, DateTime(2025, 3, 10));
      expect(w.end, DateTime(2025, 3, 23));
    });

    test('monthly repeat: window is the calendar month', () {
      final g = _goalForMarch2025(
        repeatCadence: GoalRepeatCadence.monthly,
        repeatDaysOfMonth: const [1, 15],
      );
      final w = GoalPeriodHelpers.evaluationWindow(g, DateTime(2025, 3, 12));
      expect(w.start, DateTime(2025, 3, 1));
      expect(w.end, DateTime(2025, 3, 31));
    });

    test('repeat off: window spans the whole period and never resets', () {
      final g = _goalForMarch2025();
      expect(g.horizon, GoalHorizon.entireGoal);
      final w = GoalPeriodHelpers.evaluationWindow(g, DateTime(2025, 3, 12));
      expect(w.start, DateTime(2025, 3, 1));
      expect(w.end, DateTime(2025, 3, 31));
    });

    test('now outside the period clamps to the nearest edge', () {
      final g = _goalForMarch2025(repeatCadence: GoalRepeatCadence.daily);
      final before = GoalPeriodHelpers.evaluationWindow(
        g,
        DateTime(2025, 2, 10),
      );
      expect(before.start, DateTime(2025, 3, 1));
      final after = GoalPeriodHelpers.evaluationWindow(
        g,
        DateTime(2025, 4, 10),
      );
      expect(after.end, DateTime(2025, 3, 31));
    });

    test('horizon derives from repeat cadence', () {
      expect(
        _goalForMarch2025(repeatCadence: GoalRepeatCadence.daily).horizon,
        GoalHorizon.daily,
      );
      expect(
        _goalForMarch2025(scheduledWeekdays: _mwf).horizon,
        GoalHorizon.weekly,
      );
      expect(
        _goalForMarch2025(
          repeatCadence: GoalRepeatCadence.monthly,
          repeatDaysOfMonth: const [1],
        ).horizon,
        GoalHorizon.monthly,
      );
      expect(_goalForMarch2025().horizon, GoalHorizon.entireGoal);
    });
  });
}
