import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/coaching_style_providers.dart';
import '../domain/models/coaching_style.dart';

import '../../../core/presentation/app_colors.dart';

/// Fullscreen coaching style selection — suitable for both onboarding
/// and settings-initiated re-selection.
///
/// [isOnboarding]: when true, shows a "Get started" CTA instead of "Save".
/// [onStyleSelected]: called after the profile is persisted; used by the
///   caller to navigate forward.
class CoachingStyleSelectionScreen extends ConsumerStatefulWidget {
  const CoachingStyleSelectionScreen({
    super.key,
    this.isOnboarding = false,
    this.onStyleSelected,
  });

  final bool isOnboarding;
  final void Function(CoachingStyle style)? onStyleSelected;

  static const routeName = '/coaching-style-selection';

  @override
  ConsumerState<CoachingStyleSelectionScreen> createState() =>
      _CoachingStyleSelectionScreenState();
}

class _CoachingStyleSelectionScreenState
    extends ConsumerState<CoachingStyleSelectionScreen> {
  CoachingStyle? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-select current style (if any) when opened from settings.
    final current = ref.read(activeCoachingStyleProvider);
    _selected = current;
  }

  Future<void> _save() async {
    final style = _selected;
    if (style == null || _saving) return;

    final previous = ref.read(activeCoachingStyleProvider);
    final isUpgrade = _isUpgrade(previous, style);

    // For upgrades (e.g. supportive → intense) show a brief confirmation.
    if (isUpgrade && mounted) {
      final confirmed = await _showUpgradeConfirmation(style);
      if (!confirmed) return;
    }

    setState(() => _saving = true);
    try {
      final service = ref.read(coachingStyleServiceProvider);
      if (widget.isOnboarding) {
        await service.setOnboardingStyle(style);
      } else {
        await service.setStyle(style);
      }
      if (mounted && !widget.isOnboarding) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your coaching style has been updated. '
              'The AI and reminders will adapt from now on.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      widget.onStyleSelected?.call(style);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// True when [next] represents a meaningfully "harder" style than [current].
  bool _isUpgrade(CoachingStyle current, CoachingStyle next) {
    const order = [
      CoachingStyle.supportive,
      CoachingStyle.balanced,
      CoachingStyle.disciplined,
      CoachingStyle.intense,
    ];
    return order.indexOf(next) > order.indexOf(current) &&
        next == CoachingStyle.intense;
  }

  Future<bool> _showUpgradeConfirmation(CoachingStyle style) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark1E1E2E,
        title: const Text('Heads up'),
        content: Text(
          'Switching to ${style.displayName} will make reminders more persistent '
          'and coaching more direct. You can change this anytime in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark0F0F1A,
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Coaching Style'),
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isOnboarding) ...[
              const SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'How should I coach you?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.fg,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'This shapes how I communicate and how persistent I am. '
                  'You can change it anytime.',
                  style: TextStyle(fontSize: 14, color: AppColors.fg54),
                ),
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: CoachingStyle.values.map((style) {
                  return _StyleCard(
                    style: style,
                    isSelected: _selected == style,
                    onTap: () => setState(() => _selected = style),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: _selected != null && !_saving ? _save : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.violetSoft,
                ),
                child: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.fg,
                        ),
                      )
                    : Text(
                        widget.isOnboarding ? 'Get started' : 'Save',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Style card ───────────────────────────────────────────────────────────────

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  final CoachingStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.violetSoft.withAlpha(38)
              : AppColors.fg.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.violetSoft
                : AppColors.fg.withAlpha(20),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2, right: 14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.violetSoft : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.violetSoft : AppColors.fg38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: AppColors.fg)
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    style.description,
                    style: TextStyle(fontSize: 13, color: AppColors.fg54),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fg.withAlpha(8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'e.g. missed workout',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.fg38,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '"${style.exampleMissedWorkout}"',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.fg70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
