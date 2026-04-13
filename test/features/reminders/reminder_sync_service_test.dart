import 'package:coach_for_life/features/reminders/application/reminder_sync_service.dart';
import 'package:coach_for_life/features/reminders/data/reminder_repository.dart';
import 'package:coach_for_life/features/reminders/domain/models/reminder_config.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReminderRepository implements ReminderRepository {
  final List<ReminderConfig> _all = [];

  void seed(Iterable<ReminderConfig> items) {
    _all
      ..clear()
      ..addAll(items);
  }

  @override
  Future<List<ReminderConfig>> listAllReminders() async => List<ReminderConfig>.from(_all);

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> taskIds) async {
    final idSet = taskIds.toSet();
    return _all.where((r) => idSet.contains(r.taskId)).toList();
  }

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {
    final i = _all.indexWhere((r) => r.id == reminder.id);
    if (i >= 0) {
      _all[i] = reminder;
    } else {
      _all.add(reminder);
    }
  }
}

class _FakeNotifications implements ReminderNotificationsPort {
  final scheduled = <({int id, DateTime when, String body})>[];
  final cancelled = <int>[];

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  int idFromTaskId(String taskId, {int slot = 0}) =>
      ('task:$taskId:$slot').hashCode.abs() % 2147483647;

  @override
  Future<bool> requestPermissionsIfNeeded() async => true;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    scheduled.add((id: id, when: when, body: body));
  }
}

ReminderConfig _reminder({
  required DateTime now,
  bool pendingAction = true,
  String modeRefId = 'disciplined',
  int escalationLevel = 1,
}) {
  return ReminderConfig(
    id: 'r1',
    taskId: 't1',
    enabled: true,
    scheduledAtIso: now.subtract(const Duration(minutes: 30)).toIso8601String(),
    modeRefId: modeRefId,
    blockUrgencyScore: 90,
    pendingAction: pendingAction,
    escalationLevel: escalationLevel,
    emergencyBypass: false,
    lastTriggeredAtMs: null,
    nextPromptAtIso: now.subtract(const Duration(minutes: 10)).toIso8601String(),
    createdAtMs: now.millisecondsSinceEpoch,
    updatedAtMs: now.millisecondsSinceEpoch,
  );
}

void main() {
  test('stale pending schedule recovers to future adaptive time', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
    final notifications = _FakeNotifications();
    final service = ReminderSyncService(
      repository: repo,
      notifications: notifications,
      now: () => now,
    );

    await service.scheduleFromCache();
    expect(notifications.scheduled, isNotEmpty);
    expect(notifications.scheduled.length, 1);
    expect(notifications.scheduled.first.when.isAfter(now), isTrue);
  });

  test('reminders stop only when task started or logical reason provided', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
    final notifications = _FakeNotifications();
    final service = ReminderSyncService(
      repository: repo,
      notifications: notifications,
      now: () => now,
    );

    await service.requestSnooze('t1');
    expect((await repo.listAllReminders()).first.pendingAction, isTrue);

    await service.markLogicalReasonProvided('t1');
    expect((await repo.listAllReminders()).first.pendingAction, isFalse);
    expect((await repo.listAllReminders()).first.enabled, isFalse);
  });

  test('disciplined auto-repeat schedules multiple future nudges', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()
      ..seed([
        _reminder(
          now: now,
          pendingAction: false,
          modeRefId: 'disciplined',
          escalationLevel: 0,
        ),
      ]);
    final notifications = _FakeNotifications();
    final service = ReminderSyncService(
      repository: repo,
      notifications: notifications,
      now: () => now,
    );

    await service.scheduleFromCache();
    expect(notifications.scheduled.length, greaterThanOrEqualTo(6));
  });

  test('flexible remains one-shot when unresolved', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()
      ..seed([
        _reminder(
          now: now,
          pendingAction: false,
          modeRefId: 'flexible',
          escalationLevel: 0,
        ).copyWith(
          scheduledAtIso: now.add(const Duration(minutes: 5)).toIso8601String(),
        ),
      ]);
    final notifications = _FakeNotifications();
    final service = ReminderSyncService(
      repository: repo,
      notifications: notifications,
      now: () => now,
    );

    await service.scheduleFromCache();
    expect(notifications.scheduled.length, 1);
  });
}
