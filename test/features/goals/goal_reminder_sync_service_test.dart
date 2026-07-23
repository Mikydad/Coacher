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
  int idFromGoalId(String goalId) =>
      (goalId.hashCode ^ 0x474f414c).abs() % 2147483647;

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

  test('active daily goal produces exactly one goal intent via orchestrator',
      () async {
    await service.applyForGoal(marchGoal());

    expect(orchestrator.evaluated, hasLength(1));
    final intent = orchestrator.evaluated.single;
    expect(intent.entityKind, ReminderEntityKinds.goal);
    expect(intent.entityId, 'g1');
    expect(intent.entityTitle, 'Goal: Read daily');
    expect(intent.proposedAt, DateTime(2025, 3, 1, 9, 0));
    expect(intent.reminderType, ReminderType.scheduled);
    // intensity 3 → disciplined mode → disciplined copy.
    expect(intent.enforcementMode, 'disciplined');
    expect(intent.bodyOverride, 'Check in on your goal — stay with the plan.');
  });

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

  test('weekly goal schedules single next occurrence on selected weekday',
      () async {
    // 2025-03-01 is a Saturday; next Monday is 2025-03-03.
    await service.applyForGoal(
      marchGoal(
        cadence: GoalRepeatCadence.weekly,
        weekdays: [DateTime.monday],
      ),
    );

    expect(orchestrator.evaluated, hasLength(1));
    expect(
      orchestrator.evaluated.single.proposedAt,
      DateTime(2025, 3, 3, 9, 0),
    );
  });

  test('cancelForGoal sweeps legacy slot ids and the ledger entry', () async {
    await service.cancelForGoal('g1');

    // 1 base + 7 weekday + 31 month-day legacy ids.
    expect(notifications.cancelledIds, hasLength(39));
    expect(orchestrator.cancelled, ['g1']);
  });

  test('applyForGoal always re-cancels before scheduling (idempotent)',
      () async {
    await service.applyForGoal(marchGoal());
    await service.applyForGoal(marchGoal());

    expect(orchestrator.evaluated, hasLength(2));
    expect(orchestrator.cancelled, ['g1', 'g1']);
  });

  test('rearmIfStale throttles within the min interval', () async {
    final goals = [marchGoal()];
    await service.rearmIfStale(goals);
    await service.rearmIfStale(goals); // within 5 min — skipped

    expect(orchestrator.evaluated, hasLength(1));

    service.debugResetRearmThrottle();
    await service.rearmIfStale(goals);
    expect(orchestrator.evaluated, hasLength(2));
  });

  test('flexible intensity maps to flexible copy and mode', () async {
    await service.applyForGoal(marchGoal(intensity: 1));

    final intent = orchestrator.evaluated.single;
    expect(intent.enforcementMode, 'flexible');
    expect(intent.bodyOverride, 'Time for your planned actions.');
  });

  test('interval repeat schedules the next action day only', () async {
    // Every 2 days from 2025-03-01 → action days 1,3,5… — at 08:00 on the
    // 1st the same-day 09:00 slot is still ahead.
    await service.applyForGoal(marchGoal(repeatInterval: 2));

    expect(orchestrator.evaluated, hasLength(1));
    expect(
      orchestrator.evaluated.single.proposedAt,
      DateTime(2025, 3, 1, 9, 0),
    );
  });
}
