import 'package:isar_community/isar.dart';

import '../../../features/time_tracker/domain/models/activity_event.dart';

part 'isar_activity_event.g.dart';

/// Synced activity-event row (PRD/Time_Tracker, 2026-09-12). Soft
/// tombstone via [active]; [dateKey] indexed for the per-day timeline.
@collection
class IsarActivityEvent {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String eventId;

  @Index()
  late int updatedAtMs;

  @Index()
  late String dateKey;

  @Index()
  late int startedAtMs;

  late String text;
  int? endedAtMs;
  int? intendedMinutes;

  /// `manual` | `timer`.
  late String sourceStorage;
  String? sourceEntityId;
  String? category;
  late bool active;
  late int createdAtMs;

  static IsarActivityEvent fromDomain(ActivityEvent e) {
    return IsarActivityEvent()
      ..eventId = e.id
      ..updatedAtMs = e.updatedAtMs
      ..dateKey = e.dateKey
      ..startedAtMs = e.startedAtMs
      ..text = e.text
      ..endedAtMs = e.endedAtMs
      ..intendedMinutes = e.intendedMinutes
      ..sourceStorage = e.source.name
      ..sourceEntityId = e.sourceEntityId
      ..category = e.category
      ..active = e.active
      ..createdAtMs = e.createdAtMs;
  }

  ActivityEvent toDomain() {
    return ActivityEvent(
      id: eventId,
      text: text,
      startedAtMs: startedAtMs,
      endedAtMs: endedAtMs,
      intendedMinutes: intendedMinutes,
      dateKey: dateKey,
      source: activitySourceFromStorage(sourceStorage),
      sourceEntityId: sourceEntityId,
      category: category,
      active: active,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
