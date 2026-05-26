import 'package:flutter/material.dart';

/// Visual tokens for Add / Edit Task (Obsidian + lime accent).
abstract final class AddTaskColors {
  static const surface = Color(0xFF0E0E0E);
  static const card = Color(0xFF181818);
  static const cardElevated = Color(0xFF222222);
  static const border = Color(0x14FFFFFF);
  static const borderActive = Color(0x66B7FF00);
  static const accent = Color(0xFFB7FF00);
  static const accentDim = Color(0xFF8BC34A);
  static const cyan = Color(0xFF00E3FD);
  static const onSurface = Color(0xFFFFFFFF);
  static const muted = Color(0xFFADAAAA);
  static const faint = Color(0xFF6B6767);
}

class AddTaskCard extends StatelessWidget {
  const AddTaskCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AddTaskColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AddTaskColors.border),
      ),
      child: child,
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
                style: const TextStyle(
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
                  style: const TextStyle(
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
  });

  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: style ??
          const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AddTaskColors.onSurface,
          ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AddTaskColors.muted.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AddTaskColors.cardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AddTaskColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AddTaskColors.borderActive, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
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
    this.iconColor = AddTaskColors.accent,
  });

  final IconData icon;
  final Color iconColor;
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
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AddTaskColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AddTaskColors.muted,
                    ),
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
        border: Border.all(color: AddTaskColors.border),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                      style: const TextStyle(
                        fontSize: 11,
                        color: AddTaskColors.faint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AddTaskColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AddTaskColors.faint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTaskCategoryTile extends StatelessWidget {
  const AddTaskCategoryTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? AddTaskColors.accent.withValues(alpha: 0.14)
                : AddTaskColors.cardElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AddTaskColors.accent : AddTaskColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AddTaskColors.accent : AddTaskColors.muted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AddTaskColors.accent : AddTaskColors.muted,
                ),
              ),
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
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AddTaskColors.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddTaskColors.border),
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
          color: selected ? AddTaskColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label.replaceAll(' ', '\n'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: 0.3,
            color: selected ? Colors.black : AddTaskColors.muted,
          ),
        ),
      ),
    );
  }
}

class AddTaskExpandableCard extends StatelessWidget {
  const AddTaskExpandableCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.children,
    this.leadingIcon,
  });

  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return AddTaskCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 20, color: AddTaskColors.muted),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AddTaskColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AddTaskColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AddTaskColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AddTaskColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ],
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
            color: isSelected ? AddTaskColors.accent : AddTaskColors.border,
            width: isSelected ? 1.5 : 1,
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
                    : Colors.white.withValues(alpha: 0.05),
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
                      style: const TextStyle(
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
              const Icon(Icons.check_circle_rounded,
                  color: AddTaskColors.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

IconData addTaskCategoryIcon(String label) {
  switch (label) {
    case 'Fitness':
      return Icons.fitness_center_rounded;
    case 'Work':
      return Icons.work_outline_rounded;
    case 'Personal':
      return Icons.favorite_border_rounded;
    case 'Planning':
      return Icons.calendar_month_outlined;
    default:
      return Icons.menu_book_rounded;
  }
}
