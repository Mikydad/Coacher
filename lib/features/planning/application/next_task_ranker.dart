import 'planned_task_collect.dart';
import '../domain/models/task_item.dart';

/// Ranks candidate tasks for "what should I do next?" flows.
///
/// Sorting rules:
/// 1) Open tasks only (`notStarted`, `inProgress`, `partial`)
/// 2) Optional user sequence first (when enabled and sequence exists)
/// 3) Higher priority first (`1` before `5`)
/// 4) Higher block urgency first
/// 5) Stable fallback by `orderIndex` then `id`
abstract final class NextTaskRanker {
  static List<PlannedTaskRow> rank(
    Iterable<PlannedTaskRow> rows, {
    Map<String, int> blockUrgencyById = const {},
    bool preferUserSequence = false,
    bool allowUrgencyOverride = true,
    int urgencyOverrideThreshold = 80,
  }) {
    final list = rows.where((r) => _isOpen(r.task)).toList();
    list.sort((a, b) {
      if (preferUserSequence) {
        final as = a.task.sequenceIndex;
        final bs = b.task.sequenceIndex;
        final aHas = as != null;
        final bHas = bs != null;

        if (allowUrgencyOverride) {
          final au = blockUrgencyById[a.blockId] ?? 0;
          final bu = blockUrgencyById[b.blockId] ?? 0;
          final aCritical = au >= urgencyOverrideThreshold;
          final bCritical = bu >= urgencyOverrideThreshold;
          if (aCritical != bCritical) {
            return bCritical ? 1 : -1;
          }
        }

        if (aHas && bHas) {
          final c = as.compareTo(bs);
          if (c != 0) return c;
        } else if (aHas != bHas) {
          return aHas ? -1 : 1;
        }
      }

      final pc = a.task.priority.compareTo(b.task.priority);
      if (pc != 0) return pc;

      final au = blockUrgencyById[a.blockId] ?? 0;
      final bu = blockUrgencyById[b.blockId] ?? 0;
      final uc = bu.compareTo(au);
      if (uc != 0) return uc;

      final oc = a.task.orderIndex.compareTo(b.task.orderIndex);
      if (oc != 0) return oc;
      return a.task.id.compareTo(b.task.id);
    });
    return list;
  }

  static PlannedTaskRow? chooseNext(
    Iterable<PlannedTaskRow> rows, {
    Map<String, int> blockUrgencyById = const {},
    bool preferUserSequence = false,
    bool allowUrgencyOverride = true,
    int urgencyOverrideThreshold = 80,
  }) {
    final ranked = rank(
      rows,
      blockUrgencyById: blockUrgencyById,
      preferUserSequence: preferUserSequence,
      allowUrgencyOverride: allowUrgencyOverride,
      urgencyOverrideThreshold: urgencyOverrideThreshold,
    );
    if (ranked.isEmpty) return null;
    return ranked.first;
  }

  static bool _isOpen(PlannedTask task) {
    switch (task.status) {
      case TaskStatus.notStarted:
      case TaskStatus.inProgress:
      case TaskStatus.partial:
        return true;
      case TaskStatus.completed:
        return false;
    }
  }
}
