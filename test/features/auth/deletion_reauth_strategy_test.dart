import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/auth/application/deletion_reauth_strategy.dart';

void main() {
  test('apple always wins (revocation is mandatory)', () {
    expect(deletionReauthFor(['password', 'apple.com']), DeletionReauth.apple);
    expect(deletionReauthFor(['google.com', 'apple.com']), DeletionReauth.apple);
  });

  test('google before password', () {
    expect(deletionReauthFor(['password', 'google.com']), DeletionReauth.google);
    expect(deletionReauthFor(['google.com']), DeletionReauth.google);
  });

  test('password alone → dialog; anonymous / empty → none', () {
    expect(deletionReauthFor(['password']), DeletionReauth.password);
    expect(deletionReauthFor(const []), DeletionReauth.none);
    expect(deletionReauthFor(['phone']), DeletionReauth.none);
  });
}
