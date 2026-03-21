import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';

class FirestorePaths {
  const FirestorePaths._();

  static String get _activeUid =>
      FirebaseAuth.instance.currentUser?.uid ?? AppConfig.localUserId;

  static String get userRoot => 'users/$_activeUid';
  static String get routines => '$userRoot/routines';
  static String blocks(String routineId) => '$routines/$routineId/blocks';
  static String tasks(String routineId, String blockId) =>
      '${blocks(routineId)}/$blockId/tasks';

  static String get timerSessions => '$userRoot/timerSessions';
  static String get taskScores => '$userRoot/taskScores';
  static String get reminders => '$userRoot/reminders';
}
