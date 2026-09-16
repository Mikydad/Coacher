import 'package:isar_community/isar.dart';

import '../../sync/deleted_entity.dart';

part 'isar_deleted_entity.g.dart';

/// Deletion tombstone (pre-launch audit H15).
///
/// Planning entities (routines / blocks / tasks) are hard-deleted locally so
/// the many Isar readers stay untouched; this side table remembers WHAT was
/// deleted and WHEN so that (a) a remote pull racing the queued Firestore
/// delete cannot resurrect the row, and (b) a deletion made on another
/// device converges here — the pull applies remote tombstones before it
/// upserts anything. Synced like any user-own entity: Isar → outbox →
/// `users/{uid}/deletedEntities/{type}_{id}` → pulled back by
/// [RemoteIsarMerge]. Rows older than [DeletedEntity.retention] are purged.
@collection
class IsarDeletedEntity {
  Id id = Isar.autoIncrement;

  /// `${entityType}:${entityId}` — one tombstone per entity.
  @Index(unique: true)
  late String entityKey;

  @Index()
  late String entityType;

  late String entityId;

  @Index()
  late int deletedAtMs;

  /// LWW field (== deletedAtMs; the tombstone never changes after creation).
  late int updatedAtMs;

  static IsarDeletedEntity fromDomain(DeletedEntity d) => IsarDeletedEntity()
    ..entityKey = d.key
    ..entityType = d.entityType
    ..entityId = d.entityId
    ..deletedAtMs = d.deletedAtMs
    ..updatedAtMs = d.updatedAtMs;

  DeletedEntity toDomain() => DeletedEntity(
    entityType: entityType,
    entityId: entityId,
    deletedAtMs: deletedAtMs,
  );
}
