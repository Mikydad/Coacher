import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_navigator.dart';
import '../../../core/presentation/app_colors.dart';
import '../application/app_screenshot.dart';
import '../application/feedback_context_collector.dart';
import '../application/tester_mode_controller.dart';
import 'tester_report_sheet.dart';

/// Hides the bubble for one frame so it doesn't appear in its own screenshot.
final bubbleHiddenForCaptureProvider = StateProvider<bool>((_) => false);

/// Floating bug-report bubble, mounted via `MaterialApp.builder` so it sits
/// on top of EVERY route (tabs, pushed details, dialogs). Renders nothing
/// unless tester mode is on.
class TesterBugBubbleLayer extends ConsumerWidget {
  const TesterBugBubbleLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible =
        ref.watch(testerModeProvider) &&
        !ref.watch(bubbleHiddenForCaptureProvider);
    if (!visible) return const SizedBox.shrink();
    // No Material ancestor above the Navigator — provide one for ink/shadows.
    return const Material(
      type: MaterialType.transparency,
      child: _DraggableBubble(),
    );
  }
}

class _DraggableBubble extends ConsumerStatefulWidget {
  const _DraggableBubble();

  @override
  ConsumerState<_DraggableBubble> createState() => _DraggableBubbleState();
}

class _DraggableBubbleState extends ConsumerState<_DraggableBubble> {
  static const double _size = 48;
  static const double _margin = 8;

  Offset? _position; // null until first layout (defaults bottom-right)
  bool _reporting = false;

  Offset _defaultPosition(Size screen, EdgeInsets padding) => Offset(
    screen.width - _size - _margin,
    screen.height - padding.bottom - _size - 140,
  );

  Offset _clamp(Offset raw, Size screen, EdgeInsets padding) => Offset(
    raw.dx.clamp(_margin, screen.width - _size - _margin),
    raw.dy.clamp(
      padding.top + _margin,
      screen.height - padding.bottom - _size - _margin,
    ),
  );

  Future<void> _startReport() async {
    if (_reporting) return;
    _reporting = true;
    try {
      // Hide the bubble, let that frame render, then grab the screenshot.
      ref.read(bubbleHiddenForCaptureProvider.notifier).state = true;
      await WidgetsBinding.instance.endOfFrame;
      final bytes = await captureAppScreenshot();
      ref.read(bubbleHiddenForCaptureProvider.notifier).state = false;

      final snapshot = await ref
          .read(feedbackContextCollectorProvider)
          .collect();

      // The bubble lives above the Navigator; the sheet needs a context
      // inside it.
      final navContext = appNavigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      await showModalBottomSheet<void>(
        context: navContext,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            TesterReportSheet(screenshot: bytes, contextSnapshot: snapshot),
      );
    } finally {
      _reporting = false;
      if (mounted) {
        ref.read(bubbleHiddenForCaptureProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final position = _position ?? _defaultPosition(screen, padding);

    return Stack(
      children: [
        Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            // Read _position (not the build-scope local) inside the
            // callbacks: move events can arrive faster than rebuilds.
            onPanUpdate: (details) => setState(() {
              final current = _position ?? _defaultPosition(screen, padding);
              _position = _clamp(current + details.delta, screen, padding);
            }),
            onPanEnd: (_) => setState(() {
              // Snap to the nearest horizontal edge, chat-heads style.
              final current = _position ?? _defaultPosition(screen, padding);
              final snapLeft = current.dx + _size / 2 < screen.width / 2;
              _position = Offset(
                snapLeft ? _margin : screen.width - _size - _margin,
                current.dy,
              );
            }),
            onTap: _startReport,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.bug_report_rounded,
                color: AppColors.onAccent,
                size: 26,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
