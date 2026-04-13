import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/local_db/isar_collections/isar_block.dart';
import '../../../core/local_db/isar_collections/isar_routine.dart';
import '../../../core/local_db/isar_collections/isar_task.dart';
import '../../../core/utils/date_keys.dart';
import '../../execution/application/execution_day_loader.dart';
import '../data/planning_repository.dart';
import '../domain/models/task_item.dart';
import 'next_task_ranker.dart';
import 'planned_task_collect.dart';

/// One-shot today rows after a mutation (avoids stale [StreamProvider.future]).
Future<List<PlannedTaskRow>> readFreshTodayPlannedRows(WidgetRef ref) {
  return collectTodayPlannedRows(ref.read(planningRepositoryProvider));
}

Future<HomeFlowSnapshot> _computeHomeFlowSnapshot(PlanningRepository repo) async {
  final dateKey = DateKeys.todayKey();
  final now = DateTime.now();
  final minutes = now.hour * 60 + now.minute;
  final routines = await repo.getRoutinesForDate(dateKey);
  var blockLabel = 'No active block';
  final openRows = <PlannedTaskRow>[];

  for (final r in routines) {
    final blocks = await repo.getBlocks(r.id);
    for (final b in blocks) {
      final start = b.startMinutesFromMidnight ?? 0;
      final end = b.endMinutesFromMidnight ?? 1439;
      final inWindow = minutes >= start && minutes <= end;
      if (inWindow) {
        blockLabel = b.title;
      }
      final tasks = await repo.getTasks(routineId: r.id, blockId: b.id);
      for (final t in tasks) {
        if (t.status != TaskStatus.completed) {
          openRows.add(
            PlannedTaskRow(
              dateKey: dateKey,
              routineId: r.id,
              blockId: b.id,
              task: t,
            ),
          );
        }
      }
    }
  }
  final next = NextTaskRanker.chooseNext(openRows);
  return HomeFlowSnapshot(
    currentBlockLabel: blockLabel,
    openTaskCount: openRows.length,
    nextTaskRow: next,
  );
}

Stream<List<PlannedTaskRow>> _todayRowsWatchStream(Ref ref) {
  final isar = ref.watch(offlineStoreProvider).isar;
  final repo = ref.read(planningRepositoryProvider);
  if (isar == null) {
    return Stream.value(const <PlannedTaskRow>[]);
  }

  final controller = StreamController<List<PlannedTaskRow>>.broadcast();

  Future<void> emit() async {
    try {
      final rows = await collectTodayPlannedRows(repo);
      if (!controller.isClosed) {
        controller.add(rows);
      }
    } catch (e, st) {
      if (!controller.isClosed) {
        controller.addError(e, st);
      }
    }
  }

  unawaited(emit());

  final subs = <StreamSubscription<void>>[
    isar.isarTasks.watchLazy(fireImmediately: false).listen((_) => unawaited(emit())),
    isar.isarRoutines.watchLazy(fireImmediately: false).listen((_) => unawaited(emit())),
    isar.isarBlocks.watchLazy(fireImmediately: false).listen((_) => unawaited(emit())),
  ];

  final timer = Timer.periodic(const Duration(minutes: 1), (_) => unawaited(emit()));

  ref.onDispose(() {
    timer.cancel();
    for (final s in subs) {
      s.cancel();
    }
    controller.close();
  });

  return controller.stream;
}

Stream<HomeFlowSnapshot> _homeFlowWatchStream(Ref ref) {
  final isar = ref.watch(offlineStoreProvider).isar;
  final repo = ref.read(planningRepositoryProvider);
  if (isar == null) {
    return Stream.value(
      const HomeFlowSnapshot(
        currentBlockLabel: 'No active block',
        openTaskCount: 0,
        nextTaskRow: null,
      ),
    );
  }

  final controller = StreamController<HomeFlowSnapshot>.broadcast();

  Future<void> emit() async {
    try {
      final snap = await _computeHomeFlowSnapshot(repo);
      if (!controller.isClosed) {
        controller.add(snap);
      }
    } catch (e, st) {
      if (!controller.isClosed) {
        controller.addError(e, st);
      }
    }
  }

  unawaited(emit());

  final subs = <StreamSubscription<void>>[
    isar.isarTasks.watchLazy(fireImmediately: false).listen((_) => unawaited(emit())),
    isar.isarRoutines.watchLazy(fireImmediately: false).listen((_) => unawaited(emit())),
    isar.isarBlocks.watchLazy(fireImmediately: false).listen((_) => unawaited(emit())),
  ];

  final timer = Timer.periodic(const Duration(minutes: 1), (_) => unawaited(emit()));

  ref.onDispose(() {
    timer.cancel();
    for (final s in subs) {
      s.cancel();
    }
    controller.close();
  });

  return controller.stream;
}

/// All planned tasks for today (every status) — Home + hub “Today”. Reactive via Isar.
final todayAllTasksRowsProvider = StreamProvider<List<PlannedTaskRow>>((ref) {
  return _todayRowsWatchStream(ref);
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

/// Invalidate non-stream task sources (e.g. after resume). Today/home streams update from Isar automatically.
void invalidateTaskListProviders(WidgetRef ref) {
  ref.invalidate(openTasksOutsideTodayProvider);
  ref.invalidate(executionDayTasksProvider);
}

class HomeFlowSnapshot {
  const HomeFlowSnapshot({
    required this.currentBlockLabel,
    required this.openTaskCount,
    required this.nextTaskRow,
  });

  final String currentBlockLabel;
  final int openTaskCount;
  final PlannedTaskRow? nextTaskRow;
}

final homeFlowSnapshotProvider = StreamProvider<HomeFlowSnapshot>((ref) {
  return _homeFlowWatchStream(ref);
});
