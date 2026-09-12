import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../direction/application/direction_providers.dart';
import '../../domain/progress_period.dart';
import 'progress_design_tokens.dart';

/// The quarter's / year's Direction text as a quiet line above the hero —
/// the number sits under the intention it belongs to. Renders nothing when
/// no Direction was written for that period.
class DirectionLine extends ConsumerWidget {
  const DirectionLine({super.key, required this.period});

  final ProgressPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (period.horizon != ProgressHorizon.quarter &&
        period.horizon != ProgressHorizon.year) {
      return const SizedBox.shrink();
    }
    final entries = ref.watch(directionEntriesStreamProvider).valueOrNull;
    if (entries == null) return const SizedBox.shrink();
    String? text;
    for (final e in entries) {
      if (e.periodKey == period.key && e.text.trim().isNotEmpty) {
        text = e.text.trim();
        break;
      }
    }
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 16,
            color: ProgressDesignTokens.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ProgressDesignTokens.onSurfaceVariant,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
