import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../add_task/presentation/add_task_screen.dart';
import '../application/getting_started_controller.dart';

/// Learn-by-doing checklist for brand-new users, pinned at the top of Home.
/// Renders nothing once onboarding is done/skipped (i.e. for everyone else).
class GettingStartedCard extends ConsumerWidget {
  const GettingStartedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gettingStartedControllerProvider);
    switch (s.phase) {
      case GettingStartedPhase.loading:
      case GettingStartedPhase.hidden:
        return const SizedBox.shrink();
      case GettingStartedPhase.active:
      case GettingStartedPhase.celebrating:
        break;
    }
    final celebrating = s.phase == GettingStartedPhase.celebrating;

    // Home's ListView already pads 16 on all sides — only add the gap below.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inkWarm,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: AppColors.accentDim, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: celebrating
              ? _Celebration(key: const ValueKey('celebrate'))
              : _Checklist(key: const ValueKey('steps'), state: s),
        ),
      ),
    );
  }
}

class _Checklist extends ConsumerWidget {
  const _Checklist({super.key, required this.state});

  final GettingStartedState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'GETTING STARTED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.accentDim,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(gettingStartedControllerProvider.notifier).skip(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: AppColors.textSoft),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Three small moves and you own this app.',
          style: TextStyle(fontSize: 12, color: AppColors.textSoft),
        ),
        const SizedBox(height: 12),
        _StepRow(
          index: 1,
          label: 'Create your first task',
          done: state.step1TaskCreated,
          onTap: state.step1TaskCreated
              ? null
              : () => Navigator.pushNamed(context, AddTaskScreen.routeName),
        ),
        _StepRow(
          index: 2,
          label: 'Complete it — tap the circle next to the task',
          done: state.step2TaskCompleted,
        ),
        _StepRow(
          index: 3,
          label: 'Watch your progress score react above',
          done: state.step3ProgressSeen,
          isLast: true,
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.label,
    required this.done,
    this.onTap,
    this.isLast = false,
  });

  final int index;
  final String label;
  final bool done;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.accent : Colors.transparent,
            border: done
                ? null
                : Border.all(
                    color: AppColors.textSoft.withValues(alpha: 0.5),
                  ),
          ),
          child: done
              ? Icon(Icons.check, size: 14, color: AppColors.onAccent)
              : Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSoft,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: done ? AppColors.textSoft : AppColors.fg,
              decoration: done ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.textSoft,
            ),
          ),
        ),
        if (onTap != null)
          Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.accent),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: onTap == null
          ? row
          : InkWell(borderRadius: BorderRadius.circular(8), onTap: onTap, child: row),
    );
  }
}

class _Celebration extends StatelessWidget {
  const _Celebration({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('🎉', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You're set!",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.fg,
                ),
              ),
              Text(
                'Plan it. Do it. Watch it compound.',
                style: TextStyle(fontSize: 12, color: AppColors.textSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
