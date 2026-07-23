import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../analytics/application/insight_generation_recompute_service.dart';
import '../../intentions/application/intentions_providers.dart';
import '../data/memory_facts_repository.dart';
import '../data/memory_session_state_repository.dart';
import '../data/people_repository.dart';
import '../domain/models/memory_fact.dart';
import '../domain/models/person.dart';
import 'memory_extraction_service.dart';
import 'relationship_care_service.dart';

final memoryFactsRepositoryProvider = Provider<MemoryFactsRepository>(
  (ref) => MemoryFactsRepository(),
);

final peopleRepositoryProvider = Provider<PeopleRepository>(
  (ref) => PeopleRepository(),
);

final memorySessionStateRepositoryProvider =
    Provider<MemorySessionStateRepository>(
      (ref) => MemorySessionStateRepository(),
    );

/// All live memory facts, newest-updated first. UI reads this — the local
/// write IS the update.
final memoryFactsStreamProvider = StreamProvider<List<MemoryFact>>((ref) {
  return ref.watch(memoryFactsRepositoryProvider).watchFacts();
});

/// All live people, newest-updated first.
final peopleStreamProvider = StreamProvider<List<Person>>((ref) {
  return ref.watch(peopleRepositoryProvider).watchPeople();
});

/// Post-conversation extraction + summarize-then-purge driver.
final memoryExtractionServiceProvider = Provider<MemoryExtractionService>(
  (ref) => MemoryExtractionService(
    history: ref.read(aiInteractionHistoryRepositoryProvider),
    facts: ref.read(memoryFactsRepositoryProvider),
    people: ref.read(peopleRepositoryProvider),
    sessionState: ref.read(memorySessionStateRepositoryProvider),
    intentions: ref.read(intentionsRepositoryProvider),
  ),
);

/// Deterministic relationship-care pattern (humanizing Phase 2) — driven
/// from the unified recompute graph, throttled internally.
final relationshipCareServiceProvider = Provider<RelationshipCareService>(
  (ref) => RelationshipCareService(
    people: ref.read(peopleRepositoryProvider),
    intentions: ref.read(intentionsRepositoryProvider),
    orchestrator: ref.read(insightGenerationOrchestratorProvider),
    insightCache: ref.read(insightCacheRepositoryProvider),
  ),
);

/// Facts by kind — the "What SidePal knows" tabs and the payload assembler
/// both slice this way.
final memoryFactsByKindProvider =
    Provider<Map<MemoryFactKind, List<MemoryFact>>>((ref) {
      final all = ref.watch(memoryFactsStreamProvider).valueOrNull ?? const [];
      final byKind = <MemoryFactKind, List<MemoryFact>>{};
      for (final f in all) {
        byKind.putIfAbsent(f.kind, () => []).add(f);
      }
      return byKind;
    });
