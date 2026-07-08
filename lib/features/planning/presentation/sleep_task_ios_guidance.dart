import 'dart:io';

import 'package:flutter/material.dart';

/// Apple does not expose a public API for third-party apps to enable system
/// Sleep Focus or Do Not Disturb. This sheet explains that and offers in-app
/// quiet modes that mirror the schedule.
Future<void> showSleepTaskIosFocusGuidance(
  BuildContext context, {
  required VoidCallback onUseInAppSleep,
  required VoidCallback onUseInAppDnd,
}) async {
  if (!Platform.isIOS) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1F232A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'iPhone Focus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'iOS does not let apps turn on Sleep Focus or Do Not Disturb '
              'automatically. You can enable them in Settings → Focus, or use '
              'Shortcuts automations.\n\n'
              'Coach can still align your daily sleep window and run an in-app '
              'quiet mode for this block.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFFADAAAA),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  onUseInAppSleep();
                },
                icon: const Icon(Icons.bedtime_rounded),
                label: const Text('Use in-app Sleep mode'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  onUseInAppDnd();
                },
                icon: const Icon(Icons.notifications_off_rounded),
                label: const Text('Use in-app Do Not Disturb'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
