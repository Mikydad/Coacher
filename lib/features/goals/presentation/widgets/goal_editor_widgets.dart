import 'package:flutter/material.dart';

import '../../application/goal_intensity_mode.dart';
import '../../domain/models/goal_categories.dart';
import '../../domain/models/goal_enums.dart';

import '../../../../core/presentation/app_colors.dart';

/// Shared palette for the goal editor — matches goals list accent styling.
abstract final class GoalEditorColors {
  static Color get lime => AppColors.accent;
  static Color get cyan => AppColors.categoryTeal;
  static Color get surface => AppColors.surfaceMuted;
  static Color get surfaceRaised => AppColors.dark222528;
  static Color get inputFill => AppColors.dark111111;
  static Color get border => AppColors.dark2A2D32;
  static Color get label => AppColors.graySlate;
  static Color get hint => AppColors.graySlateDeep;
}

/// Matches Add Task field styling — darker inset fill, soft radius, clear hints.
InputDecoration goalEditorInputDecoration({
  String? hintText,
  double radius = 28,
  bool isDense = false,
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: GoalEditorColors.label.withValues(alpha: 0.5),
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      fontSize: isDense ? 14 : 16,
    ),
    filled: true,
    fillColor: GoalEditorColors.inputFill,
    isDense: isDense,
    contentPadding:
        contentPadding ??
        EdgeInsets.symmetric(horizontal: 22, vertical: isDense ? 12 : 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: GoalEditorColors.lime.withValues(alpha: 0.85),
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: Colors.red.shade300),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
    ),
  );
}

class GoalEditorSectionLabel extends StatelessWidget {
  const GoalEditorSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: GoalEditorColors.label,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

class GoalEditorTextField extends StatelessWidget {
  const GoalEditorTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.helperText,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: TextStyle(
            color: AppColors.fg,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          decoration: goalEditorInputDecoration(hintText: hintText),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: TextStyle(color: AppColors.fg38, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class GoalEditorSectorChips extends StatelessWidget {
  const GoalEditorSectorChips({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final id in GoalCategories.all)
          _SectorChip(
            label: GoalCategories.label(id),
            selected: selectedId == id,
            onTap: () => onSelected(id),
          ),
      ],
    );
  }
}

class _SectorChip extends StatelessWidget {
  const _SectorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? GoalEditorColors.lime : GoalEditorColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: selected ? null : Border.all(color: GoalEditorColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: Colors.black),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : AppColors.fg70,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalEditorHorizonToggle extends StatelessWidget {
  const GoalEditorHorizonToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final GoalHorizon selected;
  final ValueChanged<GoalHorizon> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: GoalEditorColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GoalEditorColors.border),
      ),
      child: Row(
        children: [
          for (final h in GoalHorizon.values)
            Expanded(
              child: _HorizonTab(
                label: switch (h) {
                  GoalHorizon.daily => 'Daily',
                  GoalHorizon.weekly => 'Weekly',
                  GoalHorizon.monthly => 'Monthly',
                },
                selected: selected == h,
                onTap: () => onChanged(h),
              ),
            ),
        ],
      ),
    );
  }
}

