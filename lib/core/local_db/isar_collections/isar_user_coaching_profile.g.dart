// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_user_coaching_profile.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarUserCoachingProfileCollection on Isar {
  IsarCollection<IsarUserCoachingProfile> get isarUserCoachingProfiles =>
      this.collection();
}

const IsarUserCoachingProfileSchema = CollectionSchema(
  name: r'IsarUserCoachingProfile',
  id: 536298728229709661,
  properties: {
    r'coachingStyle': PropertySchema(
      id: 0,
      name: r'coachingStyle',
      type: IsarType.string,
    ),
    r'lastChangedAtMs': PropertySchema(
      id: 1,
      name: r'lastChangedAtMs',
      type: IsarType.long,
    ),
    r'payloadJson': PropertySchema(
      id: 2,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'profileId': PropertySchema(
      id: 3,
      name: r'profileId',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 4,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'updatedAtMs': PropertySchema(
      id: 5,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },
  estimateSize: _isarUserCoachingProfileEstimateSize,
  serialize: _isarUserCoachingProfileSerialize,
  deserialize: _isarUserCoachingProfileDeserialize,
  deserializeProp: _isarUserCoachingProfileDeserializeProp,
  idName: r'id',
  indexes: {
    r'profileId': IndexSchema(
      id: 6052971939042612300,
      name: r'profileId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'profileId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'coachingStyle': IndexSchema(
      id: -2394567169003877769,
      name: r'coachingStyle',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'coachingStyle',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarUserCoachingProfileGetId,
  getLinks: _isarUserCoachingProfileGetLinks,
  attach: _isarUserCoachingProfileAttach,
  version: '3.1.0+1',
);

int _isarUserCoachingProfileEstimateSize(
  IsarUserCoachingProfile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.coachingStyle.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.profileId.length * 3;
  return bytesCount;
}

void _isarUserCoachingProfileSerialize(
  IsarUserCoachingProfile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.coachingStyle);
  writer.writeLong(offsets[1], object.lastChangedAtMs);
  writer.writeString(offsets[2], object.payloadJson);
  writer.writeString(offsets[3], object.profileId);
  writer.writeLong(offsets[4], object.schemaVersion);
  writer.writeLong(offsets[5], object.updatedAtMs);
}

IsarUserCoachingProfile _isarUserCoachingProfileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarUserCoachingProfile();
  object.coachingStyle = reader.readString(offsets[0]);
  object.id = id;
  object.lastChangedAtMs = reader.readLong(offsets[1]);
  object.payloadJson = reader.readString(offsets[2]);
  object.profileId = reader.readString(offsets[3]);
  object.schemaVersion = reader.readLong(offsets[4]);
  object.updatedAtMs = reader.readLong(offsets[5]);
  return object;
}

P _isarUserCoachingProfileDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarUserCoachingProfileGetId(IsarUserCoachingProfile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarUserCoachingProfileGetLinks(
  IsarUserCoachingProfile object,
) {
  return [];
}

void _isarUserCoachingProfileAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarUserCoachingProfile object,
) {
  object.id = id;
}

extension IsarUserCoachingProfileByIndex
    on IsarCollection<IsarUserCoachingProfile> {
  Future<IsarUserCoachingProfile?> getByProfileId(String profileId) {
    return getByIndex(r'profileId', [profileId]);
  }

  IsarUserCoachingProfile? getByProfileIdSync(String profileId) {
    return getByIndexSync(r'profileId', [profileId]);
  }

  Future<bool> deleteByProfileId(String profileId) {
    return deleteByIndex(r'profileId', [profileId]);
  }

  bool deleteByProfileIdSync(String profileId) {
    return deleteByIndexSync(r'profileId', [profileId]);
  }

  Future<List<IsarUserCoachingProfile?>> getAllByProfileId(
    List<String> profileIdValues,
  ) {
    final values = profileIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'profileId', values);
  }

  List<IsarUserCoachingProfile?> getAllByProfileIdSync(
    List<String> profileIdValues,
  ) {
    final values = profileIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'profileId', values);
  }

  Future<int> deleteAllByProfileId(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'profileId', values);
  }

  int deleteAllByProfileIdSync(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'profileId', values);
  }

  Future<Id> putByProfileId(IsarUserCoachingProfile object) {
    return putByIndex(r'profileId', object);
  }

  Id putByProfileIdSync(
    IsarUserCoachingProfile object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'profileId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByProfileId(List<IsarUserCoachingProfile> objects) {
    return putAllByIndex(r'profileId', objects);
  }

  List<Id> putAllByProfileIdSync(
    List<IsarUserCoachingProfile> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'profileId', objects, saveLinks: saveLinks);
  }
}

