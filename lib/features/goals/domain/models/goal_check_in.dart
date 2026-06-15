/// One row per calendar day per goal; Firestore doc id = [dateKey] (`yyyy-MM-dd`).
///
/// [value] is the numeric amount logged for the day (e.g. 3 sessions, 45 minutes).
/// When null, only [metCommitment] is meaningful (legacy boolean-only check-ins).
class GoalCheckIn {
  const GoalCheckIn({
    required this.goalId,
    required this.dateKey,
    required this.metCommitment,
    required this.updatedAtMs,
    this.value,
    this.note,
  });

  final String goalId;
  final String dateKey;
  final bool metCommitment;
  final int updatedAtMs;

  /// Numeric progress logged for this day. Null for legacy boolean-only check-ins.
  final double? value;
  final String? note;

  GoalCheckIn copyWith({
    String? goalId,
    String? dateKey,
    bool? metCommitment,
    int? updatedAtMs,
    double? value,
    String? note,
  }) =>
      GoalCheckIn(
        goalId: goalId ?? this.goalId,
        dateKey: dateKey ?? this.dateKey,
        metCommitment: metCommitment ?? this.metCommitment,
        updatedAtMs: updatedAtMs ?? this.updatedAtMs,
        value: value ?? this.value,
        note: note ?? this.note,
      );

  Map<String, dynamic> toMap() => {
    'goalId': goalId,
    'dateKey': dateKey,
    'metCommitment': metCommitment,
    'updatedAtMs': updatedAtMs,
    if (value != null) 'value': value,
    if (note != null) 'note': note,
  };

  static GoalCheckIn fromMap(Map<String, dynamic> map) => GoalCheckIn(
    goalId: map['goalId'] as String? ?? '',
    dateKey: map['dateKey'] as String? ?? '',
    metCommitment: map['metCommitment'] as bool? ?? false,
    updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    value: (map['value'] as num?)?.toDouble(),
    note: map['note'] as String?,
  );
}
