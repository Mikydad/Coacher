import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/notifications/local_notifications_service.dart';
import 'package:sidepal/features/goals/application/goal_reminder_sync_service.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/reminders/application/notification_route_resolver.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_type.dart';

import '../../support/no_op_orchestrator_service.dart';

class _FakeGoalNotifications implements GoalNotificationsPort {
  final List<int> cancelledIds = [];

  @override
  int idFromGoalId(String goalId, {int slot = 0}) => slot == 0
      ? (goalId.hashCode ^ 0x474f414c).abs() % 2147483647
      : ('goal:$goalId:$slot').hashCode.abs() % 2147483647;

  @override
  int idFromGoalIdWeekday(String goalId, int weekday) =>
      ('goalw:$goalId:$weekday').hashCode.abs() % 2147483647;

  @override
  int idFromGoalIdMonthDay(String goalId, int dayOfMonth) =>
      ('goalm:$goalId:$dayOfMonth').hashCode.abs() % 2147483647;

  @override
  Future<void> cancel(int id) async => cancelledIds.add(id);
}

UserGoal _goal({
  String id = 'g1',
  bool reminderEnabled = true,
  GoalStatus status = GoalStatus.active,
  GoalRepeatCadence repeatCadence = GoalRepeatCadence.daily,
  int repeatInterval = 1,
  List<int>? scheduledWeekdays,
  int intensity = 3,
  required int startMs,
  required int endMs,
}) {
  return UserGoal(
    id: id,
    title: 'Read daily',
    categoryId: 'study',
    status: status,
    measurementKind: MeasurementKind.minutes,
    targetValue: 1,
    intensity: intensity,
    periodStartMs: startMs,
    periodEndMs: endMs,
    repeatCadence: repeatCadence,
    repeatInterval: repeatInterval,
    scheduledWeekdays: scheduledWeekdays,
    reminderEnabled: reminderEnabled,
    reminderMinutesFromMidnight: reminderEnabled ? 9 * 60 : null,
    reminderStyle: GoalReminderStyle.dailyOnce,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

void main() {
  late _FakeGoalNotifications notifications;
  late NoOpOrchestratorService orchestrator;
  late GoalReminderSyncService service;
  final now = DateTime(2025, 3, 1, 8, 0); // 08:00 — before the 09:00 reminder

  setUp(() {
    notifications = _FakeGoalNotifications();
    orchestrator = NoOpOrchestratorService();
    service = GoalReminderSyncService(
      notifications: notifications,
      orchestrator: orchestrator,
      now: () => now,
    );
  });

  UserGoal marchGoal({
    GoalRepeatCadence cadence = GoalRepeatCadence.daily,
    List<int>? weekdays,
    GoalStatus status = GoalStatus.active,
    bool reminderEnabled = true,
    int intensity = 3,
    int repeatInterval = 1,
  }) => _goal(
    startMs: DateTime(2025, 3, 1).millisecondsSinceEpoch,
    endMs: DateTime(2025, 3, 31, 23, 59).millisecondsSinceEpoch,
    repeatCadence: cadence,
    scheduledWeekdays: weekdays,
    status: status,
    reminderEnabled: reminderEnabled,
    intensity: intensity,
    repeatInterval: repeatInterval,
  );

  test(
    'an active daily goal arms TWO occurrences, in distinct slots (C4: one '
    'armed occurrence meant an untouched phone went quiet after the first)',
    () async {
      await service.applyForGoal(marchGoal());

      expect(orchestrator.evaluated, hasLength(2));

      final first = orchestrator.evaluated[0];
      expect(first.entityKind, ReminderEntityKinds.goal);
      expect(first.entityId, 'g1');
      expect(first.entityTitle, 'Goal: Read daily');
      expect(first.proposedAt, DateTime(2025, 3, 1, 9, 0));
      expect(first.reminderType, ReminderType.scheduled);
      expect(first.slot, 0);
      // intensity 3 → disciplined mode → disciplined copy.
      expect(first.enforcementMode, 'disciplined');
      expect(first.bodyOverride, 'Check in on your goal — stay with the plan.');

      // Tomorrow's occurrence is armed NOW, so missing an app-open cannot
      // silence the goal.
      final second = orchestrator.evaluated[1];
      expect(second.proposedAt, DateTime(2025, 3, 2, 9, 0));
      expect(second.slot, 1);
      // Distinct slots mean distinct OS ids — arming the second must not
      // cancel the first.
      expect(
        notifications.idFromGoalId('g1', slot: 1),
        isNot(notifications.idFromGoalId('g1', slot: 0)),
      );
    },
  );

  test('passive (repeat=off) goal schedules nothing', () async {
    await service.applyForGoal(marchGoal(cadence: GoalRepeatCadence.off));

    expect(orchestrator.evaluated, isEmpty);
    // Cancel sweep still ran (cleanup on transition to passive).
    expect(orchestrator.cancelled, contains('g1'));
  });

  test('paused goal cancels and schedules nothing', () async {
    await service.applyForGoal(marchGoal(status: GoalStatus.paused));

    expect(orchestrator.evaluated, isEmpty);
    expect(orchestrator.cancelled, contains('g1'));
  });

  test('reminder disabled schedules nothing', () async {
    await service.applyForGoal(marchGoal(reminderEnabled: false));

    expect(orchestrator.evaluated, isEmpty);
  });

  test('a weekly goal arms its next two matching weekdays', () async {
    // 2025-03-01 is a Saturday; the next two Mondays are the 3rd and the 10th.
    await service.applyForGoal(
      marchGoal(
        cadence: GoalRepeatCadence.weekly,
        weekdays: [DateTime.monday],
      ),
    );

    expect(orchestrator.evaluated, hasLength(2));
    expect(orchestrator.evaluated[0].proposedAt, DateTime(2025, 3, 3, 9, 0));
    expect(orchestrator.evaluated[1].proposedAt, DateTime(2025, 3, 10, 9, 0));
  });

  test('a goal whose period holds only one more day arms just that one, and '
      'sweeps the stale sibling slot', () async {
    final lastDay = _goal(
      startMs: DateTime(2025, 3, 1).millisecondsSinceEpoch,
      endMs: DateTime(2025, 3, 1, 23, 59).millisecondsSinceEpoch,
    );

    await service.applyForGoal(lastDay);

    expect(orchestrator.evaluated, hasLength(1));
    // Slot 1 has nothing to hold, so it is explicitly cancelled rather than
    // left armed from a previous, longer period.
    expect(
      notifications.cancelledIds,
      contains(notifications.idFromGoalId('g1', slot: 1)),
    );
  });

  test('cancelForGoal sweeps legacy slot ids and the ledger entry', () async {
    await service.cancelForGoal('g1');

    // 2 armed slots + 7 weekday + 31 month-day legacy ids.
    expect(notifications.cancelledIds, hasLength(40));
    expect(
      notifications.cancelledIds,
      containsAll([
        notifications.idFromGoalId('g1', slot: 0),
        notifications.idFromGoalId('g1', slot: 1),
      ]),
    );
    expect(orchestrator.cancelled, ['g1']);
  });

  test(
      'schedule path never destroys the armed slot up front — the '
      'orchestrator swaps it after the budget check (review A)', () async {
    await service.applyForGoal(marchGoal());
    await service.applyForGoal(marchGoal());

    // Two applies × two armed occurrences.
    expect(orchestrator.evaluated, hasLength(4));
    // No entity-scoped cancel from the sync service on the schedule path:
    // a suppressed/budget-denied evaluation must leave the previously
    // armed reminder intact.
    expect(orchestrator.cancelled, isEmpty);
    // Only the retired legacy weekday/month-day slots are swept up front
    // (7 + 31 = 38 per apply); neither live slot is touched.
    expect(notifications.cancelledIds, hasLength(76));
    expect(
      notifications.cancelledIds,
      isNot(contains(notifications.idFromGoalId('g1', slot: 0))),
    );
    expect(
      notifications.cancelledIds,
      isNot(contains(notifications.idFromGoalId('g1', slot: 1))),
    );
  });

  test('rearmIfStale throttles within the min interval', () async {
    final goals = [marchGoal()];
    await service.rearmIfStale(goals);
    await service.rearmIfStale(goals); // within 5 min — skipped

    expect(orchestrator.evaluated, hasLength(2)); // one apply, two slots

    service.debugResetRearmThrottle();
    await service.rearmIfStale(goals);
    expect(orchestrator.evaluated, hasLength(4));
  });

  test('flexible intensity maps to flexible copy and mode', () async {
    await service.applyForGoal(marchGoal(intensity: 1));

    final intent = orchestrator.evaluated.first;
    expect(intent.enforcementMode, 'flexible');
    expect(intent.bodyOverride, 'Time for your planned actions.');
  });

  test('interval repeat arms the next two action days', () async {
    // Every 2 days from 2025-03-01 → action days 1,3,5… — at 08:00 on the
    // 1st the same-day 09:00 slot is still ahead.
    await service.applyForGoal(marchGoal(repeatInterval: 2));

    expect(orchestrator.evaluated, hasLength(2));
    expect(orchestrator.evaluated[0].proposedAt, DateTime(2025, 3, 1, 9, 0));
    expect(orchestrator.evaluated[1].proposedAt, DateTime(2025, 3, 3, 9, 0));
  });
}
