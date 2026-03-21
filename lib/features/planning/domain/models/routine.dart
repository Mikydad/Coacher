import '../../../../core/validation/model_validators.dart';

class Routine {
  const Routine({
    required this.id,
    required this.title,
    required this.dateKey,
    required this.orderIndex,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String title;
  final String dateKey; // yyyy-MM-dd for tomorrow-plan grouping
  final int orderIndex;
  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'routine.id');
    ModelValidators.requireNotBlank(title, 'routine.title');
    ModelValidators.requireNotBlank(dateKey, 'routine.dateKey');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'dateKey': dateKey,
    'orderIndex': orderIndex,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static Routine fromMap(Map<String, dynamic> map) => Routine(
    id: map['id'] as String,
    title: map['title'] as String,
    dateKey: map['dateKey'] as String,
    orderIndex: map['orderIndex'] as int,
    createdAtMs: map['createdAtMs'] as int,
    updatedAtMs: map['updatedAtMs'] as int,
  );
}
