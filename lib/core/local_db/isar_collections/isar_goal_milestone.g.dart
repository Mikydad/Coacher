// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_goal_milestone.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarGoalMilestoneCollection on Isar {
  IsarCollection<IsarGoalMilestone> get isarGoalMilestones => this.collection();
}

const IsarGoalMilestoneSchema = CollectionSchema(
  name: r'IsarGoalMilestone',
  id: 4798406987947707536,
  properties: {
    r'completed': PropertySchema(
      id: 0,
      name: r'completed',
      type: IsarType.bool,
    ),
    r'goalId': PropertySchema(id: 1, name: r'goalId', type: IsarType.string),
    r'milestoneId': PropertySchema(
      id: 2,
      name: r'milestoneId',
      type: IsarType.string,
    ),
    r'orderIndex': PropertySchema(
      id: 3,
      name: r'orderIndex',
      type: IsarType.long,
    ),
    r'title': PropertySchema(id: 4, name: r'title', type: IsarType.string),
    r'updatedAtMs': PropertySchema(
      id: 5,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarGoalMilestoneEstimateSize,
  serialize: _isarGoalMilestoneSerialize,
  deserialize: _isarGoalMilestoneDeserialize,
  deserializeProp: _isarGoalMilestoneDeserializeProp,
  idName: r'id',
  indexes: {
    r'milestoneId': IndexSchema(
      id: 6650917624138872266,
      name: r'milestoneId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'milestoneId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'goalId': IndexSchema(
      id: 2738626632585230611,
      name: r'goalId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'goalId',
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
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarGoalMilestoneGetId,
  getLinks: _isarGoalMilestoneGetLinks,
  attach: _isarGoalMilestoneAttach,
  version: '3.3.2',
);

int _isarGoalMilestoneEstimateSize(
  IsarGoalMilestone object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.goalId.length * 3;
  bytesCount += 3 + object.milestoneId.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _isarGoalMilestoneSerialize(
  IsarGoalMilestone object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.completed);
  writer.writeString(offsets[1], object.goalId);
  writer.writeString(offsets[2], object.milestoneId);
  writer.writeLong(offsets[3], object.orderIndex);
  writer.writeString(offsets[4], object.title);
  writer.writeLong(offsets[5], object.updatedAtMs);
}

IsarGoalMilestone _isarGoalMilestoneDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarGoalMilestone();
  object.completed = reader.readBool(offsets[0]);
  object.goalId = reader.readString(offsets[1]);
  object.id = id;
  object.milestoneId = reader.readString(offsets[2]);
  object.orderIndex = reader.readLong(offsets[3]);
  object.title = reader.readString(offsets[4]);
  object.updatedAtMs = reader.readLong(offsets[5]);
  return object;
}

P _isarGoalMilestoneDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarGoalMilestoneGetId(IsarGoalMilestone object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarGoalMilestoneGetLinks(
  IsarGoalMilestone object,
) {
  return [];
}

void _isarGoalMilestoneAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarGoalMilestone object,
) {
  object.id = id;
}

extension IsarGoalMilestoneByIndex on IsarCollection<IsarGoalMilestone> {
  Future<IsarGoalMilestone?> getByMilestoneId(String milestoneId) {
    return getByIndex(r'milestoneId', [milestoneId]);
  }

  IsarGoalMilestone? getByMilestoneIdSync(String milestoneId) {
    return getByIndexSync(r'milestoneId', [milestoneId]);
  }

  Future<bool> deleteByMilestoneId(String milestoneId) {
    return deleteByIndex(r'milestoneId', [milestoneId]);
  }

  bool deleteByMilestoneIdSync(String milestoneId) {
    return deleteByIndexSync(r'milestoneId', [milestoneId]);
  }

  Future<List<IsarGoalMilestone?>> getAllByMilestoneId(
    List<String> milestoneIdValues,
  ) {
    final values = milestoneIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'milestoneId', values);
  }

  List<IsarGoalMilestone?> getAllByMilestoneIdSync(
    List<String> milestoneIdValues,
  ) {
    final values = milestoneIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'milestoneId', values);
  }

  Future<int> deleteAllByMilestoneId(List<String> milestoneIdValues) {
    final values = milestoneIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'milestoneId', values);
  }

  int deleteAllByMilestoneIdSync(List<String> milestoneIdValues) {
    final values = milestoneIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'milestoneId', values);
  }

  Future<Id> putByMilestoneId(IsarGoalMilestone object) {
    return putByIndex(r'milestoneId', object);
  }

  Id putByMilestoneIdSync(IsarGoalMilestone object, {bool saveLinks = true}) {
    return putByIndexSync(r'milestoneId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMilestoneId(List<IsarGoalMilestone> objects) {
    return putAllByIndex(r'milestoneId', objects);
  }

  List<Id> putAllByMilestoneIdSync(
    List<IsarGoalMilestone> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'milestoneId', objects, saveLinks: saveLinks);
  }
}

