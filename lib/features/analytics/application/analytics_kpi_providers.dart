import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/application/auth_providers.dart';
import 'kpi_engine.dart';

final habitKpiSnapshotProvider = FutureProvider.family<HabitKpiSnapshot, String>((
  ref,
  habitId,
) async {
  // Rebuild on account switch so cached values never leak across users.
  ref.watch(authUidProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  final events = await repo.listEvents(entityId: habitId);
  return computeHabitKpisFromEvents(events);
});
