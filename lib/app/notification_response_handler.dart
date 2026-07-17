import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/di/providers.dart';
import '../features/analytics/presentation/analytics_progress_screen.dart';
import '../features/community/presentation/circle_detail_screen.dart';
import '../features/focus/presentation/focus_selection_screen.dart';
import '../features/goals/application/goals_providers.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/planning/application/planned_task_collect.dart';
import '../features/reminders/application/attention_orchestrator_providers.dart';
import '../features/reminders/domain/models/notification_interaction_type.dart';
import 'app_navigator.dart';
import 'application/main_tab_navigation.dart';

const _taskPayloadPrefix = 'task:';
const _goalPayloadPrefix = 'goal:';
const _layer4PayloadPrefix = 'layer4:';
const _pendingNotificationIntentPrefsKey = 'pending_notification_intent_v1';

class _PendingRouteIntent {
  const _PendingRouteIntent._({
    required this.routeName,
    this.goalId,
    this.taskId,
    this.taskLabel,
    this.taskDurationMinutes,
  });

  const _PendingRouteIntent.goal(String goalId)
    : this._(routeName: GoalDetailScreen.routeName, goalId: goalId);

  const _PendingRouteIntent.progress()
    : this._(routeName: AnalyticsProgressScreen.routeName);

  const _PendingRouteIntent.focus({
    required String taskId,
    required String taskLabel,
    int? taskDurationMinutes,
  }) : this._(
         routeName: FocusSelectionScreen.routeName,
         taskId: taskId,
         taskLabel: taskLabel,
         taskDurationMinutes: taskDurationMinutes,
       );

  final String routeName;
  final String? goalId;
  final String? taskId;
  final String? taskLabel;
  final int? taskDurationMinutes;

  Object? get arguments {
    if (routeName == GoalDetailScreen.routeName) return goalId;
    if (routeName == AnalyticsProgressScreen.routeName) return null;
    if (routeName == FocusSelectionScreen.routeName) {
      final id = taskId;
      if (id == null || id.isEmpty) return null;
      return FocusLaunchArgs(
        taskId: id,
        taskLabel: taskLabel ?? 'Task',
        taskDurationMinutes: taskDurationMinutes,
        autoOpenTimer: true,
        autoStartDelaySeconds: 10,
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'routeName': routeName,
    if (goalId != null) 'goalId': goalId,
    if (taskId != null) 'taskId': taskId,
    if (taskLabel != null) 'taskLabel': taskLabel,
    if (taskDurationMinutes != null) 'taskDurationMinutes': taskDurationMinutes,
  };

  static _PendingRouteIntent? fromJson(Map<String, dynamic> map) {
    final routeName = map['routeName'];
    if (routeName is! String || routeName.isEmpty) return null;
    if (routeName == GoalDetailScreen.routeName) {
      final goalId = map['goalId'];
      if (goalId is String && goalId.isNotEmpty) {
        return _PendingRouteIntent.goal(goalId);
      }
      return null;
    }
    if (routeName == AnalyticsProgressScreen.routeName) {
      return const _PendingRouteIntent.progress();
    }
    if (routeName == FocusSelectionScreen.routeName) {
      final taskId = map['taskId'];
      if (taskId is! String || taskId.isEmpty) return null;
      final taskLabel = map['taskLabel'];
      final taskDurationMinutes = (map['taskDurationMinutes'] as num?)?.toInt();
      return _PendingRouteIntent.focus(
        taskId: taskId,
        taskLabel: taskLabel is String && taskLabel.isNotEmpty
            ? taskLabel
            : 'Task',
        taskDurationMinutes: taskDurationMinutes,
      );
    }
    return null;
  }
}

_PendingRouteIntent? _pendingRouteIntent;

bool _pushNowIfReady(
  String routeName, {
  Object? arguments,
  ProviderContainer? container,
}) {
  final nav = appNavigatorKey.currentState;
  if (nav == null) {
    debugPrint('[NotifTap] navigator not ready for route=$routeName');
    return false;
  }

  debugPrint(
    '[NotifTap] pushing route=$routeName argsType=${arguments.runtimeType}',
  );
  nav.pushNamed(routeName, arguments: arguments);
  return true;
}

Future<void> _persistPendingIntent(_PendingRouteIntent? pending) async {
  final prefs = await SharedPreferences.getInstance();
  if (pending == null) {
    await prefs.remove(_pendingNotificationIntentPrefsKey);
    return;
  }
  await prefs.setString(
    _pendingNotificationIntentPrefsKey,
    jsonEncode(pending.toJson()),
  );
}

Future<_PendingRouteIntent?> _loadPendingIntentFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_pendingNotificationIntentPrefsKey);
  if (raw == null || raw.isEmpty) return null;
  try {
    final parsed = jsonDecode(raw);
    if (parsed is! Map<String, dynamic>) return null;
    return _PendingRouteIntent.fromJson(parsed);
  } catch (_) {
    return null;
  }
}

