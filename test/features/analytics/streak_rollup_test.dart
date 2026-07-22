import 'package:sidepal/features/analytics/application/daily_analytics_engine.dart';
import 'package:sidepal/features/coaching/application/enforcement_mode_policy.dart';
import 'package:sidepal/features/coaching/domain/models/enforcement_mode.dart';
import 'package:flutter_test/flutter_test.dart';

DailyAnalyticsSnapshot _day(String key, double rate) {
  return DailyAnalyticsSnapshot(
    dateKey: key,
    createdCount: 3,
    completedCount: (rate * 3).round(),
    weightedCreated: 10,
    weightedCompleted: rate * 10,
    completionRate: rate,
    weightedCompletionRate: rate,
    schemaVersion: 3,
  );
}

void main() {
  group('rollupDailyAnalytics streak thresholds', () {
    test('disciplined: 88% day does not qualify', () {
      final now = DateTime(2026, 5, 23);
      final rollup = rollupDailyAnalytics(
        snapshots: [
          _day('2026-05-19', 1.0),
          _day('2026-05-20', 1.0),
          _day('2026-05-21', 1.0),
          _day('2026-05-22', 1.0),
          _day('2026-05-23', 0.88),
        ],
        now: now,
        enforcementMode: EnforcementMode.disciplined,
      );
      expect(rollup.bestStreakDays, 4);
      expect(rollup.currentStreakDays, 0);
    });

    test('flexible: 96% day qualifies (almost everything done)', () {
      final now = DateTime(2026, 5, 23);
      final rollup = rollupDailyAnalytics(
        snapshots: [
          _day('2026-05-22', 1.0),
          _day('2026-05-23', 0.96),
        ],
        now: now,
        enforcementMode: EnforcementMode.flexible,
      );
      expect(rollup.currentStreakDays, 2);
    });

    test('extreme: 96% day does not qualify', () {
      final now = DateTime(2026, 5, 23);
      final rollup = rollupDailyAnalytics(
        snapshots: [
          _day('2026-05-22', 1.0),
          _day('2026-05-23', 0.96),
        ],
        now: now,
        enforcementMode: EnforcementMode.extreme,
      );
      expect(rollup.bestStreakDays, 1);
      expect(rollup.currentStreakDays, 0);
    });

    test('flexible: 85% day qualifies', () {
      final now = DateTime(2026, 5, 23);
      final rollup = rollupDailyAnalytics(
        snapshots: [
          _day('2026-05-19', 0.85),
          _day('2026-05-20', 0.85),
          _day('2026-05-21', 0.85),
          _day('2026-05-22', 0.85),
          _day('2026-05-23', 0.85),
        ],
        now: now,
        enforcementMode: EnforcementMode.flexible,
      );
      expect(rollup.currentStreakDays, 5);
    });

    test('protected day bridges gap without completion', () {
      final now = DateTime(2026, 5, 23);
      final rollup = rollupDailyAnalytics(
        snapshots: [
          _day('2026-05-21', 1.0),
          _day('2026-05-22', 1.0),
          _day('2026-05-23', 1.0),
        ],
        now: now,
        enforcementMode: EnforcementMode.disciplined,
        protectedDateKeys: {'2026-05-22'},
      );
      expect(rollup.currentStreakDays, 3);
    });
  });

  group('EnforcementModePolicy.streakDayThreshold', () {
    test('thresholds match spec', () {
      expect(
        EnforcementModePolicy.streakDayThreshold(EnforcementMode.flexible),
        0.80,
      );
      expect(
        EnforcementModePolicy.streakDayThreshold(EnforcementMode.disciplined),
        0.90,
      );
      expect(
        EnforcementModePolicy.streakDayThreshold(EnforcementMode.extreme),
        1.0,
      );
    });
  });
}
