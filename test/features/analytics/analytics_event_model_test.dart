import 'package:coach_for_life/features/analytics/domain/models/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AnalyticsEvent toMap/fromMap roundtrip', () {
    final event = AnalyticsEvent(
      id: 'evt-1',
      type: AnalyticsEventType.habitCompleted,
      entityId: 'habit-1',
      entityKind: 'habit',
      dateKey: '2026-05-02',
      timestampLocalIso: '2026-05-02T07:30:00.000',
      sourceSurface: 'home',
      idempotencyKey: 'habit-1-2026-05-02-complete',
      modeRefId: 'disciplined',
      reason: 'done early',
      createdAtMs: 1,
      updatedAtMs: 2,
      schemaVersion: 1,
    );
    final restored = AnalyticsEvent.fromMap(event.toMap());
    expect(restored.id, event.id);
    expect(restored.type, AnalyticsEventType.habitCompleted);
    expect(restored.idempotencyKey, event.idempotencyKey);
    expect(restored.schemaVersion, 1);
  });

  test('AnalyticsEvent fallback defaults for legacy maps', () {
    final restored = AnalyticsEvent.fromMap({
      'id': 'evt-legacy',
      'entityId': 'task-1',
      'entityKind': 'task',
      'dateKey': '2026-05-02',
      'timestampLocalIso': '2026-05-02T09:00:00.000',
      'sourceSurface': 'timer',
      'idempotencyKey': 'legacy',
      'createdAtMs': 1,
      'updatedAtMs': 2,
    });
    expect(restored.type, AnalyticsEventType.taskStarted);
    expect(restored.schemaVersion, 1);
  });
}