void _queuePendingIntent(_PendingRouteIntent pending) {
  debugPrint('[NotifTap] queue pending intent route=${pending.routeName}');
  _pendingRouteIntent = pending;
  unawaited(_persistPendingIntent(pending));
}

/// Pushes any pending notification route once the global navigator is available.
void flushPendingNotificationNavigationIntent() {
  unawaited(_flushPendingNotificationNavigationIntent());
}

Future<void> _flushPendingNotificationNavigationIntent() async {
  _pendingRouteIntent ??= await _loadPendingIntentFromPrefs();
  final pending = _pendingRouteIntent;
  if (pending == null) {
    debugPrint('[NotifTap] flush: no pending intent');
    return;
  }
  debugPrint('[NotifTap] flush: trying pending route=${pending.routeName}');
  final args = pending.arguments;
  if (_pushNowIfReady(
    pending.routeName,
    arguments: args,
    container: appRootProviderContainer,
  )) {
    debugPrint('[NotifTap] flush: pending intent consumed');
    _pendingRouteIntent = null;
    await _persistPendingIntent(null);
  } else {
    debugPrint('[NotifTap] flush: navigator still unavailable');
  }
}

@visibleForTesting
void debugClearPendingNotificationNavigationIntent() {
  _pendingRouteIntent = null;
  unawaited(_persistPendingIntent(null));
}

/// Handles taps and notification actions for local reminders (task = timeboxed; goal = daily).
Future<void> handleNotificationResponse(
  NotificationResponse response,
  ProviderContainer container,
) async {
  debugPrint(
    '[NotifTap] received response '
    'type=${response.notificationResponseType.name} '
    'id=${response.id} actionId=${response.actionId} payload=${response.payload}',
  );
  var raw = response.payload;
  if (raw == null || raw.isEmpty) {
    debugPrint('[NotifTap] payload empty, trying notification-id fallback');
    raw = await _payloadFromNotificationId(response, container);
  }
  if (raw == null || raw.isEmpty) {
    debugPrint('[NotifTap] unresolved payload -> abort navigation');
    return;
  }
  debugPrint('[NotifTap] resolved payload=$raw');

  if (raw.startsWith(_goalPayloadPrefix)) {
    final goalId = Uri.decodeComponent(
      raw.substring(_goalPayloadPrefix.length),
    );
    if (goalId.isEmpty) {
      debugPrint('[NotifTap] goal payload empty id -> abort');
      return;
    }
    debugPrint('[NotifTap] goal tap goalId=$goalId');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_pushNowIfReady(GoalDetailScreen.routeName, arguments: goalId)) {
        _queuePendingIntent(_PendingRouteIntent.goal(goalId));
      }
    });
    return;
  }

  if (raw.startsWith(_layer4PayloadPrefix)) {
    await _handleLayer4InsightTap(raw, container);
    return;
  }

  // Circle deep link — appended in Phase 4 (do not modify cases above).
  if (raw.startsWith('circle:')) {
    final circleId = raw.substring('circle:'.length);
    if (circleId.isNotEmpty) {
      debugPrint('[NotifTap] circle tap circleId=$circleId');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pushNowIfReady(CircleDetailScreen.routeName, arguments: circleId);
      });
    }
    return;
  }

  if (!raw.startsWith(_taskPayloadPrefix)) {
    debugPrint('[NotifTap] payload not task/goal/layer4/circle -> ignore');
    return;
  }
  final taskId = Uri.decodeComponent(raw.substring(_taskPayloadPrefix.length));
  if (taskId.isEmpty) {
    debugPrint('[NotifTap] task payload empty id -> abort');
    return;
  }
  debugPrint('[NotifTap] task tap taskId=$taskId');

  final sync = container.read(reminderSyncServiceProvider);
  final orchestrator = container.read(attentionOrchestratorServiceProvider);

  if (response.actionId == 'snooze') {
    debugPrint('[NotifTap] snooze action for task=$taskId');
    // Record snooze interaction (logs analytics + detects repeated snooze pattern).
    unawaited(
      orchestrator.onInteractionReceived(
        taskId,
        NotificationInteractionType.snoozed,
      ),
    );
    await sync.requestSnooze(taskId);
    return;
  }

  // Tap = opened interaction.
  unawaited(
    orchestrator.onInteractionReceived(
      taskId,
      NotificationInteractionType.opened,
    ),
  );

  var label = 'Task';
  int? durationMinutes;
  try {
    final rows = await collectTodayPlannedRows(
      container.read(planningRepositoryProvider),
    );
    for (final r in rows) {
      if (r.task.id == taskId) {
        label = r.task.title;
        durationMinutes = r.task.durationMinutes;
        break;
      }
    }
  } catch (e) {
    debugPrint('notification_response_handler: swallowed error: $e');
  }
  debugPrint('[NotifTap] resolved task label="$label" for taskId=$taskId');

  container.read(activeExecutionTaskIdProvider.notifier).state = taskId;
  container.read(activeExecutionTaskLabelProvider.notifier).state = label;
  container
      .read(executionControllerProvider.notifier)
      .setTask(id: taskId, label: label, durationMinutes: durationMinutes);
  debugPrint('[NotifTap] execution state primed for taskId=$taskId');

  final launch = FocusLaunchArgs(
    taskId: taskId,
    taskLabel: label,
    taskDurationMinutes: durationMinutes,
    autoOpenTimer: true,
    autoStartDelaySeconds: 10,
  );
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!_pushNowIfReady(FocusSelectionScreen.routeName, arguments: launch)) {
      _queuePendingIntent(
        _PendingRouteIntent.focus(
          taskId: taskId,
          taskLabel: label,
          taskDurationMinutes: durationMinutes,
        ),
      );
    } else {
      debugPrint(
        '[NotifTap] focus route pushed immediately for taskId=$taskId',
      );
    }
  });
}

