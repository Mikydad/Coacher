import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../context_override/application/context_override_providers.dart';
import '../../goals/application/goals_providers.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../profile/application/profile_providers.dart';
import 'analytics_period_bundle_loader.dart';
import 'analytics_period_bundle.dart';
import 'daily_analytics_providers.dart' show computeAnalyticsPeriodBundle;

/// Local-first analytics bundle: cached Isar snapshots first, fresh compute in background.
class AnalyticsPeriodBundleNotifier extends AsyncNotifier<AnalyticsPeriodBundle> {
  int _refreshGeneration = 0;

  @override
  Future<AnalyticsPeriodBundle> build() async {
    ref.watch(goalsStreamProvider);
    ref.watch(todayAllTasksRowsProvider);
    ref.watch(defaultEnforcementModeProvider);
    ref.watch(attentionStateProvider);

    final cached = await loadCachedAnalyticsPeriodBundle(ref);
    if (cached != null) {
      final generation = ++_refreshGeneration;
      unawaited(_publishFresh(generation));
      return cached;
    }

    _refreshGeneration++;
    return computeAnalyticsPeriodBundle(ref);
  }

  Future<void> _publishFresh(int generation) async {
    try {
      final fresh = await computeAnalyticsPeriodBundle(ref);
      if (generation != _refreshGeneration) return;
      state = AsyncData(fresh);
    } catch (_) {
      // Keep showing cached bundle if background refresh fails.
    }
  }
}

final analyticsPeriodBundleProvider =
    AsyncNotifierProvider<AnalyticsPeriodBundleNotifier, AnalyticsPeriodBundle>(
  AnalyticsPeriodBundleNotifier.new,
);
