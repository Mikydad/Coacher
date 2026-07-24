import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/utils/date_keys.dart';
import '../../analytics/application/insight_generation_providers.dart';
import '../../analytics/domain/models/generated_insight.dart';
import '../../thinking/application/thinking_loop_service.dart';
import '../application/intentions_providers.dart';
import '../domain/models/intention.dart';

/// "On your radar" (humanizing Phase 7b) — the quiet collapsed tail of
/// the Promises section. Standing understandings, not obligations:
/// dormant intentions (extraction Phase 2 + reflection Phase 7) and
/// today's reflection observation, all generating ZERO notifications
/// until the user engages.
///
/// Interactions are the whole point of surfacing them:
/// - "Remind me" promotes a dormant intention to `open` — it becomes
///   plannable and the nudge ladder arms immediately (Isar-only);
/// - dismissing retires it (synced status, so it stays dismissed on
///   every device);
/// - the observation is labeled INFERRED (provenance honesty) and its
///   dismissal clears the reflection insight scope.
///
/// Collapsed by default — radar content must never compete with open
/// promises. Hidden entirely when there is nothing on the radar.
class OnYourRadarSection extends ConsumerStatefulWidget {
  const OnYourRadarSection({super.key});

  @override
  ConsumerState<OnYourRadarSection> createState() =>
      _OnYourRadarSectionState();
}

class _OnYourRadarSectionState extends ConsumerState<OnYourRadarSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final radar = ref.watch(radarIntentionsProvider);
    final observation = _todayObservation(ref);
    final count = radar.length + (observation != null ? 1 : 0);
    if (count == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  'ON YOUR RADAR · $count',
                  style: TextStyle(
                    color: AppColors.fg54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 260),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: AppColors.fg54,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_expanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfacePanel,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.fg12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        if (observation != null)
                          _ObservationRow(observation: observation),
                        if (observation != null && radar.isNotEmpty)
                          Divider(height: 1, color: AppColors.fg12),
                        for (var i = 0; i < radar.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: AppColors.fg12),
                          _RadarRow(intention: radar[i]),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// Today's reflection observation, if the Thinking Loop produced one.
  /// Day-scoped by construction (source window today..today), so
  /// yesterday's reflection never lingers here.
  GeneratedInsight? _todayObservation(WidgetRef ref) {
    final insights =
        ref
            .watch(
              layer3EntityInsightsProvider(
                ThinkingLoopService.reflectionScopeId,
              ),
            )
            .valueOrNull ??
        const [];
    final today = DateKeys.todayKey();
    for (final insight in insights) {
      if (insight.insightType != InsightType.reflectionObservation) continue;
      if (!layer3InsightActiveOnDateKey(insight, today)) continue;
      return insight;
    }
    return null;
  }
}

/// The day's reflection observation — hedged AI text, honestly labeled.
class _ObservationRow extends ConsumerWidget {
  const _ObservationRow({required this.observation});

  final GeneratedInsight observation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.psychology_outlined,
              size: 18,
              color: AppColors.fg54,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  observation.message,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'INFERRED',
                  style: TextStyle(
                    color: AppColors.fg54,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _dismiss(ref),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: AppColors.fg54),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dismiss(WidgetRef ref) async {
    await ref
        .read(insightCacheRepositoryProvider)
        .replaceScopeInsights(
          scopeType: InsightScopeType.entity,
          scopeId: ThinkingLoopService.reflectionScopeId,
          insights: const [],
        );
  }
}

/// One dormant intention: a standing understanding with two quiet exits —
/// wake it ("Remind me" → open, plannable, ladder arms now) or retire it.
class _RadarRow extends ConsumerWidget {
  const _RadarRow({required this.intention});

  final Intention intention;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              intention.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () => _promote(ref),
            child: Text(
              'Remind me',
              style: TextStyle(color: AppColors.cyan, fontSize: 12),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _dismiss(ref),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: AppColors.fg54),
            ),
          ),
        ],
      ),
    );
  }

  /// Dormant → open: the local write IS the update; the nudge ladder is
  /// planned right away, airplane-safe.
  Future<void> _promote(WidgetRef ref) async {
    final updated = await ref
        .read(intentionsRepositoryProvider)
        .updateStatus(intention.id, IntentionStatus.open);
    if (updated == null) return;
    try {
      await ref
          .read(intentionNudgeSyncServiceProvider)
          .applyForIntention(updated);
    } catch (_) {}
  }

  Future<void> _dismiss(WidgetRef ref) async {
    await ref
        .read(intentionsRepositoryProvider)
        .updateStatus(intention.id, IntentionStatus.dismissed);
  }
}
