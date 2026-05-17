import '../../../core/utils/date_keys.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../planning/application/planned_task_collect.dart';
import '../domain/models/analytics_event.dart';
import '../domain/models/behavior_feature_object.dart';
import 'feature_builder_input_adapters.dart';
import 'feature_builder_metrics.dart';

class FeatureAssemblyIssue {
  const FeatureAssemblyIssue({required this.entityId, required this.reason});

  final String entityId;
  final String reason;
}

class FeatureAssemblyResult {
  const FeatureAssemblyResult({
    required this.featuresByEntityId,
    required this.issues,
  });

  final Map<String, BehaviorFeatureObject> featuresByEntityId;
  final List<FeatureAssemblyIssue> issues;
}

class FeatureBuilderAssembler {
  const FeatureBuilderAssembler();

  FeatureAssemblyResult assemble({
    required FeatureBuilderInputBundle inputs,
    DateTime? now,
  }) {
    final nowLocal = now ?? DateTime.now();
    final featuresByEntityId = <String, BehaviorFeatureObject>{};
    final issues = <FeatureAssemblyIssue>[];
    final keys7d = _tailDateKeys(inputs.window.dateKeys, count: 7);
    final keys30d = _tailDateKeys(inputs.window.dateKeys, count: 30);

    for (final entry in inputs.taskSeedsById.entries) {
      final entityId = entry.key.trim();
      if (entityId.isEmpty) {
        issues.add(
          const FeatureAssemblyIssue(
            entityId: '',
            reason: 'task_entity_id_missing',
          ),
        );
        continue;
      }
      final seed = entry.value;
      final history = inputs.eventHistoryByEntityId[entityId];
      final feature = _assembleTaskLikeEntity(
        seed: seed,
        history: history,
        nowLocal: nowLocal,
        keys7d: keys7d,
        keys30d: keys30d,
        windowDateKeys: inputs.window.dateKeys.toSet(),
        windowStartDateKey: inputs.window.startDateKey,
        windowEndDateKey: inputs.window.endDateKey,
      );
      featuresByEntityId[entityId] = feature;
    }

    for (final entry in inputs.goalSeedsById.entries) {
      final entityId = entry.key.trim();
      if (entityId.isEmpty) {
        issues.add(
          const FeatureAssemblyIssue(
            entityId: '',
            reason: 'goal_entity_id_missing',
          ),
        );
        continue;
      }
      final seed = entry.value;
      final history = inputs.eventHistoryByEntityId[entityId];
      final feature = _assembleGoalLikeEntity(
        seed: seed,
        history: history,
        nowLocal: nowLocal,
        keys7d: keys7d,
        keys30d: keys30d,
        windowStartDateKey: inputs.window.startDateKey,
        windowEndDateKey: inputs.window.endDateKey,
      );
      featuresByEntityId[entityId] = feature;
    }

    return FeatureAssemblyResult(
      featuresByEntityId: featuresByEntityId,
      issues: issues,
    );
  }

