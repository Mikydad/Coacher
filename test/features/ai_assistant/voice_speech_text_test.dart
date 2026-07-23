import 'package:sidepal/features/ai_assistant/application/voice_speech_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeForSpeech', () {
    test('strips mem grounding markers with and without labels', () {
      expect(
        sanitizeForSpeech('Sarah is your sister. [mem:abc123]'),
        'Sarah is your sister.',
      );
      expect(
        sanitizeForSpeech('You prefer mornings [mem:x9_Z-1|stated] for this.'),
        'You prefer mornings for this.',
      );
    });

    test('unwraps bold and removes list markers', () {
      expect(sanitizeForSpeech('This is **really** key'), 'This is really key');
      expect(
        sanitizeForSpeech('- first thing\n- second thing\n1. third'),
        'first thing\nsecond thing\nthird',
      );
    });

    test('collapses runs of spaces and blank lines', () {
      expect(
        sanitizeForSpeech('Hello   there.\n\n\nNext  line.'),
        'Hello there.\nNext line.',
      );
    });

    test('plain text passes through untouched', () {
      expect(sanitizeForSpeech('Just a plain reply.'), 'Just a plain reply.');
    });
  });

  group('splitIntoSentences', () {
    test('splits on sentence terminators', () {
      expect(splitIntoSentences('One. Two! Three? Four… Five'), [
        'One.',
        'Two!',
        'Three?',
        'Four…',
        'Five',
      ]);
    });

    test('newlines are boundaries (list-style replies)', () {
      expect(splitIntoSentences('call your cousin\nbook the dentist'), [
        'call your cousin',
        'book the dentist',
      ]);
    });

    test('does not split on periods without trailing whitespace', () {
      expect(splitIntoSentences('Around 2.30 works'), ['Around 2.30 works']);
    });

    test('tiny fragments merge into the previous chunk', () {
      expect(splitIntoSentences('Sounds good. Ok'), ['Sounds good. Ok']);
    });

    test('empty and whitespace-only input yields no chunks', () {
      expect(splitIntoSentences(''), isEmpty);
      expect(splitIntoSentences('  \n '), isEmpty);
    });
  });

  group('speechChunksFor', () {
    test('sanitizes then chunks a realistic Coach reply', () {
      const reply =
          'You mentioned Sarah is your **sister** [mem:f1|stated]. '
          'Want me to find a good time?\n- tomorrow morning\n- Saturday';
      expect(speechChunksFor(reply), [
        'You mentioned Sarah is your sister.',
        'Want me to find a good time?',
        'tomorrow morning',
        'Saturday',
      ]);
    });
  });
}
