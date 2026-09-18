import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/community/domain/models/circle_enums.dart';

/// The server posts `stakePhotoRemoved` when a live stake photo is taken
/// down early (P-5, 2026-09-18); the client must parse it by name.
void main() {
  test('stakePhotoRemoved round-trips its storage name', () {
    expect(
      ActivityEventTypeStorage.fromStorage('stakePhotoRemoved'),
      ActivityEventType.stakePhotoRemoved,
    );
    expect(ActivityEventType.stakePhotoRemoved.storageValue, 'stakePhotoRemoved');
  });
}
