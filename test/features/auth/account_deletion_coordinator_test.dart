import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/session/session_scope.dart';
import 'package:sidepal/features/auth/application/account_deletion_coordinator.dart';
import 'package:sidepal/features/auth/application/auth_repository_interface.dart';
import 'package:sidepal/features/auth/domain/auth_failure.dart';

/// Only deleteAccount matters here; everything else is unreachable.
class _FakeAuth implements AuthRepositoryInterface {
  _FakeAuth({this.failure});

  final AuthFailure? failure;
  int deleteCalls = 0;

  @override
  Future<AuthFailure?> deleteAccount() async {
    deleteCalls++;
    return failure;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(SessionScope.resetForTests);
  tearDown(SessionScope.resetForTests);

  test('success: transports released BEFORE delete, wipe runs AFTER, no mounted gate', () async {
    final auth = _FakeAuth();
    final log = <String>[];
    final result = await AccountDeletionCoordinator.run(
      auth: auth,
      releaseTransports: () async => log.add('release'),
      clearLocalSession: () async {
        log.add('wipe(gen=${SessionScope.generation})');
      },
    );
    expect(result, isNull);
    expect(auth.deleteCalls, 1);
    expect(log, ['release', 'wipe(gen=1)']);
    expect(
      SessionScope.isTearingDown,
      isTrue,
      reason: 'the injected wipe did not end the teardown; the real one does',
    );
  });

  test('failure: no wipe, teardown lifted so the session resumes', () async {
    final auth = _FakeAuth(failure: const NetworkFailure());
    var wiped = false;
    final result = await AccountDeletionCoordinator.run(
      auth: auth,
      releaseTransports: () async {},
      clearLocalSession: () async => wiped = true,
    );
    expect(result, isA<NetworkFailure>());
    expect(wiped, isFalse);
    expect(SessionScope.isTearingDown, isFalse);
    expect(SessionScope.generation, 1, reason: 'jobs from before the attempt stay stale');
  });

  test('a transport-release failure does not block deletion', () async {
    final auth = _FakeAuth();
    var wiped = false;
    final result = await AccountDeletionCoordinator.run(
      auth: auth,
      releaseTransports: () async => throw StateError('no push channel'),
      clearLocalSession: () async => wiped = true,
    );
    expect(result, isNull);
    expect(wiped, isTrue);
  });
}
