import 'package:isar_community/isar.dart';

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

  /// Repeat schedule storage; null = saved before repeat schedules existed
  /// (derived via [UserGoal.legacyRepeatCadence] on read).
  String? repeatCadenceStorage;
  int? repeatInterval;

  /// Weekdays acted on when repeat is weekly (1=Mon … 7=Sun).
  List<int>? scheduledWeekdays;

  /// Days of month (1–31) acted on when repeat is monthly.
  List<int>? repeatDaysOfMonth;
  late bool reminderEnabled;
  int? reminderMinutesFromMidnight;
  late String reminderStyleStorage;
  late int createdAtMs;
  String? colorHex;

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
      ..repeatCadenceStorage = g.repeatCadence.storageValue
      ..repeatInterval = g.repeatInterval
      ..scheduledWeekdays = g.scheduledWeekdays
      ..repeatDaysOfMonth = g.repeatDaysOfMonth
      ..reminderEnabled = g.reminderEnabled
      ..reminderMinutesFromMidnight = g.reminderMinutesFromMidnight
      ..reminderStyleStorage = g.reminderStyle.storageValue
      ..createdAtMs = g.createdAtMs
      ..colorHex = g.colorHex;
  }

  UserGoal toDomain() {
    return UserGoal(
      id: goalId,
      title: title,
      categoryId: categoryId,
      // horizonStorage is ignored on read — the window derives from repeat.
      status: GoalStatusStorage.fromStorage(statusStorage),
      measurementKind: MeasurementKindStorage.fromStorage(
        measurementKindStorage,
      ),
      targetValue: targetValue,
      customLabel: customLabel,
      intensity: intensity,
      periodStartMs: periodStartMs,
      periodEndMs: periodEndMs,
      periodMode: GoalPeriodModeStorage.fromStorage(periodModeStorage),
      durationDays: durationDays,
      repeatCadence: repeatCadenceStorage != null
          ? GoalRepeatCadenceStorage.fromStorage(repeatCadenceStorage)
          : UserGoal.legacyRepeatCadence(scheduledWeekdays),
      repeatInterval: repeatInterval ?? 1,
      scheduledWeekdays: scheduledWeekdays,
      repeatDaysOfMonth: repeatDaysOfMonth,
      reminderEnabled: reminderEnabled,
      reminderMinutesFromMidnight: reminderMinutesFromMidnight,
      reminderStyle: GoalReminderStyleStorage.fromStorage(reminderStyleStorage),
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
      colorHex: colorHex,
    );
  }
}
