import 'package:isar_community/isar.dart';

import '../../../features/memory/domain/models/memory_fact.dart';

part 'isar_memory_fact.g.dart';

/// Synced memory fact row (PRD Phase 2, §5.1). Soft tombstone via [active]
/// so a delete/deactivate on one device wins over a stale edit (LWW).
@collection
class IsarMemoryFact {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String factId;

  @Index()
  late int updatedAtMs;

  @Index()
  late String kindStorage;

  late String content;
  String? structuredJson;

  @Index()
  String? personId;

  /// The load-bearing column — see [MemoryProvenance].
  late String provenanceStorage;

  late double confidence;
  String? sourceQuote;
  String? sourceSessionId;
  int? lastReferencedAtMs;
  late int contradictionCount;
  late bool active;
  late int createdAtMs;

  static IsarMemoryFact fromDomain(MemoryFact f) {
    return IsarMemoryFact()
      ..factId = f.id
      ..updatedAtMs = f.updatedAtMs
      ..kindStorage = f.kind.name
      ..content = f.content
      ..structuredJson = f.structuredJson
      ..personId = f.personId
      ..provenanceStorage = f.provenance.name
      ..confidence = f.confidence
      ..sourceQuote = f.sourceQuote
      ..sourceSessionId = f.sourceSessionId
      ..lastReferencedAtMs = f.lastReferencedAtMs
      ..contradictionCount = f.contradictionCount
      ..active = f.active
      ..createdAtMs = f.createdAtMs;
  }

  MemoryFact toDomain() {
    return MemoryFact(
      id: factId,
      kind: memoryFactKindFromStorage(kindStorage),
      content: content,
      structuredJson: structuredJson,
      personId: personId,
      provenance: memoryProvenanceFromStorage(provenanceStorage),
      confidence: confidence,
      sourceQuote: sourceQuote,
      sourceSessionId: sourceSessionId,
      lastReferencedAtMs: lastReferencedAtMs,
      contradictionCount: contradictionCount,
      active: active,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
