// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_scheduled_time_block.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarScheduledTimeBlockCollection on Isar {
  IsarCollection<IsarScheduledTimeBlock> get isarScheduledTimeBlocks =>
      this.collection();
}

const IsarScheduledTimeBlockSchema = CollectionSchema(
  name: r'IsarScheduledTimeBlock',
  id: -3571937354928469015,
  properties: {
    r'allowOverlapOverride': PropertySchema(
      id: 0,
      name: r'allowOverlapOverride',
      type: IsarType.bool,
    ),
    r'blockId': PropertySchema(id: 1, name: r'blockId', type: IsarType.string),
    r'computedEndAtMs': PropertySchema(
      id: 2,
      name: r'computedEndAtMs',
      type: IsarType.long,
    ),
    r'createdAtMs': PropertySchema(
      id: 3,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'entityId': PropertySchema(
      id: 4,
      name: r'entityId',
      type: IsarType.string,
    ),
    r'entityKind': PropertySchema(
      id: 5,
      name: r'entityKind',
      type: IsarType.string,
    ),
    r'expectedDurationMinutes': PropertySchema(
      id: 6,
      name: r'expectedDurationMinutes',
      type: IsarType.long,
    ),
    r'flexibilityType': PropertySchema(
      id: 7,
      name: r'flexibilityType',
      type: IsarType.string,
    ),
    r'importance': PropertySchema(
      id: 8,
      name: r'importance',
      type: IsarType.long,
    ),
    r'payloadJson': PropertySchema(
      id: 9,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 10,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'startAtMs': PropertySchema(
      id: 11,
      name: r'startAtMs',
      type: IsarType.long,
    ),
    r'updatedAtMs': PropertySchema(
      id: 12,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarScheduledTimeBlockEstimateSize,
  serialize: _isarScheduledTimeBlockSerialize,
  deserialize: _isarScheduledTimeBlockDeserialize,
  deserializeProp: _isarScheduledTimeBlockDeserializeProp,
  idName: r'id',
  indexes: {
    r'blockId': IndexSchema(
      id: -413886092950911832,
      name: r'blockId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'blockId',
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
    r'startAtMs': IndexSchema(
      id: 1947653327722226078,
      name: r'startAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'startAtMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'computedEndAtMs': IndexSchema(
      id: -1632174962571888278,
      name: r'computedEndAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'computedEndAtMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarScheduledTimeBlockGetId,
  getLinks: _isarScheduledTimeBlockGetLinks,
  attach: _isarScheduledTimeBlockAttach,
  version: '3.3.2',
);

int _isarScheduledTimeBlockEstimateSize(
  IsarScheduledTimeBlock object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.blockId.length * 3;
  bytesCount += 3 + object.entityId.length * 3;
  bytesCount += 3 + object.entityKind.length * 3;
  bytesCount += 3 + object.flexibilityType.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  return bytesCount;
}

void _isarScheduledTimeBlockSerialize(
  IsarScheduledTimeBlock object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.allowOverlapOverride);
  writer.writeString(offsets[1], object.blockId);
  writer.writeLong(offsets[2], object.computedEndAtMs);
  writer.writeLong(offsets[3], object.createdAtMs);
  writer.writeString(offsets[4], object.entityId);
  writer.writeString(offsets[5], object.entityKind);
  writer.writeLong(offsets[6], object.expectedDurationMinutes);
  writer.writeString(offsets[7], object.flexibilityType);
  writer.writeLong(offsets[8], object.importance);
  writer.writeString(offsets[9], object.payloadJson);
  writer.writeLong(offsets[10], object.schemaVersion);
  writer.writeLong(offsets[11], object.startAtMs);
  writer.writeLong(offsets[12], object.updatedAtMs);
}

IsarScheduledTimeBlock _isarScheduledTimeBlockDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarScheduledTimeBlock();
  object.allowOverlapOverride = reader.readBool(offsets[0]);
  object.blockId = reader.readString(offsets[1]);
  object.computedEndAtMs = reader.readLong(offsets[2]);
  object.createdAtMs = reader.readLong(offsets[3]);
  object.entityId = reader.readString(offsets[4]);
  object.entityKind = reader.readString(offsets[5]);
  object.expectedDurationMinutes = reader.readLong(offsets[6]);
  object.flexibilityType = reader.readString(offsets[7]);
  object.id = id;
  object.importance = reader.readLong(offsets[8]);
  object.payloadJson = reader.readString(offsets[9]);
  object.schemaVersion = reader.readLong(offsets[10]);
  object.startAtMs = reader.readLong(offsets[11]);
  object.updatedAtMs = reader.readLong(offsets[12]);
  return object;
}

P _isarScheduledTimeBlockDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarScheduledTimeBlockGetId(IsarScheduledTimeBlock object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarScheduledTimeBlockGetLinks(
  IsarScheduledTimeBlock object,
) {
  return [];
}

void _isarScheduledTimeBlockAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarScheduledTimeBlock object,
) {
  object.id = id;
}

extension IsarScheduledTimeBlockByIndex
    on IsarCollection<IsarScheduledTimeBlock> {
  Future<IsarScheduledTimeBlock?> getByBlockId(String blockId) {
    return getByIndex(r'blockId', [blockId]);
  }

  IsarScheduledTimeBlock? getByBlockIdSync(String blockId) {
    return getByIndexSync(r'blockId', [blockId]);
  }

  Future<bool> deleteByBlockId(String blockId) {
    return deleteByIndex(r'blockId', [blockId]);
  }

  bool deleteByBlockIdSync(String blockId) {
    return deleteByIndexSync(r'blockId', [blockId]);
  }

  Future<List<IsarScheduledTimeBlock?>> getAllByBlockId(
    List<String> blockIdValues,
  ) {
    final values = blockIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'blockId', values);
  }

  List<IsarScheduledTimeBlock?> getAllByBlockIdSync(
    List<String> blockIdValues,
  ) {
    final values = blockIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'blockId', values);
  }

  Future<int> deleteAllByBlockId(List<String> blockIdValues) {
    final values = blockIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'blockId', values);
  }

  int deleteAllByBlockIdSync(List<String> blockIdValues) {
    final values = blockIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'blockId', values);
  }

  Future<Id> putByBlockId(IsarScheduledTimeBlock object) {
    return putByIndex(r'blockId', object);
  }

  Id putByBlockIdSync(IsarScheduledTimeBlock object, {bool saveLinks = true}) {
    return putByIndexSync(r'blockId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBlockId(List<IsarScheduledTimeBlock> objects) {
    return putAllByIndex(r'blockId', objects);
  }

  List<Id> putAllByBlockIdSync(
    List<IsarScheduledTimeBlock> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'blockId', objects, saveLinks: saveLinks);
  }
}

extension IsarScheduledTimeBlockQueryWhereSort
    on QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QWhere> {
  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterWhere>
  anyStartAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'startAtMs'),
      );
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterWhere>
  anyComputedEndAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'computedEndAtMs'),
      );
    });
  }
}

