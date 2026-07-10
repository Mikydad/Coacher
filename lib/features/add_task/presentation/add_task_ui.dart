import 'package:flutter/material.dart';

import '../../../core/presentation/app_colors.dart';

/// Visual tokens for Add / Edit Task (Obsidian Pulse).
abstract final class AddTaskColors {
  static Color get surface => AppColors.ink;
  static Color get card => AppColors.dark1A1919;
  static Color get cardElevated => AppColors.inkWarm;
  static Color get inputFill => AppColors.dark111111;
  static Color get cardHighest => AppColors.inkElevated;
  static Color get border => AppColors.whiteBorder8;
  static Color get borderActive => AppColors.accentDim;
  static Color get accent => AppColors.accent;
  static Color get accentContainer => AppColors.accentBright;
  static Color get accentDim => AppColors.accentDim;
  static Color get cyan => AppColors.cyan;
  static Color get onSurface => AppColors.white;
  static Color get muted => AppColors.textSoft;
  static Color get faint => AppColors.grayWarm;
}

class AddTaskHeroSectionLabel extends StatelessWidget {
  const AddTaskHeroSectionLabel({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AddTaskColors.onSurface,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AddTaskColors.muted,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class AddTaskSectionLabel extends StatelessWidget {
  const AddTaskSectionLabel({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AddTaskColors.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AddTaskColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AddTaskField extends StatelessWidget {
  const AddTaskField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.style,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextStyle? style;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final radius = maxLines == 1 ? 28.0 : 22.0;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      autofocus: autofocus,
      style:
          style ??
          TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AddTaskColors.onSurface,
          ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AddTaskColors.muted.withValues(alpha: 0.55),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AddTaskColors.inputFill,
        // Resting border so the field reads as editable, not as a label.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: AddTaskColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: AddTaskColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: AddTaskColors.accentDim.withValues(alpha: 0.85),
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: maxLines == 1 ? 20 : 16,
        ),
      ),
    );
  }
}

class AddTaskSettingsActionRow extends StatelessWidget {
  const AddTaskSettingsActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AddTaskColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AddTaskColors.cardHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor ?? AddTaskColors.cyan,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AddTaskColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AddTaskColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AddTaskColors.accentDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTaskSettingsToggleRow extends StatelessWidget {
  const AddTaskSettingsToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AddTaskColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AddTaskColors.cardHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor ?? AddTaskColors.cyan,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AddTaskColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AddTaskColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AddTaskColors.accentDim.withValues(
                  alpha: 0.55,
                ),
                activeThumbColor: AddTaskColors.accentContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTaskCollapsibleSection extends StatelessWidget {
  const AddTaskCollapsibleSection({
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
              color: AddTaskColors.card,
              borderRadius: BorderRadius.circular(16),
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
                          color: AddTaskColors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: AddTaskColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AddTaskColors.muted,
                  ),
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

class AddTaskToggleRow extends StatelessWidget {
  const AddTaskToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? AddTaskColors.accent).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? AddTaskColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AddTaskColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AddTaskColors.muted),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AddTaskColors.accent.withValues(alpha: 0.45),
              activeThumbColor: AddTaskColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class AddTaskInsetPanel extends StatelessWidget {
  const AddTaskInsetPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AddTaskColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class AddTaskPickerRow extends StatelessWidget {
  const AddTaskPickerRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AddTaskColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: AddTaskColors.faint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AddTaskColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (interactive)
                Icon(Icons.chevron_right, color: AddTaskColors.faint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}


class AddTaskDurationSegment extends StatelessWidget {
  const AddTaskDurationSegment({
    super.key,
    required this.options,
    this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _DurationCell(
                label: options[i],
                selected: selected == options[i],
                onTap: () => onSelected(options[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DurationCell extends StatelessWidget {
  const _DurationCell({
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AddTaskColors.accentContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AddTaskColors.accentDim.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: selected ? AppColors.accentDeep : AddTaskColors.muted,
          ),
        ),
      ),
    );
  }
}

class AddTaskEnforcementTile extends StatelessWidget {
  const AddTaskEnforcementTile({
    super.key,
    required this.modeId,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  final String modeId;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  static IconData iconFor(String id) {
    switch (id) {
      case 'disciplined':
        return Icons.track_changes_rounded;
      case 'extreme':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.spa_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AddTaskColors.accent.withValues(alpha: 0.12)
              : AddTaskColors.cardElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AddTaskColors.accent : Colors.transparent,
            width: isSelected ? 1.5 : 0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AddTaskColors.accent.withValues(alpha: 0.2)
                    : AppColors.fg.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconFor(modeId),
                size: 18,
                color: isSelected ? AddTaskColors.accent : AddTaskColors.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AddTaskColors.accent
                          : AddTaskColors.onSurface,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AddTaskColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AddTaskColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

IconData addTaskCategoryIcon(String label) {
  switch (label) {
    case 'Study':
      return Icons.menu_book_rounded;
    case 'Fitness':
      return Icons.fitness_center_rounded;
    case 'Work':
      return Icons.work_outline_rounded;
    case 'Personal':
      return Icons.favorite_border_rounded;
    case 'Planning':
      return Icons.calendar_month_outlined;
    case 'Sleep':
      return Icons.bedtime_rounded;
    default:
      // User-created categories.
      return Icons.label_outline_rounded;
  }
}
