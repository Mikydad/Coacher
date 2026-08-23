import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/context/activity_signal.dart';
import '../../../core/context/calendar_signal.dart';
import '../../../core/context/context_providers.dart';
import '../../../core/context/geofence_signal.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/runtime/recompute_scope.dart';
import '../../../core/runtime/unified_recompute_graph.dart';
import '../../intentions/application/intentions_providers.dart';
import '../../intentions/presentation/geofence_opt_in_flow.dart';
import 'setting_row.dart';
import 'settings_page_scaffold.dart';

/// Smart Timing page (Profile reorg 2026-08-23): the three ambient-context
/// switches that used to sit in the Profile "Core Optimization" list.
class SmartTimingSettingsScreen extends StatelessWidget {
  const SmartTimingSettingsScreen({super.key});

  static const routeName = '/settings/smart-timing';

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Smart Timing',
      children: [
        const SettingsSectionHeader(label: 'Ambient context'),
        const SizedBox(height: 4),
        Text(
          'Optional signals that help SidePal pick better moments. '
          'Everything is checked in the moment and stays on this device.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSoft.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          child: Column(
            children: [
              CalendarSignalRow(),
              ActivitySignalRow(),
              GeofenceSignalRow(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Calendar-aware timing toggle (humanizing Phase 4b): the persistent
/// switch behind the one-time ask card. On → OS grant is requested if
/// needed; the signal stays ephemeral (busy intervals only, never stored).
/// Off → remembered decline, the ask card never returns.
class CalendarSignalRow extends ConsumerWidget {
  const CalendarSignalRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(calendarSignalChoiceProvider).valueOrNull;
    final enabled = choice == CalendarSignalChoice.enabled;
    return SettingRow(
      icon: Icons.calendar_month_rounded,
      title: 'Calendar-aware timing',
      subtitle: 'Plan promises around your real meetings — read-only',
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: (v) => _toggle(context, ref, v),
      ),
      onTap: () => _toggle(context, ref, !enabled),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final service = ref.read(calendarSignalServiceProvider);
    if (on) {
      final granted = await service.enable();
      if (granted) {
        UnifiedRecomputeGraph.instance.schedule(
          RecomputeScope.forReminderChange(),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Calendar access is off at the system level — allow it in '
              'iOS Settings > SidePal, then try again.',
            ),
          ),
        );
      }
    } else {
      await service.decline();
    }
    ref.invalidate(calendarSignalChoiceProvider);
  }
}

/// Motion-aware timing toggle (humanizing Phase 6a): the persistent
/// switch behind the one-time ask card. On → OS grant is requested if
/// needed (the first Core Motion query IS the prompt); readings stay
/// decision-time snapshots, never stored. Off → remembered decline.
class ActivitySignalRow extends ConsumerWidget {
  const ActivitySignalRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(activitySignalChoiceProvider).valueOrNull;
    final enabled = choice == ActivitySignalChoice.enabled;
    return SettingRow(
      icon: Icons.directions_walk_rounded,
      title: 'Motion-aware timing',
      subtitle: "Suggest calls when you're walking — checked in the moment",
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: (v) => _toggle(context, ref, v),
      ),
      onTap: () => _toggle(context, ref, !enabled),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final service = ref.read(activitySignalServiceProvider);
    if (on) {
      final granted = await service.enable();
      if (!granted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Motion access is off at the system level — allow it in '
              'iOS Settings > SidePal > Motion & Fitness, then try again.',
            ),
          ),
        );
      }
    } else {
      await service.decline();
    }
    ref.invalidate(activitySignalChoiceProvider);
  }
}

/// Head-out nudges toggle (humanizing Phase 6b): the persistent switch
/// behind the per-intention capture ask. On → runs the enable + explicit
/// set-home ladder (one home area, device-local, exit-only). Off →
/// remembered decline; the native region and armed list are cleared —
/// off means off. Tapping the row when enabled re-opens home setup, so
/// a "Later" at capture time or a move can be fixed here.
class GeofenceSignalRow extends ConsumerWidget {
  const GeofenceSignalRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(geofenceStateProvider).valueOrNull;
    final enabled = state?.choice == GeofenceSignalChoice.enabled;
    final subtitle = enabled && state?.hasHome != true
        ? 'Home not set yet — tap to set it while you’re there'
        : 'Nudge chosen promises when you leave home — one area, '
              'on-device only';
    return SettingRow(
      icon: Icons.near_me_outlined,
      title: 'Head-out nudges',
      subtitle: subtitle,
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: (v) => _toggle(context, ref, v),
      ),
      onTap: () => _toggle(context, ref, !enabled || state?.hasHome != true),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    if (on) {
      await ensureGeofenceReady(context, ref);
    } else {
      await ref.read(geofenceArmingServiceProvider).decline();
    }
    ref.invalidate(geofenceStateProvider);
  }
}
