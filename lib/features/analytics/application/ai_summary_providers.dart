import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_remote_config_service.dart';
import '../../../core/di/providers.dart';
import '../../../core/local_db/isar_collections/isar_ai_summary.dart';
import '../../coaching/application/coaching_style_providers.dart';
import '../domain/models/ai_summary_response.dart';
import '../domain/models/coaching_ai_payload.dart';
import '../domain/models/current_coaching_focus.dart';
import '../domain/models/generated_insight.dart';
import 'ai_response_validator.dart';
import 'coaching_ai_client.dart';
import 'deterministic_coaching_renderer.dart';
import 'insight_generation_providers.dart';
import '../../../core/utils/date_keys.dart';
import 'layer4_delivery_policy.dart';

// ─── Infrastructure providers ─────────────────────────────────────────────────

// aiSummaryRepositoryProvider is declared in core/di/providers.dart

/// Resolves to [ProxyCoachingAiClient] (backed by the `aiChat` Cloud Function)
/// when AI is enabled, or [MockCoachingAiClient] when disabled remotely.
/// This is an async provider because Remote Config requires a network fetch.
final coachingAiClientProvider = FutureProvider<CoachingAiClient>((ref) async {
  final aiEnabled = await AiRemoteConfigService.instance.isAiEnabled();
  if (!aiEnabled) {
    return const MockCoachingAiClient();
  }
  return ProxyCoachingAiClient();
});

final _deterministicRendererProvider = Provider<DeterministicCoachingRenderer>(
  (_) => const DeterministicCoachingRenderer(),
);

final _aiResponseValidatorProvider = Provider<AiResponseValidator>(
  (_) => const AiResponseValidator(),
);

// ─── Current AI summary stream ────────────────────────────────────────────────

/// Streams the latest [AiSummaryResponse] for the current active focus.
/// Emits null when no summary exists yet for the active focus.
final currentAiSummaryProvider = StreamProvider<AiSummaryResponse?>((ref) {
  final isar = ref.watch(offlineStoreProvider).isar;
  if (isar == null) {
    return Stream.fromFuture(
      ref.read(aiSummaryRepositoryProvider).getLatestSummary(),
    );
  }

  final controller = StreamController<AiSummaryResponse?>.broadcast();

  Future<void> emit() async {
    try {
      // Always emit the summary that matches the current active focus.
      final focus = await ref.read(focusRepositoryProvider).getActiveFocus();
      AiSummaryResponse? summary;
      if (focus != null) {
        summary = await ref
            .read(aiSummaryRepositoryProvider)
            .getSummaryForFocus(focus.focusId);
      }
      if (!controller.isClosed) controller.add(summary);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  unawaited(emit());

  // Re-emit whenever the AI summary collection changes.
  final sub = isar.isarAiSummarys
      .watchLazy(fireImmediately: false)
      .listen((_) => unawaited(emit()));

  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });

  return controller.stream;
});

// ─── Recompute AI summary ─────────────────────────────────────────────────────

