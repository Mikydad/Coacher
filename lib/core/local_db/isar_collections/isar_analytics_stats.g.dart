// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_analytics_stats.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarAnalyticsStatsCollection on Isar {
  IsarCollection<IsarAnalyticsStats> get isarAnalyticsStats =>
      this.collection();
}

const IsarAnalyticsStatsSchema = CollectionSchema(
  name: r'IsarAnalyticsStats',
  id: -579119515500626235,
  properties: {
    r'createdAtMs': PropertySchema(
      id: 0,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'dateKey': PropertySchema(
      id: 1,
      name: r'dateKey',
      type: IsarType.string,
    ),
    r'payloadJson': PropertySchema(
      id: 2,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 3,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'scopeId': PropertySchema(
      id: 4,
      name: r'scopeId',
      type: IsarType.string,
    ),
    r'scopeType': PropertySchema(
      id: 5,
      name: r'scopeType',
      type: IsarType.string,
    ),
    r'statsId': PropertySchema(
      id: 6,
      name: r'statsId',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 7,
      name: r'updatedAtMs',
      type: IsarType.long,
    )
  },
  estimateSize: _isarAnalyticsStatsEstimateSize,
  serialize: _isarAnalyticsStatsSerialize,
  deserialize: _isarAnalyticsStatsDeserialize,
  deserializeProp: _isarAnalyticsStatsDeserializeProp,
  idName: r'id',
  indexes: {
    r'statsId': IndexSchema(
      id: -2501059016366061103,
      name: r'statsId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'statsId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'scopeType': IndexSchema(
      id: -2068910790579052619,
      name: r'scopeType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'scopeType',
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
  getId: _isarAnalyticsStatsGetId,
  getLinks: _isarAnalyticsStatsGetLinks,
  attach: _isarAnalyticsStatsAttach,
  version: '3.1.0+1',
);

int _isarAnalyticsStatsEstimateSize(
  IsarAnalyticsStats object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.scopeId.length * 3;
  bytesCount += 3 + object.scopeType.length * 3;
  bytesCount += 3 + object.statsId.length * 3;
  return bytesCount;
}

void _isarAnalyticsStatsSerialize(
  IsarAnalyticsStats object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.createdAtMs);
  writer.writeString(offsets[1], object.dateKey);
  writer.writeString(offsets[2], object.payloadJson);
  writer.writeLong(offsets[3], object.schemaVersion);
  writer.writeString(offsets[4], object.scopeId);
  writer.writeString(offsets[5], object.scopeType);
  writer.writeString(offsets[6], object.statsId);
  writer.writeLong(offsets[7], object.updatedAtMs);
}

IsarAnalyticsStats _isarAnalyticsStatsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAnalyticsStats();
  object.createdAtMs = reader.readLong(offsets[0]);
  object.dateKey = reader.readString(offsets[1]);
  object.id = id;
  object.payloadJson = reader.readString(offsets[2]);
  object.schemaVersion = reader.readLong(offsets[3]);
  object.scopeId = reader.readString(offsets[4]);
  object.scopeType = reader.readString(offsets[5]);
  object.statsId = reader.readString(offsets[6]);
  object.updatedAtMs = reader.readLong(offsets[7]);
  return object;
}

P _isarAnalyticsStatsDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarAnalyticsStatsGetId(IsarAnalyticsStats object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarAnalyticsStatsGetLinks(
    IsarAnalyticsStats object) {
  return [];
}

void _isarAnalyticsStatsAttach(
    IsarCollection<dynamic> col, Id id, IsarAnalyticsStats object) {
  object.id = id;
}

extension IsarAnalyticsStatsByIndex on IsarCollection<IsarAnalyticsStats> {
  Future<IsarAnalyticsStats?> getByStatsId(String statsId) {
    return getByIndex(r'statsId', [statsId]);
  }

  IsarAnalyticsStats? getByStatsIdSync(String statsId) {
    return getByIndexSync(r'statsId', [statsId]);
  }

  Future<bool> deleteByStatsId(String statsId) {
    return deleteByIndex(r'statsId', [statsId]);
  }

  bool deleteByStatsIdSync(String statsId) {
    return deleteByIndexSync(r'statsId', [statsId]);
  }

  Future<List<IsarAnalyticsStats?>> getAllByStatsId(
      List<String> statsIdValues) {
    final values = statsIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'statsId', values);
  }

  List<IsarAnalyticsStats?> getAllByStatsIdSync(List<String> statsIdValues) {
    final values = statsIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'statsId', values);
  }

  Future<int> deleteAllByStatsId(List<String> statsIdValues) {
    final values = statsIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'statsId', values);
  }

  int deleteAllByStatsIdSync(List<String> statsIdValues) {
    final values = statsIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'statsId', values);
  }

  Future<Id> putByStatsId(IsarAnalyticsStats object) {
    return putByIndex(r'statsId', object);
  }

  Id putByStatsIdSync(IsarAnalyticsStats object, {bool saveLinks = true}) {
    return putByIndexSync(r'statsId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByStatsId(List<IsarAnalyticsStats> objects) {
    return putAllByIndex(r'statsId', objects);
  }

  List<Id> putAllByStatsIdSync(List<IsarAnalyticsStats> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'statsId', objects, saveLinks: saveLinks);
  }
}

