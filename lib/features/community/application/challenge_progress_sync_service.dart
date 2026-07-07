import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/task_item.dart';
import '../data/challenge_repository.dart';
import '../domain/models/challenge.dart';

/// Observes task completions and goal check-ins (read-only) and automatically
/// increments [Challenge.memberProgress] for matching active challenges.
///
/// **Safety contract:** Does NOT modify any existing provider state. All errors
/// are caught and logged. A separate service from [CircleActivityBridgeService].
class ChallengeProgressSyncService {
  ChallengeProgressSyncService({
    required ChallengeRepository challengeRepo,
    required String Function() currentUserId,
  }) : _challengeRepo = challengeRepo,
       _currentUserId = currentUserId;

  final ChallengeRepository _challengeRepo;
  final String Function() _currentUserId;

  /// Task IDs already incremented in this session.
  final Set<String> _processedTaskIds = {};

  /// Goal+dateKey combos already incremented in this session.
  final Set<String> _processedGoalKeys = {};

  /// Starts all listeners. Returns a dispose callback.
  VoidCallback start(ProviderContainer container) {
    final subs = <ProviderSubscription>[];

    // ── Completed tasks ───────────────────────────────────────────────────────
    subs.add(
      container.listen<AsyncValue<List<PlannedTaskRow>>>(
        todayAllTasksRowsProvider,
        (_, next) {
          next.whenData((rows) {
            for (final row in rows) {
              if (row.task.status == TaskStatus.completed) {
                _onTaskCompleted(row.task);
              }
            }
          });
        },
        fireImmediately: true,
      ),
    );

    // ── Goal check-ins ────────────────────────────────────────────────────────
    subs.add(
      container.listen<AsyncValue<List<UserGoal>>>(goalsStreamProvider, (
        _,
        next,
      ) {
        next.whenData((goals) => _onGoalsUpdated(container, goals));
      }, fireImmediately: true),
    );

    return () {
      for (final s in subs) {
        s.close();
      }
    };
  }

  // ── Internal handlers ──────────────────────────────────────────────────────

  void _onTaskCompleted(PlannedTask task) async {
    if (_processedTaskIds.contains(task.id)) return;
    _processedTaskIds.add(task.id);

    try {
      final uid = _currentUserId();
      if (uid.isEmpty) return;

      final circleIds = await _fetchCircleIds(uid);

      for (final circleId in circleIds) {
        final challenges = await _challengeRepo.watchChallenges(circleId).first;

        for (final challenge in challenges) {
          if (challenge.status != ChallengeStatus.active) continue;
          if (!_matchesChallengeUnit(task.category ?? '', challenge.unit)) {
            continue;
          }
          await _challengeRepo.updateProgress(
            circleId: circleId,
            challengeId: challenge.id,
            userId: uid,
            delta: 1,
          );
        }
      }
    } catch (e) {
      debugPrint('[ChallengeProgressSync] task error: $e');
    }
  }

  void _onGoalsUpdated(
    ProviderContainer container,
    List<UserGoal> goals,
  ) async {
    try {
      final uid = _currentUserId();
      if (uid.isEmpty) return;

      final goalsRepo = container.read(goalsRepositoryProvider);
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      for (final goal in goals) {
        final sessionKey = '${goal.id}:$todayKey';
        if (_processedGoalKeys.contains(sessionKey)) continue;

        final checkIns = await goalsRepo.getCheckInsForGoal(
          goal.id,
          startDateKey: todayKey,
          endDateKey: todayKey,
        );

        final metToday = checkIns.any((c) => c.metCommitment);
        if (!metToday) continue;

        _processedGoalKeys.add(sessionKey);

        final circleIds = await _fetchCircleIds(uid);

        for (final circleId in circleIds) {
          final challenges = await _challengeRepo
              .watchChallenges(circleId)
              .first;

          for (final challenge in challenges) {
            if (challenge.status != ChallengeStatus.active) continue;
            if (!_matchesChallengeUnit(goal.categoryId, challenge.unit)) {
              continue;
            }
            await _challengeRepo.updateProgress(
              circleId: circleId,
              challengeId: challenge.id,
              userId: uid,
              delta: 1,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[ChallengeProgressSync] goal check-in error: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<List<String>> _fetchCircleIds(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestorePaths.userCircleIds(uid))
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  // ── Matching logic ─────────────────────────────────────────────────────────

  /// Fuzzy match: maps known category names to typical challenge units.
  /// Falls back to an exact case-insensitive match.
  @visibleForTesting
  static bool matchesChallengeUnit(String category, String unit) {
    return _matchesChallengeUnit(category, unit);
  }

  static bool _matchesChallengeUnit(String category, String unit) {
    final cat = category.toLowerCase().trim();
    final u = unit.toLowerCase().trim();

    const mappings = <String, List<String>>{
      'fitness': ['workout', 'miles', 'sessions', 'reps', 'steps', 'km'],
      'health': ['meals', 'glasses', 'hours', 'sessions', 'steps'],
      'learning': ['pages', 'sessions', 'chapters', 'hours', 'lessons'],
      'study': ['pages', 'sessions', 'chapters', 'hours', 'lessons'],
      'work': ['tasks', 'sessions', 'hours', 'pomodoros'],
      'habit': ['sessions', 'days', 'times'],
      'mindfulness': ['sessions', 'minutes', 'hours'],
    };

    for (final entry in mappings.entries) {
      if (cat.contains(entry.key)) {
        if (entry.value.any((k) => u.contains(k))) return true;
      }
    }

    // Exact or contains fallback
    return u.contains(cat) || cat.contains(u);
  }
}
