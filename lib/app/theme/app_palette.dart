import 'package:flutter/material.dart';

/// Shared neutral surface ramp ("Obsidian") used across all tabs so raised
/// chrome (app bars, footer nav, cards, chips) reads as distinct layers
/// instead of blending into the page background.
abstract final class AppPalette {
  /// Page background for every tab and pushed screen — dark neutral grey,
  /// one step lighter than pure black.
  static const background = Color(0xFF15171B);

  /// App bars and the footer nav — one visible step lighter than
  /// [background].
  static const appBarSurface = Color(0xFF1E2126);

  /// Default card / panel surface.
  static const card = Color(0xFF1F232A);

  /// Chips, action buttons, and elevated tiles sitting on cards or needing
  /// extra separation from [background].
  static const cardHigh = Color(0xFF262B33);

  /// Hairline border for cards and chips.
  static final border = Colors.white.withValues(alpha: 0.08);

  /// Soft drop shadow shared by cards.
  static final cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
