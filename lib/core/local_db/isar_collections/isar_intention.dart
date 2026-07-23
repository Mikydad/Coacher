import 'package:isar_community/isar.dart';

import '../../../features/intentions/domain/models/intention.dart';

part 'isar_intention.g.dart';

/// Synced intention row (PRD Phase 1). Soft tombstone via [active] so a
/// delete on one device wins over a stale edit from another (LWW).
@collection
class IsarIntention {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String intentionId;

  @Index()
  late int updatedAtMs;

  late String title;
  late String rawUtterance;
  String? personId;
  late int windowStartMs;
  late int windowEndMs;
  late int estimatedMinutes;
  late String importanceStorage;
  late List<String> activityTags;
  String? aiHintsJson;
  String? dependsOnText;
  String? anchorEntityId;
  String? locationHintText;

  @Index()
  late String statusStorage;

  int? pinnedAtMs;
  int? completedAtMs;
  late int nudgeCount;
  late int snoozeCount;
  late bool active;
  late int createdAtMs;

  static IsarIntention fromDomain(Intention i) {
    return IsarIntention()
      ..intentionId = i.id
      ..updatedAtMs = i.updatedAtMs
      ..title = i.title
      ..rawUtterance = i.rawUtterance
      ..personId = i.personId
      ..windowStartMs = i.windowStartMs
      ..windowEndMs = i.windowEndMs
      ..estimatedMinutes = i.estimatedMinutes
      ..importanceStorage = i.importance.name
      ..activityTags = i.activityTags
      ..aiHintsJson = i.aiHintsJson
      ..dependsOnText = i.dependsOnText
      ..anchorEntityId = i.anchorEntityId
      ..locationHintText = i.locationHintText
      ..statusStorage = i.status.name
      ..pinnedAtMs = i.pinnedAtMs
      ..completedAtMs = i.completedAtMs
      ..nudgeCount = i.nudgeCount
      ..snoozeCount = i.snoozeCount
      ..active = i.active
      ..createdAtMs = i.createdAtMs;
  }

  Intention toDomain() {
    return Intention(
      id: intentionId,
      title: title,
      rawUtterance: rawUtterance,
      personId: personId,
      windowStartMs: windowStartMs,
      windowEndMs: windowEndMs,
      estimatedMinutes: estimatedMinutes,
      importance: intentionImportanceFromStorage(importanceStorage),
      activityTags: activityTags,
      aiHintsJson: aiHintsJson,
      dependsOnText: dependsOnText,
      anchorEntityId: anchorEntityId,
      locationHintText: locationHintText,
      status: intentionStatusFromStorage(statusStorage),
      pinnedAtMs: pinnedAtMs,
      completedAtMs: completedAtMs,
      nudgeCount: nudgeCount,
      snoozeCount: snoozeCount,
      active: active,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
