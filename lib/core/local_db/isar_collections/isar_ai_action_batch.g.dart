// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_ai_action_batch.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarAiActionBatchCollection on Isar {
  IsarCollection<IsarAiActionBatch> get isarAiActionBatchs => this.collection();
}

const IsarAiActionBatchSchema = CollectionSchema(
  name: r'IsarAiActionBatch',
  id: 4477134964203800930,
  properties: {
    r'actionsJson': PropertySchema(
      id: 0,
      name: r'actionsJson',
      type: IsarType.string,
    ),
    r'batchId': PropertySchema(id: 1, name: r'batchId', type: IsarType.string),
    r'createdAtMs': PropertySchema(
      id: 2,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'failedActionIds': PropertySchema(
      id: 3,
      name: r'failedActionIds',
      type: IsarType.stringList,
    ),
    r'snapshotJson': PropertySchema(
      id: 4,
      name: r'snapshotJson',
      type: IsarType.string,
    ),
    r'state': PropertySchema(id: 5, name: r'state', type: IsarType.string),
    r'succeededActionIds': PropertySchema(
      id: 6,
      name: r'succeededActionIds',
      type: IsarType.stringList,
    ),
    r'undoneAtMs': PropertySchema(
      id: 7,
      name: r'undoneAtMs',
      type: IsarType.long,
    ),
    r'updatedAtMs': PropertySchema(
      id: 8,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarAiActionBatchEstimateSize,
  serialize: _isarAiActionBatchSerialize,
  deserialize: _isarAiActionBatchDeserialize,
  deserializeProp: _isarAiActionBatchDeserializeProp,
  idName: r'id',
  indexes: {
    r'batchId': IndexSchema(
      id: -5468368523860846432,
      name: r'batchId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'batchId',
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

  getId: _isarAiActionBatchGetId,
  getLinks: _isarAiActionBatchGetLinks,
  attach: _isarAiActionBatchAttach,
  version: '3.3.2',
);

int _isarAiActionBatchEstimateSize(
  IsarAiActionBatch object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.actionsJson.length * 3;
  bytesCount += 3 + object.batchId.length * 3;
  bytesCount += 3 + object.failedActionIds.length * 3;
  {
    for (var i = 0; i < object.failedActionIds.length; i++) {
      final value = object.failedActionIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.snapshotJson.length * 3;
  bytesCount += 3 + object.state.length * 3;
  bytesCount += 3 + object.succeededActionIds.length * 3;
  {
    for (var i = 0; i < object.succeededActionIds.length; i++) {
      final value = object.succeededActionIds[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _isarAiActionBatchSerialize(
  IsarAiActionBatch object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.actionsJson);
  writer.writeString(offsets[1], object.batchId);
  writer.writeLong(offsets[2], object.createdAtMs);
  writer.writeStringList(offsets[3], object.failedActionIds);
  writer.writeString(offsets[4], object.snapshotJson);
  writer.writeString(offsets[5], object.state);
  writer.writeStringList(offsets[6], object.succeededActionIds);
  writer.writeLong(offsets[7], object.undoneAtMs);
  writer.writeLong(offsets[8], object.updatedAtMs);
}

IsarAiActionBatch _isarAiActionBatchDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAiActionBatch();
  object.actionsJson = reader.readString(offsets[0]);
  object.batchId = reader.readString(offsets[1]);
  object.createdAtMs = reader.readLong(offsets[2]);
  object.failedActionIds = reader.readStringList(offsets[3]) ?? [];
  object.id = id;
  object.snapshotJson = reader.readString(offsets[4]);
  object.state = reader.readString(offsets[5]);
  object.succeededActionIds = reader.readStringList(offsets[6]) ?? [];
  object.undoneAtMs = reader.readLongOrNull(offsets[7]);
  object.updatedAtMs = reader.readLong(offsets[8]);
  return object;
}

P _isarAiActionBatchDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringList(offset) ?? []) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarAiActionBatchGetId(IsarAiActionBatch object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarAiActionBatchGetLinks(
  IsarAiActionBatch object,
) {
  return [];
}

void _isarAiActionBatchAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarAiActionBatch object,
) {
  object.id = id;
}

extension IsarAiActionBatchByIndex on IsarCollection<IsarAiActionBatch> {
  Future<IsarAiActionBatch?> getByBatchId(String batchId) {
    return getByIndex(r'batchId', [batchId]);
  }

  IsarAiActionBatch? getByBatchIdSync(String batchId) {
    return getByIndexSync(r'batchId', [batchId]);
  }

  Future<bool> deleteByBatchId(String batchId) {
    return deleteByIndex(r'batchId', [batchId]);
  }

  bool deleteByBatchIdSync(String batchId) {
    return deleteByIndexSync(r'batchId', [batchId]);
  }

  Future<List<IsarAiActionBatch?>> getAllByBatchId(List<String> batchIdValues) {
    final values = batchIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'batchId', values);
  }

  List<IsarAiActionBatch?> getAllByBatchIdSync(List<String> batchIdValues) {
    final values = batchIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'batchId', values);
  }

  Future<int> deleteAllByBatchId(List<String> batchIdValues) {
    final values = batchIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'batchId', values);
  }

  int deleteAllByBatchIdSync(List<String> batchIdValues) {
    final values = batchIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'batchId', values);
  }

  Future<Id> putByBatchId(IsarAiActionBatch object) {
    return putByIndex(r'batchId', object);
  }

  Id putByBatchIdSync(IsarAiActionBatch object, {bool saveLinks = true}) {
    return putByIndexSync(r'batchId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBatchId(List<IsarAiActionBatch> objects) {
    return putAllByIndex(r'batchId', objects);
  }

  List<Id> putAllByBatchIdSync(
    List<IsarAiActionBatch> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'batchId', objects, saveLinks: saveLinks);
  }
}

extension IsarAiActionBatchQueryWhereSort
    on QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QWhere> {
  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhere>
  anyCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAtMs'),
      );
    });
  }
}

