import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/context_override_providers.dart';
import '../domain/models/context_override.dart';
import '../domain/models/user_attention_state.dart';
import 'context_override_quick_activate_sheet.dart';

/// Persistent home screen banner shown while any override is active.
///
/// Updates the remaining-time label every 60 seconds.
/// Renders nothing when no override is active.
/// Tapping opens the quick-activate sheet to manage or end the override.
class ActiveOverrideBanner extends ConsumerStatefulWidget {
  const ActiveOverrideBanner({super.key});

  @override
  ConsumerState<ActiveOverrideBanner> createState() =>
      _ActiveOverrideBannerState();
}

class _ActiveOverrideBannerState extends ConsumerState<ActiveOverrideBanner> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh remaining-time label every 60 seconds.
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effective = ref.watch(effectiveOverrideProvider);
    if (effective == ContextOverride.none) return const SizedBox.shrink();

    final stateAsync = ref.watch(attentionStateProvider);
    final state = stateAsync.valueOrNull;

    return GestureDetector(
      onTap: () => showContextOverrideQuickActivateSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _overrideColor(effective).withAlpha(30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _overrideColor(effective).withAlpha(80)),
        ),
        child: Row(
          children: [
            Text(effective.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${effective.displayName} mode active',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _subtitleText(state, effective),
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            // End now button
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _endOverride(context),
              child: const Text('End', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleText(UserAttentionState? state, ContextOverride effective) {
    // Sleep window override — no manual expiry
    if (state != null &&
        effective == ContextOverride.sleep &&
        state.activeOverride == ContextOverride.none) {
      return 'Sleep window active';
    }
    final expires = state?.overrideExpiresAt;
    if (expires == null) return 'Until you end it';
    final remaining = expires.difference(DateTime.now());
    if (remaining.isNegative) return 'Expiring…';
    if (remaining.inMinutes < 1) return 'Less than a minute left';
    if (remaining.inHours < 1) return '${remaining.inMinutes}m remaining';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    return m > 0 ? '${h}h ${m}m remaining' : '${h}h remaining';
  }

  Future<void> _endOverride(BuildContext context) async {
    final review = await ref.read(contextOverrideServiceProvider).endOverride();
    if (review.overrideType != ContextOverride.none) {
      ref.read(pendingRecoveryReviewProvider.notifier).state = review;
    }
  }

  Color _overrideColor(ContextOverride type) {
    switch (type) {
      case ContextOverride.meeting:
        return Colors.blueAccent;
      case ContextOverride.focus:
        return Colors.purpleAccent;
      case ContextOverride.sleep:
        return Colors.indigo;
      case ContextOverride.vacation:
        return Colors.tealAccent;
      case ContextOverride.doNotDisturb:
        return Colors.red;
      case ContextOverride.none:
        return Colors.white;
    }
  }
}
