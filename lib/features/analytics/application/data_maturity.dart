import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/analytics_repository.dart';

/// How much real behavioral data backs the pipeline, per entity and globally.
///
/// The cold-start problem this solves: without a gate, one completed task on
/// day one flows through all four layers and comes out phrased with full
/// authority ("you're 100% consistent!") — it reads as guessing and burns
/// trust. Insights must be *earned* by real data.
///
/// Thresholds (product decision, 2026-07-15):
/// - entity leaves `observing` at ≥3 distinct active days AND ≥5 events;
///   `established` at ≥7 distinct active days.
/// - global (account-wide) `established` at ≥5 distinct active days — the
///   warm-up focus card counts "Day X of 5" against this.
enum DataMaturityStage { observing, calibrating, established }

/// Days-with-activity required before an entity's insights may show at all.
const int kEntityMinActiveDays = 3;

/// Events required before an entity's insights may show at all.
const int kEntityMinEvents = 5;

/// Distinct active days at which an entity graduates to `established`.
const int kEntityEstablishedActiveDays = 7;

/// Distinct active days (any entity) for global `established` — gates global
/// insights and ends the warm-up card. This is the "of 5" in "Day X of 5".
const int kGlobalEstablishedActiveDays = 5;

/// Distinct active days for global `calibrating`.
const int kGlobalMinActiveDays = 3;

/// Confidence floor applied to the (already restricted) insight types allowed
/// through while an entity is still `calibrating`.
const double kCalibratingConfidenceFloor = 0.55;

class EntityDataMaturity {
  const EntityDataMaturity({
    required this.stage,
    required this.distinctActiveDays,
    required this.eventCount,
  });

  static const empty = EntityDataMaturity(
    stage: DataMaturityStage.observing,
    distinctActiveDays: 0,
    eventCount: 0,
  );

  final DataMaturityStage stage;
  final int distinctActiveDays;
  final int eventCount;
}

class GlobalDataMaturity {
  const GlobalDataMaturity({
    required this.stage,
    required this.activeDaysObserved,
  });

  static const empty = GlobalDataMaturity(
    stage: DataMaturityStage.observing,
    activeDaysObserved: 0,
  );

  final DataMaturityStage stage;

  /// Distinct dateKeys with at least one analytics event, capped at
  /// [kGlobalEstablishedActiveDays] for display ("Day X of 5").
  final int activeDaysObserved;

  bool get isEstablished => stage == DataMaturityStage.established;
}

class DataMaturitySnapshot {
  const DataMaturitySnapshot({required this.global, required this.byEntityId});

  final GlobalDataMaturity global;
  final Map<String, EntityDataMaturity> byEntityId;

  EntityDataMaturity forEntity(String entityId) =>
      byEntityId[entityId] ?? EntityDataMaturity.empty;
}

/// Computes maturity from the analytics event log in one pass. Pure counting —
/// no interpretation — so it stays deterministic and cheap enough to run on
/// every recompute.
class DataMaturityEvaluator {
  DataMaturityEvaluator({required AnalyticsRepository analyticsRepository})
    : _analyticsRepository = analyticsRepository;

  final AnalyticsRepository _analyticsRepository;

  Future<DataMaturitySnapshot> evaluate() async {
    final events = await _analyticsRepository.listEvents();

    final globalDays = <String>{};
    final daysByEntity = <String, Set<String>>{};
    final countByEntity = <String, int>{};

    for (final event in events) {
      final dateKey = event.dateKey.trim();
      final entityId = event.entityId.trim();
      if (dateKey.isEmpty || entityId.isEmpty) continue;
      globalDays.add(dateKey);
      (daysByEntity[entityId] ??= <String>{}).add(dateKey);
      countByEntity[entityId] = (countByEntity[entityId] ?? 0) + 1;
    }

    final byEntityId = <String, EntityDataMaturity>{
      for (final entry in daysByEntity.entries)
        entry.key: _entityMaturity(
          distinctActiveDays: entry.value.length,
          eventCount: countByEntity[entry.key] ?? 0,
        ),
    };

    return DataMaturitySnapshot(
      global: _globalMaturity(activeDays: globalDays.length),
      byEntityId: byEntityId,
    );
  }

  static EntityDataMaturity _entityMaturity({
    required int distinctActiveDays,
    required int eventCount,
  }) {
    final DataMaturityStage stage;
    if (distinctActiveDays < kEntityMinActiveDays ||
        eventCount < kEntityMinEvents) {
      stage = DataMaturityStage.observing;
    } else if (distinctActiveDays < kEntityEstablishedActiveDays) {
      stage = DataMaturityStage.calibrating;
    } else {
      stage = DataMaturityStage.established;
    }
    return EntityDataMaturity(
      stage: stage,
      distinctActiveDays: distinctActiveDays,
      eventCount: eventCount,
    );
  }

  static GlobalDataMaturity _globalMaturity({required int activeDays}) {
    final DataMaturityStage stage;
    if (activeDays < kGlobalMinActiveDays) {
      stage = DataMaturityStage.observing;
    } else if (activeDays < kGlobalEstablishedActiveDays) {
      stage = DataMaturityStage.calibrating;
    } else {
      stage = DataMaturityStage.established;
    }
    return GlobalDataMaturity(stage: stage, activeDaysObserved: activeDays);
  }
}

final dataMaturityEvaluatorProvider = Provider<DataMaturityEvaluator>((ref) {
  return DataMaturityEvaluator(
    analyticsRepository: ref.read(analyticsRepositoryProvider),
  );
});
