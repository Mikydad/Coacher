import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/task_item.dart';
import '../data/activity_feed_repository.dart';
import '../domain/models/activity_feed_item.dart';
import '../domain/models/circle_enums.dart';
import 'user_circle_membership_service.dart';

const _kStreakMilestones = {7, 14, 30, 60, 100};

/// Observes existing data providers (read-only) and fans out
/// [ActivityFeedItem]s to every circle the user belongs to.
///
/// **Safety contract:** This service NEVER calls `ref.invalidate`,
/// NEVER modifies existing provider state, and NEVER throws to the caller —
/// all errors are caught and logged.
class CircleActivityBridgeService {
  CircleActivityBridgeService({
    required ActivityFeedRepository feedRepo,
    required UserCircleMembershipService membershipSvc,
    required String Function() currentUserId,
    required String Function() currentDisplayName,
  }) : _feedRepo = feedRepo,
       _membershipSvc = membershipSvc,
       _currentUserId = currentUserId,
       _currentDisplayName = currentDisplayName;

  final ActivityFeedRepository _feedRepo;
  // ignore: unused_field
  final UserCircleMembershipService _membershipSvc;
  final String Function() _currentUserId;
  final String Function() _currentDisplayName;

  // Tracks previous streak values to detect milestone crossings.
  final Map<String, int> _lastKnownStreak = {};

  // Tracks task IDs already posted today to avoid duplicates in-session.
  final Set<String> _seenCompletedTaskIds = {};

  // Tracks milestone IDs already posted to avoid duplicates in-session.
  final Set<String> _seenCompletedMilestoneIds = {};

  /// Starts all listeners. Returns a [VoidCallback] that disposes them.
  VoidCallback start(ProviderContainer container) {
    final subs = <ProviderSubscription>[];

    // ── 1. Goals: check-in metCommitment + milestones ──────────────────────
    subs.add(
      container.listen<AsyncValue<List<UserGoal>>>(goalsStreamProvider, (
        _,
        next,
      ) {
        next.whenData((goals) => _checkGoals(container, goals));
      }, fireImmediately: true),
    );

    // ── 2. Tasks: completed status ──────────────────────────────────────────
    subs.add(
      container.listen<AsyncValue<List<PlannedTaskRow>>>(
        todayAllTasksRowsProvider,
        (_, next) {
          next.whenData(_checkCompletedTasks);
        },
        fireImmediately: true,
      ),
    );

    return () {
      for (final s in subs) {
        s.close();
      }
    };
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _checkGoals(
    ProviderContainer container,
    List<UserGoal> goals,
  ) async {
    try {
      final today = DateKeys.todayKey();
      final goalsRepo = container.read(goalsRepositoryProvider);

      for (final goal in goals) {
        final goalId = goal.id;
        final goalTitle = goal.title;

        // Check today's check-in
        final checkIns = await goalsRepo.getCheckInsForGoal(
          goalId,
          startDateKey: today,
          endDateKey: today,
        );
        for (final checkIn in checkIns) {
          if (checkIn.metCommitment) {
            await _fanOut(
              eventType: ActivityEventType.goalCompleted,
              entityId: goalId,
              entityTitle: goalTitle,
              dateKey: today,
            );
          }
        }

        // Check milestones
        final milestones = await goalsRepo.getMilestones(goalId);
        for (final milestone in milestones) {
          if (milestone.completed &&
              !_seenCompletedMilestoneIds.contains(milestone.id)) {
            _seenCompletedMilestoneIds.add(milestone.id);
            await _fanOut(
              eventType: ActivityEventType.milestoneReached,
              entityId: milestone.id,
              entityTitle: milestone.title,
              dateKey: today,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[CircleActivityBridge] goal check error: $e');
    }
  }

  Future<void> _checkCompletedTasks(List<PlannedTaskRow> rows) async {
    try {
      final today = DateKeys.todayKey();
      for (final row in rows) {
        if (row.task.status == TaskStatus.completed) {
          final taskId = row.task.id;
          if (_seenCompletedTaskIds.contains(taskId)) continue;
          _seenCompletedTaskIds.add(taskId);
          await _fanOut(
            eventType: ActivityEventType.taskFinished,
            entityId: taskId,
            entityTitle: row.task.title,
            dateKey: today,
          );
        }
      }
    } catch (e) {
      debugPrint('[CircleActivityBridge] task completion error: $e');
    }
  }

  /// Called externally when a habit streak value changes.
  /// Posts a [habitStreakReached] event if the new streak hits a milestone.
  Future<void> checkHabitStreak({
    required String habitId,
    required String habitTitle,
    required int currentStreak,
  }) async {
    try {
      final prev = _lastKnownStreak[habitId] ?? 0;
      _lastKnownStreak[habitId] = currentStreak;

      if (currentStreak <= prev) return;
      if (!_kStreakMilestones.contains(currentStreak)) return;

      await _fanOut(
        eventType: ActivityEventType.habitStreakReached,
        entityId: habitId,
        entityTitle: habitTitle,
        value: '$currentStreak',
        dateKey: DateKeys.todayKey(),
      );
    } catch (e) {
      debugPrint('[CircleActivityBridge] habit streak error: $e');
    }
  }

  // ── Fan-out ───────────────────────────────────────────────────────────────

  Future<void> _fanOut({
    required ActivityEventType eventType,
    required String? entityId,
    required String? entityTitle,
    String? value,
    required String dateKey,
  }) async {
    try {
      final uid = _currentUserId();
      if (uid.isEmpty) return;

      final circleIds = await _fetchCircleIds(uid);
      if (circleIds.isEmpty) return;

      for (final circleId in circleIds) {
        try {
          final existing = await _feedRepo.findExistingItem(
            circleId: circleId,
            userId: uid,
            entityId: entityId,
            eventType: eventType,
            dateKey: dateKey,
          );
          if (existing != null) continue;

          final item = ActivityFeedItem(
            id: StableId.generate('feed'),
            circleId: circleId,
            userId: uid,
            displayName: _currentDisplayName(),
            eventType: eventType,
            entityId: entityId,
            entityTitle: entityTitle,
            value: value,
            dateKey: dateKey,
            createdAtMs: DateTime.now().millisecondsSinceEpoch,
          );
          await _feedRepo.postFeedItem(item);
        } catch (e) {
          debugPrint(
            '[CircleActivityBridge] fanOut circle=$circleId error: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('[CircleActivityBridge] fanOut error: $e');
    }
  }

  Future<List<String>> _fetchCircleIds(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestorePaths.userCircleIds(uid))
        .get();
    return snap.docs.map((d) => d.id).toList();
  }
}
