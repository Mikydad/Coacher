// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_ai_pulse_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarAiPulseCacheCollection on Isar {
  IsarCollection<IsarAiPulseCache> get isarAiPulseCaches => this.collection();
}

const IsarAiPulseCacheSchema = CollectionSchema(
  name: r'IsarAiPulseCache',
  id: 3023830392217638682,
  properties: {
    r'circleId': PropertySchema(
      id: 0,
      name: r'circleId',
      type: IsarType.string,
    ),
    r'generatedAtMs': PropertySchema(
      id: 1,
      name: r'generatedAtMs',
      type: IsarType.long,
    ),
    r'payload': PropertySchema(
      id: 2,
      name: r'payload',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 3,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _isarAiPulseCacheEstimateSize,
  serialize: _isarAiPulseCacheSerialize,
  deserialize: _isarAiPulseCacheDeserialize,
  deserializeProp: _isarAiPulseCacheDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'circleId_type': IndexSchema(
      id: -6825630351702198329,
      name: r'circleId_type',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'circleId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'generatedAtMs': IndexSchema(
      id: 175890871767624139,
      name: r'generatedAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'generatedAtMs',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarAiPulseCacheGetId,
  getLinks: _isarAiPulseCacheGetLinks,
  attach: _isarAiPulseCacheAttach,
  version: '3.1.0+1',
);

int _isarAiPulseCacheEstimateSize(
  IsarAiPulseCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.circleId.length * 3;
  bytesCount += 3 + object.payload.length * 3;
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _isarAiPulseCacheSerialize(
  IsarAiPulseCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.circleId);
  writer.writeLong(offsets[1], object.generatedAtMs);
  writer.writeString(offsets[2], object.payload);
  writer.writeString(offsets[3], object.type);
}

IsarAiPulseCache _isarAiPulseCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAiPulseCache();
  object.circleId = reader.readString(offsets[0]);
  object.generatedAtMs = reader.readLong(offsets[1]);
  object.isarId = id;
  object.payload = reader.readString(offsets[2]);
  object.type = reader.readString(offsets[3]);
  return object;
}

P _isarAiPulseCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarAiPulseCacheGetId(IsarAiPulseCache object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _isarAiPulseCacheGetLinks(IsarAiPulseCache object) {
  return [];
}

void _isarAiPulseCacheAttach(
    IsarCollection<dynamic> col, Id id, IsarAiPulseCache object) {
  object.isarId = id;
}

extension IsarAiPulseCacheByIndex on IsarCollection<IsarAiPulseCache> {
  Future<IsarAiPulseCache?> getByCircleIdType(String circleId, String type) {
    return getByIndex(r'circleId_type', [circleId, type]);
  }

  IsarAiPulseCache? getByCircleIdTypeSync(String circleId, String type) {
    return getByIndexSync(r'circleId_type', [circleId, type]);
  }

  Future<bool> deleteByCircleIdType(String circleId, String type) {
    return deleteByIndex(r'circleId_type', [circleId, type]);
  }

  bool deleteByCircleIdTypeSync(String circleId, String type) {
    return deleteByIndexSync(r'circleId_type', [circleId, type]);
  }

  Future<List<IsarAiPulseCache?>> getAllByCircleIdType(
      List<String> circleIdValues, List<String> typeValues) {
    final len = circleIdValues.length;
    assert(
        typeValues.length == len, 'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([circleIdValues[i], typeValues[i]]);
    }

    return getAllByIndex(r'circleId_type', values);
  }

  List<IsarAiPulseCache?> getAllByCircleIdTypeSync(
      List<String> circleIdValues, List<String> typeValues) {
    final len = circleIdValues.length;
    assert(
        typeValues.length == len, 'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([circleIdValues[i], typeValues[i]]);
    }

    return getAllByIndexSync(r'circleId_type', values);
  }

  Future<int> deleteAllByCircleIdType(
      List<String> circleIdValues, List<String> typeValues) {
    final len = circleIdValues.length;
    assert(
        typeValues.length == len, 'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([circleIdValues[i], typeValues[i]]);
    }

    return deleteAllByIndex(r'circleId_type', values);
  }

  int deleteAllByCircleIdTypeSync(
      List<String> circleIdValues, List<String> typeValues) {
    final len = circleIdValues.length;
    assert(
        typeValues.length == len, 'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([circleIdValues[i], typeValues[i]]);
    }

    return deleteAllByIndexSync(r'circleId_type', values);
  }

  Future<Id> putByCircleIdType(IsarAiPulseCache object) {
    return putByIndex(r'circleId_type', object);
  }

  Id putByCircleIdTypeSync(IsarAiPulseCache object, {bool saveLinks = true}) {
    return putByIndexSync(r'circleId_type', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCircleIdType(List<IsarAiPulseCache> objects) {
    return putAllByIndex(r'circleId_type', objects);
  }

  List<Id> putAllByCircleIdTypeSync(List<IsarAiPulseCache> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'circleId_type', objects, saveLinks: saveLinks);
  }
}

extension IsarAiPulseCacheQueryWhereSort
    on QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QWhere> {
  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhere>
      anyGeneratedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'generatedAtMs'),
      );
    });
  }
}

