class OfflineOperation {
  const OfflineOperation({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.documentPath,
    required this.payload,
    required this.updatedAtMs,
    this.uid,
    this.attempts = 0,
    this.nextAttemptMs = 0,
  });

  final String id;
  final String entityType;
  final String operationType; // upsert | delete
  final String documentPath;
  final Map<String, dynamic>? payload;
  final int updatedAtMs;

  /// Uid of the user who enqueued this operation. Ops whose uid does not
  /// match the current user are dropped at flush time so one account's
  /// offline writes never replay into another account's Firestore tree.
  /// Null only for entries persisted before this field existed.
  final String? uid;

  /// Failed flush attempts so far (audit M4). Drives the back-off below.
  final int attempts;

  /// Earliest time the next attempt may run (0 = immediately).
  final int nextAttemptMs;

  OfflineOperation withRetryScheduled({
    required int attempts,
    required int nextAttemptMs,
  }) => OfflineOperation(
    id: id,
    entityType: entityType,
    operationType: operationType,
    documentPath: documentPath,
    payload: payload,
    updatedAtMs: updatedAtMs,
    uid: uid,
    attempts: attempts,
    nextAttemptMs: nextAttemptMs,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'entityType': entityType,
    'operationType': operationType,
    'documentPath': documentPath,
    'payload': payload,
    'updatedAtMs': updatedAtMs,
    if (uid != null) 'uid': uid,
    if (attempts > 0) 'attempts': attempts,
    if (nextAttemptMs > 0) 'nextAttemptMs': nextAttemptMs,
  };

  static OfflineOperation fromMap(Map<String, dynamic> map) => OfflineOperation(
    id: map['id'] as String,
    entityType: map['entityType'] as String,
    operationType: map['operationType'] as String,
    documentPath: map['documentPath'] as String,
    payload: (map['payload'] as Map?)?.cast<String, dynamic>(),
    updatedAtMs: map['updatedAtMs'] as int,
    uid: map['uid'] as String?,
    attempts: (map['attempts'] as num?)?.toInt() ?? 0,
    nextAttemptMs: (map['nextAttemptMs'] as num?)?.toInt() ?? 0,
  );
}
