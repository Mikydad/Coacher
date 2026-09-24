import 'package:flutter/material.dart';

import '../../../reminders/domain/models/reminder_occurrence_enums.dart';
import '../add_task_ui.dart';
import 'add_task_classification_section.dart';

/// Collapsed power-user toggle (habit anchor) and, while a reminder is on,
/// the "If you miss it" chooser with its Critical switch (moved here from
/// under the reminder card, 2026-09-18 — it shapes the reminder ladder, so
/// it is an advanced reminder setting, not something every task needs to
/// see). Sleep hides this whole section — its schedule is already rigid by
/// default and its extras live in their own card. [sectionKey] stays owned
/// by the screen State: the expand-scroll and conflict flows resolve it
/// against the ambient Scrollable, so this section must render inside the
/// main ListView subtree.
///
/// "Strict for this task" and "Fixed time slot" left this card on
/// 2026-09-24 (Miko: fewer user actions). Strict duplicated the
/// per-task Extreme mode one card up; Fixed time only nudged conflict
/// severity and was lost on every edit. The task fields stay and are still
/// honoured for tasks that already carry them.
class AddTaskAdvancedSection extends StatelessWidget {
  const AddTaskAdvancedSection({
    super.key,
    required this.sectionKey,
    required this.expanded,
    required this.isHabitAnchor,
    required this.onToggleExpanded,
    required this.onHabitAnchorChanged,
    this.reminderEnabled = false,
    this.taxonomy = ReminderTaxonomy.flexible,
    this.isCritical = false,
    this.onTaxonomyChanged,
    this.onCriticalChanged,
  });

  final GlobalKey sectionKey;
  final bool expanded;
  final bool isHabitAnchor;
  final VoidCallback onToggleExpanded;
  final ValueChanged<bool> onHabitAnchorChanged;

  /// The chooser renders only while this is true — classification only
  /// matters when a reminder exists (FR-R-23).
  final bool reminderEnabled;
  final ReminderTaxonomy taxonomy;
  final bool isCritical;
  final ValueChanged<ReminderTaxonomy>? onTaxonomyChanged;
  final ValueChanged<bool>? onCriticalChanged;

  bool get _showsClassification =>
      reminderEnabled && onTaxonomyChanged != null && onCriticalChanged != null;

  String get _subtitle {
    final parts = <String>[];
    if (isHabitAnchor) parts.add('Habit anchor');
    if (_showsClassification && isCritical) parts.add('Critical');
    if (parts.isEmpty) {
      return _showsClassification
          ? 'Habit anchor, if you miss it'
          : 'Habit anchor off';
    }
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
        if (_showsClassification) ...[
          AddTaskClassificationSection(
            taxonomy: taxonomy,
            isCritical: isCritical,
            onTaxonomyChanged: onTaxonomyChanged!,
            onCriticalChanged: onCriticalChanged!,
          ),
          const SizedBox(height: 16),
        ],
        AddTaskToggleRow(
          icon: Icons.anchor_rounded,
          iconColor: AddTaskColors.accentDim,
          title: 'Habit anchor',
          subtitle: 'Priority scheduling for a stable habit slot',
          value: isHabitAnchor,
          onChanged: onHabitAnchorChanged,
        ),
      ],
    );
  }
}
