import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_goal_check_in.dart';
import '../../../core/local_db/isar_collections/isar_points.dart';
import '../../../core/local_db/isar_collections/isar_task.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/points.dart';

/// Offline points balance (read-only mirror; the ledger is server truth).
final pointsBalanceProvider = StreamProvider<int>((ref) {
  final isar = OfflineStore.instance.isar!;
  final uid = FirestorePaths.activeUid;
  return isar.isarPointsBalances
      .filter()
      .uidEqualTo(uid)
      .watch(fireImmediately: true)
      .map((rows) => rows.isEmpty ? 0 : rows.first.balance);
});

/// Ledger history, newest first (hub "points" sheet).
final pointsTxnsProvider = StreamProvider<List<PointsTxn>>((ref) {
  final isar = OfflineStore.instance.isar!;
  return isar.isarPointsTxns
      .where()
      .sortByAtMsDesc()
      .watch(fireImmediately: true)
      .map((rows) => rows.map((e) => e.toDomain()).toList());
});

/// Curated charity list (D7 — active entries only ever reach the mirror).
final charitiesProvider = StreamProvider<List<Charity>>((ref) {
  final isar = OfflineStore.instance.isar!;
  return isar.isarCharitys
      .where()
      .watch(fireImmediately: true)
      .map((rows) => rows.map((e) => e.toDomain()).toList());
});

/// PT-3 earn wiring — re-derivation instead of scattering grant calls
/// through every completion path: scan today's completed artifacts in
/// Isar and fire `grantPoints` for each. Deterministic server txn ids
/// make every re-fire a no-op, so this can run on every app open and
/// after every sync without double-granting; offline completions are
/// granted on the next online sweep.
class PointsEarnService {
  PointsEarnService();

  bool _ranThisSession = false;

  Future<void> sweepToday({bool force = false}) async {
    if (_ranThisSession && !force) return;
    _ranThisSession = true;

    final isar = OfflineStore.instance.isar;
    if (isar == null) return;
    final functions = FirebaseFunctions.instance;

    Future<void> fire(String source, String refId) async {
      try {
        await functions
            .httpsCallable('grantPoints')
            .call<Map<String, dynamic>>({'source': source, 'refId': refId});
      } catch (e) {
        // Silent by design: the next sweep retries, ids dedupe server-side.
        debugPrint('grantPoints($source,$refId) deferred: $e');
      }
    }

    try {
      final todayKey = _todayKey();

      // Completed goal check-ins → earn_goal (+ first one → earn_checkin).
      final checkIns = await isar.isarGoalCheckIns
          .filter()
          .dateKeyEqualTo(todayKey)
          .findAll();
      final metGoals = checkIns.where((c) => c.metCommitment).toList();
      if (metGoals.isNotEmpty) {
        await fire('earn_checkin', todayKey.replaceAll('-', '_'));
      }
      for (final c in metGoals) {
        await fire('earn_goal', c.goalId);
      }

      // Completed tasks planned for today → earn_task.
      final tasks = await isar.isarTasks
          .filter()
          .planDateKeyEqualTo(todayKey)
          .findAll();
      for (final t in tasks.where((t) => t.statusName == 'completed')) {
        await fire('earn_task', t.taskId);
      }
    } catch (e, st) {
      debugPrint('PointsEarnService sweep failed: $e\n$st');
    }
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

final pointsEarnServiceProvider = Provider<PointsEarnService>(
  (ref) => PointsEarnService(),
);
