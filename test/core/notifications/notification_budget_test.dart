import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/notifications/notification_budget.dart';

class _FakePending implements PendingNotificationsSource {
  _FakePending(this.count, {this.throws = false});

  final int count;
  final bool throws;

  @override
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async {
    if (throws) throw StateError('platform channel unavailable');
    return List.generate(
      count,
      (i) => PendingNotificationRequest(i, 'title', 'body', null),
    );
  }
}

void main() {
  test('allows scheduling under the safety cap', () async {
    final budget = NotificationBudget(pending: _FakePending(10));
    expect(await budget.canSchedule(), isTrue);
  });

  test('allows exactly up to the cap', () async {
    final budget = NotificationBudget(
      pending: _FakePending(NotificationBudget.kDefaultSafeCap - 1),
    );
    expect(await budget.canSchedule(), isTrue);
  });

  test('denies when the cap would be crossed', () async {
    final budget = NotificationBudget(
      pending: _FakePending(NotificationBudget.kDefaultSafeCap),
    );
    expect(await budget.canSchedule(), isFalse);
  });

  test('multi-slot requests count against the cap', () async {
    final budget = NotificationBudget(
      pending: _FakePending(NotificationBudget.kDefaultSafeCap - 2),
    );
    expect(await budget.canSchedule(needed: 2), isTrue);
    expect(await budget.canSchedule(needed: 3), isFalse);
  });

  test('fails open when the pending queue cannot be read', () async {
    final budget = NotificationBudget(pending: _FakePending(0, throws: true));
    expect(await budget.canSchedule(), isTrue);
  });

  test('custom cap is honored', () async {
    final budget = NotificationBudget(pending: _FakePending(5), safeCap: 5);
    expect(await budget.canSchedule(), isFalse);
  });
}
