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

  /// Uid used for all user-scoped paths (feedback reports attach it too).
  static String get activeUid => _activeUid;

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

  /// Singleton doc (collection `onboarding`, doc `profile`) — what the user
  /// told us during first-launch onboarding (struggles / interests).
  static String get onboardingProfileDoc => '$userRoot/onboarding/profile';

  static String get analyticsEvents => '$userRoot/analytics_events';
  static String get analyticsStats => '$userRoot/analytics_stats';

  static String goalDocument(String goalId) => '$goals/$goalId';

  static String goalActions(String goalId) => '${goalDocument(goalId)}/actions';

  static String goalMilestones(String goalId) =>
      '${goalDocument(goalId)}/milestones';

  static String goalCheckIns(String goalId) =>
      '${goalDocument(goalId)}/checkIns';

  // ── Community / Accountability Circles ──────────────────────────────────────

  static String get circles => 'circles';
  static String circleDoc(String circleId) => 'circles/$circleId';
  static String circleMembers(String circleId) => 'circles/$circleId/members';
  static String circleMemberDoc(String circleId, String userId) =>
      'circles/$circleId/members/$userId';
  static String circleMessages(String circleId) => 'circles/$circleId/messages';
  static String circleActivityFeed(String circleId) =>
      'circles/$circleId/activityFeed';
  static String userCircleIds(String uid) => 'users/$uid/circleIds';
  static String userCircleIdDoc(String uid, String circleId) =>
      'users/$uid/circleIds/$circleId';
  static String circleWeeklyCommitments(String circleId) =>
      'circles/$circleId/weeklyCommitments';
  static String circleChallenges(String circleId) =>
      'circles/$circleId/challenges';
  static String challengeDoc(String circleId, String challengeId) =>
      'circles/$circleId/challenges/$challengeId';
  static String challengeVotes(String circleId, String challengeId) =>
      'circles/$circleId/challenges/$challengeId/votes';
  static String circleRemovalVotes(String circleId) =>
      'circles/$circleId/removalVotes';
  static String circleAiPulse(String circleId) => 'circles/$circleId/aiPulse';
  static String userCircleNotifPrefs(String uid) =>
      'users/$uid/circleNotifPrefs';
  static String userCircleNotifPrefsDoc(String uid, String circleId) =>
      'users/$uid/circleNotifPrefs/$circleId';
}
