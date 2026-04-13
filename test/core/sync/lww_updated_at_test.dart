import 'package:coach_for_life/core/sync/lww_updated_at.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies when there is no local row', () {
    expect(
      shouldApplyRemoteUpdatedAt(localUpdatedAtMs: null, remoteUpdatedAtMs: 5),
      isTrue,
    );
  });

  test('applies only when remote is strictly newer', () {
    expect(
      shouldApplyRemoteUpdatedAt(localUpdatedAtMs: 10, remoteUpdatedAtMs: 11),
      isTrue,
    );
    expect(
      shouldApplyRemoteUpdatedAt(localUpdatedAtMs: 10, remoteUpdatedAtMs: 10),
      isFalse,
    );
    expect(
      shouldApplyRemoteUpdatedAt(localUpdatedAtMs: 10, remoteUpdatedAtMs: 9),
      isFalse,
    );
  });
}
