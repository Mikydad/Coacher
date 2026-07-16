// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_stake_challenge.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarStakeChallengeCollection on Isar {
  IsarCollection<IsarStakeChallenge> get isarStakeChallenges =>
      this.collection();
}

const IsarStakeChallengeSchema = CollectionSchema(
  name: r'IsarStakeChallenge',
  id: -20830184439097663,
  properties: {
    r'challengeId': PropertySchema(
      id: 0,
      name: r'challengeId',
      type: IsarType.string,
    ),
    r'circleId': PropertySchema(
      id: 1,
      name: r'circleId',
      type: IsarType.string,
    ),
    r'createdAtMs': PropertySchema(
      id: 2,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'creatorUid': PropertySchema(
      id: 3,
      name: r'creatorUid',
      type: IsarType.string,
    ),
    r'deadlineMs': PropertySchema(
      id: 4,
      name: r'deadlineMs',
      type: IsarType.long,
    ),
    r'decidedAtMs': PropertySchema(
      id: 5,
      name: r'decidedAtMs',
      type: IsarType.long,
    ),
    r'frozenGoalJson': PropertySchema(
      id: 6,
      name: r'frozenGoalJson',
      type: IsarType.string,
    ),
    r'mode': PropertySchema(id: 7, name: r'mode', type: IsarType.string),
    r'participantsJson': PropertySchema(
      id: 8,
      name: r'participantsJson',
      type: IsarType.string,
    ),
    r'photoStateStorage': PropertySchema(
      id: 9,
      name: r'photoStateStorage',
      type: IsarType.string,
    ),
    r'resultsJson': PropertySchema(
      id: 10,
      name: r'resultsJson',
      type: IsarType.string,
    ),
    r'revealExpiresAtMs': PropertySchema(
      id: 11,
      name: r'revealExpiresAtMs',
      type: IsarType.long,
    ),
    r'revealedAtMs': PropertySchema(
      id: 12,
      name: r'revealedAtMs',
      type: IsarType.long,
    ),
    r'statusStorage': PropertySchema(
      id: 13,
      name: r'statusStorage',
      type: IsarType.string,
    ),
    r'typeStorage': PropertySchema(
      id: 14,
      name: r'typeStorage',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 15,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarStakeChallengeEstimateSize,
  serialize: _isarStakeChallengeSerialize,
  deserialize: _isarStakeChallengeDeserialize,
  deserializeProp: _isarStakeChallengeDeserializeProp,
  idName: r'id',
  indexes: {
    r'challengeId': IndexSchema(
      id: 4483557487511118379,
      name: r'challengeId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'challengeId',
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
    r'statusStorage': IndexSchema(
      id: 2590634662480333716,
      name: r'statusStorage',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'statusStorage',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarStakeChallengeGetId,
  getLinks: _isarStakeChallengeGetLinks,
  attach: _isarStakeChallengeAttach,
  version: '3.3.2',
);

int _isarStakeChallengeEstimateSize(
  IsarStakeChallenge object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.challengeId.length * 3;
  bytesCount += 3 + object.circleId.length * 3;
  bytesCount += 3 + object.creatorUid.length * 3;
  bytesCount += 3 + object.frozenGoalJson.length * 3;
  {
    final value = object.mode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.participantsJson.length * 3;
  {
    final value = object.photoStateStorage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.resultsJson.length * 3;
  bytesCount += 3 + object.statusStorage.length * 3;
  bytesCount += 3 + object.typeStorage.length * 3;
  return bytesCount;
}

void _isarStakeChallengeSerialize(
  IsarStakeChallenge object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.challengeId);
  writer.writeString(offsets[1], object.circleId);
  writer.writeLong(offsets[2], object.createdAtMs);
  writer.writeString(offsets[3], object.creatorUid);
  writer.writeLong(offsets[4], object.deadlineMs);
  writer.writeLong(offsets[5], object.decidedAtMs);
  writer.writeString(offsets[6], object.frozenGoalJson);
  writer.writeString(offsets[7], object.mode);
  writer.writeString(offsets[8], object.participantsJson);
  writer.writeString(offsets[9], object.photoStateStorage);
  writer.writeString(offsets[10], object.resultsJson);
  writer.writeLong(offsets[11], object.revealExpiresAtMs);
  writer.writeLong(offsets[12], object.revealedAtMs);
  writer.writeString(offsets[13], object.statusStorage);
  writer.writeString(offsets[14], object.typeStorage);
  writer.writeLong(offsets[15], object.updatedAtMs);
}

IsarStakeChallenge _isarStakeChallengeDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarStakeChallenge();
  object.challengeId = reader.readString(offsets[0]);
  object.circleId = reader.readString(offsets[1]);
  object.createdAtMs = reader.readLong(offsets[2]);
  object.creatorUid = reader.readString(offsets[3]);
  object.deadlineMs = reader.readLong(offsets[4]);
  object.decidedAtMs = reader.readLongOrNull(offsets[5]);
  object.frozenGoalJson = reader.readString(offsets[6]);
  object.id = id;
  object.mode = reader.readStringOrNull(offsets[7]);
  object.participantsJson = reader.readString(offsets[8]);
  object.photoStateStorage = reader.readStringOrNull(offsets[9]);
  object.resultsJson = reader.readString(offsets[10]);
  object.revealExpiresAtMs = reader.readLongOrNull(offsets[11]);
  object.revealedAtMs = reader.readLongOrNull(offsets[12]);
  object.statusStorage = reader.readString(offsets[13]);
  object.typeStorage = reader.readString(offsets[14]);
  object.updatedAtMs = reader.readLong(offsets[15]);
  return object;
}

P _isarStakeChallengeDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarStakeChallengeGetId(IsarStakeChallenge object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarStakeChallengeGetLinks(
  IsarStakeChallenge object,
) {
  return [];
}

void _isarStakeChallengeAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarStakeChallenge object,
) {
  object.id = id;
}

extension IsarStakeChallengeByIndex on IsarCollection<IsarStakeChallenge> {
  Future<IsarStakeChallenge?> getByChallengeId(String challengeId) {
    return getByIndex(r'challengeId', [challengeId]);
  }

  IsarStakeChallenge? getByChallengeIdSync(String challengeId) {
    return getByIndexSync(r'challengeId', [challengeId]);
  }

  Future<bool> deleteByChallengeId(String challengeId) {
    return deleteByIndex(r'challengeId', [challengeId]);
  }

  bool deleteByChallengeIdSync(String challengeId) {
    return deleteByIndexSync(r'challengeId', [challengeId]);
  }

  Future<List<IsarStakeChallenge?>> getAllByChallengeId(
    List<String> challengeIdValues,
  ) {
    final values = challengeIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'challengeId', values);
  }

  List<IsarStakeChallenge?> getAllByChallengeIdSync(
    List<String> challengeIdValues,
  ) {
    final values = challengeIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'challengeId', values);
  }

  Future<int> deleteAllByChallengeId(List<String> challengeIdValues) {
    final values = challengeIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'challengeId', values);
  }

  int deleteAllByChallengeIdSync(List<String> challengeIdValues) {
    final values = challengeIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'challengeId', values);
  }

  Future<Id> putByChallengeId(IsarStakeChallenge object) {
    return putByIndex(r'challengeId', object);
  }

  Id putByChallengeIdSync(IsarStakeChallenge object, {bool saveLinks = true}) {
    return putByIndexSync(r'challengeId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByChallengeId(List<IsarStakeChallenge> objects) {
    return putAllByIndex(r'challengeId', objects);
  }

  List<Id> putAllByChallengeIdSync(
    List<IsarStakeChallenge> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'challengeId', objects, saveLinks: saveLinks);
  }
}

extension IsarStakeChallengeQueryWhereSort
    on QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QWhere> {
  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhere>
  anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarStakeChallengeQueryWhere
    on QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QWhereClause> {
  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
  challengeIdEqualTo(String challengeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'challengeId',
          value: [challengeId],
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
  challengeIdNotEqualTo(String challengeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'challengeId',
                lower: [],
                upper: [challengeId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'challengeId',
                lower: [challengeId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'challengeId',
                lower: [challengeId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'challengeId',
                lower: [],
                upper: [challengeId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
  statusStorageEqualTo(String statusStorage) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'statusStorage',
          value: [statusStorage],
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterWhereClause>
  statusStorageNotEqualTo(String statusStorage) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusStorage',
                lower: [],
                upper: [statusStorage],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusStorage',
                lower: [statusStorage],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusStorage',
                lower: [statusStorage],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusStorage',
                lower: [],
                upper: [statusStorage],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarStakeChallengeQueryFilter
    on QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QFilterCondition> {
  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  challengeIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'challengeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  challengeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'challengeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  challengeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'challengeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  challengeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'challengeId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  challengeIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'challengeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  challengeIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'challengeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  challengeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'challengeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  challengeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'challengeId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  challengeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'challengeId', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  challengeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'challengeId', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  circleIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'circleId', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  circleIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'circleId', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  creatorUidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'creatorUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  creatorUidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'creatorUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  creatorUidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'creatorUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  creatorUidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'creatorUid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  creatorUidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'creatorUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  creatorUidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'creatorUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  creatorUidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'creatorUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  creatorUidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'creatorUid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  creatorUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'creatorUid', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  creatorUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'creatorUid', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  deadlineMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deadlineMs', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  deadlineMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deadlineMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  deadlineMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deadlineMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  deadlineMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deadlineMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  decidedAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'decidedAtMs'),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  decidedAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'decidedAtMs'),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  decidedAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'decidedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  decidedAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'decidedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  decidedAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'decidedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  decidedAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'decidedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  frozenGoalJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'frozenGoalJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  frozenGoalJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'frozenGoalJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  frozenGoalJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'frozenGoalJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  frozenGoalJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'frozenGoalJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  frozenGoalJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'frozenGoalJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  frozenGoalJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'frozenGoalJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  frozenGoalJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'frozenGoalJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  frozenGoalJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'frozenGoalJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  frozenGoalJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'frozenGoalJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  frozenGoalJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'frozenGoalJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'mode'),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'mode'),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mode', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  modeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mode', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  participantsJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'participantsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  participantsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'participantsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  participantsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'participantsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  participantsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'participantsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  participantsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'participantsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  participantsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'participantsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  participantsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'participantsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  participantsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'participantsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  participantsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'participantsJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  participantsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'participantsJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'photoStateStorage'),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'photoStateStorage'),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'photoStateStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'photoStateStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'photoStateStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'photoStateStorage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'photoStateStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'photoStateStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'photoStateStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'photoStateStorage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'photoStateStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  photoStateStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'photoStateStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  resultsJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'resultsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  resultsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'resultsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  resultsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'resultsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  resultsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'resultsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  resultsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'resultsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  resultsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'resultsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  resultsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'resultsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  resultsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'resultsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  resultsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resultsJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  resultsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'resultsJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealExpiresAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'revealExpiresAtMs'),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealExpiresAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'revealExpiresAtMs'),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealExpiresAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'revealExpiresAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealExpiresAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'revealExpiresAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealExpiresAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'revealExpiresAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealExpiresAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'revealExpiresAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealedAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'revealedAtMs'),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealedAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'revealedAtMs'),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealedAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'revealedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealedAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'revealedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealedAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'revealedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  revealedAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'revealedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  statusStorageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  statusStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  statusStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  statusStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'statusStorage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  statusStorageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  statusStorageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  statusStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  statusStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'statusStorage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  statusStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'statusStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  statusStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'statusStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  typeStorageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'typeStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  typeStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'typeStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  typeStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'typeStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  typeStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'typeStorage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  typeStorageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'typeStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  typeStorageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'typeStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  typeStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'typeStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  typeStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'typeStorage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  typeStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'typeStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  typeStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'typeStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterFilterCondition>
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

extension IsarStakeChallengeQueryObject
    on QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QFilterCondition> {}

extension IsarStakeChallengeQueryLinks
    on QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QFilterCondition> {}

extension IsarStakeChallengeQuerySortBy
    on QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QSortBy> {
  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByChallengeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'challengeId', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByChallengeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'challengeId', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByCircleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByCircleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByCreatorUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorUid', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByCreatorUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorUid', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByDeadlineMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadlineMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByDeadlineMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadlineMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByDecidedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decidedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByDecidedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decidedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByFrozenGoalJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frozenGoalJson', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByFrozenGoalJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frozenGoalJson', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByParticipantsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByParticipantsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByPhotoStateStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoStateStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByPhotoStateStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoStateStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByResultsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByResultsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByRevealExpiresAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revealExpiresAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByRevealExpiresAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revealExpiresAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByRevealedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revealedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByRevealedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revealedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByStatusStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByStatusStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByTypeStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByTypeStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarStakeChallengeQuerySortThenBy
    on QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QSortThenBy> {
  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByChallengeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'challengeId', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByChallengeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'challengeId', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByCircleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByCircleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'circleId', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByCreatorUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorUid', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByCreatorUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorUid', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByDeadlineMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadlineMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByDeadlineMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadlineMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByDecidedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decidedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByDecidedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decidedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByFrozenGoalJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frozenGoalJson', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByFrozenGoalJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frozenGoalJson', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByParticipantsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByParticipantsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByPhotoStateStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoStateStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByPhotoStateStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoStateStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByResultsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByResultsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByRevealExpiresAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revealExpiresAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByRevealExpiresAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revealExpiresAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByRevealedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revealedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByRevealedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revealedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByStatusStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByStatusStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByTypeStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByTypeStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarStakeChallengeQueryWhereDistinct
    on QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct> {
  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByChallengeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'challengeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByCircleId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'circleId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByCreatorUid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creatorUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByDeadlineMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deadlineMs');
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByDecidedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'decidedAtMs');
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByFrozenGoalJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'frozenGoalJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByMode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByParticipantsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'participantsJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByPhotoStateStorage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'photoStateStorage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByResultsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resultsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByRevealExpiresAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'revealExpiresAtMs');
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByRevealedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'revealedAtMs');
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByStatusStorage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'statusStorage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByTypeStorage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'typeStorage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarStakeChallengeQueryProperty
    on QueryBuilder<IsarStakeChallenge, IsarStakeChallenge, QQueryProperty> {
  QueryBuilder<IsarStakeChallenge, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarStakeChallenge, String, QQueryOperations>
  challengeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'challengeId');
    });
  }

  QueryBuilder<IsarStakeChallenge, String, QQueryOperations>
  circleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'circleId');
    });
  }

  QueryBuilder<IsarStakeChallenge, int, QQueryOperations>
  createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarStakeChallenge, String, QQueryOperations>
  creatorUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creatorUid');
    });
  }

  QueryBuilder<IsarStakeChallenge, int, QQueryOperations> deadlineMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deadlineMs');
    });
  }

  QueryBuilder<IsarStakeChallenge, int?, QQueryOperations>
  decidedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'decidedAtMs');
    });
  }

  QueryBuilder<IsarStakeChallenge, String, QQueryOperations>
  frozenGoalJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frozenGoalJson');
    });
  }

  QueryBuilder<IsarStakeChallenge, String?, QQueryOperations> modeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mode');
    });
  }

  QueryBuilder<IsarStakeChallenge, String, QQueryOperations>
  participantsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'participantsJson');
    });
  }

  QueryBuilder<IsarStakeChallenge, String?, QQueryOperations>
  photoStateStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photoStateStorage');
    });
  }

  QueryBuilder<IsarStakeChallenge, String, QQueryOperations>
  resultsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resultsJson');
    });
  }

  QueryBuilder<IsarStakeChallenge, int?, QQueryOperations>
  revealExpiresAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'revealExpiresAtMs');
    });
  }

  QueryBuilder<IsarStakeChallenge, int?, QQueryOperations>
  revealedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'revealedAtMs');
    });
  }

  QueryBuilder<IsarStakeChallenge, String, QQueryOperations>
  statusStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statusStorage');
    });
  }

  QueryBuilder<IsarStakeChallenge, String, QQueryOperations>
  typeStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'typeStorage');
    });
  }

  QueryBuilder<IsarStakeChallenge, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
