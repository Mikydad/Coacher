import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_activity_event.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/models/activity_event.dart';

/// Local-first activity events: Isar is the source of truth, replication
/// happens through the outbox (push) and RemoteIsarMerge (pull, LWW on
/// updatedAtMs). Deletion is a soft tombstone — never `outboxDelete`, so
/// the delete wins LWW on every device.
///
/// SidePal doesn't track your time for you. It makes it effortless for you
/// to record your time, then helps you see what you actually did with it.
class ActivityEventRepository {
  ActivityEventRepository({int Function()? now}) : _now = now ?? _wallClock;

  static int _wallClock() => DateTime.now().millisecondsSinceEpoch;

  final int Function() _now;

  Isar get _isar => OfflineStore.instance.isar!;

  static const String _entityType = 'activity_event';

  /// One calendar day's live events, sorted by start. The timeline.
  Stream<List<ActivityEvent>> watchDay(String dateKey) {
    return _isar.isarActivityEvents
        .filter()
        .dateKeyEqualTo(dateKey)
        .and()
        .activeEqualTo(true)
        .sortByStartedAtMs()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList(growable: false));
  }

  Future<List<ActivityEvent>> fetchDayOnce(String dateKey) async {
    final rows = await _isar.isarActivityEvents
        .filter()
        .dateKeyEqualTo(dateKey)
        .and()
        .activeEqualTo(true)
        .sortByStartedAtMs()
        .findAll();
    return rows.map((e) => e.toDomain()).toList(growable: false);
  }

  /// Live events started at or after [sinceMs], newest first — the
  /// recent-chips window.
  Stream<List<ActivityEvent>> watchRecentSince(int sinceMs) {
    return _isar.isarActivityEvents
        .filter()
        .startedAtMsGreaterThan(sinceMs, include: true)
        .and()
        .activeEqualTo(true)
        .sortByStartedAtMsDesc()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList(growable: false));
  }

  /// The most recently started live event, any day — drives the Home
  /// pill's "Scrolling · since 10:03 PM" copy.
  Stream<ActivityEvent?> watchLatest() {
    return _isar.isarActivityEvents
        .filter()
        .activeEqualTo(true)
        .sortByStartedAtMsDesc()
        .limit(1)
        .watch(fireImmediately: true)
        .map((rows) => rows.isEmpty ? null : rows.first.toDomain());
  }

  Future<ActivityEvent?> fetchLatestOnce() async {
    final row = await _isar.isarActivityEvents
        .filter()
        .activeEqualTo(true)
        .sortByStartedAtMsDesc()
        .findFirst();
    return row?.toDomain();
  }

  Future<ActivityEvent?> getById(String id) async {
    final row = await _isar.isarActivityEvents
        .filter()
        .eventIdEqualTo(id)
        .findFirst();
    return row?.toDomain();
  }

  /// Validate → stamp `updatedAtMs` → Isar → outbox. Returns the stored
  /// event. Tombstones pass through unchanged apart from the stamp.
  Future<ActivityEvent> upsert(ActivityEvent event) async {
    final stamped = event.copyWith(updatedAtMs: _now());
    if (stamped.active) stamped.validate();
    await _isar.writeTxn(() async {
      await _isar.isarActivityEvents.putByEventId(
        IsarActivityEvent.fromDomain(stamped),
      );
    });
    await outboxUpsert(
      entityType: _entityType,
      documentPath: FirestorePaths.activityEventDocument(stamped.id),
      payload: stamped.toMap(),
    );
    return stamped;
  }

  /// Soft delete: the tombstone row stays locally and replicates so the
  /// delete wins LWW against stale edits from other devices.
  Future<void> softDelete(String id) async {
    final current = await getById(id);
    if (current == null || !current.active) return;
    await upsert(current.copyWith(active: false));
  }

  /// Timer stop (and the edit sheet's End row). No-op when the event is
  /// gone or the end would not be after the start.
  Future<ActivityEvent?> setEnd(String id, int endedAtMs) async {
    final current = await getById(id);
    if (current == null || !current.active) return null;
    if (endedAtMs <= current.startedAtMs) return current;
    if (current.endedAtMs == endedAtMs) return current;
    return upsert(current.copyWith(endedAtMs: endedAtMs));
  }
}
