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
    this.alarm = false,
    this.onAlarmChanged,
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

  /// Alarm mode (feat/alarm-mode): the reminder rings until stopped. Shown
  /// as a small chip beside the plan-day footnote — deliberately not a
  /// full row, because most reminders are fine as notifications and the
  /// option should not compete with the pickers. Sleep hides it: its
  /// wake-up alarm lives in the Sleep extras card, anchored at sleep end.
  final bool alarm;
  final ValueChanged<bool>? onAlarmChanged;

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
                                Expanded(
                                  child: Text(
                                    'Plan day · $planLabel',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AddTaskColors.faint,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (!sleep && onAlarmChanged != null)
                                  AddTaskAlarmChip(
                                    selected: alarm,
                                    onChanged: onAlarmChanged!,
                                  ),
                              ],
                            ),
                          ),
                          if (!sleep && alarm)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                              child: Text(
                                'Rings every 2 minutes for 10 minutes, '
                                'through focus and quiet hours, until you '
                                'stop it.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AddTaskColors.faint,
                                  height: 1.3,
                                ),
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

/// The little alarm toggle that lives beside the plan-day footnote: a pill
/// with a bell that fills with the accent when the reminder is an alarm.
/// Small on purpose (CLAUDE.md: one primary action per screen) — this is a
/// modifier on the reminder, not a section of its own.
class AddTaskAlarmChip extends StatelessWidget {
  const AddTaskAlarmChip({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AddTaskColors.accent : AddTaskColors.faint;
    return Semantics(
      button: true,
      toggled: selected,
      label: 'Alarm',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(!selected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AddTaskColors.accent.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? AddTaskColors.accentDim : AddTaskColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.alarm_on_rounded : Icons.alarm_rounded,
                  size: 13,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  selected ? 'Alarm on' : 'Alarm',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
