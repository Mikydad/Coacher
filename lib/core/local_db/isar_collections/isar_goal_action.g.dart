// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_goal_action.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarGoalActionCollection on Isar {
  IsarCollection<IsarGoalAction> get isarGoalActions => this.collection();
}

const IsarGoalActionSchema = CollectionSchema(
  name: r'IsarGoalAction',
  id: -279390144713161269,
  properties: {
    r'actionId': PropertySchema(
      id: 0,
      name: r'actionId',
      type: IsarType.string,
    ),
    r'completed': PropertySchema(
      id: 1,
      name: r'completed',
      type: IsarType.bool,
    ),
    r'completedDateKeys': PropertySchema(
      id: 2,
      name: r'completedDateKeys',
      type: IsarType.stringList,
    ),
    r'goalId': PropertySchema(id: 3, name: r'goalId', type: IsarType.string),
    r'orderIndex': PropertySchema(
      id: 4,
      name: r'orderIndex',
      type: IsarType.long,
    ),
    r'repeatWeekdays': PropertySchema(
      id: 5,
      name: r'repeatWeekdays',
      type: IsarType.longList,
    ),
    r'title': PropertySchema(id: 6, name: r'title', type: IsarType.string),
    r'updatedAtMs': PropertySchema(
      id: 7,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarGoalActionEstimateSize,
  serialize: _isarGoalActionSerialize,
  deserialize: _isarGoalActionDeserialize,
  deserializeProp: _isarGoalActionDeserializeProp,
  idName: r'id',
  indexes: {
    r'actionId': IndexSchema(
      id: -48703777413607206,
      name: r'actionId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'actionId',
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

  getId: _isarGoalActionGetId,
  getLinks: _isarGoalActionGetLinks,
  attach: _isarGoalActionAttach,
  version: '3.3.2',
);

int _isarGoalActionEstimateSize(
  IsarGoalAction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.actionId.length * 3;
  {
    final list = object.completedDateKeys;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  bytesCount += 3 + object.goalId.length * 3;
  {
    final value = object.repeatWeekdays;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _isarGoalActionSerialize(
  IsarGoalAction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.actionId);
  writer.writeBool(offsets[1], object.completed);
  writer.writeStringList(offsets[2], object.completedDateKeys);
  writer.writeString(offsets[3], object.goalId);
  writer.writeLong(offsets[4], object.orderIndex);
  writer.writeLongList(offsets[5], object.repeatWeekdays);
  writer.writeString(offsets[6], object.title);
  writer.writeLong(offsets[7], object.updatedAtMs);
}

IsarGoalAction _isarGoalActionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarGoalAction();
  object.actionId = reader.readString(offsets[0]);
  object.completed = reader.readBool(offsets[1]);
  object.completedDateKeys = reader.readStringList(offsets[2]);
  object.goalId = reader.readString(offsets[3]);
  object.id = id;
  object.orderIndex = reader.readLong(offsets[4]);
  object.repeatWeekdays = reader.readLongList(offsets[5]);
  object.title = reader.readString(offsets[6]);
  object.updatedAtMs = reader.readLong(offsets[7]);
  return object;
}

P _isarGoalActionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readStringList(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLongList(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarGoalActionGetId(IsarGoalAction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarGoalActionGetLinks(IsarGoalAction object) {
  return [];
}

void _isarGoalActionAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarGoalAction object,
) {
  object.id = id;
}

extension IsarGoalActionByIndex on IsarCollection<IsarGoalAction> {
  Future<IsarGoalAction?> getByActionId(String actionId) {
    return getByIndex(r'actionId', [actionId]);
  }

  IsarGoalAction? getByActionIdSync(String actionId) {
    return getByIndexSync(r'actionId', [actionId]);
  }

  Future<bool> deleteByActionId(String actionId) {
    return deleteByIndex(r'actionId', [actionId]);
  }

  bool deleteByActionIdSync(String actionId) {
    return deleteByIndexSync(r'actionId', [actionId]);
  }

  Future<List<IsarGoalAction?>> getAllByActionId(List<String> actionIdValues) {
    final values = actionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'actionId', values);
  }

  List<IsarGoalAction?> getAllByActionIdSync(List<String> actionIdValues) {
    final values = actionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'actionId', values);
  }

  Future<int> deleteAllByActionId(List<String> actionIdValues) {
    final values = actionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'actionId', values);
  }

  int deleteAllByActionIdSync(List<String> actionIdValues) {
    final values = actionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'actionId', values);
  }

  Future<Id> putByActionId(IsarGoalAction object) {
    return putByIndex(r'actionId', object);
  }

  Id putByActionIdSync(IsarGoalAction object, {bool saveLinks = true}) {
    return putByIndexSync(r'actionId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByActionId(List<IsarGoalAction> objects) {
    return putAllByIndex(r'actionId', objects);
  }

  List<Id> putAllByActionIdSync(
    List<IsarGoalAction> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'actionId', objects, saveLinks: saveLinks);
  }
}

extension IsarGoalActionQueryWhereSort
    on QueryBuilder<IsarGoalAction, IsarGoalAction, QWhere> {
  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhere> anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarGoalActionQueryWhere
    on QueryBuilder<IsarGoalAction, IsarGoalAction, QWhereClause> {
  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause>
  actionIdEqualTo(String actionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'actionId', value: [actionId]),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause>
  actionIdNotEqualTo(String actionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'actionId',
                lower: [],
                upper: [actionId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'actionId',
                lower: [actionId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'actionId',
                lower: [actionId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'actionId',
                lower: [],
                upper: [actionId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause> goalIdEqualTo(
    String goalId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'goalId', value: [goalId]),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterWhereClause>
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

extension IsarGoalActionQueryFilter
    on QueryBuilder<IsarGoalAction, IsarGoalAction, QFilterCondition> {
  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  actionIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'actionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  actionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'actionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  actionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'actionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  actionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'actionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  actionIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'actionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  actionIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'actionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  actionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'actionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  actionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'actionId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  actionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'actionId', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  actionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'actionId', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'completed', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'completedDateKeys'),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'completedDateKeys'),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'completedDateKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'completedDateKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'completedDateKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'completedDateKeys',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'completedDateKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'completedDateKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'completedDateKeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'completedDateKeys',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'completedDateKeys', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'completedDateKeys', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'completedDateKeys', length, true, length, true);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'completedDateKeys', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'completedDateKeys', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'completedDateKeys', 0, true, length, include);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedDateKeys',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  completedDateKeysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'completedDateKeys',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  goalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'goalId', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  goalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'goalId', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  orderIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'orderIndex', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'repeatWeekdays'),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'repeatWeekdays'),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'repeatWeekdays', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'repeatWeekdays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'repeatWeekdays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'repeatWeekdays',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'repeatWeekdays', length, true, length, true);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'repeatWeekdays', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'repeatWeekdays', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'repeatWeekdays', 0, true, length, include);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'repeatWeekdays', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  repeatWeekdaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'repeatWeekdays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterFilterCondition>
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

extension IsarGoalActionQueryObject
    on QueryBuilder<IsarGoalAction, IsarGoalAction, QFilterCondition> {}

extension IsarGoalActionQueryLinks
    on QueryBuilder<IsarGoalAction, IsarGoalAction, QFilterCondition> {}

extension IsarGoalActionQuerySortBy
    on QueryBuilder<IsarGoalAction, IsarGoalAction, QSortBy> {
  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> sortByActionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  sortByActionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> sortByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  sortByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> sortByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  sortByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  sortByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  sortByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarGoalActionQuerySortThenBy
    on QueryBuilder<IsarGoalAction, IsarGoalAction, QSortThenBy> {
  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> thenByActionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  thenByActionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> thenByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  thenByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> thenByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  thenByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  thenByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  thenByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarGoalActionQueryWhereDistinct
    on QueryBuilder<IsarGoalAction, IsarGoalAction, QDistinct> {
  QueryBuilder<IsarGoalAction, IsarGoalAction, QDistinct> distinctByActionId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QDistinct>
  distinctByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completed');
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QDistinct>
  distinctByCompletedDateKeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedDateKeys');
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QDistinct> distinctByGoalId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goalId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QDistinct>
  distinctByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderIndex');
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QDistinct>
  distinctByRepeatWeekdays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatWeekdays');
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoalAction, IsarGoalAction, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarGoalActionQueryProperty
    on QueryBuilder<IsarGoalAction, IsarGoalAction, QQueryProperty> {
  QueryBuilder<IsarGoalAction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarGoalAction, String, QQueryOperations> actionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actionId');
    });
  }

  QueryBuilder<IsarGoalAction, bool, QQueryOperations> completedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completed');
    });
  }

  QueryBuilder<IsarGoalAction, List<String>?, QQueryOperations>
  completedDateKeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedDateKeys');
    });
  }

  QueryBuilder<IsarGoalAction, String, QQueryOperations> goalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goalId');
    });
  }

  QueryBuilder<IsarGoalAction, int, QQueryOperations> orderIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderIndex');
    });
  }

  QueryBuilder<IsarGoalAction, List<int>?, QQueryOperations>
  repeatWeekdaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatWeekdays');
    });
  }

  QueryBuilder<IsarGoalAction, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<IsarGoalAction, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
