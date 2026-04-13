// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_routine.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarRoutineCollection on Isar {
  IsarCollection<IsarRoutine> get isarRoutines => this.collection();
}

const IsarRoutineSchema = CollectionSchema(
  name: r'IsarRoutine',
  id: -6773196286720765320,
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
    r'modeId': PropertySchema(
      id: 2,
      name: r'modeId',
      type: IsarType.string,
    ),
    r'modeStorage': PropertySchema(
      id: 3,
      name: r'modeStorage',
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
    r'title': PropertySchema(
      id: 6,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 7,
      name: r'updatedAtMs',
      type: IsarType.long,
    )
  },
  estimateSize: _isarRoutineEstimateSize,
  serialize: _isarRoutineSerialize,
  deserialize: _isarRoutineDeserialize,
  deserializeProp: _isarRoutineDeserializeProp,
  idName: r'id',
  indexes: {
    r'routineId': IndexSchema(
      id: -7971259615846791236,
      name: r'routineId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'routineId',
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarRoutineGetId,
  getLinks: _isarRoutineGetLinks,
  attach: _isarRoutineAttach,
  version: '3.1.0+1',
);

int _isarRoutineEstimateSize(
  IsarRoutine object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  bytesCount += 3 + object.modeId.length * 3;
  bytesCount += 3 + object.modeStorage.length * 3;
  bytesCount += 3 + object.routineId.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _isarRoutineSerialize(
  IsarRoutine object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.createdAtMs);
  writer.writeString(offsets[1], object.dateKey);
  writer.writeString(offsets[2], object.modeId);
  writer.writeString(offsets[3], object.modeStorage);
  writer.writeLong(offsets[4], object.orderIndex);
  writer.writeString(offsets[5], object.routineId);
  writer.writeString(offsets[6], object.title);
  writer.writeLong(offsets[7], object.updatedAtMs);
}

IsarRoutine _isarRoutineDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarRoutine();
  object.createdAtMs = reader.readLong(offsets[0]);
  object.dateKey = reader.readString(offsets[1]);
  object.id = id;
  object.modeId = reader.readString(offsets[2]);
  object.modeStorage = reader.readString(offsets[3]);
  object.orderIndex = reader.readLong(offsets[4]);
  object.routineId = reader.readString(offsets[5]);
  object.title = reader.readString(offsets[6]);
  object.updatedAtMs = reader.readLong(offsets[7]);
  return object;
}

P _isarRoutineDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarRoutineGetId(IsarRoutine object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarRoutineGetLinks(IsarRoutine object) {
  return [];
}

void _isarRoutineAttach(
    IsarCollection<dynamic> col, Id id, IsarRoutine object) {
  object.id = id;
}

extension IsarRoutineByIndex on IsarCollection<IsarRoutine> {
  Future<IsarRoutine?> getByRoutineId(String routineId) {
    return getByIndex(r'routineId', [routineId]);
  }

  IsarRoutine? getByRoutineIdSync(String routineId) {
    return getByIndexSync(r'routineId', [routineId]);
  }

  Future<bool> deleteByRoutineId(String routineId) {
    return deleteByIndex(r'routineId', [routineId]);
  }

  bool deleteByRoutineIdSync(String routineId) {
    return deleteByIndexSync(r'routineId', [routineId]);
  }

  Future<List<IsarRoutine?>> getAllByRoutineId(List<String> routineIdValues) {
    final values = routineIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'routineId', values);
  }

  List<IsarRoutine?> getAllByRoutineIdSync(List<String> routineIdValues) {
    final values = routineIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'routineId', values);
  }

  Future<int> deleteAllByRoutineId(List<String> routineIdValues) {
    final values = routineIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'routineId', values);
  }

  int deleteAllByRoutineIdSync(List<String> routineIdValues) {
    final values = routineIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'routineId', values);
  }

  Future<Id> putByRoutineId(IsarRoutine object) {
    return putByIndex(r'routineId', object);
  }

  Id putByRoutineIdSync(IsarRoutine object, {bool saveLinks = true}) {
    return putByIndexSync(r'routineId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRoutineId(List<IsarRoutine> objects) {
    return putAllByIndex(r'routineId', objects);
  }

  List<Id> putAllByRoutineIdSync(List<IsarRoutine> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'routineId', objects, saveLinks: saveLinks);
  }
}

