import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/analytics/application/analytics_period_bundle_notifier.dart';
import '../../features/analytics/application/delivery_providers.dart';
import '../../features/analytics/application/focus_providers.dart';
import '../../features/execution/application/execution_day_loader.dart';
import '../../features/ai_assistant/application/ai_assistant_providers.dart';
import '../../features/analytics/application/ai_summary_providers.dart';
import '../../features/goals/application/goals_providers.dart';
import '../di/providers.dart';
import 'recompute_scope.dart';

/// Debounced, generation-protected, dependency-ordered recompute pipeline.
///
/// Every schedule mutation routes through this graph via
/// [UnifiedRecomputeGraph.schedule]. The graph coalesces rapid mutations
/// into a single flush, executes steps in strict dependency order, and
/// skips steps that are not required by the scope.
///
/// Design rules:
/// - Plain-Dart singleton; no Riverpod dependency beyond [ProviderContainer].
/// - [attachContainer] must be called once at app bootstrap before any
///   mutation is processed.
/// - The generation counter prevents a stale flush from clobbering a newer
///   mutation's recompute.
class UnifiedRecomputeGraph {
  UnifiedRecomputeGraph._();

  static final UnifiedRecomputeGraph instance = UnifiedRecomputeGraph._();

  /// Coalescing window. Chosen to be slightly shorter than the old
  /// [PostSyncRefreshCoordinator] 450 ms to improve perceived freshness.
  static const Duration kDebounce = Duration(milliseconds: 400);

  ProviderContainer? _container;
  RecomputeScope _pendingScope = const RecomputeScope();
  Timer? _timer;
  int _generation = 0;

  /// Called once at app bootstrap — same pattern as [PostSyncRefreshCoordinator].
  void attachContainer(ProviderContainer container) {
    _container = container;
  }

  /// Queue a recompute for [scope], merging with any already-pending scope.
  ///
  /// Resets the debounce timer. If called rapidly, all scopes are coalesced
  /// into one flush.
  void schedule(RecomputeScope scope) {
    if (scope.isEmpty) return;
    _pendingScope = _pendingScope.merge(scope);
    _generation++;
    _timer?.cancel();
    _timer = Timer(debugDurationOverride ?? kDebounce, _flush);
  }

  Future<void> _flush() async {
    _timer = null;
    final scope = _pendingScope;
    _pendingScope = const RecomputeScope();
    final capturedGeneration = _generation;

    flushCountForTests++;

    final container = _container;
    if (container == null) {
      debugPrint(
        '[UnifiedRecomputeGraph] flush called before attachContainer — skipping invalidations',
      );
      return;
    }

    // ── Step 1: Overlap detection ──────────────────────────────────────────
    // Overlap re-check requires TimeBlockSyncService — deferred to Phase 1-A
    // T3 when the coordinator can inject it. Logged for now.
    if (scope.overlaps) {
      debugPrint(
        '[UnifiedRecomputeGraph] step:overlaps (pending coordinator wiring)',
      );
    }

    if (_generationChanged(capturedGeneration)) return;

    // ── Step 2: Analytics bundle (streaks embedded) ────────────────────────
    if (scope.analytics) {
      container.invalidate(analyticsPeriodBundleProvider);
      debugPrint('[UnifiedRecomputeGraph] step:analytics');
    }

    if (_generationChanged(capturedGeneration)) return;

    // ── Step 3: Coaching focus (light path) ───────────────────────────────
    if (scope.focus) {
      container.invalidate(recomputeCoachingFocusProvider);
      container.invalidate(executionDayTasksProvider);
      debugPrint('[UnifiedRecomputeGraph] step:focus');
    }

    if (_generationChanged(capturedGeneration)) return;

    // ── Step 4: Proactive suggestions ─────────────────────────────────────
    if (scope.suggestions) {
      container.invalidate(proactiveSuggestionsProvider);
      debugPrint('[UnifiedRecomputeGraph] step:suggestions');
    }

    if (_generationChanged(capturedGeneration)) return;

    // ── Step 5: Layer 3 + Layer 4 delivery ────────────────────────────────
    if (scope.layer34) {
      invalidateTodayCoachingDeliveryFromContainer(container);
      debugPrint('[UnifiedRecomputeGraph] step:layer34');
    }

    if (_generationChanged(capturedGeneration)) return;

    // ── Step 6: AI summary ────────────────────────────────────────────────
    if (scope.aiSummary) {
      container.invalidate(currentAiSummaryProvider);
      debugPrint('[UnifiedRecomputeGraph] step:aiSummary');
    }

    if (_generationChanged(capturedGeneration)) return;

    // ── Step 7: Notification reconciliation ───────────────────────────────
    // Goal reminders are one-shot since the Phase 0 orchestrator reroute
    // (decision log 2026-07-23): a fired reminder needs its next occurrence
    // re-armed on the next app activity. This step is that roll-forward —
    // throttled inside rearmIfStale so frequent flushes stay cheap. All
    // reads are local (IsarGoalsRepository), so this is airplane-mode safe.
    if (scope.notifications) {
      try {
        final goals = await container
            .read(goalsRepositoryProvider)
            .fetchGoalsOnce();
        if (_generationChanged(capturedGeneration)) return;
        await container.read(goalReminderSyncServiceProvider).rearmIfStale(goals);
        debugPrint('[UnifiedRecomputeGraph] step:notifications');
      } catch (e) {
        debugPrint('[UnifiedRecomputeGraph] step:notifications failed: $e');
      }
    }
  }

  bool _generationChanged(int capturedGeneration) {
    if (_generation != capturedGeneration) {
      debugPrint(
        '[UnifiedRecomputeGraph] generation changed — aborting stale flush',
      );
      return true;
    }
    return false;
  }

  // ── Test helpers ───────────────────────────────────────────────────────────

  /// Override debounce duration for tests (set to [Duration.zero] for
  /// synchronous-style tests, or a known duration for timer tests).
  @visibleForTesting
  Duration? debugDurationOverride;

  @visibleForTesting
  int flushCountForTests = 0;

  @visibleForTesting
  void flushNowForTests() {
    _timer?.cancel();
    _timer = null;
    // Fire synchronously via unawaited (flush is async but only invalidates).
    _flush();
  }

  @visibleForTesting
  void resetForTests() {
    _timer?.cancel();
    _timer = null;
    _pendingScope = const RecomputeScope();
    _generation = 0;
    flushCountForTests = 0;
    _container = null;
    debugDurationOverride = null;
  }
}
