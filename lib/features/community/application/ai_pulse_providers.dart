import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_pulse_repository.dart';
import '../domain/models/ai_pulse.dart';
import 'circle_ai_pulse_service.dart';
import 'challenge_providers.dart';
import 'circle_providers.dart';

final aiPulseRepositoryProvider = Provider<AiPulseRepository>((ref) {
  return FirestoreAiPulseRepository();
});

final circleAiPulseServiceProvider = Provider<CircleAiPulseService>((ref) {
  return CircleAiPulseService(
    pulseRepo: ref.read(aiPulseRepositoryProvider),
    feedRepo: ref.read(activityFeedRepositoryProvider),
    challengeRepo: ref.read(challengeRepositoryProvider),
  );
});

final latestDailyPulseProvider = StreamProvider.family<AiPulse?, String>((
  ref,
  circleId,
) {
  return ref
      .watch(aiPulseRepositoryProvider)
      .watchLatestPulse(circleId, AiPulseType.daily);
});

final latestWeeklyPulseProvider = StreamProvider.family<AiPulse?, String>((
  ref,
  circleId,
) {
  return ref
      .watch(aiPulseRepositoryProvider)
      .watchLatestPulse(circleId, AiPulseType.weekly);
});
