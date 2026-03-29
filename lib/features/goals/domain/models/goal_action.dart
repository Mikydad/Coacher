class GoalAction {
  const GoalAction({
    required this.id,
    required this.goalId,
    required this.title,
    required this.orderIndex,
  });

  final String id;
  final String goalId;
  final String title;
  final int orderIndex;

  Map<String, dynamic> toMap() => {
    'id': id,
    'goalId': goalId,
    'title': title,
    'orderIndex': orderIndex,
  };

  static GoalAction fromMap(Map<String, dynamic> map) => GoalAction(
    id: map['id'] as String,
    goalId: map['goalId'] as String? ?? '',
    title: map['title'] as String? ?? '',
    orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
  );
}
