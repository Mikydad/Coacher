import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/getting_started_controller.dart';
import 'tour_targets.dart';

/// Spotlight walkthrough for a new user's first task, mounted via
/// `MaterialApp.builder` (same layer as the tester bug bubble) so it can
/// follow the user from Home into the Add Task screen.
///
/// Per step it dims everything EXCEPT the target (the dim is four plain
/// boxes around the hole, so taps on the target pass straight through to
/// the real button), pulses a glow around it, and shows a small animated
/// instruction card. The completeTask step is a non-blocking hint chip —
/// real life may take hours between creating and finishing the task.
class GettingStartedTourLayer extends ConsumerStatefulWidget {
  const GettingStartedTourLayer({super.key});

  @override
  ConsumerState<GettingStartedTourLayer> createState() =>
      _GettingStartedTourLayerState();
}

class _GettingStartedTourLayerState
    extends ConsumerState<GettingStartedTourLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _measureTimer;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    // Started lazily in build — a repeating animation while the tour is
    // hidden would make every pumpAndSettle in tests spin forever.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    // Targets move (scrolling, keyboard, layout) — re-measure while visible.
    _measureTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _measure(),
    );
  }

  @override
  void dispose() {
    _measureTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  GlobalKey? _keyForStep(TourStep step) => switch (step) {
    TourStep.tapAddTask => TourTargets.addTaskTile,
    TourStep.nameTask => TourTargets.addTaskTitleField,
    TourStep.saveTask => TourTargets.addTaskSaveButton,
    TourStep.completeTask => TourTargets.firstTaskCheckbox,
    TourStep.seeProgress => TourTargets.progressCard,
  };

  void _measure() {
    if (!mounted) return;
    final state = ref.read(gettingStartedControllerProvider);
    if (!state.isActive) {
      if (_targetRect != null) setState(() => _targetRect = null);
      return;
    }
    final rect = TourTargets.rectOf(_keyForStep(state.step)!);
    if (rect != _targetRect) setState(() => _targetRect = rect);
  }

  static const _instructions = {
    TourStep.tapAddTask: (
      title: 'Create your first task',
      body: 'Tap here — plan one small thing for today.',
    ),
    TourStep.nameTask: (
      title: 'Give it a name',
      body: 'Something you\'ll actually do, like "Read 10 pages".',
    ),
    TourStep.saveTask: (
      title: 'Now save it',
      body: 'Tap the button to put it on today\'s plan.',
    ),
    TourStep.completeTask: (
      title: '',
      body: 'When you finish your task, tap the circle next to it.',
    ),
    TourStep.seeProgress: (
      title: 'You did it! 🎉',
      body: 'This is your progress — it just moved because of you.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gettingStartedControllerProvider);
    final showsGlow = state.isActive && _targetRect != null;
    if (showsGlow && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!showsGlow && _pulse.isAnimating) {
      _pulse.stop();
    }
    if (!state.isActive) return const SizedBox.shrink();

    // Hint mode: small, non-blocking, no dim.
    if (state.step == TourStep.completeTask) {
      return _HintChip(
        text: _instructions[TourStep.completeTask]!.body,
        targetRect: _targetRect,
        pulse: _pulse,
        onSkip: () =>
            ref.read(gettingStartedControllerProvider.notifier).skip(),
      );
    }

    final rect = _targetRect;
    // Target not on screen (wrong tab, scrolled away, transition frame):
    // render nothing rather than a spotlight pointing at nowhere.
    if (rect == null) return const SizedBox.shrink();

    final screen = MediaQuery.sizeOf(context);
    final hole = rect.inflate(8);
    final instruction = _instructions[state.step]!;
    final cardBelow = hole.bottom + 140 < screen.height;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Four dim panels around the hole — the hole itself has NO widget,
          // so taps reach the real button underneath.
          _dim(0, 0, screen.width, hole.top),
          _dim(0, hole.bottom, screen.width, screen.height - hole.bottom),
          _dim(0, hole.top, hole.left, hole.height),
          _dim(hole.right, hole.top, screen.width - hole.right, hole.height),

          // Pulsing glow ring around the target (doesn't intercept taps).
          Positioned.fromRect(
            rect: hole,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accent,
                      width: 2 + _pulse.value * 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(
                          alpha: 0.25 + _pulse.value * 0.3,
                        ),
                        blurRadius: 14 + _pulse.value * 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Instruction card near the target.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            left: 20,
            right: 20,
            top: cardBelow ? hole.bottom + 16 : null,
            bottom: cardBelow ? null : screen.height - hole.top + 16,
            child: _InstructionCard(
              key: ValueKey(state.step),
              title: instruction.title,
              body: instruction.body,
              arrowUp: cardBelow,
              arrowX: hole.center.dx,
              onSkip: () =>
                  ref.read(gettingStartedControllerProvider.notifier).skip(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dim(double left, double top, double width, double height) {
    if (width <= 0 || height <= 0) return const SizedBox.shrink();
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // absorb — only the target is interactive
        child: const ColoredBox(color: Color(0x99000000)),
      ),
    );
  }
}

class _InstructionCard extends StatefulWidget {
  const _InstructionCard({
    super.key,
    required this.title,
    required this.body,
    required this.arrowUp,
    required this.arrowX,
    required this.onSkip,
  });

  final String title;
  final String body;
  final bool arrowUp;
  final double arrowX;
  final VoidCallback onSkip;

  @override
  State<_InstructionCard> createState() => _InstructionCardState();
}

class _InstructionCardState extends State<_InstructionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.inkWarm,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 24),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.fg,
                ),
              ),
            ),
          Text(
            widget.body,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSoft,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onSkip,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
              ),
              child: Text(
                'Skip tour',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSoft.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final arrow = Align(
      alignment: Alignment.topLeft,
      child: Padding(
        // Arrow tracks the target horizontally (20 = stack side inset).
        padding: EdgeInsets.only(
          left: (widget.arrowX - 20 - 8).clamp(12.0, 320.0),
        ),
        child: CustomPaint(
          size: const Size(16, 8),
          painter: _ArrowPainter(pointsUp: widget.arrowUp),
        ),
      ),
    );

    return FadeTransition(
      opacity: CurvedAnimation(parent: _in, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, widget.arrowUp ? 0.06 : -0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _in, curve: Curves.easeOutCubic)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.arrowUp ? [arrow, card] : [card, arrow],
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.pointsUp});

  final bool pointsUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.inkWarm;
    final path = pointsUp
        ? (Path()
            ..moveTo(size.width / 2, 0)
            ..lineTo(0, size.height)
            ..lineTo(size.width, size.height))
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width, 0)
            ..lineTo(size.width / 2, size.height));
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.pointsUp != pointsUp;
}

/// Non-blocking reminder shown while waiting for the first task to be
/// completed (could be hours). Glows the checkbox when it's on screen.
class _HintChip extends StatelessWidget {
  const _HintChip({
    required this.text,
    required this.targetRect,
    required this.pulse,
    required this.onSkip,
  });

  final String text;
  final Rect? targetRect;
  final Animation<double> pulse;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          if (targetRect != null)
            Positioned.fromRect(
              rect: targetRect!.inflate(6),
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (_, _) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withValues(
                          alpha: 0.5 + pulse.value * 0.5,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomInset + 96,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              decoration: BoxDecoration(
                color: AppColors.inkWarm.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(color: AppColors.accentDim, width: 3),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x40000000), blurRadius: 16),
                ],
              ),
              child: Row(
                children: [
                  const Text('👆', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.fg,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSkip,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.close,
                        size: 15,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
