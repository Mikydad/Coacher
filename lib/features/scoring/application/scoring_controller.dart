import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/stable_id.dart';
import '../data/scoring_repository.dart';
import '../domain/models/task_score.dart';

class ScoringController {
  ScoringController(this._repo);

  final ScoringRepository _repo;

  Future<TaskScore> submit({
    required String taskId,
    required int completionPercent,
    String? reason,
    String? timerSessionId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final score = TaskScore(
      id: StableId.generate('score'),
      taskId: taskId,
      completionPercent: completionPercent,
      reason: reason,
      timerSessionId: timerSessionId,
      createdAtMs: now,
      updatedAtMs: now,
    );
    score.validate();
    await _repo.upsertScore(score);
    return score;
  }
}

final scoredTaskStatusesProvider = StateProvider<Map<String, int>>((ref) => {});
