import '../../../../core/validation/model_validators.dart';

const int kGeneratedInsightSchemaVersion = 2;
const int kGeneratedInsightSchemaVersionV1 = 1;

enum InsightLifecycleState {
  generated,
  active,
  reinforced,
  resolved,
  archived,
}

InsightLifecycleState insightLifecycleStateFromStorage(String? raw) {
  for (final value in InsightLifecycleState.values) {
    if (value.name == raw) return value;
  }
  return InsightLifecycleState.active;
}

/// Whether [state] is still relevant for display / delivery.
bool isInsightLive(InsightLifecycleState state) {
  switch (state) {
    case InsightLifecycleState.generated:
    case InsightLifecycleState.active:
    case InsightLifecycleState.reinforced:
      return true;
    case InsightLifecycleState.resolved:
    case InsightLifecycleState.archived:
      return false;
  }
}

/// 0–1 urgency: how time-sensitive the coaching recommendation is.
/// Derived from severity and lifecycle state only.
double computeInsightUrgency({
  required InsightPriority priority,
  required double confidence,
  required InsightLifecycleState state,
}) {
  double base;
  switch (priority) {
    case InsightPriority.high:
      base = 0.9;
    case InsightPriority.medium:
      base = 0.55;
    case InsightPriority.low:
      base = 0.25;
  }
  // Reinforced signals are slightly more urgent than first-seen.
  final stateFactor = state == InsightLifecycleState.reinforced ? 1.1 : 1.0;
  return (base * confidence * stateFactor).clamp(0.0, 1.0);
}

/// 0–1 coaching importance: how strategically significant this insight is
/// relative to the user's goals. Higher for risk/focus buckets.
double computeCoachingImportance({
  required InsightBucket bucket,
  required InsightPriority priority,
  required double confidence,
}) {
  double bucketWeight;
  switch (bucket) {
    case InsightBucket.risk:
      bucketWeight = 1.0;
    case InsightBucket.neutral:
      bucketWeight = 0.7;
    case InsightBucket.reinforcement:
      bucketWeight = 0.4;
  }
  double priorityFactor;
  switch (priority) {
    case InsightPriority.high:
      priorityFactor = 1.0;
    case InsightPriority.medium:
      priorityFactor = 0.7;
    case InsightPriority.low:
      priorityFactor = 0.4;
  }
  return (bucketWeight * priorityFactor * confidence).clamp(0.0, 1.0);
}

enum InsightScopeType { entity, global }

InsightScopeType insightScopeTypeFromStorage(String? raw) {
  for (final value in InsightScopeType.values) {
    if (value.name == raw) return value;
  }
  return InsightScopeType.entity;
}

enum InsightBucket { risk, neutral, reinforcement }

InsightBucket insightBucketFromStorage(String? raw) {
  for (final value in InsightBucket.values) {
    if (value.name == raw) return value;
  }
  return InsightBucket.neutral;
}

enum InsightPriority { high, medium, low }

InsightPriority insightPriorityFromStorage(String? raw) {
  for (final value in InsightPriority.values) {
    if (value.name == raw) return value;
  }
  return InsightPriority.medium;
}

enum InsightAction {
  doNow,
  reschedule,
  reduceIntensity,
  focus,
  reduceLoad,
  keepGoing,
}

InsightAction insightActionFromStorage(String? raw) {
  for (final value in InsightAction.values) {
    if (value.name == raw) return value;
  }
  return InsightAction.doNow;
}

enum InsightType {
  streakRiskWarning,
  habitTooHard,
  timingMisalignment,
  goalAtRisk,
  latePattern,
  inconsistencyNotice,
  lowEngagementNotice,
  strongStreakPraise,
  consistentBehaviorPraise,
  goalProgressSuccess,
  // Focus-oriented (Phase 3)
  highestMomentumLeverage,
  fragileStreakAlert,
  bestRecoveryOpportunity,
  // Global coaching summaries (Phase 3)
  overloadTrend,
  improvingConsistency,
  unstableRoutinePattern,
}

InsightType insightTypeFromStorage(String? raw) {
  for (final value in InsightType.values) {
    if (value.name == raw) return value;
  }
  return InsightType.latePattern;
}

const Set<InsightType> kLayer3V1InsightTypes = <InsightType>{
  InsightType.streakRiskWarning,
  InsightType.habitTooHard,
  InsightType.timingMisalignment,
  InsightType.goalAtRisk,
  InsightType.latePattern,
  InsightType.inconsistencyNotice,
  InsightType.lowEngagementNotice,
  InsightType.strongStreakPraise,
  InsightType.consistentBehaviorPraise,
  InsightType.goalProgressSuccess,
};

const Set<InsightType> kLayer3V2InsightTypes = <InsightType>{
  ...kLayer3V1InsightTypes,
  InsightType.highestMomentumLeverage,
  InsightType.fragileStreakAlert,
  InsightType.bestRecoveryOpportunity,
  InsightType.overloadTrend,
  InsightType.improvingConsistency,
  InsightType.unstableRoutinePattern,
};

