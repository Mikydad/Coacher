import 'package:coach_for_life/features/ai_assistant/application/entity_normaliser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const normaliser = EntityNormaliser();

  group('EntityNormaliser.normalise', () {
    test('fitness keywords map to fitness', () {
      for (final kw in ['workout', 'gym', 'exercise', 'run', 'cardio', 'swim']) {
        expect(normaliser.normalise(kw), 'fitness', reason: '"$kw" should map to fitness');
      }
    });

    test('study keywords map to study', () {
      for (final kw in ['study', 'reading', 'homework', 'revision']) {
        expect(normaliser.normalise(kw), 'study', reason: '"$kw" should map to study');
      }
    });

    test('work keywords map to work', () {
      for (final kw in ['meeting', 'standup', 'call', 'presentation']) {
        expect(normaliser.normalise(kw), 'work', reason: '"$kw" should map to work');
      }
    });

    test('sleep keywords map to sleep', () {
      for (final kw in ['sleep', 'nap', 'rest', 'bedtime']) {
        expect(normaliser.normalise(kw), 'sleep', reason: '"$kw" should map to sleep');
      }
    });

    test('meal keywords map to meal', () {
      for (final kw in ['breakfast', 'lunch', 'dinner', 'meal prep', 'cook']) {
        expect(normaliser.normalise(kw), 'meal', reason: '"$kw" should map to meal');
      }
    });

    test('mindfulness keywords map to mindfulness', () {
      for (final kw in ['meditation', 'yoga', 'journaling', 'mindfulness']) {
        expect(normaliser.normalise(kw), 'mindfulness',
            reason: '"$kw" should map to mindfulness');
      }
    });

    test('mixed case is normalised', () {
      expect(normaliser.normalise('WORKOUT'), 'fitness');
      expect(normaliser.normalise('Meditation'), 'mindfulness');
    });

    test('unknown entity is returned as lowercase cleaned string', () {
      expect(normaliser.normalise('Hiking'), 'hiking');
      // 'practice' is a study keyword, so 'Piano Practice' maps to study
      // (this is expected behaviour — generic match)
      expect(normaliser.normalise('Totally Unknown Activity'), 'totally unknown activity');
    });

    test('punctuation is stripped', () {
      expect(normaliser.normalise('gym!!!'), 'fitness');
      expect(normaliser.normalise('lunch.'), 'meal');
    });
  });

  group('EntityNormaliser.similarityScore', () {
    test('exact category match returns 1.0', () {
      // "workout" and "gym" both normalise to "fitness"
      expect(normaliser.similarityScore('workout', 'workout'), 1.0);
    });

    test('same category returns 0.9', () {
      // "workout" → fitness, "gym session" → fitness (different raw strings, same norm)
      expect(normaliser.similarityScore('workout', 'gym session'), 0.9);
    });

    test('partial word overlap returns 0.7', () {
      // "morning piano" and "evening piano" share the word "piano"
      expect(normaliser.similarityScore('morning piano', 'evening piano'), 0.7);
    });

    test('no match returns 0.0', () {
      expect(normaliser.similarityScore('hiking', 'piano'), 0.0);
    });

    test('case insensitive comparison — same category', () {
      // WORKOUT → fitness, gym → fitness → both normalise to fitness → 0.9
      expect(normaliser.similarityScore('WORKOUT', 'gym'), 0.9);
    });
  });
}
