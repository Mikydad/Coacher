import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_direction_entry.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/direction_periods.dart';
import '../domain/models/direction_entry.dart';

/// Local-first Direction store: Isar is the source of truth, replication
/// happens through the outbox (push) and RemoteIsarMerge (pull, LWW on
/// updatedAtMs). There is no delete path — clearing writes `''` and the row
/// stays as history.
///
/// Direction is not something SidePal asks the user to accomplish. It is
/// something SidePal remembers while helping them.
class DirectionRepository {
  DirectionRepository({int Function()? now}) : _now = now ?? _wallClock;

  static int _wallClock() => DateTime.now().millisecondsSinceEpoch;

  final int Function() _now;

  Isar get _isar => OfflineStore.instance.isar!;

  /// Every row, history included, newest write first. UI and AI derive the
  /// current slots from this — the local write IS the update.
  Stream<List<DirectionEntry>> watchAll() {
    return _isar.isarDirectionEntrys
        .where()
        .sortByUpdatedAtMsDesc()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList(growable: false));
  }

  Future<List<DirectionEntry>> fetchAllOnce() async {
    final rows = await _isar.isarDirectionEntrys
        .where()
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows.map((e) => e.toDomain()).toList(growable: false);
  }

  Future<DirectionEntry?> get(DirectionHorizon horizon, String periodKey) async {
    final row = await _isar.isarDirectionEntrys
        .filter()
        .entryIdEqualTo(directionEntryId(horizon, periodKey))
        .findFirst();
    return row?.toDomain();
  }

  /// Upsert-or-create the entry for [period] with [text].
  ///
  /// **No-op when the trimmed text equals what is already stored** (absent
  /// counts as `''`). This is load-bearing: the page autosaves on a
  /// debounce + blur + dispose, and without this guard every blur would
  /// bump `updatedAtMs` and enqueue an outbox op for nothing.
  ///
  /// Returns the stored entry (existing one when nothing changed; null when
  /// there was nothing stored and the text is empty — no empty rows are
  /// created).
  Future<DirectionEntry?> setText(DirectionPeriod period, String text) async {
    final trimmed = text.trim();
    final existing = await get(period.horizon, period.key);
    if (existing == null && trimmed.isEmpty) return null;
    if (existing != null && existing.text == trimmed) return existing;

    final entry = DirectionEntry.forPeriod(
      period,
      text: trimmed,
      nowMs: _now(),
      createdAtMs: existing?.createdAtMs,
    );
    entry.validate();
    await _isar.writeTxn(() async {
      await _isar.isarDirectionEntrys.putByEntryId(
        IsarDirectionEntry.fromDomain(entry),
      );
    });
    await outboxUpsert(
      entityType: 'direction',
      documentPath: FirestorePaths.directionDocument(entry.id),
      payload: entry.toMap(),
    );
    return entry;
  }
}
