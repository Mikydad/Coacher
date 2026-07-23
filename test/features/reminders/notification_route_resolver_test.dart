import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/notifications/local_notifications_service.dart';
import 'package:sidepal/core/notifications/notification_action_ids.dart';
import 'package:sidepal/features/context_override/domain/models/interruption_level.dart';
import 'package:sidepal/features/reminders/application/notification_route_resolver.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_intent.dart';

ReminderIntent _intent(String entityKind, {String entityId = 'e1'}) =>
    ReminderIntent(
      id: 'ri_test',
      entityId: entityId,
      entityKind: entityKind,
      entityTitle: 'Title',
      proposedAt: DateTime(2025, 3, 1, 9),
      importance: 50,
      interruptionLevel: InterruptionLevel.medium,
      enforcementMode: 'flexible',
      createdAtMs: 0,
    );

void main() {
  final notifications = LocalNotificationsService.instance;

  test('task intent routes to task id namespace with task payload + category',
      () {
    final route = resolveNotificationRoute(_intent(ReminderEntityKinds.task));

    expect(route.notifId, notifications.idFromTaskId('e1'));
    expect(route.payload, 'task:e1');
    expect(route.darwinCategoryId, NotificationCategoryIds.taskReminder);
    expect(route.immediate, isFalse);
  });

  test('habit intent routes like a task', () {
    final route = resolveNotificationRoute(_intent(ReminderEntityKinds.habit));

    expect(route.notifId, notifications.idFromTaskId('e1'));
    expect(route.payload, 'task:e1');
  });

  test('goal intent routes to goal id namespace with goal payload, no category',
      () {
    final route = resolveNotificationRoute(_intent(ReminderEntityKinds.goal));

    // Must stay in sync with LocalNotificationsService.idFromGoalId so
    // cancelForGoal's sweep and tap routing keep working.
    expect(route.notifId, notifications.idFromGoalId('e1'));
    expect(route.payload, 'goal:e1');
    expect(route.darwinCategoryId, isNull);
    expect(route.immediate, isFalse);
  });

  test('stake invite routes to legacy invite id, stake payload, immediate',
      () {
    final route =
        resolveNotificationRoute(_intent(ReminderEntityKinds.stakeInvite));

    // Legacy scheme from main_tab_shell's original showNow call — keeps
    // re-emits stable and lets pre-migration invites cancel under the same id.
    expect(route.notifId, 'e1'.hashCode & 0x7fffffff);
    expect(route.payload, 'stake:e1');
    expect(route.darwinCategoryId, isNull);
    expect(route.immediate, isTrue);
  });

  test('entity ids are uri-encoded in payloads', () {
    final route = resolveNotificationRoute(
      _intent(ReminderEntityKinds.goal, entityId: 'a b/c'),
    );

    expect(route.payload, 'goal:${Uri.encodeComponent('a b/c')}');
  });
}
