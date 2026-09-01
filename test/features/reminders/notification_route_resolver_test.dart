import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/notifications/local_notifications_service.dart';
import 'package:sidepal/core/notifications/notification_action_ids.dart';
import 'package:sidepal/features/analytics/application/coaching_insight_notification_policy.dart';
import 'package:sidepal/features/context_override/domain/models/interruption_level.dart';
import 'package:sidepal/features/reminders/application/notification_route_resolver.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_intent.dart';

ReminderIntent _intent(
  String entityKind, {
  String entityId = 'e1',
  int slot = 0,
}) => ReminderIntent(
  id: 'ri_test',
  entityId: entityId,
  entityKind: entityKind,
  entityTitle: 'Title',
  proposedAt: DateTime(2025, 3, 1, 9),
  importance: 50,
  interruptionLevel: InterruptionLevel.medium,
  enforcementMode: 'flexible',
  slot: slot,
  createdAtMs: 0,
);

void main() {
  final notifications = LocalNotificationsService.instance;

  test(
    'task intent routes to task id namespace with task payload + category',
    () {
      final route = resolveNotificationRoute(_intent(ReminderEntityKinds.task));

      expect(route.notifId, notifications.idFromTaskId('e1'));
      expect(route.payload, 'task:e1');
      expect(route.darwinCategoryId, NotificationCategoryIds.taskReminder);
      expect(route.immediate, isFalse);
    },
  );

  test('habit intent routes like a task', () {
    final route = resolveNotificationRoute(_intent(ReminderEntityKinds.habit));

    expect(route.notifId, notifications.idFromTaskId('e1'));
    expect(route.payload, 'task:e1');
  });

  test(
    'goal intent routes to goal id namespace with goal payload, no category',
    () {
      final route = resolveNotificationRoute(_intent(ReminderEntityKinds.goal));

      // Must stay in sync with LocalNotificationsService.idFromGoalId so
      // cancelForGoal's sweep and tap routing keep working.
      expect(route.notifId, notifications.idFromGoalId('e1'));
      expect(route.payload, 'goal:e1');
      expect(route.darwinCategoryId, isNull);
      expect(route.immediate, isFalse);
    },
  );

  test(
    "goal slot 1 mirrors the service's slot-aware id and is distinct from "
    'slot 0 (FR-R-14: two armed occurrences must be separately cancellable)',
    () {
      final slot0 = resolveNotificationRoute(
        _intent(ReminderEntityKinds.goal),
      );
      final slot1 = resolveNotificationRoute(
        _intent(ReminderEntityKinds.goal, slot: 1),
      );

      expect(slot1.notifId, notifications.idFromGoalId('e1', slot: 1));
      expect(slot1.notifId, isNot(slot0.notifId));
      // Same tap destination either way — the slot is a scheduling detail.
      expect(slot1.payload, 'goal:e1');
    },
  );

  test(
    'goal slot 0 keeps its historic id so an upgrade cannot orphan an armed '
    'notification',
    () {
      expect(
        resolveNotificationRoute(_intent(ReminderEntityKinds.goal)).notifId,
        ('e1'.hashCode ^ 0x474f414c).abs() % 2147483647,
      );
    },
  );

  test('stake invite routes to legacy invite id, stake payload, immediate', () {
    final route = resolveNotificationRoute(
      _intent(ReminderEntityKinds.stakeInvite),
    );

    // Legacy scheme from main_tab_shell's original showNow call — keeps
    // re-emits stable and lets pre-migration invites cancel under the same id.
    expect(route.notifId, 'e1'.hashCode & 0x7fffffff);
    expect(route.payload, 'stake:e1');
    expect(route.darwinCategoryId, isNull);
    expect(route.immediate, isTrue);
  });

  test('stake card ready routes to its own id space, stake payload, '
      'immediate (OQ-1)', () {
    final route = resolveNotificationRoute(
      _intent(ReminderEntityKinds.stakeCard),
    );

    expect(route.notifId, 'stake_card:e1'.hashCode.abs() % 2147483647);
    // Distinct from the invite scheme for the same challenge id.
    expect(route.notifId, isNot('e1'.hashCode & 0x7fffffff));
    expect(route.payload, 'stake:e1');
    expect(route.immediate, isTrue);
  });

  test('coach insight routes to the fixed COIN slot with a layer4 payload '
      '(V-01)', () {
    final route = resolveNotificationRoute(
      _intent(
        ReminderEntityKinds.coachInsight,
        entityId: 'entity::goal-1::streak',
      ),
    );

    expect(route.notifId, kCoachingInsightNotificationId);
    // Raw id, no percent-encoding — the layer4 tap handler splits on '::'
    // without decoding.
    expect(route.payload, 'layer4:entity::goal-1::streak');
    expect(route.darwinCategoryId, isNull);
    expect(route.immediate, isFalse);
  });

  test('entity ids are uri-encoded in payloads', () {
    final route = resolveNotificationRoute(
      _intent(ReminderEntityKinds.goal, entityId: 'a b/c'),
    );

    expect(route.payload, 'goal:${Uri.encodeComponent('a b/c')}');
  });
}
