import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/context/context_providers.dart';
import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/friendly_date.dart';
import '../../../core/utils/stable_id.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../auth/application/auth_providers.dart';
import '../../coaching/application/coaching_style_providers.dart';
import '../../coaching/application/default_mode_resolver.dart';
import '../../context_override/application/context_override_providers.dart';
import '../../goals/application/goals_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../time_blocks/application/time_block_providers.dart';
import '../../../core/local_db/isar_collections/isar_ai_action_batch.dart';
import '../../../core/offline/offline_store.dart';
import '../data/dismissed_suggestion_repository.dart';
import '../domain/models/proactive_suggestion.dart';
import '../../../core/tier/tier_providers.dart';
import 'ai_action_batch_repository.dart';
import 'ai_action_batch_state.dart';
import '../../intentions/application/intentions_providers.dart';
import '../../memory/application/memory_providers.dart';
import 'ai_action_executor.dart';
import 'ai_tier_guard.dart';
import 'ai_assistant_service.dart';
import 'ai_assumption_engine.dart';
import 'ai_entity_resolver.dart';
import 'ai_chat_suggestion_enricher.dart';
import 'ai_conflict_detector.dart';
import 'ai_intent_parser.dart';
import 'ai_operating_layer_client.dart';
import 'ai_payload_assembler.dart';
import 'entity_normaliser.dart';
import 'proactive_suggestion_engine.dart';
import 'schedule_optimisation_service.dart';
import 'voice_reply_stream.dart';

// ─── AI client ────────────────────────────────────────────────────────────────