extension IsarScheduledTimeBlockQueryWhere
    on
        QueryBuilder<
          IsarScheduledTimeBlock,
          IsarScheduledTimeBlock,
          QWhereClause
        > {
  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  blockIdEqualTo(String blockId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'blockId', value: [blockId]),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  blockIdNotEqualTo(String blockId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockId',
                lower: [],
                upper: [blockId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockId',
                lower: [blockId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockId',
                lower: [blockId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockId',
                lower: [],
                upper: [blockId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  startAtMsEqualTo(int startAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'startAtMs', value: [startAtMs]),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  startAtMsNotEqualTo(int startAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startAtMs',
                lower: [],
                upper: [startAtMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startAtMs',
                lower: [startAtMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startAtMs',
                lower: [startAtMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startAtMs',
                lower: [],
                upper: [startAtMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  startAtMsGreaterThan(int startAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startAtMs',
          lower: [startAtMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  startAtMsLessThan(int startAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startAtMs',
          lower: [],
          upper: [startAtMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  startAtMsBetween(
    int lowerStartAtMs,
    int upperStartAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startAtMs',
          lower: [lowerStartAtMs],
          includeLower: includeLower,
          upper: [upperStartAtMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  computedEndAtMsEqualTo(int computedEndAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'computedEndAtMs',
          value: [computedEndAtMs],
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  computedEndAtMsNotEqualTo(int computedEndAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'computedEndAtMs',
                lower: [],
                upper: [computedEndAtMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'computedEndAtMs',
                lower: [computedEndAtMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'computedEndAtMs',
                lower: [computedEndAtMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'computedEndAtMs',
                lower: [],
                upper: [computedEndAtMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  computedEndAtMsGreaterThan(int computedEndAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'computedEndAtMs',
          lower: [computedEndAtMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  computedEndAtMsLessThan(int computedEndAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'computedEndAtMs',
          lower: [],
          upper: [computedEndAtMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterWhereClause
  >
  computedEndAtMsBetween(
    int lowerComputedEndAtMs,
    int upperComputedEndAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'computedEndAtMs',
          lower: [lowerComputedEndAtMs],
          includeLower: includeLower,
          upper: [upperComputedEndAtMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarScheduledTimeBlockQueryFilter
    on
        QueryBuilder<
          IsarScheduledTimeBlock,
          IsarScheduledTimeBlock,
          QFilterCondition
        > {
  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  allowOverlapOverrideEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'allowOverlapOverride',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  blockIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  blockIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  blockIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  blockIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'blockId',
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  blockIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  blockIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  blockIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'blockId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  blockIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'blockId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  blockIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'blockId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  blockIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'blockId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  computedEndAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'computedEndAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  computedEndAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'computedEndAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  computedEndAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'computedEndAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  computedEndAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'computedEndAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  expectedDurationMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'expectedDurationMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  expectedDurationMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'expectedDurationMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  expectedDurationMinutesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'expectedDurationMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  expectedDurationMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'expectedDurationMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  flexibilityTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'flexibilityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  flexibilityTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'flexibilityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  flexibilityTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'flexibilityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  flexibilityTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'flexibilityType',
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  flexibilityTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'flexibilityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  flexibilityTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'flexibilityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  flexibilityTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'flexibilityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  flexibilityTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'flexibilityType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  flexibilityTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'flexibilityType', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  flexibilityTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'flexibilityType', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  importanceEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'importance', value: value),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  importanceGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'importance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  importanceLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'importance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  importanceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'importance',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  startAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  startAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  startAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
    QAfterFilterCondition
  >
  startAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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
    IsarScheduledTimeBlock,
    IsarScheduledTimeBlock,
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

extension IsarScheduledTimeBlockQueryObject
    on
        QueryBuilder<
          IsarScheduledTimeBlock,
          IsarScheduledTimeBlock,
          QFilterCondition
        > {}

extension IsarScheduledTimeBlockQueryLinks
    on
        QueryBuilder<
          IsarScheduledTimeBlock,
          IsarScheduledTimeBlock,
          QFilterCondition
        > {}

extension IsarScheduledTimeBlockQuerySortBy
    on QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QSortBy> {
  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByAllowOverlapOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowOverlapOverride', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByAllowOverlapOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowOverlapOverride', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByBlockId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByBlockIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByComputedEndAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedEndAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByComputedEndAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedEndAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByEntityKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByEntityKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByExpectedDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDurationMinutes', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByExpectedDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDurationMinutes', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByFlexibilityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flexibilityType', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByFlexibilityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flexibilityType', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByImportance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importance', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByImportanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importance', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByStartAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByStartAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarScheduledTimeBlockQuerySortThenBy
    on
        QueryBuilder<
          IsarScheduledTimeBlock,
          IsarScheduledTimeBlock,
          QSortThenBy
        > {
  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByAllowOverlapOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowOverlapOverride', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByAllowOverlapOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowOverlapOverride', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByBlockId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByBlockIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByComputedEndAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedEndAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByComputedEndAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedEndAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByEntityKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByEntityKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKind', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByExpectedDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDurationMinutes', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByExpectedDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDurationMinutes', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByFlexibilityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flexibilityType', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByFlexibilityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flexibilityType', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByImportance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importance', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByImportanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importance', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByStartAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByStartAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarScheduledTimeBlockQueryWhereDistinct
    on QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct> {
  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByAllowOverlapOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowOverlapOverride');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByBlockId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByComputedEndAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'computedEndAtMs');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByEntityId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByEntityKind({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityKind', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByExpectedDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expectedDurationMinutes');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByFlexibilityType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'flexibilityType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByImportance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'importance');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByStartAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startAtMs');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, IsarScheduledTimeBlock, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarScheduledTimeBlockQueryProperty
    on
        QueryBuilder<
          IsarScheduledTimeBlock,
          IsarScheduledTimeBlock,
          QQueryProperty
        > {
  QueryBuilder<IsarScheduledTimeBlock, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, bool, QQueryOperations>
  allowOverlapOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowOverlapOverride');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, String, QQueryOperations>
  blockIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockId');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, int, QQueryOperations>
  computedEndAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'computedEndAtMs');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, int, QQueryOperations>
  createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, String, QQueryOperations>
  entityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityId');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, String, QQueryOperations>
  entityKindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityKind');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, int, QQueryOperations>
  expectedDurationMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expectedDurationMinutes');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, String, QQueryOperations>
  flexibilityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flexibilityType');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, int, QQueryOperations>
  importanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'importance');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, String, QQueryOperations>
  payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, int, QQueryOperations>
  schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, int, QQueryOperations>
  startAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startAtMs');
    });
  }

  QueryBuilder<IsarScheduledTimeBlock, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
