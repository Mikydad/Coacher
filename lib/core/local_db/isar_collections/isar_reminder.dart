import 'package:isar_community/isar.dart';

import '../../../features/reminders/domain/models/reminder_config.dart';
import '../../../features/reminders/domain/models/reminder_occurrence_enums.dart';

part 'isar_reminder.g.dart';

@collection
class IsarReminder {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String reminderId;

  @Index()
  late String taskId;

  @Index()
  late int updatedAtMs;

  String? taskTitle;
  late bool enabled;
  String? scheduledAtIso;
  String? modeRefId;
  late int blockUrgencyScore;
  late bool pendingAction;
  late int escalationLevel;
  late bool emergencyBypass;
  int? lastTriggeredAtMs;
  String? nextPromptAtIso;
  late int createdAtMs;

  /// Stable classification (FR-R-20/21). Stored as strings so a row written
  /// by a newer client degrades instead of throwing.
  String taxonomy = 'flexible';
  int criticality = 1;
  String classificationSource = 'heuristic';
  int? classifierVersion;
  String? aiBody;

  static IsarReminder fromDomain(ReminderConfig r) {
    return IsarReminder()
      ..reminderId = r.id
      ..taskId = r.taskId
      ..updatedAtMs = r.updatedAtMs
      ..taskTitle = r.taskTitle
      ..enabled = r.enabled
      ..scheduledAtIso = r.scheduledAtIso
      ..modeRefId = r.modeRefId
      ..blockUrgencyScore = r.blockUrgencyScore
      ..pendingAction = r.pendingAction
      ..escalationLevel = r.escalationLevel
      ..emergencyBypass = r.emergencyBypass
      ..lastTriggeredAtMs = r.lastTriggeredAtMs
      ..nextPromptAtIso = r.nextPromptAtIso
      ..createdAtMs = r.createdAtMs
      ..taxonomy = r.taxonomy.toStorage()
      ..criticality = r.criticality
      ..classificationSource = r.classificationSource.toStorage()
      ..classifierVersion = r.classifierVersion
      ..aiBody = r.aiBody;
  }

  ReminderConfig toDomain() {
    return ReminderConfig(
      id: reminderId,
      taskId: taskId,
      taskTitle: taskTitle,
      enabled: enabled,
      scheduledAtIso: scheduledAtIso,
      modeRefId: modeRefId,
      blockUrgencyScore: blockUrgencyScore,
      pendingAction: pendingAction,
      escalationLevel: escalationLevel,
      emergencyBypass: emergencyBypass,
      lastTriggeredAtMs: lastTriggeredAtMs,
      nextPromptAtIso: nextPromptAtIso,
      taxonomy: ReminderTaxonomy.fromStorage(taxonomy),
      criticality: criticality,
      classificationSource: ClassificationSource.fromStorage(
        classificationSource,
      ),
      classifierVersion: classifierVersion,
      aiBody: aiBody,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
