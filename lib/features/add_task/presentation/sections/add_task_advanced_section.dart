import 'package:flutter/material.dart';

import '../add_task_ui.dart';

/// Collapsed power-user toggles (habit anchor, per-task strict, fixed time).
/// Sleep hides this — its schedule is already rigid by default and its extras
/// live in their own card. [sectionKey] stays owned by the screen State: the
/// expand-scroll and conflict flows resolve it against the ambient Scrollable,
/// so this section must render inside the main ListView subtree.
class AddTaskAdvancedSection extends StatelessWidget {
  const AddTaskAdvancedSection({
    super.key,
    required this.sectionKey,
    required this.expanded,
    required this.isHabitAnchor,
    required this.strictModeRequired,
    required this.isRigid,
    required this.onToggleExpanded,
    required this.onHabitAnchorChanged,
    required this.onStrictChanged,
    required this.onRigidChanged,
  });

  final GlobalKey sectionKey;
  final bool expanded;
  final bool isHabitAnchor;
  final bool strictModeRequired;
  final bool isRigid;
  final VoidCallback onToggleExpanded;
  final ValueChanged<bool> onHabitAnchorChanged;
  final ValueChanged<bool> onStrictChanged;
  final ValueChanged<bool> onRigidChanged;

  String get _subtitle {
    final parts = <String>[];
    if (isHabitAnchor) parts.add('Habit anchor');
    if (strictModeRequired) parts.add('Strict');
    if (isRigid) parts.add('Fixed time');
    if (parts.isEmpty) return 'Habit, strict rules, fixed time';
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return AddTaskCollapsibleSection(
      key: sectionKey,
      title: 'Advanced settings',
      subtitle: _subtitle,
      expanded: expanded,
      onToggle: onToggleExpanded,
      children: [
        AddTaskToggleRow(
          icon: Icons.anchor_rounded,
          iconColor: AddTaskColors.accentDim,
          title: 'Habit anchor',
          subtitle: 'Priority scheduling for a stable habit slot',
          value: isHabitAnchor,
          onChanged: onHabitAnchorChanged,
        ),
        const SizedBox(height: 8),
        AddTaskToggleRow(
          icon: Icons.gavel_rounded,
          iconColor: AddTaskColors.cyan,
          title: 'Strict for this task',
          subtitle: 'Extra checks even when the slot is Flexible',
          value: strictModeRequired,
          onChanged: onStrictChanged,
        ),
        const SizedBox(height: 8),
        AddTaskToggleRow(
          icon: Icons.lock_clock_rounded,
          title: 'Fixed time slot',
          subtitle: 'Treat as a hard block for conflict detection',
          value: isRigid,
          onChanged: onRigidChanged,
        ),
      ],
    );
  }
}
