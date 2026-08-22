import '../../../../core/validation/model_validators.dart';

import 'memory_fact.dart' show MemoryProvenance, memoryProvenanceFromStorage;

/// Normalized relationship class — what deterministic patterns key on
/// ("no interaction with a `family` person in N weeks"). The free-form
/// [Person.relationship] keeps the user's own words.
enum PersonKind { family, friend, partner, work, community, other }

PersonKind personKindFromStorage(String? raw) {
  for (final v in PersonKind.values) {
    if (v.name == raw) return v;
  }
  return PersonKind.other;
}

/// Best-effort normalization of a free-form relationship phrase.
/// Deterministic and conservative: anything unrecognized is [PersonKind.other].
PersonKind normalizeRelationship(String? freeForm) {
  if (freeForm == null) return PersonKind.other;
  final r = freeForm.toLowerCase().trim();
  const family = {
    'mom',
    'mother',
    'dad',
    'father',
    'parent',
    'sister',
    'brother',
    'sibling',
    'son',
    'daughter',
    'child',
    'kid',
    'grandma',
    'grandmother',
    'grandpa',
    'grandfather',
    'aunt',
    'uncle',
    'cousin',
    'nephew',
    'niece',
    'in-law',
    'family',
  };
  const partner = {
    'wife',
    'husband',
    'spouse',
    'partner',
    'girlfriend',
    'boyfriend',
    'fiancée',
    'fiancé',
    'fiancee',
    'fiance',
  };
  const work = {
    'boss',
    'manager',
    'colleague',
    'coworker',
    'co-worker',
    'cofounder',
    'co-founder',
    'client',
    'mentor',
    'mentee',
    'teammate',
    'assistant',
    'employee',
    'investor',
    'business partner',
  };
  const community = {
    'neighbor',
    'neighbour',
    'coach',
    'trainer',
    'teacher',
    'professor',
    'classmate',
    'roommate',
    'flatmate',
    'teammate',
  };
  bool matches(Set<String> kinds) => kinds.any((k) => r == k || r.contains(k));
  if (matches(family)) return PersonKind.family;
  if (matches(partner)) return PersonKind.partner;
  if (matches(work)) return PersonKind.work;
  if (matches(community)) return PersonKind.community;
  if (r.contains('friend')) return PersonKind.friend;
  return PersonKind.other;
}

/// Someone in the user's life (PRD §5.5 — "know WHO people are, not manage
/// Person #17"). Fully synced entity: outbox + pull, LWW on [updatedAtMs],
/// soft tombstone [active]. NEVER synced to any external contacts API.
class Person {
  const Person({
    required this.id,
    required this.displayName,
    this.relationship,
    this.kind = PersonKind.other,
    this.aliases = const [],
    this.notesJson,
    required this.provenance,
    this.lastInteractionAtMs,
    this.active = true,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  /// StableId (`person_...`), client-generated.
  final String id;

  /// "Sarah".
  final String displayName;

  /// Free-form, the user's words: "my sister", "cofounder".
  final String? relationship;

  /// Normalized class for deterministic patterns.
  final PersonKind kind;

  /// Alternate references: "my sister", "Sar".
  final List<String> aliases;

  /// Small structured facts stated by the user (birthday, timezone) —
  /// never scraped from anywhere.
  final String? notesJson;

  /// Same enum as memory facts — an inferred relationship is labeled.
  final MemoryProvenance provenance;

  /// Derived DETERMINISTICALLY from completed intentions/conversations
  /// referencing this person — never LLM-estimated.
  final int? lastInteractionAtMs;

  /// Soft tombstone for LWW sync: false = deleted.
  final bool active;

  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'person.id');
    ModelValidators.requireNotBlank(displayName, 'person.displayName');
    if (displayName.length > 80) {
      throw ArgumentError('person.displayName must be ≤80 chars');
    }
  }

  /// Whether [text] plausibly refers to this person (name or alias,
  /// case-insensitive). Used to link intentions and derive
  /// [lastInteractionAtMs].
  bool matchesReference(String text) {
    final lower = text.toLowerCase();
    if (lower.contains(displayName.toLowerCase())) return true;
    return aliases.any(
      (a) => a.trim().isNotEmpty && lower.contains(a.toLowerCase()),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'relationship': relationship,
    'kind': kind.name,
    'aliases': aliases,
    'notesJson': notesJson,
    'provenance': provenance.name,
    'lastInteractionAtMs': lastInteractionAtMs,
    'active': active,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static Person fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      relationship: map['relationship'] as String?,
      kind: personKindFromStorage(map['kind'] as String?),
      aliases: (map['aliases'] as List?)?.cast<String>() ?? const [],
      notesJson: map['notesJson'] as String?,
      provenance: memoryProvenanceFromStorage(map['provenance'] as String?),
      lastInteractionAtMs: (map['lastInteractionAtMs'] as num?)?.toInt(),
      active: map['active'] as bool? ?? true,
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  Person copyWith({
    String? displayName,
    String? relationship,
    PersonKind? kind,
    List<String>? aliases,
    String? notesJson,
    MemoryProvenance? provenance,
    int? lastInteractionAtMs,
    bool? active,
    int? updatedAtMs,
  }) {
    return Person(
      id: id,
      displayName: displayName ?? this.displayName,
      relationship: relationship ?? this.relationship,
      kind: kind ?? this.kind,
      aliases: aliases ?? this.aliases,
      notesJson: notesJson ?? this.notesJson,
      provenance: provenance ?? this.provenance,
      lastInteractionAtMs: lastInteractionAtMs ?? this.lastInteractionAtMs,
      active: active ?? this.active,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}
