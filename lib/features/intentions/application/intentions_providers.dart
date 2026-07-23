import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/notifications/notification_ledger_repository.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/scheduling/free_window_calculator.dart';
import '../../../core/utils/date_keys.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../reminders/application/attention_orchestrator_providers.dart';
import '../data/intentions_repository.dart';
import '../data/opportunity_plan_repository.dart';
import '../domain/models/intention.dart';
import 'intention_nudge_sync_service.dart';

final intentionsRepositoryProvider = Provider<IntentionsRepository>(
  (ref) => IntentionsRepository(),
);

final opportunityPlanRepositoryProvider = Provider<OpportunityPlanRepository>(
  (ref) => OpportunityPlanRepository(),
);

/// All live (non-tombstoned) intentions, newest first. UI reads this —
/// the local write IS the update (no invalidate-and-refetch).
final intentionsStreamProvider = StreamProvider<List<Intention>>((ref) {
  return ref.watch(intentionsRepositoryProvider).watchIntentions();
});

/// Open intentions — the Promises strip's main content.
final openIntentionsProvider = Provider<List<Intention>>((ref) {
  final all = ref.watch(intentionsStreamProvider).valueOrNull ?? const [];
  return all
      .where((i) => i.status == IntentionStatus.open)
      .toList(growable: false);
});

/// Dormant intentions — the "on your radar" section (hidden when empty;
/// only Phase 2 extraction creates these).
final radarIntentionsProvider = Provider<List<Intention>>((ref) {
  final all = ref.watch(intentionsStreamProvider).valueOrNull ?? const [];
  return all
      .where((i) => i.status == IntentionStatus.dormant)
      .toList(growable: false);
});

/// Cached opportunity plans keyed by intention id — powers the "planned
/// for …" line on the Promises strip.
final opportunityPlansProvider =
    StreamProvider<Map<String, OpportunityPlan>>((ref) {
  return ref
      .watch(opportunityPlanRepositoryProvider)
      .watchPlans()
      .map((plans) => {for (final p in plans) p.intentionId: p});
});

/// One seize-the-moment opportunity for the Home card: an open intention
/// that fits inside the free window the user is in RIGHT NOW.
class SeizeTheMomentCandidate {
  const SeizeTheMomentCandidate({
    required this.intention,
    required this.freeMinutes,
    this.beforeTitle,
  });

  final Intention intention;
  final int freeMinutes;
  final String? beforeTitle;
}

/// Intention ids the user said "Not now" to this session — the card must
/// not nag twice for the same promise in one sitting.
final dismissedSeizeCandidatesProvider = StateProvider<Set<String>>(
  (ref) => const {},
);

final seizeTheMomentProvider = FutureProvider<SeizeTheMomentCandidate?>((
  ref,
) async {
  final open = ref.watch(openIntentionsProvider);
  final dismissed = ref.watch(dismissedSeizeCandidatesProvider);
  final now = DateTime.now();
  final nowMs = now.millisecondsSinceEpoch;
  final candidates = open.where(
    (i) =>
        !dismissed.contains(i.id) &&
        !i.isPinned &&
        i.windowStartMs <= nowMs &&
        i.windowEndMs > nowMs,
  );
  if (candidates.isEmpty) return null;

  List<Map<String, dynamic>> busyMaps;
  try {
    final rows = await collectTasksForDateKey(
      ref.read(planningRepositoryProvider),
      DateKeys.todayKey(now),
    );
    busyMaps = scheduleMapsFromPlannedRows(rows);
  } catch (_) {
    busyMaps = const [];
  }
  final nowMinute = now.hour * 60 + now.minute;
  final windows = FreeWindowCalculator.computeWindows(busyMaps);
  FreeWindow? current;
  for (final w in windows) {
    if (w.startMinute <= nowMinute && nowMinute < w.endMinute) {
      current = w;
      break;
    }
  }
  if (current == null) return null;
  final remaining = current.endMinute - nowMinute;
  if (remaining < 10) return null;

  // Best fit: prefers the intention that actually fits, then importance,
  // then the tightest deadline.
  final fitting =
      candidates.where((i) => i.estimatedMinutes <= remaining).toList()
        ..sort((a, b) {
          final imp = b.importance.index.compareTo(a.importance.index);
          if (imp != 0) return imp;
          return a.windowEndMs.compareTo(b.windowEndMs);
        });
  if (fitting.isEmpty) return null;
  return SeizeTheMomentCandidate(
    intention: fitting.first,
    freeMinutes: remaining,
    beforeTitle: current.beforeTitle,
  );
});

final intentionNudgeSyncServiceProvider = Provider<IntentionNudgeSyncService>(
  (ref) => IntentionNudgeSyncService(
    intentions: ref.read(intentionsRepositoryProvider),
    plans: ref.read(opportunityPlanRepositoryProvider),
    planningRepository: ref.read(planningRepositoryProvider),
    featureCache: ref.read(featureCacheRepositoryProvider),
    ledger: NotificationLedgerRepository(OfflineStore.instance.isar!),
    orchestrator: ref.read(attentionOrchestratorServiceProvider),
    budget: ref.read(notificationBudgetProvider),
  ),
);
