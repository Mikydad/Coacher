import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../../auth/application/auth_providers.dart';
import '../data/weekly_commitment_repository.dart';
import '../domain/models/weekly_commitment.dart';

final weeklyCommitmentRepositoryProvider = Provider<WeeklyCommitmentRepository>(
  (ref) => FirestoreWeeklyCommitmentRepository(),
);

/// Live stream of all weekly commitments for a circle (current ISO week).
final circleWeeklyCommitmentsProvider =
    StreamProvider.family<List<WeeklyCommitment>, String>((ref, circleId) {
      // Auth-scoped (audit H6).
      final uid = ref.watch(authUidProvider);
      if (uid == null || uid.isEmpty) return Stream.value(const []);
      final weekKey = DateKeys.isoWeekKey(DateTime.now());
      return ref
          .watch(weeklyCommitmentRepositoryProvider)
          .watchCommitments(circleId, weekKey: weekKey);
    });

/// Optimistic ticks (2026-09-19): commitment id → the completed count the
/// user has just confirmed, shown at once while the Firestore transaction
/// runs. The row displays max(stored, expected); an entry is dropped on
/// failure, and once the stream has caught up. Only ever raises a count —
/// never a phantom tick the server did not accept for long.
final commitmentExpectedCountProvider = StateProvider<Map<String, int>>(
  (ref) => const {},
);
