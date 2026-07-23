import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_action_ids.dart';
import 'notification_budget.dart';
import 'notification_reconciliation_service.dart';

/// Narrow OS-notification surface needed by goal reminders (test seam).
abstract interface class GoalNotificationsPort {
  int idFromGoalId(String goalId);
  int idFromGoalIdWeekday(String goalId, int weekday);
  int idFromGoalIdMonthDay(String goalId, int dayOfMonth);
  Future<void> cancel(int id);
}

class LocalNotificationsService
    implements
        ActiveNotificationsSource,
        PendingNotificationsSource,
        GoalNotificationsPort {
  LocalNotificationsService._();

  static final LocalNotificationsService instance =
      LocalNotificationsService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  String? _lastDrainedResponseSignature;
  Map<int, String>? _taskIdByNotificationIdCache;
  static const _taskIdByNotificationIdPrefsKey =
      'notification_task_id_index_v1';

  Future<void> initialize({
    void Function(NotificationResponse response)?
    onDidReceiveNotificationResponse,
  }) async {
    tz_data.initializeTimeZones();
    // Without this, `tz.local` stays UTC and every `zonedSchedule` below fires at
    // the wrong absolute time (off by the device's UTC offset) — the root cause
    // of reminders silently not appearing. Point `tz.local` at the device zone.
    await _configureLocalTimeZone();
    // Every action opens the app (`foreground`), mirroring the Android
    // snooze action's `showsUserInterface: true` — so all responses arrive
    // in the normal foreground handler and no background isolate (which has
    // no Isar/Riverpod) is needed.
    final initializationSettings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        notificationCategories: [
          DarwinNotificationCategory(
            NotificationCategoryIds.taskReminder,
            actions: [
              DarwinNotificationAction.plain(
                NotificationActionIds.done,
                'Done',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                NotificationActionIds.later,
                'Later',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                NotificationActionIds.wrongTime,
                'Wrong time',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                NotificationActionIds.openCoach,
                'Open Coach',
                options: {DarwinNotificationActionOption.foreground},
              ),
            ],
          ),
          DarwinNotificationCategory(
            NotificationCategoryIds.intentionNudge,
            actions: [
              DarwinNotificationAction.plain(
                NotificationActionIds.done,
                'Done',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                NotificationActionIds.later,
                'Later',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                NotificationActionIds.wrongTime,
                'Wrong time',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                NotificationActionIds.openCoach,
                'Open Coach',
                options: {DarwinNotificationActionOption.foreground},
              ),
            ],
          ),
        ],
      ),
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final timeZoneName =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('[Notif] local timezone set to $timeZoneName');
    } catch (e) {
      // Fall back to UTC if the device timezone can't be resolved. Better to
      // keep scheduling (possibly offset) than to crash notification init.
      debugPrint('[Notif] failed to resolve local timezone, using UTC: $e');
    }
  }

  /// Cold start: the plugin does not always deliver [onDidReceiveNotificationResponse] for
  /// the notification that launched the app. Drain once after [MaterialApp] has a navigator.
  Future<void> drainLaunchNotificationResponse(
    Future<void> Function(NotificationResponse response) onResponse,
  ) async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (response == null) {
      debugPrint('[NotifTap] drainLaunch: no launch notification response');
      return;
    }
    final signature = _responseSignature(response);
    if (signature == _lastDrainedResponseSignature) {
      debugPrint('[NotifTap] drainLaunch: duplicate launch response ignored');
      return;
    }
    debugPrint(
      '[NotifTap] drainLaunch: delivering launch response '
      'id=${response.id} actionId=${response.actionId} payload=${response.payload}',
    );
    _lastDrainedResponseSignature = signature;
    await onResponse(response);
  }

  String _responseSignature(NotificationResponse response) {
    return '${response.notificationResponseType.name}|${response.id}|${response.actionId}|${response.payload}';
  }

  Future<bool> requestPermissionsIfNeeded() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosOk =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    final androidOk = await android?.requestNotificationsPermission() ?? true;
    return iosOk && androidOk;
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,

    /// iOS category (see [NotificationCategoryIds]) — null means no action
    /// buttons on iOS. Only pass a category whose actions the response
    /// handler actually supports for this payload kind.
    String? darwinCategoryId,
  }) async {
    final scheduled = _normalizeScheduleTime(when);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduled, tz.local),
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'coach4life_reminders',
          'Coach4Life Reminders',
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              NotificationActionIds.later,
              'Snooze',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(categoryIdentifier: darwinCategoryId),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    await _indexNotificationTaskMapping(id: id, payload: payload);
  }

  /// Immediate one-shot notification (no scheduling) — e.g. a challenge
  /// invite the sync layer just discovered while the app is running.
  /// Separate channel from task reminders so users can tune them apart.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sidepal_events',
          'SidePal Events',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    await _removeNotificationTaskMapping(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    await _clearNotificationTaskMapping();
  }

  /// Returns the list of notifications currently shown in the OS tray.
  ///
  /// Available on iOS 10+ and Android 6+. Returns an empty list on
  /// unsupported platforms or if the plugin cannot query the tray.
  @override
  Future<List<ActiveNotification>> getActiveNotifications() async {
    try {
      return await _plugin.getActiveNotifications();
    } catch (_) {
      return const [];
    }
  }

  /// Notifications scheduled but not yet delivered (the queue iOS caps at 64).
  /// Distinct from [getActiveNotifications], which reads the delivered tray.
  @override
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (_) {
      return const [];
    }
  }

  int idFromTaskId(String taskId, {int slot = 0}) =>
      ('task:$taskId:$slot').hashCode.abs() % 2147483647;

  /// Distinct from [idFromTaskId] to reduce id collisions between modules.
  @override
  int idFromGoalId(String goalId) =>
      (goalId.hashCode ^ 0x474f414c).abs() % 2147483647;

  /// Slot-aware intention nudge ids (0 = primary, 1 = deadline-eve safety,
  /// 2 = fallback). Mirrored by resolveNotificationRoute for intentions.
  int idFromIntentionId(String intentionId, {int slot = 0}) =>
      ('intention:$intentionId:$slot').hashCode.abs() % 2147483647;

  /// Per-weekday slot (1=Mon…7=Sun) for goals restricted to specific days —
  /// each weekday gets its own weekly-repeating notification.
  @override
  int idFromGoalIdWeekday(String goalId, int weekday) =>
      ('goalw:$goalId:$weekday').hashCode.abs() % 2147483647;

  /// Per day-of-month slot (1–31) for monthly-repeating goal reminders.
  @override
  int idFromGoalIdMonthDay(String goalId, int dayOfMonth) =>
      ('goalm:$goalId:$dayOfMonth').hashCode.abs() % 2147483647;

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
    debugPrint(
      'Scheduling daily goal reminder: id=$id atLocal=$scheduled tz=$when',
    );
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
    await _indexNotificationTaskMapping(id: id, payload: payload);
  }

  /// Repeats every week on [firstFireLocal]'s weekday at its local hour/minute.
  Future<void> scheduleWeeklyAtLocalTime({
    required int id,
    required String title,
    required String body,
    required DateTime firstFireLocal,
    String? payload,
  }) async {
    var scheduled = firstFireLocal;
    final now = DateTime.now();
    while (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    final when = tz.TZDateTime.from(scheduled, tz.local);
    debugPrint(
      'Scheduling weekly goal reminder: id=$id atLocal=$scheduled tz=$when',
    );
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
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
    await _indexNotificationTaskMapping(id: id, payload: payload);
  }

  /// Repeats every month on [firstFireLocal]'s day-of-month at its local
  /// hour/minute. Months without that day (e.g. the 31st) are skipped by
  /// the OS matcher.
  Future<void> scheduleMonthlyAtLocalTime({
    required int id,
    required String title,
    required String body,
    required DateTime firstFireLocal,
    String? payload,
  }) async {
    var scheduled = firstFireLocal;
    final now = DateTime.now();
    while (!scheduled.isAfter(now)) {
      scheduled = DateTime(
        scheduled.year,
        scheduled.month + 1,
        scheduled.day,
        scheduled.hour,
        scheduled.minute,
      );
    }
    final when = tz.TZDateTime.from(scheduled, tz.local);
    debugPrint(
      'Scheduling monthly goal reminder: id=$id atLocal=$scheduled tz=$when',
    );
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
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: payload,
    );
    await _indexNotificationTaskMapping(id: id, payload: payload);
  }

  Future<String?> taskIdForNotificationId(int id) async {
    final map = await _loadNotificationTaskMapping();
    return map[id];
  }

  @visibleForTesting
  Future<void> debugSetTaskIdIndexForTests(Map<int, String> mapping) async {
    _taskIdByNotificationIdCache = Map<int, String>.from(mapping);
    await _saveNotificationTaskMapping();
  }

  Future<void> _indexNotificationTaskMapping({
    required int id,
    required String? payload,
  }) async {
    final map = await _loadNotificationTaskMapping();
    String? taskId;
    if (payload != null && payload.startsWith('task:')) {
      taskId = Uri.decodeComponent(payload.substring('task:'.length));
      if (taskId.isEmpty) taskId = null;
    }
    if (taskId == null) {
      map.remove(id);
      debugPrint('[NotifTap] id-map remove id=$id (no task payload)');
    } else {
      map[id] = taskId;
      debugPrint('[NotifTap] id-map set id=$id -> taskId=$taskId');
    }
    await _saveNotificationTaskMapping();
  }

  Future<void> _removeNotificationTaskMapping(int id) async {
    final map = await _loadNotificationTaskMapping();
    if (map.remove(id) != null) {
      debugPrint('[NotifTap] id-map remove id=$id');
      await _saveNotificationTaskMapping();
    }
  }

  Future<void> _clearNotificationTaskMapping() async {
    final map = await _loadNotificationTaskMapping();
    if (map.isNotEmpty) {
      debugPrint('[NotifTap] id-map clear all entries=${map.length}');
      map.clear();
      await _saveNotificationTaskMapping();
    }
  }

  Future<Map<int, String>> _loadNotificationTaskMapping() async {
    final cached = _taskIdByNotificationIdCache;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_taskIdByNotificationIdPrefsKey);
    if (raw == null || raw.isEmpty) {
      _taskIdByNotificationIdCache = <int, String>{};
      return _taskIdByNotificationIdCache!;
    }
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        final out = <int, String>{};
        parsed.forEach((k, v) {
          final id = int.tryParse(k);
          if (id != null && v is String && v.isNotEmpty) {
            out[id] = v;
          }
        });
        _taskIdByNotificationIdCache = out;
        return out;
      }
    } catch (e) {
      debugPrint('local_notifications_service: swallowed error: $e');
    }
    _taskIdByNotificationIdCache = <int, String>{};
    return _taskIdByNotificationIdCache!;
  }

  Future<void> _saveNotificationTaskMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _taskIdByNotificationIdCache ?? <int, String>{};
    final enc = <String, String>{};
    map.forEach((k, v) {
      enc['$k'] = v;
    });
    await prefs.setString(_taskIdByNotificationIdPrefsKey, jsonEncode(enc));
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
