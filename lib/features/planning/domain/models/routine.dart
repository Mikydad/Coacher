import '../../../../core/validation/model_validators.dart';
import 'routine_mode.dart';

class Routine {
  const Routine({
    required this.id,
    required this.title,
    required this.dateKey,
    required this.orderIndex,
    this.modeId = 'flexible',
    this.mode = RoutineMode.flexible,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String title;
  final String dateKey; // yyyy-MM-dd for tomorrow-plan grouping
  final int orderIndex;
  /// Stable mode config id. Built-ins: `flexible`, `disciplined`, `extreme`.
  final String modeId;
  /// Base mode for policy derivation, independent from custom labels.
  final RoutineMode mode;
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
    'modeId': modeId,
    'mode': mode.storageValue,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static Routine fromMap(Map<String, dynamic> map) => Routine(
    id: map['id'] as String? ?? '',
    title: map['title'] as String? ?? 'Daily plan',
    dateKey: map['dateKey'] as String? ?? '',
    orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
    modeId: map['modeId'] as String? ?? 'flexible',
    mode: RoutineModeStorage.fromStorage(map['mode'] as String?),
    createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
    updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
  );
}
