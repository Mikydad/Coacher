class GoalMilestone {
  const GoalMilestone({
    required this.id,
    required this.goalId,
    required this.title,
    required this.completed,
    required this.orderIndex,
  });

  final String id;
  final String goalId;
  final String title;
  final bool completed;
  final int orderIndex;

  GoalMilestone copyWith({
    String? id,
    String? goalId,
    String? title,
    bool? completed,
    int? orderIndex,
  }) {
    return GoalMilestone(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'goalId': goalId,
    'title': title,
    'completed': completed,
    'orderIndex': orderIndex,
  };

  static GoalMilestone fromMap(Map<String, dynamic> map) => GoalMilestone(
    id: map['id'] as String,
    goalId: map['goalId'] as String? ?? '',
    title: map['title'] as String? ?? '',
    completed: map['completed'] as bool? ?? false,
    orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
  );
}
