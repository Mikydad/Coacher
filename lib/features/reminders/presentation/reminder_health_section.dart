import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/reminder_health_provider.dart';
import '../domain/models/reminder_health.dart';

/// "Reminder health" in Settings → Notifications (FR-R-80).
///
/// Every line here used to be a `debugPrint` and nothing else (AUDIT §10 L5).
/// A user whose notification permission was revoked, or whose timezone failed
/// to resolve, had no way to find out why SidePal had gone quiet. This is the
/// page that answers "why didn't it fire?".
class ReminderHealthSection extends ConsumerWidget {
  const ReminderHealthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reminderHealthProvider);

    return async.when(
      loading: () => const _HealthRow(label: 'Status', value: 'Checking…'),
      error: (e, _) =>
          const _HealthRow(label: 'Status', value: 'Could not check'),
      data: (health) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HealthRow(
            label: 'Status',
            value: health.summaryLine,
            tone: health.isHealthy ? _Tone.good : _Tone.warn,
          ),
          _HealthRow(
            label: 'System permission',
            value: switch (health.permitted) {
              true => 'Allowed',
              false => 'Blocked',
              null => 'Unknown',
            },
            tone: health.permitted == false ? _Tone.warn : _Tone.neutral,
          ),
          _HealthRow(
            label: 'Scheduled now',
            value: health.pendingCount == null
                ? 'Unknown'
                : '${health.pendingCount} of ${health.pendingCap}',
            tone: health.pendingNearCap ? _Tone.warn : _Tone.neutral,
          ),
          _HealthRow(
            label: 'Time zone',
            value: health.timeZoneResolved
                ? (health.timeZoneName ?? 'Resolved')
                : 'Unresolved — retrying',
            tone: health.timeZoneResolved ? _Tone.neutral : _Tone.warn,
          ),
          _HealthRow(
            label: 'Last check',
            value: health.lastReconciliationSummary ?? 'Not run yet',
          ),
          _HealthRow(
            label: 'Server backup',
            value: health.pushRegistered ? 'Registered' : 'Not registered',
          ),
          for (final issue in health.issues) _IssueNote(issue: issue),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: TextButton(
              onPressed: () => ref.invalidate(reminderHealthProvider),
              child: const Text('Re-check'),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Tone { neutral, good, warn }

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.label,
    required this.value,
    this.tone = _Tone.neutral,
  });

  final String label;
  final String value;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: switch (tone) {
                  _Tone.warn => AppColors.amber,
                  _Tone.good => AppColors.textPrimary,
                  _Tone.neutral => AppColors.textPrimary,
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueNote extends StatelessWidget {
  const _IssueNote({required this.issue});

  final ReminderHealthIssue issue;

  @override
  Widget build(BuildContext context) {
    final isNote = issue.severity == ReminderHealthSeverity.note;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            issue.title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isNote ? AppColors.textMuted : AppColors.amber,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            issue.detail,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The quiet Home hint (FR-R-80): one thin, dismissible line, shown only when
/// reminders genuinely cannot do their job.
///
/// Follows the stuck-writes line's contract — silence is the normal state,
/// and this appears only for a real fault, never for the Android timing note.
class ReminderHealthHomeHint extends ConsumerStatefulWidget {
  const ReminderHealthHomeHint({super.key});

  @override
  ConsumerState<ReminderHealthHomeHint> createState() =>
      _ReminderHealthHomeHintState();
}

class _ReminderHealthHomeHintState
    extends ConsumerState<ReminderHealthHomeHint> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final health = ref.watch(reminderHealthProvider).valueOrNull;
    if (health == null || health.isHealthy) return const SizedBox.shrink();

    final worst = health.faults.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 3, height: 28, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              worst.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _dismissed = true),
            icon: Icon(Icons.close, size: 15, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
