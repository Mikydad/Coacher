import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_reminder.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_reminder_occurrence.dart';
import 'package:sidepal/core/notifications/notification_presentation.dart';
import 'package:sidepal/features/reminders/application/reminder_copy_bank.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_alert_mode.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';

/// feat/alarm-mode: the synced fields degrade safely and the OS presentation
/// is genuinely an alarm's, not a louder reminder's.
void main() {
  group('ReminderAlertMode', () {
    test('unknown or missing storage reads as notification', () {
      expect(ReminderAlertMode.fromStorage(null), ReminderAlertMode.notification);
      expect(
        ReminderAlertMode.fromStorage('siren'),
        ReminderAlertMode.notification,
      );
      expect(ReminderAlertMode.fromStorage(' ALARM '), ReminderAlertMode.alarm);
    });
  });

  group('ReminderConfig', () {
    const base = ReminderConfig(
      id: 'r1',
      taskId: 't1',
      enabled: true,
      scheduledAtIso: '2026-09-13T22:00:00.000',
      alertMode: ReminderAlertMode.alarm,
      alarmOffsetMinutes: 480,
      createdAtMs: 1,
      updatedAtMs: 2,
    );

    test('alarm fields survive toMap / fromMap', () {
      final back = ReminderConfig.fromMap(base.toMap());
      expect(back.alertMode, ReminderAlertMode.alarm);
      expect(back.alarmOffsetMinutes, 480);
      expect(back.isAlarm, isTrue);
      expect(back.alarmAt, DateTime(2026, 9, 14, 6, 0));
    });

    test('a pre-alarm document (no fields) is a plain reminder', () {
      final map = base.toMap()
        ..remove('alertMode')
        ..remove('alarmOffsetMinutes');
      final back = ReminderConfig.fromMap(map);
      expect(back.isAlarm, isFalse);
      expect(back.alarmOffsetMinutes, 0);
    });

    test('an absurd offset is clamped rather than trusted', () {
      final map = base.toMap()..['alarmOffsetMinutes'] = 99999;
      expect(ReminderConfig.fromMap(map).alarmOffsetMinutes, 24 * 60);
    });

    test('Isar round-trip keeps both fields', () {
      final back = IsarReminder.fromDomain(base).toDomain();
      expect(back.alertMode, ReminderAlertMode.alarm);
      expect(back.alarmOffsetMinutes, 480);
    });

    test('copyWith can switch the mode off', () {
      final off = base.copyWith(
        alertMode: ReminderAlertMode.notification,
        alarmOffsetMinutes: 0,
      );
      expect(off.isAlarm, isFalse);
      expect(off.alarmAt, DateTime(2026, 9, 13, 22, 0));
    });
  });

  group('ReminderOccurrence.alarmStoppedAtMs', () {
    const row = ReminderOccurrence(
      id: 'o1',
      entityId: 't1',
      entityKind: 'task',
      dateKey: '2026-09-13',
      scheduledAtMs: 1,
      windowMinutes: 30,
      alarmStoppedAtMs: 42,
      createdAtMs: 0,
      updatedAtMs: 0,
    );

    test('survives toMap / fromMap and Isar', () {
      expect(ReminderOccurrence.fromMap(row.toMap()).alarmStoppedAtMs, 42);
      expect(
        IsarReminderOccurrence.fromDomain(row).toDomain().alarmStoppedAtMs,
        42,
      );
      expect(row.isAlarmStopped, isTrue);
    });

    test('copyWith(null) clears it — a snooze after a stop', () {
      final cleared = row.copyWith(alarmStoppedAtMs: null);
      expect(cleared.isAlarmStopped, isFalse);
      // And the sentinel default keeps it.
      expect(row.copyWith(updatedAtMs: 9).alarmStoppedAtMs, 42);
    });
  });

  group('NotificationPresentation alarm', () {
    test('Android: its own channel, alarm audio usage, bundled sound', () {
      final details = NotificationPresentation.androidAlarm();
      expect(details.channelId, NotificationPresentation.channelAlarm);
      expect(details.importance, fln.Importance.max);
      expect(details.audioAttributesUsage, fln.AudioAttributesUsage.alarm);
      expect(details.category, fln.AndroidNotificationCategory.alarm);
      expect(
        details.sound,
        isA<fln.RawResourceAndroidNotificationSound>().having(
          (s) => s.sound,
          'sound',
          NotificationPresentation.alarmSoundAndroidRaw,
        ),
      );
      // Not one of the reminder channels: the user can tune alarms apart.
      expect(details.channelId, isNot(NotificationPresentation.channelUrgent));
    });

    test('iOS: Time Sensitive with the bundled sound', () {
      final details = NotificationPresentation.darwinAlarm(
        categoryIdentifier: 'cat',
      );
      expect(details.interruptionLevel, fln.InterruptionLevel.timeSensitive);
      expect(details.sound, NotificationPresentation.alarmSoundDarwin);
      expect(details.presentSound, isTrue);
      expect(details.categoryIdentifier, 'cat');
    });
  });

  group('ReminderCopyBank.alarm', () {
    test('a task alarm names the task; later rings say they are repeats', () {
      final first = ReminderCopyBank.alarm(entityTitle: 'Take meds');
      final third = ReminderCopyBank.alarm(entityTitle: 'Take meds', ring: 2);
      expect(first.title, 'Take meds');
      expect(first.body, 'Alarm: time for Take meds.');
      expect(third.body, contains('still ringing'));
    });

    test('a wake-up speaks about getting up, not about "Sleep"', () {
      final copy = ReminderCopyBank.alarm(entityTitle: 'Sleep', isWakeUp: true);
      expect(copy.title, 'Wake up');
      expect(copy.body, isNot(contains('Sleep')));
    });

    test('a blank title still says something sayable', () {
      expect(ReminderCopyBank.alarm(entityTitle: '  ').body, contains('your task'));
    });
  });
}
