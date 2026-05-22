import '../../../core/notifications/local_notifications_service.dart';
import '../data/circle_notif_prefs_repository.dart';
import '../domain/models/circle_notif_prefs.dart';

/// Notification types specific to accountability circles.
enum CircleNotifType {
  mention,
  challenge,
  accomplishment,
  reaction,
  weeklySummary,
}

/// Routes circle-related push notifications through per-circle preferences
/// before delegating to [LocalNotificationsService].
///
/// Does NOT modify [LocalNotificationsService].
class CircleNotificationRouter {
  CircleNotificationRouter({
    required LocalNotificationsService notifications,
    required CircleNotifPrefsRepository prefsRepo,
  })  : _notifications = notifications,
        _prefsRepo = prefsRepo;

  final LocalNotificationsService _notifications;
  final CircleNotifPrefsRepository _prefsRepo;

  /// Delivers a notification for a circle event if allowed by the user's prefs.
  Future<void> deliver({
    required String circleId,
    required CircleNotifType type,
    required String title,
    required String body,
    required int notificationId,
  }) async {
    final prefs = await _prefsRepo.getPrefs(circleId);
    if (prefs.isMuted) return;
    if (!_isEnabled(prefs, type)) return;

    await _notifications.schedule(
      id: notificationId,
      title: title,
      body: body,
      when: DateTime.now(),
      payload: 'circle:$circleId',
    );
  }

  static bool _isEnabled(CircleNotifPrefs prefs, CircleNotifType type) {
    switch (type) {
      case CircleNotifType.mention:
        return prefs.mentions;
      case CircleNotifType.challenge:
        return prefs.challengeUpdates;
      case CircleNotifType.accomplishment:
        return prefs.accomplishments;
      case CircleNotifType.reaction:
        return prefs.reactions;
      case CircleNotifType.weeklySummary:
        return prefs.weeklySummary;
    }
  }
}
