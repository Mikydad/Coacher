import 'package:isar_community/isar.dart';

import '../../../features/direction/domain/direction_periods.dart';
import '../../../features/direction/domain/models/direction_entry.dart';

part 'isar_direction_entry.g.dart';

/// Synced Direction row (PRD/Direction, 2026-09-11). One row per horizon
/// per calendar period; [entryId] is deterministic (`dir_<horizon>_<key>`)
/// so devices converge on one row under LWW. No tombstone: clearing writes
/// an empty [text] and the row stays as history.
@collection
class IsarDirectionEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String entryId;

  @Index()
  late int updatedAtMs;

  /// `year` | `quarter` | `month`.
  @Index()
  late String horizonStorage;

  @Index()
  late String periodKey;

  late String text;
  late int periodStartMs;
  late int periodEndMs;
  late int createdAtMs;

  static IsarDirectionEntry fromDomain(DirectionEntry e) {
    return IsarDirectionEntry()
      ..entryId = e.id
      ..updatedAtMs = e.updatedAtMs
      ..horizonStorage = e.horizon.name
      ..periodKey = e.periodKey
      ..text = e.text
      ..periodStartMs = e.periodStartMs
      ..periodEndMs = e.periodEndMs
      ..createdAtMs = e.createdAtMs;
  }

  DirectionEntry toDomain() {
    return DirectionEntry(
      id: entryId,
      horizon:
          directionHorizonFromStorage(horizonStorage) ??
          DirectionPeriods.parseKey(periodKey)?.horizon ??
          DirectionHorizon.month,
      periodKey: periodKey,
      text: text,
      periodStartMs: periodStartMs,
      periodEndMs: periodEndMs,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
