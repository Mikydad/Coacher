import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/ai_assistant/application/voice_selection.dart';

Map<String, String> _voice(
  String name,
  String locale,
  String quality, {
  String? identifier,
}) => {
  'name': name,
  'locale': locale,
  'quality': quality,
  'identifier': ?identifier,
};

void main() {
  group('pickPreferredIosVoice', () {
    test('returns null when only compact (default) voices are installed', () {
      final voices = [
        _voice('Samantha', 'en-US', 'default'),
        _voice('Fred', 'en-US', 'default'),
      ];
      expect(pickPreferredIosVoice(voices, 'en-US'), isNull);
    });

    test('picks enhanced over default and carries the identifier', () {
      final voices = [
        _voice('Samantha', 'en-US', 'default'),
        _voice(
          'Samantha (Enhanced)',
          'en-US',
          'enhanced',
          identifier: 'com.apple.voice.enhanced.en-US.Samantha',
        ),
      ];
      final picked = pickPreferredIosVoice(voices, 'en-US');
      expect(picked?['name'], 'Samantha (Enhanced)');
      expect(
        picked?['identifier'],
        'com.apple.voice.enhanced.en-US.Samantha',
      );
    });

    test('premium beats enhanced within the same locale', () {
      final voices = [
        _voice('Samantha (Enhanced)', 'en-US', 'enhanced'),
        _voice('Ava (Premium)', 'en-US', 'premium'),
      ];
      expect(
        pickPreferredIosVoice(voices, 'en-US')?['name'],
        'Ava (Premium)',
      );
    });

    test('exact locale (accent) beats higher quality elsewhere', () {
      final voices = [
        _voice('Ava (Premium)', 'en-US', 'premium'),
        _voice('Serena (Enhanced)', 'en-GB', 'enhanced'),
      ];
      expect(
        pickPreferredIosVoice(voices, 'en-GB')?['name'],
        'Serena (Enhanced)',
      );
    });

    test('same-language fallback when no exact locale is installed', () {
      final voices = [
        _voice('Karen (Enhanced)', 'en-AU', 'enhanced'),
        _voice('Alice (Premium)', 'it-IT', 'premium'),
      ];
      expect(
        pickPreferredIosVoice(voices, 'en-US')?['name'],
        'Karen (Enhanced)',
      );
    });

    test('other languages never win regardless of quality', () {
      final voices = [_voice('Alice (Premium)', 'it-IT', 'premium')];
      expect(pickPreferredIosVoice(voices, 'en-US'), isNull);
    });

    test('handles underscore locales and malformed entries', () {
      final voices = <dynamic>[
        'garbage',
        <Object?, Object?>{'name': null, 'locale': 'en-US'},
        _voice('Samantha (Enhanced)', 'en_US', 'enhanced'),
      ];
      expect(
        pickPreferredIosVoice(voices, 'en_US')?['name'],
        'Samantha (Enhanced)',
      );
    });

    test('tie-breaks deterministically by name', () {
      final voices = [
        _voice('Zoe (Enhanced)', 'en-US', 'enhanced'),
        _voice('Allison (Enhanced)', 'en-US', 'enhanced'),
      ];
      expect(
        pickPreferredIosVoice(voices, 'en-US')?['name'],
        'Allison (Enhanced)',
      );
    });
  });
}
