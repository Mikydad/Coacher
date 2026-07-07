import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';

/// PRD Progress page — "Obsidian Pulse" palette.
abstract final class ProgressDesignTokens {
  static Color get surface => AppColors.ink;
  static Color get surfaceContainerLow => AppColors.inkDeep;
  static Color get surfaceContainerHigh => AppColors.inkWarm;
  static Color get surfaceContainerHighest => AppColors.inkElevated;
  static Color get surfaceBright => AppColors.dark2C2C2C;

  static Color get primary => AppColors.limeCream;
  static Color get primaryDim => AppColors.accentDim;
  static Color get primaryContainer => AppColors.accentBright;
  static Color get onPrimaryContainer => AppColors.accentDeep;

  static Color get secondary => AppColors.cyan;
  static Color get onSurface => AppColors.white;
  static Color get onSurfaceVariant => AppColors.textSoft;

  static final ringGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDim, secondary],
  );

  static const sectionSpacing = 24.0;
  static const cardRadius = 16.0;
  static const heroRadius = 16.0;
}
