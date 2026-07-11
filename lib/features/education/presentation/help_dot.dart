import 'package:flutter/material.dart';

import '../../../core/presentation/app_colors.dart';
import 'help_sheet.dart';

/// Small always-available `?` that opens the [HelpSheet] for a guide or
/// element topic. Attach it next to any title that needs explaining.
///
/// Deliberately stateless and prefs-free: unlike first-time cards, help
/// stays reachable forever — that's the point of a `?`.
class HelpDot extends StatelessWidget {
  const HelpDot(this.guideId, {super.key, this.dense = false});

  final String guideId;

  /// Tighter footprint (22px box, 13px icon) for cramped spots like the
  /// half-width Add Task cards, where the regular 32px dot steals enough
  /// room to ellipsize titles ("Accounta…").
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final box = dense ? 22.0 : 32.0;
    return IconButton(
      onPressed: () => showHelpSheet(context, guideId),
      tooltip: 'What is this?',
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: box, minHeight: box),
      visualDensity: VisualDensity.compact,
      icon: Icon(
        Icons.help_outline_rounded,
        size: dense ? 13 : 16,
        color: AppColors.textSoft.withValues(alpha: 0.6),
      ),
    );
  }
}

/// Page-level `?` for AppBar actions: opens the page's [HelpSheet]
/// (what the page is for, how to use it, why it exists).
class HelpAppBarButton extends StatelessWidget {
  const HelpAppBarButton(this.guideId, {super.key});

  final String guideId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showHelpSheet(context, guideId),
      tooltip: 'About this page',
      icon: const Icon(Icons.help_outline_rounded, size: 20),
    );
  }
}