/// Async because [buildAiOperatingLayerClient] fetches Remote Config.
final aiOperatingLayerClientProvider = FutureProvider<AiOperatingLayerClient>((
  ref,
) async {
  final planning = ref.read(planningRepositoryProvider);
  return buildAiOperatingLayerClient(
    toolRunner: AiCoachToolRunner(
      dayScheduleLookup: (dateKey) async {
        final rows = await collectTasksForDateKey(planning, dateKey);
        // Tool output feeds the model's prose — hand it the human word so
        // the reply says "Sunday", not the date key (2026-08-25).
        final dayLabel = friendlyDateKey(dateKey);
        if (rows.isEmpty) return 'Nothing scheduled on $dayLabel ($dateKey).';
        final buffer = StringBuffer('Tasks on $dayLabel ($dateKey):\n');
        for (final row in rows) {
          final t = row.task;
          var time = 'no time set';
          final iso = t.reminderTimeIso;
          if (iso != null && iso.isNotEmpty) {
            final dt = DateTime.tryParse(iso)?.toLocal();
            if (dt != null) {
              time =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            }
          }
          buffer.writeln(
            '- ${t.title} at $time (${t.durationMinutes} min, ${t.status.name})',
          );
        }
        return buffer.toString().trim();
      },
    ),
  );
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
    memoryFactsRepository: ref.read(memoryFactsRepositoryProvider),
    peopleRepository: ref.read(peopleRepositoryProvider),
    intentionsRepository: ref.read(intentionsRepositoryProvider),
    contextSnapshotService: ref.read(contextSnapshotServiceProvider),
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

// ─── Chat suggestion enricher ─────────────────────────────────────────────────

final aiChatSuggestionEnricherProvider = Provider<AiChatSuggestionEnricher>((
  ref,
) {
  return AiChatSuggestionEnricher(
    proactiveEngine: ref.read(proactiveSuggestionEngineProvider),
    dismissedRepo: ref.read(dismissedSuggestionRepositoryProvider),
  );
});

// ─── Entity resolver ──────────────────────────────────────────────────────────

final aiEntityResolverProvider = Provider<AiEntityResolver>((ref) {
  return AiEntityResolver(
    planningRepository: ref.read(planningRepositoryProvider),
    goalsRepository: ref.read(goalsRepositoryProvider),
  );
});

// ─── Intent parser ────────────────────────────────────────────────────────────

final aiIntentParserProvider = FutureProvider<AiIntentParser>((ref) async {
  final client = await ref.watch(aiOperatingLayerClientProvider.future);
  final assembler = ref.read(aiPayloadAssemblerProvider);
  final assumptionEngine = ref.read(aiAssumptionEngineProvider);
  final conflictDetector = ref.read(aiConflictDetectorProvider);
  final enricher = ref.read(aiChatSuggestionEnricherProvider);
  return AiIntentParser(
    client: client,
    assembler: assembler,
    assumptionEngine: assumptionEngine,
    conflictDetector: conflictDetector,
    chatSuggestionEnricher: enricher,
    entityResolver: ref.read(aiEntityResolverProvider),
  );
});

// ─── Batch repository provider ────────────────────────────────────────────────

final aiActionBatchRepositoryProvider = Provider<AiActionBatchRepository>((
  ref,
) {
  return AiActionBatchRepository(OfflineStore.instance.isar!);
});

/// The most recent [IsarAiActionBatch] — used by the UI to decide whether
/// to show the "Undo AI changes" button.
// Isar watch streams (fix-wave Phase 2, §8 E5): the old cached
// FutureProviders were only ever invalidated from inside the undo handlers
// — circular, so the Undo chip stayed at its stale pre-confirm value for
// the rest of the app session. A watch emits the moment any batch write
// lands; no manual invalidation exists anymore.
Stream<T> _watchBatches<T>(
  Ref ref,
  Future<T> Function(AiActionBatchRepository repo) read,
) async* {
  // Rebuild on account switch so values never leak across users.
  ref.watch(authUidProvider);
  final repo = ref.read(aiActionBatchRepositoryProvider);
  final isar = OfflineStore.instance.isar;
  yield await read(repo);
  if (isar == null) return;
  await for (final _ in isar.isarAiActionBatchs.watchLazy()) {
    yield await read(repo);
  }
}

final lastAiBatchProvider = StreamProvider<IsarAiActionBatch?>(
  (ref) => _watchBatches(ref, (repo) => repo.findMostRecent()),
);

/// Whether the undo button should be visible: most recent batch is
/// undoable (`completed` or `partialFailure` — matching the executor's own
/// rule) and was created within the last 30 minutes. Re-evaluated on every
/// batch write; a chip lingering past the window resolves honestly to
/// UndoNotAvailable on tap.
final canUndoLastAiBatchProvider = StreamProvider<bool>(
  (ref) => _watchBatches(ref, (repo) async {
    final batch = await repo.findMostRecent();
    if (batch == null) return false;
    final isUndoable =
        batch.state == AiActionBatchState.completed.name ||
        batch.state == AiActionBatchState.partialFailure.name;
    if (!isUndoable) return false;
    final ageMs = DateTime.now().millisecondsSinceEpoch - batch.createdAtMs;
    return ageMs <= const Duration(minutes: 30).inMilliseconds;
  }),
);

/// Recent AI batch history — last 5 batches, newest first.
final recentAiBatchesProvider = StreamProvider<List<IsarAiActionBatch>>(
  (ref) => _watchBatches(ref, (repo) => repo.listRecent()),
);

// ─── Action executor ─────────────────────────────────────────────────────────

final aiActionExecutorProvider = Provider<AiActionExecutor>((ref) {
  // AI-created tasks default to the profile Discipline Mode scaled to
  // medium importance (same matrix as Add Task) — never raw `extreme`.
  final enforcementMode = ref.watch(defaultEnforcementModeProvider);
  return AiActionExecutor(
    planningRepository: ref.read(planningRepositoryProvider),
    goalsRepository: ref.read(goalsRepositoryProvider),
    reminderRepository: ref.read(reminderRepositoryProvider),
    reminderSyncService: ref.read(reminderSyncServiceProvider),
    timeBlockSyncService: ref.read(timeBlockSyncServiceProvider),
    contextOverrideService: ref.read(contextOverrideServiceProvider),
    batchRepository: ref.read(aiActionBatchRepositoryProvider),
    defaultModeRefId: DefaultModeResolver.resolveModeRefId(
      profileDefault: enforcementMode,
    ),
    tierGuard: AiTierGuard(
      gate: () => ref.read(tierGateProvider),
      goalsRepository: ref.read(goalsRepositoryProvider),
      reminderRepository: ref.read(reminderRepositoryProvider),
    ),
    intentionsRepository: ref.read(intentionsRepositoryProvider),
    intentionNudgeSyncService: ref.read(intentionNudgeSyncServiceProvider),
    memoryFactsRepository: ref.read(memoryFactsRepositoryProvider),
    peopleRepository: ref.read(peopleRepositoryProvider),
  );
});

// ─── AI Assistant service ─────────────────────────────────────────────────────

/// [ChangeNotifierProvider] so the UI can listen to fine-grained state updates
/// without rebuilding the whole screen on every notifyListeners call.
final aiAssistantServiceProvider =
    ChangeNotifierProvider.family<AiAssistantService, AiIntentParser>((
      ref,
      parser,
    ) {
      final analyticsRepo = ref.read(analyticsRepositoryProvider);
      final assembler = ref.read(aiPayloadAssemblerProvider);
      // Voice Level 2: streamed conversational replies. Endpoint/token are
      // closures so Firebase is touched at stream time, never at build time.
      final voiceStreamer = AiVoiceReplyStreamer(
        assembler: assembler,
        endpoint: () => Uri.parse(
          'https://us-central1-${Firebase.app().options.projectId}'
          '.cloudfunctions.net/aiChatStream',
        ),
        idToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
      );
      return AiAssistantService(
        intentParser: parser,
        actionExecutor: ref.read(aiActionExecutorProvider),
        historyRepository: ref.read(aiInteractionHistoryRepositoryProvider),
        memoryExtraction: ref.read(memoryExtractionServiceProvider),
        onScheduleMutated: assembler.invalidateSessionCache,
        voiceReplyStreamer: voiceStreamer.stream,
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
    });

/// Convenience provider that resolves the async parser and returns the service.
/// The screen should watch this; while loading it shows the READY pill as
/// "LOADING" or a skeleton.
final resolvedAiAssistantProvider = FutureProvider<AiAssistantService>((
  ref,
) async {
  final parser = await ref.watch(aiIntentParserProvider.future);
  final service = ref.watch(aiAssistantServiceProvider(parser));
  // Launch continuity (fix-wave Phase 7, §8 U10): the last same-day
  // session rehydrates as marked history — idempotent, no-op once done.
  unawaited(service.hydrateFromHistory());
  return service;
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

final proactiveSuggestionEngineProvider = Provider<ProactiveSuggestionEngine>((
  ref,
) {
  return ProactiveSuggestionEngine(
    planningRepository: ref.read(planningRepositoryProvider),
    goalsRepository: ref.read(goalsRepositoryProvider),
    timeBlockRepository: ref.read(timeBlockRepositoryProvider),
    dismissedRepo: ref.read(dismissedSuggestionRepositoryProvider),
    normaliser: ref.read(entityNormaliserProvider),
    optimisationService: ref.read(scheduleOptimisationServiceProvider),
    // Reminder V2 strategist proposals (FR-R-61): today's day-scoped
    // suggestions from the Thinking Loop, rendered like any other card.
    // The pre-drafted input hands the ask to the coach — the user sends it,
    // the coach's confirmed tools (with their 30-min undo) execute it. D7's
    // no-auto-apply, using machinery that already exists.
    strategistSource: () async {
      final proposals = await ref
          .read(strategistProposalsStoreProvider)
          .loadForDay(DateKeys.todayKey());
      final now = DateTime.now();
      return [
        for (final p in proposals)
          ProactiveSuggestion(
            id: 'strategist_${p.kind}_${p.taskId}',
            type: ProactiveSuggestionType.reminderStrategy,
            title: p.taskTitle.isEmpty ? 'A reminder to rethink' : p.taskTitle,
            description: p.suggestion,
            preDraftedInput: switch (p.kind) {
              'reschedule' =>
                'Help me find a better time for "${p.taskTitle}" — it keeps slipping.',
              'ladderTuning' =>
                'Adjust how "${p.taskTitle}" reminds me — the current rhythm is not working.',
              'aggregate' =>
                'Make "${p.taskTitle}" quieter — batch its misses instead of reminding each time.',
              _ =>
                'Should I drop "${p.taskTitle}"? Walk me through whether to keep it.',
            },
            confidence: 0.55,
            generatedAt: now,
          ),
      ];
    },
  );
});

/// [FutureProvider] that triggers [ProactiveSuggestionEngine.generateForToday].
/// Invalidated on task mutation and app foreground events.
final proactiveSuggestionsProvider = FutureProvider<List<ProactiveSuggestion>>((
  ref,
) async {
  final engine = ref.read(proactiveSuggestionEngineProvider);
  return engine.generateForToday();
});

// ─── Morning brief state ──────────────────────────────────────────────────────

/// Tracks the date key on which the Coach screen was last opened.
/// Used by the morning brief to ensure the snackbar is only shown once per day.
final coachLastOpenedDateKeyProvider = StateProvider<String?>((ref) => null);

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
