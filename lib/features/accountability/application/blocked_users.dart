import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_blocked_user.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/outbox_writer.dart';

/// Block / unblock users (Apple UGC bar; accountability PRD P-8).
/// User-own data: instant Isar write, outbox replication, LWW on
/// `updatedAtMs` — works in airplane mode like everything else.
class BlockedUsersRepository {
  BlockedUsersRepository();

  Isar get _isar => OfflineStore.instance.isar!;

  Stream<Set<String>> watchBlockedUids() {
    return _isar.isarBlockedUsers
        .where()
        .watch(fireImmediately: true)
        .map((rows) => {
              for (final r in rows)
                if (r.active) r.blockedUid,
            });
  }

  Future<void> setBlocked(String blockedUid, {required bool blocked}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await _isar.isarBlockedUsers
        .filter()
        .blockedUidEqualTo(blockedUid)
        .findFirst();
    final row = IsarBlockedUser()
      ..blockedUid = blockedUid
      ..active = blocked
      ..createdAtMs = existing?.createdAtMs ?? now
      ..updatedAtMs = now;
    await _isar.writeTxn(() async {
      await _isar.isarBlockedUsers.putByBlockedUid(row);
    });
    await outboxUpsert(
      entityType: 'blockedUser',
      documentPath:
          '${FirestorePaths.userRoot}/blocked/$blockedUid',
      payload: {
        'blockedUid': blockedUid,
        'active': blocked,
        'createdAtMs': row.createdAtMs,
        'updatedAtMs': now,
      },
    );
  }
}

final blockedUsersRepositoryProvider = Provider<BlockedUsersRepository>(
  (ref) => BlockedUsersRepository(),
);

/// Uids this account has blocked — feed/reveal surfaces filter on it.
final blockedUidsProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(blockedUsersRepositoryProvider).watchBlockedUids();
});
