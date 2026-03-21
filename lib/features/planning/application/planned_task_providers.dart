import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../execution/application/execution_day_loader.dart';
import 'planned_task_collect.dart';

/// All planned tasks for today (every status) — Home + hub “Today”.
final todayAllTasksRowsProvider = FutureProvider<List<PlannedTaskRow>>((
  ref,
) async {
  final repo = ref.read(planningRepositoryProvider);
  return collectTasksForDateKeyPreferServer(
    repo,
    DateKeys.todayKey(),
    enforceTaskPlanDate: true,
  );
});

/// Open tasks on other plan days (bounded window around today).
final openTasksOutsideTodayProvider = FutureProvider<List<PlannedTaskRow>>((
  ref,
) async {
  final repo = ref.read(planningRepositoryProvider);
  final today = DateKeys.todayKey();
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day);
  final rows = <PlannedTaskRow>[];

  for (var offset = -7; offset <= 14; offset++) {
    if (offset == 0) continue;
    final dk = DateKeys.yyyymmdd(base.add(Duration(days: offset)));
    if (dk == today) continue;
    final dayRows = await collectTasksForDateKey(
      repo,
      dk,
      enforceTaskPlanDate: true,
    );
    for (final row in dayRows) {
      if (taskIsOpenForHub(row.task)) {
        rows.add(row);
      }
    }
  }

  rows.sort((a, b) {
    final dc = a.dateKey.compareTo(b.dateKey);
    if (dc != 0) return dc;
    return a.task.orderIndex.compareTo(b.task.orderIndex);
  });
  return rows;
});

void invalidateTaskListProviders(WidgetRef ref) {
  ref.invalidate(todayAllTasksRowsProvider);
  ref.invalidate(openTasksOutsideTodayProvider);
  ref.invalidate(executionDayTasksProvider);
}
