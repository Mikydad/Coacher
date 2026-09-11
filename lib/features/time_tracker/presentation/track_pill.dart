import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/time_tracker_providers.dart';
import 'track_activity_sheet.dart';

/// Home's capture entry (decision 9 + F3): one thin pill under the action
/// circles — `◷ Track what you're doing +` — that opens the capture sheet
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
      label = "Track what you're doing";
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('track_pill'),
        borderRadius: BorderRadius.circular(20),
        onTap: () => showTrackActivitySheet(context),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.fg.withAlpha(12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_outlined, size: 16, color: AppColors.textSoft),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ongoing == null ? AppColors.textSoft : AppColors.fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.add, size: 18, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