  BehaviorFeatureObject _assembleTaskLikeEntity({
    required TaskFeatureSeed seed,
    required FeatureEventHistory? history,
    required DateTime nowLocal,
    required Set<String> keys7d,
    required Set<String> keys30d,
    required Set<String> windowDateKeys,
    required String windowStartDateKey,
    required String windowEndDateKey,
  }) {
    final allEvents = history?.events ?? const <AnalyticsEvent>[];
    final completionEvents = allEvents
        .where(
          (e) =>
              e.type == AnalyticsEventType.taskCompleted ||
              e.type == AnalyticsEventType.habitCompleted,
        )
        .toList();
    final completionDateKeys = completionEvents
        .map((e) => e.dateKey.trim())
        .where((k) => k.isNotEmpty)
        .toSet();

    final scheduledAll = seed.scheduledDateKeysInWindow.isNotEmpty
        ? seed.scheduledDateKeysInWindow
        : (seed.scheduledDateKey.trim().isNotEmpty
              ? {seed.scheduledDateKey}
              : <String>{});

    final timingSamples = <CompletionTimingSample>[];
    for (final event in completionEvents) {
      final dk = event.dateKey.trim();
      if (dk.isEmpty) continue;
      final completed = DateTime.tryParse(event.timestampLocalIso)?.toLocal();
      if (completed == null) continue;
      final scheduled = _scheduledInstantForTaskRow(seed.row, dk);
      timingSamples.add(
        CompletionTimingSample(
          completionDateKey: dk,
          scheduledAtLocal: scheduled,
          completedAtLocal: completed,
        ),
      );
    }

    final deferCount = allEvents
        .where(
          (e) =>
              e.type == AnalyticsEventType.taskDeferred &&
              windowDateKeys.contains(e.dateKey.trim()),
        )
        .length;

    final sessions = completionEvents
        .map(
          (_) => SessionEffortSample(
            plannedMinutes: seed.row.task.durationMinutes,
            actualMinutes: seed.row.task.durationMinutes,
          ),
        )
        .toList();

    final todayKey = DateKeys.yyyymmdd(
      DateTime(nowLocal.year, nowLocal.month, nowLocal.day),
    );
    final hasScheduledToday = scheduledAll.contains(todayKey);
    final completedToday = completionDateKeys.contains(todayKey);
    final rowForToday = seed.rowPlannedForToday;
    final scheduledInstantToday = hasScheduledToday
        ? _scheduledInstantForTaskRow(rowForToday ?? seed.row, todayKey)
        : null;

    final timeMetrics = computeBehaviorTimeMetrics(
      keys7d: keys7d,
      keys30d: keys30d,
      scheduledDateKeysInFullWindow: scheduledAll,
      completionDateKeys: completionDateKeys,
      timingSamples: timingSamples,
      hasScheduledOccurrenceToday: hasScheduledToday,
      scheduledInstantToday: scheduledInstantToday,
      completedToday: completedToday,
      nowLocal: nowLocal,
    );

    final isHabit = seed.entityKind == BehaviorEntityKind.habit.name;
    final context = computeFeatureContext(
      completionEvents: completionEvents,
      isHabitAnchor: isHabit,
      priority: seed.row.task.priority,
    );
    final feature = BehaviorFeatureObject(
      entityId: seed.row.task.id,
      entityKind: behaviorEntityKindFromStorage(seed.entityKind),
      timeMetrics: timeMetrics,
      streakMetrics: computeFeatureStreakMetrics(
        completionDateKeys: completionDateKeys,
        nowLocal: nowLocal,
      ),
      effortMetrics: computeFeatureEffortMetrics(
        sessions: sessions,
        deferredEventCount: deferCount,
      ),
      goalMetrics: BehaviorGoalMetrics.empty,
      contextFeatures: context,
      computedAtMs: nowLocal.millisecondsSinceEpoch,
      windowStartDateKey: windowStartDateKey,
      windowEndDateKey: windowEndDateKey,
      schemaVersion: kBehaviorFeatureSchemaVersion,
    );
    feature.validate();
    return feature;
  }

