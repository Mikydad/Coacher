// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_goal.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarGoalCollection on Isar {
  IsarCollection<IsarGoal> get isarGoals => this.collection();
}

const IsarGoalSchema = CollectionSchema(
  name: r'IsarGoal',
  id: -4348511956834917587,
  properties: {
    r'categoryId': PropertySchema(
      id: 0,
      name: r'categoryId',
      type: IsarType.string,
    ),
    r'createdAtMs': PropertySchema(
      id: 1,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'customLabel': PropertySchema(
      id: 2,
      name: r'customLabel',
      type: IsarType.string,
    ),
    r'durationDays': PropertySchema(
      id: 3,
      name: r'durationDays',
      type: IsarType.long,
    ),
    r'goalId': PropertySchema(
      id: 4,
      name: r'goalId',
      type: IsarType.string,
    ),
    r'horizonStorage': PropertySchema(
      id: 5,
      name: r'horizonStorage',
      type: IsarType.string,
    ),
    r'intensity': PropertySchema(
      id: 6,
      name: r'intensity',
      type: IsarType.long,
    ),
    r'measurementKindStorage': PropertySchema(
      id: 7,
      name: r'measurementKindStorage',
      type: IsarType.string,
    ),
    r'periodEndMs': PropertySchema(
      id: 8,
      name: r'periodEndMs',
      type: IsarType.long,
    ),
    r'periodModeStorage': PropertySchema(
      id: 9,
      name: r'periodModeStorage',
      type: IsarType.string,
    ),
    r'periodStartMs': PropertySchema(
      id: 10,
      name: r'periodStartMs',
      type: IsarType.long,
    ),
    r'reminderEnabled': PropertySchema(
      id: 11,
      name: r'reminderEnabled',
      type: IsarType.bool,
    ),
    r'reminderMinutesFromMidnight': PropertySchema(
      id: 12,
      name: r'reminderMinutesFromMidnight',
      type: IsarType.long,
    ),
    r'reminderStyleStorage': PropertySchema(
      id: 13,
      name: r'reminderStyleStorage',
      type: IsarType.string,
    ),
    r'statusStorage': PropertySchema(
      id: 14,
      name: r'statusStorage',
      type: IsarType.string,
    ),
    r'targetValue': PropertySchema(
      id: 15,
      name: r'targetValue',
      type: IsarType.double,
    ),
    r'title': PropertySchema(
      id: 16,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 17,
      name: r'updatedAtMs',
      type: IsarType.long,
    )
  },
  estimateSize: _isarGoalEstimateSize,
  serialize: _isarGoalSerialize,
  deserialize: _isarGoalDeserialize,
  deserializeProp: _isarGoalDeserializeProp,
  idName: r'id',
  indexes: {
    r'goalId': IndexSchema(
      id: 2738626632585230611,
      name: r'goalId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'goalId',
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
  getId: _isarGoalGetId,
  getLinks: _isarGoalGetLinks,
  attach: _isarGoalAttach,
  version: '3.1.0+1',
);

int _isarGoalEstimateSize(
  IsarGoal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.categoryId.length * 3;
  {
    final value = object.customLabel;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.goalId.length * 3;
  bytesCount += 3 + object.horizonStorage.length * 3;
  bytesCount += 3 + object.measurementKindStorage.length * 3;
  bytesCount += 3 + object.periodModeStorage.length * 3;
  bytesCount += 3 + object.reminderStyleStorage.length * 3;
  bytesCount += 3 + object.statusStorage.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _isarGoalSerialize(
  IsarGoal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.categoryId);
  writer.writeLong(offsets[1], object.createdAtMs);
  writer.writeString(offsets[2], object.customLabel);
  writer.writeLong(offsets[3], object.durationDays);
  writer.writeString(offsets[4], object.goalId);
  writer.writeString(offsets[5], object.horizonStorage);
  writer.writeLong(offsets[6], object.intensity);
  writer.writeString(offsets[7], object.measurementKindStorage);
  writer.writeLong(offsets[8], object.periodEndMs);
  writer.writeString(offsets[9], object.periodModeStorage);
  writer.writeLong(offsets[10], object.periodStartMs);
  writer.writeBool(offsets[11], object.reminderEnabled);
  writer.writeLong(offsets[12], object.reminderMinutesFromMidnight);
  writer.writeString(offsets[13], object.reminderStyleStorage);
  writer.writeString(offsets[14], object.statusStorage);
  writer.writeDouble(offsets[15], object.targetValue);
  writer.writeString(offsets[16], object.title);
  writer.writeLong(offsets[17], object.updatedAtMs);
}

IsarGoal _isarGoalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarGoal();
  object.categoryId = reader.readString(offsets[0]);
  object.createdAtMs = reader.readLong(offsets[1]);
  object.customLabel = reader.readStringOrNull(offsets[2]);
  object.durationDays = reader.readLongOrNull(offsets[3]);
  object.goalId = reader.readString(offsets[4]);
  object.horizonStorage = reader.readString(offsets[5]);
  object.id = id;
  object.intensity = reader.readLong(offsets[6]);
  object.measurementKindStorage = reader.readString(offsets[7]);
  object.periodEndMs = reader.readLong(offsets[8]);
  object.periodModeStorage = reader.readString(offsets[9]);
  object.periodStartMs = reader.readLong(offsets[10]);
  object.reminderEnabled = reader.readBool(offsets[11]);
  object.reminderMinutesFromMidnight = reader.readLongOrNull(offsets[12]);
  object.reminderStyleStorage = reader.readString(offsets[13]);
  object.statusStorage = reader.readString(offsets[14]);
  object.targetValue = reader.readDouble(offsets[15]);
  object.title = reader.readString(offsets[16]);
  object.updatedAtMs = reader.readLong(offsets[17]);
  return object;
}

P _isarGoalDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
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
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarGoalGetId(IsarGoal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarGoalGetLinks(IsarGoal object) {
  return [];
}

void _isarGoalAttach(IsarCollection<dynamic> col, Id id, IsarGoal object) {
  object.id = id;
}

extension IsarGoalByIndex on IsarCollection<IsarGoal> {
  Future<IsarGoal?> getByGoalId(String goalId) {
    return getByIndex(r'goalId', [goalId]);
  }

  IsarGoal? getByGoalIdSync(String goalId) {
    return getByIndexSync(r'goalId', [goalId]);
  }

  Future<bool> deleteByGoalId(String goalId) {
    return deleteByIndex(r'goalId', [goalId]);
  }

  bool deleteByGoalIdSync(String goalId) {
    return deleteByIndexSync(r'goalId', [goalId]);
  }

  Future<List<IsarGoal?>> getAllByGoalId(List<String> goalIdValues) {
    final values = goalIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'goalId', values);
  }

  List<IsarGoal?> getAllByGoalIdSync(List<String> goalIdValues) {
    final values = goalIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'goalId', values);
  }

  Future<int> deleteAllByGoalId(List<String> goalIdValues) {
    final values = goalIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'goalId', values);
  }

  int deleteAllByGoalIdSync(List<String> goalIdValues) {
    final values = goalIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'goalId', values);
  }

  Future<Id> putByGoalId(IsarGoal object) {
    return putByIndex(r'goalId', object);
  }

  Id putByGoalIdSync(IsarGoal object, {bool saveLinks = true}) {
    return putByIndexSync(r'goalId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByGoalId(List<IsarGoal> objects) {
    return putAllByIndex(r'goalId', objects);
  }

  List<Id> putAllByGoalIdSync(List<IsarGoal> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'goalId', objects, saveLinks: saveLinks);
  }
}