extension IsarGoalMilestoneQueryWhereSort
    on QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QWhere> {
  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhere>
  anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarGoalMilestoneQueryWhere
    on QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QWhereClause> {
  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
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

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
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

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
  milestoneIdEqualTo(String milestoneId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'milestoneId',
          value: [milestoneId],
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
  milestoneIdNotEqualTo(String milestoneId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'milestoneId',
                lower: [],
                upper: [milestoneId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'milestoneId',
                lower: [milestoneId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'milestoneId',
                lower: [milestoneId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'milestoneId',
                lower: [],
                upper: [milestoneId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
  goalIdEqualTo(String goalId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'goalId', value: [goalId]),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
  goalIdNotEqualTo(String goalId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'goalId',
                lower: [],
                upper: [goalId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'goalId',
                lower: [goalId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'goalId',
                lower: [goalId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'goalId',
                lower: [],
                upper: [goalId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
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

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
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

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
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

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
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

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterWhereClause>
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
}

extension IsarGoalMilestoneQueryFilter
    on QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QFilterCondition> {
  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  completedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'completed', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  goalIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  goalIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  goalIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  goalIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'goalId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  goalIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  goalIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  goalIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  goalIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'goalId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  goalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'goalId', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  goalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'goalId', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  milestoneIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'milestoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  milestoneIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'milestoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  milestoneIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'milestoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  milestoneIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'milestoneId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  milestoneIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'milestoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  milestoneIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'milestoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  milestoneIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'milestoneId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  milestoneIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'milestoneId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  milestoneIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'milestoneId', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  milestoneIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'milestoneId', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  orderIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'orderIndex', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  orderIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'orderIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  orderIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'orderIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  orderIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'orderIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterFilterCondition>
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

extension IsarGoalMilestoneQueryObject
    on QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QFilterCondition> {}

extension IsarGoalMilestoneQueryLinks
    on QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QFilterCondition> {}

extension IsarGoalMilestoneQuerySortBy
    on QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QSortBy> {
  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByMilestoneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByMilestoneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarGoalMilestoneQuerySortThenBy
    on QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QSortThenBy> {
  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByMilestoneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByMilestoneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarGoalMilestoneQueryWhereDistinct
    on QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QDistinct> {
  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QDistinct>
  distinctByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completed');
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QDistinct>
  distinctByGoalId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goalId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QDistinct>
  distinctByMilestoneId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'milestoneId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QDistinct>
  distinctByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderIndex');
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QDistinct>
  distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarGoalMilestoneQueryProperty
    on QueryBuilder<IsarGoalMilestone, IsarGoalMilestone, QQueryProperty> {
  QueryBuilder<IsarGoalMilestone, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarGoalMilestone, bool, QQueryOperations> completedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completed');
    });
  }

  QueryBuilder<IsarGoalMilestone, String, QQueryOperations> goalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goalId');
    });
  }

  QueryBuilder<IsarGoalMilestone, String, QQueryOperations>
  milestoneIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'milestoneId');
    });
  }

  QueryBuilder<IsarGoalMilestone, int, QQueryOperations> orderIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderIndex');
    });
  }

  QueryBuilder<IsarGoalMilestone, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<IsarGoalMilestone, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
