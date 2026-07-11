import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/cloud_sync_providers.dart';

import 'app_colors.dart';

/// App-wide cloud sync affordance.
///
/// Routine background synchronisation is silent: this shows NOTHING while a
/// remote pull or queue flush is in flight during normal operation. It appears
/// only when the write queue is stuck with changes that failed to reach the
/// cloud ([SyncService.hasSyncIssue]) — a state the user should know about —
/// rendered as a thin, static (non-animated) warning line under the status bar
/// so it reads as "attention needed", not "currently syncing".
class CloudSyncGlobalIndicator extends ConsumerWidget {
  const CloudSyncGlobalIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasIssue = ref.watch(cloudSyncHasIssueProvider);
    if (!hasIssue) return const SizedBox.shrink();

    final top = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: top),
            Container(height: 2, color: AppColors.amber),
          ],
        ),
      ),
    );
  }
}
