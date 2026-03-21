class AppConfig {
  const AppConfig._();

  // V1 runs without auth; this fixed id keeps Firestore paths user-scoped.
  static const String localUserId = 'local-user-v1';
}
