import 'package:coach_for_life/app/app_navigator.dart';
import 'package:coach_for_life/app/notification_response_handler.dart';
import 'package:coach_for_life/core/di/providers.dart';
import 'package:coach_for_life/core/notifications/local_notifications_service.dart';
import 'package:coach_for_life/core/utils/date_keys.dart';
import 'package:coach_for_life/features/focus/presentation/focus_selection_screen.dart';
import 'package:coach_for_life/features/planning/domain/models/block.dart';
import 'package:coach_for_life/features/planning/domain/models/routine.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:coach_for_life/features/reminders/data/reminder_repository.dart';
import 'package:coach_for_life/features/reminders/domain/models/reminder_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/no_op_planning_repository.dart';

class _FakeReminderRepository implements ReminderRepository {
  _FakeReminderRepository(this._all);

  final List<ReminderConfig> _all;

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}

  @override
  Future<List<ReminderConfig>> listAllReminders() async => _all;

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> taskIds) async {
    final set = taskIds.toSet();
    return _all.where((r) => set.contains(r.taskId)).toList();
  }

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {}
}

class _FakePlanningRepository extends NoOpPlanningRepository {
  _FakePlanningRepository({required this.taskId, required this.title});

  final String taskId;
  final String title;

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async {
    return [
      Routine(
        id: 'r1',
        title: 'Daily plan',
        dateKey: dateKey,
        orderIndex: 0,
        createdAtMs: 1,
        updatedAtMs: 1,
      ),
    ];
  }

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async {
    return [
      TaskBlock(
        id: 'b1',
        routineId: routineId,
        title: 'Main',
        orderIndex: 0,
        createdAtMs: 1,
        updatedAtMs: 1,
      ),
    ];
  }

  @override
  Future<List<PlannedTask>> getTasks({required String routineId, required String blockId}) async {
    return [
      PlannedTask(
        id: taskId,
        routineId: routineId,
        blockId: blockId,
        title: title,
        durationMinutes: 25,
        priority: 2,
        orderIndex: 0,
        reminderEnabled: true,
        reminderTimeIso: null,
        status: TaskStatus.notStarted,
        createdAtMs: 1,
        updatedAtMs: 1,
        planDateKey: DateKeys.todayKey(),
      ),
    ];
  }
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
    super.didPush(route, previousRoute);
  }
}

NotificationResponse _bodyTapResponse({required String? payload, int? id}) {
  return NotificationResponse(
    notificationResponseType: NotificationResponseType.selectedNotification,
    payload: payload,
    id: id,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await LocalNotificationsService.instance.debugSetTaskIdIndexForTests(const {});
  });

  testWidgets('body tap with payload opens focus with task and timer args', (tester) async {
    debugClearPendingNotificationNavigationIntent();
    const taskId = 'task-reading';
    const title = 'Start reading book';
    final container = ProviderContainer(
      overrides: [
        planningRepositoryProvider.overrideWithValue(
          _FakePlanningRepository(taskId: taskId, title: title),
        ),
        reminderRepositoryProvider.overrideWithValue(_FakeReminderRepository(const [])),
      ],
    );
    addTearDown(container.dispose);

    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: appNavigatorKey,
        navigatorObservers: [observer],
        routes: {
          '/': (_) => const SizedBox.shrink(),
          FocusSelectionScreen.routeName: (_) => const SizedBox.shrink(),
        },
      ),
    );

    await handleNotificationResponse(
      _bodyTapResponse(payload: 'task:${Uri.encodeComponent(taskId)}'),
      container,
    );
    await tester.pump();

    final pushed = observer.pushed.where((r) => r.settings.name == FocusSelectionScreen.routeName).toList();
    expect(pushed, hasLength(1));
    final args = pushed.first.settings.arguments;
    expect(args, isA<FocusLaunchArgs>());
    final launch = args as FocusLaunchArgs;
    expect(launch.taskId, taskId);
    expect(launch.taskLabel, title);
    expect(launch.autoOpenTimer, isTrue);
    expect(launch.autoStartDelaySeconds, 10);
  });

  testWidgets('payload fallback from persisted notification id index navigates', (tester) async {
    debugClearPendingNotificationNavigationIntent();
    const taskId = 'task-reading-fallback';
    const title = 'Start reading book';
    final container = ProviderContainer(
      overrides: [
        planningRepositoryProvider.overrideWithValue(
          _FakePlanningRepository(taskId: taskId, title: title),
        ),
        reminderRepositoryProvider.overrideWithValue(_FakeReminderRepository(const [])),
      ],
    );
    addTearDown(container.dispose);

    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: appNavigatorKey,
        navigatorObservers: [observer],
        routes: {
          '/': (_) => const SizedBox.shrink(),
          FocusSelectionScreen.routeName: (_) => const SizedBox.shrink(),
        },
      ),
    );

    final notifId = LocalNotificationsService.instance.idFromTaskId(taskId, slot: 0);
    await LocalNotificationsService.instance.debugSetTaskIdIndexForTests({notifId: taskId});
    await handleNotificationResponse(_bodyTapResponse(payload: null, id: notifId), container);
    await tester.pump();

    final pushed = observer.pushed.where((r) => r.settings.name == FocusSelectionScreen.routeName).toList();
    expect(pushed, hasLength(1));
  });

  testWidgets('queues when navigator unavailable then flushes exactly once', (tester) async {
    debugClearPendingNotificationNavigationIntent();
    const taskId = 'task-queued';
    const title = 'Start reading book';
    final container = ProviderContainer(
      overrides: [
        planningRepositoryProvider.overrideWithValue(
          _FakePlanningRepository(taskId: taskId, title: title),
        ),
        reminderRepositoryProvider.overrideWithValue(_FakeReminderRepository(const [])),
      ],
    );
    addTearDown(container.dispose);

    await handleNotificationResponse(
      _bodyTapResponse(payload: 'task:${Uri.encodeComponent(taskId)}'),
      container,
    );

    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: appNavigatorKey,
        navigatorObservers: [observer],
        routes: {
          '/': (_) => const SizedBox.shrink(),
          FocusSelectionScreen.routeName: (_) => const SizedBox.shrink(),
        },
      ),
    );

    flushPendingNotificationNavigationIntent();
    await tester.pump();
    flushPendingNotificationNavigationIntent();
    await tester.pump();

    final pushed = observer.pushed.where((r) => r.settings.name == FocusSelectionScreen.routeName).toList();
    expect(pushed, hasLength(1));
  });
}
