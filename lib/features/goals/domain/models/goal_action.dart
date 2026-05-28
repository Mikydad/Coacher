class GoalAction {
  const GoalAction({
    required this.id,
    required this.goalId,
    required this.title,
    required this.orderIndex,
    this.completed = false,
  });

  final String id;
  final String goalId;
  final String title;
  final int orderIndex;
  final bool completed;

  GoalAction copyWith({
    String? id,
    String? goalId,
    String? title,
    int? orderIndex,
    bool? completed,
  }) {
    return GoalAction(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'goalId': goalId,
    'title': title,
    'orderIndex': orderIndex,
    'completed': completed,
  };

  static GoalAction fromMap(Map<String, dynamic> map) => GoalAction(
    id: map['id'] as String,
    goalId: map['goalId'] as String? ?? '',
    title: map['title'] as String? ?? '',
    orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
    completed: map['completed'] as bool? ?? false,
  );
}