extension IsarGoalQueryWhereSort on QueryBuilder<IsarGoal, IsarGoal, QWhere> {
  QueryBuilder<IsarGoal, IsarGoal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhere> anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarGoalQueryWhere on QueryBuilder<IsarGoal, IsarGoal, QWhereClause> {
  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> goalIdEqualTo(
      String goalId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'goalId',
        value: [goalId],
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> goalIdNotEqualTo(
      String goalId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalId',
              lower: [],
              upper: [goalId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalId',
              lower: [goalId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalId',
              lower: [goalId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalId',
              lower: [],
              upper: [goalId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> updatedAtMsEqualTo(
      int updatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAtMs',
        value: [updatedAtMs],
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> updatedAtMsNotEqualTo(
      int updatedAtMs) {
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> updatedAtMsGreaterThan(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> updatedAtMsLessThan(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterWhereClause> updatedAtMsBetween(
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

extension IsarGoalQueryFilter
    on QueryBuilder<IsarGoal, IsarGoal, QFilterCondition> {
  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> categoryIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> categoryIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> categoryIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> categoryIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> categoryIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> categoryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> categoryIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> categoryIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> categoryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      categoryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> createdAtMsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> createdAtMsLessThan(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> createdAtMsBetween(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> customLabelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customLabel',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      customLabelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customLabel',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> customLabelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      customLabelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> customLabelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> customLabelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customLabel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> customLabelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> customLabelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> customLabelContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> customLabelMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customLabel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> customLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      customLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> durationDaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'durationDays',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      durationDaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'durationDays',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> durationDaysEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      durationDaysGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> durationDaysLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationDays',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> durationDaysBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> goalIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> goalIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> goalIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> goalIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'goalId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> goalIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> goalIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> goalIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> goalIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'goalId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> goalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goalId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> goalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'goalId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> horizonStorageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'horizonStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      horizonStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'horizonStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      horizonStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'horizonStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> horizonStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'horizonStorage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      horizonStorageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'horizonStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      horizonStorageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'horizonStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      horizonStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'horizonStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> horizonStorageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'horizonStorage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      horizonStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'horizonStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      horizonStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'horizonStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> intensityEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intensity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> intensityGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'intensity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> intensityLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'intensity',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> intensityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'intensity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      measurementKindStorageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'measurementKindStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      measurementKindStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'measurementKindStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      measurementKindStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'measurementKindStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      measurementKindStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'measurementKindStorage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      measurementKindStorageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'measurementKindStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      measurementKindStorageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'measurementKindStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      measurementKindStorageContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'measurementKindStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      measurementKindStorageMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'measurementKindStorage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      measurementKindStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'measurementKindStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      measurementKindStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'measurementKindStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> periodEndMsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodEndMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodEndMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodEndMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> periodEndMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodEndMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> periodEndMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodEndMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodModeStorageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodModeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodModeStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodModeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodModeStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodModeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodModeStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodModeStorage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodModeStorageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'periodModeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodModeStorageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'periodModeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodModeStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'periodModeStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodModeStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'periodModeStorage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodModeStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodModeStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodModeStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'periodModeStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> periodStartMsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodStartMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      periodStartMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodStartMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> periodStartMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodStartMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> periodStartMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodStartMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reminderEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderMinutesFromMidnightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reminderMinutesFromMidnight',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderMinutesFromMidnightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reminderMinutesFromMidnight',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderMinutesFromMidnightEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reminderMinutesFromMidnight',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderMinutesFromMidnightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reminderMinutesFromMidnight',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderMinutesFromMidnightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reminderMinutesFromMidnight',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderMinutesFromMidnightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reminderMinutesFromMidnight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderStyleStorageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reminderStyleStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderStyleStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reminderStyleStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderStyleStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reminderStyleStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderStyleStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reminderStyleStorage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderStyleStorageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reminderStyleStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderStyleStorageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reminderStyleStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderStyleStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reminderStyleStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderStyleStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reminderStyleStorage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderStyleStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reminderStyleStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      reminderStyleStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reminderStyleStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> statusStorageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      statusStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statusStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> statusStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statusStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> statusStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statusStorage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      statusStorageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'statusStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> statusStorageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'statusStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> statusStorageContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'statusStorage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> statusStorageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'statusStorage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      statusStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      statusStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'statusStorage',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> targetValueEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
      targetValueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> targetValueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> targetValueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> titleEqualTo(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> titleGreaterThan(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> titleLessThan(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> titleBetween(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> titleStartsWith(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> titleEndsWith(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> titleContains(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> titleMatches(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> updatedAtMsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition>
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> updatedAtMsLessThan(
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

  QueryBuilder<IsarGoal, IsarGoal, QAfterFilterCondition> updatedAtMsBetween(
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

extension IsarGoalQueryObject
    on QueryBuilder<IsarGoal, IsarGoal, QFilterCondition> {}

extension IsarGoalQueryLinks
    on QueryBuilder<IsarGoal, IsarGoal, QFilterCondition> {}

extension IsarGoalQuerySortBy on QueryBuilder<IsarGoal, IsarGoal, QSortBy> {
  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByCustomLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customLabel', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByCustomLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customLabel', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByDurationDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationDays', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByDurationDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationDays', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByHorizonStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horizonStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByHorizonStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horizonStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByIntensity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intensity', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByIntensityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intensity', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy>
      sortByMeasurementKindStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'measurementKindStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy>
      sortByMeasurementKindStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'measurementKindStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByPeriodEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByPeriodEndMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMs', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByPeriodModeStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodModeStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByPeriodModeStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodModeStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByPeriodStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByPeriodStartMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMs', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByReminderEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy>
      sortByReminderMinutesFromMidnight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesFromMidnight', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy>
      sortByReminderMinutesFromMidnightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesFromMidnight', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByReminderStyleStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderStyleStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy>
      sortByReminderStyleStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderStyleStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByStatusStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByStatusStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarGoalQuerySortThenBy
    on QueryBuilder<IsarGoal, IsarGoal, QSortThenBy> {
  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByCustomLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customLabel', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByCustomLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customLabel', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByDurationDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationDays', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByDurationDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationDays', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByHorizonStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horizonStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByHorizonStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horizonStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByIntensity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intensity', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByIntensityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intensity', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy>
      thenByMeasurementKindStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'measurementKindStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy>
      thenByMeasurementKindStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'measurementKindStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByPeriodEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByPeriodEndMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMs', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByPeriodModeStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodModeStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByPeriodModeStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodModeStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByPeriodStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByPeriodStartMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMs', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByReminderEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderEnabled', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy>
      thenByReminderMinutesFromMidnight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesFromMidnight', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy>
      thenByReminderMinutesFromMidnightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderMinutesFromMidnight', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByReminderStyleStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderStyleStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy>
      thenByReminderStyleStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderStyleStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByStatusStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByStatusStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QAfterSortBy> thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarGoalQueryWhereDistinct
    on QueryBuilder<IsarGoal, IsarGoal, QDistinct> {
  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByCategoryId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByCustomLabel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customLabel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByDurationDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationDays');
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByGoalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goalId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByHorizonStorage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'horizonStorage',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByIntensity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intensity');
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByMeasurementKindStorage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'measurementKindStorage',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByPeriodEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodEndMs');
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByPeriodModeStorage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodModeStorage',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByPeriodStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodStartMs');
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByReminderEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderEnabled');
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct>
      distinctByReminderMinutesFromMidnight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderMinutesFromMidnight');
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByReminderStyleStorage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderStyleStorage',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByStatusStorage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statusStorage',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetValue');
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoal, IsarGoal, QDistinct> distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarGoalQueryProperty
    on QueryBuilder<IsarGoal, IsarGoal, QQueryProperty> {
  QueryBuilder<IsarGoal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarGoal, String, QQueryOperations> categoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryId');
    });
  }

  QueryBuilder<IsarGoal, int, QQueryOperations> createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarGoal, String?, QQueryOperations> customLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customLabel');
    });
  }

  QueryBuilder<IsarGoal, int?, QQueryOperations> durationDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationDays');
    });
  }

  QueryBuilder<IsarGoal, String, QQueryOperations> goalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goalId');
    });
  }

  QueryBuilder<IsarGoal, String, QQueryOperations> horizonStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'horizonStorage');
    });
  }

  QueryBuilder<IsarGoal, int, QQueryOperations> intensityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intensity');
    });
  }

  QueryBuilder<IsarGoal, String, QQueryOperations>
      measurementKindStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'measurementKindStorage');
    });
  }

  QueryBuilder<IsarGoal, int, QQueryOperations> periodEndMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodEndMs');
    });
  }

  QueryBuilder<IsarGoal, String, QQueryOperations> periodModeStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodModeStorage');
    });
  }

  QueryBuilder<IsarGoal, int, QQueryOperations> periodStartMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodStartMs');
    });
  }

  QueryBuilder<IsarGoal, bool, QQueryOperations> reminderEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderEnabled');
    });
  }

  QueryBuilder<IsarGoal, int?, QQueryOperations>
      reminderMinutesFromMidnightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderMinutesFromMidnight');
    });
  }

  QueryBuilder<IsarGoal, String, QQueryOperations>
      reminderStyleStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderStyleStorage');
    });
  }

  QueryBuilder<IsarGoal, String, QQueryOperations> statusStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statusStorage');
    });
  }

  QueryBuilder<IsarGoal, double, QQueryOperations> targetValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetValue');
    });
  }

  QueryBuilder<IsarGoal, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<IsarGoal, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
