import 'package:flutter/foundation.dart';

import '../../../core/utils/date_keys.dart';
import '../../analytics/application/insight_generation_orchestrator.dart';
import '../../analytics/data/insight_cache_repository.dart';
import '../../analytics/domain/models/behavior_feature_object.dart';
import '../../analytics/domain/models/detected_pattern.dart';
import '../../analytics/domain/models/generated_insight.dart';
import '../../intentions/data/intentions_repository.dart';
import '../data/people_repository.dart';
import '../domain/models/person.dart';

/// Deterministic Layer-2 addition (PRD §5.5): "no interaction with a
/// `family`/`partner` person in N weeks" → insight candidate → the normal
/// Layer-3/4 delivery machinery. This is how *"you haven't talked to your
/// sister in a while"* happens — computed truth, warm phrasing, zero
/// invention.
///
/// Two deterministic jobs, both Isar-only (airplane-mode safe):
///  1. Derive [Person.lastInteractionAtMs] from recently COMPLETED
///     intentions whose title references the person ("Call cousin Sara"
///     done → Sara interacted). Monotonic — never LLM-estimated.
///  2. For cared-about people with a known interaction baseline, emit a
///     [PatternCode.relationshipGap] pattern once the gap crosses
///     [gapThresholdDays], map it through the standard insight policy,
///     personalize the copy, and cache it under the person's entity scope
///     (the delivery-day loader merges entity insights whose source window
///     covers today). People without a recorded interaction produce
///     NOTHING — no baseline, no claim.
class RelationshipCareService {
  RelationshipCareService({
    required PeopleRepository people,
    required IntentionsRepository intentions,
    required InsightGenerationOrchestrator orchestrator,
    required InsightCacheRepository insightCache,
    this.gapThresholdDays = 21,
    this.interactionLookbackDays = 60,
  }) : _people = people,
       _intentions = intentions,
       _orchestrator = orchestrator,
       _insightCache = insightCache;

  final PeopleRepository _people;
  final IntentionsRepository _intentions;
  final InsightGenerationOrchestrator _orchestrator;
  final InsightCacheRepository _insightCache;

  /// N weeks = 3 by default — long enough that the nudge feels caring, not
  /// naggy.
  final int gapThresholdDays;

  /// How far back completed intentions count as interaction evidence.
  final int interactionLookbackDays;

  static const Duration _kRecomputeThrottle = Duration(hours: 6);
  int _lastRunMs = 0;

  /// Recompute-graph entry point — throttled internally so frequent
  /// flushes stay cheap (same contract as the intention nudge rearm).
  Future<void> rearmIfStale({DateTime? now}) async {
    final at = now ?? DateTime.now();
    if (at.millisecondsSinceEpoch - _lastRunMs <
        _kRecomputeThrottle.inMilliseconds) {
      return;
    }
    _lastRunMs = at.millisecondsSinceEpoch;
    await recompute(now: at);
  }

  Future<void> recompute({DateTime? now}) async {
    final at = now ?? DateTime.now();
    try {
      final cared = (await _people.fetchPeopleOnce())
          .where(isCaredAboutKind)
          .toList(growable: false);
      if (cared.isEmpty) return;

      await _deriveInteractionsFromIntentions(cared, at);

      // Re-read so freshly derived bumps count in the gap math.
      final refreshed = (await _people.fetchPeopleOnce())
          .where(isCaredAboutKind)
          .toList(growable: false);

      for (final person in refreshed) {
        final pattern = buildGapPattern(
          person,
          now: at,
          gapThresholdDays: gapThresholdDays,
        );
        if (pattern == null) {
          // No gap (or no baseline): clear any stale care insight so a
          // completed call retires the nudge on the next recompute.
          await _insightCache.replaceScopeInsights(
            scopeType: InsightScopeType.entity,
            scopeId: person.id,
            insights: const [],
          );
          continue;
        }
        final out = _orchestrator.runForEntity(
          entityId: person.id,
          patterns: [pattern],
          now: at,
        );
        if (out.hasFatalError) continue;
        final gapDays = (pattern.metadata['gapDays'] as num?)?.toInt() ?? 0;
        final personalized = out.insights
            .map((insight) => personalizeInsight(insight, person, gapDays))
            .toList(growable: false);
        await _insightCache.replaceScopeInsights(
          scopeType: InsightScopeType.entity,
          scopeId: person.id,
          insights: personalized,
        );
      }
    } catch (e) {
      debugPrint('[RelationshipCareService] recompute failed: $e');
    }
  }

