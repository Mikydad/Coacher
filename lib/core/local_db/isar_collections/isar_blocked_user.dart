import 'package:isar_community/isar.dart';

part 'isar_blocked_user.g.dart';

/// A user this account has blocked (Apple UGC requirement; accountability
/// PRD P-8). User-own data: Isar first, outbox to
/// `users/{uid}/blocked/{blockedUid}`, pulled back by [RemoteIsarMerge].
/// Blocking hides the blocked user's feed posts and stake reveals from ME —
/// it never affects what others see.
@collection
class IsarBlockedUser {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String blockedUid;

  @Index()
  late int updatedAtMs;

  late int createdAtMs;

  /// True = blocked; false = unblocked (kept as a row for LWW sync instead
  /// of a delete, so unblock wins over a stale block from another device).
  late bool active;
}
