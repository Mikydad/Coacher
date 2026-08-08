import 'package:flutter/material.dart';

import '../add_task_ui.dart';

/// Accountability and Deep Work share one row of half-width cards.
/// IntrinsicHeight bounds the stretch: inside the ListView height is
/// unbounded, and stretching into it crashes layout. (Layout mirrored by
/// test/features/add_task/add_task_split_row_test.dart.)
class AddTaskAccountabilityDeepWorkRow extends StatelessWidget {
  const AddTaskAccountabilityDeepWorkRow({
    super.key,
    required this.accountabilityLabel,
    required this.focusSession,
    required this.onAccountabilityTap,
    required this.onFocusSessionChanged,
  });

  /// Short uppercase mode label — the picker sheet explains the rest.
  final String accountabilityLabel;
  final bool focusSession;
  final VoidCallback onAccountabilityTap;
  final ValueChanged<bool> onFocusSessionChanged;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AddTaskSplitSettingCard(
              icon: Icons.verified_user_outlined,
              title: 'Accountability',
              // No HelpDot here: 'Accountability' barely fits the half-width
              // card, and a dot on one card but not its twin looks lopsided.
              subtitle: accountabilityLabel,
              onTap: onAccountabilityTap,
              trailing: Text(
                'CHANGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AddTaskColors.accentDim,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AddTaskSplitSettingCard(
              icon: Icons.bolt_rounded,
              title: 'Deep Work',
              subtitle: 'BLOCKS ALERTS',
              onTap: () => onFocusSessionChanged(!focusSession),
              trailing: Switch.adaptive(
                value: focusSession,
                onChanged: onFocusSessionChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeTrackColor: AddTaskColors.accentDim.withValues(
                  alpha: 0.55,
                ),
                activeThumbColor: AddTaskColors.accentContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
