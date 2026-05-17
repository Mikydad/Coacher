import '../../../../core/validation/model_validators.dart';
import 'behavior_feature_object.dart';

const int kDetectedPatternSchemaVersion = 1;
const int kGlobalPatternSnapshotSchemaVersion = 1;

enum PatternGroup {
  streakConsistency,
  timeBehavior,
  effortDifficulty,
  goalAlignment,
  behavioralStability,
}

PatternGroup patternGroupFromStorage(String? raw) {
  for (final value in PatternGroup.values) {
    if (value.name == raw) return value;
  }
  return PatternGroup.streakConsistency;
}

enum PatternCode {
  streakRisk,
  strongStreak,
  inconsistentBehavior,
  lateBehavior,
  timeMisalignment,
  tooHard,
  lowEngagement,
  /// Goal entity: progress materially behind expected trajectory (Layer 1 goal metrics).
  goalProgressDrift,
  /// Task/habit: high share of missed scheduled days vs scheduled opportunities in 7d window.
  scheduleRhythmVolatile,
}

PatternCode patternCodeFromStorage(String? raw) {
  for (final value in PatternCode.values) {
    if (value.name == raw) return value;
  }
  return PatternCode.streakRisk;
}

const Set<PatternCode> kLayer2V1PatternCodes = <PatternCode>{
  PatternCode.streakRisk,
  PatternCode.strongStreak,
  PatternCode.inconsistentBehavior,
  PatternCode.lateBehavior,
  PatternCode.timeMisalignment,
  PatternCode.tooHard,
  PatternCode.lowEngagement,
  PatternCode.goalProgressDrift,
  PatternCode.scheduleRhythmVolatile,
};

const Set<PatternGroup> kLayer2V1PatternGroups = <PatternGroup>{
  PatternGroup.streakConsistency,
  PatternGroup.timeBehavior,
  PatternGroup.effortDifficulty,
  PatternGroup.goalAlignment,
  PatternGroup.behavioralStability,
};

/// Layer 2 codes that are persisted/detectable but must not drive Layer 3 copy yet.
const Set<PatternCode> kDeferredLayer2PatternCodesForInsightMapping = <PatternCode>{
  PatternCode.goalProgressDrift,
  PatternCode.scheduleRhythmVolatile,
};

class DetectedPattern {
  const DetectedPattern({
    required this.entityId,
    required this.entityKind,
    required this.patternCode,
    required this.patternGroup,
    required this.severity,
    required this.confidence,
    required this.detectedAtMs,
    required this.sourceWindowStartDateKey,
    required this.sourceWindowEndDateKey,
    this.metadata = const <String, dynamic>{},
    this.schemaVersion = kDetectedPatternSchemaVersion,
  });

