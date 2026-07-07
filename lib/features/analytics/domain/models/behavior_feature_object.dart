import '../../../../core/validation/model_validators.dart';

/// Bump when [BehaviorTimeMetrics] semantics or shape change (invalidates cached features).
const int kBehaviorFeatureSchemaVersion = 2;

enum BehaviorEntityKind { task, habit, goal }

BehaviorEntityKind behaviorEntityKindFromStorage(String? raw) {
  for (final value in BehaviorEntityKind.values) {
    if (value.name == raw) return value;
  }
  return BehaviorEntityKind.task;
}

/// Layer 1 time / adherence / punctuality metrics — single unambiguous meaning each.
///
/// **Adherence (scheduled entities)** — `scheduledOccurrences*d` > 0:
/// - [completionRate7d] = completedOnScheduledDays / scheduledOccurrences7d (same for 30d).
/// - [missedScheduledCount7d] = scheduled days in 7d tail without a completion on that day.
///
/// **Flex density (no scheduled plan days in window)** — scheduled count is 0:
/// - [completionRate7d] is 0 (adherence undefined).
/// - [flexCompletionFrequency7d] = distinct completion days in 7d / 7 (NOT adherence).
///
/// **Late completion (timing drift)** — among completions with valid schedule timestamps:
/// - [lateCompletionRate7d] = fraction completed after scheduled instant (7d tail).
/// - [avgCompletionDelayMinutes] = mean minutes after schedule among **late** completions in 7d.
///
/// **Current overdue** — snapshot at [BehaviorFeatureObject.computedAtMs] / assembler `now`:
/// - [isCurrentlyOverdue] / [minutesOverdue] only for task/habit scheduled **today** and not completed today.
class BehaviorTimeMetrics {
  const BehaviorTimeMetrics({
    required this.scheduledOccurrences7d,
    required this.scheduledOccurrences30d,
    required this.missedScheduledCount7d,
    required this.missedScheduledCount30d,
    required this.completionRate7d,
    required this.completionRate30d,
    required this.flexCompletionFrequency7d,
    required this.flexCompletionFrequency30d,
    required this.lateCompletionRate7d,
    required this.lateCompletionRate30d,
    required this.avgCompletionDelayMinutes,
    required this.isCurrentlyOverdue,
    required this.minutesOverdue,
  });

  static const empty = BehaviorTimeMetrics(
    scheduledOccurrences7d: 0,
    scheduledOccurrences30d: 0,
    missedScheduledCount7d: 0,
    missedScheduledCount30d: 0,
    completionRate7d: 0,
    completionRate30d: 0,
    flexCompletionFrequency7d: 0,
    flexCompletionFrequency30d: 0,
    lateCompletionRate7d: 0,
    lateCompletionRate30d: 0,
    avgCompletionDelayMinutes: 0,
    isCurrentlyOverdue: false,
    minutesOverdue: 0,
  );

  /// Count of planned / required occurrences intersecting the trailing 7d key set.
  final int scheduledOccurrences7d;

  /// Count intersecting the trailing 30d key set.
  final int scheduledOccurrences30d;

  /// Scheduled days in 7d tail with no completion on that calendar day.
  final int missedScheduledCount7d;

  final int missedScheduledCount30d;

  /// Adherence: completed scheduled days / scheduled days (0 if no scheduled days in window).
  final double completionRate7d;
  final double completionRate30d;

  /// Flex: distinct completion days / window length (7 or 30). Not adherence.
  final double flexCompletionFrequency7d;
  final double flexCompletionFrequency30d;

  /// Share of completions (with timing) that finished after scheduled instant.
  final double lateCompletionRate7d;
  final double lateCompletionRate30d;

  /// Average delay in minutes among late completions in 7d tail (0 if none).
  final int avgCompletionDelayMinutes;

  final bool isCurrentlyOverdue;
  final int minutesOverdue;

  Map<String, dynamic> toMap() => {
    'scheduledOccurrences7d': scheduledOccurrences7d < 0
        ? 0
        : scheduledOccurrences7d,
    'scheduledOccurrences30d': scheduledOccurrences30d < 0
        ? 0
        : scheduledOccurrences30d,
    'missedScheduledCount7d': missedScheduledCount7d < 0
        ? 0
        : missedScheduledCount7d,
    'missedScheduledCount30d': missedScheduledCount30d < 0
        ? 0
        : missedScheduledCount30d,
    'completionRate7d': completionRate7d.clamp(0.0, 1.0),
    'completionRate30d': completionRate30d.clamp(0.0, 1.0),
    'flexCompletionFrequency7d': flexCompletionFrequency7d.clamp(0.0, 1.0),
    'flexCompletionFrequency30d': flexCompletionFrequency30d.clamp(0.0, 1.0),
    'lateCompletionRate7d': lateCompletionRate7d.clamp(0.0, 1.0),
    'lateCompletionRate30d': lateCompletionRate30d.clamp(0.0, 1.0),
    'avgCompletionDelayMinutes': avgCompletionDelayMinutes < 0
        ? 0
        : avgCompletionDelayMinutes,
    'isCurrentlyOverdue': isCurrentlyOverdue,
    'minutesOverdue': minutesOverdue < 0 ? 0 : minutesOverdue,
  };

