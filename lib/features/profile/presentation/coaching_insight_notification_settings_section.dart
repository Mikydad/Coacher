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
    final enabled =
        prefAsync.whenOrNull(
          data: (p) => p?.coachingInsightNotificationsEnabled,
        ) ??
        true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coaching insights',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enabled
                        ? 'Get occasional observations and suggestions based '
                              'on how your days are going. A few a day at most.'
                        : 'Off. Coaching insights still show in the app.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: enabled,
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
