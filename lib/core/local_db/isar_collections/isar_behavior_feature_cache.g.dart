// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_behavior_feature_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarBehaviorFeatureCacheCollection on Isar {
  IsarCollection<IsarBehaviorFeatureCache> get isarBehaviorFeatureCaches =>
      this.collection();
}

const IsarBehaviorFeatureCacheSchema = CollectionSchema(
  name: r'IsarBehaviorFeatureCache',
  id: 8410238928793649792,
  properties: {
    r'createdAtMs': PropertySchema(
      id: 0,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'entityId': PropertySchema(
      id: 1,
      name: r'entityId',
      type: IsarType.string,
    ),
    r'entityKind': PropertySchema(
      id: 2,
      name: r'entityKind',
      type: IsarType.string,
    ),
    r'payloadJson': PropertySchema(
      id: 3,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 4,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'updatedAtMs': PropertySchema(
      id: 5,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
    r'windowEndDateKey': PropertySchema(
      id: 6,
      name: r'windowEndDateKey',
      type: IsarType.string,
    ),
    r'windowStartDateKey': PropertySchema(
      id: 7,
      name: r'windowStartDateKey',
      type: IsarType.string,
    ),
  },
  estimateSize: _isarBehaviorFeatureCacheEstimateSize,
  serialize: _isarBehaviorFeatureCacheSerialize,
  deserialize: _isarBehaviorFeatureCacheDeserialize,
  deserializeProp: _isarBehaviorFeatureCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r'entityId': IndexSchema(
      id: 745355021660786263,
      name: r'entityId',
      unique: true,
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
  getId: _isarBehaviorFeatureCacheGetId,
  getLinks: _isarBehaviorFeatureCacheGetLinks,
  attach: _isarBehaviorFeatureCacheAttach,
  version: '3.1.0+1',
);

int _isarBehaviorFeatureCacheEstimateSize(
  IsarBehaviorFeatureCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.entityId.length * 3;
  bytesCount += 3 + object.entityKind.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  {
    final value = object.windowEndDateKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.windowStartDateKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarBehaviorFeatureCacheSerialize(
  IsarBehaviorFeatureCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.createdAtMs);
  writer.writeString(offsets[1], object.entityId);
  writer.writeString(offsets[2], object.entityKind);
  writer.writeString(offsets[3], object.payloadJson);
  writer.writeLong(offsets[4], object.schemaVersion);
  writer.writeLong(offsets[5], object.updatedAtMs);
  writer.writeString(offsets[6], object.windowEndDateKey);
  writer.writeString(offsets[7], object.windowStartDateKey);
}

IsarBehaviorFeatureCache _isarBehaviorFeatureCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarBehaviorFeatureCache();
  object.createdAtMs = reader.readLong(offsets[0]);
  object.entityId = reader.readString(offsets[1]);
  object.entityKind = reader.readString(offsets[2]);
  object.id = id;
  object.payloadJson = reader.readString(offsets[3]);
  object.schemaVersion = reader.readLong(offsets[4]);
  object.updatedAtMs = reader.readLong(offsets[5]);
  object.windowEndDateKey = reader.readStringOrNull(offsets[6]);
  object.windowStartDateKey = reader.readStringOrNull(offsets[7]);
  return object;
}

P _isarBehaviorFeatureCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarBehaviorFeatureCacheGetId(IsarBehaviorFeatureCache object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarBehaviorFeatureCacheGetLinks(
  IsarBehaviorFeatureCache object,
) {
  return [];
}

void _isarBehaviorFeatureCacheAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarBehaviorFeatureCache object,
) {
  object.id = id;
}

extension IsarBehaviorFeatureCacheByIndex
    on IsarCollection<IsarBehaviorFeatureCache> {
  Future<IsarBehaviorFeatureCache?> getByEntityId(String entityId) {
    return getByIndex(r'entityId', [entityId]);
  }

  IsarBehaviorFeatureCache? getByEntityIdSync(String entityId) {
    return getByIndexSync(r'entityId', [entityId]);
  }

  Future<bool> deleteByEntityId(String entityId) {
    return deleteByIndex(r'entityId', [entityId]);
  }

  bool deleteByEntityIdSync(String entityId) {
    return deleteByIndexSync(r'entityId', [entityId]);
  }

  Future<List<IsarBehaviorFeatureCache?>> getAllByEntityId(
    List<String> entityIdValues,
  ) {
    final values = entityIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'entityId', values);
  }

  List<IsarBehaviorFeatureCache?> getAllByEntityIdSync(
    List<String> entityIdValues,
  ) {
    final values = entityIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'entityId', values);
  }

  Future<int> deleteAllByEntityId(List<String> entityIdValues) {
    final values = entityIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'entityId', values);
  }

  int deleteAllByEntityIdSync(List<String> entityIdValues) {
    final values = entityIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'entityId', values);
  }

  Future<Id> putByEntityId(IsarBehaviorFeatureCache object) {
    return putByIndex(r'entityId', object);
  }

  Id putByEntityIdSync(
    IsarBehaviorFeatureCache object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'entityId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEntityId(List<IsarBehaviorFeatureCache> objects) {
    return putAllByIndex(r'entityId', objects);
  }

  List<Id> putAllByEntityIdSync(
    List<IsarBehaviorFeatureCache> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'entityId', objects, saveLinks: saveLinks);
  }
}

