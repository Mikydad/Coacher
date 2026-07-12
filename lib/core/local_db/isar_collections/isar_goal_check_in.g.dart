// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_goal_check_in.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarGoalCheckInCollection on Isar {
  IsarCollection<IsarGoalCheckIn> get isarGoalCheckIns => this.collection();
}

const IsarGoalCheckInSchema = CollectionSchema(
  name: r'IsarGoalCheckIn',
  id: -4455215819357919105,
  properties: {
    r'checkInKey': PropertySchema(
      id: 0,
      name: r'checkInKey',
      type: IsarType.string,
    ),
    r'dateKey': PropertySchema(id: 1, name: r'dateKey', type: IsarType.string),
    r'goalId': PropertySchema(id: 2, name: r'goalId', type: IsarType.string),
    r'metCommitment': PropertySchema(
      id: 3,
      name: r'metCommitment',
      type: IsarType.bool,
    ),
    r'note': PropertySchema(id: 4, name: r'note', type: IsarType.string),
    r'updatedAtMs': PropertySchema(
      id: 5,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
    r'value': PropertySchema(id: 6, name: r'value', type: IsarType.double),
  },

  estimateSize: _isarGoalCheckInEstimateSize,
  serialize: _isarGoalCheckInSerialize,
  deserialize: _isarGoalCheckInDeserialize,
  deserializeProp: _isarGoalCheckInDeserializeProp,
  idName: r'id',
  indexes: {
    r'checkInKey': IndexSchema(
      id: 3478872615835082951,
      name: r'checkInKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'checkInKey',
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

  getId: _isarGoalCheckInGetId,
  getLinks: _isarGoalCheckInGetLinks,
  attach: _isarGoalCheckInAttach,
  version: '3.3.2',
);

int _isarGoalCheckInEstimateSize(
  IsarGoalCheckIn object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.checkInKey.length * 3;
  bytesCount += 3 + object.dateKey.length * 3;
  bytesCount += 3 + object.goalId.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarGoalCheckInSerialize(
  IsarGoalCheckIn object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.checkInKey);
  writer.writeString(offsets[1], object.dateKey);
  writer.writeString(offsets[2], object.goalId);
  writer.writeBool(offsets[3], object.metCommitment);
  writer.writeString(offsets[4], object.note);
  writer.writeLong(offsets[5], object.updatedAtMs);
  writer.writeDouble(offsets[6], object.value);
}

IsarGoalCheckIn _isarGoalCheckInDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarGoalCheckIn();
  object.checkInKey = reader.readString(offsets[0]);
  object.dateKey = reader.readString(offsets[1]);
  object.goalId = reader.readString(offsets[2]);
  object.id = id;
  object.metCommitment = reader.readBool(offsets[3]);
  object.note = reader.readStringOrNull(offsets[4]);
  object.updatedAtMs = reader.readLong(offsets[5]);
  object.value = reader.readDoubleOrNull(offsets[6]);
  return object;
}

P _isarGoalCheckInDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarGoalCheckInGetId(IsarGoalCheckIn object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarGoalCheckInGetLinks(IsarGoalCheckIn object) {
  return [];
}

void _isarGoalCheckInAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarGoalCheckIn object,
) {
  object.id = id;
}

extension IsarGoalCheckInByIndex on IsarCollection<IsarGoalCheckIn> {
  Future<IsarGoalCheckIn?> getByCheckInKey(String checkInKey) {
    return getByIndex(r'checkInKey', [checkInKey]);
  }

  IsarGoalCheckIn? getByCheckInKeySync(String checkInKey) {
    return getByIndexSync(r'checkInKey', [checkInKey]);
  }

  Future<bool> deleteByCheckInKey(String checkInKey) {
    return deleteByIndex(r'checkInKey', [checkInKey]);
  }

  bool deleteByCheckInKeySync(String checkInKey) {
    return deleteByIndexSync(r'checkInKey', [checkInKey]);
  }

  Future<List<IsarGoalCheckIn?>> getAllByCheckInKey(
    List<String> checkInKeyValues,
  ) {
    final values = checkInKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'checkInKey', values);
  }

  List<IsarGoalCheckIn?> getAllByCheckInKeySync(List<String> checkInKeyValues) {
    final values = checkInKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'checkInKey', values);
  }

  Future<int> deleteAllByCheckInKey(List<String> checkInKeyValues) {
    final values = checkInKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'checkInKey', values);
  }

  int deleteAllByCheckInKeySync(List<String> checkInKeyValues) {
    final values = checkInKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'checkInKey', values);
  }

  Future<Id> putByCheckInKey(IsarGoalCheckIn object) {
    return putByIndex(r'checkInKey', object);
  }

  Id putByCheckInKeySync(IsarGoalCheckIn object, {bool saveLinks = true}) {
    return putByIndexSync(r'checkInKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCheckInKey(List<IsarGoalCheckIn> objects) {
    return putAllByIndex(r'checkInKey', objects);
  }

  List<Id> putAllByCheckInKeySync(
    List<IsarGoalCheckIn> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'checkInKey', objects, saveLinks: saveLinks);
  }
}

