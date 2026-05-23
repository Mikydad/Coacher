import 'package:coach_for_life/core/sync/post_sync_refresh_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    PostSyncRefreshCoordinator.instance.resetForTests();
    PostSyncRefreshCoordinator.debounceForTests = const Duration(milliseconds: 40);
  });

  tearDown(() {
    PostSyncRefreshCoordinator.instance.resetForTests();
    PostSyncRefreshCoordinator.debounceForTests =
        PostSyncRefreshCoordinator.debounce;
  });

  test('coalesces multiple schedule calls into one flush', () async {
    final coordinator = PostSyncRefreshCoordinator.instance;

    coordinator.schedule(tasks: true);
    coordinator.schedule(coachingDelivery: true);
    coordinator.schedule(todayAnalytics: true);

    expect(coordinator.flushCountForTests, 0);

    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(coordinator.flushCountForTests, 1);
  });

  test('flushNowForTests runs immediately', () {
    final coordinator = PostSyncRefreshCoordinator.instance;
    coordinator.schedule(tasks: true);
    coordinator.flushNowForTests();
    expect(coordinator.flushCountForTests, 1);
  });
}