extension IsarBehaviorFeatureCacheQueryWhereSort
    on
        QueryBuilder<
          IsarBehaviorFeatureCache,
          IsarBehaviorFeatureCache,
          QWhere
        > {
  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterWhere>
  anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarBehaviorFeatureCacheQueryWhere
    on
        QueryBuilder<
          IsarBehaviorFeatureCache,
          IsarBehaviorFeatureCache,
          QWhereClause
        > {
  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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

extension IsarBehaviorFeatureCacheQueryFilter
    on
        QueryBuilder<
          IsarBehaviorFeatureCache,
          IsarBehaviorFeatureCache,
          QFilterCondition
        > {
  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  payloadJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  payloadJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  payloadJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  payloadJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'payloadJson',
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  payloadJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  payloadJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'payloadJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schemaVersion', value: value),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  schemaVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  schemaVersionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'schemaVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  schemaVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'schemaVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'windowEndDateKey'),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'windowEndDateKey'),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'windowEndDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'windowEndDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'windowEndDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'windowEndDateKey',
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'windowEndDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'windowEndDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'windowEndDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'windowEndDateKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'windowEndDateKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowEndDateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'windowEndDateKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'windowStartDateKey'),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'windowStartDateKey'),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'windowStartDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'windowStartDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'windowStartDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'windowStartDateKey',
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
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'windowStartDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'windowStartDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'windowStartDateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'windowStartDateKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'windowStartDateKey', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarBehaviorFeatureCache,
    IsarBehaviorFeatureCache,
    QAfterFilterCondition
  >
  windowStartDateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'windowStartDateKey', value: ''),
      );
    });
  }
}

extension IsarBehaviorFeatureCacheQueryObject
    on
        QueryBuilder<
          IsarBehaviorFeatureCache,
          IsarBehaviorFeatureCache,
          QFilterCondition
        > {}

extension IsarBehaviorFeatureCacheQueryLinks
    on
        QueryBuilder<
          IsarBehaviorFeatureCache,
          IsarBehaviorFeatureCache,
          QFilterCondition
        > {}

extension IsarBehaviorFeatureCacheQuerySortBy
    on
        QueryBuilder<
          IsarBehaviorFeatureCache,
          IsarBehaviorFeatureCache,
          QSortBy
        > {
  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByEntityKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByEntityKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByWindowEndDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEndDateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByWindowEndDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEndDateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByWindowStartDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowStartDateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  sortByWindowStartDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowStartDateKey', Sort.desc);
    });
  }
}

extension IsarBehaviorFeatureCacheQuerySortThenBy
    on
        QueryBuilder<
          IsarBehaviorFeatureCache,
          IsarBehaviorFeatureCache,
          QSortThenBy
        > {
  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByEntityKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByEntityKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByWindowEndDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEndDateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByWindowEndDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEndDateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByWindowStartDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowStartDateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QAfterSortBy>
  thenByWindowStartDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowStartDateKey', Sort.desc);
    });
  }
}

extension IsarBehaviorFeatureCacheQueryWhereDistinct
    on
        QueryBuilder<
          IsarBehaviorFeatureCache,
          IsarBehaviorFeatureCache,
          QDistinct
        > {
  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QDistinct>
  distinctByEntityId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QDistinct>
  distinctByEntityKind({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityKind', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QDistinct>
  distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QDistinct>
  distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QDistinct>
  distinctByWindowEndDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'windowEndDateKey',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, IsarBehaviorFeatureCache, QDistinct>
  distinctByWindowStartDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'windowStartDateKey',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension IsarBehaviorFeatureCacheQueryProperty
    on
        QueryBuilder<
          IsarBehaviorFeatureCache,
          IsarBehaviorFeatureCache,
          QQueryProperty
        > {
  QueryBuilder<IsarBehaviorFeatureCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, int, QQueryOperations>
  createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, String, QQueryOperations>
  entityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityId');
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, String, QQueryOperations>
  entityKindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityKind');
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, String, QQueryOperations>
  payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, int, QQueryOperations>
  schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, String?, QQueryOperations>
  windowEndDateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'windowEndDateKey');
    });
  }

  QueryBuilder<IsarBehaviorFeatureCache, String?, QQueryOperations>
  windowStartDateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'windowStartDateKey');
    });
  }
}
