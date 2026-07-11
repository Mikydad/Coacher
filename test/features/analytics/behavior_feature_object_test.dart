import 'package:coach_for_life/features/analytics/application/behavior_feature_entity_kind.dart';
import 'package:coach_for_life/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_enums.dart';
import 'package:coach_for_life/features/goals/domain/models/user_goal.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('behavior_feature_object', () {
    test('fromMap applies deterministic defaults for sparse payloads', () {
      final feature = BehaviorFeatureObject.fromMap(<String, dynamic>{
        'entityId': 'task-1',
        'entityKind': 'task',
      });

      expect(feature.entityId, 'task-1');
      expect(feature.entityKind, BehaviorEntityKind.task);
      expect(feature.timeMetrics.completionRate7d, 0);
      expect(feature.timeMetrics.missedScheduledCount7d, 0);
      expect(feature.streakMetrics.currentStreak, 0);
      expect(feature.effortMetrics.avgSnoozeCount, 0);
      expect(feature.goalMetrics.gap, 0);
      expect(feature.contextFeatures.bestTimeBlock, 'morning');
      expect(feature.contextFeatures.priority, 3);
      expect(feature.schemaVersion, kBehaviorFeatureSchemaVersion);
    });

    test('fromMap falls back to derived goal gap when missing', () {
      final feature = BehaviorFeatureObject.fromMap(<String, dynamic>{
        'entityId': 'goal-1',
        'entityKind': 'goal',
        'goalMetrics': {'progress': 0.2, 'expectedProgress': 0.7},
      });

      expect(feature.goalMetrics.gap, closeTo(0.5, 0.0001));
    });

    test('toMap clamps unsupported values to safe ranges', () {
      final feature = BehaviorFeatureObject(
        entityId: 'habit-1',
        entityKind: BehaviorEntityKind.habit,
        timeMetrics: const BehaviorTimeMetrics(
          scheduledOccurrences7d: -1,
          scheduledOccurrences30d: -2,
          missedScheduledCount7d: -1,
          missedScheduledCount30d: -1,
          completionRate7d: 2.5,
          completionRate30d: -1,
          flexCompletionFrequency7d: 9,
          flexCompletionFrequency30d: -1,
          lateCompletionRate7d: 4,
          lateCompletionRate30d: -2,
          avgCompletionDelayMinutes: -5,
          isCurrentlyOverdue: true,
          minutesOverdue: -3,
        ),
        streakMetrics: const BehaviorStreakMetrics(
          currentStreak: -3,
          longestStreak: -4,
          missedLast2Days: true,
          missedCount7d: 20,
        ),
        effortMetrics: const BehaviorEffortMetrics(
          avgSnoozeCount: -1,
          avgSessionDuration: -1,
          plannedVsActualRatio: -1,
        ),
        goalMetrics: const BehaviorGoalMetrics(
          progress: 2,
          expectedProgress: -1,
          gap: 99,
        ),
        contextFeatures: const BehaviorContextFeatures(
          bestTimeBlock: 'night',
          isHabitAnchor: true,
          priority: 9,
        ),
        computedAtMs: 123,
      );

      final out = feature.toMap();
      final time = out['timeMetrics'] as Map<String, dynamic>;
      final streak = out['streakMetrics'] as Map<String, dynamic>;
      final effort = out['effortMetrics'] as Map<String, dynamic>;
      final goal = out['goalMetrics'] as Map<String, dynamic>;
      final context = out['contextFeatures'] as Map<String, dynamic>;

      expect(time['completionRate7d'], 1.0);
      expect(time['completionRate30d'], 0.0);
      expect(time['scheduledOccurrences7d'], 0);
      expect(time['flexCompletionFrequency7d'], 1.0);
      expect(time['lateCompletionRate7d'], 1.0);
      expect(time['avgCompletionDelayMinutes'], 0);
      expect(streak['currentStreak'], 0);
      expect(streak['longestStreak'], 0);
      expect(streak['missedCount7d'], 7);
      expect(effort['avgSnoozeCount'], 0.0);
      expect(effort['avgSessionDuration'], 0);
      expect(effort['plannedVsActualRatio'], 0.0);
      expect(goal['progress'], 1.0);
      expect(goal['expectedProgress'], 0.0);
      expect(context['bestTimeBlock'], 'morning');
      expect(context['priority'], 5);
    });
  });

  group('behavior_entity_kind_mapping', () {
    test('maps habit-anchor task to habit kind', () {
      final task = PlannedTask(
        id: 't1',
        routineId: 'r1',
        blockId: 'b1',
        title: 'task',
        durationMinutes: 25,
        priority: 3,
        orderIndex: 0,
        reminderEnabled: false,
        reminderTimeIso: null,
        status: TaskStatus.notStarted,
        createdAtMs: 0,
        updatedAtMs: 0,
        isHabitAnchor: true,
      );
      expect(behaviorEntityKindForTask(task), BehaviorEntityKind.habit);
    });

    test('maps non-habit goal to goal kind', () {
      final goal = UserGoal(
        id: 'g1',
        title: 'Goal',
        categoryId: 'study',
        repeatCadence: GoalRepeatCadence.weekly,
        status: GoalStatus.active,
        measurementKind: MeasurementKind.sessions,
        targetValue: 1,
        intensity: 3,
        periodStartMs: 0,
        periodEndMs: 1,
        createdAtMs: 0,
        updatedAtMs: 0,
      );
      expect(behaviorEntityKindForGoal(goal), BehaviorEntityKind.goal);
    });
  });
}