extension IsarRoutineQueryWhereSort
    on QueryBuilder<IsarRoutine, IsarRoutine, QWhere> {
  QueryBuilder<IsarRoutine, IsarRoutine, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarRoutineQueryWhere
    on QueryBuilder<IsarRoutine, IsarRoutine, QWhereClause> {
  QueryBuilder<IsarRoutine, IsarRoutine, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterWhereClause> routineIdEqualTo(
      String routineId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'routineId',
        value: [routineId],
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterWhereClause> routineIdNotEqualTo(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterWhereClause> dateKeyEqualTo(
      String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [dateKey],
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterWhereClause> dateKeyNotEqualTo(
      String dateKey) {
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
}

extension IsarRoutineQueryFilter
    on QueryBuilder<IsarRoutine, IsarRoutine, QFilterCondition> {
  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> dateKeyEqualTo(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> dateKeyLessThan(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> dateKeyBetween(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> dateKeyEndsWith(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> dateKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> dateKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> modeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> modeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> modeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> modeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> modeIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> modeIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modeId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modeId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeStorageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modeStorage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeStorageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeStorageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modeStorage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modeStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      modeStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modeStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      orderIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      orderIndexLessThan(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      orderIndexBetween(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      routineIdEqualTo(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      routineIdLessThan(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      routineIdBetween(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      routineIdStartsWith(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      routineIdEndsWith(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      routineIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'routineId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      routineIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'routineId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      routineIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'routineId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      routineIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'routineId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> titleEqualTo(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      titleGreaterThan(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> titleLessThan(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> titleBetween(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> titleStartsWith(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> titleEndsWith(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> titleContains(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> titleMatches(
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
      updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
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

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterFilterCondition>
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

extension IsarRoutineQueryObject
    on QueryBuilder<IsarRoutine, IsarRoutine, QFilterCondition> {}

extension IsarRoutineQueryLinks
    on QueryBuilder<IsarRoutine, IsarRoutine, QFilterCondition> {}

extension IsarRoutineQuerySortBy
    on QueryBuilder<IsarRoutine, IsarRoutine, QSortBy> {
  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByModeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeId', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByModeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeId', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByModeStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByModeStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByRoutineId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineId', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByRoutineIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineId', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarRoutineQuerySortThenBy
    on QueryBuilder<IsarRoutine, IsarRoutine, QSortThenBy> {
  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByModeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeId', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByModeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeId', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByModeStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByModeStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByRoutineId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineId', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByRoutineIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'routineId', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QAfterSortBy> thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarRoutineQueryWhereDistinct
    on QueryBuilder<IsarRoutine, IsarRoutine, QDistinct> {
  QueryBuilder<IsarRoutine, IsarRoutine, QDistinct> distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QDistinct> distinctByDateKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QDistinct> distinctByModeId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QDistinct> distinctByModeStorage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modeStorage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QDistinct> distinctByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderIndex');
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QDistinct> distinctByRoutineId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'routineId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarRoutine, IsarRoutine, QDistinct> distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarRoutineQueryProperty
    on QueryBuilder<IsarRoutine, IsarRoutine, QQueryProperty> {
  QueryBuilder<IsarRoutine, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarRoutine, int, QQueryOperations> createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarRoutine, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<IsarRoutine, String, QQueryOperations> modeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modeId');
    });
  }

  QueryBuilder<IsarRoutine, String, QQueryOperations> modeStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modeStorage');
    });
  }

  QueryBuilder<IsarRoutine, int, QQueryOperations> orderIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderIndex');
    });
  }

  QueryBuilder<IsarRoutine, String, QQueryOperations> routineIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'routineId');
    });
  }

  QueryBuilder<IsarRoutine, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<IsarRoutine, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
