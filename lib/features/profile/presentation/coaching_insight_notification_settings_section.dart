import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../analytics/application/coaching_insight_notification_policy.dart';
import '../application/profile_providers.dart';

import '../../../core/presentation/app_colors.dart';

/// Toggle and copy for coaching insight push notifications (Profile / Settings).
class CoachingInsightNotificationSettingsSection extends ConsumerWidget {
  const CoachingInsightNotificationSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefAsync = ref.watch(userProfilePreferenceStreamProvider);
    final enabled = prefAsync.whenOrNull(
          data: (p) => p?.coachingInsightNotificationsEnabled,
        ) ??
        true;
    final sentToday = prefAsync.whenOrNull(
          data: (p) {
            if (p == null) return 0;
            final normalized = coachingNotificationBudgetForDay(p, DateTime.now());
            return normalized.coachingNotificationSentAtMs.length;
          },
        ) ??
        0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coaching insight notifications',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enabled
                        ? 'Up to $kMaxCoachingInsightNotificationsPerDay per day, '
                            'at least ${kMinGapBetweenCoachingInsightNotifications.inHours}h apart. '
                            'Insights still show in Progress and on Home.'
                        : 'Push notifications off. Open the app to see coaching insights.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSoft,
                    ),
                  ),
                  if (enabled && sentToday > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Sent today: $sentToday / $kMaxCoachingInsightNotificationsPerDay',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.accentDim,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: enabled,
              activeTrackColor: AppColors.accentBright.withValues(alpha: 0.5),
              activeThumbColor: AppColors.accentBright,
              onChanged: prefAsync.isLoading
                  ? null
                  : (v) async {
                      await ref
                          .read(profilePreferenceServiceProvider)
                          .setCoachingInsightNotificationsEnabled(v);
                      if (!v) {
                        await ref
                            .read(localNotificationsServiceProvider)
                            .cancel(kCoachingInsightNotificationId);
                      }
                    },
            ),
          ],
        ),
      ],
    );
  }
}
