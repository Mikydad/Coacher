import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ai/ai_proxy_client.dart';
import '../../../core/ai/ai_remote_config_service.dart';
import '../../../core/utils/date_keys.dart';
import '../../analytics/application/insight_generation_orchestrator.dart';
import '../../analytics/data/insight_cache_repository.dart';
import '../../analytics/domain/models/behavior_feature_object.dart';
import '../../analytics/domain/models/detected_pattern.dart';
import '../../analytics/domain/models/generated_insight.dart';
import '../../intentions/application/intention_capture.dart';
import '../../intentions/data/intentions_repository.dart';
import '../../intentions/domain/models/intention.dart';
import '../../memory/data/memory_facts_repository.dart';
import '../../memory/data/people_repository.dart';
import 'reflection_parser.dart';
import 'reflection_payload.dart';

/// The Thinking Loop (humanizing Phase 7, PRD §12): every so often —
/// locally, quietly — SidePal asks itself *"given everything I know: did
/// Mike forget something? Is he avoiding something? Should an intention
/// move?"*
///
/// The deterministic layers already think; this adds ONE budgeted LLM
/// reflection pass per device-day (purpose `reflect`, system budget,
/// silent-skip, server kill switch) over the full local picture. Its
/// output is never an action — only proposals that flow through the same
/// validation machinery as everything else:
///
/// - dormant intentions → `IntentionStatus.dormant` (zero notifications
///   until engaged; the planner only reads `open`);
/// - hint updates → `aiHintsJson.preferredTimeBlock`, an ADVISORY scoring
///   input the planner already sanity-checks and weighs low;
/// - at most one observation → an `InsightType.reflectionObservation`
///   through the standard Layer-3 policy (cooldowns, caps, day-scoped
///   delivery), labeled aiInferred in metadata.
///
/// Skip semantics ("fresh inputs" — settled with Miko 2026-07-24): a pass
/// runs at most once per local day AND only when the durable inputs hash
/// changed since the last completed pass — an unchanged life must not
/// burn budget re-reflecting. Failures (offline, AI down, kill switch,
/// budget out) leave the day unmarked, so the next app open retries —
/// the extraction-service stay-pending pattern.
class ThinkingLoopService {
  ThinkingLoopService({
    required MemoryFactsRepository facts,
    required PeopleRepository people,
    required IntentionsRepository intentions,
    required InsightGenerationOrchestrator orchestrator,
    required InsightCacheRepository insightCache,
    AiProxyClient? proxy,
    AiRemoteConfigService? remoteConfig,
    DateTime Function()? now,
  }) : _facts = facts,
       _people = people,
       _intentions = intentions,
       _orchestrator = orchestrator,
       _insightCache = insightCache,
       _proxy = proxy ?? AiProxyClient(),
       _remoteConfig = remoteConfig ?? AiRemoteConfigService.instance,
       _now = now ?? DateTime.now;

  final MemoryFactsRepository _facts;
  final PeopleRepository _people;
  final IntentionsRepository _intentions;
  final InsightGenerationOrchestrator _orchestrator;
  final InsightCacheRepository _insightCache;
  final AiProxyClient _proxy;
  final AiRemoteConfigService _remoteConfig;
  final DateTime Function() _now;

  static const lastDayPrefsKey = 'thinking_loop_last_day_v1';
  static const inputsHashPrefsKey = 'thinking_loop_inputs_hash_v1';

  /// The synthetic entity scope reflection insights live under. The
  /// delivery-day loader merges ALL entity insights whose source window
  /// covers today, so no per-entity registration is needed.
  static const reflectionScopeId = 'reflection';

  /// Dormant proposals get the same wide, quiet window as extraction's
  /// observations — "on your radar", zero notifications until engaged.
  static const observationWindow = Duration(days: 60);

  /// In-flight guard (P2-11): bootstrap and resume both launch this
  /// unawaited within seconds of each other on a cold start; without the
  /// guard, two overlapping runs could each pass the day/hash checks and
  /// double-spend the system AI budget.
  Future<void>? _inFlight;

  /// Entry point — bootstrap and app resume. Cheap when not due.
  Future<void> reflectIfDue() {
    return _inFlight ??= _reflectIfDue().whenComplete(() => _inFlight = null);
  }