extension IsarAiPulseCacheQueryWhere
    on QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QWhereClause> {
  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      circleIdEqualToAnyType(String circleId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'circleId_type',
        value: [circleId],
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      circleIdNotEqualToAnyType(String circleId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'circleId_type',
              lower: [],
              upper: [circleId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'circleId_type',
              lower: [circleId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'circleId_type',
              lower: [circleId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'circleId_type',
              lower: [],
              upper: [circleId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      circleIdTypeEqualTo(String circleId, String type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'circleId_type',
        value: [circleId, type],
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      circleIdEqualToTypeNotEqualTo(String circleId, String type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'circleId_type',
              lower: [circleId],
              upper: [circleId, type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'circleId_type',
              lower: [circleId, type],
              includeLower: false,
              upper: [circleId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'circleId_type',
              lower: [circleId, type],
              includeLower: false,
              upper: [circleId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'circleId_type',
              lower: [circleId],
              upper: [circleId, type],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      generatedAtMsEqualTo(int generatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'generatedAtMs',
        value: [generatedAtMs],
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      generatedAtMsNotEqualTo(int generatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generatedAtMs',
              lower: [],
              upper: [generatedAtMs],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generatedAtMs',
              lower: [generatedAtMs],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generatedAtMs',
              lower: [generatedAtMs],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generatedAtMs',
              lower: [],
              upper: [generatedAtMs],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      generatedAtMsGreaterThan(
    int generatedAtMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'generatedAtMs',
        lower: [generatedAtMs],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      generatedAtMsLessThan(
    int generatedAtMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'generatedAtMs',
        lower: [],
        upper: [generatedAtMs],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterWhereClause>
      generatedAtMsBetween(
    int lowerGeneratedAtMs,
    int upperGeneratedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'generatedAtMs',
        lower: [lowerGeneratedAtMs],
        includeLower: includeLower,
        upper: [upperGeneratedAtMs],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarAiPulseCacheQueryFilter
    on QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QFilterCondition> {
  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      circleIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'circleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      circleIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'circleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      circleIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'circleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      circleIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'circleId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      circleIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'circleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      circleIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'circleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      circleIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'circleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      circleIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'circleId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      circleIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'circleId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      circleIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'circleId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      generatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'generatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      generatedAtMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'generatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      generatedAtMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'generatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      generatedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'generatedAtMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      payloadEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      payloadGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      payloadLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      payloadBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payload',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      payloadStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      payloadEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      payloadContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      payloadMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payload',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      payloadIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payload',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      payloadIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payload',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension IsarAiPulseCacheQueryObject
    on QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QFilterCondition> {}

extension IsarAiPulseCacheQueryLinks
    on QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QFilterCondition> {}

extension IsarAiPulseCacheQuerySortBy
    on QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QSortBy> {
  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      sortByCircleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.asc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      sortByCircleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.desc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      sortByGeneratedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      sortByGeneratedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      sortByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      sortByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension IsarAiPulseCacheQuerySortThenBy
    on QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QSortThenBy> {
  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      thenByCircleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.asc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      thenByCircleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.desc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      thenByGeneratedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      thenByGeneratedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      thenByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      thenByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension IsarAiPulseCacheQueryWhereDistinct
    on QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QDistinct> {
  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QDistinct>
      distinctByCircleId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'circleId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QDistinct>
      distinctByGeneratedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'generatedAtMs');
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QDistinct> distinctByPayload(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payload', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension IsarAiPulseCacheQueryProperty
    on QueryBuilder<IsarAiPulseCache, IsarAiPulseCache, QQueryProperty> {
  QueryBuilder<IsarAiPulseCache, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<IsarAiPulseCache, String, QQueryOperations> circleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'circleId');
    });
  }

  QueryBuilder<IsarAiPulseCache, int, QQueryOperations>
      generatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'generatedAtMs');
    });
  }

  QueryBuilder<IsarAiPulseCache, String, QQueryOperations> payloadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payload');
    });
  }

  QueryBuilder<IsarAiPulseCache, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
