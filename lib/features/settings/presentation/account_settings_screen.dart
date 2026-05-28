import 'package:flutter/material.dart';

import 'settings_page_scaffold.dart';

/// Account-only settings — password, privacy, and data controls land here later.
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  static const routeName = '/settings/account';

  @override
  Widget build(BuildContext context) {
    return const SettingsPageScaffold(
      title: 'Account Settings',
      children: [
        SettingsSectionHeader(label: 'Security'),
        SizedBox(height: 10),
        SettingsObsidianCard(
          child: Column(
            children: [
              SettingsPlaceholderRow(
                title: 'Change password',
                subtitle: 'Update how you sign in to Quittr',
              ),
              SettingsPlaceholderRow(
                title: 'Two-factor authentication',
                subtitle: 'Add an extra layer of protection',
                isLast: true,
              ),
            ],
          ),
        ),
        SizedBox(height: 32),
        SettingsSectionHeader(label: 'Privacy & Data'),
        SizedBox(height: 10),
        SettingsObsidianCard(
          child: Column(
            children: [
              SettingsPlaceholderRow(
                title: 'Privacy preferences',
                subtitle: 'Control what is stored and shared',
              ),
              SettingsPlaceholderRow(
                title: 'Export my data',
                subtitle: 'Download a copy of your coaching data',
              ),
              SettingsPlaceholderRow(
                title: 'Delete account',
                subtitle: 'Permanently remove your account and data',
                isLast: true,
              ),
            ],
          ),
        ),
        SizedBox(height: 40),
      ],
    );
  }
}
