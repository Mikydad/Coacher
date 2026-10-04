import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../reminders/domain/models/reminder_occurrence_enums.dart';
import '../add_task_ui.dart';

/// The three taxonomy options, in the order they appear in the segment.
const _order = <ReminderTaxonomy>[
  ReminderTaxonomy.timeSensitive,
  ReminderTaxonomy.flexible,
  ReminderTaxonomy.routine,
];

/// Every label states the OUTCOME, because that is the only thing the
/// taxonomy actually decides (PRD §3.2) — and because the internal names
/// cannot be shown here. `flexible` collides with the *Accountability* mode
/// of the same name that sits on this very screen, where it means something
/// unrelated ("reminders are gentle") — a task can legitimately be
/// Disciplined accountability with a `flexible` class, which reads as a
/// contradiction only because of the shared word. Naming all three by what
/// happens removes the collision and makes the row self-explanatory.
String _labelFor(ReminderTaxonomy t) => switch (t) {
  ReminderTaxonomy.timeSensitive => 'EXPIRES',
  ReminderTaxonomy.flexible => 'COMES BACK',
  ReminderTaxonomy.routine => 'ADDS UP',
};

String _explanationFor(ReminderTaxonomy t) => switch (t) {
  ReminderTaxonomy.timeSensitive =>
    'Stops mattering later. Logged as missed — never nagged about.',
  ReminderTaxonomy.flexible =>
    'Still worth doing. Resurfaces at a good moment.',
  ReminderTaxonomy.routine =>
    'Low-stakes. Misses just add up in one daily line.',
};

/// "If you miss it" — the classification chooser (FR-R-21), living in
/// Advanced settings since 2026-09-18 and shown only while a reminder is on.
///
/// Never a required decision: the heuristic has already answered by the time
/// this renders, and [taxonomy] shows that answer. Tapping a segment makes it
/// the user's answer instead — which is then never overwritten by the
/// heuristic or by AI.
///
/// The Critical toggle is offered for every class. The three segments
/// decide what a MISS means; Critical decides how LOUD the reminder is
/// (criticality 3 pierces the interruption boundary, the Focus Shield and
/// the sleep window). Those are two different questions, and tying Critical
/// to `EXPIRES` alone read as if the other two classes could never matter
/// enough (Miko, 2026-09-18).
class AddTaskClassificationSection extends StatelessWidget {
  const AddTaskClassificationSection({
    super.key,
    required this.taxonomy,
    required this.isCritical,
    required this.onTaxonomyChanged,
    required this.onCriticalChanged,
  });

  final ReminderTaxonomy taxonomy;
  final bool isCritical;
  final ValueChanged<ReminderTaxonomy> onTaxonomyChanged;
  final ValueChanged<bool> onCriticalChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AddTaskSectionLabel(
          title: 'If you miss it',
          subtitle: _explanationFor(taxonomy),
        ),
        const SizedBox(height: 10),
        AddTaskDurationSegment(
          options: _order.map(_labelFor).toList(growable: false),
          selected: _labelFor(taxonomy),
          onSelected: (label) {
            for (final t in _order) {
              if (_labelFor(t) == label) {
                onTaxonomyChanged(t);
                return;
              }
            }
          },
        ),
        const SizedBox(height: 8),
        AddTaskToggleRow(
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          iconColor: AddTaskColors.cyan,
          title: 'Critical',
          subtitle: 'Reaches you through focus sessions and quiet hours.',
          value: isCritical,
          onChanged: onCriticalChanged,
        ),
      ],
    );
  }
}
