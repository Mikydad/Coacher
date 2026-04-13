// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_block.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarBlockCollection on Isar {
  IsarCollection<IsarBlock> get isarBlocks => this.collection();
}

const IsarBlockSchema = CollectionSchema(
  name: r'IsarBlock',
  id: 1091908912106400045,
  properties: {
    r'blockId': PropertySchema(
      id: 0,
      name: r'blockId',
      type: IsarType.string,
    ),
    r'createdAtMs': PropertySchema(
      id: 1,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'endMinutesFromMidnight': PropertySchema(
      id: 2,
      name: r'endMinutesFromMidnight',
      type: IsarType.long,
    ),
    r'modeRefId': PropertySchema(
      id: 3,
      name: r'modeRefId',
      type: IsarType.string,
    ),
    r'orderIndex': PropertySchema(
      id: 4,
      name: r'orderIndex',
      type: IsarType.long,
    ),
    r'routineId': PropertySchema(
      id: 5,
      name: r'routineId',
      type: IsarType.string,
    ),
    r'startMinutesFromMidnight': PropertySchema(
      id: 6,
      name: r'startMinutesFromMidnight',
      type: IsarType.long,
    ),
    r'title': PropertySchema(
      id: 7,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 8,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
    r'urgencyScore': PropertySchema(
      id: 9,
      name: r'urgencyScore',
      type: IsarType.long,
    )
  },
  estimateSize: _isarBlockEstimateSize,
  serialize: _isarBlockSerialize,
  deserialize: _isarBlockDeserialize,
  deserializeProp: _isarBlockDeserializeProp,
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
        )
      ],
    ),
    r'routineId': IndexSchema(
      id: -7971259615846791236,
      name: r'routineId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'routineId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarBlockGetId,
  getLinks: _isarBlockGetLinks,
  attach: _isarBlockAttach,
  version: '3.1.0+1',
);

int _isarBlockEstimateSize(
  IsarBlock object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.blockId.length * 3;
  {
    final value = object.modeRefId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.routineId.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _isarBlockSerialize(
  IsarBlock object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.blockId);
  writer.writeLong(offsets[1], object.createdAtMs);
  writer.writeLong(offsets[2], object.endMinutesFromMidnight);
  writer.writeString(offsets[3], object.modeRefId);
  writer.writeLong(offsets[4], object.orderIndex);
  writer.writeString(offsets[5], object.routineId);
  writer.writeLong(offsets[6], object.startMinutesFromMidnight);
  writer.writeString(offsets[7], object.title);
  writer.writeLong(offsets[8], object.updatedAtMs);
  writer.writeLong(offsets[9], object.urgencyScore);
}

IsarBlock _isarBlockDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarBlock();
  object.blockId = reader.readString(offsets[0]);
  object.createdAtMs = reader.readLong(offsets[1]);
  object.endMinutesFromMidnight = reader.readLongOrNull(offsets[2]);
  object.id = id;
  object.modeRefId = reader.readStringOrNull(offsets[3]);
  object.orderIndex = reader.readLong(offsets[4]);
  object.routineId = reader.readString(offsets[5]);
  object.startMinutesFromMidnight = reader.readLongOrNull(offsets[6]);
  object.title = reader.readString(offsets[7]);
  object.updatedAtMs = reader.readLong(offsets[8]);
  object.urgencyScore = reader.readLong(offsets[9]);
  return object;
}

