import '../../../../core/validation/model_validators.dart';

/// What kind of knowledge a fact is (PRD §5.1).
enum MemoryFactKind {
  /// Stable truth about the user's life ("has a sister named Sarah").
  semanticFact,

  /// Likes/dislikes/styles ("prefers morning workouts").
  preference,

  /// Behavioral regularity ("usually skips Friday evening tasks").
  learnedPattern,

  /// Distilled session summary — the summarize-then-purge output.
  episodicSummary,

  /// A commitment mentioned in passing, not yet an intention.
  promiseNote,

  /// Standing understanding ("wants to reconnect with college friends") —
  /// generates zero notifications until an opportunity appears.
  observation,
}

MemoryFactKind memoryFactKindFromStorage(String? raw) {
  for (final v in MemoryFactKind.values) {
    if (v.name == raw) return v;
  }
  return MemoryFactKind.semanticFact;
}

/// How a piece of knowledge entered the system — THE load-bearing column
/// (settled: Q2 — inferred memories are labeled, not confirm-gated).
///
/// - [userStated]: extraction with verbatim-quote verification; asserted
///   as fact. A fact claiming this without a matching quote is demoted to
///   [aiInferred] before it is saved.
/// - [userConfirmed]: an inferred fact the user tapped ✓ Correct on (or
///   edited); asserted as fact.
/// - [derivedDeterministic]: written ONLY by the Layer-1/2 pattern engine —
///   no LLM in the loop; asserted as observed pattern.
/// - [aiInferred]: auto-saved silently but always labeled "Inferred";
///   hedged in conversation, advisory-only in scheduling, corroborated or
///   decayed by suggestion responses.
enum MemoryProvenance { userStated, userConfirmed, derivedDeterministic, aiInferred }

MemoryProvenance memoryProvenanceFromStorage(String? raw) {
  for (final v in MemoryProvenance.values) {
    if (v.name == raw) return v;
  }
  // Unknown provenance is treated as the weakest class — never promote by
  // accident.
  return MemoryProvenance.aiInferred;
}

/// One remembered thing about the user. Fully synced entity: Isar is the
/// source of truth, replication via the outbox, LWW on [updatedAtMs].
/// Deletion/deactivation is a soft tombstone ([active] = false).
class MemoryFact {
  const MemoryFact({
    required this.id,
    required this.kind,
    required this.content,
    this.structuredJson,
    this.personId,
    required this.provenance,
    this.confidence = 0.7,
    this.sourceQuote,
    this.sourceSessionId,
    this.lastReferencedAtMs,
    this.contradictionCount = 0,
    this.active = true,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  /// StableId (`memfact_...`), client-generated.
  final String id;

  final MemoryFactKind kind;

  /// Human-readable statement, ≤200 chars ([validate] enforces).
  final String content;

  /// Optional machine shape, e.g. `{"preferredTimeBlock":"morning"}` —
  /// what the OpportunityPlanner reads as an advisory hint.
  final String? structuredJson;

  /// Link to an IsarPerson when the fact is about someone.
  final String? personId;

  final MemoryProvenance provenance;

  /// 0..1. Starts at extraction confidence; corroborated or decayed by
  /// suggestion responses (§4.4) and contradictions.
  final double confidence;

  /// Verbatim transcript quote backing a [MemoryProvenance.userStated]
  /// fact. The extraction pipeline verifies it string-matches the
  /// transcript before the strong provenance is allowed to stand.
  final String? sourceQuote;

  final String? sourceSessionId;

  /// Stamped whenever the fact is injected into a Coach payload — powers
  /// relevance ranking and eventual decay.
  final int? lastReferencedAtMs;

  /// Two contradictions deactivate the fact (§5.2).
  final int contradictionCount;

  /// Soft tombstone for LWW sync: false = deleted/deactivated.
  final bool active;

  final int createdAtMs;
  final int updatedAtMs;

  /// Facts the Coach may assert vs. must hedge.
  bool get isAsserted =>
      provenance == MemoryProvenance.userStated ||
      provenance == MemoryProvenance.userConfirmed;

  void validate() {
    ModelValidators.requireNotBlank(id, 'memoryFact.id');
    ModelValidators.requireNotBlank(content, 'memoryFact.content');
    if (content.length > 200) {
      throw ArgumentError('memoryFact.content must be ≤200 chars');
    }
    if (confidence < 0 || confidence > 1) {
      throw ArgumentError('memoryFact.confidence must be within 0..1');
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'kind': kind.name,
    'content': content,
    'structuredJson': structuredJson,
    'personId': personId,
    'provenance': provenance.name,
    'confidence': confidence,
    'sourceQuote': sourceQuote,
    'sourceSessionId': sourceSessionId,
    'lastReferencedAtMs': lastReferencedAtMs,
    'contradictionCount': contradictionCount,
    'active': active,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static MemoryFact fromMap(Map<String, dynamic> map) {
    return MemoryFact(
      id: map['id'] as String? ?? '',
      kind: memoryFactKindFromStorage(map['kind'] as String?),
      content: map['content'] as String? ?? '',
      structuredJson: map['structuredJson'] as String?,
      personId: map['personId'] as String?,
      provenance: memoryProvenanceFromStorage(map['provenance'] as String?),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.7,
      sourceQuote: map['sourceQuote'] as String?,
      sourceSessionId: map['sourceSessionId'] as String?,
      lastReferencedAtMs: (map['lastReferencedAtMs'] as num?)?.toInt(),
      contradictionCount: (map['contradictionCount'] as num?)?.toInt() ?? 0,
      active: map['active'] as bool? ?? true,
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  MemoryFact copyWith({
    MemoryFactKind? kind,
    String? content,
    String? structuredJson,
    String? personId,
    MemoryProvenance? provenance,
    double? confidence,
    String? sourceQuote,
    String? sourceSessionId,
    int? lastReferencedAtMs,
    int? contradictionCount,
    bool? active,
    int? updatedAtMs,
  }) {
    return MemoryFact(
      id: id,
      kind: kind ?? this.kind,
      content: content ?? this.content,
      structuredJson: structuredJson ?? this.structuredJson,
      personId: personId ?? this.personId,
      provenance: provenance ?? this.provenance,
      confidence: confidence ?? this.confidence,
      sourceQuote: sourceQuote ?? this.sourceQuote,
      sourceSessionId: sourceSessionId ?? this.sourceSessionId,
      lastReferencedAtMs: lastReferencedAtMs ?? this.lastReferencedAtMs,
      contradictionCount: contradictionCount ?? this.contradictionCount,
      active: active ?? this.active,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}
