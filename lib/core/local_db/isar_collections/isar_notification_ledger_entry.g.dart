// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_notification_ledger_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarNotificationLedgerEntryCollection on Isar {
  IsarCollection<IsarNotificationLedgerEntry>
  get isarNotificationLedgerEntrys => this.collection();
}

const IsarNotificationLedgerEntrySchema = CollectionSchema(
  name: r'IsarNotificationLedgerEntry',
  id: 5070143245161287990,
  properties: {
    r'cancelledAtMs': PropertySchema(
      id: 0,
      name: r'cancelledAtMs',
      type: IsarType.long,
    ),
    r'deliveredAtMs': PropertySchema(
      id: 1,
      name: r'deliveredAtMs',
      type: IsarType.long,
    ),
    r'entityId': PropertySchema(
      id: 2,
      name: r'entityId',
      type: IsarType.string,
    ),
    r'entityKind': PropertySchema(
      id: 3,
      name: r'entityKind',
      type: IsarType.string,
    ),
    r'ignoredCount': PropertySchema(
      id: 4,
      name: r'ignoredCount',
      type: IsarType.long,
    ),
    r'interactedAtMs': PropertySchema(
      id: 5,
      name: r'interactedAtMs',
      type: IsarType.long,
    ),
    r'interactionType': PropertySchema(
      id: 6,
      name: r'interactionType',
      type: IsarType.string,
    ),
    r'notifId': PropertySchema(id: 7, name: r'notifId', type: IsarType.long),
    r'scheduledForMs': PropertySchema(
      id: 8,
      name: r'scheduledForMs',
      type: IsarType.long,
    ),
    r'snoozeCount': PropertySchema(
      id: 9,
      name: r'snoozeCount',
      type: IsarType.long,
    ),
    r'snoozedUntilMs': PropertySchema(
      id: 10,
      name: r'snoozedUntilMs',
      type: IsarType.long,
    ),
    r'sourceContext': PropertySchema(
      id: 11,
      name: r'sourceContext',
      type: IsarType.string,
    ),
    r'state': PropertySchema(id: 12, name: r'state', type: IsarType.string),
    r'updatedAtMs': PropertySchema(
      id: 13,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarNotificationLedgerEntryEstimateSize,
  serialize: _isarNotificationLedgerEntrySerialize,
  deserialize: _isarNotificationLedgerEntryDeserialize,
  deserializeProp: _isarNotificationLedgerEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'notifId': IndexSchema(
      id: 3816694177820424078,
      name: r'notifId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'notifId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'entityId': IndexSchema(
      id: 745355021660786263,
      name: r'entityId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entityId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'state': IndexSchema(
      id: 7917036384617311412,
      name: r'state',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'state',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'scheduledForMs': IndexSchema(
      id: -1512195739800297874,
      name: r'scheduledForMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'scheduledForMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'updatedAtMs': IndexSchema(
      id: 2203618382568911480,
      name: r'updatedAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAtMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarNotificationLedgerEntryGetId,
  getLinks: _isarNotificationLedgerEntryGetLinks,
  attach: _isarNotificationLedgerEntryAttach,
  version: '3.3.2',
);

int _isarNotificationLedgerEntryEstimateSize(
  IsarNotificationLedgerEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.entityId.length * 3;
  bytesCount += 3 + object.entityKind.length * 3;
  {
    final value = object.interactionType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sourceContext.length * 3;
  bytesCount += 3 + object.state.length * 3;
  return bytesCount;
}

void _isarNotificationLedgerEntrySerialize(
  IsarNotificationLedgerEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.cancelledAtMs);
  writer.writeLong(offsets[1], object.deliveredAtMs);
  writer.writeString(offsets[2], object.entityId);
  writer.writeString(offsets[3], object.entityKind);
  writer.writeLong(offsets[4], object.ignoredCount);
  writer.writeLong(offsets[5], object.interactedAtMs);
  writer.writeString(offsets[6], object.interactionType);
  writer.writeLong(offsets[7], object.notifId);
  writer.writeLong(offsets[8], object.scheduledForMs);
  writer.writeLong(offsets[9], object.snoozeCount);
  writer.writeLong(offsets[10], object.snoozedUntilMs);
  writer.writeString(offsets[11], object.sourceContext);
  writer.writeString(offsets[12], object.state);
  writer.writeLong(offsets[13], object.updatedAtMs);
}

IsarNotificationLedgerEntry _isarNotificationLedgerEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarNotificationLedgerEntry();
  object.cancelledAtMs = reader.readLongOrNull(offsets[0]);
  object.deliveredAtMs = reader.readLongOrNull(offsets[1]);
  object.entityId = reader.readString(offsets[2]);
  object.entityKind = reader.readString(offsets[3]);
  object.id = id;
  object.ignoredCount = reader.readLong(offsets[4]);
  object.interactedAtMs = reader.readLongOrNull(offsets[5]);
  object.interactionType = reader.readStringOrNull(offsets[6]);
  object.notifId = reader.readLong(offsets[7]);
  object.scheduledForMs = reader.readLongOrNull(offsets[8]);
  object.snoozeCount = reader.readLong(offsets[9]);
  object.snoozedUntilMs = reader.readLongOrNull(offsets[10]);
  object.sourceContext = reader.readString(offsets[11]);
  object.state = reader.readString(offsets[12]);
  object.updatedAtMs = reader.readLong(offsets[13]);
  return object;
}

P _isarNotificationLedgerEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarNotificationLedgerEntryGetId(IsarNotificationLedgerEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarNotificationLedgerEntryGetLinks(
  IsarNotificationLedgerEntry object,
) {
  return [];
}

void _isarNotificationLedgerEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarNotificationLedgerEntry object,
) {
  object.id = id;
}

extension IsarNotificationLedgerEntryByIndex
    on IsarCollection<IsarNotificationLedgerEntry> {
  Future<IsarNotificationLedgerEntry?> getByNotifId(int notifId) {
    return getByIndex(r'notifId', [notifId]);
  }

  IsarNotificationLedgerEntry? getByNotifIdSync(int notifId) {
    return getByIndexSync(r'notifId', [notifId]);
  }

  Future<bool> deleteByNotifId(int notifId) {
    return deleteByIndex(r'notifId', [notifId]);
  }

  bool deleteByNotifIdSync(int notifId) {
    return deleteByIndexSync(r'notifId', [notifId]);
  }

  Future<List<IsarNotificationLedgerEntry?>> getAllByNotifId(
    List<int> notifIdValues,
  ) {
    final values = notifIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'notifId', values);
  }

  List<IsarNotificationLedgerEntry?> getAllByNotifIdSync(
    List<int> notifIdValues,
  ) {
    final values = notifIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'notifId', values);
  }

  Future<int> deleteAllByNotifId(List<int> notifIdValues) {
    final values = notifIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'notifId', values);
  }

  int deleteAllByNotifIdSync(List<int> notifIdValues) {
    final values = notifIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'notifId', values);
  }

  Future<Id> putByNotifId(IsarNotificationLedgerEntry object) {
    return putByIndex(r'notifId', object);
  }

  Id putByNotifIdSync(
    IsarNotificationLedgerEntry object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'notifId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNotifId(List<IsarNotificationLedgerEntry> objects) {
    return putAllByIndex(r'notifId', objects);
  }

  List<Id> putAllByNotifIdSync(
    List<IsarNotificationLedgerEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'notifId', objects, saveLinks: saveLinks);
  }
}

