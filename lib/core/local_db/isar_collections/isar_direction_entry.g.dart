// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_direction_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarDirectionEntryCollection on Isar {
  IsarCollection<IsarDirectionEntry> get isarDirectionEntrys =>
      this.collection();
}

const IsarDirectionEntrySchema = CollectionSchema(
  name: r'IsarDirectionEntry',
  id: -3554308723592998165,
  properties: {
    r'createdAtMs': PropertySchema(
      id: 0,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'entryId': PropertySchema(id: 1, name: r'entryId', type: IsarType.string),
    r'horizonStorage': PropertySchema(
      id: 2,
      name: r'horizonStorage',
      type: IsarType.string,
    ),
    r'periodEndMs': PropertySchema(
      id: 3,
      name: r'periodEndMs',
      type: IsarType.long,
    ),
    r'periodKey': PropertySchema(
      id: 4,
      name: r'periodKey',
      type: IsarType.string,
    ),
    r'periodStartMs': PropertySchema(
      id: 5,
      name: r'periodStartMs',
      type: IsarType.long,
    ),
    r'text': PropertySchema(id: 6, name: r'text', type: IsarType.string),
    r'updatedAtMs': PropertySchema(
      id: 7,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarDirectionEntryEstimateSize,
  serialize: _isarDirectionEntrySerialize,
  deserialize: _isarDirectionEntryDeserialize,
  deserializeProp: _isarDirectionEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'entryId': IndexSchema(
      id: 3733379884318738402,
      name: r'entryId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entryId',
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
    r'horizonStorage': IndexSchema(
      id: -7098034022036905874,
      name: r'horizonStorage',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'horizonStorage',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'periodKey': IndexSchema(
      id: 1168583613613626778,
      name: r'periodKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'periodKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarDirectionEntryGetId,
  getLinks: _isarDirectionEntryGetLinks,
  attach: _isarDirectionEntryAttach,
  version: '3.3.2',
);

int _isarDirectionEntryEstimateSize(
  IsarDirectionEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.entryId.length * 3;
  bytesCount += 3 + object.horizonStorage.length * 3;
  bytesCount += 3 + object.periodKey.length * 3;
  bytesCount += 3 + object.text.length * 3;
  return bytesCount;
}

void _isarDirectionEntrySerialize(
  IsarDirectionEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.createdAtMs);
  writer.writeString(offsets[1], object.entryId);
  writer.writeString(offsets[2], object.horizonStorage);
  writer.writeLong(offsets[3], object.periodEndMs);
  writer.writeString(offsets[4], object.periodKey);
  writer.writeLong(offsets[5], object.periodStartMs);
  writer.writeString(offsets[6], object.text);
  writer.writeLong(offsets[7], object.updatedAtMs);
}

IsarDirectionEntry _isarDirectionEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarDirectionEntry();
  object.createdAtMs = reader.readLong(offsets[0]);
  object.entryId = reader.readString(offsets[1]);
  object.horizonStorage = reader.readString(offsets[2]);
  object.id = id;
  object.periodEndMs = reader.readLong(offsets[3]);
  object.periodKey = reader.readString(offsets[4]);
  object.periodStartMs = reader.readLong(offsets[5]);
  object.text = reader.readString(offsets[6]);
  object.updatedAtMs = reader.readLong(offsets[7]);
  return object;
}

P _isarDirectionEntryDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarDirectionEntryGetId(IsarDirectionEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarDirectionEntryGetLinks(
  IsarDirectionEntry object,
) {
  return [];
}

void _isarDirectionEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarDirectionEntry object,
) {
  object.id = id;
}

extension IsarDirectionEntryByIndex on IsarCollection<IsarDirectionEntry> {
  Future<IsarDirectionEntry?> getByEntryId(String entryId) {
    return getByIndex(r'entryId', [entryId]);
  }

  IsarDirectionEntry? getByEntryIdSync(String entryId) {
    return getByIndexSync(r'entryId', [entryId]);
  }

  Future<bool> deleteByEntryId(String entryId) {
    return deleteByIndex(r'entryId', [entryId]);
  }

  bool deleteByEntryIdSync(String entryId) {
    return deleteByIndexSync(r'entryId', [entryId]);
  }

  Future<List<IsarDirectionEntry?>> getAllByEntryId(
    List<String> entryIdValues,
  ) {
    final values = entryIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'entryId', values);
  }

  List<IsarDirectionEntry?> getAllByEntryIdSync(List<String> entryIdValues) {
    final values = entryIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'entryId', values);
  }

  Future<int> deleteAllByEntryId(List<String> entryIdValues) {
    final values = entryIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'entryId', values);
  }

  int deleteAllByEntryIdSync(List<String> entryIdValues) {
    final values = entryIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'entryId', values);
  }

  Future<Id> putByEntryId(IsarDirectionEntry object) {
    return putByIndex(r'entryId', object);
  }

  Id putByEntryIdSync(IsarDirectionEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'entryId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEntryId(List<IsarDirectionEntry> objects) {
    return putAllByIndex(r'entryId', objects);
  }

  List<Id> putAllByEntryIdSync(
    List<IsarDirectionEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'entryId', objects, saveLinks: saveLinks);
  }
}

