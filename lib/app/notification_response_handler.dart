import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/providers.dart';
import '../features/focus/presentation/focus_selection_screen.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/planning/application/planned_task_providers.dart';
import 'app_navigator.dart';

const _taskPayloadPrefix = 'task:';
const _goalPayloadPrefix = 'goal:';

Future<void> _pushNamedWhenReady(
  String routeName, {
  Object? arguments,
  int maxRetries = 12,
}) async {
  for (var i = 0; i < maxRetries; i++) {
    final nav = appNavigatorKey.currentState;
    if (nav != null) {
      nav.pushNamed(routeName, arguments: arguments);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}

/// Handles taps and notification actions for local reminders (task = timeboxed; goal = daily).
Future<void> handleNotificationResponse(
  NotificationResponse response,
  ProviderContainer container,
) async {
  var raw = response.payload;
  if (raw == null || raw.isEmpty) {
    raw = await _payloadFromNotificationId(response, container);
  }
  if (raw == null || raw.isEmpty) return;

  if (raw.startsWith(_goalPayloadPrefix)) {
    final goalId = Uri.decodeComponent(raw.substring(_goalPayloadPrefix.length));
    if (goalId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _pushNamedWhenReady(
        GoalDetailScreen.routeName,
        arguments: goalId,
      );
    });
    return;
  }

  if (!raw.startsWith(_taskPayloadPrefix)) return;
  final taskId = Uri.decodeComponent(raw.substring(_taskPayloadPrefix.length));
  if (taskId.isEmpty) return;

  final sync = container.read(reminderSyncServiceProvider);

  if (response.actionId == 'snooze') {
    await sync.requestSnooze(taskId);
    return;
  }

  var label = 'Task';
  try {
    final rows = await container.read(todayAllTasksRowsProvider.future);
    for (final r in rows) {
      if (r.task.id == taskId) {
        label = r.task.title;
        break;
      }
    }
  } catch (_) {}

  container.read(activeExecutionTaskIdProvider.notifier).state = taskId;
  container.read(activeExecutionTaskLabelProvider.notifier).state = label;
  container.read(executionControllerProvider.notifier).setTask(id: taskId, label: label);

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _pushNamedWhenReady(
      FocusSelectionScreen.routeName,
      arguments: FocusLaunchArgs(
        taskId: taskId,
        taskLabel: label,
        autoOpenTimer: true,
        autoStartDelaySeconds: 10,
      ),
    );
  });
}

Future<String?> _payloadFromNotificationId(
  NotificationResponse response,
  ProviderContainer container,
) async {
  final id = response.id;
  if (id == null) return null;
  try {
    final reminders = await container.read(reminderCacheStoreProvider).load();
    final notifications = container.read(localNotificationsServiceProvider);
    for (final r in reminders) {
      for (var slot = 0; slot < 64; slot++) {
        if (notifications.idFromTaskId(r.taskId, slot: slot) == id) {
          return 'task:${Uri.encodeComponent(r.taskId)}';
        }
      }
    }
  } catch (_) {}
  return null;
}
