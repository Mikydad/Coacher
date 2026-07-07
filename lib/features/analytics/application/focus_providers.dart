import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/local_db/isar_collections/isar_coaching_focus.dart';
import '../../../core/utils/date_keys.dart';
import '../../auth/application/auth_providers.dart';
import '../../coaching/domain/models/enforcement_mode.dart';
import '../domain/models/current_coaching_focus.dart';
import '../domain/models/detected_behavior_pattern.dart';
import 'focus_candidate.dart';
import 'focus_selector.dart';
import 'insight_generation_providers.dart';
import 'layer4_delivery_policy.dart';
import 'pattern_detection_orchestrator.dart';

// ─── Repository provider ──────────────────────────────────────────────────────

// focusRepositoryProvider is declared in core/di/providers.dart

// ─── Read active focus ────────────────────────────────────────────────────────

final currentCoachingFocusProvider = StreamProvider<CurrentCoachingFocus?>((
  ref,
) {
  final isar = ref.watch(offlineStoreProvider).isar;
  if (isar == null) {
    return Stream.fromFuture(
      ref.read(focusRepositoryProvider).getActiveFocus(),
    );
  }

  final controller = StreamController<CurrentCoachingFocus?>.broadcast();

  Future<void> emit() async {
    try {
      final focus = await ref.read(focusRepositoryProvider).getActiveFocus();
      if (!controller.isClosed) controller.add(focus);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  unawaited(emit());
  final sub = isar.isarCoachingFocus
      .watchLazy(fireImmediately: false)
      .listen((_) => unawaited(emit()));

  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });

  return controller.stream;
});

// ─── Focus history ────────────────────────────────────────────────────────────

final focusHistoryProvider = FutureProvider<List<CurrentCoachingFocus>>((ref) {
  // Rebuild on account switch so cached values never leak across users.
  ref.watch(authUidProvider);
  return ref.read(focusRepositoryProvider).getRecentFocusHistory();
});

// ─── Build + persist today's coaching focus ──────────────────────────────────

final recomputeCoachingFocusProvider = FutureProvider<CurrentCoachingFocus?>((
  ref,
) async {
  final today = DateKeys.todayKey();
  final now = DateTime.now();

  // Pull today's insights (Layer 3 output).
  final insights = await ref.read(
    layer3DeliveryDayInsightsProvider(today).future,
  );
  if (insights.isEmpty) return null;

  // Pull today's canonical Layer 2 patterns.
  final patternRepo = ref.read(patternDetectionRepositoryProvider);
  final globalSnapshot = await patternRepo.readGlobalBehaviorSnapshot(
    dateKey: today,
  );
  final patternsByEntityId = <String, List<DetectedBehaviorPattern>>{};
  if (globalSnapshot != null) {
    for (final entry in globalSnapshot.entries) {
      final entityPatterns = await patternRepo.readEntityBehaviorPatterns(
        entityId: entry.patternCode.name,
        dateKey: today,
      );
      if (entityPatterns.isNotEmpty) {
        patternsByEntityId[entry.patternCode.name] = entityPatterns;
      }
    }
  }

  // Resolve realtime context.
  final timingProfile = resolveTimingProfile(
    now: now,
    justCompletedTask: false,
  );
  final ctx = FocusRealtimeContext(timingProfile: timingProfile);

  // Pre-load all reminder configs to resolve per-entity EnforcementMode.
  final allReminders = await ref
      .read(reminderRepositoryProvider)
      .listAllReminders();
  final modeByEntityId = <String, EnforcementMode>{
    for (final r in allReminders)
      r.id: EnforcementMode.fromModeRefId(r.modeRefId),
  };

  // Build candidates.
  final candidates = insights.map((insight) {
    final patterns =
        patternsByEntityId[insight.scopeId] ??
        patternsByEntityId[insight.insightType.name] ??
        const <DetectedBehaviorPattern>[];
    final enforcementMode =
        modeByEntityId[insight.scopeId] ?? EnforcementMode.disciplined;
    return FocusCandidate(
      insight: insight,
      supportingPatterns: patterns,
      realtimeContext: ctx,
      enforcementMode: enforcementMode,
    );
  }).toList();

  // Load existing focus for anti-thrash check.
  final existing = await ref.read(focusRepositoryProvider).getActiveFocus();

  // Select.
  final result = selectFocus(
    candidates: candidates,
    existingFocus: existing,
    now: now,
  );

  // Persist.
  await ref.read(focusRepositoryProvider).upsertFocus(result.focus);

  return result.focus;
});
