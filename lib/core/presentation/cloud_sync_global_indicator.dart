import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/cloud_sync_providers.dart';

import 'app_colors.dart';

/// App-wide cloud sync affordance: thin progress under the status bar.
///
/// Visible on every main tab while [SyncService.syncFromRemote] runs so you can
/// verify sync during testing without section-level spinners.
class CloudSyncGlobalIndicator extends ConsumerWidget {
  const CloudSyncGlobalIndicator({super.key});

  static Color get _accent => AppColors.accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncing = ref.watch(cloudSyncInProgressProvider);
    if (!syncing) return const SizedBox.shrink();

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
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: _accent,
            ),
          ],
        ),
      ),
    );
  }
}