class _HorizonTab extends StatelessWidget {
  const _HorizonTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? GoalEditorColors.surfaceRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: GoalEditorColors.lime.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ]
              : null,
          border: selected
              ? Border.all(color: GoalEditorColors.lime.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? GoalEditorColors.lime : AppColors.fg54,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class GoalEditorPeriodModeCards extends StatelessWidget {
  const GoalEditorPeriodModeCards({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final GoalPeriodMode selected;
  final ValueChanged<GoalPeriodMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PeriodCard(
            icon: Icons.calendar_today_outlined,
            title: 'CALENDAR',
            subtitle: 'Pick dates / month / week',
            selected: selected == GoalPeriodMode.calendar,
            onTap: () => onChanged(GoalPeriodMode.calendar),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PeriodCard(
            icon: Icons.timelapse_outlined,
            title: 'DAY COUNT',
            subtitle: 'Fixed number of days — e.g. 30-day challenge',
            selected: selected == GoalPeriodMode.durationDays,
            onTap: () => onChanged(GoalPeriodMode.durationDays),
          ),
        ),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        height: 110,
        decoration: BoxDecoration(
          color: GoalEditorColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.fg70 : GoalEditorColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.fg : AppColors.fg38,
              size: 20,
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.fg : AppColors.fg54,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.fg38,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalEditorDateCard extends StatelessWidget {
  const GoalEditorDateCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: GoalEditorColors.inputFill,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.fg38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: GoalEditorColors.lime,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: Colors.black,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalEditorMeasurementDropdown extends StatelessWidget {
  const GoalEditorMeasurementDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MeasurementKind value;
  final ValueChanged<MeasurementKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: GoalEditorColors.inputFill,
        borderRadius: BorderRadius.circular(28),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MeasurementKind>(
          value: value,
          isExpanded: true,
          dropdownColor: GoalEditorColors.surfaceRaised,
          icon: Icon(Icons.unfold_more, color: AppColors.fg38, size: 20),
          style: TextStyle(
            color: AppColors.fg,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          items: [
            for (final k in MeasurementKind.values)
              DropdownMenuItem(value: k, child: Text(k.displayLabel())),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class GoalEditorDisciplineSection extends StatelessWidget {
  const GoalEditorDisciplineSection({
    super.key,
    required this.intensity,
    required this.onChanged,
  });

  final double intensity;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final level = intensity.round().clamp(1, 5);
    final label = GoalIntensityMode.displayLabelForIntensity(
      level,
    ).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.fg,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: GoalEditorColors.lime,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'LVL $level',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '$level / 5 FOCUS',
              style: TextStyle(color: AppColors.fg38, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: GoalEditorColors.lime,
            inactiveTrackColor: GoalEditorColors.cyan.withValues(alpha: 0.6),
            thumbColor: GoalEditorColors.lime,
            overlayColor: GoalEditorColors.lime.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: intensity,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FLEXIBLE',
              style: TextStyle(color: AppColors.fg38, fontSize: 10),
            ),
            Text(
              'EXTREME',
              style: TextStyle(color: AppColors.fg38, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class GoalEditorReminderCard extends StatelessWidget {
  const GoalEditorReminderCard({
    super.key,
    required this.enabled,
    required this.timeLabel,
    required this.onToggle,
    required this.onPickTime,
  });

  final bool enabled;
  final String timeLabel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GoalEditorColors.inputFill,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.fg24),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.fg54,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: enabled ? onPickTime : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily reminder',
                    style: TextStyle(
                      color: AppColors.fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    enabled ? 'Alert scheduled for $timeLabel' : 'Off',
                    style: TextStyle(color: AppColors.fg38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeTrackColor: GoalEditorColors.lime.withValues(alpha: 0.4),
            activeThumbColor: GoalEditorColors.lime,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

class GoalEditorCollapsibleSection extends StatelessWidget {
  const GoalEditorCollapsibleSection({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: GoalEditorColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GoalEditorColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(color: AppColors.fg38, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, color: AppColors.fg54),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeOutCubic,
          sizeCurve: Curves.easeOutCubic,
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class GoalEditorSetupStepsSection extends StatelessWidget {
  const GoalEditorSetupStepsSection({
    super.key,
    required this.stepCount,
    required this.children,
    required this.onAdd,
  });

  final int stepCount;
  final List<Widget> children;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoalEditorSectionLabel(
          'Setup steps',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: GoalEditorColors.cyan.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: GoalEditorColors.cyan.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              stepCount == 0 ? 'OPTIONAL' : '$stepCount ADDED',
              style: TextStyle(
                color: GoalEditorColors.cyan,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Prep tasks to get started — they don\'t drive goal completion.',
            style: TextStyle(color: AppColors.fg38, fontSize: 12, height: 1.4),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.fg24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppColors.fg54, size: 18),
                SizedBox(width: 6),
                Text(
                  'Add setup step',
                  style: TextStyle(
                    color: AppColors.fg54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// @deprecated Use [GoalEditorSetupStepsSection].
typedef GoalEditorActionsSection = GoalEditorSetupStepsSection;

/// Greyed-out template steps shown as a worked example, not real content.
/// Collapses away (fade + size) once the user starts writing their own steps;
/// "Use these steps" copies them into real editable rows for users who want them.
class GoalEditorExampleStepsCard extends StatelessWidget {
  const GoalEditorExampleStepsCard({
    super.key,
    required this.visible,
    required this.steps,
    required this.onUseThese,
  });

  final bool visible;
  final List<String> steps;
  final VoidCallback onUseThese;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstCurve: Curves.easeOutCubic,
      secondCurve: Curves.easeOutCubic,
      sizeCurve: Curves.easeOutCubic,
      duration: const Duration(milliseconds: 260),
      crossFadeState: visible
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(),
      secondChild: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GoalEditorColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: GoalEditorColors.cyan.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: GoalEditorColors.cyan.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'EXAMPLE',
                    style: TextStyle(
                      color: GoalEditorColors.cyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Steps could look like this:',
                    style: TextStyle(color: AppColors.fg38, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (i + 1).toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: GoalEditorColors.lime.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: TextStyle(
                          color: AppColors.fg38,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onUseThese,
                style: TextButton.styleFrom(
                  foregroundColor: GoalEditorColors.cyan,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
                child: const Text(
                  'Use these steps',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalEditorSetupStepRow extends StatelessWidget {
  const GoalEditorSetupStepRow({
    super.key,
    required this.index,
    required this.controller,
    required this.canRemove,
    required this.onRemove,
    this.onChanged,
  });

  final int index;
  final TextEditingController controller;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final number = (index + 1).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        decoration: BoxDecoration(
          color: GoalEditorColors.inputFill,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Text(
              number,
              style: TextStyle(
                color: GoalEditorColors.lime,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(
                  color: AppColors.fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: index == 0
                      ? 'Install Flutter SDK'
                      : 'Add next setup step…',
                  hintStyle: TextStyle(
                    color: GoalEditorColors.label.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            if (canRemove)
              IconButton(
                icon: Icon(Icons.close, color: AppColors.fg38, size: 18),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ),
    );
  }
}

/// @deprecated Use [GoalEditorSetupStepRow].
typedef GoalEditorActionRow = GoalEditorSetupStepRow;

class GoalEditorHeader extends StatelessWidget implements PreferredSizeWidget {
  const GoalEditorHeader({
    super.key,
    required this.isEditing,
    required this.onBack,
    this.onSave,
  });

  final bool isEditing;
  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.fg70),
        onPressed: onBack,
      ),
      centerTitle: true,
      title: Text(
        isEditing ? 'EDIT GOAL' : 'NEW GOAL',
        style: TextStyle(
          color: AppColors.fg,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 1.5,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Save',
          onPressed: onSave,
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: onSave != null
                  ? GoalEditorColors.lime
                  : GoalEditorColors.lime.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.save_outlined,
              size: 18,
              color: onSave != null ? Colors.black : Colors.black38,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class GoalEditorSaveButton extends StatelessWidget {
  const GoalEditorSaveButton({
    super.key,
    required this.saving,
    required this.onPressed,
  });

  final bool saving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: GoalEditorColors.lime,
          foregroundColor: Colors.black,
          disabledBackgroundColor: GoalEditorColors.lime.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black54,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SAVE GOAL',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.bolt, size: 18),
                ],
              ),
      ),
    );
  }
}