extension IsarNotificationLedgerEntryQueryWhereSort
    on
        QueryBuilder<
          IsarNotificationLedgerEntry,
          IsarNotificationLedgerEntry,
          QWhere
        > {
  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhere
  >
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhere
  >
  anyNotifId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'notifId'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhere
  >
  anyScheduledForMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'scheduledForMs'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhere
  >
  anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarNotificationLedgerEntryQueryWhere
    on
        QueryBuilder<
          IsarNotificationLedgerEntry,
          IsarNotificationLedgerEntry,
          QWhereClause
        > {
  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  notifIdEqualTo(int notifId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'notifId', value: [notifId]),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  notifIdNotEqualTo(int notifId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'notifId',
                lower: [],
                upper: [notifId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'notifId',
                lower: [notifId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'notifId',
                lower: [notifId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'notifId',
                lower: [],
                upper: [notifId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  notifIdGreaterThan(int notifId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'notifId',
          lower: [notifId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  notifIdLessThan(int notifId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'notifId',
          lower: [],
          upper: [notifId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  notifIdBetween(
    int lowerNotifId,
    int upperNotifId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'notifId',
          lower: [lowerNotifId],
          includeLower: includeLower,
          upper: [upperNotifId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  entityIdEqualTo(String entityId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entityId', value: [entityId]),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  entityIdNotEqualTo(String entityId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [],
                upper: [entityId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [entityId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [entityId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [],
                upper: [entityId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  stateEqualTo(String state) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'state', value: [state]),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  stateNotEqualTo(String state) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'state',
                lower: [],
                upper: [state],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'state',
                lower: [state],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'state',
                lower: [state],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'state',
                lower: [],
                upper: [state],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  scheduledForMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'scheduledForMs', value: [null]),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  scheduledForMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'scheduledForMs',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  scheduledForMsEqualTo(int? scheduledForMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'scheduledForMs',
          value: [scheduledForMs],
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  scheduledForMsNotEqualTo(int? scheduledForMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scheduledForMs',
                lower: [],
                upper: [scheduledForMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scheduledForMs',
                lower: [scheduledForMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scheduledForMs',
                lower: [scheduledForMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scheduledForMs',
                lower: [],
                upper: [scheduledForMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  scheduledForMsGreaterThan(int? scheduledForMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'scheduledForMs',
          lower: [scheduledForMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  scheduledForMsLessThan(int? scheduledForMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'scheduledForMs',
          lower: [],
          upper: [scheduledForMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  scheduledForMsBetween(
    int? lowerScheduledForMs,
    int? upperScheduledForMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'scheduledForMs',
          lower: [lowerScheduledForMs],
          includeLower: includeLower,
          upper: [upperScheduledForMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  updatedAtMsEqualTo(int updatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'updatedAtMs',
          value: [updatedAtMs],
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  updatedAtMsNotEqualTo(int updatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAtMs',
                lower: [],
                upper: [updatedAtMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAtMs',
                lower: [updatedAtMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAtMs',
                lower: [updatedAtMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAtMs',
                lower: [],
                upper: [updatedAtMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  updatedAtMsGreaterThan(int updatedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAtMs',
          lower: [updatedAtMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  updatedAtMsLessThan(int updatedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAtMs',
          lower: [],
          upper: [updatedAtMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterWhereClause
  >
  updatedAtMsBetween(
    int lowerUpdatedAtMs,
    int upperUpdatedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAtMs',
          lower: [lowerUpdatedAtMs],
          includeLower: includeLower,
          upper: [upperUpdatedAtMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarNotificationLedgerEntryQueryFilter
    on
        QueryBuilder<
          IsarNotificationLedgerEntry,
          IsarNotificationLedgerEntry,
          QFilterCondition
        > {
  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  cancelledAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'cancelledAtMs'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  cancelledAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'cancelledAtMs'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  cancelledAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cancelledAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  cancelledAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cancelledAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  cancelledAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cancelledAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  cancelledAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cancelledAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  deliveredAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'deliveredAtMs'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  deliveredAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'deliveredAtMs'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  deliveredAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deliveredAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  deliveredAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deliveredAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  deliveredAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deliveredAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  deliveredAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deliveredAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entityId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entityId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityKindEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entityKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityKindGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityKindLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityKindBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityKind',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityKindStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entityKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityKindEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entityKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityKindContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entityKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityKindMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entityKind',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityKindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityKind', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  entityKindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entityKind', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  ignoredCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ignoredCount', value: value),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  ignoredCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ignoredCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  ignoredCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ignoredCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  ignoredCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ignoredCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactedAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'interactedAtMs'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactedAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'interactedAtMs'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactedAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'interactedAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactedAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'interactedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactedAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'interactedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactedAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'interactedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'interactionType'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'interactionType'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'interactionType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'interactionType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'interactionType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'interactionType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'interactionType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'interactionType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'interactionType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'interactionType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'interactionType', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  interactionTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'interactionType', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  notifIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notifId', value: value),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  notifIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notifId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  notifIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notifId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  notifIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notifId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  scheduledForMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'scheduledForMs'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  scheduledForMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'scheduledForMs'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  scheduledForMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'scheduledForMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  scheduledForMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'scheduledForMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  scheduledForMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'scheduledForMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  scheduledForMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'scheduledForMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  snoozeCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'snoozeCount', value: value),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  snoozeCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'snoozeCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  snoozeCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'snoozeCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  snoozeCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'snoozeCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  snoozedUntilMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'snoozedUntilMs'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  snoozedUntilMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'snoozedUntilMs'),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  snoozedUntilMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'snoozedUntilMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  snoozedUntilMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'snoozedUntilMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  snoozedUntilMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'snoozedUntilMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  snoozedUntilMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'snoozedUntilMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  sourceContextEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceContext',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  sourceContextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceContext',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  sourceContextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceContext',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  sourceContextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceContext',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  sourceContextStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceContext',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  sourceContextEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceContext',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  sourceContextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceContext',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  sourceContextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceContext',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  sourceContextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceContext', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  sourceContextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceContext', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  stateEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  stateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  stateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  stateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'state',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  stateStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  stateEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  stateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'state',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  stateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'state',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  stateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'state', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  stateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'state', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  updatedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  updatedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterFilterCondition
  >
  updatedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarNotificationLedgerEntryQueryObject
    on
        QueryBuilder<
          IsarNotificationLedgerEntry,
          IsarNotificationLedgerEntry,
          QFilterCondition
        > {}

extension IsarNotificationLedgerEntryQueryLinks
    on
        QueryBuilder<
          IsarNotificationLedgerEntry,
          IsarNotificationLedgerEntry,
          QFilterCondition
        > {}

extension IsarNotificationLedgerEntryQuerySortBy
    on
        QueryBuilder<
          IsarNotificationLedgerEntry,
          IsarNotificationLedgerEntry,
          QSortBy
        > {
  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByCancelledAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledAtMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByCancelledAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledAtMs', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByDeliveredAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAtMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByDeliveredAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAtMs', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByEntityKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByEntityKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByIgnoredCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredCount', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByIgnoredCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredCount', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByInteractedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactedAtMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByInteractedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactedAtMs', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByInteractionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactionType', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByInteractionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactionType', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByNotifId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifId', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByNotifIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifId', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByScheduledForMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledForMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByScheduledForMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledForMs', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortBySnoozeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozeCount', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortBySnoozeCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozeCount', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortBySnoozedUntilMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozedUntilMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortBySnoozedUntilMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozedUntilMs', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortBySourceContext() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceContext', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortBySourceContextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceContext', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarNotificationLedgerEntryQuerySortThenBy
    on
        QueryBuilder<
          IsarNotificationLedgerEntry,
          IsarNotificationLedgerEntry,
          QSortThenBy
        > {
  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByCancelledAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledAtMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByCancelledAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelledAtMs', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByDeliveredAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAtMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByDeliveredAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAtMs', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByEntityKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByEntityKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByIgnoredCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredCount', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByIgnoredCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredCount', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByInteractedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactedAtMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByInteractedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactedAtMs', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByInteractionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactionType', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByInteractionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interactionType', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByNotifId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifId', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByNotifIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifId', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByScheduledForMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledForMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByScheduledForMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledForMs', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenBySnoozeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozeCount', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenBySnoozeCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozeCount', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenBySnoozedUntilMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozedUntilMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenBySnoozedUntilMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozedUntilMs', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenBySourceContext() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceContext', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenBySourceContextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceContext', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QAfterSortBy
  >
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarNotificationLedgerEntryQueryWhereDistinct
    on
        QueryBuilder<
          IsarNotificationLedgerEntry,
          IsarNotificationLedgerEntry,
          QDistinct
        > {
  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctByCancelledAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cancelledAtMs');
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctByDeliveredAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deliveredAtMs');
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctByEntityId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctByEntityKind({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityKind', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctByIgnoredCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ignoredCount');
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctByInteractedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'interactedAtMs');
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctByInteractionType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'interactionType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctByNotifId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notifId');
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctByScheduledForMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledForMs');
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctBySnoozeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'snoozeCount');
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctBySnoozedUntilMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'snoozedUntilMs');
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctBySourceContext({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceContext',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctByState({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'state', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    IsarNotificationLedgerEntry,
    IsarNotificationLedgerEntry,
    QDistinct
  >
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarNotificationLedgerEntryQueryProperty
    on
        QueryBuilder<
          IsarNotificationLedgerEntry,
          IsarNotificationLedgerEntry,
          QQueryProperty
        > {
  QueryBuilder<IsarNotificationLedgerEntry, int, QQueryOperations>
  idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, int?, QQueryOperations>
  cancelledAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cancelledAtMs');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, int?, QQueryOperations>
  deliveredAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deliveredAtMs');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, String, QQueryOperations>
  entityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityId');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, String, QQueryOperations>
  entityKindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityKind');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, int, QQueryOperations>
  ignoredCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ignoredCount');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, int?, QQueryOperations>
  interactedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'interactedAtMs');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, String?, QQueryOperations>
  interactionTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'interactionType');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, int, QQueryOperations>
  notifIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notifId');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, int?, QQueryOperations>
  scheduledForMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledForMs');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, int, QQueryOperations>
  snoozeCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snoozeCount');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, int?, QQueryOperations>
  snoozedUntilMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snoozedUntilMs');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, String, QQueryOperations>
  sourceContextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceContext');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, String, QQueryOperations>
  stateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'state');
    });
  }

  QueryBuilder<IsarNotificationLedgerEntry, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
