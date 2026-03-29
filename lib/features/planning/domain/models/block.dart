import '../../../../core/validation/model_validators.dart';

class TaskBlock {
  const TaskBlock({
    required this.id,
    required this.routineId,
    required this.title,
    required this.orderIndex,
    this.startMinutesFromMidnight,
    this.endMinutesFromMidnight,
    this.urgencyScore = 0,
    this.modeRefId,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String routineId;
  final String title;
  final int orderIndex;
  /// Optional local-time schedule window for the block (0..1439).
  final int? startMinutesFromMidnight;
  final int? endMinutesFromMidnight;
  /// Snapshot urgency score (0..100) used for UI sorting/highlighting.
  final int urgencyScore;
  /// Optional policy reference to a mode config id.
  final String? modeRefId;
  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'block.id');
    ModelValidators.requireNotBlank(routineId, 'block.routineId');
    ModelValidators.requireNotBlank(title, 'block.title');
    if (startMinutesFromMidnight != null &&
        (startMinutesFromMidnight! < 0 || startMinutesFromMidnight! > 1439)) {
      throw ArgumentError('block.startMinutesFromMidnight must be 0..1439');
    }
    if (endMinutesFromMidnight != null &&
        (endMinutesFromMidnight! < 0 || endMinutesFromMidnight! > 1439)) {
      throw ArgumentError('block.endMinutesFromMidnight must be 0..1439');
    }
    if (urgencyScore < 0 || urgencyScore > 100) {
      throw ArgumentError('block.urgencyScore must be 0..100');
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'routineId': routineId,
    'title': title,
    'orderIndex': orderIndex,
    if (startMinutesFromMidnight != null) 'startMinutesFromMidnight': startMinutesFromMidnight,
    if (endMinutesFromMidnight != null) 'endMinutesFromMidnight': endMinutesFromMidnight,
    'urgencyScore': urgencyScore,
    if (modeRefId != null) 'modeRefId': modeRefId,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static TaskBlock fromMap(Map<String, dynamic> map) => TaskBlock(
    id: map['id'] as String? ?? '',
    routineId: map['routineId'] as String? ?? '',
    title: map['title'] as String? ?? 'Main',
    orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
    startMinutesFromMidnight: (map['startMinutesFromMidnight'] as num?)?.toInt(),
    endMinutesFromMidnight: (map['endMinutesFromMidnight'] as num?)?.toInt(),
    urgencyScore: (map['urgencyScore'] as num?)?.toInt() ?? 0,
    modeRefId: map['modeRefId'] as String?,
    createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
    updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
  );
}
