import '../../goals/data/goals_repository.dart';
import '../domain/models/behavior_feature_object.dart';
import '../domain/models/generated_insight.dart';

/// Adds [GeneratedInsight.metadata]['displayTitle'] for entity-scoped rows when
/// the backing goal exists (tasks/habits: optional later via planning lookup).
Future<List<GeneratedInsight>> enrichInsightsWithDisplayTitles({
  required List<GeneratedInsight> insights,
  required GoalsRepository goalsRepository,
}) async {
  final out = <GeneratedInsight>[];
  for (final insight in insights) {
    if (insight.scopeType != InsightScopeType.entity) {
      out.add(insight);
      continue;
    }
    final kindName = insight.metadata['entityKind'] as String?;
    if (kindName != BehaviorEntityKind.goal.name) {
      out.add(insight);
      continue;
    }
    final goal = await goalsRepository.getGoal(insight.scopeId.trim());
    final title = goal?.title.trim();
    if (title == null || title.isEmpty) {
      out.add(insight);
      continue;
    }
    out.add(
      GeneratedInsight(
        insightId: insight.insightId,
        scopeType: insight.scopeType,
        scopeId: insight.scopeId,
        insightType: insight.insightType,
        insightBucket: insight.insightBucket,
        priority: insight.priority,
        messageKey: insight.messageKey,
        message: insight.message,
        action: insight.action,
        linkedPatternCodes: insight.linkedPatternCodes,
        confidence: insight.confidence,
        detectedAtMs: insight.detectedAtMs,
        sourceWindowStartDateKey: insight.sourceWindowStartDateKey,
        sourceWindowEndDateKey: insight.sourceWindowEndDateKey,
        metadata: <String, dynamic>{
          ...insight.metadata,
          'displayTitle': title,
        },
        schemaVersion: insight.schemaVersion,
      ),
    );
  }
  return out;
}
