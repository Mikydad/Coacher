import 'package:coach_for_life/features/analytics/application/pattern_scoring.dart';
import 'package:coach_for_life/features/analytics/domain/models/detected_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pattern_scoring', () {
    test('centralized config includes all Layer 2 V1 pattern codes', () {
      expect(kLayer2PatternConfig.version, kLayer2PatternConfigVersion);
      expect(
        kLayer2PatternConfig.baseSeverityByCode.keys.toSet(),
        equals(kLayer2V1PatternCodes),
      );
    });

    test('base severity lookup is deterministic and clamped', () {
      expect(
        baseSeverityForPattern(PatternCode.streakRisk),
        closeTo(0.90, 0.0001),
      );
      expect(
        baseSeverityForPattern(PatternCode.strongStreak),
        closeTo(0.15, 0.0001),
      );
    });

    test('normalizedDistance supports higher-is-worse and lower-is-worse', () {
      final higher = normalizedDistance(
        value: 0.8,
        threshold: 0.6,
        higherIsWorse: true,
        maxSpan: 0.4,
      );
      final lower = normalizedDistance(
        value: 0.3,
        threshold: 0.6,
        higherIsWorse: false,
        maxSpan: 0.6,
      );
      expect(higher, closeTo(0.5, 0.0001));
      expect(lower, closeTo(0.5, 0.0001));
    });

    test('hybrid severity blends base and signal adjustments', () {
      final severity = computeHybridSeverity(
        patternCode: PatternCode.tooHard,
        thresholdDistance: 0.8,
        signalStrength: 0.6,
      );
      expect(severity, greaterThan(0.0));
      expect(severity, lessThanOrEqualTo(1.0));
    });

    test('hybrid confidence clamps and weights all components', () {
      final confidence = computeHybridConfidence(
        dataCompleteness: 0.9,
        sampleQuality: 0.75,
        signalStrength: 0.8,
      );
      expect(confidence, greaterThan(0.0));
      expect(confidence, lessThanOrEqualTo(1.0));
    });

    test('utility clamps produce safe normalized values', () {
      expect(clampUnit(3.2), 1.0);
      expect(clampUnit(-0.5), 0.0);
      expect(clampNonNegative(-2.1), 0.0);
      expect(clampNonNegative(1.2), 1.2);
    });
  });
}
