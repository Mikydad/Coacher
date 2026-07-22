import 'package:sidepal/features/analytics/application/feature_builder_input_adapters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureBuilderDateNormalizer', () {
    test('rollingWindow builds inclusive date keys', () {
      final window = FeatureBuilderDateNormalizer.rollingWindow(
        now: DateTime(2026, 5, 6, 23, 59),
        trailingDays: 3,
      );

      expect(window.startDateKey, '2026-05-04');
      expect(window.endDateKey, '2026-05-06');
      expect(window.dateKeys, ['2026-05-04', '2026-05-05', '2026-05-06']);
    });

    test('iso conversion returns null for bad values', () {
      expect(FeatureBuilderDateNormalizer.dateKeyFromIsoLocal(null), isNull);
      expect(FeatureBuilderDateNormalizer.dateKeyFromIsoLocal(''), isNull);
      expect(
        FeatureBuilderDateNormalizer.dateKeyFromIsoLocal('bad-date'),
        isNull,
      );
    });

    test('epoch and datetime normalization use local calendar date', () {
      final local = DateTime(2026, 4, 30, 12, 30);
      final fromDate = FeatureBuilderDateNormalizer.dateKeyFromDateTime(local);
      final fromEpoch = FeatureBuilderDateNormalizer.dateKeyFromEpochMs(
        local.millisecondsSinceEpoch,
      );
      expect(fromDate, '2026-04-30');
      expect(fromEpoch, '2026-04-30');
    });
  });
}
