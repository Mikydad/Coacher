import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../features/goals/domain/models/user_goal.dart';
import '../../features/planning/domain/models/block.dart';
import '../../features/planning/domain/models/routine.dart';
import '../../features/planning/domain/models/task_item.dart';
import '../../features/reminders/data/reminder_repository.dart';
import '../../features/reminders/domain/models/reminder_config.dart';
import '../firebase/firestore_client.dart';
import '../firebase/firestore_paths.dart';
import '../local_db/isar_collections/isar_block.dart';
import '../local_db/isar_collections/isar_goal.dart';
import '../local_db/isar_collections/isar_reminder.dart';
import '../local_db/isar_collections/isar_routine.dart';
import 'isar_lww_merge.dart';
import 'lww_updated_at.dart';

String _docFieldId(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
  Map<String, dynamic> data, [
  String key = 'id',
]) {
  final v = data[key];
  if (v is String && v.trim().isNotEmpty) return v.trim();
  if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
  return doc.id;
}

/// Pulls Firestore planning, reminders, and goals into Isar using last-write-wins on [updatedAtMs].
class RemoteIsarMerge {
  RemoteIsarMerge(this._isar);

  final Isar _isar;
  final FirestoreClient _client = FirestoreClient();

  Future<void> run() async {
    await _pullRoutinesBlocksTasks();
    await _pullReminders();
    await _pullGoals();
    debugPrint('RemoteIsarMerge: pull finished');
  }

  Future<void> _pullRoutinesBlocksTasks() async {
    final routinesCol = _client.userCollection('routines');
    final routinesSnap = await routinesCol.get();
    for (final doc in routinesSnap.docs) {
      try {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = _docFieldId(doc, m);
        final routine = Routine.fromMap(m);
        await _mergeRoutine(routine);
        final routineId = routine.id;
        final blocksSnap = await routinesCol.doc(routineId).collection('blocks').get();
        for (final bDoc in blocksSnap.docs) {
          try {
            final bm = Map<String, dynamic>.from(bDoc.data());
            bm['id'] = _docFieldId(bDoc, bm);
            final rid = bm['routineId'];
            bm['routineId'] = rid is String && rid.trim().isNotEmpty ? rid.trim() : routineId;
            final block = TaskBlock.fromMap(bm);
            await _mergeBlock(block);
            final tasksSnap = await routinesCol
                .doc(routineId)
                .collection('blocks')
                .doc(block.id)
                .collection('tasks')
                .get();
            for (final tDoc in tasksSnap.docs) {
              try {
                final tm = Map<String, dynamic>.from(tDoc.data());
                tm['id'] = _docFieldId(tDoc, tm);
                final tr = tm['routineId'];
                tm['routineId'] = tr is String && tr.trim().isNotEmpty ? tr.trim() : routineId;
                final tb = tm['blockId'];
                tm['blockId'] = tb is String && tb.trim().isNotEmpty ? tb.trim() : block.id;
                final task = PlannedTask.fromMap(tm);
                await _mergeTask(task);
              } catch (e, st) {
                debugPrint('RemoteIsarMerge: skip task ${tDoc.id}: $e\n$st');
              }
            }
          } catch (e, st) {
            debugPrint('RemoteIsarMerge: skip block ${bDoc.id}: $e\n$st');
          }
        }
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip routine ${doc.id}: $e\n$st');
      }
    }
  }

  Future<void> _pullReminders() async {
    final snap = await FirebaseFirestore.instance.collection(FirestorePaths.reminders).get();
    for (final doc in snap.docs) {
      try {
        final r = reminderConfigFromFirestoreDoc(doc);
        await _mergeReminder(r);
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip reminder ${doc.id}: $e\n$st');
      }
    }
  }

  Future<void> _pullGoals() async {
    final snap = await FirebaseFirestore.instance.collection(FirestorePaths.goals).get();
    for (final doc in snap.docs) {
      try {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = _docFieldId(doc, m);
        final g = UserGoal.fromMap(m);
        await _mergeGoal(g);
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip goal ${doc.id}: $e\n$st');
      }
    }
  }

  Future<void> _mergeRoutine(Routine incoming) async {
    final existing = await _isar.isarRoutines.filter().routineIdEqualTo(incoming.id).findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarRoutines.putByRoutineId(IsarRoutine.fromDomain(incoming));
    });
  }

  Future<void> _mergeBlock(TaskBlock incoming) async {
    final existing = await _isar.isarBlocks.filter().blockIdEqualTo(incoming.id).findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarBlocks.putByBlockId(IsarBlock.fromDomain(incoming));
    });
  }

  Future<void> _mergeTask(PlannedTask incoming) => mergePlannedTaskLwwIntoIsar(_isar, incoming);

  Future<void> _mergeReminder(ReminderConfig incoming) async {
    final existing = await _isar.isarReminders.filter().reminderIdEqualTo(incoming.id).findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarReminders.putByReminderId(IsarReminder.fromDomain(incoming));
    });
  }

  Future<void> _mergeGoal(UserGoal incoming) async {
    final existing = await _isar.isarGoals.filter().goalIdEqualTo(incoming.id).findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarGoals.putByGoalId(IsarGoal.fromDomain(incoming));
    });
  }
}
