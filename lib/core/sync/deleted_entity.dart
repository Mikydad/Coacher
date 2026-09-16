/// A replicated deletion record (pre-launch audit H15).
///
/// Hard deletes + an upsert-only pull meant a task deleted offline came back
/// if the pull read its old remote doc before the queued delete landed, and
/// a deletion made on another device never arrived at all. The tombstone is
/// the durable, replicated statement "type:id was deleted at T"; the pull
/// applies it locally and refuses to upsert a remote row whose
/// `updatedAtMs` is not newer than T (an edit AFTER the delete is a
/// deliberate resurrection and wins).
class DeletedEntity {
  const DeletedEntity({
    required this.entityType,
    required this.entityId,
    required this.deletedAtMs,
  });

  /// `routine` | `block` | `task` (any entity type with an id).
  final String entityType;
  final String entityId;
  final int deletedAtMs;

  /// LWW field; identical to [deletedAtMs] — tombstones are immutable.
  int get updatedAtMs => deletedAtMs;

  /// Isar unique key + Firestore document id stem.
  String get key => '$entityType:$entityId';

  /// Firestore document id (`:` is legal but reads badly in the console).
  String get docId => '${entityType}_$entityId';

  /// Keep tombstones long enough for a device that stays offline for a
  /// month to still learn about the deletion when it reconnects.
  static const Duration retention = Duration(days: 30);

  Map<String, dynamic> toMap() => {
    'entityType': entityType,
    'entityId': entityId,
    'deletedAtMs': deletedAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static DeletedEntity? fromMap(Map<String, dynamic> map) {
    final type = map['entityType'];
    final id = map['entityId'];
    final at = (map['deletedAtMs'] as num?)?.toInt() ??
        (map['updatedAtMs'] as num?)?.toInt();
    if (type is! String || type.isEmpty || id is! String || id.isEmpty) {
      return null;
    }
    if (at == null || at <= 0) return null;
    return DeletedEntity(entityType: type, entityId: id, deletedAtMs: at);
  }

  /// Whether an incoming remote row is superseded by this tombstone.
  bool supersedes(int incomingUpdatedAtMs) => deletedAtMs >= incomingUpdatedAtMs;
}
