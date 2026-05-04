import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import 'kpi_engine.dart';

final habitKpiSnapshotProvider = FutureProvider.family<HabitKpiSnapshot, String>((
  ref,
  habitId,
) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final events = await repo.listEvents(entityId: habitId);
  return computeHabitKpisFromEvents(events);
});
