import 'package:coach_for_life/features/ai_assistant/application/ai_intent_router.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_intent_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiIntentRouter.classify', () {
    final cases = <({String input, AiIntentKind kind, AiFocusDate? focus})>[
      (input: "What's my plan for tomorrow?", kind: AiIntentKind.query, focus: AiFocusDate.tomorrow),
      (input: 'Show me my schedule today', kind: AiIntentKind.query, focus: AiFocusDate.today),
      (input: 'Tell me what is on my plan', kind: AiIntentKind.query, focus: null),
      (input: 'List my tasks for tomorrow', kind: AiIntentKind.query, focus: AiFocusDate.tomorrow),
      (input: 'How many tasks do I have today?', kind: AiIntentKind.query, focus: AiFocusDate.today),
      (input: 'When is my workout tomorrow?', kind: AiIntentKind.query, focus: AiFocusDate.tomorrow),
      (input: 'How am I doing on my goals?', kind: AiIntentKind.query, focus: null),
      (input: 'Add gym at 6am tomorrow', kind: AiIntentKind.mutate, focus: AiFocusDate.tomorrow),
      (input: 'Create a reading task at 9', kind: AiIntentKind.mutate, focus: null),
      (input: 'Delete morning workout', kind: AiIntentKind.mutate, focus: null),
      (input: 'Move study to 8am', kind: AiIntentKind.mutate, focus: null),
      (input: 'Schedule meditation at 7', kind: AiIntentKind.mutate, focus: null),
      (input: 'Remove the gym reminder', kind: AiIntentKind.mutate, focus: null),
      (input: 'Set focus mode for 30 minutes', kind: AiIntentKind.mutate, focus: null),
      (input: 'Help me plan tomorrow', kind: AiIntentKind.suggest, focus: AiFocusDate.tomorrow),
      (input: 'Plan my day tomorrow', kind: AiIntentKind.suggest, focus: AiFocusDate.tomorrow),
      (input: 'Suggest a schedule for today', kind: AiIntentKind.suggest, focus: AiFocusDate.today),
      (input: 'Recommend tasks for tomorrow morning', kind: AiIntentKind.suggest, focus: AiFocusDate.tomorrow),
      (input: 'Optimize my tomorrow schedule', kind: AiIntentKind.suggest, focus: AiFocusDate.tomorrow),
      (input: 'Fill my free time tomorrow', kind: AiIntentKind.suggest, focus: AiFocusDate.tomorrow),
      (input: 'Help me with planning this week', kind: AiIntentKind.suggest, focus: AiFocusDate.week),
      (input: 'Plan tomorrow', kind: AiIntentKind.suggest, focus: AiFocusDate.tomorrow),
    ];

    for (final c in cases) {
      test('${c.input} → ${c.kind.name}', () {
        final route = AiIntentRouter.classify(c.input);
        expect(route.kind, c.kind, reason: c.input);
        expect(route.focusDate, c.focus, reason: c.input);
      });
    }
  });
}
