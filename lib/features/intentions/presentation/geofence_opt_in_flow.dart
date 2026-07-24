import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/context/geofence_signal.dart';
import '../../../core/presentation/app_colors.dart';
import '../application/intentions_providers.dart';

/// The shared enable-then-set-home ladder (humanizing Phase 6b), used by
/// the per-intention capture toggle and the Profile switch. Returns true
/// when the geofence is fully live (choice + OS grant + home anchor).
///
/// Home is an EXPLICIT one-time confirmation (settled with Miko: no
/// inference, no silent current-location-as-home) — the dialog tells the
/// user to do it while actually at home, and "Later" keeps the opt-in
/// remembered so arming starts the moment home is set in Profile.
Future<bool> ensureGeofenceReady(BuildContext context, WidgetRef ref) async {
  final arming = ref.read(geofenceArmingServiceProvider);

  if (await arming.getChoice() != GeofenceSignalChoice.enabled) {
    final granted = await arming.enable();
    ref.invalidate(geofenceStateProvider);
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SidePal needs \u201cAlways\u201d location access to notice '
              'when you head out — even with the app closed. Allow Always '
              'in iOS Settings > SidePal > Location, then try again from '
              'Profile.',
            ),
          ),
        );
      }
      return false;
    }
  }

  if (await arming.hasHome()) return true;
  if (!context.mounted) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Set home?'),
      content: const Text(
        'SidePal will use your current location as your home area — do '
        'this while you\u2019re at home. One area, stored only on this '
        'device, used only to notice when you head out.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Later', style: TextStyle(color: AppColors.textSoft)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text("I'm home — set it"),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  final ok = await arming.setHomeToCurrentLocation();
  ref.invalidate(geofenceStateProvider);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Couldn\u2019t read your location just now — you can set home '
          'from Profile later.',
        ),
      ),
    );
  }
  return ok;
}
