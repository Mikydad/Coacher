import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notifications_service.dart';

/// The "time's up" notification for a focus session with a target
/// (2026-09-27): armed when the timer starts or resumes, disarmed on pause,
/// stop, or a task switch. Local-only, so it works in airplane mode. It
/// surfaces only while the app is away — in the foreground the timer
/// screen's celebration is the moment.
abstract interface class FocusEndAlertPort {
  Future<void> arm({
    required String taskLabel,
    required int targetMinutes,
    required DateTime at,
  });

  Future<void> disarm();
}

class LocalFocusEndAlert implements FocusEndAlertPort {
  const LocalFocusEndAlert();

  /// One focus session runs at a time, so one fixed id: re-arming replaces.
  /// A literal (not a String.hashCode) so a relaunch can still cancel it.
  static const int notificationId = 0x464F4355; // 'FOCU'

  @override
  Future<void> arm({
    required String taskLabel,
    required int targetMinutes,
    required DateTime at,
  }) async {
    try {
      await LocalNotificationsService.instance.scheduleWhenAway(
        id: notificationId,
        title: "⏱ Time's up: $taskLabel",
        body:
            '$targetMinutes minutes of focus. Nice work! Open SidePal to '
            'wrap it up.',
        when: at,
      );
    } catch (e) {
      // Quiet failure: the in-app auto-stop and celebration still run.
      debugPrint('[FocusEndAlert] arm failed: $e');
    }
  }

  @override
  Future<void> disarm() async {
    try {
      await LocalNotificationsService.instance.cancel(notificationId);
    } catch (e) {
      debugPrint('[FocusEndAlert] disarm failed: $e');
    }
  }
}
