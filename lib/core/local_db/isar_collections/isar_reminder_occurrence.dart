import 'package:isar_community/isar.dart';

import '../../../features/reminders/domain/models/reminder_occurrence.dart';
import '../../../features/reminders/domain/models/reminder_occurrence_enums.dart';

part 'isar_reminder_occurrence.g.dart';

/// Local mirror of `users/{uid}/reminderOccurrences/{id}` — one row per
/// entity per scheduled day, keyed by [occurrenceKey]
/// (`entityKind|entityId|dateKey`), the same composite-key shape as
/// [IsarGoalCheckIn].
///
/// Enums are stored as strings so a row written by a newer client degrades
/// instead of throwing on read.
@collection
class IsarReminderOccurrence {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String occurrenceId;

  /// The natural composite key as a single unique index, so an upsert stays
  /// one `putBy` call and a re-arm can never create a duplicate day row.
  @Index(unique: true)
  late String occurrenceKey;

  @Index()
  late String entityId;

  @Index()
  late String entityKind;

  @Index()
  late String dateKey;

  /// Indexed: the Recovery Card and the state sweep both range over time.
  @Index()
  late int scheduledAtMs;

  /// Indexed: "everything not yet resolved" is the hottest query in R2.
  @Index()
  late String state;

  @Index()
  late int updatedAtMs;

  late int windowMinutes;
  String? entityTitle;
  String? modeRefId;
  late String taxonomy;
  late int criticality;
  late String classificationSource;
  int? classifierVersion;
  late int ladderPosition;
  int? overdueSinceMs;
  String? resolutionKind;
  String? resolutionReason;
  int? resolvedAtMs;
  String? dismissedForDayKey;
  late int createdAtMs;

  static String keyFor(String entityKind, String entityId, String dateKey) =>
      ReminderOccurrence.keyFor(entityKind, entityId, dateKey);

  static IsarReminderOccurrence fromDomain(ReminderOccurrence o) {
    return IsarReminderOccurrence()
      ..occurrenceId = o.id
      ..occurrenceKey = o.occurrenceKey
      ..entityId = o.entityId
      ..entityKind = o.entityKind
      ..dateKey = o.dateKey
      ..scheduledAtMs = o.scheduledAtMs
      ..state = o.state.toStorage()
      ..updatedAtMs = o.updatedAtMs
      ..windowMinutes = o.windowMinutes
      ..entityTitle = o.entityTitle
      ..modeRefId = o.modeRefId
      ..taxonomy = o.taxonomy.toStorage()
      ..criticality = o.criticality
      ..classificationSource = o.classificationSource.toStorage()
      ..classifierVersion = o.classifierVersion
      ..ladderPosition = o.ladderPosition
      ..overdueSinceMs = o.overdueSinceMs
      ..resolutionKind = o.resolutionKind?.toStorage()
      ..resolutionReason = o.resolutionReason
      ..resolvedAtMs = o.resolvedAtMs
      ..dismissedForDayKey = o.dismissedForDayKey
      ..createdAtMs = o.createdAtMs;
  }

  ReminderOccurrence toDomain() {
    return ReminderOccurrence(
      id: occurrenceId,
      entityId: entityId,
      entityKind: entityKind,
      dateKey: dateKey,
      scheduledAtMs: scheduledAtMs,
      windowMinutes: windowMinutes,
      entityTitle: entityTitle,
      modeRefId: modeRefId,
      state: ReminderOccurrenceState.fromStorage(state),
      taxonomy: ReminderTaxonomy.fromStorage(taxonomy),
      criticality: criticality,
      classificationSource: ClassificationSource.fromStorage(
        classificationSource,
      ),
      classifierVersion: classifierVersion,
      ladderPosition: ladderPosition,
      overdueSinceMs: overdueSinceMs,
      resolutionKind: ReminderResolutionKind.fromStorage(resolutionKind),
      resolutionReason: resolutionReason,
      resolvedAtMs: resolvedAtMs,
      dismissedForDayKey: dismissedForDayKey,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