extension IsarAnalyticsStatsQueryWhereSort
    on QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QWhere> {
  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhere>
      anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarAnalyticsStatsQueryWhere
    on QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QWhereClause> {
  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
      statsIdEqualTo(String statsId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'statsId',
        value: [statsId],
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
      statsIdNotEqualTo(String statsId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'statsId',
              lower: [],
              upper: [statsId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'statsId',
              lower: [statsId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'statsId',
              lower: [statsId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'statsId',
              lower: [],
              upper: [statsId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
      scopeTypeEqualTo(String scopeType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'scopeType',
        value: [scopeType],
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
      scopeTypeNotEqualTo(String scopeType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType',
              lower: [],
              upper: [scopeType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType',
              lower: [scopeType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType',
              lower: [scopeType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeType',
              lower: [],
              upper: [scopeType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
      scopeIdEqualTo(String scopeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'scopeId',
        value: [scopeId],
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
      dateKeyEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [dateKey],
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
      dateKeyNotEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
      updatedAtMsEqualTo(int updatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAtMs',
        value: [updatedAtMs],
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterWhereClause>
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

extension IsarAnalyticsStatsQueryFilter
    on QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QFilterCondition> {
  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      createdAtMsGreaterThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      createdAtMsLessThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      createdAtMsBetween(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      dateKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      dateKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      dateKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      payloadJsonEqualTo(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      payloadJsonGreaterThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      payloadJsonLessThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      payloadJsonBetween(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      payloadJsonStartsWith(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      payloadJsonEndsWith(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payloadJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      schemaVersionGreaterThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      schemaVersionLessThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      schemaVersionBetween(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeIdEqualTo(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeIdGreaterThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeIdLessThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeIdBetween(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeIdStartsWith(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeIdEndsWith(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scopeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scopeId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scopeId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeTypeEqualTo(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeTypeGreaterThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeTypeLessThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeTypeBetween(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeTypeStartsWith(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeTypeEndsWith(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scopeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scopeType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scopeType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      scopeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scopeType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      statsIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      statsIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      statsIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      statsIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statsId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      statsIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'statsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      statsIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'statsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      statsIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'statsId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      statsIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'statsId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      statsIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statsId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      statsIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'statsId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      updatedAtMsGreaterThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      updatedAtMsLessThan(
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

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterFilterCondition>
      updatedAtMsBetween(
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

extension IsarAnalyticsStatsQueryObject
    on QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QFilterCondition> {}

extension IsarAnalyticsStatsQueryLinks
    on QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QFilterCondition> {}

extension IsarAnalyticsStatsQuerySortBy
    on QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QSortBy> {
  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByScopeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByScopeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByScopeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeType', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByScopeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeType', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByStatsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statsId', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByStatsIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statsId', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarAnalyticsStatsQuerySortThenBy
    on QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QSortThenBy> {
  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByScopeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByScopeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByScopeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeType', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByScopeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeType', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByStatsId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statsId', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByStatsIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statsId', Sort.desc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QAfterSortBy>
      thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarAnalyticsStatsQueryWhereDistinct
    on QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QDistinct> {
  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QDistinct>
      distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QDistinct>
      distinctByDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QDistinct>
      distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QDistinct>
      distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QDistinct>
      distinctByScopeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scopeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QDistinct>
      distinctByScopeType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scopeType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QDistinct>
      distinctByStatsId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statsId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QDistinct>
      distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarAnalyticsStatsQueryProperty
    on QueryBuilder<IsarAnalyticsStats, IsarAnalyticsStats, QQueryProperty> {
  QueryBuilder<IsarAnalyticsStats, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarAnalyticsStats, int, QQueryOperations>
      createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarAnalyticsStats, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<IsarAnalyticsStats, String, QQueryOperations>
      payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<IsarAnalyticsStats, int, QQueryOperations>
      schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<IsarAnalyticsStats, String, QQueryOperations> scopeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scopeId');
    });
  }

  QueryBuilder<IsarAnalyticsStats, String, QQueryOperations>
      scopeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scopeType');
    });
  }

  QueryBuilder<IsarAnalyticsStats, String, QQueryOperations> statsIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statsId');
    });
  }

  QueryBuilder<IsarAnalyticsStats, int, QQueryOperations>
      updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