  /// Deterministic interaction derivation: a COMPLETED intention whose
  /// title references the person is an interaction at its completion time.
  Future<void> _deriveInteractionsFromIntentions(
    List<Person> cared,
    DateTime now,
  ) async {
    final cutoffMs = now
        .subtract(Duration(days: interactionLookbackDays))
        .millisecondsSinceEpoch;
    final all = await _intentions.fetchIntentionsOnce();
    for (final intention in all) {
      final doneAt = intention.completedAtMs;
      if (doneAt == null || doneAt < cutoffMs) continue;
      for (final person in cared) {
        if (person.matchesReference(intention.title)) {
          // Monotonic inside the repository — an older completion never
          // regresses a newer interaction.
          await _people.recordInteraction(person.id, doneAt);
        }
      }
    }
  }

  // ─── Pure logic (unit-tested) ───────────────────────────────────────────────

  /// Relationship kinds the care pattern watches.
  @visibleForTesting
  static bool isCaredAboutKind(Person person) =>
      person.kind == PersonKind.family || person.kind == PersonKind.partner;

  /// Emits the gap pattern, or null when there is no baseline
  /// (lastInteractionAtMs unknown — we never invent a claim) or the gap is
  /// under the threshold.
  @visibleForTesting
  static DetectedPattern? buildGapPattern(
    Person person, {
    required DateTime now,
    int gapThresholdDays = 21,
  }) {
    final lastMs = person.lastInteractionAtMs;
    if (lastMs == null) return null;
    final gapDays = now
        .difference(DateTime.fromMillisecondsSinceEpoch(lastMs))
        .inDays;
    if (gapDays < gapThresholdDays) return null;

    // Severity grows linearly past the threshold: 0.4 at N days, +0.01/day,
    // capped at 1.0. Deterministic — confidence is always 1.0 because the
    // gap is measured, not guessed.
    final severity = (0.4 + (gapDays - gapThresholdDays) * 0.01).clamp(
      0.0,
      1.0,
    );

    return DetectedPattern(
      entityId: person.id,
      entityKind: BehaviorEntityKind.person,
      patternCode: PatternCode.relationshipGap,
      patternGroup: PatternGroup.relationshipCare,
      severity: severity,
      confidence: 1.0,
      detectedAtMs: now.millisecondsSinceEpoch,
      sourceWindowStartDateKey: DateKeys.todayKey(
        DateTime.fromMillisecondsSinceEpoch(lastMs),
      ),
      sourceWindowEndDateKey: DateKeys.todayKey(now),
      metadata: {'gapDays': gapDays, 'personId': person.id},
    );
  }

  /// Warm, specific copy: "It's been 4 weeks since you last connected with
  /// Sarah (your sister). A quick call goes a long way."
  @visibleForTesting
  static String buildCareMessage(Person person, int gapDays) {
    final weeks = gapDays ~/ 7;
    final when = weeks >= 2 ? '$weeks weeks' : '$gapDays days';
    final rel = person.relationship?.trim();
    final who = (rel == null || rel.isEmpty)
        ? person.displayName
        : '${person.displayName} ($rel)';
    return "It's been $when since you last connected with $who. "
        'A quick call goes a long way.';
  }

  @visibleForTesting
  static GeneratedInsight personalizeInsight(
    GeneratedInsight insight,
    Person person,
    int gapDays,
  ) {
    if (insight.insightType != InsightType.relationshipCareNudge) {
      return insight;
    }
    return GeneratedInsight(
      insightId: insight.insightId,
      scopeType: insight.scopeType,
      scopeId: insight.scopeId,
      insightType: insight.insightType,
      insightBucket: insight.insightBucket,
      priority: insight.priority,
      messageKey: insight.messageKey,
      message: buildCareMessage(person, gapDays),
      action: insight.action,
      linkedPatternCodes: insight.linkedPatternCodes,
      confidence: insight.confidence,
      detectedAtMs: insight.detectedAtMs,
      sourceWindowStartDateKey: insight.sourceWindowStartDateKey,
      sourceWindowEndDateKey: insight.sourceWindowEndDateKey,
      lifecycleState: insight.lifecycleState,
      urgency: insight.urgency,
      coachingImportance: insight.coachingImportance,
      supportingMetrics: insight.supportingMetrics,
      metadata: <String, dynamic>{
        ...insight.metadata,
        'personId': person.id,
        'personDisplayName': person.displayName,
        'gapDays': gapDays,
      },
      schemaVersion: insight.schemaVersion,
    );
  }
}
