import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService instance = LocalNotificationsService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _appLaunchNotificationHandled = false;

  Future<void> initialize({
    void Function(NotificationResponse response)? onDidReceiveNotificationResponse,
  }) async {
    tz_data.initializeTimeZones();
    const initializationSettings = InitializationSettings(
      iOS: DarwinInitializationSettings(),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  /// Cold start: the plugin does not always deliver [onDidReceiveNotificationResponse] for
  /// the notification that launched the app. Drain once after [MaterialApp] has a navigator.
  Future<void> drainLaunchNotificationResponse(
    Future<void> Function(NotificationResponse response) onResponse,
  ) async {
    if (_appLaunchNotificationHandled) return;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return;
    final response = details!.notificationResponse;
    if (response == null) return;
    _appLaunchNotificationHandled = true;
    await onResponse(response);
  }

  Future<bool> requestPermissionsIfNeeded() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosOk =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    final androidOk = await android?.requestNotificationsPermission() ?? true;
    return iosOk && androidOk;
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    final scheduled = _normalizeScheduleTime(when);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduled, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'coach4life_reminders',
          'Coach4Life Reminders',
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'snooze',
              'Snooze',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  int idFromTaskId(String taskId, {int slot = 0}) =>
      ('task:$taskId:$slot').hashCode.abs() % 2147483647;

  /// Distinct from [idFromTaskId] to reduce id collisions between modules.
  int idFromGoalId(String goalId) => (goalId.hashCode ^ 0x474f414c).abs() % 2147483647;

  /// Repeats every day at the same local hour/minute (see [matchDateTimeComponents]).
  Future<void> scheduleDailyAtLocalTime({
    required int id,
    required String title,
    required String body,
    required DateTime firstFireLocal,
    String? payload,
  }) async {
    final scheduled = _normalizeDailyFirstFire(firstFireLocal);
    final when = tz.TZDateTime.from(scheduled, tz.local);
    debugPrint('Scheduling daily goal reminder: id=$id atLocal=$scheduled tz=$when');
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'coach4life_goal_reminders',
          'Goal reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  DateTime _normalizeScheduleTime(DateTime when) {
    // Ensure we always schedule in the future, even for stale cached dates.
    var normalized = when;
    final now = DateTime.now();
    while (!normalized.isAfter(now)) {
      normalized = normalized.add(const Duration(days: 1));
    }
    return normalized;
  }

  DateTime _normalizeDailyFirstFire(DateTime when) {
    final now = DateTime.now();
    if (when.isAfter(now)) return when;
    return when.add(const Duration(days: 1));
  }
}
