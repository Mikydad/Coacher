import 'package:flutter/material.dart';

/// PRD Progress page — "Obsidian Pulse" palette.
abstract final class ProgressDesignTokens {
  static const surface = Color(0xFF0E0E0E);
  static const surfaceContainerLow = Color(0xFF131313);
  static const surfaceContainerHigh = Color(0xFF201F1F);
  static const surfaceContainerHighest = Color(0xFF262626);
  static const surfaceBright = Color(0xFF2C2C2C);

  static const primary = Color(0xFFEAFFB8);
  static const primaryDim = Color(0xFFB2ED00);
  static const primaryContainer = Color(0xFFBEFC00);
  static const onPrimaryContainer = Color(0xFF445D00);

  static const secondary = Color(0xFF00E3FD);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFFADAAAA);

  static const ringGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDim, secondary],
  );

  static const sectionSpacing = 24.0;
  static const cardRadius = 16.0;
  static const heroRadius = 16.0;
}
