import 'package:coach_for_life/features/reminders/application/reminder_sync_service.dart';
import 'package:coach_for_life/features/reminders/data/reminder_cache_store.dart';
import 'package:coach_for_life/features/reminders/data/reminder_repository.dart';
import 'package:coach_for_life/features/reminders/domain/models/reminder_config.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReminderRepository implements ReminderRepository {
  final Map<String, ReminderConfig> _byTask = {};

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> taskIds) async {
    return taskIds.map((id) => _byTask[id]).whereType<ReminderConfig>().toList();
  }

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {
    _byTask[reminder.taskId] = reminder;
  }
}

class _FakeReminderCacheStore extends ReminderCacheStore {
  List<ReminderConfig> data = const [];

  @override
  Future<List<ReminderConfig>> load() async => data;

  @override
  Future<void> save(List<ReminderConfig> reminders) async {
    data = List<ReminderConfig>.from(reminders);
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
  int idFromTaskId(String taskId) => taskId.hashCode.abs() % 2147483647;

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
    final repo = _FakeReminderRepository();
    final cache = _FakeReminderCacheStore()..data = [_reminder(now: now)];
    final notifications = _FakeNotifications();
    final service = ReminderSyncService(
      repository: repo,
      cacheStore: cache,
      notifications: notifications,
      now: () => now,
    );

    await service.scheduleFromCache();
    expect(notifications.scheduled, isNotEmpty);
    expect(notifications.scheduled.first.when.isAfter(now), isTrue);
  });

  test('reminders stop only when task started or logical reason provided', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository();
    final cache = _FakeReminderCacheStore()..data = [_reminder(now: now)];
    final notifications = _FakeNotifications();
    final service = ReminderSyncService(
      repository: repo,
      cacheStore: cache,
      notifications: notifications,
      now: () => now,
    );

    await service.requestSnooze('t1');
    expect(cache.data.first.pendingAction, isTrue);

    await service.markLogicalReasonProvided('t1');
    expect(cache.data.first.pendingAction, isFalse);
    expect(cache.data.first.enabled, isFalse);
  });
}