extension IsarAiActionBatchQueryWhere
    on QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QWhereClause> {
  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
  batchIdEqualTo(String batchId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'batchId', value: [batchId]),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
  batchIdNotEqualTo(String batchId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchId',
                lower: [],
                upper: [batchId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchId',
                lower: [batchId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchId',
                lower: [batchId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'batchId',
                lower: [],
                upper: [batchId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
  stateEqualTo(String state) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'state', value: [state]),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterWhereClause>
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

extension IsarAiActionBatchQueryFilter
    on QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QFilterCondition> {
  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  actionsJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'actionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  actionsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'actionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  actionsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'actionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  actionsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'actionsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  actionsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'actionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  actionsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'actionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  actionsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'actionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  actionsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'actionsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  actionsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'actionsJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  actionsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'actionsJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  batchIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  batchIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  batchIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  batchIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'batchId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  batchIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  batchIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  batchIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'batchId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  batchIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'batchId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  batchIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'batchId', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  batchIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'batchId', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'failedActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'failedActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'failedActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'failedActionIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'failedActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'failedActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'failedActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'failedActionIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'failedActionIds', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'failedActionIds', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'failedActionIds', length, true, length, true);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'failedActionIds', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'failedActionIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'failedActionIds', 0, true, length, include);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'failedActionIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  failedActionIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'failedActionIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  snapshotJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'snapshotJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  snapshotJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'snapshotJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  snapshotJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'snapshotJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  snapshotJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'snapshotJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  snapshotJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'snapshotJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  snapshotJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'snapshotJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  snapshotJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'snapshotJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  snapshotJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'snapshotJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  snapshotJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'snapshotJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  snapshotJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'snapshotJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  stateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'state', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  stateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'state', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'succeededActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'succeededActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'succeededActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'succeededActionIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'succeededActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'succeededActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'succeededActionIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsElementMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'succeededActionIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'succeededActionIds', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'succeededActionIds', value: ''),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'succeededActionIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'succeededActionIds', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'succeededActionIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'succeededActionIds', 0, true, length, include);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'succeededActionIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  succeededActionIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'succeededActionIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  undoneAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'undoneAtMs'),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  undoneAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'undoneAtMs'),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  undoneAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'undoneAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  undoneAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'undoneAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  undoneAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'undoneAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  undoneAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'undoneAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterFilterCondition>
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

extension IsarAiActionBatchQueryObject
    on QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QFilterCondition> {}

extension IsarAiActionBatchQueryLinks
    on QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QFilterCondition> {}

extension IsarAiActionBatchQuerySortBy
    on QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QSortBy> {
  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByActionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByActionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortBySnapshotJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortBySnapshotJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByUndoneAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'undoneAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByUndoneAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'undoneAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarAiActionBatchQuerySortThenBy
    on QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QSortThenBy> {
  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByActionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByActionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByBatchId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByBatchIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'batchId', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenBySnapshotJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenBySnapshotJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByUndoneAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'undoneAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByUndoneAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'undoneAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarAiActionBatchQueryWhereDistinct
    on QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QDistinct> {
  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QDistinct>
  distinctByActionsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actionsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QDistinct>
  distinctByBatchId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'batchId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QDistinct>
  distinctByFailedActionIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failedActionIds');
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QDistinct>
  distinctBySnapshotJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'snapshotJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QDistinct>
  distinctByState({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'state', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QDistinct>
  distinctBySucceededActionIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'succeededActionIds');
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QDistinct>
  distinctByUndoneAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'undoneAtMs');
    });
  }

  QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarAiActionBatchQueryProperty
    on QueryBuilder<IsarAiActionBatch, IsarAiActionBatch, QQueryProperty> {
  QueryBuilder<IsarAiActionBatch, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarAiActionBatch, String, QQueryOperations>
  actionsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actionsJson');
    });
  }

  QueryBuilder<IsarAiActionBatch, String, QQueryOperations> batchIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'batchId');
    });
  }

  QueryBuilder<IsarAiActionBatch, int, QQueryOperations> createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarAiActionBatch, List<String>, QQueryOperations>
  failedActionIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failedActionIds');
    });
  }

  QueryBuilder<IsarAiActionBatch, String, QQueryOperations>
  snapshotJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snapshotJson');
    });
  }

  QueryBuilder<IsarAiActionBatch, String, QQueryOperations> stateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'state');
    });
  }

  QueryBuilder<IsarAiActionBatch, List<String>, QQueryOperations>
  succeededActionIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'succeededActionIds');
    });
  }

  QueryBuilder<IsarAiActionBatch, int?, QQueryOperations> undoneAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'undoneAtMs');
    });
  }

  QueryBuilder<IsarAiActionBatch, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
