import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';

/// PRD Progress page — "Obsidian Pulse" palette.
abstract final class ProgressDesignTokens {
  static const surface = AppColors.ink;
  static const surfaceContainerLow = AppColors.inkDeep;
  static const surfaceContainerHigh = AppColors.inkWarm;
  static const surfaceContainerHighest = AppColors.inkElevated;
  static const surfaceBright = AppColors.dark2C2C2C;

  static const primary = AppColors.limeCream;
  static const primaryDim = AppColors.accentDim;
  static const primaryContainer = AppColors.accentBright;
  static const onPrimaryContainer = AppColors.accentDeep;

  static const secondary = AppColors.cyan;
  static const onSurface = AppColors.white;
  static const onSurfaceVariant = AppColors.textSoft;

  static const ringGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDim, secondary],
  );

  static const sectionSpacing = 24.0;
  static const cardRadius = 16.0;
  static const heroRadius = 16.0;
}
