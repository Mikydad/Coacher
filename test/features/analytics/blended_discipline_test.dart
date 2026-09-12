import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/analytics/application/blended_discipline.dart';
import 'package:sidepal/features/analytics/application/daily_analytics_engine.dart';
import 'package:sidepal/features/coaching/domain/models/enforcement_mode.dart';

DailyAnalyticsSnapshot _snap(String key, double created, double completed) {
  return DailyAnalyticsSnapshot(
    dateKey: key,
    createdCount: created.round(),
    completedCount: completed.round(),
    weightedCreated: created,
    weightedCompleted: completed,
    completionRate: created == 0 ? 0 : completed / created,
    weightedCompletionRate: created == 0 ? 0 : completed / created,
    schemaVersion: 3,
  );
}

void main() {
  group('blendRates', () {
    test('both planned → 0.6·goal + 0.4·task', () {
      final r = blendRates(
        goalWeightedCreated: 10,
        goalWeightedCompleted: 10, // 1.0
        taskWeightedCreated: 10,
        taskWeightedCompleted: 5, // 0.5
      );
      expect(r, closeTo(0.8, 1e-9));
    });

    test('only goals planned → goal rate, not capped at 60%', () {
      final r = blendRates(
        goalWeightedCreated: 4,
        goalWeightedCompleted: 4,
        taskWeightedCreated: 0,
        taskWeightedCompleted: 0,
      );
      expect(r, 1.0);
    });

    test('only tasks planned → task rate, not capped at 40%', () {
      final r = blendRates(
        goalWeightedCreated: 0,
        goalWeightedCompleted: 0,
        taskWeightedCreated: 8,
        taskWeightedCompleted: 6,
      );
      expect(r, closeTo(0.75, 1e-9));
    });

    test('neither planned → null (quiet day, never 0%)', () {
      expect(
        blendRates(
          goalWeightedCreated: 0,
          goalWeightedCompleted: 0,
          taskWeightedCreated: 0,
          taskWeightedCompleted: 0,
        ),
        isNull,
      );
    });

    test('blendedDayRate tolerates missing snapshots', () {
      expect(blendedDayRate(null, null), isNull);
      expect(blendedDayRate(_snap('2026-09-01', 2, 1), null), 0.5);
      expect(blendedDayRate(null, _snap('2026-09-01', 2, 2)), 1.0);
    });

    test('blendedPeriodRate is weighted over sums, not a mean of day rates', () {
      final goal = rollupDailyAnalytics(
        snapshots: [
          _snap('2026-09-01', 1, 1), // light day, 100%
          _snap('2026-09-02', 9, 0), // heavy day, 0%
        ],
        now: DateTime(2026, 9, 3),
      );
      final task = rollupDailyAnalytics(
        snapshots: [_snap('2026-09-01', 10, 10)],
        now: DateTime(2026, 9, 3),
      );
      // goal = 1/10 = 0.1 (not the 0.5 mean), task = 1.0
      expect(blendedPeriodRate(goal, task), closeTo(0.6 * 0.1 + 0.4 * 1.0, 1e-9));
    });
  });

  group('ringStateFor', () {
    test('threshold follows the enforcement mode', () {
      RingState at(double v, EnforcementMode m) => ringStateFor(
        blended: v,
        isProtected: false,
        isFuture: false,
        mode: m,
      );
      expect(at(0.8, EnforcementMode.flexible), RingState.qualified);
      expect(at(0.8, EnforcementMode.disciplined), RingState.partial);
      expect(at(0.9, EnforcementMode.disciplined), RingState.qualified);
      expect(at(0.99, EnforcementMode.extreme), RingState.partial);
      expect(at(1.0, EnforcementMode.extreme), RingState.qualified);
    });

    test('missed, quiet, future, protected precedence', () {
      expect(
        ringStateFor(blended: 0, isProtected: false, isFuture: false, mode: EnforcementMode.flexible),
        RingState.missed,
      );
      expect(
        ringStateFor(blended: null, isProtected: false, isFuture: false, mode: EnforcementMode.flexible),
        RingState.quiet,
      );
      expect(
        ringStateFor(blended: null, isProtected: true, isFuture: false, mode: EnforcementMode.flexible),
        RingState.protected,
      );
      expect(
        ringStateFor(blended: 0.3, isProtected: true, isFuture: false, mode: EnforcementMode.flexible),
        RingState.protected,
      );
      // A protected day that qualified on its own is still qualified.
      expect(
        ringStateFor(blended: 1.0, isProtected: true, isFuture: false, mode: EnforcementMode.flexible),
        RingState.qualified,
      );
      expect(
        ringStateFor(blended: 1.0, isProtected: false, isFuture: true, mode: EnforcementMode.flexible),
        RingState.future,
      );
    });
  });

  group('streaks', () {
    const mode = EnforcementMode.disciplined; // 90%
    final rates = <String, double?>{
      '2026-09-05': 1.0,
      '2026-09-06': 1.0,
      '2026-09-07': 0.5, // break
      '2026-09-08': 0.95,
      '2026-09-09': null, // quiet → breaks (decision Q2)
      '2026-09-10': 1.0,
      '2026-09-11': 1.0,
      '2026-09-12': 1.0,
    };

    test('current streak walks back from today and stops at a quiet day', () {
      expect(
        blendedCurrentStreak(
          ratesByDateKey: rates,
          todayKey: '2026-09-12',
          earliestDateKey: '2026-09-01',
          protectedDateKeys: const {},
          mode: mode,
        ),
        3,
      );
    });

    test('protected quiet day bridges the streak', () {
      expect(
        blendedCurrentStreak(
          ratesByDateKey: rates,
          todayKey: '2026-09-12',
          earliestDateKey: '2026-09-01',
          protectedDateKeys: const {'2026-09-09'},
          mode: mode,
        ),
        5,
      );
    });

    test('current streak never walks past earliestDateKey', () {
      expect(
        blendedCurrentStreak(
          ratesByDateKey: rates,
          todayKey: '2026-09-12',
          earliestDateKey: '2026-09-11',
          protectedDateKeys: const {},
          mode: mode,
        ),
        2,
      );
    });

    test('best streak within a window ignores days after today', () {
      expect(
        blendedBestStreak(
          ratesByDateKey: rates,
          startDateKey: '2026-09-01',
          endDateKey: '2026-09-30',
          todayKey: '2026-09-12',
          protectedDateKeys: const {},
          mode: mode,
        ),
        3,
      );
      expect(
        blendedBestStreak(
          ratesByDateKey: rates,
          startDateKey: '2026-09-01',
          endDateKey: '2026-09-08',
          todayKey: '2026-09-12',
          protectedDateKeys: const {},
          mode: mode,
        ),
        2,
      );
    });
  });
}
