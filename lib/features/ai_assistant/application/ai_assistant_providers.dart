import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../coaching/application/coaching_style_providers.dart';
import '../../context_override/application/context_override_providers.dart';
import '../../goals/application/goals_providers.dart';
import '../../time_blocks/application/time_block_providers.dart';
import 'ai_action_executor.dart';
import 'ai_assistant_service.dart';
import 'ai_intent_parser.dart';
import 'ai_operating_layer_client.dart';
import 'ai_payload_assembler.dart';

// ─── AI client ────────────────────────────────────────────────────────────────

/// Async because [buildAiOperatingLayerClient] fetches Remote Config.
final aiOperatingLayerClientProvider =
    FutureProvider<AiOperatingLayerClient>((ref) async {
  return buildAiOperatingLayerClient();
});

// ─── Payload assembler ────────────────────────────────────────────────────────

final aiPayloadAssemblerProvider = Provider<AiPayloadAssembler>((ref) {
  return AiPayloadAssembler(
    planningRepository: ref.read(planningRepositoryProvider),
    goalsRepository: ref.read(goalsRepositoryProvider),
    contextOverrideRepository: ref.read(contextOverrideRepositoryProvider),
    coachingStyleRepository: ref.read(coachingStyleRepositoryProvider),
    historyRepository: ref.read(aiInteractionHistoryRepositoryProvider),
  );
});

// ─── Intent parser ────────────────────────────────────────────────────────────

final aiIntentParserProvider = FutureProvider<AiIntentParser>((ref) async {
  final client = await ref.watch(aiOperatingLayerClientProvider.future);
  final assembler = ref.read(aiPayloadAssemblerProvider);
  return AiIntentParser(client: client, assembler: assembler);
});

// ─── Action executor ─────────────────────────────────────────────────────────

final aiActionExecutorProvider = Provider<AiActionExecutor>((ref) {
  return AiActionExecutor(
    planningRepository: ref.read(planningRepositoryProvider),
    goalsRepository: ref.read(goalsRepositoryProvider),
    reminderRepository: ref.read(reminderRepositoryProvider),
    reminderSyncService: ref.read(reminderSyncServiceProvider),
    timeBlockSyncService: ref.read(timeBlockSyncServiceProvider),
    contextOverrideService: ref.read(contextOverrideServiceProvider),
    ref: ref,
  );
});

// ─── AI Assistant service ─────────────────────────────────────────────────────

/// [ChangeNotifierProvider] so the UI can listen to fine-grained state updates
/// without rebuilding the whole screen on every notifyListeners call.
final aiAssistantServiceProvider =
    ChangeNotifierProvider.family<AiAssistantService, AiIntentParser>(
  (ref, parser) {
    final analyticsRepo = ref.read(analyticsRepositoryProvider);
    return AiAssistantService(
      intentParser: parser,
      actionExecutor: ref.read(aiActionExecutorProvider),
      historyRepository: ref.read(aiInteractionHistoryRepositoryProvider),
      analyticsLogger: (eventName, props) {
        final type = AnalyticsEventType.values.firstWhere(
          (e) => e.name == eventName,
          orElse: () => AnalyticsEventType.aiCommandSubmitted,
        );
        final event = AnalyticsEvent(
          id: StableId.generate('ai_evt'),
          type: type,
          entityId: props['sessionId']?.toString() ?? 'ai',
          entityKind: 'aiSession',
          dateKey: DateKeys.todayKey(),
          timestampLocalIso: DateTime.now().toIso8601String(),
          sourceSurface: 'coach_ai',
          idempotencyKey: StableId.generate('ai_evt_idem'),
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        );
        analyticsRepo.logEvent(event);
      },
    );
  },
);

/// Convenience provider that resolves the async parser and returns the service.
/// The screen should watch this; while loading it shows the READY pill as
/// "LOADING" or a skeleton.
final resolvedAiAssistantProvider =
    FutureProvider<AiAssistantService>((ref) async {
  final parser = await ref.watch(aiIntentParserProvider.future);
  return ref.watch(aiAssistantServiceProvider(parser));
});
