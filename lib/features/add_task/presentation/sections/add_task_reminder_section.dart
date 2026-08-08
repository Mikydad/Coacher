import 'package:flutter/material.dart';

import '../../../../core/utils/date_keys.dart';
import '../../../planning/application/task_schedule_display.dart';
import '../../../planning/domain/sleep_task.dart';
import '../add_task_ui.dart';

/// Reminder card: toggle row plus, when on, date/time pickers (Sleep pairs
/// start/end instead) and the plan-day footnote. [sectionKey] stays owned by
/// the screen State — conflict resolution scrolls this card into view via
/// `Scrollable.ensureVisible`, so the section must render inside the main
/// ListView subtree. The pickers merge the picked component into
/// [reminderTime] and emit one full DateTime through [onReminderTimeChanged];
/// the toggle's permission side effect lives in the State's [onReminderToggled].
class AddTaskReminderSection extends StatelessWidget {
  const AddTaskReminderSection({
    super.key,
    required this.sectionKey,
    required this.reminderEnabled,
    required this.reminderTime,
    required this.category,
    required this.effectiveDurationMinutes,
    required this.planDateKey,
    required this.onReminderToggled,
    required this.onReminderTimeChanged,
  });

  final GlobalKey sectionKey;
  final bool reminderEnabled;
  final DateTime reminderTime;
  final String? category;

  /// Sleep-end display: start + this many minutes.
  final int effectiveDurationMinutes;

  /// The form's resolved plan day (`yyyy-MM-dd`); rendered as 'Today' when it
  /// matches the current day.
  final String planDateKey;
  final ValueChanged<bool> onReminderToggled;
  final ValueChanged<DateTime> onReminderTimeChanged;

  @override
  Widget build(BuildContext context) {
    final timeLabel = TimeOfDay.fromDateTime(reminderTime).format(context);
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(reminderTime);
    final planLabel = planDateKey == DateKeys.todayKey()
        ? 'Today'
        : planDateKey;

    return KeyedSubtree(
      key: sectionKey,
      child: Material(
        color: AddTaskColors.card,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          // Slimmer than the sibling cards on purpose (user call, 2026-07-15):
          // the collapsed reminder row reads ~15% shorter.
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AddTaskToggleRow(
                icon: Icons.notifications_active_outlined,
                iconColor: AddTaskColors.cyan,
                title: 'Reminder',
                subtitle: 'Get notified before this task starts',
                value: reminderEnabled,
                onChanged: onReminderToggled,
              ),
              if (reminderEnabled) ...[
                AddTaskInsetPanel(
                  child: Builder(
                    builder: (context) {
                      final sleep = isSleepCategory(category);
                      final datePicker = AddTaskPickerRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: dateLabel,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: reminderTime,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked == null || !context.mounted) return;
                          onReminderTimeChanged(
                            DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              reminderTime.hour,
                              reminderTime.minute,
                            ),
                          );
                        },
                      );
                      final timePicker = AddTaskPickerRow(
                        icon: Icons.schedule_rounded,
                        label: sleep ? 'Sleep start' : 'Time',
                        value: timeLabel,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(reminderTime),
                          );
                          if (picked == null) return;
                          onReminderTimeChanged(
                            DateTime(
                              reminderTime.year,
                              reminderTime.month,
                              reminderTime.day,
                              picked.hour,
                              picked.minute,
                            ),
                          );
                        },
                      );

                      return Column(
                        children: [
                          // Sleep pairs its start/end times; everything else
                          // pairs date + time — one row either way.
                          if (sleep) ...[
                            datePicker,
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: timePicker),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: AddTaskPickerRow(
                                    icon: Icons.bedtime_rounded,
                                    label: 'Sleep end',
                                    value: formatTaskTimeOfDay(
                                      reminderTime.add(
                                        Duration(
                                          minutes: effectiveDurationMinutes,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Row(
                              children: [
                                Expanded(child: datePicker),
                                const SizedBox(width: 8),
                                Expanded(child: timePicker),
                              ],
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_available_outlined,
                                  size: 13,
                                  color: AddTaskColors.faint,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Plan day · $planLabel',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AddTaskColors.faint,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
