class OfflineOperation {
  const OfflineOperation({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.documentPath,
    required this.payload,
    required this.updatedAtMs,
  });

  final String id;
  final String entityType;
  final String operationType; // upsert | delete
  final String documentPath;
  final Map<String, dynamic>? payload;
  final int updatedAtMs;

  Map<String, dynamic> toMap() => {
    'id': id,
    'entityType': entityType,
    'operationType': operationType,
    'documentPath': documentPath,
    'payload': payload,
    'updatedAtMs': updatedAtMs,
  };

  static OfflineOperation fromMap(Map<String, dynamic> map) => OfflineOperation(
    id: map['id'] as String,
    entityType: map['entityType'] as String,
    operationType: map['operationType'] as String,
    documentPath: map['documentPath'] as String,
    payload: (map['payload'] as Map?)?.cast<String, dynamic>(),
    updatedAtMs: map['updatedAtMs'] as int,
  );
}
