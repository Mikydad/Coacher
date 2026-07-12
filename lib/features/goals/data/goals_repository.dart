import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_client.dart';
import '../../../core/firebase/firestore_paths.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/models/goal_action.dart';
import '../domain/models/goal_check_in.dart';
import '../domain/models/goal_milestone.dart';
import '../domain/models/user_goal.dart';

/// Firestore: `users/{uid}/goals/{goalId}` with subcollections
/// `actions`, `milestones`, `checkIns` (check-in doc id = `yyyy-MM-dd`).
abstract class GoalsRepository {
  Stream<List<UserGoal>> watchGoals();

  /// Live stream of one goal (null when it doesn't exist / was deleted).
  Stream<UserGoal?> watchGoal(String goalId);

  /// Live streams of a goal's subcollections — the UI's primary read path:
  /// local mutations and background sync pulls both surface here, so screens
  /// update in one frame with no refetch.
  Stream<List<GoalAction>> watchActions(String goalId);
  Stream<List<GoalMilestone>> watchMilestones(String goalId);
  Stream<List<GoalCheckIn>> watchCheckIns(String goalId);

  /// One-shot fetch (e.g. bootstrap); same ordering as [watchGoals] snapshots.
  Future<List<UserGoal>> fetchGoalsOnce();

  Future<UserGoal?> getGoal(String goalId);

  Future<void> upsertGoal(UserGoal goal);

  Future<void> deleteGoal(String goalId);

  Future<List<GoalAction>> getActions(String goalId);

  Future<void> upsertAction(GoalAction action);

  Future<void> deleteAction({required String goalId, required String actionId});

  Future<List<GoalMilestone>> getMilestones(String goalId);

  Future<void> upsertMilestone(GoalMilestone milestone);

  Future<void> deleteMilestone({
    required String goalId,
    required String milestoneId,
  });

  Future<void> upsertCheckIn(GoalCheckIn checkIn);

  Future<GoalCheckIn?> getTodayCheckIn(String goalId, String dateKey);

  Future<List<GoalCheckIn>> getCheckInsForGoal(
    String goalId, {
    String? startDateKey,
    String? endDateKey,
  });
}

class FirestoreGoalsRepository implements GoalsRepository {
  FirestoreGoalsRepository(this._client);

  final FirestoreClient _client;

  CollectionReference<Map<String, dynamic>> get _goals =>
      _client.userCollection('goals');

