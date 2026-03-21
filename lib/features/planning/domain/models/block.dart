import '../../../../core/validation/model_validators.dart';

class TaskBlock {
  const TaskBlock({
    required this.id,
    required this.routineId,
    required this.title,
    required this.orderIndex,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String routineId;
  final String title;
  final int orderIndex;
  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'block.id');
    ModelValidators.requireNotBlank(routineId, 'block.routineId');
    ModelValidators.requireNotBlank(title, 'block.title');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'routineId': routineId,
    'title': title,
    'orderIndex': orderIndex,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static TaskBlock fromMap(Map<String, dynamic> map) => TaskBlock(
    id: map['id'] as String,
    routineId: map['routineId'] as String,
    title: map['title'] as String,
    orderIndex: map['orderIndex'] as int,
    createdAtMs: map['createdAtMs'] as int,
    updatedAtMs: map['updatedAtMs'] as int,
  );
}
