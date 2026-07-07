const Object _sentinel = Object();

/// A single accountability commitment a user sets for a circle week.
///
/// [weekKey] uses ISO 8601 format: `'yyyy-Www'` (e.g. `'2026-W21'`).
class WeeklyCommitment {
  const WeeklyCommitment({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.title,
    required this.targetCount,
    required this.completedCount,
    required this.weekKey,
    required this.updatedAtMs,
  });

  final String id;
  final String circleId;
  final String userId;

  /// Short commitment label, e.g. `'Workout ×5'`.
  final String title;

  /// How many times this week the user intends to do this. Range: 1–7.
  final int targetCount;

  /// How many times already completed. Must be ≤ [targetCount].
  final int completedCount;

  /// ISO week key: `'yyyy-Www'`.
  final String weekKey;

  final int updatedAtMs;

  void validate() {
    if (title.trim().isEmpty) {
      throw ArgumentError('weekly_commitment.title must not be empty');
    }
    if (targetCount < 1 || targetCount > 7) {
      throw ArgumentError(
        'weekly_commitment.targetCount must be 1–7, got $targetCount',
      );
    }
    if (completedCount > targetCount) {
      throw ArgumentError(
        'weekly_commitment.completedCount ($completedCount) exceeds targetCount ($targetCount)',
      );
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'circleId': circleId,
    'userId': userId,
    'title': title,
    'targetCount': targetCount,
    'completedCount': completedCount,
    'weekKey': weekKey,
    'updatedAtMs': updatedAtMs,
  };

  static WeeklyCommitment fromMap(Map<String, dynamic> map) {
    return WeeklyCommitment(
      id: map['id'] as String? ?? '',
      circleId: map['circleId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      targetCount: (map['targetCount'] as num?)?.toInt() ?? 1,
      completedCount: (map['completedCount'] as num?)?.toInt() ?? 0,
      weekKey: map['weekKey'] as String? ?? '',
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  WeeklyCommitment copyWith({
    String? id,
    String? circleId,
    String? userId,
    String? title,
    int? targetCount,
    int? completedCount,
    String? weekKey,
    int? updatedAtMs,
  }) {
    return WeeklyCommitment(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetCount: targetCount ?? this.targetCount,
      completedCount: completedCount ?? this.completedCount,
      weekKey: weekKey ?? this.weekKey,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}
