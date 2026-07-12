import 'package:isar_community/isar.dart';

import '../../../features/goals/domain/models/goal_check_in.dart';

part 'isar_goal_check_in.g.dart';

/// Local mirror of `users/{uid}/goals/{goalId}/checkIns/{dateKey}` —
/// see [IsarGoalAction] for the replication model. One row per goal per
/// local calendar day, keyed by [checkInKey] (`goalId|dateKey`).
@collection
class IsarGoalCheckIn {
  Id id = Isar.autoIncrement;

  /// `'$goalId|$dateKey'` — the natural composite key as a single unique
  /// index so upserts stay one `putBy` call.
  @Index(unique: true)
  late String checkInKey;

  @Index()
  late String goalId;

  @Index()
  late String dateKey;

  late bool metCommitment;
  double? value;
  String? note;

  @Index()
  late int updatedAtMs;

  static String keyFor(String goalId, String dateKey) => '$goalId|$dateKey';

  static IsarGoalCheckIn fromDomain(GoalCheckIn c) {
    return IsarGoalCheckIn()
      ..checkInKey = keyFor(c.goalId, c.dateKey)
      ..goalId = c.goalId
      ..dateKey = c.dateKey
      ..metCommitment = c.metCommitment
      ..value = c.value
      ..note = c.note
      ..updatedAtMs = c.updatedAtMs;
  }

  GoalCheckIn toDomain() {
    return GoalCheckIn(
      goalId: goalId,
      dateKey: dateKey,
      metCommitment: metCommitment,
      updatedAtMs: updatedAtMs,
      value: value,
      note: note,
    );
  }
}