P _isarBlockDeserializeProp<P>(
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
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarBlockGetId(IsarBlock object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarBlockGetLinks(IsarBlock object) {
  return [];
}

void _isarBlockAttach(IsarCollection<dynamic> col, Id id, IsarBlock object) {
  object.id = id;
}

extension IsarBlockByIndex on IsarCollection<IsarBlock> {
  Future<IsarBlock?> getByBlockId(String blockId) {
    return getByIndex(r'blockId', [blockId]);
  }

  IsarBlock? getByBlockIdSync(String blockId) {
    return getByIndexSync(r'blockId', [blockId]);
  }

  Future<bool> deleteByBlockId(String blockId) {
    return deleteByIndex(r'blockId', [blockId]);
  }

  bool deleteByBlockIdSync(String blockId) {
    return deleteByIndexSync(r'blockId', [blockId]);
  }

  Future<List<IsarBlock?>> getAllByBlockId(List<String> blockIdValues) {
    final values = blockIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'blockId', values);
  }

  List<IsarBlock?> getAllByBlockIdSync(List<String> blockIdValues) {
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

  Future<Id> putByBlockId(IsarBlock object) {
    return putByIndex(r'blockId', object);
  }

  Id putByBlockIdSync(IsarBlock object, {bool saveLinks = true}) {
    return putByIndexSync(r'blockId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBlockId(List<IsarBlock> objects) {
    return putAllByIndex(r'blockId', objects);
  }

  List<Id> putAllByBlockIdSync(List<IsarBlock> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'blockId', objects, saveLinks: saveLinks);
  }
}

extension IsarBlockQueryWhereSort
    on QueryBuilder<IsarBlock, IsarBlock, QWhere> {
  QueryBuilder<IsarBlock, IsarBlock, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarBlockQueryWhere
    on QueryBuilder<IsarBlock, IsarBlock, QWhereClause> {
  QueryBuilder<IsarBlock, IsarBlock, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<IsarBlock, IsarBlock, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarBlock, IsarBlock, QAfterWhereClause> blockIdEqualTo(
      String blockId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'blockId',
        value: [blockId],
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterWhereClause> blockIdNotEqualTo(
      String blockId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'blockId',
              lower: [],
              upper: [blockId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'blockId',
              lower: [blockId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'blockId',
              lower: [blockId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'blockId',
              lower: [],
              upper: [blockId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterWhereClause> routineIdEqualTo(
      String routineId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'routineId',
        value: [routineId],
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterWhereClause> routineIdNotEqualTo(
      String routineId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'routineId',
              lower: [],
              upper: [routineId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'routineId',
              lower: [routineId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'routineId',
              lower: [routineId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'routineId',
              lower: [],
              upper: [routineId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarBlockQueryFilter
    on QueryBuilder<IsarBlock, IsarBlock, QFilterCondition> {
  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> blockIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> blockIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blockId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> blockIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blockId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> blockIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blockId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> blockIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'blockId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> blockIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'blockId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> blockIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'blockId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> blockIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'blockId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> blockIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      blockIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'blockId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> createdAtMsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
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

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> createdAtMsLessThan(
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

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> createdAtMsBetween(
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

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      endMinutesFromMidnightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endMinutesFromMidnight',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      endMinutesFromMidnightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endMinutesFromMidnight',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      endMinutesFromMidnightEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endMinutesFromMidnight',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      endMinutesFromMidnightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endMinutesFromMidnight',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      endMinutesFromMidnightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endMinutesFromMidnight',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      endMinutesFromMidnightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endMinutesFromMidnight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> modeRefIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'modeRefId',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      modeRefIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'modeRefId',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> modeRefIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      modeRefIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> modeRefIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> modeRefIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modeRefId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> modeRefIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> modeRefIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> modeRefIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> modeRefIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modeRefId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> modeRefIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modeRefId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      modeRefIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modeRefId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> orderIndexEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      orderIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> orderIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> orderIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> routineIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'routineId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      routineIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'routineId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> routineIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'routineId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> routineIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'routineId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> routineIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'routineId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> routineIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'routineId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> routineIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'routineId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> routineIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'routineId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> routineIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'routineId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      routineIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'routineId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      startMinutesFromMidnightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startMinutesFromMidnight',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      startMinutesFromMidnightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startMinutesFromMidnight',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      startMinutesFromMidnightEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startMinutesFromMidnight',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      startMinutesFromMidnightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startMinutesFromMidnight',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      startMinutesFromMidnightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startMinutesFromMidnight',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      startMinutesFromMidnightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startMinutesFromMidnight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> updatedAtMsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
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

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> updatedAtMsLessThan(
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

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> updatedAtMsBetween(
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

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> urgencyScoreEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'urgencyScore',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      urgencyScoreGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'urgencyScore',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition>
      urgencyScoreLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'urgencyScore',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterFilterCondition> urgencyScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'urgencyScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarBlockQueryObject
    on QueryBuilder<IsarBlock, IsarBlock, QFilterCondition> {}

extension IsarBlockQueryLinks
    on QueryBuilder<IsarBlock, IsarBlock, QFilterCondition> {}

extension IsarBlockQuerySortBy on QueryBuilder<IsarBlock, IsarBlock, QSortBy> {
  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByBlockId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByBlockIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy>
      sortByEndMinutesFromMidnight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutesFromMidnight', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy>
      sortByEndMinutesFromMidnightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutesFromMidnight', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByModeRefId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByModeRefIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByRoutineId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineId', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByRoutineIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineId', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy>
      sortByStartMinutesFromMidnight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutesFromMidnight', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy>
      sortByStartMinutesFromMidnightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutesFromMidnight', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByUrgencyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'urgencyScore', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> sortByUrgencyScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'urgencyScore', Sort.desc);
    });
  }
}

extension IsarBlockQuerySortThenBy
    on QueryBuilder<IsarBlock, IsarBlock, QSortThenBy> {
  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByBlockId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByBlockIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockId', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy>
      thenByEndMinutesFromMidnight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutesFromMidnight', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy>
      thenByEndMinutesFromMidnightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutesFromMidnight', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByModeRefId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByModeRefIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByRoutineId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineId', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByRoutineIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineId', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy>
      thenByStartMinutesFromMidnight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutesFromMidnight', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy>
      thenByStartMinutesFromMidnightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutesFromMidnight', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByUrgencyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'urgencyScore', Sort.asc);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QAfterSortBy> thenByUrgencyScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'urgencyScore', Sort.desc);
    });
  }
}

extension IsarBlockQueryWhereDistinct
    on QueryBuilder<IsarBlock, IsarBlock, QDistinct> {
  QueryBuilder<IsarBlock, IsarBlock, QDistinct> distinctByBlockId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QDistinct> distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QDistinct>
      distinctByEndMinutesFromMidnight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endMinutesFromMidnight');
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QDistinct> distinctByModeRefId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modeRefId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QDistinct> distinctByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderIndex');
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QDistinct> distinctByRoutineId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'routineId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QDistinct>
      distinctByStartMinutesFromMidnight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startMinutesFromMidnight');
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QDistinct> distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }

  QueryBuilder<IsarBlock, IsarBlock, QDistinct> distinctByUrgencyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'urgencyScore');
    });
  }
}

extension IsarBlockQueryProperty
    on QueryBuilder<IsarBlock, IsarBlock, QQueryProperty> {
  QueryBuilder<IsarBlock, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarBlock, String, QQueryOperations> blockIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockId');
    });
  }

  QueryBuilder<IsarBlock, int, QQueryOperations> createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarBlock, int?, QQueryOperations>
      endMinutesFromMidnightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endMinutesFromMidnight');
    });
  }

  QueryBuilder<IsarBlock, String?, QQueryOperations> modeRefIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modeRefId');
    });
  }

  QueryBuilder<IsarBlock, int, QQueryOperations> orderIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderIndex');
    });
  }

  QueryBuilder<IsarBlock, String, QQueryOperations> routineIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'routineId');
    });
  }

  QueryBuilder<IsarBlock, int?, QQueryOperations>
      startMinutesFromMidnightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startMinutesFromMidnight');
    });
  }

  QueryBuilder<IsarBlock, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<IsarBlock, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }

  QueryBuilder<IsarBlock, int, QQueryOperations> urgencyScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'urgencyScore');
    });
  }
}
