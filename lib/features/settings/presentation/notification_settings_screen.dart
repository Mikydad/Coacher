import 'package:flutter/material.dart';

import '../../profile/presentation/coaching_insight_notification_settings_section.dart';
import 'settings_page_scaffold.dart';

/// Push and in-app notification preferences (not coaching tone / discipline modes).
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  static const routeName = '/settings/notifications';

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: 'Notifications',
      children: [
        SettingsSectionHeader(label: 'Coach'),
        SizedBox(height: 10),
        SettingsObsidianCard(
          child: CoachingInsightNotificationSettingsSection(),
        ),
        SizedBox(height: 40),
      ],
    );
  }
}
