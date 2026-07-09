// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_activity_feed_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarActivityFeedCacheCollection on Isar {
  IsarCollection<IsarActivityFeedCache> get isarActivityFeedCaches =>
      this.collection();
}

const IsarActivityFeedCacheSchema = CollectionSchema(
  name: r'IsarActivityFeedCache',
  id: -7141913318395602495,
  properties: {
    r'circleId': PropertySchema(
      id: 0,
      name: r'circleId',
      type: IsarType.string,
    ),
    r'createdAtMs': PropertySchema(
      id: 1,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'itemId': PropertySchema(id: 2, name: r'itemId', type: IsarType.string),
    r'payload': PropertySchema(id: 3, name: r'payload', type: IsarType.string),
  },

  estimateSize: _isarActivityFeedCacheEstimateSize,
  serialize: _isarActivityFeedCacheSerialize,
  deserialize: _isarActivityFeedCacheDeserialize,
  deserializeProp: _isarActivityFeedCacheDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'itemId': IndexSchema(
      id: -5342806140158601489,
      name: r'itemId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'itemId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'circleId': IndexSchema(
      id: 2024179452621641335,
      name: r'circleId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'circleId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'createdAtMs': IndexSchema(
      id: 6848184219297703682,
      name: r'createdAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAtMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarActivityFeedCacheGetId,
  getLinks: _isarActivityFeedCacheGetLinks,
  attach: _isarActivityFeedCacheAttach,
  version: '3.3.2',
);

int _isarActivityFeedCacheEstimateSize(
  IsarActivityFeedCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.circleId.length * 3;
  bytesCount += 3 + object.itemId.length * 3;
  bytesCount += 3 + object.payload.length * 3;
  return bytesCount;
}

void _isarActivityFeedCacheSerialize(
  IsarActivityFeedCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.circleId);
  writer.writeLong(offsets[1], object.createdAtMs);
  writer.writeString(offsets[2], object.itemId);
  writer.writeString(offsets[3], object.payload);
}

IsarActivityFeedCache _isarActivityFeedCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarActivityFeedCache();
  object.circleId = reader.readString(offsets[0]);
  object.createdAtMs = reader.readLong(offsets[1]);
  object.isarId = id;
  object.itemId = reader.readString(offsets[2]);
  object.payload = reader.readString(offsets[3]);
  return object;
}

P _isarActivityFeedCacheDeserializeProp<P>(
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

Id _isarActivityFeedCacheGetId(IsarActivityFeedCache object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _isarActivityFeedCacheGetLinks(
  IsarActivityFeedCache object,
) {
  return [];
}

void _isarActivityFeedCacheAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarActivityFeedCache object,
) {
  object.isarId = id;
}

extension IsarActivityFeedCacheByIndex
    on IsarCollection<IsarActivityFeedCache> {
  Future<IsarActivityFeedCache?> getByItemId(String itemId) {
    return getByIndex(r'itemId', [itemId]);
  }

  IsarActivityFeedCache? getByItemIdSync(String itemId) {
    return getByIndexSync(r'itemId', [itemId]);
  }

  Future<bool> deleteByItemId(String itemId) {
    return deleteByIndex(r'itemId', [itemId]);
  }

  bool deleteByItemIdSync(String itemId) {
    return deleteByIndexSync(r'itemId', [itemId]);
  }

  Future<List<IsarActivityFeedCache?>> getAllByItemId(
    List<String> itemIdValues,
  ) {
    final values = itemIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'itemId', values);
  }

  List<IsarActivityFeedCache?> getAllByItemIdSync(List<String> itemIdValues) {
    final values = itemIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'itemId', values);
  }

  Future<int> deleteAllByItemId(List<String> itemIdValues) {
    final values = itemIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'itemId', values);
  }

  int deleteAllByItemIdSync(List<String> itemIdValues) {
    final values = itemIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'itemId', values);
  }

  Future<Id> putByItemId(IsarActivityFeedCache object) {
    return putByIndex(r'itemId', object);
  }

  Id putByItemIdSync(IsarActivityFeedCache object, {bool saveLinks = true}) {
    return putByIndexSync(r'itemId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByItemId(List<IsarActivityFeedCache> objects) {
    return putAllByIndex(r'itemId', objects);
  }

  List<Id> putAllByItemIdSync(
    List<IsarActivityFeedCache> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'itemId', objects, saveLinks: saveLinks);
  }
}

extension IsarActivityFeedCacheQueryWhereSort
    on QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QWhere> {
  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhere>
  anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhere>
  anyCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAtMs'),
      );
    });
  }
}

