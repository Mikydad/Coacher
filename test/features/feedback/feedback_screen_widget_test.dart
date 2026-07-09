import 'dart:typed_data';

import 'package:coach_for_life/features/feedback/application/feedback_context_collector.dart';
import 'package:coach_for_life/features/feedback/application/feedback_submit_service.dart';
import 'package:coach_for_life/features/feedback/data/feedback_repository.dart';
import 'package:coach_for_life/features/feedback/domain/models/feedback_report.dart';
import 'package:coach_for_life/features/feedback/presentation/feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingRepository implements FeedbackRepository {
  final List<FeedbackReport> submitted = [];

  @override
  Future<void> submit(
    FeedbackReport report, {
    Uint8List? screenshotBytes,
    String screenshotContentType = 'image/png',
  }) async {
    submitted.add(report);
  }
}

void main() {
  late _RecordingRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = _RecordingRepository();
  });

  Widget buildScreen() => ProviderScope(
    overrides: [
      feedbackRepositoryProvider.overrideWithValue(repository),
      feedbackContextCollectorProvider.overrideWith(
        (ref) => FeedbackContextCollector(
          ref,
          packageInfoLoader: () async => throw Exception('no plugin in VM'),
          deviceInfoLoader: () async => throw Exception('no plugin in VM'),
          connectivityLoader: () async => throw Exception('no plugin in VM'),
        ),
      ),
    ],
    child: const MaterialApp(home: FeedbackScreen()),
  );

  testWidgets('renders the four type chips with Bug preselected', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());

    for (final label in ['Bug', 'Feature idea', 'Question', 'Other']) {
      expect(find.text(label), findsOneWidget);
    }
    final bugChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('Bug'), matching: find.byType(ChoiceChip)),
    );
    expect(bugChip.selected, isTrue);
  });

  testWidgets('Send is disabled when the message is empty', (tester) async {
    await tester.pumpWidget(buildScreen());

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('submits the typed message with the selected type', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());

    await tester.tap(find.text('Question'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextField),
      'How do I archive a goal?',
    );
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(repository.submitted, hasLength(1));
    final report = repository.submitted.single;
    expect(report.type, FeedbackType.question);
    expect(report.message, 'How do I archive a goal?');
    expect(report.context['appVersion'], 'unknown'); // collector degraded
    expect(find.text('Feedback sent — thank you!'), findsOneWidget);
  });

  testWidgets('a second submit inside the cool-down shows the wait message', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());

    await tester.enterText(find.byType(TextField), 'first');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(repository.submitted, hasLength(1));

    await tester.enterText(find.byType(TextField), 'second');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    // Let the success SnackBar (4s) expire so the queued rate-limit one shows.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(repository.submitted, hasLength(1)); // still just the first
    expect(find.textContaining('Please wait'), findsOneWidget);
  });
}
