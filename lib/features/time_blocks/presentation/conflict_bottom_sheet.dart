import 'package:flutter/material.dart';

import '../domain/models/time_conflict.dart';

/// What the user chose in the conflict bottom sheet.
enum ConflictAction { saveAnyway, adjustTime, shortenDuration }

/// Shows a bottom sheet listing scheduling conflicts and asks the user
/// how to proceed. Never hard-blocks saving — the user always has a path
/// through.
class ConflictBottomSheet extends StatelessWidget {
  const ConflictBottomSheet._({required this.conflicts});

  final List<TimeConflict> conflicts;

  /// Show the bottom sheet and return the user's chosen [ConflictAction],
  /// or null if dismissed without choosing.
  static Future<ConflictAction?> show({
    required BuildContext context,
    required List<TimeConflict> conflicts,
  }) {
    return showModalBottomSheet<ConflictAction>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ConflictBottomSheet._(conflicts: conflicts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final worst = conflicts
        .map((c) => c.severityLabel)
        .reduce((a, b) => a.index > b.index ? a : b);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: _worstColor(worst),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Scheduling Conflict',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              conflicts.length == 1
                  ? 'This task overlaps 1 existing item.'
                  : 'This task overlaps ${conflicts.length} existing items.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: 16),

            // Conflict list
            for (final conflict in conflicts.take(4)) ...[
              _ConflictRow(conflict: conflict),
              const SizedBox(height: 8),
            ],
            if (conflicts.length > 4)
              Text(
                '+${conflicts.length - 4} more conflicts',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Colors.white12),
            const SizedBox(height: 16),

            // Action buttons
            _ActionButton(
              label: 'Save anyway',
              subtitle: 'Keep this schedule even with the overlap.',
              icon: Icons.check_circle_outline,
              color: Colors.white,
              onTap: () => Navigator.pop(context, ConflictAction.saveAnyway),
            ),
            const SizedBox(height: 10),
            _ActionButton(
              label: 'Adjust time',
              subtitle: 'Go back and change the scheduled time.',
              icon: Icons.schedule,
              color: Colors.blueAccent,
              onTap: () => Navigator.pop(context, ConflictAction.adjustTime),
            ),
            const SizedBox(height: 10),
            _ActionButton(
              label: 'Shorten duration',
              subtitle: 'Reduce how long this task takes.',
              icon: Icons.compress,
              color: Colors.orangeAccent,
              onTap: () =>
                  Navigator.pop(context, ConflictAction.shortenDuration),
            ),
          ],
        ),
      ),
    );
  }

  Color _worstColor(ConflictSeverity severity) {
    switch (severity) {
      case ConflictSeverity.minor:
        return Colors.yellow;
      case ConflictSeverity.moderate:
        return Colors.orange;
      case ConflictSeverity.severe:
        return Colors.red;
    }
  }
}

class _ConflictRow extends StatelessWidget {
  const _ConflictRow({required this.conflict});

  final TimeConflict conflict;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _severityColor(conflict.severityLabel),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            conflict.conflictingEntityTitle,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _severityColor(conflict.severityLabel).withAlpha(40),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${conflict.overlapMinutes}m overlap · ${conflict.severityLabel.name}',
            style: TextStyle(
              fontSize: 11,
              color: _severityColor(conflict.severityLabel),
            ),
          ),
        ),
      ],
    );
  }

  Color _severityColor(ConflictSeverity severity) {
    switch (severity) {
      case ConflictSeverity.minor:
        return Colors.yellow;
      case ConflictSeverity.moderate:
        return Colors.orange;
      case ConflictSeverity.severe:
        return Colors.red;
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white30, size: 18),
          ],
        ),
      ),
    );
  }
}
