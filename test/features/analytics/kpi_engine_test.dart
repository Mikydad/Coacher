import 'package:coach_for_life/features/analytics/application/kpi_engine.dart';
import 'package:coach_for_life/features/analytics/domain/models/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

AnalyticsEvent _evt({
  required AnalyticsEventType type,
  required String dateKey,
}) {
  return AnalyticsEvent(
    id: '${type.name}-$dateKey',
    type: type,
    entityId: 'habit-1',
    entityKind: 'habit',
    dateKey: dateKey,
    timestampLocalIso: '${dateKey}T08:00:00.000',
    sourceSurface: 'home',
    idempotencyKey: '${type.name}-$dateKey',
    createdAtMs: 1,
    updatedAtMs: 1,
  );
}

void main() {
  test('computes today and weekly completion rates', () {
    final now = DateTime(2026, 5, 10, 12, 0);
    final out = computeHabitKpisFromEvents([
      _evt(type: AnalyticsEventType.habitCompleted, dateKey: '2026-05-10'),
      _evt(type: AnalyticsEventType.habitCompleted, dateKey: '2026-05-09'),
      _evt(type: AnalyticsEventType.habitCompleted, dateKey: '2026-05-08'),
    ], now: now);
    expect(out.todayCompletionRate, 1.0);
    expect(out.weeklyCompletionRate, closeTo(3 / 7, 0.0001));
    expect(out.completedDaysInWindow, 3);
    expect(out.weeklySeries.length, 7);
    expect(out.weeklySeries.last, 1.0);
  });

  test('risk is medium when yesterday missed', () {
    final now = DateTime(2026, 5, 10, 12, 0);
    final out = computeHabitKpisFromEvents([
      _evt(type: AnalyticsEventType.habitCompleted, dateKey: '2026-05-08'),
    ], now: now);
    expect(out.riskLevel, HabitRiskLevel.medium);
  });

  test('risk is high when two consecutive recent days missed', () {
    final now = DateTime(2026, 5, 10, 12, 0);
    final out = computeHabitKpisFromEvents([
      _evt(type: AnalyticsEventType.habitCompleted, dateKey: '2026-05-07'),
    ], now: now);
    expect(out.riskLevel, HabitRiskLevel.high);
  });

  test('defaults are safe when no usable events', () {
    final now = DateTime(2026, 5, 10, 12, 0);
    final out = computeHabitKpisFromEvents(const [], now: now);
    expect(out.todayCompletionRate, 0);
    expect(out.weeklyCompletionRate, 0);
    expect(out.riskLevel, HabitRiskLevel.high);
    expect(out.weeklySeries, [0, 0, 0, 0, 0, 0, 0]);
  });
}
