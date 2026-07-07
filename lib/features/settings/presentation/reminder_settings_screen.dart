import 'package:flutter/material.dart';

import '../../context_override/presentation/override_settings_section.dart';
import 'settings_page_scaffold.dart';

/// Reminder and attention timing — sleep window, overrides, adaptive triggers.
class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({super.key});

  static const routeName = '/settings/reminders';

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: 'Reminder Settings',
      children: [
        SettingsSectionHeader(label: 'Attention & Sleep'),
        SizedBox(height: 10),
        SettingsObsidianCard(child: OverrideSettingsSection()),
        SizedBox(height: 40),
      ],
    );
  }
}
