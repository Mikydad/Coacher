import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReminderConfig.toMap includes modeRefId and blockUrgencyScore', () {
    final r = ReminderConfig(
      id: 'r1',
      taskId: 't1',
      enabled: true,
      scheduledAtIso: '2026-03-24T10:00:00.000',
      modeRefId: 'disciplined',
      blockUrgencyScore: 72,
      createdAtMs: 1,
      updatedAtMs: 2,
    );
    final m = r.toMap();
    expect(m['modeRefId'], 'disciplined');
    expect(m['blockUrgencyScore'], 72);
  });

  group('ReminderConfig.copyWith — L4: nullables must be clearable', () {
    ReminderConfig seeded() => ReminderConfig(
      id: 'r1',
      taskId: 't1',
      taskTitle: 'Study',
      enabled: true,
      scheduledAtIso: '2026-03-24T10:00:00.000',
      modeRefId: 'disciplined',
      blockUrgencyScore: 72,
      lastTriggeredAtMs: 111,
      nextPromptAtIso: '2026-03-24T10:15:00.000',
      activeNotificationId: 42,
      createdAtMs: 1,
      updatedAtMs: 2,
    );

    test('an explicit null CLEARS the field instead of keeping it', () {
      final cleared = seeded().copyWith(
        scheduledAtIso: null,
        taskTitle: null,
        modeRefId: null,
        lastTriggeredAtMs: null,
        nextPromptAtIso: null,
        activeNotificationId: null,
      );

      expect(cleared.scheduledAtIso, isNull);
      expect(cleared.taskTitle, isNull);
      expect(cleared.modeRefId, isNull);
      expect(cleared.lastTriggeredAtMs, isNull);
      expect(cleared.nextPromptAtIso, isNull);
      expect(cleared.activeNotificationId, isNull);
    });

    test('an omitted field is preserved', () {
      final same = seeded().copyWith(enabled: false);

      expect(same.enabled, isFalse);
      expect(same.scheduledAtIso, '2026-03-24T10:00:00.000');
      expect(same.taskTitle, 'Study');
      expect(same.modeRefId, 'disciplined');
      expect(same.lastTriggeredAtMs, 111);
      expect(same.nextPromptAtIso, '2026-03-24T10:15:00.000');
      expect(same.activeNotificationId, 42);
    });

    test('a provided value replaces the old one', () {
      final updated = seeded().copyWith(
        nextPromptAtIso: '2026-03-24T11:00:00.000',
        lastTriggeredAtMs: 999,
      );

      expect(updated.nextPromptAtIso, '2026-03-24T11:00:00.000');
      expect(updated.lastTriggeredAtMs, 999);
    });

    test('non-nullable fields are untouched by the sentinel change', () {
      final updated = seeded().copyWith(escalationLevel: 3);

      expect(updated.escalationLevel, 3);
      expect(updated.blockUrgencyScore, 72);
      expect(updated.id, 'r1');
      expect(updated.taskId, 't1');
      expect(updated.createdAtMs, 1);
    });
  });
}
