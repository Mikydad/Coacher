import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_colors.dart';
import '../application/time_tracker_providers.dart';
import 'track_activity_sheet.dart';

/// Home's capture entry (decision 9 + F3): one thin pill under the action
/// circles — `◷ Track your time +` — that opens the capture sheet
/// and nothing else. When something is ongoing it reads
/// `◷ Scrolling · since 10:03 PM +`, so the pill doubles as the
/// "what am I doing" reminder without a card or a notification.
class TrackPill extends ConsumerWidget {
  const TrackPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongoing = ref.watch(ongoingActivityProvider);
    final String label;
    if (ongoing == null) {
      label = 'Track your time';
    } else {
      final loc = MaterialLocalizations.of(context);
      final since = loc.formatTimeOfDay(
        TimeOfDay.fromDateTime(
          DateTime.fromMillisecondsSinceEpoch(ongoing.startedAtMs),
        ),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
      label = '${ongoing.text} · since $since';
    }

    // Redesign 2026-09-14: a white pill with a soft shadow — clock in a
    // light disc, olive + in a pale-green disc. The whole pill is one tap
    // target; the + is its own button to the same sheet.
    final radius = BorderRadius.circular(999);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfacePanel,
        borderRadius: radius,
        boxShadow: appCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('track_pill'),
          borderRadius: radius,
          onTap: () => showTrackActivitySheet(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule_outlined,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ongoing == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppCircleIconButton(
                  icon: Icons.add_rounded,
                  size: 40,
                  iconSize: 22,
                  iconColor: AppColors.accent,
                  background: AppColors.actionTint,
                  shadow: false,
                  tooltip: 'Log an activity',
                  onPressed: () => showTrackActivitySheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
