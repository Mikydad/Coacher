class GoalMilestone {
  const GoalMilestone({
    required this.id,
    required this.goalId,
    required this.title,
    required this.completed,
    required this.orderIndex,
    this.updatedAtMs = 0,
  });

  final String id;
  final String goalId;
  final String title;
  final bool completed;
  final int orderIndex;

  /// Last local edit time — drives last-write-wins sync merging. `0` for
  /// legacy records; stamped by the repository on every upsert.
  final int updatedAtMs;

  GoalMilestone copyWith({
    String? id,
    String? goalId,
    String? title,
    bool? completed,
    int? orderIndex,
    int? updatedAtMs,
  }) {
    return GoalMilestone(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      orderIndex: orderIndex ?? this.orderIndex,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'goalId': goalId,
    'title': title,
    'completed': completed,
    'orderIndex': orderIndex,
    'updatedAtMs': updatedAtMs,
  };

  static GoalMilestone fromMap(Map<String, dynamic> map) => GoalMilestone(
    id: map['id'] as String,
    goalId: map['goalId'] as String? ?? '',
    title: map['title'] as String? ?? '',
    completed: map['completed'] as bool? ?? false,
    orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
    updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
  );
}
