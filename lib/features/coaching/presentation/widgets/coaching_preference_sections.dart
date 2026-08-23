import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../education/presentation/first_time_feature_card.dart';
import '../../../education/presentation/help_dot.dart';
import '../../../profile/application/profile_providers.dart';
import '../../../settings/presentation/settings_page_scaffold.dart';
import '../../application/coaching_style_providers.dart';
import '../../domain/models/coaching_style.dart';
import '../../domain/models/enforcement_mode.dart';

/// Discipline Mode and Coach Tone, each collapsed to the currently selected
/// value — tap it (or the chevron) to reveal the other options; picking one
/// collapses again.
///
/// These live directly on the Profile page, above the settings list
/// (2026-08-23): they are the two knobs the user actually reaches for, so
/// they sit out in the open rather than behind a settings door. The widgets
/// carry no outer padding — the host supplies it.

class DisciplineModeSection extends ConsumerStatefulWidget {
  const DisciplineModeSection({super.key});

  @override
  ConsumerState<DisciplineModeSection> createState() =>
      _DisciplineModeSectionState();
}

class _DisciplineModeSectionState extends ConsumerState<DisciplineModeSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final activeMode = ref.watch(defaultEnforcementModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeaderWithHelp(
          label: 'Discipline Mode',
          helpId: 'disciplineModes',
        ),
        const SizedBox(height: 10),
        const FirstTimeFeatureCard(guideId: 'disciplineModes'),
        _DisciplineTile(
          mode: activeMode,
          isActive: true,
          expandChevron: _expanded,
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_expanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      for (final mode in EnforcementMode.values)
                        if (mode != activeMode)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DisciplineTile(
                              mode: mode,
                              isActive: false,
                              onTap: () => _select(mode),
                            ),
                          ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _select(EnforcementMode mode) async {
    setState(() => _expanded = false);
    await ref
        .read(profilePreferenceServiceProvider)
        .setDefaultEnforcementMode(mode);
  }
}

class CoachToneSection extends ConsumerStatefulWidget {
  const CoachToneSection({super.key});

  @override
  ConsumerState<CoachToneSection> createState() => _CoachToneSectionState();
}

class _CoachToneSectionState extends ConsumerState<CoachToneSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final activeStyle = ref.watch(activeCoachingStyleProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeaderWithHelp(label: 'Coach Tone', helpId: 'coachTone'),
        const SizedBox(height: 10),
        _ToneTile(
          style: activeStyle,
          isActive: true,
          expandChevron: _expanded,
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_expanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      for (final style in CoachingStyle.values)
                        if (style != activeStyle)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ToneTile(
                              style: style,
                              isActive: false,
                              onTap: () => _select(style),
                            ),
                          ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _select(CoachingStyle style) async {
    setState(() => _expanded = false);
    await ref.read(coachingStyleServiceProvider).setStyle(style);
  }
}

class _SectionHeaderWithHelp extends StatelessWidget {
  const _SectionHeaderWithHelp({required this.label, required this.helpId});

  final String label;
  final String helpId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(child: SettingsSectionHeader(label: label)),
        HelpDot(helpId),
      ],
    );
  }
}

// ─── Tiles ───────────────────────────────────────────────────────────────────

class _DisciplineTile extends StatelessWidget {
  const _DisciplineTile({
    required this.mode,
    required this.isActive,
    required this.onTap,
    this.expandChevron,
  });

  final EnforcementMode mode;
  final bool isActive;
  final VoidCallback onTap;

  /// Non-null on the collapsed summary tile: renders the expand chevron,
  /// rotated when open.
  final bool? expandChevron;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    switch (mode) {
      case EnforcementMode.flexible:
        icon = Icons.waves_rounded;
        iconColor = AppColors.cyan;
      case EnforcementMode.disciplined:
        icon = Icons.bolt_rounded;
        iconColor = isActive ? AppColors.limeShadow : AppColors.accentDim;
      case EnforcementMode.extreme:
        icon = Icons.shield_rounded;
        iconColor = AppColors.coral;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentBright.withValues(alpha: 0.05)
              : AppColors.inkDeep,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.accentDim.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.accentDim : AppColors.inkElevated,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          mode.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.limeCream
                                : AppColors.white,
                          ),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        const _ActivePill(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    mode.description,
                    style: TextStyle(fontSize: 12, color: AppColors.textSoft),
                  ),
                ],
              ),
            ),
            if (expandChevron != null) ...[
              const SizedBox(width: 8),
              _ExpandChevron(open: expandChevron!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToneTile extends StatelessWidget {
  const _ToneTile({
    required this.style,
    required this.isActive,
    required this.onTap,
    this.expandChevron,
  });

  final CoachingStyle style;
  final bool isActive;
  final VoidCallback onTap;
  final bool? expandChevron;

  static String copyFor(CoachingStyle style) => switch (style) {
    CoachingStyle.supportive => 'Encouraging and light',
    CoachingStyle.balanced => 'Empathetic and steady',
    CoachingStyle.disciplined => 'Direct and focused',
    CoachingStyle.intense => 'Radical honesty only',
  };

  Color _textColor() {
    if (isActive) return AppColors.limeCream;
    return switch (style) {
      CoachingStyle.supportive => AppColors.cyan,
      CoachingStyle.balanced => AppColors.white,
      CoachingStyle.disciplined => AppColors.white,
      CoachingStyle.intense => AppColors.coral,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentBright.withValues(alpha: 0.08)
              : AppColors.inkDeep,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.accentDim.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          style.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textColor(),
                          ),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        const _ActivePill(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    copyFor(style),
                    style: TextStyle(fontSize: 11, color: AppColors.textSoft),
                  ),
                ],
              ),
            ),
            if (expandChevron != null) ...[
              const SizedBox(width: 8),
              _ExpandChevron(open: expandChevron!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.limeCream,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'ACTIVE',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.onAccent,
        ),
      ),
    );
  }
}

class _ExpandChevron extends StatelessWidget {
  const _ExpandChevron({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: open ? 0.5 : 0,
      duration: const Duration(milliseconds: 260),
      child: Icon(
        Icons.expand_more_rounded,
        color: AppColors.textSoft,
        size: 22,
      ),
    );
  }
}
