import 'dart:io';

import 'package:flutter/material.dart';

import '../../../planning/domain/sleep_task.dart';
import '../add_task_ui.dart';

/// Sleep-only extras card: sync the daily sleep window and (non-iOS) pick the
/// in-app quiet mode. Renders nothing for non-sleep categories. All mutation
/// flows back through the callbacks so the owning State's `setState` (and its
/// draft-dirty hook) stays the single write path.
class AddTaskSleepExtrasSection extends StatelessWidget {
  const AddTaskSleepExtrasSection({
    super.key,
    required this.category,
    required this.syncSleepWindowAndQuietMode,
    required this.inAppQuietMode,
    required this.onSyncChanged,
    required this.onQuietModeChanged,
    this.alarm = false,
    this.sleepEndLabel,
    this.onAlarmChanged,
  });

  final String? category;
  final bool syncSleepWindowAndQuietMode;

  /// `sleep` or `dnd`.
  final String inAppQuietMode;
  final ValueChanged<bool> onSyncChanged;
  final ValueChanged<String> onQuietModeChanged;

  /// Wake-up alarm (feat/alarm-mode): rings at sleep END — [sleepEndLabel]
  /// is the formatted end time for the subtitle. Inline here rather than
  /// behind the reminder card's chip because for Sleep the alarm IS the
  /// point, and it is on by default for new sleep tasks.
  final bool alarm;
  final String? sleepEndLabel;
  final ValueChanged<bool>? onAlarmChanged;

  @override
  Widget build(BuildContext context) {
    if (!isSleepCategory(category)) return const SizedBox.shrink();

    return Material(
      color: AddTaskColors.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onAlarmChanged != null) ...[
              AddTaskToggleRow(
                icon: Icons.alarm_rounded,
                iconColor: AddTaskColors.accent,
                title: 'Wake-up alarm',
                subtitle: sleepEndLabel == null
                    ? 'Rings at sleep end until you stop it'
                    : 'Rings at $sleepEndLabel until you stop it',
                value: alarm,
                onChanged: onAlarmChanged!,
              ),
              const SizedBox(height: 4),
            ],
            AddTaskToggleRow(
              icon: Icons.bedtime_rounded,
              iconColor: AddTaskColors.accentDim,
              title: 'Quiet hours & status',
              subtitle: Platform.isIOS
                  ? 'Updates your quiet hours; offers in-app Sleep or DND status'
                  : 'Updates your quiet hours and in-app quiet mode',
              value: syncSleepWindowAndQuietMode,
              onChanged: onSyncChanged,
            ),
            if (syncSleepWindowAndQuietMode && !Platform.isIOS) ...[
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'sleep', label: Text('Sleep')),
                  ButtonSegment(value: 'dnd', label: Text('DND')),
                ],
                selected: {inAppQuietMode},
                onSelectionChanged: (s) {
                  if (s.isEmpty) return;
                  onQuietModeChanged(s.first);
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