  Future<void> _upsertWithQueue({
    required String entityType,
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    await outboxUpsert(
      entityType: entityType,
      documentPath: path,
      payload: payload,
    );
  }

  Future<void> _deleteWithQueue({
    required String entityType,
    required String path,
  }) async {
    await outboxDelete(entityType: entityType, documentPath: path);
  }

  static Future<void> _purgeCollection(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    while (true) {
      final snap = await col.limit(400).get();
      if (snap.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  @override
  Stream<List<UserGoal>> watchGoals() {
    return _goals.orderBy('updatedAtMs', descending: true).snapshots().map((s) {
      return s.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return UserGoal.fromMap(data);
      }).toList();
    });
  }

  @override
  Stream<UserGoal?> watchGoal(String goalId) {
    return _goals.doc(goalId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      final m = Map<String, dynamic>.from(data);
      m['id'] = doc.id;
      return UserGoal.fromMap(m);
    });
  }

  @override
  Stream<List<GoalAction>> watchActions(String goalId) {
    return _goals
        .doc(goalId)
        .collection('actions')
        .orderBy('orderIndex')
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            return GoalAction.fromMap(data);
          }).toList(),
        );
  }

  @override
  Stream<List<GoalMilestone>> watchMilestones(String goalId) {
    return _goals
        .doc(goalId)
        .collection('milestones')
        .orderBy('orderIndex')
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            return GoalMilestone.fromMap(data);
          }).toList(),
        );
  }

  @override
  Stream<List<GoalCheckIn>> watchCheckIns(String goalId) {
    return _goals
        .doc(goalId)
        .collection('checkIns')
        .orderBy('dateKey')
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) => GoalCheckIn.fromMap(Map<String, dynamic>.from(d.data())),
              )
              .toList(),
        );
  }

  @override
  Future<List<UserGoal>> fetchGoalsOnce() async {
    final snap = await _goals.orderBy('updatedAtMs', descending: true).get();
    return snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return UserGoal.fromMap(data);
    }).toList();
  }

  @override
  Future<UserGoal?> getGoal(String goalId) async {
    final doc = await _goals.doc(goalId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return UserGoal.fromMap(data);
  }

  @override
  Future<void> upsertGoal(UserGoal goal) async {
    goal.validate();
    final path = FirestorePaths.goalDocument(goal.id);
    await _upsertWithQueue(
      entityType: 'goal',
      path: path,
      payload: goal.toMap(),
    );
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final goalRef = _goals.doc(goalId);
    await _purgeCollection(goalRef.collection('actions'));
    await _purgeCollection(goalRef.collection('milestones'));
    await _purgeCollection(goalRef.collection('checkIns'));
    await _deleteWithQueue(
      entityType: 'goal',
      path: FirestorePaths.goalDocument(goalId),
    );
  }

  @override
  Future<List<GoalAction>> getActions(String goalId) async {
    final snap = await _goals
        .doc(goalId)
        .collection('actions')
        .orderBy('orderIndex')
        .get();
    return snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return GoalAction.fromMap(data);
    }).toList();
  }

  @override
  Future<void> upsertAction(GoalAction action) async {
    final path = '${FirestorePaths.goalActions(action.goalId)}/${action.id}';
    await _upsertWithQueue(
      entityType: 'goalAction',
      path: path,
      payload: action.toMap(),
    );
  }

  @override
  Future<void> deleteAction({
    required String goalId,
    required String actionId,
  }) async {
    await _deleteWithQueue(
      entityType: 'goalAction',
      path: '${FirestorePaths.goalActions(goalId)}/$actionId',
    );
  }

  @override
  Future<List<GoalMilestone>> getMilestones(String goalId) async {
    final snap = await _goals
        .doc(goalId)
        .collection('milestones')
        .orderBy('orderIndex')
        .get();
    return snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return GoalMilestone.fromMap(data);
    }).toList();
  }

  @override
  Future<void> upsertMilestone(GoalMilestone milestone) async {
    final path =
        '${FirestorePaths.goalMilestones(milestone.goalId)}/${milestone.id}';
    await _upsertWithQueue(
      entityType: 'goalMilestone',
      path: path,
      payload: milestone.toMap(),
    );
  }

  @override
  Future<void> deleteMilestone({
    required String goalId,
    required String milestoneId,
  }) async {
    await _deleteWithQueue(
      entityType: 'goalMilestone',
      path: '${FirestorePaths.goalMilestones(goalId)}/$milestoneId',
    );
  }

  @override
  Future<void> upsertCheckIn(GoalCheckIn checkIn) async {
    final path =
        '${FirestorePaths.goalCheckIns(checkIn.goalId)}/${checkIn.dateKey}';
    await _upsertWithQueue(
      entityType: 'goalCheckIn',
      path: path,
      payload: checkIn.toMap(),
    );
  }

  @override
  Future<GoalCheckIn?> getTodayCheckIn(String goalId, String dateKey) async {
    final doc = await _goals
        .doc(goalId)
        .collection('checkIns')
        .doc(dateKey)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return GoalCheckIn.fromMap(Map<String, dynamic>.from(doc.data()!));
  }

  @override
  Future<List<GoalCheckIn>> getCheckInsForGoal(
    String goalId, {
    String? startDateKey,
    String? endDateKey,
  }) async {
    final snap = await _goals
        .doc(goalId)
        .collection('checkIns')
        .orderBy('dateKey')
        .get();
    var list = snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      return GoalCheckIn.fromMap(data);
    }).toList();
    if (startDateKey != null) {
      list = list.where((c) => c.dateKey.compareTo(startDateKey) >= 0).toList();
    }
    if (endDateKey != null) {
      list = list.where((c) => c.dateKey.compareTo(endDateKey) <= 0).toList();
    }
    return list;
  }
}
