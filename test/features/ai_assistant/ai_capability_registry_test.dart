import 'package:coach_for_life/features/ai_assistant/application/ai_capability_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiCapabilityRegistry.buildPayloadSection', () {
    test('includes read, mutate, and unsupported domain ids', () {
      final section = AiCapabilityRegistry.buildPayloadSection();

      expect(section['read'], AiCapabilityRegistry.supportedRead);
      expect(section['mutate'], AiCapabilityRegistry.supportedMutate);
      expect(section['unsupported'], contains('community'));
      expect(section['unsupported'], contains('billing'));
    });
  });

  group('AiCapabilityRegistry.detectUnsupported', () {
    test('returns community match for circle queries', () {
      final match = AiCapabilityRegistry.detectUnsupported(
        'What did my circle post today?',
      );

      expect(match, isNotNull);
      expect(match!.domainId, 'community');
      expect(match.message, contains('Circles'));
    });

    test('returns billing match for subscription queries', () {
      final match = AiCapabilityRegistry.detectUnsupported(
        'Cancel my subscription please',
      );

      expect(match, isNotNull);
      expect(match!.domainId, 'billing');
    });

    test('returns null for schedule queries', () {
      final match = AiCapabilityRegistry.detectUnsupported(
        'What is my plan for tomorrow?',
      );

      expect(match, isNull);
    });
  });

  group('AiCapabilityRegistry.formatForPrompt', () {
    test('lists supported read and mutate scopes', () {
      final prompt = AiCapabilityRegistry.formatForPrompt();

      expect(prompt, contains('today_schedule'));
      expect(prompt, contains('tasks_create_edit_move_delete'));
      expect(prompt, contains('unsupported'));
    });
  });
}
