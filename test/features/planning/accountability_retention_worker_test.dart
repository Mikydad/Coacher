import 'package:coach_for_life/features/planning/application/accountability_retention_worker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retention worker delegates prune call with 30-day policy', () async {
    var called = false;
    int? days;
    final worker = AccountabilityRetentionWorker(({
      int retentionDays = 30,
      int? nowMs,
    }) async {
      called = true;
      days = retentionDays;
      return 3;
    });
    final removed = await worker.run(retentionDays: 30);
    expect(called, isTrue);
    expect(days, 30);
    expect(removed, 3);
  });
}
