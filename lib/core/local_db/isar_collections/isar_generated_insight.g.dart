// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_generated_insight.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarGeneratedInsightCollection on Isar {
  IsarCollection<IsarGeneratedInsight> get isarGeneratedInsights =>
      this.collection();
}

const IsarGeneratedInsightSchema = CollectionSchema(
  name: r'IsarGeneratedInsight',
  id: -1674630329411026687,
  properties: {
    r'createdAtMs': PropertySchema(
      id: 0,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'insightBucket': PropertySchema(
      id: 1,
      name: r'insightBucket',
      type: IsarType.string,
    ),
    r'insightId': PropertySchema(
      id: 2,
      name: r'insightId',
      type: IsarType.string,
    ),
    r'insightType': PropertySchema(
      id: 3,
      name: r'insightType',
      type: IsarType.string,
    ),
    r'payloadJson': PropertySchema(
      id: 4,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'priority': PropertySchema(
      id: 5,
      name: r'priority',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 6,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'scopeId': PropertySchema(
      id: 7,
      name: r'scopeId',
      type: IsarType.string,
    ),
    r'scopeType': PropertySchema(
      id: 8,
      name: r'scopeType',
      type: IsarType.string,
    ),
    r'sourceWindowEndDateKey': PropertySchema(
      id: 9,
      name: r'sourceWindowEndDateKey',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 10,
      name: r'updatedAtMs',
      type: IsarType.long,
    )
  },
  estimateSize: _isarGeneratedInsightEstimateSize,
  serialize: _isarGeneratedInsightSerialize,
  deserialize: _isarGeneratedInsightDeserialize,
  deserializeProp: _isarGeneratedInsightDeserializeProp,
  idName: r'id',
  indexes: {
    r'insightId': IndexSchema(
      id: 5818887354909674719,
      name: r'insightId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'insightId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'scopeType_scopeId': IndexSchema(
      id: 5174616854289195848,
      name: r'scopeType_scopeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'scopeType',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'scopeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'scopeId': IndexSchema(
      id: 2528183376744017072,
      name: r'scopeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'scopeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'sourceWindowEndDateKey': IndexSchema(
      id: -6342370504464842497,
      name: r'sourceWindowEndDateKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sourceWindowEndDateKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
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
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarGeneratedInsightGetId,
  getLinks: _isarGeneratedInsightGetLinks,
  attach: _isarGeneratedInsightAttach,
  version: '3.1.0+1',
);

int _isarGeneratedInsightEstimateSize(
  IsarGeneratedInsight object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.insightBucket.length * 3;
  bytesCount += 3 + object.insightId.length * 3;
  bytesCount += 3 + object.insightType.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.priority.length * 3;
  bytesCount += 3 + object.scopeId.length * 3;
  bytesCount += 3 + object.scopeType.length * 3;
  bytesCount += 3 + object.sourceWindowEndDateKey.length * 3;
  return bytesCount;
}

void _isarGeneratedInsightSerialize(
  IsarGeneratedInsight object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.createdAtMs);
  writer.writeString(offsets[1], object.insightBucket);
  writer.writeString(offsets[2], object.insightId);
  writer.writeString(offsets[3], object.insightType);
  writer.writeString(offsets[4], object.payloadJson);
  writer.writeString(offsets[5], object.priority);
  writer.writeLong(offsets[6], object.schemaVersion);
  writer.writeString(offsets[7], object.scopeId);
  writer.writeString(offsets[8], object.scopeType);
  writer.writeString(offsets[9], object.sourceWindowEndDateKey);
  writer.writeLong(offsets[10], object.updatedAtMs);
}

IsarGeneratedInsight _isarGeneratedInsightDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarGeneratedInsight();
  object.createdAtMs = reader.readLong(offsets[0]);
  object.id = id;
  object.insightBucket = reader.readString(offsets[1]);
  object.insightId = reader.readString(offsets[2]);
  object.insightType = reader.readString(offsets[3]);
  object.payloadJson = reader.readString(offsets[4]);
  object.priority = reader.readString(offsets[5]);
  object.schemaVersion = reader.readLong(offsets[6]);
  object.scopeId = reader.readString(offsets[7]);
  object.scopeType = reader.readString(offsets[8]);
  object.sourceWindowEndDateKey = reader.readString(offsets[9]);
  object.updatedAtMs = reader.readLong(offsets[10]);
  return object;
}

P _isarGeneratedInsightDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarGeneratedInsightGetId(IsarGeneratedInsight object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarGeneratedInsightGetLinks(
    IsarGeneratedInsight object) {
  return [];
}

void _isarGeneratedInsightAttach(
    IsarCollection<dynamic> col, Id id, IsarGeneratedInsight object) {
  object.id = id;
}

extension IsarGeneratedInsightByIndex on IsarCollection<IsarGeneratedInsight> {
  Future<IsarGeneratedInsight?> getByInsightId(String insightId) {
    return getByIndex(r'insightId', [insightId]);
  }

  IsarGeneratedInsight? getByInsightIdSync(String insightId) {
    return getByIndexSync(r'insightId', [insightId]);
  }

  Future<bool> deleteByInsightId(String insightId) {
    return deleteByIndex(r'insightId', [insightId]);
  }

  bool deleteByInsightIdSync(String insightId) {
    return deleteByIndexSync(r'insightId', [insightId]);
  }

  Future<List<IsarGeneratedInsight?>> getAllByInsightId(
      List<String> insightIdValues) {
    final values = insightIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'insightId', values);
  }

  List<IsarGeneratedInsight?> getAllByInsightIdSync(
      List<String> insightIdValues) {
    final values = insightIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'insightId', values);
  }

  Future<int> deleteAllByInsightId(List<String> insightIdValues) {
    final values = insightIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'insightId', values);
  }

  int deleteAllByInsightIdSync(List<String> insightIdValues) {
    final values = insightIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'insightId', values);
  }

  Future<Id> putByInsightId(IsarGeneratedInsight object) {
    return putByIndex(r'insightId', object);
  }

  Id putByInsightIdSync(IsarGeneratedInsight object, {bool saveLinks = true}) {
    return putByIndexSync(r'insightId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByInsightId(List<IsarGeneratedInsight> objects) {
    return putAllByIndex(r'insightId', objects);
  }

  List<Id> putAllByInsightIdSync(List<IsarGeneratedInsight> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'insightId', objects, saveLinks: saveLinks);
  }
}

extension IsarGeneratedInsightQueryWhereSort
    on QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QWhere> {
  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhere>
      anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarGeneratedInsightQueryWhere
    on QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QWhereClause> {
  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
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

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      insightIdEqualTo(String insightId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'insightId',
        value: [insightId],
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      insightIdNotEqualTo(String insightId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'insightId',
              lower: [],
              upper: [insightId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'insightId',
              lower: [insightId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'insightId',
              lower: [insightId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'insightId',
              lower: [],
              upper: [insightId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      scopeTypeEqualToAnyScopeId(String scopeType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'scopeType_scopeId',
        value: [scopeType],
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      scopeTypeNotEqualToAnyScopeId(String scopeType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType_scopeId',
              lower: [],
              upper: [scopeType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType_scopeId',
              lower: [scopeType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType_scopeId',
              lower: [scopeType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType_scopeId',
              lower: [],
              upper: [scopeType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      scopeTypeScopeIdEqualTo(String scopeType, String scopeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'scopeType_scopeId',
        value: [scopeType, scopeId],
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      scopeTypeEqualToScopeIdNotEqualTo(String scopeType, String scopeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType_scopeId',
              lower: [scopeType],
              upper: [scopeType, scopeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType_scopeId',
              lower: [scopeType, scopeId],
              includeLower: false,
              upper: [scopeType],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType_scopeId',
              lower: [scopeType, scopeId],
              includeLower: false,
              upper: [scopeType],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType_scopeId',
              lower: [scopeType],
              upper: [scopeType, scopeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      scopeIdEqualTo(String scopeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'scopeId',
        value: [scopeId],
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      scopeIdNotEqualTo(String scopeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeId',
              lower: [],
              upper: [scopeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeId',
              lower: [scopeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeId',
              lower: [scopeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeId',
              lower: [],
              upper: [scopeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      sourceWindowEndDateKeyEqualTo(String sourceWindowEndDateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sourceWindowEndDateKey',
        value: [sourceWindowEndDateKey],
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      sourceWindowEndDateKeyNotEqualTo(String sourceWindowEndDateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceWindowEndDateKey',
              lower: [],
              upper: [sourceWindowEndDateKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceWindowEndDateKey',
              lower: [sourceWindowEndDateKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceWindowEndDateKey',
              lower: [sourceWindowEndDateKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceWindowEndDateKey',
              lower: [],
              upper: [sourceWindowEndDateKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      updatedAtMsEqualTo(int updatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAtMs',
        value: [updatedAtMs],
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      updatedAtMsNotEqualTo(int updatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAtMs',
              lower: [],
              upper: [updatedAtMs],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAtMs',
              lower: [updatedAtMs],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAtMs',
              lower: [updatedAtMs],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAtMs',
              lower: [],
              upper: [updatedAtMs],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      updatedAtMsGreaterThan(
    int updatedAtMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAtMs',
        lower: [updatedAtMs],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      updatedAtMsLessThan(
    int updatedAtMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAtMs',
        lower: [],
        upper: [updatedAtMs],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterWhereClause>
      updatedAtMsBetween(
    int lowerUpdatedAtMs,
    int upperUpdatedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAtMs',
        lower: [lowerUpdatedAtMs],
        includeLower: includeLower,
        upper: [upperUpdatedAtMs],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarGeneratedInsightQueryFilter on QueryBuilder<IsarGeneratedInsight,
    IsarGeneratedInsight, QFilterCondition> {
  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> createdAtMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> createdAtMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> createdAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAtMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightBucketEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'insightBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightBucketGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'insightBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightBucketLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'insightBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightBucketBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'insightBucket',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightBucketStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'insightBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightBucketEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'insightBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      insightBucketContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'insightBucket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      insightBucketMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'insightBucket',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightBucketIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'insightBucket',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightBucketIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'insightBucket',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'insightId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'insightId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'insightId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'insightId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'insightId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'insightId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      insightIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'insightId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      insightIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'insightId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'insightId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'insightId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'insightType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'insightType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'insightType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'insightType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'insightType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'insightType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      insightTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'insightType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      insightTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'insightType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'insightType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> insightTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'insightType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> payloadJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> payloadJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> payloadJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> payloadJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payloadJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> payloadJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> payloadJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payloadJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> priorityEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> priorityGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> priorityLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> priorityBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priority',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> priorityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> priorityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      priorityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'priority',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      priorityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'priority',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> priorityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> priorityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'priority',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> schemaVersionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> schemaVersionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> schemaVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'schemaVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scopeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      scopeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      scopeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scopeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scopeId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scopeId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scopeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scopeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scopeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scopeType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scopeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scopeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      scopeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scopeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      scopeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scopeType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scopeType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> scopeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scopeType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> sourceWindowEndDateKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceWindowEndDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> sourceWindowEndDateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceWindowEndDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> sourceWindowEndDateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceWindowEndDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> sourceWindowEndDateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceWindowEndDateKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> sourceWindowEndDateKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceWindowEndDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> sourceWindowEndDateKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceWindowEndDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      sourceWindowEndDateKeyContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceWindowEndDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
          QAfterFilterCondition>
      sourceWindowEndDateKeyMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceWindowEndDateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> sourceWindowEndDateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceWindowEndDateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> sourceWindowEndDateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceWindowEndDateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> updatedAtMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> updatedAtMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight,
      QAfterFilterCondition> updatedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAtMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarGeneratedInsightQueryObject on QueryBuilder<IsarGeneratedInsight,
    IsarGeneratedInsight, QFilterCondition> {}

extension IsarGeneratedInsightQueryLinks on QueryBuilder<IsarGeneratedInsight,
    IsarGeneratedInsight, QFilterCondition> {}

extension IsarGeneratedInsightQuerySortBy
    on QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QSortBy> {
  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByInsightBucket() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightBucket', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByInsightBucketDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightBucket', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByInsightId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByInsightIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByInsightType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightType', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByInsightTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightType', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByScopeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByScopeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByScopeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeType', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByScopeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeType', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortBySourceWindowEndDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceWindowEndDateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortBySourceWindowEndDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceWindowEndDateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarGeneratedInsightQuerySortThenBy
    on QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QSortThenBy> {
  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByInsightBucket() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightBucket', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByInsightBucketDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightBucket', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByInsightId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByInsightIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByInsightType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightType', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByInsightTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightType', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByScopeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByScopeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByScopeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeType', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByScopeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeType', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenBySourceWindowEndDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceWindowEndDateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenBySourceWindowEndDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceWindowEndDateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QAfterSortBy>
      thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarGeneratedInsightQueryWhereDistinct
    on QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct> {
  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct>
      distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct>
      distinctByInsightBucket({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'insightBucket',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct>
      distinctByInsightId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'insightId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct>
      distinctByInsightType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'insightType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct>
      distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct>
      distinctByPriority({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priority', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct>
      distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct>
      distinctByScopeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scopeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct>
      distinctByScopeType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scopeType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct>
      distinctBySourceWindowEndDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceWindowEndDateKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGeneratedInsight, IsarGeneratedInsight, QDistinct>
      distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarGeneratedInsightQueryProperty on QueryBuilder<
    IsarGeneratedInsight, IsarGeneratedInsight, QQueryProperty> {
  QueryBuilder<IsarGeneratedInsight, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarGeneratedInsight, int, QQueryOperations>
      createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarGeneratedInsight, String, QQueryOperations>
      insightBucketProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'insightBucket');
    });
  }

  QueryBuilder<IsarGeneratedInsight, String, QQueryOperations>
      insightIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'insightId');
    });
  }

  QueryBuilder<IsarGeneratedInsight, String, QQueryOperations>
      insightTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'insightType');
    });
  }

  QueryBuilder<IsarGeneratedInsight, String, QQueryOperations>
      payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<IsarGeneratedInsight, String, QQueryOperations>
      priorityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priority');
    });
  }

  QueryBuilder<IsarGeneratedInsight, int, QQueryOperations>
      schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<IsarGeneratedInsight, String, QQueryOperations>
      scopeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scopeId');
    });
  }

  QueryBuilder<IsarGeneratedInsight, String, QQueryOperations>
      scopeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scopeType');
    });
  }

  QueryBuilder<IsarGeneratedInsight, String, QQueryOperations>
      sourceWindowEndDateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceWindowEndDateKey');
    });
  }

  QueryBuilder<IsarGeneratedInsight, int, QQueryOperations>
      updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
