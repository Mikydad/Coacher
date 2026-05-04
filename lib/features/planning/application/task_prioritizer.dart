import 'planned_task_collect.dart';

enum TaskPriorityLayer {
  habitAnchor,
  overdueScheduled,
  upcomingScheduled,
  doNow,
  flexible,
}

class PrioritizedTaskRow {
  const PrioritizedTaskRow({
    required this.row,
    required this.layer,
    this.score,
  });

  final PlannedTaskRow row;
  final TaskPriorityLayer layer;
  final double? score;
}

List<PrioritizedTaskRow> prioritizePlannedTasks(
  Iterable<PlannedTaskRow> rows, {
  DateTime? now,
  Map<String, int> blockUrgencyById = const {},
  int doNowLimit = 3,
}) {
  final current = now ?? DateTime.now();
  final openRows = rows.where((r) => taskIsOpenForHub(r.task)).toList();

  final habitAnchors = <PlannedTaskRow>[];
  final overdue = <PlannedTaskRow>[];
  final upcoming = <PlannedTaskRow>[];
  final flexible = <PlannedTaskRow>[];

  for (final row in openRows) {
    if (row.task.isHabitAnchor) {
      habitAnchors.add(row);
      continue;
    }
    final scheduled = _scheduledToday(row, current);
    if (scheduled == null) {
      flexible.add(row);
      continue;
    }
    if (scheduled.isBefore(current)) {
      overdue.add(row);
    } else {
      upcoming.add(row);
    }
  }

  habitAnchors.sort((a, b) => _compareHabitAnchor(a, b, current));
  overdue.sort((a, b) => _compareByScheduledTime(a, b, current));
  upcoming.sort((a, b) => _compareByScheduledTime(a, b, current));

  final doNowPool = List<PlannedTaskRow>.from(flexible)
    ..sort((a, b) {
      final durationCmp = a.task.durationMinutes.compareTo(b.task.durationMinutes);
      if (durationCmp != 0) return durationCmp;
      final priorityCmp = a.task.priority.compareTo(b.task.priority);
      if (priorityCmp != 0) return priorityCmp;
      final seqCmp = _compareSequenceIndex(a, b);
      if (seqCmp != 0) return seqCmp;
      final orderCmp = a.task.orderIndex.compareTo(b.task.orderIndex);
      if (orderCmp != 0) return orderCmp;
      return a.task.id.compareTo(b.task.id);
    });

  final doNowCount = doNowLimit < 0
      ? 0
      : (doNowLimit > doNowPool.length ? doNowPool.length : doNowLimit);
  final doNow = doNowPool.take(doNowCount).toList();
  final doNowIds = doNow.map((r) => r.task.id).toSet();

  final remainingFlexible = flexible.where((r) => !doNowIds.contains(r.task.id)).toList();
  remainingFlexible.sort((a, b) {
    final as = _flexScore(a, blockUrgencyById);
    final bs = _flexScore(b, blockUrgencyById);
    final scoreCmp = bs.compareTo(as); // high score first
    if (scoreCmp != 0) return scoreCmp;
    final seqCmp = _compareSequenceIndex(a, b);
    if (seqCmp != 0) return seqCmp;
    final orderCmp = a.task.orderIndex.compareTo(b.task.orderIndex);
    if (orderCmp != 0) return orderCmp;
    return a.task.id.compareTo(b.task.id);
  });

  final out = <PrioritizedTaskRow>[];
  out.addAll(habitAnchors.map((r) => PrioritizedTaskRow(row: r, layer: TaskPriorityLayer.habitAnchor)));
  out.addAll(overdue.map((r) => PrioritizedTaskRow(row: r, layer: TaskPriorityLayer.overdueScheduled)));
  out.addAll(upcoming.map((r) => PrioritizedTaskRow(row: r, layer: TaskPriorityLayer.upcomingScheduled)));
  out.addAll(doNow.map((r) => PrioritizedTaskRow(row: r, layer: TaskPriorityLayer.doNow)));
  out.addAll(
    remainingFlexible.map(
      (r) => PrioritizedTaskRow(
        row: r,
        layer: TaskPriorityLayer.flexible,
        score: _flexScore(r, blockUrgencyById),
      ),
    ),
  );
  return out;
}

int _compareHabitAnchor(PlannedTaskRow a, PlannedTaskRow b, DateTime now) {
  final at = _scheduledToday(a, now);
  final bt = _scheduledToday(b, now);
  if (at != null && bt != null) {
    final c = at.compareTo(bt);
    if (c != 0) return c;
  } else if (at != null || bt != null) {
    return at != null ? -1 : 1;
  }
  final seqCmp = _compareSequenceIndex(a, b);
  if (seqCmp != 0) return seqCmp;
  final orderCmp = a.task.orderIndex.compareTo(b.task.orderIndex);
  if (orderCmp != 0) return orderCmp;
  return a.task.id.compareTo(b.task.id);
}

DateTime? _scheduledToday(PlannedTaskRow row, DateTime now) {
  final iso = row.task.reminderTimeIso;
  if (iso == null || iso.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return null;
  final local = parsed.toLocal();
  if (local.year != now.year || local.month != now.month || local.day != now.day) {
    return null;
  }
  return local;
}

int _compareByScheduledTime(PlannedTaskRow a, PlannedTaskRow b, DateTime now) {
  final at = _scheduledToday(a, now);
  final bt = _scheduledToday(b, now);
  if (at != null && bt != null) {
    final c = at.compareTo(bt);
    if (c != 0) return c;
  }
  final orderCmp = a.task.orderIndex.compareTo(b.task.orderIndex);
  if (orderCmp != 0) return orderCmp;
  return a.task.id.compareTo(b.task.id);
}

double _flexScore(PlannedTaskRow row, Map<String, int> blockUrgencyById) {
  // V1 weights (simple and deterministic).
  const priorityWeight = 0.5;
  const urgencyWeight = 0.3;
  const easeWeight = 0.2;

  final priorityScore = (6 - row.task.priority) / 5.0; // p1 => 1.0, p5 => 0.2
  final urgencyRaw = (blockUrgencyById[row.blockId] ?? 50).clamp(0, 100);
  final urgencyScore = urgencyRaw / 100.0;
  final easeScore = 1.0 / row.task.durationMinutes.clamp(1, 24 * 60);

  return (priorityWeight * priorityScore) +
      (urgencyWeight * urgencyScore) +
      (easeWeight * easeScore);
}

int _compareSequenceIndex(PlannedTaskRow a, PlannedTaskRow b) {
  final as = a.task.sequenceIndex;
  final bs = b.task.sequenceIndex;
  final aHas = as != null;
  final bHas = bs != null;
  if (aHas && bHas) {
    final c = as.compareTo(bs);
    if (c != 0) return c;
  } else if (aHas != bHas) {
    return aHas ? -1 : 1;
  }
  return 0;
}