/// Coaching insight notifications use payload `layer4:` + [GeneratedInsight.insightId].
Future<void> _handleLayer4InsightTap(
  String raw,
  ProviderContainer container,
) async {
  final insightId = raw.substring(_layer4PayloadPrefix.length);
  debugPrint('[NotifTap] layer4 insightId=$insightId');
  final parts = insightId.split('::');
  if (parts.length >= 2 && parts[0] == 'entity') {
    final entityId = parts[1].trim();
    if (entityId.isNotEmpty) {
      try {
        final goal = await container
            .read(goalsRepositoryProvider)
            .getGoal(entityId);
        if (goal != null) {
          debugPrint('[NotifTap] layer4 -> goal detail goalId=$entityId');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_pushNowIfReady(
              GoalDetailScreen.routeName,
              arguments: entityId,
            )) {
              _queuePendingIntent(_PendingRouteIntent.goal(entityId));
            }
          });
          return;
        }
      } catch (e) {
        debugPrint('[NotifTap] layer4 goal lookup failed: $e');
      }
    }
  }
  debugPrint('[NotifTap] layer4 -> Progress (coaching)');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_pushNowIfReady(
      AnalyticsProgressScreen.routeName,
      container: container,
    )) {
      _queuePendingIntent(const _PendingRouteIntent.progress());
    }
  });
}

Future<String?> _payloadFromNotificationId(
  NotificationResponse response,
  ProviderContainer container,
) async {
  final id = response.id;
  if (id == null) return null;
  try {
    final notifications = container.read(localNotificationsServiceProvider);
    final indexedTaskId = await notifications.taskIdForNotificationId(id);
    if (indexedTaskId != null && indexedTaskId.isNotEmpty) {
      debugPrint(
        '[NotifTap] id-map hit notificationId=$id -> taskId=$indexedTaskId',
      );
      return 'task:${Uri.encodeComponent(indexedTaskId)}';
    }
    debugPrint(
      '[NotifTap] id-map miss notificationId=$id, trying reminder scan',
    );
    final reminders = await container
        .read(reminderRepositoryProvider)
        .listAllReminders();
    // After Phase C each entity has at most 1 active OS notification (slot 0).
    for (final r in reminders) {
      if (notifications.idFromTaskId(r.taskId, slot: 0) == id) {
        debugPrint(
          '[NotifTap] reminder-scan hit notificationId=$id -> taskId=${r.taskId}',
        );
        return 'task:${Uri.encodeComponent(r.taskId)}';
      }
    }
    debugPrint('Notification fallback: no reminder matched notificationId=$id');
  } catch (e) {
    debugPrint('Notification fallback failed for notificationId=$id error=$e');
  }
  return null;
}
