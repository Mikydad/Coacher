import '../../../../core/validation/model_validators.dart';
import 'behavior_feature_object.dart';
import 'detected_pattern.dart';
import 'pattern_taxonomy.dart';

const int kDetectedBehaviorPatternSchemaVersion = 1;
const int kGlobalBehaviorPatternSnapshotSchemaVersion = 1;

/// Single Layer 1 (or declared detection-context) metric observation used as evidence.
class PatternMetricEvidence {
  const PatternMetricEvidence({
    required this.metricPath,
    required this.valueSerialized,
  });

  /// Dotted path (e.g. `timeMetrics.completionRate7d`, `layer1.completionSignal7d`).
  final String metricPath;
  final String valueSerialized;

  Map<String, dynamic> toMap() => {
    'metricPath': metricPath,
    'valueSerialized': valueSerialized,
  };

  static PatternMetricEvidence fromMap(Map<String, dynamic> map) {
    return PatternMetricEvidence(
      metricPath: map['metricPath'] as String? ?? '',
      valueSerialized: map['valueSerialized'] as String? ?? '',
    );
  }
}

/// Layer 2 Phase 2 pattern: structured interpretation + metric evidence only.
class DetectedBehaviorPattern {
  const DetectedBehaviorPattern({
    required this.entityId,
    required this.entityKind,
    required this.patternCode,
    required this.patternGroup,
    required this.taxonomyFamily,
    required this.severity,
    required this.confidence,
    required this.detectedAtMs,
    required this.sourceWindowStartDateKey,
    required this.sourceWindowEndDateKey,
    required this.evidence,
    this.schemaVersion = kDetectedBehaviorPatternSchemaVersion,
  });

