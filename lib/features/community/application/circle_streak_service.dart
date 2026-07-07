import 'package:flutter/foundation.dart';

import '../../../core/utils/date_keys.dart';
import '../data/activity_feed_repository.dart';
import '../data/circle_repository.dart';

/// Evaluates circle streaks once per day (called on app foreground after midnight).
///
/// A circle's streak increments when ≥60% of members post any activity today.
/// If fewer members are active, the streak resets to 0.
class CircleStreakService {
  CircleStreakService({
    required CircleRepository circleRepo,
    required ActivityFeedRepository feedRepo,
  }) : _circleRepo = circleRepo,
       _feedRepo = feedRepo;

  final CircleRepository _circleRepo;
  final ActivityFeedRepository _feedRepo;

  /// Called once per day with the IDs of circles the current user belongs to.
  Future<void> evaluateStreaks(List<String> circleIds) async {
    for (final circleId in circleIds) {
      try {
        await _evaluateCircle(circleId);
      } catch (e) {
        debugPrint('[CircleStreakService] error evaluating $circleId: $e');
      }
    }
  }

  Future<void> _evaluateCircle(String circleId) async {
    final circle = await _circleRepo.getCircle(circleId);
    if (circle == null) return;

    if (circle.memberCount == 0) return;

    final todayKey = DateKeys.todayKey();
    final todayFeed = await _feedRepo.watchFeed(circleId).first;

    final activeUserIds = todayFeed
        .where((item) => item.dateKey == todayKey)
        .map((item) => item.userId)
        .toSet();

    final threshold = (circle.memberCount * 0.6).ceil();

    if (activeUserIds.length >= threshold) {
      final newStreak = circle.currentStreak + 1;
      await _circleRepo.updateCircle(
        circle.copyWith(
          currentStreak: newStreak,
          longestStreak: newStreak > circle.longestStreak
              ? newStreak
              : circle.longestStreak,
        ),
      );
    } else {
      await _circleRepo.updateCircle(circle.copyWith(currentStreak: 0));
    }
  }
}
