import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/presentation/app_colors.dart';
import 'package:sidepal/core/presentation/range_picker_theme.dart';

/// The stock range picker builds its save action with a WIDGET-level
/// `TextButton.styleFrom(foregroundColor: headerForeground)`, which beats any
/// TextButtonTheme — so the label color can only come from
/// `rangePickerHeaderForegroundColor`. These tests pin that down: the label
/// must resolve to the on-accent token (black in the dark palette), not the
/// lime scheme color that made it unreadable on the lime pill.
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

  testWidgets('save action label resolves to the on-accent token', (
    tester,
  ) async {
    await openPicker(tester);

    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Set duration'),
    );
    final foreground = button.style?.foregroundColor?.resolve(
      const <WidgetState>{},
    );
    expect(foreground, AppColors.onAccent);
    // The lime scheme color is what previously leaked through and made the
    // label vanish into the pill.
    expect(foreground, isNot(AppColors.accent));
  });

  testWidgets('save action is a filled pill, not flat text', (tester) async {
    await openPicker(tester);

    final context = tester.element(
      find.widgetWithText(TextButton, 'Set duration'),
    );
    final style = TextButtonTheme.of(context).style;
    expect(
      style?.backgroundColor?.resolve(const <WidgetState>{}),
      isNotNull,
      reason: 'the save action needs a fill to read as a button',
    );
    expect(style?.shape, isNotNull);
  });

  testWidgets('header band pairs accent background with on-accent content', (
    tester,
  ) async {
    await openPicker(tester);

    final context = tester.element(find.text('Goal duration'));
    final theme = DatePickerTheme.of(context);
    expect(theme.rangePickerHeaderBackgroundColor, AppColors.accent);
    expect(theme.rangePickerHeaderForegroundColor, AppColors.onAccent);
  });
}
