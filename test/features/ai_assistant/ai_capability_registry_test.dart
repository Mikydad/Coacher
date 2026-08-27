import 'package:sidepal/features/ai_assistant/application/ai_capability_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

}
