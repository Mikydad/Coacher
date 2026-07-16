// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_blocked_user.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarBlockedUserCollection on Isar {
  IsarCollection<IsarBlockedUser> get isarBlockedUsers => this.collection();
}

const IsarBlockedUserSchema = CollectionSchema(
  name: r'IsarBlockedUser',
  id: -7944027769267431740,
  properties: {
    r'active': PropertySchema(id: 0, name: r'active', type: IsarType.bool),
    r'blockedUid': PropertySchema(
      id: 1,
      name: r'blockedUid',
      type: IsarType.string,
    ),
    r'createdAtMs': PropertySchema(
      id: 2,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'updatedAtMs': PropertySchema(
      id: 3,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarBlockedUserEstimateSize,
  serialize: _isarBlockedUserSerialize,
  deserialize: _isarBlockedUserDeserialize,
  deserializeProp: _isarBlockedUserDeserializeProp,
  idName: r'id',
  indexes: {
    r'blockedUid': IndexSchema(
      id: -1874856640962865745,
      name: r'blockedUid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'blockedUid',
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

  getId: _isarBlockedUserGetId,
  getLinks: _isarBlockedUserGetLinks,
  attach: _isarBlockedUserAttach,
  version: '3.3.2',
);

int _isarBlockedUserEstimateSize(
  IsarBlockedUser object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.blockedUid.length * 3;
  return bytesCount;
}

void _isarBlockedUserSerialize(
  IsarBlockedUser object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.active);
  writer.writeString(offsets[1], object.blockedUid);
  writer.writeLong(offsets[2], object.createdAtMs);
  writer.writeLong(offsets[3], object.updatedAtMs);
}

IsarBlockedUser _isarBlockedUserDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarBlockedUser();
  object.active = reader.readBool(offsets[0]);
  object.blockedUid = reader.readString(offsets[1]);
  object.createdAtMs = reader.readLong(offsets[2]);
  object.id = id;
  object.updatedAtMs = reader.readLong(offsets[3]);
  return object;
}

P _isarBlockedUserDeserializeProp<P>(
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarBlockedUserGetId(IsarBlockedUser object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarBlockedUserGetLinks(IsarBlockedUser object) {
  return [];
}

void _isarBlockedUserAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarBlockedUser object,
) {
  object.id = id;
}

extension IsarBlockedUserByIndex on IsarCollection<IsarBlockedUser> {
  Future<IsarBlockedUser?> getByBlockedUid(String blockedUid) {
    return getByIndex(r'blockedUid', [blockedUid]);
  }

  IsarBlockedUser? getByBlockedUidSync(String blockedUid) {
    return getByIndexSync(r'blockedUid', [blockedUid]);
  }

  Future<bool> deleteByBlockedUid(String blockedUid) {
    return deleteByIndex(r'blockedUid', [blockedUid]);
  }

  bool deleteByBlockedUidSync(String blockedUid) {
    return deleteByIndexSync(r'blockedUid', [blockedUid]);
  }

  Future<List<IsarBlockedUser?>> getAllByBlockedUid(
    List<String> blockedUidValues,
  ) {
    final values = blockedUidValues.map((e) => [e]).toList();
    return getAllByIndex(r'blockedUid', values);
  }

  List<IsarBlockedUser?> getAllByBlockedUidSync(List<String> blockedUidValues) {
    final values = blockedUidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'blockedUid', values);
  }

  Future<int> deleteAllByBlockedUid(List<String> blockedUidValues) {
    final values = blockedUidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'blockedUid', values);
  }

  int deleteAllByBlockedUidSync(List<String> blockedUidValues) {
    final values = blockedUidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'blockedUid', values);
  }

  Future<Id> putByBlockedUid(IsarBlockedUser object) {
    return putByIndex(r'blockedUid', object);
  }

  Id putByBlockedUidSync(IsarBlockedUser object, {bool saveLinks = true}) {
    return putByIndexSync(r'blockedUid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBlockedUid(List<IsarBlockedUser> objects) {
    return putAllByIndex(r'blockedUid', objects);
  }

  List<Id> putAllByBlockedUidSync(
    List<IsarBlockedUser> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'blockedUid', objects, saveLinks: saveLinks);
  }
}

extension IsarBlockedUserQueryWhereSort
    on QueryBuilder<IsarBlockedUser, IsarBlockedUser, QWhere> {
  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhere> anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarBlockedUserQueryWhere
    on QueryBuilder<IsarBlockedUser, IsarBlockedUser, QWhereClause> {
  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause>
  blockedUidEqualTo(String blockedUid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'blockedUid', value: [blockedUid]),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause>
  blockedUidNotEqualTo(String blockedUid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockedUid',
                lower: [],
                upper: [blockedUid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockedUid',
                lower: [blockedUid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockedUid',
                lower: [blockedUid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'blockedUid',
                lower: [],
                upper: [blockedUid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterWhereClause>
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

extension IsarBlockedUserQueryFilter
    on QueryBuilder<IsarBlockedUser, IsarBlockedUser, QFilterCondition> {
  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  activeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'active', value: value),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  blockedUidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'blockedUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  blockedUidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'blockedUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  blockedUidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'blockedUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  blockedUidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'blockedUid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  blockedUidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'blockedUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  blockedUidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'blockedUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  blockedUidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'blockedUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  blockedUidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'blockedUid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  blockedUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'blockedUid', value: ''),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  blockedUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'blockedUid', value: ''),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
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

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterFilterCondition>
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

extension IsarBlockedUserQueryObject
    on QueryBuilder<IsarBlockedUser, IsarBlockedUser, QFilterCondition> {}

extension IsarBlockedUserQueryLinks
    on QueryBuilder<IsarBlockedUser, IsarBlockedUser, QFilterCondition> {}

extension IsarBlockedUserQuerySortBy
    on QueryBuilder<IsarBlockedUser, IsarBlockedUser, QSortBy> {
  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy> sortByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  sortByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  sortByBlockedUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedUid', Sort.asc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  sortByBlockedUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedUid', Sort.desc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarBlockedUserQuerySortThenBy
    on QueryBuilder<IsarBlockedUser, IsarBlockedUser, QSortThenBy> {
  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy> thenByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  thenByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  thenByBlockedUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedUid', Sort.asc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  thenByBlockedUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedUid', Sort.desc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarBlockedUserQueryWhereDistinct
    on QueryBuilder<IsarBlockedUser, IsarBlockedUser, QDistinct> {
  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QDistinct> distinctByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'active');
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QDistinct>
  distinctByBlockedUid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockedUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarBlockedUser, IsarBlockedUser, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarBlockedUserQueryProperty
    on QueryBuilder<IsarBlockedUser, IsarBlockedUser, QQueryProperty> {
  QueryBuilder<IsarBlockedUser, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarBlockedUser, bool, QQueryOperations> activeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'active');
    });
  }

  QueryBuilder<IsarBlockedUser, String, QQueryOperations> blockedUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockedUid');
    });
  }

  QueryBuilder<IsarBlockedUser, int, QQueryOperations> createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarBlockedUser, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
