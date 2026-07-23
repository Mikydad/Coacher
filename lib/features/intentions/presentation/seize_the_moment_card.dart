import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/intentions_providers.dart';
import '../domain/models/intention.dart';

/// "Seize the moment" (PRD §4.6) — shown only when the user is inside a
/// free window RIGHT NOW that fits an open promise. Quiet by design:
/// dismissing hides it for the session, never a modal, never a badge.
class SeizeTheMomentCard extends ConsumerWidget {
  const SeizeTheMomentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidate = ref.watch(seizeTheMomentProvider).valueOrNull;
    if (candidate == null) return const SizedBox.shrink();
    final intention = candidate.intention;

    final contextLine = candidate.beforeTitle == null
        ? 'You have about ${candidate.freeMinutes} min free.'
        : 'About ${candidate.freeMinutes} min before '
              '${candidate.beforeTitle}.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cyanBorder20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${intention.title} now?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            contextLine,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _markDone(ref, intention.id),
                child: const Text('Doing it'),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.fg70,
                ),
                onPressed: () => _dismiss(ref, intention.id),
                child: const Text('Not now'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _markDone(WidgetRef ref, String intentionId) async {
    await ref
        .read(intentionsRepositoryProvider)
        .updateStatus(
          intentionId,
          IntentionStatus.done,
          completedAtMs: DateTime.now().millisecondsSinceEpoch,
        );
    await ref
        .read(intentionNudgeSyncServiceProvider)
        .cancelForIntention(intentionId);
  }

  void _dismiss(WidgetRef ref, String intentionId) {
    final current = ref.read(dismissedSeizeCandidatesProvider);
    ref.read(dismissedSeizeCandidatesProvider.notifier).state = {
      ...current,
      intentionId,
    };
  }
}