  static BehaviorTimeMetrics fromMap(Map<String, dynamic>? map) {
    final source = map ?? const <String, dynamic>{};
    final legacyLate = ((source['lateRate'] as num?)?.toDouble() ?? 0).clamp(
      0.0,
      1.0,
    );
    final legacyDelay = ((source['avgDelayMinutes'] as num?)?.toInt() ?? 0)
        .clamp(0, 999999);
    final hasV2 = source.containsKey('missedScheduledCount7d');
    if (!hasV2) {
      return BehaviorTimeMetrics(
        scheduledOccurrences7d: 0,
        scheduledOccurrences30d: 0,
        missedScheduledCount7d: 0,
        missedScheduledCount30d: 0,
        completionRate7d:
            ((source['completionRate7d'] as num?)?.toDouble() ?? 0).clamp(
              0.0,
              1.0,
            ),
        completionRate30d:
            ((source['completionRate30d'] as num?)?.toDouble() ?? 0).clamp(
              0.0,
              1.0,
            ),
        flexCompletionFrequency7d: 0,
        flexCompletionFrequency30d: 0,
        lateCompletionRate7d: legacyLate,
        lateCompletionRate30d: legacyLate,
        avgCompletionDelayMinutes: legacyDelay,
        isCurrentlyOverdue: false,
        minutesOverdue: 0,
      );
    }
    return BehaviorTimeMetrics(
      scheduledOccurrences7d:
          ((source['scheduledOccurrences7d'] as num?)?.toInt() ?? 0).clamp(
            0,
            999999,
          ),
      scheduledOccurrences30d:
          ((source['scheduledOccurrences30d'] as num?)?.toInt() ?? 0).clamp(
            0,
            999999,
          ),
      missedScheduledCount7d:
          ((source['missedScheduledCount7d'] as num?)?.toInt() ?? 0).clamp(
            0,
            999999,
          ),
      missedScheduledCount30d:
          ((source['missedScheduledCount30d'] as num?)?.toInt() ?? 0).clamp(
            0,
            999999,
          ),
      completionRate7d: ((source['completionRate7d'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0),
      completionRate30d:
          ((source['completionRate30d'] as num?)?.toDouble() ?? 0).clamp(
            0.0,
            1.0,
          ),
      flexCompletionFrequency7d:
          ((source['flexCompletionFrequency7d'] as num?)?.toDouble() ?? 0)
              .clamp(0.0, 1.0),
      flexCompletionFrequency30d:
          ((source['flexCompletionFrequency30d'] as num?)?.toDouble() ?? 0)
              .clamp(0.0, 1.0),
      lateCompletionRate7d:
          ((source['lateCompletionRate7d'] as num?)?.toDouble() ?? legacyLate)
              .clamp(0.0, 1.0),
      lateCompletionRate30d:
          ((source['lateCompletionRate30d'] as num?)?.toDouble() ?? legacyLate)
              .clamp(0.0, 1.0),
      avgCompletionDelayMinutes:
          ((source['avgCompletionDelayMinutes'] as num?)?.toInt() ??
                  legacyDelay)
              .clamp(0, 999999),
      isCurrentlyOverdue: source['isCurrentlyOverdue'] as bool? ?? false,
      minutesOverdue: ((source['minutesOverdue'] as num?)?.toInt() ?? 0).clamp(
        0,
        999999,
      ),
    );
  }
}

/// 0–1 signal for Layer 2: adherence when scheduled days exist, else flex week-density.
double layer1CompletionSignal7d(BehaviorTimeMetrics m) {
  if (m.scheduledOccurrences7d > 0) {
    return m.completionRate7d.clamp(0.0, 1.0);
  }
  return (m.flexCompletionFrequency7d * 7.0).clamp(0.0, 1.0);
}

double layer1CompletionSignal30d(BehaviorTimeMetrics m) {
  if (m.scheduledOccurrences30d > 0) {
    return m.completionRate30d.clamp(0.0, 1.0);
  }
  return (m.flexCompletionFrequency30d * 30.0).clamp(0.0, 1.0);
}

class BehaviorStreakMetrics {
  const BehaviorStreakMetrics({
    required this.currentStreak,
    required this.longestStreak,
    required this.missedLast2Days,
    required this.missedCount7d,
  });

  static const empty = BehaviorStreakMetrics(
    currentStreak: 0,
    longestStreak: 0,
    missedLast2Days: false,
    missedCount7d: 0,
  );

  final int currentStreak;
  final int longestStreak;
  final bool missedLast2Days;
  final int missedCount7d;

  Map<String, dynamic> toMap() => {
    'currentStreak': currentStreak < 0 ? 0 : currentStreak,
    'longestStreak': longestStreak < 0 ? 0 : longestStreak,
    'missedLast2Days': missedLast2Days,
    'missedCount7d': missedCount7d.clamp(0, 7),
  };

  static BehaviorStreakMetrics fromMap(Map<String, dynamic>? map) {
    final source = map ?? const <String, dynamic>{};
    return BehaviorStreakMetrics(
      currentStreak: ((source['currentStreak'] as num?)?.toInt() ?? 0).clamp(
        0,
        999999,
      ),
      longestStreak: ((source['longestStreak'] as num?)?.toInt() ?? 0).clamp(
        0,
        999999,
      ),
      missedLast2Days: source['missedLast2Days'] as bool? ?? false,
      missedCount7d: ((source['missedCount7d'] as num?)?.toInt() ?? 0).clamp(
        0,
        7,
      ),
    );
  }
}

class BehaviorEffortMetrics {
  const BehaviorEffortMetrics({
    required this.avgSnoozeCount,
    required this.avgSessionDuration,
    required this.plannedVsActualRatio,
  });

  static const empty = BehaviorEffortMetrics(
    avgSnoozeCount: 0,
    avgSessionDuration: 0,
    plannedVsActualRatio: 0,
  );

  final double avgSnoozeCount;
  final int avgSessionDuration;
  final double plannedVsActualRatio;

  Map<String, dynamic> toMap() => {
    'avgSnoozeCount': avgSnoozeCount < 0 ? 0 : avgSnoozeCount,
    'avgSessionDuration': avgSessionDuration < 0 ? 0 : avgSessionDuration,
    'plannedVsActualRatio': plannedVsActualRatio < 0 ? 0 : plannedVsActualRatio,
  };

  static BehaviorEffortMetrics fromMap(Map<String, dynamic>? map) {
    final source = map ?? const <String, dynamic>{};
    return BehaviorEffortMetrics(
      avgSnoozeCount: ((source['avgSnoozeCount'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 9999.0),
      avgSessionDuration: ((source['avgSessionDuration'] as num?)?.toInt() ?? 0)
          .clamp(0, 999999),
      plannedVsActualRatio:
          ((source['plannedVsActualRatio'] as num?)?.toDouble() ?? 0).clamp(
            0.0,
            9999.0,
          ),
    );
  }
}

class BehaviorGoalMetrics {
  const BehaviorGoalMetrics({
    required this.progress,
    required this.expectedProgress,
    required this.gap,
  });

  static const empty = BehaviorGoalMetrics(
    progress: 0,
    expectedProgress: 0,
    gap: 0,
  );

  final double progress;
  final double expectedProgress;
  final double gap;

  Map<String, dynamic> toMap() => {
    'progress': progress.clamp(0.0, 1.0),
    'expectedProgress': expectedProgress.clamp(0.0, 1.0),
    'gap': gap,
  };

  static BehaviorGoalMetrics fromMap(Map<String, dynamic>? map) {
    final source = map ?? const <String, dynamic>{};
    final progress = ((source['progress'] as num?)?.toDouble() ?? 0).clamp(
      0.0,
      1.0,
    );
    final expectedProgress =
        ((source['expectedProgress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
    final fallbackGap = expectedProgress - progress;
    return BehaviorGoalMetrics(
      progress: progress,
      expectedProgress: expectedProgress,
      gap: (source['gap'] as num?)?.toDouble() ?? fallbackGap,
    );
  }
}

class BehaviorContextFeatures {
  const BehaviorContextFeatures({
    required this.bestTimeBlock,
    required this.isHabitAnchor,
    required this.priority,
  });

  static const empty = BehaviorContextFeatures(
    bestTimeBlock: 'morning',
    isHabitAnchor: false,
    priority: 3,
  );

  final String bestTimeBlock;
  final bool isHabitAnchor;
  final int priority;

  Map<String, dynamic> toMap() => {
    'bestTimeBlock': _sanitizeTimeBlock(bestTimeBlock),
    'isHabitAnchor': isHabitAnchor,
    'priority': priority.clamp(1, 5),
  };

  static BehaviorContextFeatures fromMap(Map<String, dynamic>? map) {
    final source = map ?? const <String, dynamic>{};
    return BehaviorContextFeatures(
      bestTimeBlock: _sanitizeTimeBlock(source['bestTimeBlock'] as String?),
      isHabitAnchor: source['isHabitAnchor'] as bool? ?? false,
      priority: ((source['priority'] as num?)?.toInt() ?? 3).clamp(1, 5),
    );
  }
}

class BehaviorFeatureObject {
  const BehaviorFeatureObject({
    required this.entityId,
    required this.entityKind,
    required this.timeMetrics,
    required this.streakMetrics,
    required this.effortMetrics,
    required this.goalMetrics,
    required this.contextFeatures,
    required this.computedAtMs,
    this.windowStartDateKey,
    this.windowEndDateKey,
    this.schemaVersion = kBehaviorFeatureSchemaVersion,
  });

  final String entityId;
  final BehaviorEntityKind entityKind;
  final BehaviorTimeMetrics timeMetrics;
  final BehaviorStreakMetrics streakMetrics;
  final BehaviorEffortMetrics effortMetrics;
  final BehaviorGoalMetrics goalMetrics;
  final BehaviorContextFeatures contextFeatures;
  final int computedAtMs;
  final String? windowStartDateKey;
  final String? windowEndDateKey;
  final int schemaVersion;

  /// Null-safe sparse-data constructor used as migration fallback.
  factory BehaviorFeatureObject.empty({
    required String entityId,
    required BehaviorEntityKind entityKind,
    required int computedAtMs,
  }) {
    return BehaviorFeatureObject(
      entityId: entityId,
      entityKind: entityKind,
      timeMetrics: BehaviorTimeMetrics.empty,
      streakMetrics: BehaviorStreakMetrics.empty,
      effortMetrics: BehaviorEffortMetrics.empty,
      goalMetrics: BehaviorGoalMetrics.empty,
      contextFeatures: BehaviorContextFeatures.empty,
      computedAtMs: computedAtMs,
    );
  }

  /// Compatibility strategy:
  /// - missing blocks get deterministic zero/default values
  /// - unknown kind falls back to task
  /// - schemaVersion defaults to latest known version for V1
  static BehaviorFeatureObject fromMap(Map<String, dynamic> map) {
    return BehaviorFeatureObject(
      entityId: map['entityId'] as String? ?? '',
      entityKind: behaviorEntityKindFromStorage(map['entityKind'] as String?),
      timeMetrics: BehaviorTimeMetrics.fromMap(
        (map['timeMetrics'] as Map?)?.cast<String, dynamic>(),
      ),
      streakMetrics: BehaviorStreakMetrics.fromMap(
        (map['streakMetrics'] as Map?)?.cast<String, dynamic>(),
      ),
      effortMetrics: BehaviorEffortMetrics.fromMap(
        (map['effortMetrics'] as Map?)?.cast<String, dynamic>(),
      ),
      goalMetrics: BehaviorGoalMetrics.fromMap(
        (map['goalMetrics'] as Map?)?.cast<String, dynamic>(),
      ),
      contextFeatures: BehaviorContextFeatures.fromMap(
        (map['contextFeatures'] as Map?)?.cast<String, dynamic>(),
      ),
      computedAtMs: (map['computedAtMs'] as num?)?.toInt() ?? 0,
      windowStartDateKey: map['windowStartDateKey'] as String?,
      windowEndDateKey: map['windowEndDateKey'] as String?,
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kBehaviorFeatureSchemaVersion,
    );
  }

  Map<String, dynamic> toMap() => {
    'entityId': entityId,
    'entityKind': entityKind.name,
    'timeMetrics': timeMetrics.toMap(),
    'streakMetrics': streakMetrics.toMap(),
    'effortMetrics': effortMetrics.toMap(),
    'goalMetrics': goalMetrics.toMap(),
    'contextFeatures': contextFeatures.toMap(),
    'computedAtMs': computedAtMs,
    if (windowStartDateKey != null) 'windowStartDateKey': windowStartDateKey,
    if (windowEndDateKey != null) 'windowEndDateKey': windowEndDateKey,
    'schemaVersion': schemaVersion,
  };

  void validate() {
    ModelValidators.requireNotBlank(entityId, 'behaviorFeature.entityId');
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'behaviorFeature.schemaVersion',
    );
  }
}

String _sanitizeTimeBlock(String? raw) {
  switch (raw) {
    case 'morning':
    case 'afternoon':
    case 'evening':
      return raw!;
    default:
      return 'morning';
  }
}