  final String entityId;
  final BehaviorEntityKind entityKind;
  final PatternCode patternCode;
  final PatternGroup patternGroup;
  final PatternTaxonomyFamily taxonomyFamily;
  final double severity;
  final double confidence;
  final int detectedAtMs;
  final String sourceWindowStartDateKey;
  final String sourceWindowEndDateKey;
  final List<PatternMetricEvidence> evidence;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(entityId, 'detectedBehaviorPattern.entityId');
    ModelValidators.requireNotBlank(
      sourceWindowStartDateKey,
      'detectedBehaviorPattern.sourceWindowStartDateKey',
    );
    ModelValidators.requireNotBlank(
      sourceWindowEndDateKey,
      'detectedBehaviorPattern.sourceWindowEndDateKey',
    );
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'detectedBehaviorPattern.schemaVersion',
    );
  }

  Map<String, dynamic> toMap() => {
    'entityId': entityId,
    'entityKind': entityKind.name,
    'patternCode': patternCode.name,
    'patternGroup': patternGroup.name,
    'taxonomyFamily': taxonomyFamily.name,
    'severity': severity.clamp(0.0, 1.0),
    'confidence': confidence.clamp(0.0, 1.0),
    'detectedAtMs': detectedAtMs,
    'sourceWindowStartDateKey': sourceWindowStartDateKey,
    'sourceWindowEndDateKey': sourceWindowEndDateKey,
    'evidence': evidence.map((e) => e.toMap()).toList(growable: false),
    'schemaVersion': schemaVersion,
  };

  static DetectedBehaviorPattern fromMap(Map<String, dynamic> map) {
    final group = patternGroupFromStorage(map['patternGroup'] as String?);
    final familyRaw = map['taxonomyFamily'] as String?;
    final taxonomyFamily = familyRaw != null
        ? patternTaxonomyFamilyFromStorage(familyRaw)
        : patternTaxonomyFamilyForGroup(group);
    final rawEvidence = map['evidence'];
    final evidence = <PatternMetricEvidence>[];
    if (rawEvidence is List) {
      for (final item in rawEvidence) {
        if (item is Map<String, dynamic>) {
          evidence.add(PatternMetricEvidence.fromMap(item));
        } else if (item is Map) {
          evidence.add(PatternMetricEvidence.fromMap(item.cast<String, dynamic>()));
        }
      }
    }
    return DetectedBehaviorPattern(
      entityId: map['entityId'] as String? ?? '',
      entityKind: behaviorEntityKindFromStorage(map['entityKind'] as String?),
      patternCode: patternCodeFromStorage(map['patternCode'] as String?),
      patternGroup: group,
      taxonomyFamily: taxonomyFamily,
      severity: ((map['severity'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      confidence: ((map['confidence'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      detectedAtMs: (map['detectedAtMs'] as num?)?.toInt() ?? 0,
      sourceWindowStartDateKey:
          map['sourceWindowStartDateKey'] as String? ?? '',
      sourceWindowEndDateKey: map['sourceWindowEndDateKey'] as String? ?? '',
      evidence: evidence,
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kDetectedBehaviorPatternSchemaVersion,
    );
  }
}

class GlobalBehaviorPatternAggregateEntry {
  const GlobalBehaviorPatternAggregateEntry({
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

  static GlobalBehaviorPatternAggregateEntry fromMap(Map<String, dynamic> map) {
    return GlobalBehaviorPatternAggregateEntry(
      patternCode: patternCodeFromStorage(map['patternCode'] as String?),
      patternGroup: patternGroupFromStorage(map['patternGroup'] as String?),
      entityCount: ((map['entityCount'] as num?)?.toInt() ?? 0).clamp(0, 999999),
      occurrenceCount:
          ((map['occurrenceCount'] as num?)?.toInt() ?? 0).clamp(0, 999999),
      averageSeverity: ((map['averageSeverity'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0),
      maxSeverity: ((map['maxSeverity'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      averageConfidence: ((map['averageConfidence'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0),
    );
  }
}

class GlobalBehaviorPatternSnapshot {
  const GlobalBehaviorPatternSnapshot({
    required this.dateKey,
    required this.entries,
    required this.totalEntitiesProcessed,
    required this.totalPatternsEmitted,
    required this.weightedAverageSeverity,
    required this.detectedAtMs,
    this.schemaVersion = kGlobalBehaviorPatternSnapshotSchemaVersion,
  });

  final String dateKey;
  final List<GlobalBehaviorPatternAggregateEntry> entries;
  final int totalEntitiesProcessed;
  final int totalPatternsEmitted;
  final double weightedAverageSeverity;
  final int detectedAtMs;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(dateKey, 'globalBehaviorPatternSnapshot.dateKey');
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'globalBehaviorPatternSnapshot.schemaVersion',
    );
  }

  Map<String, dynamic> toMap() => {
    'dateKey': dateKey,
    'entries': entries.map((e) => e.toMap()).toList(),
    'totalEntitiesProcessed': totalEntitiesProcessed < 0 ? 0 : totalEntitiesProcessed,
    'totalPatternsEmitted': totalPatternsEmitted < 0 ? 0 : totalPatternsEmitted,
    'weightedAverageSeverity': weightedAverageSeverity.clamp(0.0, 1.0),
    'detectedAtMs': detectedAtMs,
    'schemaVersion': schemaVersion,
  };

  static GlobalBehaviorPatternSnapshot fromMap(Map<String, dynamic> map) {
    final rawEntries = map['entries'];
    final entries = <GlobalBehaviorPatternAggregateEntry>[];
    if (rawEntries is List) {
      for (final item in rawEntries) {
        if (item is Map<String, dynamic>) {
          entries.add(GlobalBehaviorPatternAggregateEntry.fromMap(item));
        } else if (item is Map) {
          entries.add(
            GlobalBehaviorPatternAggregateEntry.fromMap(item.cast<String, dynamic>()),
          );
        }
      }
    }
    return GlobalBehaviorPatternSnapshot(
      dateKey: map['dateKey'] as String? ?? '',
      entries: entries,
      totalEntitiesProcessed:
          ((map['totalEntitiesProcessed'] as num?)?.toInt() ?? 0).clamp(0, 999999),
      totalPatternsEmitted:
          ((map['totalPatternsEmitted'] as num?)?.toInt() ?? 0).clamp(0, 999999),
      weightedAverageSeverity:
          ((map['weightedAverageSeverity'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      detectedAtMs: (map['detectedAtMs'] as num?)?.toInt() ?? 0,
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kGlobalBehaviorPatternSnapshotSchemaVersion,
    );
  }
}
