import 'package:shared_preferences/shared_preferences.dart';

/// Prefs-backed per-collection sync cursors: the max remote `updatedAtMs`
/// successfully merged so far. Lets [RemoteIsarMerge] pull only newer docs
/// instead of re-reading whole collections on every sync (AUDIT §7 P1).
///
/// Invariants:
/// - Advance only after a fully successful pull, and only to the max
///   `updatedAtMs` actually SEEN in remote docs — never `DateTime.now()`,
///   because client clocks differ across devices.
/// - Cursors never move backwards ([advance] is monotonic).
/// - Cursor pulls cannot observe remote deletions; the merge never deletes
///   locally either (LWW upsert only), so behavior is unchanged. A force
///   pull (cursor ignored) remains the full-reconcile escape hatch.
/// - [clearAll] must run on account switch / local wipe so the next pull
///   is a full one (see AuthSessionPolicy.clearLocalSession).
class SyncCursorStore {
  const SyncCursorStore();

  static const String _prefix = 'sync_cursor_v1_';

  Future<int> read(String collection) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$collection') ?? 0;
  }

  /// Advances the cursor for [collection]; ignores values that would move
  /// it backwards or are non-positive.
  Future<void> advance(String collection, int maxUpdatedAtMs) async {
    if (maxUpdatedAtMs <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$collection';
    final current = prefs.getInt(key) ?? 0;
    if (maxUpdatedAtMs > current) {
      await prefs.setInt(key, maxUpdatedAtMs);
    }
  }

  /// Removes every sync cursor (next pull is a full pull).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
