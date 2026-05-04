import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config/app_config.dart';

class FirestorePaths {
  const FirestorePaths._();

  /// When Firebase is not initialized (e.g. VM unit tests), use [AppConfig.localUserId].
  static String get _activeUid {
    if (Firebase.apps.isEmpty) {
      return AppConfig.localUserId;
    }
    return FirebaseAuth.instance.currentUser?.uid ?? AppConfig.localUserId;
  }

  static String get userRoot => 'users/$_activeUid';
  static String get routines => '$userRoot/routines';
  static String blocks(String routineId) => '$routines/$routineId/blocks';
  static String tasks(String routineId, String blockId) =>
      '${blocks(routineId)}/$blockId/tasks';

  static String get timerSessions => '$userRoot/timerSessions';
  static String get taskScores => '$userRoot/taskScores';
  static String get reminders => '$userRoot/reminders';
  static String get routineModes => '$userRoot/routineModes';
  static String get flowTransitionEvents => '$userRoot/flowTransitionEvents';
  static String get accountabilityLogs => '$userRoot/accountabilityLogs';

  static String get goals => '$userRoot/goals';
  static String get analyticsEvents => '$userRoot/analytics_events';
  static String get analyticsStats => '$userRoot/analytics_stats';

  static String goalDocument(String goalId) => '$goals/$goalId';

  static String goalActions(String goalId) => '${goalDocument(goalId)}/actions';

  static String goalMilestones(String goalId) => '${goalDocument(goalId)}/milestones';

  static String goalCheckIns(String goalId) => '${goalDocument(goalId)}/checkIns';
}