class GeneratedInsight {
  const GeneratedInsight({
    required this.insightId,
    required this.scopeType,
    required this.scopeId,
    required this.insightType,
    required this.insightBucket,
    required this.priority,
    required this.messageKey,
    required this.message,
    required this.action,
    required this.linkedPatternCodes,
    required this.confidence,
    required this.detectedAtMs,
    required this.sourceWindowStartDateKey,
    required this.sourceWindowEndDateKey,
    this.lifecycleState = InsightLifecycleState.active,
    this.urgency = 0.0,
    this.coachingImportance = 0.0,
    this.supportingMetrics = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
    this.schemaVersion = kGeneratedInsightSchemaVersion,
  });

  final String insightId;
  final InsightScopeType scopeType;
  final String scopeId;
  final InsightType insightType;
  final InsightBucket insightBucket;
  final InsightPriority priority;
  final String messageKey;
  final String message;
  final InsightAction action;
  final List<String> linkedPatternCodes;
  final double confidence;
  final int detectedAtMs;
  final String sourceWindowStartDateKey;
  final String sourceWindowEndDateKey;
  /// Phase 3 lifecycle.
  final InsightLifecycleState lifecycleState;
  /// 0–1 time-sensitivity derived from priority, confidence, and lifecycle.
  final double urgency;
  /// 0–1 strategic coaching significance derived from bucket + priority + confidence.
  final double coachingImportance;
  /// Flat key→value metrics from underlying pattern evidence (for explainability).
  final Map<String, dynamic> supportingMetrics;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(insightId, 'generatedInsight.insightId');
    ModelValidators.requireNotBlank(scopeId, 'generatedInsight.scopeId');
    ModelValidators.requireNotBlank(messageKey, 'generatedInsight.messageKey');
    ModelValidators.requireNotBlank(message, 'generatedInsight.message');
    ModelValidators.requireNotBlank(
      sourceWindowStartDateKey,
      'generatedInsight.sourceWindowStartDateKey',
    );
    ModelValidators.requireNotBlank(
      sourceWindowEndDateKey,
      'generatedInsight.sourceWindowEndDateKey',
    );
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'generatedInsight.schemaVersion',
    );
  }

  Map<String, dynamic> toMap() => {
    'insightId': insightId,
    'scopeType': scopeType.name,
    'scopeId': scopeId,
    'insightType': insightType.name,
    'insightBucket': insightBucket.name,
    'priority': priority.name,
    'messageKey': messageKey,
    'message': message,
    'action': action.name,
    'linkedPatternCodes': linkedPatternCodes
        .map((code) => code.trim())
        .where((code) => code.isNotEmpty)
        .toList(growable: false),
    'confidence': confidence.clamp(0.0, 1.0),
    'detectedAtMs': detectedAtMs,
    'sourceWindowStartDateKey': sourceWindowStartDateKey,
    'sourceWindowEndDateKey': sourceWindowEndDateKey,
    'lifecycleState': lifecycleState.name,
    'urgency': urgency.clamp(0.0, 1.0),
    'coachingImportance': coachingImportance.clamp(0.0, 1.0),
    'supportingMetrics': supportingMetrics,
    'metadata': metadata,
    'schemaVersion': schemaVersion,
  };

  /// Compatibility strategy for future schema upgrades:
  /// - unknown enum values fall back to deterministic defaults
  /// - unknown linked pattern payloads become an empty list
  /// - missing confidence defaults to 0 and is clamped
  /// - schemaVersion defaults to current Layer 3 version
  static GeneratedInsight fromMap(Map<String, dynamic> map) {
    final linked = map['linkedPatternCodes'];
    final linkedPatternCodes = <String>[];
    if (linked is List) {
      for (final value in linked) {
        if (value is String) {
          final code = value.trim();
          if (code.isNotEmpty) linkedPatternCodes.add(code);
        }
      }
    }
    final supportingRaw = map['supportingMetrics'];
    final supportingMetrics = supportingRaw is Map
        ? supportingRaw.cast<String, dynamic>()
        : const <String, dynamic>{};
    return GeneratedInsight(
      insightId: map['insightId'] as String? ?? '',
      scopeType: insightScopeTypeFromStorage(map['scopeType'] as String?),
      scopeId: map['scopeId'] as String? ?? '',
      insightType: insightTypeFromStorage(map['insightType'] as String?),
      insightBucket: insightBucketFromStorage(map['insightBucket'] as String?),
      priority: insightPriorityFromStorage(map['priority'] as String?),
      messageKey: map['messageKey'] as String? ?? '',
      message: map['message'] as String? ?? '',
      action: insightActionFromStorage(map['action'] as String?),
      linkedPatternCodes: linkedPatternCodes,
      confidence: ((map['confidence'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      detectedAtMs: (map['detectedAtMs'] as num?)?.toInt() ?? 0,
      sourceWindowStartDateKey:
          map['sourceWindowStartDateKey'] as String? ?? '',
      sourceWindowEndDateKey: map['sourceWindowEndDateKey'] as String? ?? '',
      lifecycleState: insightLifecycleStateFromStorage(
        map['lifecycleState'] as String?,
      ),
      urgency: ((map['urgency'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      coachingImportance:
          ((map['coachingImportance'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      supportingMetrics: supportingMetrics,
      metadata:
          (map['metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kGeneratedInsightSchemaVersion,
    );
  }
}
