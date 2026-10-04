import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// AlarmKit (iOS 26+) — real system alarms for alarm reminders
/// (feat/alarm-mode, settled with Miko 2026-10-04).
///
/// A notification ring is muted by the silent switch and needs Face ID to
/// stop from the lock screen. An AlarmKit alarm is the Clock app's alarm:
/// full screen on the lock screen, rings through silent mode and Focus
/// until the user acts, Stop works without unlocking. When the user has
/// granted it, [AlarmScheduler] hands alarms here INSTEAD of the five
/// notification rings; denied, unavailable (iOS < 26, Android) or failing,
/// the rings stay the floor.
///
/// The native half is ios/Runner/AlarmKitBridge.swift. Its Snooze button
/// runs an App Intent inside the app process — no app launch to the
/// foreground — that re-schedules the same alarm id five minutes on and
/// records the snooze for Dart to pick up ([drainEvents]).
enum AlarmKitAuthorization {
  /// No AlarmKit on this device (iOS < 26, Android, tests).
  unavailable,
  notDetermined,
  denied,
  authorized;

  static AlarmKitAuthorization fromWire(String? value) => switch (value) {
    'authorized' => AlarmKitAuthorization.authorized,
    'denied' => AlarmKitAuthorization.denied,
    'notDetermined' => AlarmKitAuthorization.notDetermined,
    _ => AlarmKitAuthorization.unavailable,
  };

  /// AlarmKit exists here, whether or not the user has answered yet.
  bool get isSupported => this != AlarmKitAuthorization.unavailable;
}

/// Something the native side did while Dart was not running — today only
/// a Snooze from the alarm's own button.
@immutable
class AlarmKitEvent {
  const AlarmKitEvent({required this.kind, required this.taskId, this.untilMs});

  final String kind;
  final String taskId;

  /// For a snooze: when the re-scheduled alarm rings.
  final int? untilMs;

  bool get isSnooze => kind == 'snooze';

  static AlarmKitEvent? fromMap(Map<Object?, Object?> map) {
    final kind = map['kind'];
    final taskId = map['taskId'];
    if (kind is! String || taskId is! String || taskId.isEmpty) return null;
    final until = map['untilMs'];
    return AlarmKitEvent(
      kind: kind,
      taskId: taskId,
      untilMs: until is num ? until.toInt() : null,
    );
  }

  @override
  String toString() => 'AlarmKitEvent($kind, $taskId, until: $untilMs)';
}

/// The AlarmKit surface the alarm scheduler needs (test seam).
abstract interface class AlarmKitPort {
  Future<AlarmKitAuthorization> authorizationStatus();

  /// Shows the system prompt when the user has not answered yet; otherwise
  /// returns the standing answer without prompting.
  Future<AlarmKitAuthorization> requestAuthorization();

  /// Schedules (or replaces — same [alarmId]) one alarm. False when the
  /// native side refused it; the caller falls back to notification rings.
  Future<bool> schedule({
    required String alarmId,
    required String taskId,
    required String title,
    required DateTime fireAt,
    required int snoozeMinutes,
  });

  /// Cancels a scheduled alarm, or stops one that is ringing.
  Future<void> cancel(String alarmId);

  /// Ids of every alarm AlarmKit holds for this app, upper-case.
  Future<Set<String>> scheduledIds();

  /// Reads AND clears what the native side recorded — idempotent consume.
  Future<List<AlarmKitEvent>> drainEvents();
}

/// One stable AlarmKit id per task, so a re-arm replaces instead of
/// stacking and the Snooze intent can re-schedule the same alarm.
/// A name-based (v5-shaped) UUID over the task id, upper-case like Swift's
/// `UUID.uuidString`.
String alarmKitIdFor(String taskId) {
  final bytes = sha1.convert(utf8.encode('sidepal-alarm:$taskId')).bytes;
  final b = List<int>.from(bytes.take(16));
  b[6] = (b[6] & 0x0f) | 0x50;
  b[8] = (b[8] & 0x3f) | 0x80;
  final hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
          '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
          '${hex.substring(20)}'
      .toUpperCase();
}

/// Thin wrapper over the native channel. Every call degrades to "AlarmKit
/// unavailable" off iOS and when the channel is missing (tests, old builds).
class MethodChannelAlarmKit implements AlarmKitPort {
  static const _channel = MethodChannel('sidepal/alarm_kit');

  bool get _onIos => !kIsWeb && Platform.isIOS;

  @override
  Future<AlarmKitAuthorization> authorizationStatus() async {
    if (!_onIos) return AlarmKitAuthorization.unavailable;
    try {
      return AlarmKitAuthorization.fromWire(
        await _channel.invokeMethod<String>('getAuthorizationStatus'),
      );
    } catch (e) {
      debugPrint('[AlarmKit] status failed: $e');
      return AlarmKitAuthorization.unavailable;
    }
  }

  @override
  Future<AlarmKitAuthorization> requestAuthorization() async {
    if (!_onIos) return AlarmKitAuthorization.unavailable;
    try {
      return AlarmKitAuthorization.fromWire(
        await _channel.invokeMethod<String>('requestAccess'),
      );
    } catch (e) {
      debugPrint('[AlarmKit] request failed: $e');
      return AlarmKitAuthorization.unavailable;
    }
  }

  @override
  Future<bool> schedule({
    required String alarmId,
    required String taskId,
    required String title,
    required DateTime fireAt,
    required int snoozeMinutes,
  }) async {
    if (!_onIos) return false;
    try {
      return await _channel.invokeMethod<bool>('schedule', {
            'id': alarmId,
            'taskId': taskId,
            'title': title,
            'fireAtMs': fireAt.millisecondsSinceEpoch,
            'snoozeMinutes': snoozeMinutes,
          }) ??
          false;
    } catch (e) {
      debugPrint('[AlarmKit] schedule failed: $e');
      return false;
    }
  }

  @override
  Future<void> cancel(String alarmId) async {
    if (!_onIos) return;
    try {
      await _channel.invokeMethod<void>('cancel', {'id': alarmId});
    } catch (e) {
      debugPrint('[AlarmKit] cancel failed: $e');
    }
  }

  @override
  Future<Set<String>> scheduledIds() async {
    if (!_onIos) return const {};
    try {
      final ids = await _channel.invokeListMethod<String>('scheduledIds');
      return {for (final id in ids ?? const <String>[]) id.toUpperCase()};
    } catch (e) {
      debugPrint('[AlarmKit] list failed: $e');
      return const {};
    }
  }

  @override
  Future<List<AlarmKitEvent>> drainEvents() async {
    if (!_onIos) return const [];
    try {
      final raw = await _channel.invokeListMethod<Object?>('drainEvents');
      return [
        for (final item in raw ?? const <Object?>[])
          if (item is Map<Object?, Object?>) ?AlarmKitEvent.fromMap(item),
      ];
    } catch (e) {
      debugPrint('[AlarmKit] drain failed: $e');
      return const [];
    }
  }
}