/// Generates (or returns a cached) [AiSummaryResponse] for the current focus.
///
/// Flow:
///   1. Check if a fresh summary already exists → return cached.
///   2. Assemble [CoachingAiPayload] from deterministic engine outputs.
///   3. Call AI client → validate → persist.
///   4. On any failure → render deterministic fallback → persist.
///
/// The returned response is always non-null: AI or fallback.
final recomputeAiSummaryProvider = FutureProvider<AiSummaryResponse>((
  ref,
) async {
  final focus = await ref.read(focusRepositoryProvider).getActiveFocus();
  if (focus == null) {
    // No active focus — return a generic fallback.
    return _buildGenericFallback();
  }

  final summaryRepo = ref.read(aiSummaryRepositoryProvider);
  final nowMs = DateTime.now().millisecondsSinceEpoch;

  // Derive payload fields needed for TTL calculation.
  final today = DateKeys.todayKey();
  final insights = await ref.read(layer3DeliveryDayInsightsProvider(today).future);
  final primaryInsight = _findPrimaryInsight(insights, focus);
  final primaryInsightType = primaryInsight?.insightType ?? InsightType.latePattern;

  final now = DateTime.now();
  final timingProfile = resolveTimingProfile(now: now, justCompletedTask: false);

  final framing = deriveCoachingFraming(
    focusReason: focus.focusReason,
    focusScore: focus.focusScore,
    urgencyScore: focus.scoreBreakdown.urgencyScore,
  );
  final summaryType = deriveSummaryType(
    framing: framing,
    primaryInsightType: primaryInsightType,
  );

  final ttlMs = computeAiSummaryTtlMs(
    summaryType: summaryType,
    focusScore: focus.focusScore,
    urgencyScore: focus.scoreBreakdown.urgencyScore,
  );

  // Return cached if fresh.
  final isFresh = await summaryRepo.hasFreshSummary(
    focusId: focus.focusId,
    ttlMs: ttlMs,
    nowMs: nowMs,
  );
  if (isFresh) {
    final cached = await summaryRepo.getSummaryForFocus(focus.focusId);
    if (cached != null) return cached;
  }

  // Resolve the user's current coaching style (defaults to balanced).
  final coachingStyle = ref.read(activeCoachingStyleProvider);

  // Assemble payload.
  final deliveryContext = AiDeliveryContext(
    timingProfile: timingProfile.name,
    localDateKey: today,
  );

  final payload = CoachingAiPayload.fromFocus(
    focus: focus,
    primaryInsightType: primaryInsightType,
    deliveryContext: deliveryContext,
    coachingStyle: coachingStyle,
    secondaryInsightType: _findSecondaryInsightType(insights, focus),
  );

  // Call AI — await the FutureProvider to resolve the real/mock client.
  final client = await ref.read(coachingAiClientProvider.future);
  final validator = ref.read(_aiResponseValidatorProvider);
  final renderer = ref.read(_deterministicRendererProvider);

  AiSummaryResponse response;
  try {
    final aiResponse = await client.generateSummary(payload);
    final validated = validator.validate(response: aiResponse, payload: payload);
    if (validated.isValid) {
      response = validated;
    } else {
      // Semantic validation rejected — use fallback.
      response = renderer.render(
        payload: payload,
        failureReason: 'semantic_validation: ${validated.validationOutcome.name}',
      );
    }
  } on AiClientException catch (e) {
    response = renderer.render(
      payload: payload,
      failureReason: e.isRateLimit ? 'rate_limit' : 'client_error: ${e.message}',
    );
  } catch (e) {
    response = renderer.render(payload: payload, failureReason: 'unknown: $e');
  }

  await summaryRepo.upsertSummary(response);
  return response;
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

GeneratedInsight? _findPrimaryInsight(
  List<GeneratedInsight> insights,
  CurrentCoachingFocus focus,
) {
  try {
    return insights.firstWhere((i) => i.insightId == focus.primaryInsightId);
  } catch (_) {
    return insights.isEmpty ? null : insights.first;
  }
}

InsightType? _findSecondaryInsightType(
  List<GeneratedInsight> insights,
  CurrentCoachingFocus focus,
) {
  if (focus.secondaryInsightId == null) return null;
  try {
    return insights
        .firstWhere((i) => i.insightId == focus.secondaryInsightId)
        .insightType;
  } catch (_) {
    return null;
  }
}

AiSummaryResponse _buildGenericFallback() {
  return const AiSummaryResponse(
    focusId: '',
    summaryType: SummaryType.daily,
    tone: CoachingTone.informative,
    dailySummary:
        'Staying consistent with your habits builds lasting results.',
    mainRecommendation: 'Complete one planned action today.',
    framing: CoachingFraming.consistency,
    generatedAtMs: 0,
    promptVersion: kCoachingAiPromptVersion,
    isFallback: true,
    metadata: {'fallbackReason': 'no_active_focus'},
  );
}
