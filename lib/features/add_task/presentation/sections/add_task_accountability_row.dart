import 'package:flutter/material.dart';

import '../add_task_ui.dart';

/// Full-width accountability row (used by the Sleep layout, which has no
/// Deep Work twin). [subtitle] carries the mode + inherit-source label the
/// screen State derives.
class AddTaskAccountabilityRow extends StatelessWidget {
  const AddTaskAccountabilityRow({
    super.key,
    required this.subtitle,
    required this.onChangeTap,
  });

  final String subtitle;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    return AddTaskSettingsActionRow(
      icon: Icons.verified_user_outlined,
      title: 'Accountability',
      subtitle: subtitle,
      actionLabel: 'CHANGE',
      onTap: onChangeTap,
    );
  }
}
