import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../analytics/application/insight_generation_recompute_service.dart';
import '../../intentions/application/intentions_providers.dart';
import '../../memory/application/memory_providers.dart';
import 'thinking_loop_service.dart';

/// The Thinking Loop (humanizing Phase 7) — one budgeted reflection pass
/// per device-day, driven from bootstrap and app resume.
final thinkingLoopServiceProvider = Provider<ThinkingLoopService>(
  (ref) => ThinkingLoopService(
    facts: ref.read(memoryFactsRepositoryProvider),
    people: ref.read(peopleRepositoryProvider),
    intentions: ref.read(intentionsRepositoryProvider),
    orchestrator: ref.read(insightGenerationOrchestratorProvider),
    insightCache: ref.read(insightCacheRepositoryProvider),
    // Reminder V2 strategist (FR-R-61): rides this daily pass — aggregates
    // in, day-scoped proposals out, suggestion-only (D7).
    loadReminderAggregates: () => loadReminderStrategyAggregates(ref),
    onReminderProposals: (proposals) => ref
        .read(strategistProposalsStoreProvider)
        .saveForDay(DateKeys.todayKey(), proposals),
  ),
);
