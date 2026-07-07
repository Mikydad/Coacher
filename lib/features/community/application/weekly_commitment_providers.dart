import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../data/weekly_commitment_repository.dart';
import '../domain/models/weekly_commitment.dart';

final weeklyCommitmentRepositoryProvider = Provider<WeeklyCommitmentRepository>(
  (ref) => FirestoreWeeklyCommitmentRepository(),
);

/// Live stream of all weekly commitments for a circle (current ISO week).
final circleWeeklyCommitmentsProvider =
    StreamProvider.family<List<WeeklyCommitment>, String>((ref, circleId) {
      final weekKey = DateKeys.isoWeekKey(DateTime.now());
      return ref
          .watch(weeklyCommitmentRepositoryProvider)
          .watchCommitments(circleId, weekKey: weekKey);
    });