extension IsarActivityFeedCacheQueryWhere
    on
        QueryBuilder<
          IsarActivityFeedCache,
          IsarActivityFeedCache,
          QWhereClause
        > {
  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
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

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  itemIdEqualTo(String itemId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'itemId', value: [itemId]),
      );
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  itemIdNotEqualTo(String itemId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'itemId',
                lower: [],
                upper: [itemId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'itemId',
                lower: [itemId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'itemId',
                lower: [itemId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'itemId',
                lower: [],
                upper: [itemId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  circleIdEqualTo(String circleId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'circleId', value: [circleId]),
      );
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  circleIdNotEqualTo(String circleId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'circleId',
                lower: [],
                upper: [circleId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'circleId',
                lower: [circleId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'circleId',
                lower: [circleId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'circleId',
                lower: [],
                upper: [circleId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  createdAtMsEqualTo(int createdAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'createdAtMs',
          value: [createdAtMs],
        ),
      );
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  createdAtMsNotEqualTo(int createdAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAtMs',
                lower: [],
                upper: [createdAtMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAtMs',
                lower: [createdAtMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAtMs',
                lower: [createdAtMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAtMs',
                lower: [],
                upper: [createdAtMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  createdAtMsGreaterThan(int createdAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAtMs',
          lower: [createdAtMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  createdAtMsLessThan(int createdAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAtMs',
          lower: [],
          upper: [createdAtMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterWhereClause>
  createdAtMsBetween(
    int lowerCreatedAtMs,
    int upperCreatedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAtMs',
          lower: [lowerCreatedAtMs],
          includeLower: includeLower,
          upper: [upperCreatedAtMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarActivityFeedCacheQueryFilter
    on
        QueryBuilder<
          IsarActivityFeedCache,
          IsarActivityFeedCache,
          QFilterCondition
        > {
  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  circleIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'circleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  circleIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'circleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  circleIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'circleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  circleIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'circleId',
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
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  circleIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'circleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  circleIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'circleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  circleIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'circleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  circleIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'circleId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  circleIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'circleId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  circleIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'circleId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
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
    IsarActivityFeedCache,
    IsarActivityFeedCache,
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
    IsarActivityFeedCache,
    IsarActivityFeedCache,
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
    IsarActivityFeedCache,
    IsarActivityFeedCache,
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
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  itemIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  itemIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  itemIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  itemIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'itemId',
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
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  itemIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  itemIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  itemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'itemId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  itemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'itemId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  itemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'itemId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  itemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'itemId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  payloadEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  payloadGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  payloadLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  payloadBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'payload',
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
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  payloadStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  payloadEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  payloadContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  payloadMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'payload',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  payloadIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payload', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityFeedCache,
    IsarActivityFeedCache,
    QAfterFilterCondition
  >
  payloadIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payload', value: ''),
      );
    });
  }
}

extension IsarActivityFeedCacheQueryObject
    on
        QueryBuilder<
          IsarActivityFeedCache,
          IsarActivityFeedCache,
          QFilterCondition
        > {}

extension IsarActivityFeedCacheQueryLinks
    on
        QueryBuilder<
          IsarActivityFeedCache,
          IsarActivityFeedCache,
          QFilterCondition
        > {}

extension IsarActivityFeedCacheQuerySortBy
    on QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QSortBy> {
  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  sortByCircleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  sortByCircleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  sortByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  sortByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  sortByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  sortByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }
}

extension IsarActivityFeedCacheQuerySortThenBy
    on QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QSortThenBy> {
  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  thenByCircleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  thenByCircleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  thenByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  thenByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemId', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  thenByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QAfterSortBy>
  thenByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }
}

extension IsarActivityFeedCacheQueryWhereDistinct
    on QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QDistinct> {
  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QDistinct>
  distinctByCircleId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'circleId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QDistinct>
  distinctByItemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarActivityFeedCache, IsarActivityFeedCache, QDistinct>
  distinctByPayload({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payload', caseSensitive: caseSensitive);
    });
  }
}

extension IsarActivityFeedCacheQueryProperty
    on
        QueryBuilder<
          IsarActivityFeedCache,
          IsarActivityFeedCache,
          QQueryProperty
        > {
  QueryBuilder<IsarActivityFeedCache, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<IsarActivityFeedCache, String, QQueryOperations>
  circleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'circleId');
    });
  }

  QueryBuilder<IsarActivityFeedCache, int, QQueryOperations>
  createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarActivityFeedCache, String, QQueryOperations>
  itemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemId');
    });
  }

  QueryBuilder<IsarActivityFeedCache, String, QQueryOperations>
  payloadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payload');
    });
  }
}
