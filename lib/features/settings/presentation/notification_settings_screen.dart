import 'package:flutter/material.dart';

import '../../context_override/presentation/override_settings_section.dart';
import '../../profile/presentation/coaching_insight_notification_settings_section.dart';
import 'settings_page_scaffold.dart';

/// Notifications & Reminders (Profile reorg 2026-08-23): the coaching-insight
/// push preferences and the reminder/attention timing (sleep window,
/// overrides) on one page. ReminderSettingsScreen still exists for callers
/// that deep-link the reminder half alone.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  static const routeName = '/settings/notifications';

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: 'Notifications & Reminders',
      children: [
        SettingsSectionHeader(label: 'Coach'),
        SizedBox(height: 10),
        SettingsObsidianCard(
          child: CoachingInsightNotificationSettingsSection(),
        ),
        SizedBox(height: 32),
        SettingsSectionHeader(label: 'Attention & Sleep'),
        SizedBox(height: 10),
        SettingsObsidianCard(child: OverrideSettingsSection()),
        SizedBox(height: 40),
      ],
    );
  }
}
