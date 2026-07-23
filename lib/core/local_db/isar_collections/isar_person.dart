import 'package:isar_community/isar.dart';

import '../../../features/memory/domain/models/memory_fact.dart'
    show memoryProvenanceFromStorage;
import '../../../features/memory/domain/models/person.dart';

part 'isar_person.g.dart';

/// Synced person row (PRD Phase 2, §5.5). Soft tombstone via [active].
/// Never synced to any external contacts API.
@collection
class IsarPerson {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String personId;

  @Index()
  late int updatedAtMs;

  late String displayName;
  String? relationship;

  @Index()
  late String kindStorage;

  late List<String> aliases;
  String? notesJson;
  late String provenanceStorage;
  int? lastInteractionAtMs;
  late bool active;
  late int createdAtMs;

  static IsarPerson fromDomain(Person p) {
    return IsarPerson()
      ..personId = p.id
      ..updatedAtMs = p.updatedAtMs
      ..displayName = p.displayName
      ..relationship = p.relationship
      ..kindStorage = p.kind.name
      ..aliases = p.aliases
      ..notesJson = p.notesJson
      ..provenanceStorage = p.provenance.name
      ..lastInteractionAtMs = p.lastInteractionAtMs
      ..active = p.active
      ..createdAtMs = p.createdAtMs;
  }

  Person toDomain() {
    return Person(
      id: personId,
      displayName: displayName,
      relationship: relationship,
      kind: personKindFromStorage(kindStorage),
      aliases: aliases,
      notesJson: notesJson,
      provenance: memoryProvenanceFromStorage(provenanceStorage),
      lastInteractionAtMs: lastInteractionAtMs,
      active: active,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