extension IsarGoalCheckInQueryWhereSort
    on QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QWhere> {
  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhere> anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarGoalCheckInQueryWhere
    on QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QWhereClause> {
  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
  checkInKeyEqualTo(String checkInKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'checkInKey', value: [checkInKey]),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
  checkInKeyNotEqualTo(String checkInKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'checkInKey',
                lower: [],
                upper: [checkInKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'checkInKey',
                lower: [checkInKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'checkInKey',
                lower: [checkInKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'checkInKey',
                lower: [],
                upper: [checkInKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
  goalIdEqualTo(String goalId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'goalId', value: [goalId]),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
  dateKeyEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dateKey', value: [dateKey]),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
  dateKeyNotEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [],
                upper: [dateKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [dateKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [dateKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [],
                upper: [dateKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterWhereClause>
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

extension IsarGoalCheckInQueryFilter
    on QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QFilterCondition> {
  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  checkInKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'checkInKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  checkInKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'checkInKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  checkInKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'checkInKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  checkInKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'checkInKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  checkInKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'checkInKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  checkInKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'checkInKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  checkInKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'checkInKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  checkInKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'checkInKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  checkInKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'checkInKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  checkInKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'checkInKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  dateKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  dateKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  dateKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dateKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dateKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  goalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'goalId', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  goalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'goalId', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  metCommitmentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'metCommitment', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'note'),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'note'),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'note',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'note',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
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

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  valueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'value'),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  valueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'value'),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  valueEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'value',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  valueGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'value',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  valueLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'value',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterFilterCondition>
  valueBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'value',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension IsarGoalCheckInQueryObject
    on QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QFilterCondition> {}

extension IsarGoalCheckInQueryLinks
    on QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QFilterCondition> {}

extension IsarGoalCheckInQuerySortBy
    on QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QSortBy> {
  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  sortByCheckInKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkInKey', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  sortByCheckInKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkInKey', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy> sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy> sortByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  sortByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  sortByMetCommitment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metCommitment', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  sortByMetCommitmentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metCommitment', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy> sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension IsarGoalCheckInQuerySortThenBy
    on QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QSortThenBy> {
  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  thenByCheckInKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkInKey', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  thenByCheckInKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkInKey', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy> thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy> thenByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  thenByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  thenByMetCommitment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metCommitment', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  thenByMetCommitmentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metCommitment', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy> thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QAfterSortBy>
  thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension IsarGoalCheckInQueryWhereDistinct
    on QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QDistinct> {
  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QDistinct>
  distinctByCheckInKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'checkInKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QDistinct> distinctByDateKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QDistinct> distinctByGoalId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goalId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QDistinct>
  distinctByMetCommitment() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metCommitment');
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }

  QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QDistinct> distinctByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value');
    });
  }
}

extension IsarGoalCheckInQueryProperty
    on QueryBuilder<IsarGoalCheckIn, IsarGoalCheckIn, QQueryProperty> {
  QueryBuilder<IsarGoalCheckIn, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarGoalCheckIn, String, QQueryOperations> checkInKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checkInKey');
    });
  }

  QueryBuilder<IsarGoalCheckIn, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<IsarGoalCheckIn, String, QQueryOperations> goalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goalId');
    });
  }

  QueryBuilder<IsarGoalCheckIn, bool, QQueryOperations>
  metCommitmentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metCommitment');
    });
  }

  QueryBuilder<IsarGoalCheckIn, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<IsarGoalCheckIn, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }

  QueryBuilder<IsarGoalCheckIn, double?, QQueryOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }
}