  Future<void> _reflectIfDue() async {
    try {
      final now = _now();
      final today = DateKeys.todayKey(now);
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(lastDayPrefsKey) == today) return;

      final facts = await _facts.fetchFactsOnce();
      final people = await _people.fetchPeopleOnce();
      final intentions = await _intentions.fetchIntentionsOnce();
      if (facts.isEmpty && people.isEmpty && intentions.isEmpty) {
        // Nothing to reflect on — but do NOT mark the day (P2-10): an
        // empty snapshot is usually a fresh install or a just-wiped
        // account switch, and onboarding/remote merge can fill Isar
        // minutes later. Leaving the day unmarked keeps the loop armed;
        // the empty re-check costs three Isar reads.
        return;
      }

      final hash = reflectionInputsHash(
        facts: facts,
        people: people,
        intentions: intentions,
      );
      if (prefs.getString(inputsHashPrefsKey) == hash) {
        // Nothing changed since the last pass — same conclusions, zero
        // spend. Mark the day; a change tomorrow re-arms the loop.
        await prefs.setString(lastDayPrefsKey, today);
        return;
      }

      if (!await _remoteConfig.isAiEnabled()) return;

      final snapshot = buildReflectionSnapshot(
        facts: facts,
        people: people,
        intentions: intentions,
        now: now,
      );

      String content;
      try {
        content = await _proxy.chat(
          messages: [
            {'role': 'system', 'content': _kReflectionSystemPrompt},
            {'role': 'user', 'content': jsonEncode(snapshot)},
          ],
          // Pinned server-side by the purpose route; advisory here.
          temperature: 0.2,
          maxTokens: 700,
          purpose: 'reflect',
          timeout: const Duration(seconds: 30),
        );
      } on AiProxyException catch (e) {
        // Offline, AI down, kill-switched, budget out — silent skip, day
        // left unmarked so the next open retries.
        debugPrint('[ThinkingLoop] reflect skipped: ${e.message}');
        return;
      }

      final live = intentions.where((i) => i.active);
      final parsed = ReflectionParser.parse(
        content,
        knownIds: reflectionKnownIds(
          facts: facts,
          people: people,
          intentions: intentions,
        ),
        openIntentionIds: {
          for (final i in live)
            if (i.isLive && !i.isPinned) i.id,
        },
        existingTitleKeys: {
          for (final i in live) ReflectionParser.titleKey(i.title),
        },
      );

      await _apply(parsed, now);
      await prefs.setString(lastDayPrefsKey, today);
      await prefs.setString(inputsHashPrefsKey, hash);
    } catch (e) {
      debugPrint('[ThinkingLoop] reflectIfDue failed: $e');
    }
  }

  Future<void> _apply(ParsedReflection parsed, DateTime now) async {
    for (final candidate in parsed.dormantIntentions) {
      final intention = buildIntention(
        IntentionDraft(
          title: candidate.title,
          rawUtterance: candidate.title,
          windowStart: now,
          windowEnd: now.add(observationWindow),
          estimatedMinutes: candidate.estimatedMinutes,
          aiHintsJson: jsonEncode({
            'source': 'reflect',
            'basedOn': candidate.basedOn,
          }),
        ),
        now: now,
      ).copyWith(status: IntentionStatus.dormant);
      await _intentions.upsertIntention(intention);
    }

    for (final hint in parsed.hintUpdates) {
      // Re-fetch at apply time: the reflect network call took up to 30s,
      // and the user may have acted meanwhile (Done, edit, pin). Writing
      // the pre-call record would carry a fresher updatedAtMs and silently
      // LWW-stomp their action on every device (Tier-1 review fix). The
      // parser's open+unpinned gate is re-checked against the fresh record
      // for the same reason.
      final fresh = await _intentions.getIntention(hint.intentionId);
      if (fresh == null || !fresh.isLive || fresh.isPinned) continue;
      await _intentions.upsertIntention(
        fresh.copyWith(
          aiHintsJson: mergeHints(fresh.aiHintsJson, hint),
          updatedAtMs: now.millisecondsSinceEpoch,
        ),
      );
    }

    await _cacheObservation(parsed.observation, now);
  }

  /// Merge, never replace: an existing hint map keeps its other keys.
  @visibleForTesting
  static String mergeHints(String? existingJson, ReflectionHintUpdate hint) {
    Map<String, dynamic> hints = {};
    if (existingJson != null && existingJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(existingJson);
        if (decoded is Map<String, dynamic>) hints = decoded;
      } catch (_) {}
    }
    hints['preferredTimeBlock'] = hint.preferredTimeBlock;
    hints['hintSource'] = 'reflect';
    if (hint.basedOn.isNotEmpty) {
      // Provenance for the confirm-at-delivery loop: "wrong time" strikes
      // contradict these sourcing records (P1-05).
      hints['basedOn'] = hint.basedOn;
    }
    return jsonEncode(hints);
  }

  /// One observation per pass, cached day-scoped under the synthetic
  /// reflection entity. No observation retires yesterday's — reflections
  /// don't linger past their day.
  Future<void> _cacheObservation(
    ReflectionObservation? observation,
    DateTime now,
  ) async {
    if (observation == null) {
      await _insightCache.replaceScopeInsights(
        scopeType: InsightScopeType.entity,
        scopeId: reflectionScopeId,
        insights: const [],
      );
      return;
    }

    final today = DateKeys.todayKey(now);
    final pattern = DetectedPattern(
      entityId: reflectionScopeId,
      entityKind: BehaviorEntityKind.reflection,
      patternCode: PatternCode.reflectionSignal,
      patternGroup: PatternGroup.reflection,
      // Fixed low severity, sub-1.0 confidence: the claim is AI-inferred,
      // not measured — it must never outrank a deterministic insight.
      severity: 0.3,
      confidence: 0.6,
      detectedAtMs: now.millisecondsSinceEpoch,
      sourceWindowStartDateKey: today,
      sourceWindowEndDateKey: today,
      metadata: {'basedOn': observation.basedOn},
    );
    final out = _orchestrator.runForEntity(
      entityId: reflectionScopeId,
      patterns: [pattern],
      now: now,
    );
    if (out.hasFatalError) return;
    final withMessage = out.insights
        .map((insight) => _withObservationMessage(insight, observation))
        .toList(growable: false);
    await _insightCache.replaceScopeInsights(
      scopeType: InsightScopeType.entity,
      scopeId: reflectionScopeId,
      insights: withMessage,
    );
  }

  static GeneratedInsight _withObservationMessage(
    GeneratedInsight insight,
    ReflectionObservation observation,
  ) {
    if (insight.insightType != InsightType.reflectionObservation) {
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
      message: observation.message,
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
        'provenance': 'aiInferred',
        'basedOn': observation.basedOn,
      },
      schemaVersion: insight.schemaVersion,
    );
  }
}

