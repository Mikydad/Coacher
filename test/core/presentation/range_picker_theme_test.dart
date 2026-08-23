import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/presentation/app_colors.dart';
import 'package:sidepal/core/presentation/range_picker_theme.dart';

/// The stock range picker builds its save action with a WIDGET-level
/// `TextButton.styleFrom(foregroundColor: headerForeground)`, which beats a
/// TextButtonTheme's `foregroundColor` — the label is recolored through a
/// theme-level `foregroundBuilder` instead. These tests pin down the fix at
/// the render level: the visible "Set duration" text must resolve to
/// `onAccent` (black in the dark palette) on the lime pill, while the
/// header keeps its stock colors (the user wants ONLY the button styled).
void main() {
  setUp(() => AppColors.palette = AppPalette.dark);

  Future<void> openPicker(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDateRange: DateTimeRange(
                  start: DateTime(2026, 9, 2),
                  end: DateTime(2026, 9, 10),
                ),
                helpText: 'Goal duration',
                saveText: 'Set duration',
                builder: sidePalRangePickerBuilder,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('save label RENDERS in onAccent despite the forced '
      'widget-level foregroundColor', (tester) async {
    await openPicker(tester);

    // The color the Text actually inherits — innermost DefaultTextStyle.
    final context = tester.element(find.text('Set duration'));
    final rendered = DefaultTextStyle.of(context).style.color;
    expect(rendered, AppColors.onAccent);
    expect(rendered, isNot(AppColors.accent));
  });

  testWidgets('save action is a lime pill, not flat text', (tester) async {
    await openPicker(tester);

    final context = tester.element(
      find.widgetWithText(TextButton, 'Set duration'),
    );
    final style = TextButtonTheme.of(context).style;
    expect(
      style?.backgroundColor?.resolve(const <WidgetState>{}),
      AppColors.accent,
    );
    expect(style?.shape, isNotNull);
  });

  testWidgets('header keeps its stock colors — only the button is themed', (
    tester,
  ) async {
    await openPicker(tester);

    final context = tester.element(find.text('Goal duration'));
    final theme = DatePickerTheme.of(context);
    expect(theme.rangePickerHeaderBackgroundColor, isNull);
    expect(theme.rangePickerHeaderForegroundColor, isNull);
  });
}