  BehaviorFeatureObject _assembleGoalLikeEntity({
    required GoalFeatureSeed seed,
    required FeatureEventHistory? history,
    required DateTime nowLocal,
    required Set<String> keys7d,
    required Set<String> keys30d,
    required String windowStartDateKey,
    required String windowEndDateKey,
  }) {
    final completionDateKeys = seed.checkIns
        .where((c) => c.metCommitment)
        .map((c) => c.dateKey.trim())
        .where((k) => k.isNotEmpty)
        .toSet();
    final opportunities7d = _goalOpportunitiesForDays(seed.goal.horizon, 7);
    final opportunities30d = _goalOpportunitiesForDays(seed.goal.horizon, 30);

    final progressFromCheckIns = computeCompletionRate(
      completedCount: completionDateKeys.where(keys30d.contains).length,
      opportunityCount: opportunities30d,
    );
    final milestoneProgress = seed.totalMilestones == 0
        ? 0.0
        : (seed.completedMilestones / seed.totalMilestones).clamp(0.0, 1.0);
    final progress = seed.totalMilestones == 0
        ? progressFromCheckIns
        : ((progressFromCheckIns + milestoneProgress) / 2).clamp(0.0, 1.0);
    final expectedProgress = _goalExpectedProgress(seed, nowLocal: nowLocal);

    final completionEvents =
        (history?.completionEvents ?? const <AnalyticsEvent>[])
            .where((e) => e.dateKey.trim().isNotEmpty)
            .toList();

    final feature = BehaviorFeatureObject(
      entityId: seed.goal.id,
      entityKind: behaviorEntityKindFromStorage(seed.entityKind),
      timeMetrics: computeGoalBehaviorTimeMetrics(
        keys7d: keys7d,
        keys30d: keys30d,
        completionDateKeys: completionDateKeys,
        scheduledOpportunities7d: opportunities7d,
        scheduledOpportunities30d: opportunities30d,
      ),
      streakMetrics: computeFeatureStreakMetrics(
        completionDateKeys: completionDateKeys,
        nowLocal: nowLocal,
      ),
      effortMetrics: BehaviorEffortMetrics.empty,
      goalMetrics: computeFeatureGoalMetrics(
        progress: progress,
        expectedProgress: expectedProgress,
      ),
      contextFeatures: computeFeatureContext(
        completionEvents: completionEvents,
        isHabitAnchor: seed.entityKind == BehaviorEntityKind.habit.name,
        priority: seed.goal.intensity,
      ),
      computedAtMs: nowLocal.millisecondsSinceEpoch,
      windowStartDateKey: windowStartDateKey,
      windowEndDateKey: windowEndDateKey,
      schemaVersion: kBehaviorFeatureSchemaVersion,
    );
    feature.validate();
    return feature;
  }
}

Set<String> _tailDateKeys(List<String> orderedKeys, {required int count}) {
  if (orderedKeys.isEmpty) return const <String>{};
  if (count <= 0) return const <String>{};
  if (orderedKeys.length <= count) return orderedKeys.toSet();
  return orderedKeys.sublist(orderedKeys.length - count).toSet();
}

DateTime _scheduledInstantForTaskRow(PlannedTaskRow row, String dateKey) {
  final reminderIso = row.task.reminderTimeIso;
  final reminder = DateTime.tryParse(reminderIso ?? '')?.toLocal();
  final key = dateKey.trim().isEmpty ? row.dateKey : dateKey;
  final date = DateKeys.parseLocalDateKey(key);
  if (reminder != null) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      reminder.hour,
      reminder.minute,
    );
  }
  return DateTime(date.year, date.month, date.day, 9);
}

int _goalOpportunitiesForDays(GoalHorizon horizon, int days) {
  switch (horizon) {
    case GoalHorizon.daily:
      return days;
    case GoalHorizon.weekly:
      return (days / 7).ceil().clamp(1, days);
    case GoalHorizon.monthly:
      return (days / 30).ceil().clamp(1, days);
  }
}

double _goalExpectedProgress(
  GoalFeatureSeed seed, {
  required DateTime nowLocal,
}) {
  final start = DateTime.fromMillisecondsSinceEpoch(
    seed.goal.periodStartMs,
  ).toLocal();
  final end = DateTime.fromMillisecondsSinceEpoch(
    seed.goal.periodEndMs,
  ).toLocal();
  final total = end.difference(start).inDays + 1;
  if (total <= 0) return 0;
  final elapsed =
      DateTime(
        nowLocal.year,
        nowLocal.month,
        nowLocal.day,
      ).difference(DateTime(start.year, start.month, start.day)).inDays +
      1;
  return (elapsed / total).clamp(0.0, 1.0);
}
