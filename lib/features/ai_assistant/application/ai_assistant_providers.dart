import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../coaching/application/coaching_style_providers.dart';
import '../../context_override/application/context_override_providers.dart';
import '../../goals/application/goals_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../time_blocks/application/time_block_providers.dart';
import '../../../core/local_db/isar_collections/isar_ai_action_batch.dart';
import '../../../core/offline/offline_store.dart';
import '../data/dismissed_suggestion_repository.dart';
import '../domain/models/proactive_suggestion.dart';
import 'ai_action_batch_repository.dart';
import 'ai_action_batch_state.dart';
import 'ai_action_executor.dart';
import 'ai_assistant_service.dart';
import 'ai_assumption_engine.dart';
import 'ai_conflict_detector.dart';
import 'ai_intent_parser.dart';
import 'ai_operating_layer_client.dart';
import 'ai_payload_assembler.dart';
import 'entity_normaliser.dart';
import 'proactive_suggestion_engine.dart';
import 'schedule_optimisation_service.dart';

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
    profilePreferenceService: ref.read(profilePreferenceServiceProvider),
  );
});

// ─── Entity normaliser ────────────────────────────────────────────────────────

final entityNormaliserProvider = Provider<EntityNormaliser>((ref) {
  return const EntityNormaliser();
});

// ─── Assumption engine ────────────────────────────────────────────────────────

final aiAssumptionEngineProvider = Provider<AiAssumptionEngine>((ref) {
  return AiAssumptionEngine(
    planningRepository: ref.read(planningRepositoryProvider),
    historyRepository: ref.read(aiInteractionHistoryRepositoryProvider),
    normaliser: ref.read(entityNormaliserProvider),
  );
});

// ─── Conflict detector ────────────────────────────────────────────────────────

final aiConflictDetectorProvider = Provider<AiConflictDetector>((ref) {
  return AiConflictDetector(
    reminderRepository: ref.read(reminderRepositoryProvider),
    contextOverrideRepository: ref.read(contextOverrideRepositoryProvider),
  );
});

// ─── Intent parser ────────────────────────────────────────────────────────────

final aiIntentParserProvider = FutureProvider<AiIntentParser>((ref) async {
  final client = await ref.watch(aiOperatingLayerClientProvider.future);
  final assembler = ref.read(aiPayloadAssemblerProvider);
  final assumptionEngine = ref.read(aiAssumptionEngineProvider);
  final conflictDetector = ref.read(aiConflictDetectorProvider);
  return AiIntentParser(
    client: client,
    assembler: assembler,
    assumptionEngine: assumptionEngine,
    conflictDetector: conflictDetector,
  );
});

// ─── Batch repository provider ────────────────────────────────────────────────

final aiActionBatchRepositoryProvider = Provider<AiActionBatchRepository>((ref) {
  return AiActionBatchRepository(OfflineStore.instance.isar!);
});

/// The most recent [IsarAiActionBatch] — used by the UI to decide whether
/// to show the "Undo AI changes" button.
final lastAiBatchProvider = FutureProvider<IsarAiActionBatch?>((ref) async {
  final repo = ref.read(aiActionBatchRepositoryProvider);
  return repo.findMostRecent();
});

/// Whether the undo button should be visible: most recent batch is `completed`
/// and was created within the last 30 minutes.
final canUndoLastAiBatchProvider = FutureProvider<bool>((ref) async {
  final batch = await ref.watch(lastAiBatchProvider.future);
  if (batch == null) return false;
  final isUndoable = batch.state == AiActionBatchState.completed.name;
  if (!isUndoable) return false;
  final ageMs = DateTime.now().millisecondsSinceEpoch - batch.createdAtMs;
  return ageMs <= const Duration(minutes: 30).inMilliseconds;
});

/// Recent AI batch history — last 5 batches, newest first.
final recentAiBatchesProvider =
    FutureProvider<List<IsarAiActionBatch>>((ref) async {
  return ref.read(aiActionBatchRepositoryProvider).listRecent();
});

// ─── Action executor ─────────────────────────────────────────────────────────

final aiActionExecutorProvider = Provider<AiActionExecutor>((ref) {
  // Read the user's default enforcement mode for task creation
  final enforcementMode = ref.watch(defaultEnforcementModeProvider);
  return AiActionExecutor(
    planningRepository: ref.read(planningRepositoryProvider),
    goalsRepository: ref.read(goalsRepositoryProvider),
    reminderRepository: ref.read(reminderRepositoryProvider),
    reminderSyncService: ref.read(reminderSyncServiceProvider),
    timeBlockSyncService: ref.read(timeBlockSyncServiceProvider),
    contextOverrideService: ref.read(contextOverrideServiceProvider),
    batchRepository: ref.read(aiActionBatchRepositoryProvider),
    defaultModeRefId: enforcementMode.name,
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

// ─── Dismissed suggestion repository ─────────────────────────────────────────

final dismissedSuggestionRepositoryProvider =
    Provider<DismissedSuggestionRepository>((ref) {
  return DismissedSuggestionRepository();
});

// ─── Schedule optimisation service ───────────────────────────────────────────

final scheduleOptimisationServiceProvider =
    Provider<ScheduleOptimisationService>((ref) {
  return ScheduleOptimisationService(
    planningRepository: ref.read(planningRepositoryProvider),
    reminderRepository: ref.read(reminderRepositoryProvider),
  );
});

// ─── Proactive suggestion engine ──────────────────────────────────────────────

final proactiveSuggestionEngineProvider =
    Provider<ProactiveSuggestionEngine>((ref) {
  return ProactiveSuggestionEngine(
    planningRepository: ref.read(planningRepositoryProvider),
    goalsRepository: ref.read(goalsRepositoryProvider),
    timeBlockRepository: ref.read(timeBlockRepositoryProvider),
    dismissedRepo: ref.read(dismissedSuggestionRepositoryProvider),
    normaliser: ref.read(entityNormaliserProvider),
    optimisationService: ref.read(scheduleOptimisationServiceProvider),
  );
});

/// [FutureProvider] that triggers [ProactiveSuggestionEngine.generateForToday].
/// Invalidated on task mutation and app foreground events.
final proactiveSuggestionsProvider =
    FutureProvider<List<ProactiveSuggestion>>((ref) async {
  final engine = ref.read(proactiveSuggestionEngineProvider);
  return engine.generateForToday();
});

// ─── Morning brief state ──────────────────────────────────────────────────────

/// Tracks the date key on which the Coach screen was last opened.
/// Used by the morning brief to ensure the snackbar is only shown once per day.
final coachLastOpenedDateKeyProvider =
    StateProvider<String?>((ref) => null);

// ─── Proactive analytics helper ───────────────────────────────────────────────

/// Logs a proactive suggestion analytics event.
///
/// Callable from any widget that has access to [WidgetRef].
void logProactiveEvent(
  WidgetRef ref,
  AnalyticsEventType type, {
  Map<String, dynamic> props = const {},
}) {
  try {
    final repo = ref.read(analyticsRepositoryProvider);
    final event = AnalyticsEvent(
      id: StableId.generate('ps_evt'),
      type: type,
      entityId: props['suggestionType']?.toString() ?? 'proactive',
      entityKind: 'proactiveSuggestion',
      dateKey: DateKeys.todayKey(),
      timestampLocalIso: DateTime.now().toIso8601String(),
      sourceSurface: 'home_proactive',
      idempotencyKey: StableId.generate('ps_evt_idem'),
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    // logEvent is async; errors must not escape the post-frame callback.
    repo.logEvent(event).catchError((_) {});
  } catch (_) {
    // Best-effort logging; never propagate
  }
}
