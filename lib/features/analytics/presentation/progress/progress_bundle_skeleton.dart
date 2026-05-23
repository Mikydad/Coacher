import 'package:flutter/material.dart';

import 'progress_design_tokens.dart';
import 'progress_shared_widgets.dart';

/// Placeholder layout for Progress when no cached analytics bundle exists yet.
class ProgressBundleSkeleton extends StatelessWidget {
  const ProgressBundleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ShimmerBar(width: 140, height: 20),
        const SizedBox(height: 12),
        const _ShimmerBar(width: 200, height: 12),
        const SizedBox(height: 24),
        Row(
          children: [
            _shimmerBox(88, 88, radius: 44),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ShimmerBar(width: double.infinity, height: 28),
                  SizedBox(height: 10),
                  _ShimmerBar(width: 120, height: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ProgressDesignTokens.sectionSpacing),
        ProgressTonalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ShimmerBar(width: 100, height: 12),
              SizedBox(height: 12),
              _ShimmerBar(width: double.infinity, height: 16),
              SizedBox(height: 8),
              _ShimmerBar(width: double.infinity, height: 16),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ProgressTonalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ShimmerBar(width: 90, height: 12),
              SizedBox(height: 12),
              _ShimmerBar(width: double.infinity, height: 14),
              SizedBox(height: 8),
              _ShimmerBar(width: 200, height: 14),
            ],
          ),
        ),
        const SizedBox(height: ProgressDesignTokens.sectionSpacing),
        ProgressTonalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ShimmerBar(width: 110, height: 12),
              SizedBox(height: 16),
              _ShimmerBar(width: double.infinity, height: 8),
              SizedBox(height: 12),
              _ShimmerBar(width: double.infinity, height: 8),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _shimmerBox(double w, double h, {double radius = 8}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: ProgressDesignTokens.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ProgressDesignTokens.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
