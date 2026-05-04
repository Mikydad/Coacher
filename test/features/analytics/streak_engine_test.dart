import 'package:coach_for_life/features/analytics/application/streak_engine.dart';
import 'package:coach_for_life/features/analytics/domain/models/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

AnalyticsEvent _habitDone(String dateKey) {
  return AnalyticsEvent(
    id: 'evt-$dateKey',
    type: AnalyticsEventType.habitCompleted,
    entityId: 'habit-1',
    entityKind: 'habit',
    dateKey: dateKey,
    timestampLocalIso: '${dateKey}T08:00:00.000',
    sourceSurface: 'home',
    idempotencyKey: 'key-$dateKey',
    createdAtMs: 1,
    updatedAtMs: 1,
  );
}

void main() {
  test('computes current and longest streak from contiguous days', () {
    final now = DateTime(2026, 5, 3, 10, 0);
    final summary = computeStreakSummaryForEvents(
      [
        _habitDone('2026-05-01'),
        _habitDone('2026-05-02'),
        _habitDone('2026-05-03'),
      ],
      now: now,
    );
    expect(summary.currentStreak, 3);
    expect(summary.longestStreak, 3);
  });

  test('ignores duplicates and invalid date keys', () {
    final now = DateTime(2026, 5, 3, 10, 0);
    final summary = computeStreakSummaryForEvents(
      [
        _habitDone('2026-05-02'),
        _habitDone('2026-05-02'),
        AnalyticsEvent(
          id: 'evt-invalid',
          type: AnalyticsEventType.habitCompleted,
          entityId: 'habit-1',
          entityKind: 'habit',
          dateKey: 'not-a-date',
          timestampLocalIso: '2026-05-02T08:00:00.000',
          sourceSurface: 'home',
          idempotencyKey: 'key-invalid',
          createdAtMs: 1,
          updatedAtMs: 1,
        ),
      ],
      now: now,
    );
    expect(summary.currentStreak, 1);
    expect(summary.longestStreak, 1);
  });

  test('keeps streak when yesterday was completed and today is not yet', () {
    final now = DateTime(2026, 5, 3, 7, 0);
    final summary = computeStreakSummaryForEvents(
      [
        _habitDone('2026-05-01'),
        _habitDone('2026-05-02'),
      ],
      now: now,
    );
    expect(summary.currentStreak, 2);
    expect(summary.longestStreak, 2);
  });

  test('drops current streak if gap larger than one day', () {
    final now = DateTime(2026, 5, 5, 10, 0);
    final summary = computeStreakSummaryForEvents(
      [
        _habitDone('2026-05-01'),
        _habitDone('2026-05-03'),
      ],
      now: now,
    );
    expect(summary.currentStreak, 0);
    expect(summary.longestStreak, 1);
  });
}
