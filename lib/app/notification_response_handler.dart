import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/providers.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/planning/application/planned_task_providers.dart';
import '../features/timer/presentation/timer_session_screen.dart';
import 'app_navigator.dart';

const _taskPayloadPrefix = 'task:';
const _goalPayloadPrefix = 'goal:';

/// Handles taps and notification actions for local reminders (task = timeboxed; goal = daily).
Future<void> handleNotificationResponse(
  NotificationResponse response,
  ProviderContainer container,
) async {
  final raw = response.payload;
  if (raw == null || raw.isEmpty) return;

  if (raw.startsWith(_goalPayloadPrefix)) {
    final goalId = Uri.decodeComponent(raw.substring(_goalPayloadPrefix.length));
    if (goalId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appNavigatorKey.currentState?.pushNamed(
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

  await sync.markTaskStarted(taskId);

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

  WidgetsBinding.instance.addPostFrameCallback((_) {
    appNavigatorKey.currentState?.pushNamed(TimerSessionScreen.routeName);
  });
}
