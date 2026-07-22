import 'package:flutter/material.dart';

import '../presentation/app_colors.dart';
import '../presentation/page_headers.dart';

/// Bottom sheet shown when a free-tier limit blocks a creation. Explains
/// the limit and names the Pro upgrade path.
///
/// TODO(paywall): route the CTA to the real paywall screen once the
/// RevenueCat integration ships — until then (and while `tier_limits_v1`
/// enforcement is off) this sheet is unreachable in production.
Future<void> showTierLimitSheet(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfacePanel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