extension IsarUserCoachingProfileQueryWhereSort
    on QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QWhere> {
  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarUserCoachingProfileQueryWhere
    on
        QueryBuilder<
          IsarUserCoachingProfile,
          IsarUserCoachingProfile,
          QWhereClause
        > {
  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterWhereClause
  >
  profileIdEqualTo(String profileId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'profileId', value: [profileId]),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterWhereClause
  >
  profileIdNotEqualTo(String profileId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'profileId',
                lower: [],
                upper: [profileId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'profileId',
                lower: [profileId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'profileId',
                lower: [profileId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'profileId',
                lower: [],
                upper: [profileId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterWhereClause
  >
  coachingStyleEqualTo(String coachingStyle) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'coachingStyle',
          value: [coachingStyle],
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterWhereClause
  >
  coachingStyleNotEqualTo(String coachingStyle) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'coachingStyle',
                lower: [],
                upper: [coachingStyle],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'coachingStyle',
                lower: [coachingStyle],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'coachingStyle',
                lower: [coachingStyle],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'coachingStyle',
                lower: [],
                upper: [coachingStyle],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarUserCoachingProfileQueryFilter
    on
        QueryBuilder<
          IsarUserCoachingProfile,
          IsarUserCoachingProfile,
          QFilterCondition
        > {
  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  coachingStyleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'coachingStyle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  coachingStyleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'coachingStyle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  coachingStyleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'coachingStyle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  coachingStyleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'coachingStyle',
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  coachingStyleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'coachingStyle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  coachingStyleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'coachingStyle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  coachingStyleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'coachingStyle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  coachingStyleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'coachingStyle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  coachingStyleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'coachingStyle', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  coachingStyleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'coachingStyle', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  lastChangedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastChangedAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  lastChangedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastChangedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  lastChangedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastChangedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  lastChangedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastChangedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  profileIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'profileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  profileIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'profileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  profileIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'profileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  profileIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'profileId',
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  profileIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'profileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  profileIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'profileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  profileIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'profileId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  profileIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'profileId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  profileIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'profileId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
    QAfterFilterCondition
  >
  profileIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'profileId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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
    IsarUserCoachingProfile,
    IsarUserCoachingProfile,
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

extension IsarUserCoachingProfileQueryObject
    on
        QueryBuilder<
          IsarUserCoachingProfile,
          IsarUserCoachingProfile,
          QFilterCondition
        > {}

extension IsarUserCoachingProfileQueryLinks
    on
        QueryBuilder<
          IsarUserCoachingProfile,
          IsarUserCoachingProfile,
          QFilterCondition
        > {}

extension IsarUserCoachingProfileQuerySortBy
    on QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QSortBy> {
  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortByCoachingStyle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coachingStyle', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortByCoachingStyleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coachingStyle', Sort.desc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortByLastChangedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortByLastChangedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarUserCoachingProfileQuerySortThenBy
    on
        QueryBuilder<
          IsarUserCoachingProfile,
          IsarUserCoachingProfile,
          QSortThenBy
        > {
  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenByCoachingStyle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coachingStyle', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenByCoachingStyleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coachingStyle', Sort.desc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenByLastChangedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenByLastChangedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChangedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarUserCoachingProfileQueryWhereDistinct
    on
        QueryBuilder<
          IsarUserCoachingProfile,
          IsarUserCoachingProfile,
          QDistinct
        > {
  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QDistinct>
  distinctByCoachingStyle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'coachingStyle',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QDistinct>
  distinctByLastChangedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastChangedAtMs');
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QDistinct>
  distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QDistinct>
  distinctByProfileId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QDistinct>
  distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<IsarUserCoachingProfile, IsarUserCoachingProfile, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarUserCoachingProfileQueryProperty
    on
        QueryBuilder<
          IsarUserCoachingProfile,
          IsarUserCoachingProfile,
          QQueryProperty
        > {
  QueryBuilder<IsarUserCoachingProfile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarUserCoachingProfile, String, QQueryOperations>
  coachingStyleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coachingStyle');
    });
  }

  QueryBuilder<IsarUserCoachingProfile, int, QQueryOperations>
  lastChangedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastChangedAtMs');
    });
  }

  QueryBuilder<IsarUserCoachingProfile, String, QQueryOperations>
  payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<IsarUserCoachingProfile, String, QQueryOperations>
  profileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileId');
    });
  }

  QueryBuilder<IsarUserCoachingProfile, int, QQueryOperations>
  schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<IsarUserCoachingProfile, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
