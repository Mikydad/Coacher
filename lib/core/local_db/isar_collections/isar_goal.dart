import 'package:isar/isar.dart';

import '../../../features/goals/domain/models/goal_enums.dart';
import '../../../features/goals/domain/models/user_goal.dart';

part 'isar_goal.g.dart';

@collection
class IsarGoal {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String goalId;

  @Index()
  late int updatedAtMs;

  late String title;
  late String categoryId;
  late String horizonStorage;
  late String statusStorage;
  late String measurementKindStorage;
  late double targetValue;
  String? customLabel;
  late int intensity;
  late int periodStartMs;
  late int periodEndMs;
  late String periodModeStorage;
  int? durationDays;
  late bool reminderEnabled;
  int? reminderMinutesFromMidnight;
  late String reminderStyleStorage;
  late int createdAtMs;

  static IsarGoal fromDomain(UserGoal g) {
    return IsarGoal()
      ..goalId = g.id
      ..updatedAtMs = g.updatedAtMs
      ..title = g.title
      ..categoryId = g.categoryId
      ..horizonStorage = g.horizon.storageValue
      ..statusStorage = g.status.storageValue
      ..measurementKindStorage = g.measurementKind.storageValue
      ..targetValue = g.targetValue
      ..customLabel = g.customLabel
      ..intensity = g.intensity
      ..periodStartMs = g.periodStartMs
      ..periodEndMs = g.periodEndMs
      ..periodModeStorage = g.periodMode.storageValue
      ..durationDays = g.durationDays
      ..reminderEnabled = g.reminderEnabled
      ..reminderMinutesFromMidnight = g.reminderMinutesFromMidnight
      ..reminderStyleStorage = g.reminderStyle.storageValue
      ..createdAtMs = g.createdAtMs;
  }

  UserGoal toDomain() {
    return UserGoal(
      id: goalId,
      title: title,
      categoryId: categoryId,
      horizon: GoalHorizonStorage.fromStorage(horizonStorage),
      status: GoalStatusStorage.fromStorage(statusStorage),
      measurementKind: MeasurementKindStorage.fromStorage(measurementKindStorage),
      targetValue: targetValue,
      customLabel: customLabel,
      intensity: intensity,
      periodStartMs: periodStartMs,
      periodEndMs: periodEndMs,
      periodMode: GoalPeriodModeStorage.fromStorage(periodModeStorage),
      durationDays: durationDays,
      reminderEnabled: reminderEnabled,
      reminderMinutesFromMidnight: reminderMinutesFromMidnight,
      reminderStyle: GoalReminderStyleStorage.fromStorage(reminderStyleStorage),
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