  final String entityId;
  final BehaviorEntityKind entityKind;
  final PatternCode patternCode;
  final PatternGroup patternGroup;
  final double severity;
  final double confidence;
  final int detectedAtMs;
  final String sourceWindowStartDateKey;
  final String sourceWindowEndDateKey;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(entityId, 'detectedPattern.entityId');
    ModelValidators.requireNotBlank(
      sourceWindowStartDateKey,
      'detectedPattern.sourceWindowStartDateKey',
    );
    ModelValidators.requireNotBlank(
      sourceWindowEndDateKey,
      'detectedPattern.sourceWindowEndDateKey',
    );
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'detectedPattern.schemaVersion',
    );
  }

  Map<String, dynamic> toMap() => {
    'entityId': entityId,
    'entityKind': entityKind.name,
    'patternCode': patternCode.name,
    'patternGroup': patternGroup.name,
    'severity': severity.clamp(0.0, 1.0),
    'confidence': confidence.clamp(0.0, 1.0),
    'detectedAtMs': detectedAtMs,
    'sourceWindowStartDateKey': sourceWindowStartDateKey,
    'sourceWindowEndDateKey': sourceWindowEndDateKey,
    'metadata': metadata,
    'schemaVersion': schemaVersion,
  };

  /// Compatibility strategy for future schema upgrades:
  /// - unknown enum values fall back to deterministic defaults
  /// - missing scores default to 0
  /// - missing metadata defaults to empty map
  static DetectedPattern fromMap(Map<String, dynamic> map) {
    return DetectedPattern(
      entityId: map['entityId'] as String? ?? '',
      entityKind: behaviorEntityKindFromStorage(map['entityKind'] as String?),
      patternCode: patternCodeFromStorage(map['patternCode'] as String?),
      patternGroup: patternGroupFromStorage(map['patternGroup'] as String?),
      severity: ((map['severity'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      confidence: ((map['confidence'] as num?)?.toDouble() ?? 0).clamp(
        0.0,
        1.0,
      ),
      detectedAtMs: (map['detectedAtMs'] as num?)?.toInt() ?? 0,
      sourceWindowStartDateKey:
          map['sourceWindowStartDateKey'] as String? ?? '',
      sourceWindowEndDateKey: map['sourceWindowEndDateKey'] as String? ?? '',
      metadata:
          (map['metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kDetectedPatternSchemaVersion,
    );
  }
}

class GlobalPatternAggregateEntry {
  const GlobalPatternAggregateEntry({
    required this.patternCode,
    required this.patternGroup,
    required this.entityCount,
    required this.occurrenceCount,
    required this.averageSeverity,
    required this.maxSeverity,
    required this.averageConfidence,
  });

  final PatternCode patternCode;
  final PatternGroup patternGroup;
  final int entityCount;
  final int occurrenceCount;
  final double averageSeverity;
  final double maxSeverity;
  final double averageConfidence;

  Map<String, dynamic> toMap() => {
    'patternCode': patternCode.name,
    'patternGroup': patternGroup.name,
    'entityCount': entityCount < 0 ? 0 : entityCount,
    'occurrenceCount': occurrenceCount < 0 ? 0 : occurrenceCount,
    'averageSeverity': averageSeverity.clamp(0.0, 1.0),
    'maxSeverity': maxSeverity.clamp(0.0, 1.0),
    'averageConfidence': averageConfidence.clamp(0.0, 1.0),
  };

  static GlobalPatternAggregateEntry fromMap(Map<String, dynamic> map) {
    return GlobalPatternAggregateEntry(
      patternCode: patternCodeFromStorage(map['patternCode'] as String?),
      patternGroup: patternGroupFromStorage(map['patternGroup'] as String?),
      entityCount: ((map['entityCount'] as num?)?.toInt() ?? 0).clamp(
        0,
        999999,
      ),
      occurrenceCount: ((map['occurrenceCount'] as num?)?.toInt() ?? 0).clamp(
        0,
        999999,
      ),
      averageSeverity: ((map['averageSeverity'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0),
      maxSeverity: ((map['maxSeverity'] as num?)?.toDouble() ?? 0).clamp(
        0.0,
        1.0,
      ),
      averageConfidence: ((map['averageConfidence'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0),
    );
  }
}

class GlobalPatternSnapshot {
  const GlobalPatternSnapshot({
    required this.dateKey,
    required this.entries,
    required this.totalEntitiesProcessed,
    required this.totalPatternsEmitted,
    required this.weightedAverageSeverity,
    required this.detectedAtMs,
    this.schemaVersion = kGlobalPatternSnapshotSchemaVersion,
  });

  final String dateKey;
  final List<GlobalPatternAggregateEntry> entries;
  final int totalEntitiesProcessed;
  final int totalPatternsEmitted;
  final double weightedAverageSeverity;
  final int detectedAtMs;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(dateKey, 'globalPatternSnapshot.dateKey');
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'globalPatternSnapshot.schemaVersion',
    );
  }

  Map<String, dynamic> toMap() => {
    'dateKey': dateKey,
    'entries': entries.map((e) => e.toMap()).toList(),
    'totalEntitiesProcessed': totalEntitiesProcessed < 0
        ? 0
        : totalEntitiesProcessed,
    'totalPatternsEmitted': totalPatternsEmitted < 0 ? 0 : totalPatternsEmitted,
    'weightedAverageSeverity': weightedAverageSeverity.clamp(0.0, 1.0),
    'detectedAtMs': detectedAtMs,
    'schemaVersion': schemaVersion,
  };

  /// Compatibility strategy:
  /// - missing entries defaults to empty list
  /// - missing counters defaults to 0
  /// - schemaVersion defaults to current Layer 2 version
  static GlobalPatternSnapshot fromMap(Map<String, dynamic> map) {
    final rawEntries = map['entries'];
    final entries = <GlobalPatternAggregateEntry>[];
    if (rawEntries is List) {
      for (final item in rawEntries) {
        if (item is Map<String, dynamic>) {
          entries.add(GlobalPatternAggregateEntry.fromMap(item));
        } else if (item is Map) {
          entries.add(
            GlobalPatternAggregateEntry.fromMap(item.cast<String, dynamic>()),
          );
        }
      }
    }
    return GlobalPatternSnapshot(
      dateKey: map['dateKey'] as String? ?? '',
      entries: entries,
      totalEntitiesProcessed:
          ((map['totalEntitiesProcessed'] as num?)?.toInt() ?? 0).clamp(
            0,
            999999,
          ),
      totalPatternsEmitted:
          ((map['totalPatternsEmitted'] as num?)?.toInt() ?? 0).clamp(
            0,
            999999,
          ),
      weightedAverageSeverity:
          ((map['weightedAverageSeverity'] as num?)?.toDouble() ?? 0).clamp(
            0.0,
            1.0,
          ),
      detectedAtMs: (map['detectedAtMs'] as num?)?.toInt() ?? 0,
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kGlobalPatternSnapshotSchemaVersion,
    );
  }
}
