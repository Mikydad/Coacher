import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/circle_repository.dart';
import 'challenge_progress_sync_service.dart';
import 'challenge_providers.dart';
import 'circle_activity_bridge_service.dart';
import 'circle_providers.dart';
import 'circle_streak_service.dart';

/// Owns the lifecycle of the app-lifetime community bridge services
/// ([CircleActivityBridgeService], [ChallengeProgressSyncService]).
///
/// These services hold in-memory dedupe state keyed by the current user's
/// goal/task ids. They must be torn down and recreated on account switch so
/// user A's baselines never suppress (or trigger) posts in user B's session.
class CommunityBridgeCoordinator {
  CommunityBridgeCoordinator._();
  static final CommunityBridgeCoordinator instance =
      CommunityBridgeCoordinator._();

  VoidCallback? _disposeActivityBridge;
  VoidCallback? _disposeChallengeSync;

  /// Starts (or restarts) both bridges with fresh internal state.
  ///
  /// Never throws — bridge failure must not crash the app.
  void restart(ProviderContainer container) {
    stop();
    try {
      final bridge = CircleActivityBridgeService(
        feedRepo: container.read(activityFeedRepositoryProvider),
        membershipSvc: container.read(userCircleMembershipServiceProvider),
        currentUserId: () => FirebaseAuth.instance.currentUser?.uid ?? '',
        currentDisplayName: () =>
            FirebaseAuth.instance.currentUser?.displayName ?? 'User',
      );
      _disposeActivityBridge = bridge.start(container);
    } catch (e) {
      debugPrint('[CommunityBridgeCoordinator] activity bridge failed: $e');
    }
    try {
      final sync = ChallengeProgressSyncService(
        challengeRepo: container.read(challengeRepositoryProvider),
        currentUserId: () => FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      _disposeChallengeSync = sync.start(container);
    } catch (e) {
      debugPrint('[CommunityBridgeCoordinator] challenge sync failed: $e');
    }
  }

  /// Disposes both bridges' provider subscriptions.
  void stop() {
    try {
      _disposeActivityBridge?.call();
      _disposeChallengeSync?.call();
    } catch (e) {
      debugPrint('[CommunityBridgeCoordinator] dispose failed: $e');
    }
    _disposeActivityBridge = null;
    _disposeChallengeSync = null;
  }

  /// One-shot circle streak evaluation (app start / foreground).
  Future<void> evaluateCircleStreaks(ProviderContainer container) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;

      final circleIds = await container.read(myCircleIdsProvider.stream).first;
      if (circleIds.isEmpty) return;

      final streakService = CircleStreakService(
        circleRepo: FirestoreCircleRepository(),
        feedRepo: container.read(activityFeedRepositoryProvider),
      );
      await streakService.evaluateStreaks(circleIds);
    } catch (e) {
      debugPrint('[CommunityBridgeCoordinator] streak evaluation failed: $e');
    }
  }
}
