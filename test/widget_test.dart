import 'package:sidepal/app/app.dart';
import 'package:sidepal/features/execution/application/execution_day_loader.dart';
import 'package:sidepal/features/planning/application/planned_task_providers.dart';
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
    expect(find.text('SidePal'), findsOneWidget);
    // Progress left the bottom nav (lives in Profile now); Accountability
    // took its slot.
    expect(find.text('Accountability'), findsOneWidget);
    expect(find.text('Progress'), findsNothing);
  });
}
