import '../domain/models/behavior_feature_object.dart';
import '../domain/models/detected_pattern.dart';
import '../domain/models/generated_insight.dart';
import 'insight_generation_policy.dart';

// Phase 2.2: Layer 3 still consumes legacy [DetectedPattern]; canonical rows arrive via
// [detectedPatternFromCanonical] metadata. Future work: map from [DetectedBehaviorPattern]
// directly and retire [kDeferredLayer2PatternCodesForInsightMapping] gating per product.

class InsightMappingContext {
  const InsightMappingContext({
    required this.scopeType,
    required this.scopeId,
    required this.sourceWindowStartDateKey,
    required this.sourceWindowEndDateKey,
    this.detectedAtMs,
  });

  final InsightScopeType scopeType;
  final String scopeId;
  final String sourceWindowStartDateKey;
  final String sourceWindowEndDateKey;
  final int? detectedAtMs;
}

List<GeneratedInsight> mapPatternsToInsights({
  required List<DetectedPattern> patterns,
  required InsightMappingContext context,
  Layer3InsightPolicyConfig config = kLayer3InsightPolicyConfig,
}) {
  final filtered = patterns
      .where(
        (p) => !kDeferredLayer2PatternCodesForInsightMapping.contains(
          p.patternCode,
        ),
      )
      .toList();
  if (filtered.isEmpty) return const <GeneratedInsight>[];
  final trimmedScopeId = context.scopeId.trim();
  if (trimmedScopeId.isEmpty) return const <GeneratedInsight>[];

  final byCode = <PatternCode, DetectedPattern>{};
  BehaviorEntityKind? entityKindForScope;
  for (final pattern in filtered) {
    if (pattern.entityId.trim() == trimmedScopeId) {
      entityKindForScope = pattern.entityKind;
    }
    final existing = byCode[pattern.patternCode];
    if (existing == null ||
        pattern.severity > existing.severity ||
        (pattern.severity == existing.severity &&
            pattern.confidence > existing.confidence)) {
      byCode[pattern.patternCode] = pattern;
    }
  }
  entityKindForScope ??= patterns.isNotEmpty ? patterns.first.entityKind : null;

  final presentCodes = byCode.keys.toSet();
  final detectedAtMs =
      context.detectedAtMs ?? DateTime.now().millisecondsSinceEpoch;
  final out = <GeneratedInsight>[];

  for (final rule in config.rules) {
    if (rule.scopeType != context.scopeType) continue;
    if (!_matchesRule(rule, presentCodes)) continue;
    final linkedCodes = _linkedCodesForRule(rule, presentCodes);
    if (linkedCodes.isEmpty) continue;
    final confidence = _averageConfidence(linkedCodes, byCode);

    final urgency = computeInsightUrgency(
      priority: rule.priority,
      confidence: confidence,
      state: InsightLifecycleState.active,
    );
    final coachingImportance = computeCoachingImportance(
      bucket: rule.insightBucket,
      priority: rule.priority,
      confidence: confidence,
    );
    final supportingMetrics = _buildSupportingMetrics(linkedCodes, byCode);

    out.add(
      GeneratedInsight(
        insightId: _insightId(
          scopeType: context.scopeType,
          scopeId: trimmedScopeId,
          insightType: rule.insightType,
          endDateKey: context.sourceWindowEndDateKey,
        ),
        scopeType: context.scopeType,
        scopeId: trimmedScopeId,
        insightType: rule.insightType,
        insightBucket: rule.insightBucket,
        priority: rule.priority,
        messageKey: rule.messageKey,
        message: rule.fallbackMessage,
        action: rule.action,
        linkedPatternCodes: linkedCodes
            .map((code) => code.name)
            .toList(growable: false),
        confidence: confidence,
        detectedAtMs: detectedAtMs,
        sourceWindowStartDateKey: context.sourceWindowStartDateKey,
        sourceWindowEndDateKey: context.sourceWindowEndDateKey,
        lifecycleState: InsightLifecycleState.active,
        urgency: urgency,
        coachingImportance: coachingImportance,
        supportingMetrics: supportingMetrics,
        metadata: <String, dynamic>{
          'ruleId': rule.ruleId,
          'linkedPatternCodes': linkedCodes
              .map((code) => code.name)
              .toList(growable: false),
          if (entityKindForScope != null) 'entityKind': entityKindForScope.name,
        },
      ),
    );
  }

  out.sort(compareInsightOrdering);
  return out;
}

bool _matchesRule(InsightMappingRule rule, Set<PatternCode> presentCodes) {
  if (!presentCodes.containsAll(rule.requiredAllPatterns)) {
    return false;
  }
  if (rule.requiredAnyPatterns.isNotEmpty &&
      rule.requiredAnyPatterns.intersection(presentCodes).isEmpty) {
    return false;
  }
  if (rule.blockedPatterns.intersection(presentCodes).isNotEmpty) {
    return false;
  }
  return true;
}

Set<PatternCode> _linkedCodesForRule(
  InsightMappingRule rule,
  Set<PatternCode> presentCodes,
) {
  final linked = <PatternCode>{...rule.requiredAllPatterns};
  if (rule.requiredAnyPatterns.isNotEmpty) {
    linked.addAll(rule.requiredAnyPatterns.intersection(presentCodes));
  }
  return linked;
}

double _averageConfidence(
  Set<PatternCode> linkedCodes,
  Map<PatternCode, DetectedPattern> byCode,
) {
  if (linkedCodes.isEmpty) return 0.0;
  var total = 0.0;
  var count = 0;
  for (final code in linkedCodes) {
    final pattern = byCode[code];
    if (pattern == null) continue;
    total += pattern.confidence;
    count += 1;
  }
  if (count == 0) return 0.0;
  return (total / count).clamp(0.0, 1.0);
}

String _insightId({
  required InsightScopeType scopeType,
  required String scopeId,
  required InsightType insightType,
  required String endDateKey,
}) {
  return '${scopeType.name}::$scopeId::${insightType.name}::$endDateKey';
}

Map<String, dynamic> _buildSupportingMetrics(
  Set<PatternCode> linkedCodes,
  Map<PatternCode, DetectedPattern> byCode,
) {
  final metrics = <String, dynamic>{};
  for (final code in linkedCodes) {
    final pattern = byCode[code];
    if (pattern == null) continue;
    final prefix = code.name;
    metrics['$prefix.severity'] = pattern.severity;
    metrics['$prefix.confidence'] = pattern.confidence;
    // Embed any canonical evidence persisted in metadata (from Phase 2.2 compat layer).
    final evidence = pattern.metadata['evidence'];
    if (evidence is List) {
      metrics['$prefix.evidence'] = evidence;
    }
  }
  return metrics;
}
