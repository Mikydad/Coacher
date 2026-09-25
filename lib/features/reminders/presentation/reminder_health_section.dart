import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/reminder_health_provider.dart';
import '../domain/models/reminder_health.dart';

/// "Reminder status" in Settings → Notifications (FR-R-80).
///
/// Every line here used to be a `debugPrint` and nothing else (AUDIT §10 L5).
/// A user whose notification permission was revoked, or whose timezone failed
/// to resolve, had no way to find out why SidePal had gone quiet. This is the
/// page that answers "why didn't it fire?".
///
/// Written for the person, not the engineer (2026-09-23): an external tester
/// read "Server backup: Not registered" as a lost-data blocker and "Last
/// check: Not run yet" as a dead job. Each row that describes internal state
/// now says what it means and whether it matters, and the snapshot is taken
/// afresh every time this panel opens — the provider is otherwise cached for
/// the life of the process, so a second visit hours later showed the first
/// visit's numbers.
class ReminderHealthSection extends ConsumerStatefulWidget {
  const ReminderHealthSection({super.key});

  @override
  ConsumerState<ReminderHealthSection> createState() =>
      _ReminderHealthSectionState();
}

class _ReminderHealthSectionState extends ConsumerState<ReminderHealthSection> {
  /// The six internal-state rows sit behind a plain "Details" toggle
  /// (2026-09-25): the default view is two sentences a tester can act on.
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    // Fresh reading on every open; the Home hint shares the same provider
    // and simply picks up the newer snapshot.
    ref.invalidate(reminderHealthProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reminderHealthProvider);

    return async.when(
      loading: () => const _StatusLine('Checking…'),
      error: (e, _) => const _StatusLine('Could not check', warn: true),
      data: (health) {
        final blocking = health.faults.isEmpty ? null : health.faults.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusLine(
              blocking?.title ?? 'Everything is working',
              warn: blocking != null,
            ),
            const SizedBox(height: 6),
            _PermissionLine(permitted: health.permitted),
            // The first fault already headlines the status line; its note
            // keeps only the detail so the title is not read twice.
            for (final issue in health.issues)
              _IssueNote(issue: issue, hideTitle: identical(issue, blocking)),
            const SizedBox(height: 4),
            _DetailsToggle(
              open: _showDetails,
              onTap: () => setState(() => _showDetails = !_showDetails),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _showDetails
                  ? _DetailRows(health: health)
                  : const SizedBox(width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextButton(
                onPressed: () => ref.invalidate(reminderHealthProvider),
                child: const Text('Check again'),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The one line that answers "are my reminders working?".
class _StatusLine extends StatelessWidget {
  const _StatusLine(this.text, {this.warn = false});

  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: warn ? AppColors.amber : AppColors.textPrimary,
      ),
    );
  }
}

/// Whether the system lets SidePal notify at all — the one fix most people
/// can actually make themselves.
class _PermissionLine extends StatelessWidget {
  const _PermissionLine({required this.permitted});

  final bool? permitted;

  @override
  Widget build(BuildContext context) {
    final text = switch (permitted) {
      true => 'SidePal has permission to send reminders.',
      false =>
        'SidePal is not allowed to send reminders. Turn them on in Settings.',
      null => 'Checking…',
    };
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 1.35,
        color: permitted == false ? AppColors.amber : AppColors.textMuted,
      ),
    );
  }
}

/// Plain text toggle in the file's own quiet style — no chevron, no card.
class _DetailsToggle extends StatelessWidget {
  const _DetailsToggle({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(open ? 'Hide details' : 'Details'),
      ),
    );
  }
}

/// The six rows that used to be the whole panel, each with its explainer.
class _DetailRows extends StatelessWidget {
  const _DetailRows({required this.health});

  final ReminderHealth health;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          label: 'Armed right now',
          value: health.pendingCount == null
              ? 'Unknown'
              : '${health.pendingCount} of ${health.pendingCap}',
          tone: health.pendingNearCap ? _Tone.warn : _Tone.neutral,
        ),
        _Explainer(
          "Today's reminders are armed in full; later days hold one slot "
          'each until they arrive, so a low number is normal. '
          "${health.pendingCap} is SidePal's safe share of the system's "
          '64-notification limit.',
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
          value:
              health.lastReconciliationSummary ??
              'Not yet since the app opened',
        ),
        const _Explainer(
          'Runs each time the app opens or comes back. It confirms what '
          'fired and re-arms anything the system dropped.',
        ),
        _HealthRow(
          label: 'Push backup',
          value: health.pushRegistered ? 'Connected' : 'Not connected yet',
        ),
        if (!health.pushRegistered)
          const _Explainer(
            'A server nudge that can wake SidePal after it has been closed '
            'for days. Reminders work without it; it connects by itself '
            'once notifications and a network are available.',
          ),
      ],
    );
  }
}

enum _Tone { neutral, good, warn }

/// One quiet sentence under a row whose value is internal state.
class _Explainer extends StatelessWidget {
  const _Explainer(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

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
  const _IssueNote({required this.issue, this.hideTitle = false});

  final ReminderHealthIssue issue;

  /// True when the title is already shown as the status line above.
  final bool hideTitle;

  @override
  Widget build(BuildContext context) {
    final isNote = issue.severity == ReminderHealthSeverity.note;
    return Padding(
      padding: EdgeInsets.only(top: hideTitle ? 4 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hideTitle) ...[
            Text(
              issue.title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isNote ? AppColors.textMuted : AppColors.amber,
              ),
            ),
            const SizedBox(height: 2),
          ],
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
