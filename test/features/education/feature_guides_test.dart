import 'package:coach_for_life/features/ai_assistant/application/ai_informational_output_guard.dart';
import 'package:coach_for_life/features/education/domain/feature_guides.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureGuides content invariants', () {
    test('ids are unique and non-empty', () {
      final ids = FeatureGuides.all.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.every((id) => id.trim().isNotEmpty), isTrue);
    });

    test('every guide has keywords, lowercase and non-empty', () {
      for (final g in FeatureGuides.all) {
        expect(g.keywords, isNotEmpty, reason: g.id);
        for (final k in g.keywords) {
          expect(k, k.toLowerCase(), reason: '${g.id}: "$k"');
          expect(k.trim(), isNotEmpty, reason: g.id);
        }
      }
    });

    test('every guide has at least 2 how-steps', () {
      for (final g in FeatureGuides.all) {
        expect(g.howSteps.length, greaterThanOrEqualTo(2), reason: g.id);
      }
    });

    // A guide containing a forbidden substring (e.g. "Firestore") would make
    // AiInformationalOutputGuard replace the AI's whole teaching answer with
    // a fallback. Check every string through the REAL guard.
    test('no guide text trips the informational output guard', () {
      for (final g in FeatureGuides.all) {
        final texts = [
          g.toPromptBlock(),
          g.oneLiner,
          ...g.tips,
          ...g.suggestedPrompts,
        ];
        for (final t in texts) {
          expect(
            AiInformationalOutputGuard.looksLikeInternalLeak(t),
            isFalse,
            reason: '${g.id}: "$t"',
          );
        }
      }
    });
  });

  group('FeatureGuides.matchTopic', () {
    test('longest keyword wins', () {
      // 'which discipline mode should i use' contains 'which mode' (circles?
      // no) and 'discipline mode' — disciplineModes must win.
      final g = FeatureGuides.matchTopic('Which discipline mode should I use?');
      expect(g?.id, 'disciplineModes');
    });

    test('matches common topics', () {
      expect(FeatureGuides.matchTopic('what are circles?')?.id, 'circles');
      expect(
        FeatureGuides.matchTopic('teach me how reminders work')?.id,
        'reminders',
      );
      expect(FeatureGuides.matchTopic('explain focus mode')?.id, 'focus');
      expect(
        FeatureGuides.matchTopic('what is plan tomorrow')?.id,
        'planTomorrow',
      );
    });

    test('returns null when nothing matches', () {
      expect(FeatureGuides.matchTopic('good morning!'), isNull);
    });
  });

  group('FeatureGuides.isEducationQuestion', () {
    test('accepts questions about features', () {
      expect(FeatureGuides.isEducationQuestion('What are Circles?'), isTrue);
      expect(
        FeatureGuides.isEducationQuestion('teach me how reminders work'),
        isTrue,
      );
      expect(
        FeatureGuides.isEducationQuestion('Which mode should I use'),
        isTrue,
      );
    });

    test('rejects commands even when they name a feature', () {
      expect(
        FeatureGuides.isEducationQuestion('add me to a circle'),
        isFalse,
      );
      expect(
        FeatureGuides.isEducationQuestion('add a workout task at 6am'),
        isFalse,
      );
    });

    test('rejects education phrasing with no feature topic', () {
      expect(
        FeatureGuides.isEducationQuestion('what is the meaning of life'),
        isFalse,
      );
    });
  });

  test('byId finds every guide', () {
    for (final g in FeatureGuides.all) {
      expect(FeatureGuides.byId(g.id), same(g));
    }
    expect(FeatureGuides.byId('nope'), isNull);
  });

  group('element help topics', () {
    test('ids unique across pages + elements; byId resolves all', () {
      final ids = FeatureGuides.searchable.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final g in FeatureGuides.searchable) {
        expect(FeatureGuides.byId(g.id), same(g));
      }
    });

    // matchTopic breaks ties toward the first list ([all]), so an element
    // keyword that duplicates a page-guide keyword can never match — it is
    // dead content. Enforce exact-string uniqueness across the whole set.
    test('keywords are exact-string unique across the combined set', () {
      final seen = <String, String>{};
      for (final g in FeatureGuides.searchable) {
        for (final k in g.keywords) {
          expect(
            seen.containsKey(k),
            isFalse,
            reason: '"$k" used by both ${seen[k]} and ${g.id}',
          );
          seen[k] = g.id;
        }
      }
    });

    test('element keywords lowercase/non-empty; steps non-blank if present',
        () {
      for (final g in FeatureGuides.elements) {
        expect(g.keywords, isNotEmpty, reason: g.id);
        for (final k in g.keywords) {
          expect(k, k.toLowerCase(), reason: '${g.id}: "$k"');
          expect(k.trim(), isNotEmpty, reason: g.id);
        }
        for (final s in g.howSteps) {
          expect(s.trim(), isNotEmpty, reason: g.id);
        }
      }
    });

    // The HelpSheet "Ask Coach about this" button prefills
    // "Tell me about <title>" — every element must resolve back to itself.
    test('ask-coach round-trip resolves every element topic', () {
      for (final g in FeatureGuides.elements) {
        final query = 'tell me about ${g.title.toLowerCase()}';
        expect(
          FeatureGuides.matchTopic(query)?.id,
          g.id,
          reason: query,
        );
        expect(FeatureGuides.isEducationQuestion(query), isTrue, reason: query);
      }
    });

    test('element questions match: flow now / task integrity', () {
      expect(FeatureGuides.matchTopic('what is flow now')?.id, 'flowNow');
      expect(
        FeatureGuides.matchTopic('explain task integrity')?.id,
        'taskIntegrity',
      );
    });

    test('no element text trips the informational output guard', () {
      for (final g in FeatureGuides.elements) {
        final texts = [
          g.toPromptBlock(),
          g.oneLiner,
          ...g.tips,
          ...g.suggestedPrompts,
        ];
        for (final t in texts) {
          expect(
            AiInformationalOutputGuard.looksLikeInternalLeak(t),
            isFalse,
            reason: '${g.id}: "$t"',
          );
        }
      }
    });
  });
}
