import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Cryptographic nonce for Sign in with Apple + Firebase Auth.
String generateAppleAuthNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

/// SHA-256 hash of [input], hex-encoded (required by Apple authorization).
String sha256Nonce(String input) {
  final digest = sha256.convert(utf8.encode(input));
  return digest.toString();
}
