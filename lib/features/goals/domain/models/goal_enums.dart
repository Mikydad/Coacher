/// How the goal period is chosen: calendar vs a fixed number of days from a start date.
enum GoalPeriodMode {
  calendar,
  durationDays,
}

extension GoalPeriodModeStorage on GoalPeriodMode {
  String get storageValue => name;

  static GoalPeriodMode fromStorage(String? raw) {
    return GoalPeriodMode.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => GoalPeriodMode.calendar,
    );
  }
}

/// PRD: Goals — habit horizons (`prd-goals.md` §9).
enum GoalHorizon {
  daily,
  weekly,
  monthly,
}

/// Stored on [UserGoal]; drives list vs archive (`prd-goals.md` §4.6).
enum GoalStatus {
  active,
  paused,
  completed,
}

/// User-chosen unit for targets (`prd-goals.md` §4.2 item 4).
enum MeasurementKind {
  minutes,
  sessions,
  count,
  distance,
  custom,
}

extension GoalHorizonStorage on GoalHorizon {
  String get storageValue => name;

  static GoalHorizon fromStorage(String? raw) {
    return GoalHorizon.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => GoalHorizon.monthly,
    );
  }
}

extension GoalStatusStorage on GoalStatus {
  String get storageValue => name;

  static GoalStatus fromStorage(String? raw) {
    return GoalStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => GoalStatus.active,
    );
  }
}

/// How a goal pushes the user (`tripleNudge` / `accountable` reserved for future logic).
enum GoalReminderStyle {
  /// Single local notification each day at [UserGoal.reminderMinutesFromMidnight].
  dailyOnce,
  /// Future: 2–3 spaced pings around the chosen time.
  tripleNudge,
  /// Future: repeat until session started or user logs a reason to skip.
  accountable,
}

extension GoalReminderStyleStorage on GoalReminderStyle {
  String get storageValue => name;

  static GoalReminderStyle fromStorage(String? raw) {
    return GoalReminderStyle.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => GoalReminderStyle.dailyOnce,
    );
  }
}

extension MeasurementKindStorage on MeasurementKind {
  String get storageValue => name;

  static MeasurementKind fromStorage(String? raw) {
    return MeasurementKind.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => MeasurementKind.minutes,
    );
  }

  String displayLabel() {
    switch (this) {
      case MeasurementKind.minutes:
        return 'Minutes';
      case MeasurementKind.sessions:
        return 'Sessions';
      case MeasurementKind.count:
        return 'Count';
      case MeasurementKind.distance:
        return 'Distance';
      case MeasurementKind.custom:
        return 'Custom';
    }
  }
}
