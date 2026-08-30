// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_reminder_occurrence.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarReminderOccurrenceCollection on Isar {
  IsarCollection<IsarReminderOccurrence> get isarReminderOccurrences =>
      this.collection();
}

const IsarReminderOccurrenceSchema = CollectionSchema(
  name: r'IsarReminderOccurrence',
  id: -2710081797454308221,
  properties: {
    r'classificationSource': PropertySchema(
      id: 0,
      name: r'classificationSource',
      type: IsarType.string,
    ),
    r'classifierVersion': PropertySchema(
      id: 1,
      name: r'classifierVersion',
      type: IsarType.long,
    ),
    r'createdAtMs': PropertySchema(
      id: 2,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'criticality': PropertySchema(
      id: 3,
      name: r'criticality',
      type: IsarType.long,
    ),
    r'dateKey': PropertySchema(id: 4, name: r'dateKey', type: IsarType.string),
    r'dismissedForDayKey': PropertySchema(
      id: 5,
      name: r'dismissedForDayKey',
      type: IsarType.string,
    ),
    r'entityId': PropertySchema(
      id: 6,
      name: r'entityId',
      type: IsarType.string,
    ),
    r'entityKind': PropertySchema(
      id: 7,
      name: r'entityKind',
      type: IsarType.string,
    ),
    r'entityTitle': PropertySchema(
      id: 8,
      name: r'entityTitle',
      type: IsarType.string,
    ),
    r'ladderPosition': PropertySchema(
      id: 9,
      name: r'ladderPosition',
      type: IsarType.long,
    ),
    r'modeRefId': PropertySchema(
      id: 10,
      name: r'modeRefId',
      type: IsarType.string,
    ),
    r'occurrenceId': PropertySchema(
      id: 11,
      name: r'occurrenceId',
      type: IsarType.string,
    ),
    r'occurrenceKey': PropertySchema(
      id: 12,
      name: r'occurrenceKey',
      type: IsarType.string,
    ),
    r'overdueSinceMs': PropertySchema(
      id: 13,
      name: r'overdueSinceMs',
      type: IsarType.long,
    ),
    r'resolutionKind': PropertySchema(
      id: 14,
      name: r'resolutionKind',
      type: IsarType.string,
    ),
    r'resolutionReason': PropertySchema(
      id: 15,
      name: r'resolutionReason',
      type: IsarType.string,
    ),
    r'resolvedAtMs': PropertySchema(
      id: 16,
      name: r'resolvedAtMs',
      type: IsarType.long,
    ),
    r'scheduledAtMs': PropertySchema(
      id: 17,
      name: r'scheduledAtMs',
      type: IsarType.long,
    ),
    r'snoozedUntilMs': PropertySchema(
      id: 18,
      name: r'snoozedUntilMs',
      type: IsarType.long,
    ),
    r'state': PropertySchema(id: 19, name: r'state', type: IsarType.string),
    r'taxonomy': PropertySchema(
      id: 20,
      name: r'taxonomy',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 21,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
    r'windowMinutes': PropertySchema(
      id: 22,
      name: r'windowMinutes',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarReminderOccurrenceEstimateSize,
  serialize: _isarReminderOccurrenceSerialize,
  deserialize: _isarReminderOccurrenceDeserialize,
  deserializeProp: _isarReminderOccurrenceDeserializeProp,
  idName: r'id',
  indexes: {
    r'occurrenceId': IndexSchema(
      id: 339117606871090824,
      name: r'occurrenceId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'occurrenceId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'occurrenceKey': IndexSchema(
      id: 1905454298359628696,
      name: r'occurrenceKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'occurrenceKey',
          type: IndexType.hash,
          caseSensitive: true,
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
    r'entityKind': IndexSchema(
      id: -3674236605151107096,
      name: r'entityKind',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entityKind',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'scheduledAtMs': IndexSchema(
      id: -8063057316894381820,
      name: r'scheduledAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'scheduledAtMs',
          type: IndexType.value,
          caseSensitive: false,
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

  getId: _isarReminderOccurrenceGetId,
  getLinks: _isarReminderOccurrenceGetLinks,
  attach: _isarReminderOccurrenceAttach,
  version: '3.3.2',
);

int _isarReminderOccurrenceEstimateSize(
  IsarReminderOccurrence object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.classificationSource.length * 3;
  bytesCount += 3 + object.dateKey.length * 3;
  {
    final value = object.dismissedForDayKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.entityId.length * 3;
  bytesCount += 3 + object.entityKind.length * 3;
  {
    final value = object.entityTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.modeRefId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.occurrenceId.length * 3;
  bytesCount += 3 + object.occurrenceKey.length * 3;
  {
    final value = object.resolutionKind;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.resolutionReason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.state.length * 3;
  bytesCount += 3 + object.taxonomy.length * 3;
  return bytesCount;
}

void _isarReminderOccurrenceSerialize(
  IsarReminderOccurrence object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.classificationSource);
  writer.writeLong(offsets[1], object.classifierVersion);
  writer.writeLong(offsets[2], object.createdAtMs);
  writer.writeLong(offsets[3], object.criticality);
  writer.writeString(offsets[4], object.dateKey);
  writer.writeString(offsets[5], object.dismissedForDayKey);
  writer.writeString(offsets[6], object.entityId);
  writer.writeString(offsets[7], object.entityKind);
  writer.writeString(offsets[8], object.entityTitle);
  writer.writeLong(offsets[9], object.ladderPosition);
  writer.writeString(offsets[10], object.modeRefId);
  writer.writeString(offsets[11], object.occurrenceId);
  writer.writeString(offsets[12], object.occurrenceKey);
  writer.writeLong(offsets[13], object.overdueSinceMs);
  writer.writeString(offsets[14], object.resolutionKind);
  writer.writeString(offsets[15], object.resolutionReason);
  writer.writeLong(offsets[16], object.resolvedAtMs);
  writer.writeLong(offsets[17], object.scheduledAtMs);
  writer.writeLong(offsets[18], object.snoozedUntilMs);
  writer.writeString(offsets[19], object.state);
  writer.writeString(offsets[20], object.taxonomy);
  writer.writeLong(offsets[21], object.updatedAtMs);
  writer.writeLong(offsets[22], object.windowMinutes);
}

IsarReminderOccurrence _isarReminderOccurrenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarReminderOccurrence();
  object.classificationSource = reader.readString(offsets[0]);
  object.classifierVersion = reader.readLongOrNull(offsets[1]);
  object.createdAtMs = reader.readLong(offsets[2]);
  object.criticality = reader.readLong(offsets[3]);
  object.dateKey = reader.readString(offsets[4]);
  object.dismissedForDayKey = reader.readStringOrNull(offsets[5]);
  object.entityId = reader.readString(offsets[6]);
  object.entityKind = reader.readString(offsets[7]);
  object.entityTitle = reader.readStringOrNull(offsets[8]);
  object.id = id;
  object.ladderPosition = reader.readLong(offsets[9]);
  object.modeRefId = reader.readStringOrNull(offsets[10]);
  object.occurrenceId = reader.readString(offsets[11]);
  object.occurrenceKey = reader.readString(offsets[12]);
  object.overdueSinceMs = reader.readLongOrNull(offsets[13]);
  object.resolutionKind = reader.readStringOrNull(offsets[14]);
  object.resolutionReason = reader.readStringOrNull(offsets[15]);
  object.resolvedAtMs = reader.readLongOrNull(offsets[16]);
  object.scheduledAtMs = reader.readLong(offsets[17]);
  object.snoozedUntilMs = reader.readLongOrNull(offsets[18]);
  object.state = reader.readString(offsets[19]);
  object.taxonomy = reader.readString(offsets[20]);
  object.updatedAtMs = reader.readLong(offsets[21]);
  object.windowMinutes = reader.readLong(offsets[22]);
  return object;
}

P _isarReminderOccurrenceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readLongOrNull(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readLongOrNull(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    case 21:
      return (reader.readLong(offset)) as P;
    case 22:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarReminderOccurrenceGetId(IsarReminderOccurrence object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarReminderOccurrenceGetLinks(
  IsarReminderOccurrence object,
) {
  return [];
}

void _isarReminderOccurrenceAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarReminderOccurrence object,
) {
  object.id = id;
}

extension IsarReminderOccurrenceByIndex
    on IsarCollection<IsarReminderOccurrence> {
  Future<IsarReminderOccurrence?> getByOccurrenceId(String occurrenceId) {
    return getByIndex(r'occurrenceId', [occurrenceId]);
  }

  IsarReminderOccurrence? getByOccurrenceIdSync(String occurrenceId) {
    return getByIndexSync(r'occurrenceId', [occurrenceId]);
  }

  Future<bool> deleteByOccurrenceId(String occurrenceId) {
    return deleteByIndex(r'occurrenceId', [occurrenceId]);
  }

  bool deleteByOccurrenceIdSync(String occurrenceId) {
    return deleteByIndexSync(r'occurrenceId', [occurrenceId]);
  }

  Future<List<IsarReminderOccurrence?>> getAllByOccurrenceId(
    List<String> occurrenceIdValues,
  ) {
    final values = occurrenceIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'occurrenceId', values);
  }

  List<IsarReminderOccurrence?> getAllByOccurrenceIdSync(
    List<String> occurrenceIdValues,
  ) {
    final values = occurrenceIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'occurrenceId', values);
  }

  Future<int> deleteAllByOccurrenceId(List<String> occurrenceIdValues) {
    final values = occurrenceIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'occurrenceId', values);
  }

  int deleteAllByOccurrenceIdSync(List<String> occurrenceIdValues) {
    final values = occurrenceIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'occurrenceId', values);
  }

  Future<Id> putByOccurrenceId(IsarReminderOccurrence object) {
    return putByIndex(r'occurrenceId', object);
  }

  Id putByOccurrenceIdSync(
    IsarReminderOccurrence object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'occurrenceId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOccurrenceId(List<IsarReminderOccurrence> objects) {
    return putAllByIndex(r'occurrenceId', objects);
  }

  List<Id> putAllByOccurrenceIdSync(
    List<IsarReminderOccurrence> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'occurrenceId', objects, saveLinks: saveLinks);
  }

  Future<IsarReminderOccurrence?> getByOccurrenceKey(String occurrenceKey) {
    return getByIndex(r'occurrenceKey', [occurrenceKey]);
  }

  IsarReminderOccurrence? getByOccurrenceKeySync(String occurrenceKey) {
    return getByIndexSync(r'occurrenceKey', [occurrenceKey]);
  }

  Future<bool> deleteByOccurrenceKey(String occurrenceKey) {
    return deleteByIndex(r'occurrenceKey', [occurrenceKey]);
  }

  bool deleteByOccurrenceKeySync(String occurrenceKey) {
    return deleteByIndexSync(r'occurrenceKey', [occurrenceKey]);
  }

  Future<List<IsarReminderOccurrence?>> getAllByOccurrenceKey(
    List<String> occurrenceKeyValues,
  ) {
    final values = occurrenceKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'occurrenceKey', values);
  }

  List<IsarReminderOccurrence?> getAllByOccurrenceKeySync(
    List<String> occurrenceKeyValues,
  ) {
    final values = occurrenceKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'occurrenceKey', values);
  }

  Future<int> deleteAllByOccurrenceKey(List<String> occurrenceKeyValues) {
    final values = occurrenceKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'occurrenceKey', values);
  }

  int deleteAllByOccurrenceKeySync(List<String> occurrenceKeyValues) {
    final values = occurrenceKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'occurrenceKey', values);
  }

  Future<Id> putByOccurrenceKey(IsarReminderOccurrence object) {
    return putByIndex(r'occurrenceKey', object);
  }

  Id putByOccurrenceKeySync(
    IsarReminderOccurrence object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'occurrenceKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOccurrenceKey(List<IsarReminderOccurrence> objects) {
    return putAllByIndex(r'occurrenceKey', objects);
  }

  List<Id> putAllByOccurrenceKeySync(
    List<IsarReminderOccurrence> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'occurrenceKey', objects, saveLinks: saveLinks);
  }
}

extension IsarReminderOccurrenceQueryWhereSort
    on QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QWhere> {
  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterWhere>
  anyScheduledAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'scheduledAtMs'),
      );
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterWhere>
  anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarReminderOccurrenceQueryWhere
    on
        QueryBuilder<
          IsarReminderOccurrence,
          IsarReminderOccurrence,
          QWhereClause
        > {
  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  occurrenceIdEqualTo(String occurrenceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'occurrenceId',
          value: [occurrenceId],
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  occurrenceIdNotEqualTo(String occurrenceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceId',
                lower: [],
                upper: [occurrenceId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceId',
                lower: [occurrenceId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceId',
                lower: [occurrenceId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceId',
                lower: [],
                upper: [occurrenceId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  occurrenceKeyEqualTo(String occurrenceKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'occurrenceKey',
          value: [occurrenceKey],
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  occurrenceKeyNotEqualTo(String occurrenceKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceKey',
                lower: [],
                upper: [occurrenceKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceKey',
                lower: [occurrenceKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceKey',
                lower: [occurrenceKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurrenceKey',
                lower: [],
                upper: [occurrenceKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  entityKindEqualTo(String entityKind) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entityKind', value: [entityKind]),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  entityKindNotEqualTo(String entityKind) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKind',
                lower: [],
                upper: [entityKind],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKind',
                lower: [entityKind],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKind',
                lower: [entityKind],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKind',
                lower: [],
                upper: [entityKind],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  dateKeyEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dateKey', value: [dateKey]),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  dateKeyNotEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [],
                upper: [dateKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [dateKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [dateKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [],
                upper: [dateKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  scheduledAtMsEqualTo(int scheduledAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'scheduledAtMs',
          value: [scheduledAtMs],
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  scheduledAtMsNotEqualTo(int scheduledAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scheduledAtMs',
                lower: [],
                upper: [scheduledAtMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scheduledAtMs',
                lower: [scheduledAtMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scheduledAtMs',
                lower: [scheduledAtMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scheduledAtMs',
                lower: [],
                upper: [scheduledAtMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  scheduledAtMsGreaterThan(int scheduledAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'scheduledAtMs',
          lower: [scheduledAtMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  scheduledAtMsLessThan(int scheduledAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'scheduledAtMs',
          lower: [],
          upper: [scheduledAtMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterWhereClause
  >
  scheduledAtMsBetween(
    int lowerScheduledAtMs,
    int upperScheduledAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'scheduledAtMs',
          lower: [lowerScheduledAtMs],
          includeLower: includeLower,
          upper: [upperScheduledAtMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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

extension IsarReminderOccurrenceQueryFilter
    on
        QueryBuilder<
          IsarReminderOccurrence,
          IsarReminderOccurrence,
          QFilterCondition
        > {
  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classificationSourceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'classificationSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classificationSourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'classificationSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classificationSourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'classificationSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classificationSourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'classificationSource',
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classificationSourceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'classificationSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classificationSourceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'classificationSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classificationSourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'classificationSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classificationSourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'classificationSource',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classificationSourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'classificationSource', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classificationSourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'classificationSource',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classifierVersionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'classifierVersion'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classifierVersionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'classifierVersion'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classifierVersionEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'classifierVersion', value: value),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classifierVersionGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'classifierVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classifierVersionLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'classifierVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  classifierVersionBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'classifierVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  createdAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  createdAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  createdAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  criticalityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'criticality', value: value),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  criticalityGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'criticality',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  criticalityLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'criticality',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  criticalityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'criticality',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dateKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateKey',
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dateKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dateKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dateKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dateKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'dismissedForDayKey'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'dismissedForDayKey'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dismissedForDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dismissedForDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dismissedForDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dismissedForDayKey',
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dismissedForDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dismissedForDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dismissedForDayKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dismissedForDayKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dismissedForDayKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  dismissedForDayKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dismissedForDayKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'entityTitle'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'entityTitle'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entityTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityTitle',
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entityTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entityTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entityTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entityTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityTitle', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  entityTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entityTitle', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  ladderPositionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ladderPosition', value: value),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  ladderPositionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ladderPosition',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  ladderPositionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ladderPosition',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  ladderPositionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ladderPosition',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'modeRefId'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'modeRefId'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'modeRefId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'modeRefId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'modeRefId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'modeRefId',
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'modeRefId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'modeRefId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'modeRefId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'modeRefId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modeRefId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  modeRefIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'modeRefId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'occurrenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'occurrenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'occurrenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'occurrenceId',
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'occurrenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'occurrenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'occurrenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'occurrenceId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'occurrenceId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'occurrenceId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'occurrenceKey',
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'occurrenceKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'occurrenceKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'occurrenceKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  occurrenceKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'occurrenceKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  overdueSinceMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'overdueSinceMs'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  overdueSinceMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'overdueSinceMs'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  overdueSinceMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'overdueSinceMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  overdueSinceMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'overdueSinceMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  overdueSinceMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'overdueSinceMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  overdueSinceMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'overdueSinceMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'resolutionKind'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'resolutionKind'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'resolutionKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'resolutionKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'resolutionKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'resolutionKind',
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'resolutionKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'resolutionKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'resolutionKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'resolutionKind',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resolutionKind', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionKindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'resolutionKind', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'resolutionReason'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'resolutionReason'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'resolutionReason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'resolutionReason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'resolutionReason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'resolutionReason',
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'resolutionReason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'resolutionReason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'resolutionReason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'resolutionReason',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resolutionReason', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolutionReasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'resolutionReason', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolvedAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'resolvedAtMs'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolvedAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'resolvedAtMs'),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolvedAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resolvedAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolvedAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'resolvedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolvedAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'resolvedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  resolvedAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'resolvedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  scheduledAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'scheduledAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  scheduledAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'scheduledAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  scheduledAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'scheduledAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  scheduledAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'scheduledAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  taxonomyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'taxonomy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  taxonomyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'taxonomy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  taxonomyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'taxonomy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  taxonomyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'taxonomy',
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  taxonomyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'taxonomy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  taxonomyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'taxonomy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  taxonomyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'taxonomy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  taxonomyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'taxonomy',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  taxonomyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'taxonomy', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  taxonomyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'taxonomy', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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
    IsarReminderOccurrence,
    IsarReminderOccurrence,
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

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  windowMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'windowMinutes', value: value),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  windowMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'windowMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  windowMinutesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'windowMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarReminderOccurrence,
    IsarReminderOccurrence,
    QAfterFilterCondition
  >
  windowMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'windowMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarReminderOccurrenceQueryObject
    on
        QueryBuilder<
          IsarReminderOccurrence,
          IsarReminderOccurrence,
          QFilterCondition
        > {}

extension IsarReminderOccurrenceQueryLinks
    on
        QueryBuilder<
          IsarReminderOccurrence,
          IsarReminderOccurrence,
          QFilterCondition
        > {}

extension IsarReminderOccurrenceQuerySortBy
    on QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QSortBy> {
  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByClassificationSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classificationSource', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByClassificationSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classificationSource', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByClassifierVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classifierVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByClassifierVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classifierVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByCriticality() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criticality', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByCriticalityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criticality', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByDismissedForDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dismissedForDayKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByDismissedForDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dismissedForDayKey', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByEntityKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByEntityKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByEntityTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByEntityTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByLadderPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ladderPosition', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByLadderPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ladderPosition', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByModeRefId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByModeRefIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByOccurrenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByOccurrenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByOccurrenceKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByOccurrenceKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByOverdueSinceMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overdueSinceMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByOverdueSinceMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overdueSinceMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByResolutionKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolutionKind', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByResolutionKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolutionKind', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByResolutionReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolutionReason', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByResolutionReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolutionReason', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByResolvedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByResolvedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByScheduledAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByScheduledAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortBySnoozedUntilMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozedUntilMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortBySnoozedUntilMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozedUntilMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByTaxonomy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxonomy', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByTaxonomyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxonomy', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByWindowMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowMinutes', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  sortByWindowMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowMinutes', Sort.desc);
    });
  }
}

extension IsarReminderOccurrenceQuerySortThenBy
    on
        QueryBuilder<
          IsarReminderOccurrence,
          IsarReminderOccurrence,
          QSortThenBy
        > {
  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByClassificationSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classificationSource', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByClassificationSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classificationSource', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByClassifierVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classifierVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByClassifierVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classifierVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByCriticality() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criticality', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByCriticalityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criticality', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByDismissedForDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dismissedForDayKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByDismissedForDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dismissedForDayKey', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByEntityKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByEntityKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByEntityTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByEntityTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByLadderPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ladderPosition', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByLadderPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ladderPosition', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByModeRefId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByModeRefIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByOccurrenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByOccurrenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByOccurrenceKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByOccurrenceKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurrenceKey', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByOverdueSinceMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overdueSinceMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByOverdueSinceMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overdueSinceMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByResolutionKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolutionKind', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByResolutionKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolutionKind', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByResolutionReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolutionReason', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByResolutionReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolutionReason', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByResolvedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByResolvedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByScheduledAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByScheduledAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenBySnoozedUntilMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozedUntilMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenBySnoozedUntilMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozedUntilMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByTaxonomy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxonomy', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByTaxonomyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxonomy', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByWindowMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowMinutes', Sort.asc);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QAfterSortBy>
  thenByWindowMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowMinutes', Sort.desc);
    });
  }
}

extension IsarReminderOccurrenceQueryWhereDistinct
    on QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct> {
  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByClassificationSource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'classificationSource',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByClassifierVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'classifierVersion');
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByCriticality() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'criticality');
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByDismissedForDayKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'dismissedForDayKey',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByEntityId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByEntityKind({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityKind', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByEntityTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByLadderPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ladderPosition');
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByModeRefId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modeRefId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByOccurrenceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'occurrenceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByOccurrenceKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'occurrenceKey',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByOverdueSinceMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'overdueSinceMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByResolutionKind({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'resolutionKind',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByResolutionReason({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'resolutionReason',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByResolvedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resolvedAtMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByScheduledAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledAtMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctBySnoozedUntilMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'snoozedUntilMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByState({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'state', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByTaxonomy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxonomy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, IsarReminderOccurrence, QDistinct>
  distinctByWindowMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'windowMinutes');
    });
  }
}

extension IsarReminderOccurrenceQueryProperty
    on
        QueryBuilder<
          IsarReminderOccurrence,
          IsarReminderOccurrence,
          QQueryProperty
        > {
  QueryBuilder<IsarReminderOccurrence, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String, QQueryOperations>
  classificationSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'classificationSource');
    });
  }

  QueryBuilder<IsarReminderOccurrence, int?, QQueryOperations>
  classifierVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'classifierVersion');
    });
  }

  QueryBuilder<IsarReminderOccurrence, int, QQueryOperations>
  createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, int, QQueryOperations>
  criticalityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'criticality');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String, QQueryOperations>
  dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String?, QQueryOperations>
  dismissedForDayKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dismissedForDayKey');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String, QQueryOperations>
  entityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityId');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String, QQueryOperations>
  entityKindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityKind');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String?, QQueryOperations>
  entityTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityTitle');
    });
  }

  QueryBuilder<IsarReminderOccurrence, int, QQueryOperations>
  ladderPositionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ladderPosition');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String?, QQueryOperations>
  modeRefIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modeRefId');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String, QQueryOperations>
  occurrenceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occurrenceId');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String, QQueryOperations>
  occurrenceKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occurrenceKey');
    });
  }

  QueryBuilder<IsarReminderOccurrence, int?, QQueryOperations>
  overdueSinceMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'overdueSinceMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String?, QQueryOperations>
  resolutionKindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resolutionKind');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String?, QQueryOperations>
  resolutionReasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resolutionReason');
    });
  }

  QueryBuilder<IsarReminderOccurrence, int?, QQueryOperations>
  resolvedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resolvedAtMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, int, QQueryOperations>
  scheduledAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledAtMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, int?, QQueryOperations>
  snoozedUntilMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snoozedUntilMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String, QQueryOperations>
  stateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'state');
    });
  }

  QueryBuilder<IsarReminderOccurrence, String, QQueryOperations>
  taxonomyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxonomy');
    });
  }

  QueryBuilder<IsarReminderOccurrence, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }

  QueryBuilder<IsarReminderOccurrence, int, QQueryOperations>
  windowMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'windowMinutes');
    });
  }
}