const _kReflectionSystemPrompt = '''
You are the quiet reflection pass of a personal coaching app. You receive a JSON snapshot of what the app already knows about its user: memory facts, people, and intentions (promises) with their status and avoidance history.

Ask yourself: did the user forget something? Are they avoiding something? Does something deserve gentle attention? Connect ONLY the dots in the snapshot — never invent.

Return STRICT JSON, no prose:
{
  "dormantIntentions": [
    {"title": "Reconnect with college friends", "estimatedMinutes": 30, "basedOn": ["<id from the snapshot>"]}
  ],
  "hintUpdates": [
    {"intentionId": "<id of an OPEN intention>", "preferredTimeBlock": "morning|afternoon|evening", "basedOn": ["<id>"]}
  ],
  "observations": [
    {"message": "hedged, gentle observation, max 200 chars", "basedOn": ["<id>"]}
  ]
}

Rules:
- Every item MUST cite "basedOn" ids copied verbatim from the snapshot. Items without valid grounding are discarded.
- "dormantIntentions" are standing wishes the user implied but never asked to be reminded of — they create NO notifications. Max 3. Never duplicate an existing intention.
- "hintUpdates" only when the snapshot shows a timing pattern (e.g. repeated snoozes) suggesting a better time block. Max 5.
- "observations" are for a possible forget/avoid/change worth mentioning. Phrase as a hedged question or gentle notice ("You might be…", "Looks like…"), never a command or diagnosis. Max 1.
- Empty arrays are the right answer for an unremarkable snapshot: {"dormantIntentions":[],"hintUpdates":[],"observations":[]}.
''';
