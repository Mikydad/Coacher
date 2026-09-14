import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/presentation/app_card.dart';
import 'package:sidepal/core/presentation/app_colors.dart';
import 'package:sidepal/core/presentation/page_headers.dart';

Widget _host(Brightness brightness, Widget child) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  home: Scaffold(body: Center(child: child)),
);

/// Mirrors the app root: `MaterialApp` re-keyed on brightness, but the
/// Navigator kept alive through a GlobalKey — so the route tree is updated
/// in place and identical `const` children are skipped unless something
/// registers an inherited dependency for them.
final _navKey = GlobalKey<NavigatorState>();
Widget _appRoot(Brightness brightness, Widget child) => MaterialApp(
  key: ValueKey(brightness),
  navigatorKey: _navKey,
  theme: ThemeData(brightness: brightness),
  home: Scaffold(body: Center(child: child)),
);

Color _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  tearDown(() => AppColors.palette = AppPalette.dark);

  testWidgets(
    'const widgets repaint on the dark/light toggle (AppColors.bindTheme)',
    (tester) async {
      // Same const instances across both pumps — exactly what a retained
      // route tree hands Flutter after the MaterialApp re-key. Without the
      // Theme dependency these would be skipped and keep the dark colors.
      const label = AppSectionLabel('PROMISES');
      const title = PageTitle('Profile');
      const column = Column(
        mainAxisSize: MainAxisSize.min,
        children: [label, title],
      );

      AppColors.palette = AppPalette.dark;
      await tester.pumpWidget(_appRoot(Brightness.dark, column));
      expect(_textColor(tester, 'PROMISES'), AppPalette.dark.textSecondary);
      expect(_textColor(tester, 'PROFILE'), AppPalette.dark.fg70);

      AppColors.palette = AppPalette.light;
      await tester.pumpWidget(_appRoot(Brightness.light, column));
      // MaterialApp animates its theme change; dependents settle with it.
      await tester.pumpAndSettle();
      expect(_textColor(tester, 'PROMISES'), AppPalette.light.textSecondary);
      expect(_textColor(tester, 'PROFILE'), AppPalette.light.fg70);
    },
  );

  testWidgets('AppCircleIconButton with no handler has no ripple target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Brightness.light,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCircleIconButton(
              icon: Icons.notifications_none_rounded,
              onPressed: null,
              tooltip: 'Notifications',
            ),
          ],
        ),
      ),
    );
    expect(find.byType(InkWell), findsNothing);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });

  testWidgets('AppDashedEmptyState renders its message centred', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Brightness.light,
        const AppDashedEmptyState(message: 'Nothing promised right now.'),
      ),
    );
    final text = tester.widget<Text>(find.text('Nothing promised right now.'));
    expect(text.textAlign, TextAlign.center);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('AppSoftPill fires its handler', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Brightness.light,
        AppSoftPill(label: 'Do now', onPressed: () => taps++),
      ),
    );
    await tester.tap(find.text('Do now'));
    expect(taps, 1);
  });
}
