import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/app/application/main_tab_navigation.dart';
import 'package:sidepal/features/education/domain/feature_guides.dart';
import 'package:sidepal/features/education/domain/page_explainers.dart';
import 'package:sidepal/features/education/presentation/first_visit_explainer.dart';
import 'package:sidepal/features/education/presentation/help_dot.dart';
import 'package:sidepal/features/education/presentation/page_explainer_sheet.dart';

const _delay = Duration(milliseconds: 450);

Widget _page(PageExplainer e, {int? tabIndex}) => ProviderScope(
  child: MaterialApp(
    home: FirstVisitExplainer(
      explainer: e,
      tabIndex: tabIndex,
      child: const Scaffold(body: Text('PAGE')),
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('registry', () {
    test('ids unique, three steps each, short copy', () {
      final ids = PageExplainers.all.map((e) => e.id).toSet();
      expect(ids.length, PageExplainers.all.length);
      for (final e in PageExplainers.all) {
        expect(e.steps, hasLength(3), reason: e.id);
        // "Small but simple": keep every line glanceable.
        expect(e.title.length, lessThanOrEqualTo(32), reason: e.id);
        expect(e.body.length, lessThanOrEqualTo(80), reason: e.id);
        expect(e.example.length, lessThanOrEqualTo(110), reason: e.id);
        expect(e.why.length, lessThanOrEqualTo(80), reason: e.id);
        for (final s in e.steps) {
          expect(s.label.length, lessThanOrEqualTo(28), reason: e.id);
        }
      }
    });

    test('every guideId resolves, and forGuide finds its explainer', () {
      for (final e in PageExplainers.all.where((e) => e.guideId != null)) {
        expect(FeatureGuides.byId(e.guideId!), isNotNull, reason: e.id);
        expect(PageExplainers.forGuide(e.guideId!), same(e));
      }
      expect(PageExplainers.forGuide('flowNow'), isNull);
    });
  });

  group('sheet', () {
    for (final e in PageExplainers.all) {
      testWidgets('${e.id} renders scene, copy and steps', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PageExplainerSheet(explainer: e)),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text(e.title), findsOneWidget);
        expect(find.text(e.example), findsOneWidget);
        for (final s in e.steps) {
          expect(find.text(s.label), findsOneWidget);
        }
        expect(find.text('Maybe later'), findsOneWidget);
        // No video URL configured → no video row.
        expect(find.text('See how it works'), findsNothing);
      });
    }

    testWidgets('video row appears when a URL is configured', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageExplainerSheet(
              explainer: PageExplainers.accountability,
              videoUrl: Uri.parse('https://youtu.be/example'),
            ),
          ),
        ),
      );
      expect(find.text('See how it works'), findsOneWidget);
    });

    testWidgets('help ? on a guided topic opens the explainer, then More '
        'details opens the long guide', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Center(child: HelpDot('direction'))),
          ),
        ),
      );
      await tester.tap(find.byType(HelpDot));
      await tester.pumpAndSettle();
      expect(find.text(PageExplainers.direction.title), findsOneWidget);

      await tester.ensureVisible(find.text('More details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('More details'));
      await tester.pumpAndSettle();
      expect(find.text(PageExplainers.direction.title), findsNothing);
      expect(find.text('WHY IT MATTERS'), findsOneWidget);
    });
  });

  group('first visit', () {
    testWidgets('opens once after the delay and marks it seen', (tester) async {
      await tester.pumpWidget(_page(PageExplainers.direction));
      await tester.pump(); // prefs load
      await tester.pump(_delay);
      await tester.pumpAndSettle();
      expect(find.text(PageExplainers.direction.title), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList('education_seen_cards_v1'),
        contains('explainer:direction'),
      );

      await tester.ensureVisible(find.text('Maybe later'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();
      expect(find.text(PageExplainers.direction.title), findsNothing);
    });

    testWidgets('never opens once seen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'education_seen_cards_v1': ['explainer:direction'],
      });
      await tester.pumpWidget(_page(PageExplainers.direction));
      await tester.pump();
      await tester.pump(_delay);
      await tester.pumpAndSettle();
      expect(find.text(PageExplainers.direction.title), findsNothing);
    });

    testWidgets('each tab opens its own explainer on its first visit', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (_, ref, _) => IndexedStack(
                index: ref.watch(mainTabIndexProvider),
                children: const [
                  Scaffold(body: Text('HOME')),
                  SizedBox(),
                  FirstVisitExplainer(
                    explainer: PageExplainers.accountability,
                    tabIndex: MainTabIndex.accountability,
                    child: Scaffold(body: Text('STAKES')),
                  ),
                  FirstVisitExplainer(
                    explainer: PageExplainers.groups,
                    tabIndex: MainTabIndex.community,
                    child: Scaffold(body: Text('GROUPS')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.text('HOME')),
      );
      Future<void> visit(int tab) async {
        container.read(mainTabIndexProvider.notifier).state = tab;
        await tester.pump();
        await tester.pump(_delay);
        await tester.pumpAndSettle();
      }

      Future<void> dismiss() async {
        await tester.ensureVisible(find.text('Maybe later'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Maybe later'));
        await tester.pumpAndSettle();
      }

      await visit(MainTabIndex.accountability);
      expect(find.text(PageExplainers.accountability.title), findsOneWidget);
      await dismiss();

      await visit(MainTabIndex.community);
      expect(find.text(PageExplainers.groups.title), findsOneWidget);
      await dismiss();

      // Second visits stay quiet.
      await visit(MainTabIndex.accountability);
      await visit(MainTabIndex.community);
      expect(find.text(PageExplainers.accountability.title), findsNothing);
      expect(find.text(PageExplainers.groups.title), findsNothing);
    });

    testWidgets('a tab page waits until its tab is selected', (tester) async {
      await tester.pumpWidget(
        _page(
          PageExplainers.accountability,
          tabIndex: MainTabIndex.accountability,
        ),
      );
      await tester.pump();
      await tester.pump(_delay);
      await tester.pumpAndSettle();
      expect(find.text(PageExplainers.accountability.title), findsNothing);

      final container = ProviderScope.containerOf(
        tester.element(find.text('PAGE')),
      );
      container.read(mainTabIndexProvider.notifier).state =
          MainTabIndex.accountability;
      await tester.pump();
      await tester.pump(_delay);
      await tester.pumpAndSettle();
      expect(find.text(PageExplainers.accountability.title), findsOneWidget);
    });
  });
}
