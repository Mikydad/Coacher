import 'package:isar/isar.dart';

import '../../../features/planning/domain/models/block.dart';

part 'isar_block.g.dart';

@collection
class IsarBlock {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String blockId;

  @Index()
  late String routineId;

  late String title;
  late int orderIndex;
  int? startMinutesFromMidnight;
  int? endMinutesFromMidnight;
  late int urgencyScore;
  String? modeRefId;
  late int createdAtMs;
  late int updatedAtMs;

  static IsarBlock fromDomain(TaskBlock b) {
    return IsarBlock()
      ..blockId = b.id
      ..routineId = b.routineId
      ..title = b.title
      ..orderIndex = b.orderIndex
      ..startMinutesFromMidnight = b.startMinutesFromMidnight
      ..endMinutesFromMidnight = b.endMinutesFromMidnight
      ..urgencyScore = b.urgencyScore
      ..modeRefId = b.modeRefId
      ..createdAtMs = b.createdAtMs
      ..updatedAtMs = b.updatedAtMs;
  }

  TaskBlock toDomain() {
    return TaskBlock(
      id: blockId,
      routineId: routineId,
      title: title,
      orderIndex: orderIndex,
      startMinutesFromMidnight: startMinutesFromMidnight,
      endMinutesFromMidnight: endMinutesFromMidnight,
      urgencyScore: urgencyScore,
      modeRefId: modeRefId,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
