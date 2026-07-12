// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_onboarding_profile.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarOnboardingProfileCollection on Isar {
  IsarCollection<IsarOnboardingProfile> get isarOnboardingProfiles =>
      this.collection();
}

const IsarOnboardingProfileSchema = CollectionSchema(
  name: r'IsarOnboardingProfile',
  id: -1659321765048696529,
  properties: {
    r'completedAtMs': PropertySchema(
      id: 0,
      name: r'completedAtMs',
      type: IsarType.long,
    ),
    r'payloadJson': PropertySchema(
      id: 1,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'profileId': PropertySchema(
      id: 2,
      name: r'profileId',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 3,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'updatedAtMs': PropertySchema(
      id: 4,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarOnboardingProfileEstimateSize,
  serialize: _isarOnboardingProfileSerialize,
  deserialize: _isarOnboardingProfileDeserialize,
  deserializeProp: _isarOnboardingProfileDeserializeProp,
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
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarOnboardingProfileGetId,
  getLinks: _isarOnboardingProfileGetLinks,
  attach: _isarOnboardingProfileAttach,
  version: '3.3.2',
);

int _isarOnboardingProfileEstimateSize(
  IsarOnboardingProfile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.profileId.length * 3;
  return bytesCount;
}

void _isarOnboardingProfileSerialize(
  IsarOnboardingProfile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.completedAtMs);
  writer.writeString(offsets[1], object.payloadJson);
  writer.writeString(offsets[2], object.profileId);
  writer.writeLong(offsets[3], object.schemaVersion);
  writer.writeLong(offsets[4], object.updatedAtMs);
}

IsarOnboardingProfile _isarOnboardingProfileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarOnboardingProfile();
  object.completedAtMs = reader.readLong(offsets[0]);
  object.id = id;
  object.payloadJson = reader.readString(offsets[1]);
  object.profileId = reader.readString(offsets[2]);
  object.schemaVersion = reader.readLong(offsets[3]);
  object.updatedAtMs = reader.readLong(offsets[4]);
  return object;
}

P _isarOnboardingProfileDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarOnboardingProfileGetId(IsarOnboardingProfile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarOnboardingProfileGetLinks(
  IsarOnboardingProfile object,
) {
  return [];
}

void _isarOnboardingProfileAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarOnboardingProfile object,
) {
  object.id = id;
}

extension IsarOnboardingProfileByIndex
    on IsarCollection<IsarOnboardingProfile> {
  Future<IsarOnboardingProfile?> getByProfileId(String profileId) {
    return getByIndex(r'profileId', [profileId]);
  }

  IsarOnboardingProfile? getByProfileIdSync(String profileId) {
    return getByIndexSync(r'profileId', [profileId]);
  }

  Future<bool> deleteByProfileId(String profileId) {
    return deleteByIndex(r'profileId', [profileId]);
  }

  bool deleteByProfileIdSync(String profileId) {
    return deleteByIndexSync(r'profileId', [profileId]);
  }

  Future<List<IsarOnboardingProfile?>> getAllByProfileId(
    List<String> profileIdValues,
  ) {
    final values = profileIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'profileId', values);
  }

  List<IsarOnboardingProfile?> getAllByProfileIdSync(
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

  Future<Id> putByProfileId(IsarOnboardingProfile object) {
    return putByIndex(r'profileId', object);
  }

  Id putByProfileIdSync(IsarOnboardingProfile object, {bool saveLinks = true}) {
    return putByIndexSync(r'profileId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByProfileId(List<IsarOnboardingProfile> objects) {
    return putAllByIndex(r'profileId', objects);
  }

  List<Id> putAllByProfileIdSync(
    List<IsarOnboardingProfile> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'profileId', objects, saveLinks: saveLinks);
  }
}

extension IsarOnboardingProfileQueryWhereSort
    on QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QWhere> {
  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarOnboardingProfileQueryWhere
    on
        QueryBuilder<
          IsarOnboardingProfile,
          IsarOnboardingProfile,
          QWhereClause
        > {
  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterWhereClause>
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

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterWhereClause>
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

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterWhereClause>
  profileIdEqualTo(String profileId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'profileId', value: [profileId]),
      );
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterWhereClause>
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
}

extension IsarOnboardingProfileQueryFilter
    on
        QueryBuilder<
          IsarOnboardingProfile,
          IsarOnboardingProfile,
          QFilterCondition
        > {
  QueryBuilder<
    IsarOnboardingProfile,
    IsarOnboardingProfile,
    QAfterFilterCondition
  >
  completedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'completedAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarOnboardingProfile,
    IsarOnboardingProfile,
    QAfterFilterCondition
  >
  completedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'completedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarOnboardingProfile,
    IsarOnboardingProfile,
    QAfterFilterCondition
  >
  completedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'completedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarOnboardingProfile,
    IsarOnboardingProfile,
    QAfterFilterCondition
  >
  completedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'completedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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
    IsarOnboardingProfile,
    IsarOnboardingProfile,
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

extension IsarOnboardingProfileQueryObject
    on
        QueryBuilder<
          IsarOnboardingProfile,
          IsarOnboardingProfile,
          QFilterCondition
        > {}

extension IsarOnboardingProfileQueryLinks
    on
        QueryBuilder<
          IsarOnboardingProfile,
          IsarOnboardingProfile,
          QFilterCondition
        > {}

extension IsarOnboardingProfileQuerySortBy
    on QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QSortBy> {
  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  sortByCompletedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  sortByCompletedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  sortByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  sortByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarOnboardingProfileQuerySortThenBy
    on QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QSortThenBy> {
  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenByCompletedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenByCompletedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarOnboardingProfileQueryWhereDistinct
    on QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QDistinct> {
  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QDistinct>
  distinctByCompletedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAtMs');
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QDistinct>
  distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QDistinct>
  distinctByProfileId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QDistinct>
  distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<IsarOnboardingProfile, IsarOnboardingProfile, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarOnboardingProfileQueryProperty
    on
        QueryBuilder<
          IsarOnboardingProfile,
          IsarOnboardingProfile,
          QQueryProperty
        > {
  QueryBuilder<IsarOnboardingProfile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarOnboardingProfile, int, QQueryOperations>
  completedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAtMs');
    });
  }

  QueryBuilder<IsarOnboardingProfile, String, QQueryOperations>
  payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<IsarOnboardingProfile, String, QQueryOperations>
  profileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileId');
    });
  }

  QueryBuilder<IsarOnboardingProfile, int, QQueryOperations>
  schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<IsarOnboardingProfile, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
