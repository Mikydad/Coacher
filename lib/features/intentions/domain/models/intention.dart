import '../../../../core/validation/model_validators.dart';

/// Lifecycle of an intention (PRD §4.1).
///
/// `dormant` is "standing understanding": captured knowledge that generates
/// zero notifications until an opportunity appears or the user engages it.
enum IntentionStatus { open, dormant, nudged, done, dismissed, expired }

IntentionStatus intentionStatusFromStorage(String? raw) {
  for (final v in IntentionStatus.values) {
    if (v.name == raw) return v;
  }
  return IntentionStatus.open;
}

enum IntentionImportance { low, normal, high }

IntentionImportance intentionImportanceFromStorage(String? raw) {
  for (final v in IntentionImportance.values) {
    if (v.name == raw) return v;
  }
  return IntentionImportance.normal;
}

/// A promise the user stated ("call my cousin tomorrow") with a soft deadline
/// window. SidePal picks the delivery moment; the user never sets a clock time
/// unless they pin one ([pinnedAtMs] opts out of smart timing entirely).
///
/// Fully synced entity: Isar is the source of truth, replication happens via
/// the outbox, LWW on [updatedAtMs]. Deletion is a soft tombstone ([active] =
/// false) so a delete on one device wins over a stale edit from another.
class Intention {
  const Intention({
    required this.id,
    required this.title,
    required this.rawUtterance,
    this.personId,
    required this.windowStartMs,
    required this.windowEndMs,
    required this.estimatedMinutes,
    this.importance = IntentionImportance.normal,
    this.activityTags = const [],
    this.aiHintsJson,
    this.dependsOnText,
    this.anchorEntityId,
    this.locationHintText,
    this.status = IntentionStatus.open,
    this.pinnedAtMs,
    this.completedAtMs,
    this.nudgeCount = 0,
    this.snoozeCount = 0,
    this.active = true,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  /// StableId (`intention_...`), client-generated.
  final String id;

  /// Normalized title ("Call cousin Sara").
  final String title;

  /// Verbatim capture — provenance and future re-parse.
  final String rawUtterance;

  /// Link to an IsarPerson once people exist (Phase 2). Carried now.
  final String? personId;

  /// Soft deadline window. Waking-window defaults: "tomorrow" → 08:00–21:00.
  final int windowStartMs;
  final int windowEndMs;

  /// Duration estimate in minutes (parsed or defaulted by kind).
  final int estimatedMinutes;

  final IntentionImportance importance;

  /// Compatibility tags, e.g. `[call, handsFree]`. May be AI-proposed;
  /// the engine validates before they influence scoring.
  final List<String> activityTags;

  /// Persisted LLM recommendations (advisory scoring inputs only,
  /// provenance-tagged). Never read on the delivery path as a live call.
  final String? aiHintsJson;

  /// "Before visiting parents" — dormant until resolvable.
  final String? dependsOnText;
  final String? anchorEntityId;

  /// Carried but unused until a location phase.
  final String? locationHintText;

  final IntentionStatus status;

  /// User-chosen exact time — opts out of smart timing entirely.
  final int? pinnedAtMs;

  final int? completedAtMs;
  final int nudgeCount;
  final int snoozeCount;

  /// Soft tombstone for LWW sync: false = deleted.
  final bool active;

  final int createdAtMs;
  final int updatedAtMs;

  bool get isPinned => pinnedAtMs != null;

  /// Open intentions are the planner's input; dormant ones wait silently.
  bool get isPlannable => active && status == IntentionStatus.open;

  void validate() {
    ModelValidators.requireNotBlank(id, 'intention.id');
    ModelValidators.requireNotBlank(title, 'intention.title');
    if (windowEndMs <= windowStartMs) {
      throw ArgumentError(
        'intention.windowEndMs must be after windowStartMs',
      );
    }
    ModelValidators.requireRange(
      value: estimatedMinutes,
      min: 1,
      max: 1440,
      fieldName: 'intention.estimatedMinutes',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'rawUtterance': rawUtterance,
    'personId': personId,
    'windowStartMs': windowStartMs,
    'windowEndMs': windowEndMs,
    'estimatedMinutes': estimatedMinutes,
    'importance': importance.name,
    'activityTags': activityTags,
    'aiHintsJson': aiHintsJson,
    'dependsOnText': dependsOnText,
    'anchorEntityId': anchorEntityId,
    'locationHintText': locationHintText,
    'status': status.name,
    'pinnedAtMs': pinnedAtMs,
    'completedAtMs': completedAtMs,
    'nudgeCount': nudgeCount,
    'snoozeCount': snoozeCount,
    'active': active,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static Intention fromMap(Map<String, dynamic> map) {
    return Intention(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      rawUtterance: map['rawUtterance'] as String? ?? '',
      personId: map['personId'] as String?,
      windowStartMs: (map['windowStartMs'] as num?)?.toInt() ?? 0,
      windowEndMs: (map['windowEndMs'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 15,
      importance: intentionImportanceFromStorage(map['importance'] as String?),
      activityTags:
          (map['activityTags'] as List?)?.cast<String>() ?? const [],
      aiHintsJson: map['aiHintsJson'] as String?,
      dependsOnText: map['dependsOnText'] as String?,
      anchorEntityId: map['anchorEntityId'] as String?,
      locationHintText: map['locationHintText'] as String?,
      status: intentionStatusFromStorage(map['status'] as String?),
      pinnedAtMs: (map['pinnedAtMs'] as num?)?.toInt(),
      completedAtMs: (map['completedAtMs'] as num?)?.toInt(),
      nudgeCount: (map['nudgeCount'] as num?)?.toInt() ?? 0,
      snoozeCount: (map['snoozeCount'] as num?)?.toInt() ?? 0,
      active: map['active'] as bool? ?? true,
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  Intention copyWith({
    String? title,
    String? rawUtterance,
    String? personId,
    int? windowStartMs,
    int? windowEndMs,
    int? estimatedMinutes,
    IntentionImportance? importance,
    List<String>? activityTags,
    String? aiHintsJson,
    String? dependsOnText,
    String? anchorEntityId,
    String? locationHintText,
    IntentionStatus? status,
    int? pinnedAtMs,
    int? completedAtMs,
    int? nudgeCount,
    int? snoozeCount,
    bool? active,
    int? updatedAtMs,
  }) {
    return Intention(
      id: id,
      title: title ?? this.title,
      rawUtterance: rawUtterance ?? this.rawUtterance,
      personId: personId ?? this.personId,
      windowStartMs: windowStartMs ?? this.windowStartMs,
      windowEndMs: windowEndMs ?? this.windowEndMs,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      importance: importance ?? this.importance,
      activityTags: activityTags ?? this.activityTags,
      aiHintsJson: aiHintsJson ?? this.aiHintsJson,
      dependsOnText: dependsOnText ?? this.dependsOnText,
      anchorEntityId: anchorEntityId ?? this.anchorEntityId,
      locationHintText: locationHintText ?? this.locationHintText,
      status: status ?? this.status,
      pinnedAtMs: pinnedAtMs ?? this.pinnedAtMs,
      completedAtMs: completedAtMs ?? this.completedAtMs,
      nudgeCount: nudgeCount ?? this.nudgeCount,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      active: active ?? this.active,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}
