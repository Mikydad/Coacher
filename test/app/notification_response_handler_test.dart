import 'package:sidepal/app/app_navigator.dart';
import 'package:sidepal/app/application/main_tab_navigation.dart';
import 'package:sidepal/app/notification_response_handler.dart';
import 'package:sidepal/core/di/providers.dart';
import 'package:sidepal/core/notifications/local_notifications_service.dart';
import 'package:sidepal/core/notifications/notification_action_ids.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:sidepal/features/focus/presentation/focus_selection_screen.dart';
import 'package:sidepal/features/reminders/domain/models/notification_interaction_type.dart';
import 'package:sidepal/features/planning/domain/models/block.dart';
import 'package:sidepal/features/planning/domain/models/routine.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:sidepal/features/reminders/application/attention_orchestrator_providers.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/no_op_orchestrator_service.dart';
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

NotificationResponse _actionResponse({
  required String payload,
  required String actionId,
}) {
  return NotificationResponse(
    notificationResponseType: NotificationResponseType.selectedNotificationAction,
    payload: payload,
    actionId: actionId,
  );
}

/// Planning fake whose task carries the strict-mode contract — a
/// notification "Done" must NOT complete it.
class _StrictTaskPlanningRepository extends _FakePlanningRepository {
  _StrictTaskPlanningRepository({required super.taskId, required super.title});

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async {
    final base = await super.getTasks(routineId: routineId, blockId: blockId);
    return [
      for (final t in base)
        PlannedTask(
          id: t.id,
          routineId: t.routineId,
          blockId: t.blockId,
          title: t.title,
          durationMinutes: t.durationMinutes,
          priority: t.priority,
          orderIndex: t.orderIndex,
          reminderEnabled: t.reminderEnabled,
          reminderTimeIso: t.reminderTimeIso,
          status: t.status,
          createdAtMs: t.createdAtMs,
          updatedAtMs: t.updatedAtMs,
          planDateKey: t.planDateKey,
          strictModeRequired: true,
        ),
    ];
  }
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
        attentionOrchestratorServiceProvider.overrideWithValue(NoOpOrchestratorService()),
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
        attentionOrchestratorServiceProvider.overrideWithValue(NoOpOrchestratorService()),
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
        attentionOrchestratorServiceProvider.overrideWithValue(NoOpOrchestratorService()),
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

  testWidgets('wrong-time action records dismissed interaction, no navigation',
      (tester) async {
    debugClearPendingNotificationNavigationIntent();
    const taskId = 'task-wrong-time';
    final orchestrator = NoOpOrchestratorService();
    final container = ProviderContainer(
      overrides: [
        planningRepositoryProvider.overrideWithValue(
          _FakePlanningRepository(taskId: taskId, title: 'T'),
        ),
        reminderRepositoryProvider
            .overrideWithValue(_FakeReminderRepository(const [])),
        attentionOrchestratorServiceProvider.overrideWithValue(orchestrator),
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
      _actionResponse(
        payload: 'task:${Uri.encodeComponent(taskId)}',
        actionId: NotificationActionIds.wrongTime,
      ),
      container,
    );
    await tester.pump();

    expect(
      orchestrator.interactions,
      [(taskId, NotificationInteractionType.dismissed)],
    );
    expect(
      observer.pushed.where((r) => r.settings.name != '/'),
      isEmpty,
    );
  });

  testWidgets('open-coach action pushes the coach route', (tester) async {
    debugClearPendingNotificationNavigationIntent();
    const taskId = 'task-open-coach';
    final orchestrator = NoOpOrchestratorService();
    final container = ProviderContainer(
      overrides: [
        planningRepositoryProvider.overrideWithValue(
          _FakePlanningRepository(taskId: taskId, title: 'T'),
        ),
        reminderRepositoryProvider
            .overrideWithValue(_FakeReminderRepository(const [])),
        attentionOrchestratorServiceProvider.overrideWithValue(orchestrator),
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
          AiAssistantScreen.routeName: (_) => const SizedBox.shrink(),
        },
      ),
    );

    await handleNotificationResponse(
      _actionResponse(
        payload: 'task:${Uri.encodeComponent(taskId)}',
        actionId: NotificationActionIds.openCoach,
      ),
      container,
    );
    await tester.pump();

    expect(
      orchestrator.interactions,
      [(taskId, NotificationInteractionType.opened)],
    );
    final pushed = observer.pushed
        .where((r) => r.settings.name == AiAssistantScreen.routeName)
        .toList();
    expect(pushed, hasLength(1));
  });

  testWidgets('done action on unknown task falls back to the tap flow',
      (tester) async {
    debugClearPendingNotificationNavigationIntent();
    const taskId = 'task-unknown';
    final orchestrator = NoOpOrchestratorService();
    final container = ProviderContainer(
      overrides: [
        // NoOp planning: task not found -> completion helper declines.
        planningRepositoryProvider.overrideWithValue(NoOpPlanningRepository()),
        reminderRepositoryProvider
            .overrideWithValue(_FakeReminderRepository(const [])),
        attentionOrchestratorServiceProvider.overrideWithValue(orchestrator),
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
      _actionResponse(
        payload: 'task:${Uri.encodeComponent(taskId)}',
        actionId: NotificationActionIds.done,
      ),
      container,
    );
    await tester.pump();

    // Fallback = normal tap behavior: opened interaction + focus route.
    expect(
      orchestrator.interactions,
      [(taskId, NotificationInteractionType.opened)],
    );
    final pushed = observer.pushed
        .where((r) => r.settings.name == FocusSelectionScreen.routeName)
        .toList();
    expect(pushed, hasLength(1));
  });

  testWidgets('done action on a strict task falls back to the focus flow',
      (tester) async {
    debugClearPendingNotificationNavigationIntent();
    const taskId = 'task-strict';
    final orchestrator = NoOpOrchestratorService();
    final container = ProviderContainer(
      overrides: [
        planningRepositoryProvider.overrideWithValue(
          _StrictTaskPlanningRepository(taskId: taskId, title: 'Deep work'),
        ),
        reminderRepositoryProvider
            .overrideWithValue(_FakeReminderRepository(const [])),
        attentionOrchestratorServiceProvider.overrideWithValue(orchestrator),
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
      _actionResponse(
        payload: 'task:${Uri.encodeComponent(taskId)}',
        actionId: NotificationActionIds.done,
      ),
      container,
    );
    await tester.pump();

    // The strict-mode contract survives: no silent completion, the focus
    // (timer) flow opens instead.
    final pushed = observer.pushed
        .where((r) => r.settings.name == FocusSelectionScreen.routeName)
        .toList();
    expect(pushed, hasLength(1));
  });

  testWidgets('stake payload switches to the accountability tab',
      (tester) async {
    debugClearPendingNotificationNavigationIntent();
    final orchestrator = NoOpOrchestratorService();
    final container = ProviderContainer(
      overrides: [
        planningRepositoryProvider.overrideWithValue(NoOpPlanningRepository()),
        reminderRepositoryProvider
            .overrideWithValue(_FakeReminderRepository(const [])),
        attentionOrchestratorServiceProvider.overrideWithValue(orchestrator),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: appNavigatorKey,
        routes: {'/': (_) => const SizedBox.shrink()},
      ),
    );

    await handleNotificationResponse(
      _bodyTapResponse(payload: 'stake:challenge-1'),
      container,
    );
    await tester.pump();

    expect(container.read(mainTabIndexProvider), MainTabIndex.accountability);
    expect(
      orchestrator.interactions,
      [('challenge-1', NotificationInteractionType.opened)],
    );
  });
}
