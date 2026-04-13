import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService instance = LocalNotificationsService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  String? _lastDrainedResponseSignature;
  Map<int, String>? _taskIdByNotificationIdCache;
  static const _taskIdByNotificationIdPrefsKey = 'notification_task_id_index_v1';

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
    await _indexNotificationTaskMapping(id: id, payload: payload);
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    await _removeNotificationTaskMapping(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    await _clearNotificationTaskMapping();
  }

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

  Future<void> _indexNotificationTaskMapping({required int id, required String? payload}) async {
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
    } catch (_) {}
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
