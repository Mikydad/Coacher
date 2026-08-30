import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Source of the OS pending-notification queue (test seam — implemented by
/// [LocalNotificationsService]).
abstract interface class PendingNotificationsSource {
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests();
}

/// Guards iOS's hard cap of 64 pending local notifications.
///
/// Beyond 64 pending requests iOS silently discards the overflow — no error,
/// an arbitrary reminder just never fires. Every producer that schedules a
/// future notification consults this budget first so the app stays under a
/// safety margin and the failure mode becomes an explicit, logged skip
/// instead of a silent OS drop. (Android has no such cap; one shared budget
/// keeps behavior predictable across platforms.)
class NotificationBudget {
  NotificationBudget({
    required PendingNotificationsSource pending,
    int safeCap = kDefaultSafeCap,
  }) : _pending = pending,
       _safeCap = safeCap;

  /// Safety margin under the hard iOS cap of 64 — leaves head-room for
  /// producers that schedule between budget checks.
  static const int kDefaultSafeCap = 56;

  final PendingNotificationsSource _pending;
  final int _safeCap;

  /// True when [needed] more notifications can be scheduled without crossing
  /// the safety margin. Fails CLOSED (false) if the pending queue can't be
  /// read (P2-12): the budget exists because iOS silently discards overflow
  /// past 64 pending — scheduling blind into a possibly-full queue recreates
  /// exactly the failure this class prevents. Skipping is explicit, logged,
  /// and self-heals on the next replan.
  Future<bool> canSchedule({int needed = 1}) async {
    final List<PendingNotificationRequest> pending;
    try {
      pending = await _pending.getPendingNotificationRequests();
    } catch (e) {
      debugPrint('[NotificationBudget] pending query failed, denying: $e');
      return false;
    }
    final ok = pending.length + needed <= _safeCap;
    if (!ok) {
      debugPrint(
        '[NotificationBudget] denied: pending=${pending.length} '
        'needed=$needed cap=$_safeCap',
      );
    }
    return ok;
  }

  /// How many more notifications fit under the safety margin.
  ///
  /// The ladder compiler needs a COUNT, not a yes/no: a task whose mode calls
  /// for four slots may only have room for two, and dropping the deepest two
  /// is better than dropping the task. Fails CLOSED (0) for the same reason
  /// [canSchedule] fails closed — scheduling blind into a possibly-full queue
  /// recreates the silent-overflow bug this class exists to prevent.
  Future<int> remainingCapacity() async {
    try {
      final pending = await _pending.getPendingNotificationRequests();
      final left = _safeCap - pending.length;
      return left < 0 ? 0 : left;
    } catch (e) {
      debugPrint('[NotificationBudget] pending query failed, reporting 0: $e');
      return 0;
    }
  }
}
