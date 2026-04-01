import 'package:coach_for_life/core/di/providers.dart';
import 'package:coach_for_life/features/execution/data/execution_repository.dart';
import 'package:coach_for_life/features/execution/data/timer_runtime_cache.dart';
import 'package:coach_for_life/features/execution/domain/models/timer_session.dart';
import 'package:coach_for_life/features/execution/domain/task_timer_engine.dart';
import 'package:coach_for_life/features/reminders/application/reminder_sync_service.dart';
import 'package:coach_for_life/features/reminders/data/reminder_cache_store.dart';
import 'package:coach_for_life/features/reminders/data/reminder_repository.dart';
import 'package:coach_for_life/features/reminders/domain/models/reminder_config.dart';
import 'package:coach_for_life/features/timer/presentation/timer_session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeExecutionRepository implements ExecutionRepository {
  @override
  Future<List<TimerSession>> getSessionsForBlock(String blockId) async => const [];

  @override
  Future<List<TimerSession>> getSessionsForTask(String taskId) async => const [];

  @override
  Future<void> upsertSession(TimerSession session) async {}
}

class _FakeTimerRuntimeCache extends TimerRuntimeCache {
  Map<String, dynamic>? data;

  @override
  Future<Map<String, dynamic>?> load() async => data;

  @override
  Future<void> save({
    required TimerSessionTargetType targetType,
    required String taskId,
    required String blockId,
    required String label,
    required ExecutionPhase phase,
    required Duration elapsed,
    DateTime? runningSince,
  }) async {
    data = <String, dynamic>{
      'targetType': targetType.storageValue,
      'taskId': taskId,
      'blockId': blockId,
      'label': label,
      'phase': phase.name,
      'elapsedMs': elapsed.inMilliseconds,
      'runningSinceMs': runningSince?.millisecondsSinceEpoch,
    };
  }
}

class _FakeReminderRepository implements ReminderRepository {
  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> taskIds) async => const [];

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {}
}

class _FakeReminderNotifications implements ReminderNotificationsPort {
  @override
  Future<void> cancel(int id) async {}

  @override
  int idFromTaskId(String taskId, {int slot = 0}) => 0;

  @override
  Future<bool> requestPermissionsIfNeeded() async => true;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {}
}

void main() {
  testWidgets('shows and cancels auto-start countdown', (tester) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final reminderSync = ReminderSyncService(
      repository: _FakeReminderRepository(),
      cacheStore: const ReminderCacheStore(),
      notifications: _FakeReminderNotifications(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          executionRepositoryProvider.overrideWithValue(_FakeExecutionRepository()),
          timerRuntimeCacheProvider.overrideWithValue(_FakeTimerRuntimeCache()),
          reminderSyncServiceProvider.overrideWithValue(reminderSync),
        ],
        child: const MaterialApp(
          home: TimerSessionScreen(
            launchArgs: TimerLaunchArgs(autoStartDelaySeconds: 10),
          ),
        ),
      ),
    );

    expect(find.textContaining('Auto-starting in 10s'), findsOneWidget);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.textContaining('Auto-starting in'), findsNothing);
  });
}
