import 'package:coach_for_life/app/app.dart';
import 'package:coach_for_life/features/execution/application/execution_day_loader.dart';
import 'package:coach_for_life/features/planning/application/planned_task_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home scaffold renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          executionDayTasksProvider.overrideWith((ref) async => const []),
          todayAllTasksRowsProvider.overrideWith((ref) => Stream.value(const [])),
          openTasksOutsideTodayProvider.overrideWith((ref) async => const []),
        ],
        child: const CoachForLifeApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Quittr'), findsOneWidget);
    expect(find.textContaining("Today's Progress"), findsOneWidget);
  });
}
