import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../context_override/presentation/override_settings_section.dart';
import '../../feedback/application/tester_mode_controller.dart';
import '../../profile/presentation/coaching_insight_notification_settings_section.dart';
import '../../reminders/presentation/reminder_debug_screen.dart';
import '../../reminders/presentation/reminder_health_section.dart';
import 'settings_page_scaffold.dart';

/// Notifications & Reminders (Profile reorg 2026-08-23): the coaching-insight
/// push preferences and the reminder/attention timing (sleep window,
/// overrides) on one page. ReminderSettingsScreen still exists for callers
/// that deep-link the reminder half alone.
///
/// Reminder health (FR-R-80) leads: when reminders are not working, that is
/// the first thing this page owes the user.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const routeName = '/settings/notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTester = ref.watch(testerModeProvider);

    return SettingsPageScaffold(
      title: 'Notifications & Reminders',
      children: [
        const SettingsSectionHeader(label: 'Reminder health'),
        const SizedBox(height: 10),
        const SettingsObsidianCard(child: ReminderHealthSection()),
        if (isTester) ...[
          const SizedBox(height: 10),
          SettingsObsidianCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Armed reminders'),
              subtitle: const Text('What the OS is actually holding'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(
                context,
                ReminderDebugScreen.routeName,
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        const SettingsSectionHeader(label: 'Coach'),
        const SizedBox(height: 10),
        const SettingsObsidianCard(
          child: CoachingInsightNotificationSettingsSection(),
        ),
        const SizedBox(height: 32),
        const SettingsSectionHeader(label: 'Attention & Sleep'),
        const SizedBox(height: 10),
        const SettingsObsidianCard(child: OverrideSettingsSection()),
        const SizedBox(height: 40),
      ],
    );
  }
}
