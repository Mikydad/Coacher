/// One row per calendar day per goal; Firestore doc id = [dateKey] (`yyyy-MM-dd`).
class GoalCheckIn {
  const GoalCheckIn({
    required this.goalId,
    required this.dateKey,
    required this.metCommitment,
    required this.updatedAtMs,
    this.note,
  });

  final String goalId;
  final String dateKey;
  final bool metCommitment;
  final int updatedAtMs;
  final String? note;

  Map<String, dynamic> toMap() => {
    'goalId': goalId,
    'dateKey': dateKey,
    'metCommitment': metCommitment,
    'updatedAtMs': updatedAtMs,
    if (note != null) 'note': note,
  };

  static GoalCheckIn fromMap(Map<String, dynamic> map) => GoalCheckIn(
    goalId: map['goalId'] as String? ?? '',
    dateKey: map['dateKey'] as String? ?? '',
    metCommitment: map['metCommitment'] as bool? ?? false,
    updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    note: map['note'] as String?,
  );
}