extension IsarDirectionEntryQueryWhereSort
    on QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QWhere> {
  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhere>
  anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarDirectionEntryQueryWhere
    on QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QWhereClause> {
  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
  entryIdEqualTo(String entryId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entryId', value: [entryId]),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
  entryIdNotEqualTo(String entryId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entryId',
                lower: [],
                upper: [entryId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entryId',
                lower: [entryId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entryId',
                lower: [entryId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entryId',
                lower: [],
                upper: [entryId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
  horizonStorageEqualTo(String horizonStorage) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'horizonStorage',
          value: [horizonStorage],
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
  horizonStorageNotEqualTo(String horizonStorage) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'horizonStorage',
                lower: [],
                upper: [horizonStorage],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'horizonStorage',
                lower: [horizonStorage],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'horizonStorage',
                lower: [horizonStorage],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'horizonStorage',
                lower: [],
                upper: [horizonStorage],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
  periodKeyEqualTo(String periodKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'periodKey', value: [periodKey]),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterWhereClause>
  periodKeyNotEqualTo(String periodKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'periodKey',
                lower: [],
                upper: [periodKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'periodKey',
                lower: [periodKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'periodKey',
                lower: [periodKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'periodKey',
                lower: [],
                upper: [periodKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarDirectionEntryQueryFilter
    on QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QFilterCondition> {
  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  entryIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  entryIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  entryIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  entryIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entryId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  entryIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  entryIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  entryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  entryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entryId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  entryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entryId', value: ''),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  entryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entryId', value: ''),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  horizonStorageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'horizonStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  horizonStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'horizonStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  horizonStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'horizonStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  horizonStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'horizonStorage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  horizonStorageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'horizonStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  horizonStorageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'horizonStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  horizonStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'horizonStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  horizonStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'horizonStorage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  horizonStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'horizonStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  horizonStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'horizonStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodEndMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'periodEndMs', value: value),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodEndMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'periodEndMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodEndMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'periodEndMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodEndMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'periodEndMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'periodKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'periodKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'periodKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'periodKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'periodKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'periodKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'periodKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'periodKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'periodKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'periodKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodStartMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'periodStartMs', value: value),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodStartMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'periodStartMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodStartMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'periodStartMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  periodStartMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'periodStartMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  textEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
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

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterFilterCondition>
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

extension IsarDirectionEntryQueryObject
    on QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QFilterCondition> {}

extension IsarDirectionEntryQueryLinks
    on QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QFilterCondition> {}

extension IsarDirectionEntryQuerySortBy
    on QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QSortBy> {
  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByEntryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByEntryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByHorizonStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horizonStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByHorizonStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horizonStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByPeriodEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByPeriodEndMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByPeriodStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByPeriodStartMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarDirectionEntryQuerySortThenBy
    on QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QSortThenBy> {
  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByEntryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByEntryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByHorizonStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horizonStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByHorizonStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horizonStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByPeriodEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByPeriodEndMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByPeriodStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByPeriodStartMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarDirectionEntryQueryWhereDistinct
    on QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QDistinct> {
  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QDistinct>
  distinctByEntryId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QDistinct>
  distinctByHorizonStorage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'horizonStorage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QDistinct>
  distinctByPeriodEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodEndMs');
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QDistinct>
  distinctByPeriodKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QDistinct>
  distinctByPeriodStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodStartMs');
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QDistinct>
  distinctByText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarDirectionEntryQueryProperty
    on QueryBuilder<IsarDirectionEntry, IsarDirectionEntry, QQueryProperty> {
  QueryBuilder<IsarDirectionEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarDirectionEntry, int, QQueryOperations>
  createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarDirectionEntry, String, QQueryOperations> entryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entryId');
    });
  }

  QueryBuilder<IsarDirectionEntry, String, QQueryOperations>
  horizonStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'horizonStorage');
    });
  }

  QueryBuilder<IsarDirectionEntry, int, QQueryOperations>
  periodEndMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodEndMs');
    });
  }

  QueryBuilder<IsarDirectionEntry, String, QQueryOperations>
  periodKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodKey');
    });
  }

  QueryBuilder<IsarDirectionEntry, int, QQueryOperations>
  periodStartMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodStartMs');
    });
  }

  QueryBuilder<IsarDirectionEntry, String, QQueryOperations> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }

  QueryBuilder<IsarDirectionEntry, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
