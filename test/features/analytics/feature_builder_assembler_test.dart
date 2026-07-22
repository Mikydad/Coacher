import 'package:sidepal/features/analytics/application/feature_builder_assembler.dart';
import 'package:sidepal/features/analytics/application/feature_builder_input_adapters.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_event.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_stats_cache.dart';
import 'package:sidepal/features/goals/domain/models/goal_check_in.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/planning/application/planned_task_collect.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feature_builder_assembler', () {
    test('assembles task and goal features deterministically', () {
      final now = DateTime(2026, 5, 6, 12);
      final bundle = FeatureBuilderInputBundle(
        window: const FeatureBuilderDateWindow(
          startDateKey: '2026-04-07',
          endDateKey: '2026-05-06',
          dateKeys: ['2026-05-04', '2026-05-05', '2026-05-06'],
        ),
        eventHistoryByEntityId: {
          't1': FeatureEventHistory(
            entityId: 't1',
            events: [
              _event(
                id: 'e1',
                type: AnalyticsEventType.taskCompleted,
                entityId: 't1',
                dateKey: '2026-05-06',
                iso: '2026-05-06T09:30:00',
              ),
            ],
          ),
        },
        taskSeedsById: {
          't1': TaskFeatureSeed(
            row: PlannedTaskRow(
              dateKey: '2026-05-06',
              routineId: 'r',
              blockId: 'b',
              task: _task(id: 't1', habit: false),
            ),
            entityKind: 'task',
            scheduledDateKey: '2026-05-06',
            scheduledDateKeysInWindow: const {'2026-05-06'},
          ),
        },
        goalSeedsById: {
          'g1': GoalFeatureSeed(
            goal: _goal(id: 'g1'),
            entityKind: 'goal',
            checkIns: const [
              GoalCheckIn(
                goalId: 'g1',
                dateKey: '2026-05-06',
                metCommitment: true,
                updatedAtMs: 1,
              ),
            ],
            completedMilestones: 1,
            totalMilestones: 2,
          ),
        },
        statsCache: const <AnalyticsStatsCache>[],
      );

      const assembler = FeatureBuilderAssembler();
      final first = assembler.assemble(inputs: bundle, now: now);
      final second = assembler.assemble(inputs: bundle, now: now);

      expect(first.issues, isEmpty);
      expect(first.featuresByEntityId.keys, containsAll(['t1', 'g1']));
      final t1 = first.featuresByEntityId['t1']!;
      expect(t1.timeMetrics.scheduledOccurrences7d, 1);
      expect(t1.timeMetrics.missedScheduledCount7d, 0);
      expect(t1.timeMetrics.completionRate7d, 1.0);
      expect(t1.timeMetrics.isCurrentlyOverdue, false);
      expect(
        first.featuresByEntityId['t1']!.toMap(),
        equals(second.featuresByEntityId['t1']!.toMap()),
      );
      expect(
        first.featuresByEntityId['g1']!.toMap(),
        equals(second.featuresByEntityId['g1']!.toMap()),
      );
    });

    test('handles missing entity ids with issues list', () {
      final bundle = FeatureBuilderInputBundle(
        window: const FeatureBuilderDateWindow(
          startDateKey: '2026-04-07',
          endDateKey: '2026-05-06',
          dateKeys: ['2026-05-06'],
        ),
        eventHistoryByEntityId: const {},
        taskSeedsById: const {},
        goalSeedsById: {
          '': GoalFeatureSeed(
            goal: _goal(id: ''),
            entityKind: 'goal',
            checkIns: const [],
            completedMilestones: 0,
            totalMilestones: 0,
          ),
        },
        statsCache: const <AnalyticsStatsCache>[],
      );
      const assembler = FeatureBuilderAssembler();
      final out = assembler.assemble(inputs: bundle, now: DateTime(2026, 5, 6));
      expect(out.featuresByEntityId, isEmpty);
      expect(out.issues, isNotEmpty);
    });
  });
}

PlannedTask _task({required String id, required bool habit}) {
  return PlannedTask(
    id: id,
    routineId: 'r',
    blockId: 'b',
    title: 'Task',
    durationMinutes: 25,
    priority: 2,
    orderIndex: 0,
    reminderEnabled: true,
    reminderTimeIso: '2026-05-06T09:00:00',
    status: TaskStatus.completed,
    createdAtMs: 0,
    updatedAtMs: 0,
    isHabitAnchor: habit,
  );
}

UserGoal _goal({required String id}) {
  return UserGoal(
    id: id,
    title: 'Goal',
    categoryId: 'study',
    repeatCadence: GoalRepeatCadence.daily,
    status: GoalStatus.active,
    measurementKind: MeasurementKind.sessions,
    targetValue: 1,
    intensity: 3,
    periodStartMs: DateTime(2026, 5, 1).millisecondsSinceEpoch,
    periodEndMs: DateTime(2026, 5, 10).millisecondsSinceEpoch,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

AnalyticsEvent _event({
  required String id,
  required AnalyticsEventType type,
  required String entityId,
  required String dateKey,
  required String iso,
}) {
  return AnalyticsEvent(
    id: id,
    type: type,
    entityId: entityId,
    entityKind: 'task',
    dateKey: dateKey,
    timestampLocalIso: iso,
    sourceSurface: 'test',
    idempotencyKey: id,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}
