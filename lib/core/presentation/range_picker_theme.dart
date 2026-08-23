import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared theming for the stock full-screen `showDateRangePicker`, passed as
/// its `builder:` (2026-08-23).
///
/// Why the header is re-colored rather than just the button: Flutter builds
/// the save action with a WIDGET-level style
/// (`date_picker.dart` → `TextButton.styleFrom(foregroundColor:
/// headerForeground)`), and a widget style always beats a theme — so the
/// button's text color can only be changed through
/// [DatePickerThemeData.rangePickerHeaderForegroundColor]. That same color
/// also paints the help text, the date headline, and the close icon, so the
/// header background has to move with it. `accent`/`onAccent` is a
/// guaranteed-contrast pair in both palettes: lime band + black content in
/// dark, deep olive + white in light.
///
/// Everything the widget style leaves unset (background, shape, padding)
/// still falls through to the [TextButtonThemeData] below, which is what
/// turns the save action into a real pill button instead of flat text.
Widget sidePalRangePickerBuilder(BuildContext context, Widget? child) {
  final theme = Theme.of(context);
  return Theme(
    data: theme.copyWith(
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          // `white` is the guaranteed contrast partner of `onAccent` in both
          // palettes (light in dark mode, dark in light mode), so the forced
          // header-foreground label always stays legible on the pill.
          backgroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      datePickerTheme: DatePickerTheme.of(context).copyWith(
        rangePickerHeaderBackgroundColor: AppColors.accent,
        rangePickerHeaderForegroundColor: AppColors.onAccent,
        // Color is overridden by the header foreground above; the size and
        // weight bump survives — the stock help text is tiny.
        rangePickerHeaderHelpStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    ),
    child: child!,
  );
}
