import 'package:isar/isar.dart';

import '../../../features/reminders/domain/models/reminder_config.dart';

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
      ..createdAtMs = r.createdAtMs;
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
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
