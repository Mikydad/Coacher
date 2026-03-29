import 'package:coach_for_life/features/reminders/domain/models/reminder_config.dart';
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
}
