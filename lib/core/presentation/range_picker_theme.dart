import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared theming for the stock full-screen `showDateRangePicker`, passed as
/// its `builder:` — styles ONLY the save action ("Set duration") into a
/// lime pill with black text; the header keeps its stock look (2026-08-23).
///
/// Why the label needs [ButtonStyle.foregroundBuilder]: the framework builds
/// the save action with a WIDGET-level
/// `TextButton.styleFrom(foregroundColor: headerForeground)`
/// (`date_picker.dart`), and per-property resolution means that
/// `foregroundColor` always beats the theme's. But the widget style leaves
/// `foregroundBuilder` unset, so a theme-level builder still applies — and
/// since the button's forced text style is applied on its outer `Material`
/// while the builder wraps the innermost child
/// (`button_style_button.dart`), an inner `DefaultTextStyle.merge` wins for
/// the label. Net effect: black-on-lime button, untouched header.
Widget sidePalRangePickerBuilder(BuildContext context, Widget? child) {
  return Theme(
    data: Theme.of(context).copyWith(
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          foregroundBuilder: (context, states, child) => DefaultTextStyle.merge(
            style: TextStyle(color: AppColors.onAccent),
            child: child!,
          ),
        ),
      ),
      datePickerTheme: DatePickerTheme.of(context).copyWith(
        // Size/weight only — the stock help text is tiny. Color stays the
        // header's own.
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
