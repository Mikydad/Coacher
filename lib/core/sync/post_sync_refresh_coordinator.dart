import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/application/main_tab_navigation.dart';
import '../../features/analytics/application/analytics_period_bundle_notifier.dart';
import '../../features/analytics/application/delivery_providers.dart';
import '../../features/planning/application/planned_task_providers.dart';

/// Debounces Riverpod invalidations after cloud pull so UI does not flash loaders repeatedly.
class PostSyncRefreshCoordinator {
  PostSyncRefreshCoordinator._();

  static final PostSyncRefreshCoordinator instance = PostSyncRefreshCoordinator._();

  /// Coalescing window for multiple schedule calls (resume + sync complete, etc.).
  static const Duration debounce = Duration(milliseconds: 450);

  @visibleForTesting
  static Duration debounceForTests = debounce;

  Timer? _timer;
  _PendingRefresh _pending = const _PendingRefresh();

  /// Queue a batched provider refresh (merged if called again within [debounce]).
  void schedule({
    bool tasks = false,
    bool coachingDelivery = false,
    bool todayAnalytics = false,
  }) {
    if (!tasks && !coachingDelivery && !todayAnalytics) return;

    _pending = _pending.merge(
      tasks: tasks,
      coachingDelivery: coachingDelivery,
      todayAnalytics: todayAnalytics,
    );

    _timer?.cancel();
    _timer = Timer(debounceForTests, _flush);
  }

  /// Called when [SyncService] finishes a successful Firestore → Isar pull.
  void scheduleAfterSuccessfulRemotePull() {
    schedule(tasks: true, coachingDelivery: true, todayAnalytics: true);
  }

  @visibleForTesting
  void flushNowForTests() {
    _timer?.cancel();
    _timer = null;
    _flush();
  }

  @visibleForTesting
  void resetForTests() {
    _timer?.cancel();
    _timer = null;
    _pending = const _PendingRefresh();
    flushCountForTests = 0;
  }

  @visibleForTesting
  int flushCountForTests = 0;

  void _flush() {
    flushCountForTests++;
    _timer = null;
    final container = appRootProviderContainer;
    if (container == null) {
      debugPrint('PostSyncRefreshCoordinator: no ProviderContainer attached');
      _pending = const _PendingRefresh();
      return;
    }

    final pending = _pending;
    _pending = const _PendingRefresh();

    if (pending.tasks) {
      invalidateTaskListProvidersFromContainer(container);
    }
    if (pending.coachingDelivery) {
      invalidateTodayCoachingDeliveryFromContainer(container);
    }
    if (pending.todayAnalytics) {
      container.invalidate(analyticsPeriodBundleProvider);
    }
  }
}

class _PendingRefresh {
  const _PendingRefresh({
    this.tasks = false,
    this.coachingDelivery = false,
    this.todayAnalytics = false,
  });

  final bool tasks;
  final bool coachingDelivery;
  final bool todayAnalytics;

  _PendingRefresh merge({
    required bool tasks,
    required bool coachingDelivery,
    required bool todayAnalytics,
  }) {
    return _PendingRefresh(
      tasks: this.tasks || tasks,
      coachingDelivery: this.coachingDelivery || coachingDelivery,
      todayAnalytics: this.todayAnalytics || todayAnalytics,
    );
  }
}
