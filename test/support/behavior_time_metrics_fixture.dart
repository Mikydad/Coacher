import 'package:sidepal/features/analytics/domain/models/behavior_feature_object.dart';

/// Compact factory for tests after Layer 1 metric split (schema v2).
BehaviorTimeMetrics testBehaviorTimeMetrics({
  int scheduledOccurrences7d = 7,
  int scheduledOccurrences30d = 30,
  int missedScheduledCount7d = 0,
  int missedScheduledCount30d = 0,
  double completionRate7d = 0.5,
  double completionRate30d = 0.5,
  double flexCompletionFrequency7d = 0,
  double flexCompletionFrequency30d = 0,
  double lateCompletionRate7d = 0,
  double lateCompletionRate30d = 0,
  int avgCompletionDelayMinutes = 0,
  bool isCurrentlyOverdue = false,
  int minutesOverdue = 0,
}) {
  return BehaviorTimeMetrics(
    scheduledOccurrences7d: scheduledOccurrences7d,
    scheduledOccurrences30d: scheduledOccurrences30d,
    missedScheduledCount7d: missedScheduledCount7d,
    missedScheduledCount30d: missedScheduledCount30d,
    completionRate7d: completionRate7d,
    completionRate30d: completionRate30d,
    flexCompletionFrequency7d: flexCompletionFrequency7d,
    flexCompletionFrequency30d: flexCompletionFrequency30d,
    lateCompletionRate7d: lateCompletionRate7d,
    lateCompletionRate30d: lateCompletionRate30d,
    avgCompletionDelayMinutes: avgCompletionDelayMinutes,
    isCurrentlyOverdue: isCurrentlyOverdue,
    minutesOverdue: minutesOverdue,
  );
}
