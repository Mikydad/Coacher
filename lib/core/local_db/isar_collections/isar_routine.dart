import 'package:isar/isar.dart';

import '../../../features/planning/domain/models/routine.dart';
import '../../../features/planning/domain/models/routine_mode.dart';

part 'isar_routine.g.dart';

@collection
class IsarRoutine {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String routineId;

  @Index()
  late String dateKey;

  late String title;
  late int orderIndex;
  late String modeId;
  late String modeStorage;
  late int createdAtMs;
  late int updatedAtMs;

  static IsarRoutine fromDomain(Routine r) {
    return IsarRoutine()
      ..routineId = r.id
      ..dateKey = r.dateKey
      ..title = r.title
      ..orderIndex = r.orderIndex
      ..modeId = r.modeId
      ..modeStorage = r.mode.storageValue
      ..createdAtMs = r.createdAtMs
      ..updatedAtMs = r.updatedAtMs;
  }

  Routine toDomain() {
    return Routine(
      id: routineId,
      title: title,
      dateKey: dateKey,
      orderIndex: orderIndex,
      modeId: modeId,
      mode: RoutineModeStorage.fromStorage(modeStorage),
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
