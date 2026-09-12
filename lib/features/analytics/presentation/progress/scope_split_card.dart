import 'package:flutter/material.dart';

import '../../../education/presentation/help_dot.dart';
import '../../application/blended_discipline.dart';
import 'progress_design_tokens.dart';
import 'progress_shared_widgets.dart';

/// The two scopes that make up the blended number, with their weights.
class ScopeSplitCard extends StatelessWidget {
  const ScopeSplitCard({
    super.key,
    required this.goalRate,
    required this.taskRate,
    required this.scopeLabel,
  });

  final double? goalRate;
  final double? taskRate;

  /// Which period these percentages cover (`ProgressPeriod.scopeLabel`).
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    final goalW = (kBlendGoalWeight * 100).round();
    final taskW = (kBlendTaskWeight * 100).round();
    return ProgressTonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW IT SPLITS · $scopeLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ProgressDesignTokens.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Goals & Habits',
                style: TextStyle(
                  color: ProgressDesignTokens.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const HelpDot('goalsHabitsBreakdown'),
            ],
          ),
          const SizedBox(height: 10),
          ProgressThinBar(
            label: 'Goals & Habits · $goalW% weight',
            ratio: goalRate ?? 0,
            color: ProgressDesignTokens.primaryDim,
            detail: goalRate == null ? 'Nothing planned' : null,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Task Integrity',
                style: TextStyle(
                  color: ProgressDesignTokens.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const HelpDot('taskIntegrity'),
            ],
          ),
          const SizedBox(height: 10),
          ProgressThinBar(
            label: 'Tasks · $taskW% weight',
            ratio: taskRate ?? 0,
            color: ProgressDesignTokens.secondary,
            detail: taskRate == null ? 'Nothing planned' : null,
          ),
        ],
      ),
    );
  }
}
