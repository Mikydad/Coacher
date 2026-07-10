import 'package:flutter/material.dart';

import '../../../core/presentation/app_colors.dart';
import 'help_sheet.dart';

/// Small always-available `?` that opens the [HelpSheet] for a guide or
/// element topic. Attach it next to any title that needs explaining.
///
/// Deliberately stateless and prefs-free: unlike first-time cards, help
/// stays reachable forever — that's the point of a `?`.
class HelpDot extends StatelessWidget {
  const HelpDot(this.guideId, {super.key});

  final String guideId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showHelpSheet(context, guideId),
      tooltip: 'What is this?',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      visualDensity: VisualDensity.compact,
      icon: Icon(
        Icons.help_outline_rounded,
        size: 16,
        color: AppColors.textSoft.withValues(alpha: 0.6),
      ),
    );
  }
}
