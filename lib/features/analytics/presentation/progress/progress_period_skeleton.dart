import 'package:flutter/material.dart';

import '../../domain/progress_period.dart';
import 'progress_design_tokens.dart';
import 'progress_shared_widgets.dart';

/// Placeholder shaped like the horizon it is about to show, so the layout
/// does not jump when the cached series lands (a few ms later).
class ProgressPeriodSkeleton extends StatelessWidget {
  const ProgressPeriodSkeleton({super.key, required this.horizon});

  final ProgressHorizon horizon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hero(),
        const SizedBox(height: ProgressDesignTokens.sectionSpacing),
        ProgressTonalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Box(width: 90, height: 10),
              SizedBox(height: 12),
              _Box(width: 120, height: 40),
              SizedBox(height: 16),
              _Box(width: 180, height: 26, radius: 999),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ProgressTonalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Box(width: 140, height: 16),
              SizedBox(height: 14),
              _Box(width: double.infinity, height: 6, radius: 999),
              SizedBox(height: 22),
              _Box(width: 120, height: 16),
              SizedBox(height: 14),
              _Box(width: double.infinity, height: 6, radius: 999),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    switch (horizon) {
      case ProgressHorizon.day:
        return const Center(child: _Box(width: 168, height: 168, radius: 84));
      case ProgressHorizon.week:
        return ProgressTonalCard(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                const Expanded(
                  child: Center(child: _Box(width: 42, height: 42, radius: 21)),
                ),
            ],
          ),
        );
      case ProgressHorizon.month:
        return ProgressTonalCard(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
          child: Column(
            children: [
              for (var r = 0; r < 6; r++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      for (var c = 0; c < 7; c++)
                        const Expanded(
                          child: Center(
                            child: _Box(width: 36, height: 36, radius: 18),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      case ProgressHorizon.quarter:
      case ProgressHorizon.year:
        return ProgressTonalCard(
          child: const _Box(width: double.infinity, height: 110),
        );
    }
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.width, required this.height, this.radius = 8});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ProgressDesignTokens.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
