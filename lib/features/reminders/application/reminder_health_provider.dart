import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/notifications/notification_budget.dart';
import '../../../core/notifications/notification_reconciliation_service.dart';
import '../../../core/push/push_messaging_service.dart';
import '../domain/models/reminder_health.dart';

/// Assembles the reminder health snapshot (FR-R-80).
///
/// A [FutureProvider] rather than a stream: this reads OS state, which has no
/// change notification worth subscribing to. The Settings row and the Home
/// hint both watch it, so they can never disagree, and `ref.invalidate` is
/// how a refresh is requested.
final reminderHealthProvider = FutureProvider<ReminderHealth>((ref) async {
  final notifications = LocalNotificationsService.instance;

  final permitted = await notifications.areNotificationsPermitted();

  int? pendingCount;
  try {
    final pending = await notifications.getPendingNotificationRequests();
    pendingCount = pending.length;
  } catch (_) {
    // Unreadable queue is reported as unknown, not as a fault.
    pendingCount = null;
  }

  return ReminderHealth(
    permitted: permitted,
    pendingCount: pendingCount,
    pendingCap: NotificationBudget.kDefaultSafeCap,
    timeZoneResolved: notifications.isTimeZoneResolved,
    timeZoneName: notifications.resolvedTimeZoneName,
    timeZoneFailureReason: notifications.timeZoneFailureReason,
    lastReconciliationAtMs: NotificationReconciliationService.lastRunAtMs,
    lastReconciliationSummary:
        NotificationReconciliationService.lastRunSummary,
    pushRegistered: PushMessagingService.instance.isRegistered,
    isAndroid: ReminderHealth.platformIsAndroid,
  );
});
