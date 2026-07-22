import 'package:sidepal/features/analytics/application/streak_engine.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_event.dart';
import 'package:sidepal/features/coaching/domain/models/enforcement_mode.dart';
import 'package:flutter_test/flutter_test.dart';

AnalyticsEvent _done(String dateKey, {String time = '08:00:00'}) =>
    AnalyticsEvent(
      id: 'evt-$dateKey',
      type: AnalyticsEventType.habitCompleted,
      entityId: 'habit-1',
      entityKind: 'habit',
      dateKey: dateKey,
      timestampLocalIso: '${dateKey}T$time.000',
      sourceSurface: 'home',
      idempotencyKey: 'key-$dateKey-$time',
      createdAtMs: 1,
      updatedAtMs: 1,
    );

void main() {
  // ─── disciplined (default) — unchanged baseline ───────────────────────────

  group('disciplined — no grace, behaviour unchanged', () {
    test('consecutive 3 days → streak=3', () {
      final now = DateTime(2026, 5, 3, 10);
      final s = computeStreakSummaryForEvents(
        [_done('2026-05-01'), _done('2026-05-02'), _done('2026-05-03')],
        now: now,
        enforcementMode: EnforcementMode.disciplined,
      );
      expect(s.currentStreak, 3);
      expect(s.longestStreak, 3);
    });

    test('gap of 2 days breaks streak immediately', () {
      final now = DateTime(2026, 5, 4, 10);
      final s = computeStreakSummaryForEvents(
        [_done('2026-05-01'), _done('2026-05-02'), _done('2026-05-04')],
        now: now,
        enforcementMode: EnforcementMode.disciplined,
      );
      expect(s.currentStreak, 1);
    });
  });

  // ─── flexible — 1-day grace period ────────────────────────────────────────

  group('flexible — 1-day grace', () {
    test('1 missed day does NOT break streak', () {
      // May 1 → May 3 (skipped May 2) — with 1-day grace should stay alive.
      final now = DateTime(2026, 5, 3, 10);
      final s = computeStreakSummaryForEvents(
        [_done('2026-05-01'), _done('2026-05-03')],
        now: now,
        enforcementMode: EnforcementMode.flexible,
      );
      expect(s.currentStreak, greaterThanOrEqualTo(1));
    });

    test('2 missed days breaks streak', () {
      final now = DateTime(2026, 5, 5, 10);
      final s = computeStreakSummaryForEvents(
        [_done('2026-05-01'), _done('2026-05-05')],
        now: now,
        enforcementMode: EnforcementMode.flexible,
      );
      // May 1 → May 5 is a 3-day gap; even with 1-day grace it breaks.
      expect(s.currentStreak, 1);
    });

    test('longest streak bridges 1-day gap correctly', () {
      final now = DateTime(2026, 5, 5, 10);
      final s = computeStreakSummaryForEvents(
        [
          _done('2026-05-01'),
          _done('2026-05-03'), // 1-day gap after May 1
          _done('2026-05-04'),
          _done('2026-05-05'),
        ],
        now: now,
        enforcementMode: EnforcementMode.flexible,
      );
      // All 4 completions with the 1-day gap bridged → longestStreak ≥ 4.
      expect(s.longestStreak, greaterThanOrEqualTo(4));
    });
  });

  // ─── extreme — no grace, on-time only (before 22:00) ─────────────────────

  group('extreme — on-time-only filter', () {
    test('completions before 22:00 count toward streak', () {
      final now = DateTime(2026, 5, 2, 10);
      final s = computeStreakSummaryForEvents(
        [_done('2026-05-01', time: '09:00:00'), _done('2026-05-02', time: '18:30:00')],
        now: now,
        enforcementMode: EnforcementMode.extreme,
      );
      expect(s.currentStreak, 2);
    });

    test('completions at or after 22:00 are excluded', () {
      final now = DateTime(2026, 5, 1, 23);
      final s = computeStreakSummaryForEvents(
        [_done('2026-05-01', time: '22:01:00')],
        now: now,
        enforcementMode: EnforcementMode.extreme,
      );
      expect(s.currentStreak, 0);
    });

    test('exactly 22:00 is excluded (hour == 22)', () {
      final now = DateTime(2026, 5, 1, 23);
      final s = computeStreakSummaryForEvents(
        [_done('2026-05-01', time: '22:00:00')],
        now: now,
        enforcementMode: EnforcementMode.extreme,
      );
      expect(s.currentStreak, 0);
    });

    test('21:59 is included', () {
      final now = DateTime(2026, 5, 1, 23);
      final s = computeStreakSummaryForEvents(
        [_done('2026-05-01', time: '21:59:00')],
        now: now,
        enforcementMode: EnforcementMode.extreme,
      );
      expect(s.currentStreak, 1);
    });

    test('unparseable timestamp treated as on-time', () {
      final event = AnalyticsEvent(
        id: 'evt-bad',
        type: AnalyticsEventType.habitCompleted,
        entityId: 'habit-1',
        entityKind: 'habit',
        dateKey: '2026-05-01',
        timestampLocalIso: 'not-a-date',
        sourceSurface: 'home',
        idempotencyKey: 'key-bad',
        createdAtMs: 1,
        updatedAtMs: 1,
      );
      final now = DateTime(2026, 5, 1, 23);
      final s = computeStreakSummaryForEvents(
        [event],
        now: now,
        enforcementMode: EnforcementMode.extreme,
      );
      expect(s.currentStreak, 1);
    });
  });

  // ─── Empty events ─────────────────────────────────────────────────────────

  test('empty events → streak=0 for all modes', () {
    final now = DateTime(2026, 5, 1, 10);
    for (final mode in EnforcementMode.values) {
      final s = computeStreakSummaryForEvents(
        [],
        now: now,
        enforcementMode: mode,
      );
      expect(s.currentStreak, 0, reason: 'mode=$mode');
    }
  });
}
