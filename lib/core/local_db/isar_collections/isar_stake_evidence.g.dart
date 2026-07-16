// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_stake_evidence.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarStakeEvidenceCollection on Isar {
  IsarCollection<IsarStakeEvidence> get isarStakeEvidences => this.collection();
}

const IsarStakeEvidenceSchema = CollectionSchema(
  name: r'IsarStakeEvidence',
  id: -8589161560029925312,
  properties: {
    r'amount': PropertySchema(id: 0, name: r'amount', type: IsarType.long),
    r'challengeId': PropertySchema(
      id: 1,
      name: r'challengeId',
      type: IsarType.string,
    ),
    r'evidenceId': PropertySchema(
      id: 2,
      name: r'evidenceId',
      type: IsarType.string,
    ),
    r'recordedAtMs': PropertySchema(
      id: 3,
      name: r'recordedAtMs',
      type: IsarType.long,
    ),
    r'source': PropertySchema(id: 4, name: r'source', type: IsarType.string),
    r'uid': PropertySchema(id: 5, name: r'uid', type: IsarType.string),
    r'unitIndex': PropertySchema(
      id: 6,
      name: r'unitIndex',
      type: IsarType.long,
    ),
    r'updatedAtMs': PropertySchema(
      id: 7,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarStakeEvidenceEstimateSize,
  serialize: _isarStakeEvidenceSerialize,
  deserialize: _isarStakeEvidenceDeserialize,
  deserializeProp: _isarStakeEvidenceDeserializeProp,
  idName: r'id',
  indexes: {
    r'evidenceId': IndexSchema(
      id: -6687577171979035414,
      name: r'evidenceId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'evidenceId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'challengeId': IndexSchema(
      id: 4483557487511118379,
      name: r'challengeId',
      unique: false,
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
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarStakeEvidenceGetId,
  getLinks: _isarStakeEvidenceGetLinks,
  attach: _isarStakeEvidenceAttach,
  version: '3.3.2',
);

int _isarStakeEvidenceEstimateSize(
  IsarStakeEvidence object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.challengeId.length * 3;
  bytesCount += 3 + object.evidenceId.length * 3;
  bytesCount += 3 + object.source.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _isarStakeEvidenceSerialize(
  IsarStakeEvidence object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.amount);
  writer.writeString(offsets[1], object.challengeId);
  writer.writeString(offsets[2], object.evidenceId);
  writer.writeLong(offsets[3], object.recordedAtMs);
  writer.writeString(offsets[4], object.source);
  writer.writeString(offsets[5], object.uid);
  writer.writeLong(offsets[6], object.unitIndex);
  writer.writeLong(offsets[7], object.updatedAtMs);
}

IsarStakeEvidence _isarStakeEvidenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarStakeEvidence();
  object.amount = reader.readLong(offsets[0]);
  object.challengeId = reader.readString(offsets[1]);
  object.evidenceId = reader.readString(offsets[2]);
  object.id = id;
  object.recordedAtMs = reader.readLong(offsets[3]);
  object.source = reader.readString(offsets[4]);
  object.uid = reader.readString(offsets[5]);
  object.unitIndex = reader.readLong(offsets[6]);
  object.updatedAtMs = reader.readLong(offsets[7]);
  return object;
}

P _isarStakeEvidenceDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarStakeEvidenceGetId(IsarStakeEvidence object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarStakeEvidenceGetLinks(
  IsarStakeEvidence object,
) {
  return [];
}

void _isarStakeEvidenceAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarStakeEvidence object,
) {
  object.id = id;
}

extension IsarStakeEvidenceByIndex on IsarCollection<IsarStakeEvidence> {
  Future<IsarStakeEvidence?> getByEvidenceId(String evidenceId) {
    return getByIndex(r'evidenceId', [evidenceId]);
  }

  IsarStakeEvidence? getByEvidenceIdSync(String evidenceId) {
    return getByIndexSync(r'evidenceId', [evidenceId]);
  }

  Future<bool> deleteByEvidenceId(String evidenceId) {
    return deleteByIndex(r'evidenceId', [evidenceId]);
  }

  bool deleteByEvidenceIdSync(String evidenceId) {
    return deleteByIndexSync(r'evidenceId', [evidenceId]);
  }

  Future<List<IsarStakeEvidence?>> getAllByEvidenceId(
    List<String> evidenceIdValues,
  ) {
    final values = evidenceIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'evidenceId', values);
  }

  List<IsarStakeEvidence?> getAllByEvidenceIdSync(
    List<String> evidenceIdValues,
  ) {
    final values = evidenceIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'evidenceId', values);
  }

  Future<int> deleteAllByEvidenceId(List<String> evidenceIdValues) {
    final values = evidenceIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'evidenceId', values);
  }

  int deleteAllByEvidenceIdSync(List<String> evidenceIdValues) {
    final values = evidenceIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'evidenceId', values);
  }

  Future<Id> putByEvidenceId(IsarStakeEvidence object) {
    return putByIndex(r'evidenceId', object);
  }

  Id putByEvidenceIdSync(IsarStakeEvidence object, {bool saveLinks = true}) {
    return putByIndexSync(r'evidenceId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEvidenceId(List<IsarStakeEvidence> objects) {
    return putAllByIndex(r'evidenceId', objects);
  }

  List<Id> putAllByEvidenceIdSync(
    List<IsarStakeEvidence> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'evidenceId', objects, saveLinks: saveLinks);
  }
}

extension IsarStakeEvidenceQueryWhereSort
    on QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QWhere> {
  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhere>
  anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarStakeEvidenceQueryWhere
    on QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QWhereClause> {
  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
  evidenceIdEqualTo(String evidenceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'evidenceId', value: [evidenceId]),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
  evidenceIdNotEqualTo(String evidenceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceId',
                lower: [],
                upper: [evidenceId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceId',
                lower: [evidenceId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceId',
                lower: [evidenceId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceId',
                lower: [],
                upper: [evidenceId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterWhereClause>
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

extension IsarStakeEvidenceQueryFilter
    on QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QFilterCondition> {
  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  amountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'amount', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  amountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'amount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  amountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'amount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  amountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'amount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  challengeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'challengeId', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  challengeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'challengeId', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  evidenceIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'evidenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  evidenceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'evidenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  evidenceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'evidenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  evidenceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'evidenceId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  evidenceIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'evidenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  evidenceIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'evidenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  evidenceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'evidenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  evidenceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'evidenceId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  evidenceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'evidenceId', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  evidenceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'evidenceId', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  recordedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'recordedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  recordedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'recordedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  recordedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'recordedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  recordedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'recordedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  sourceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  sourceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  sourceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'source',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  uidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  uidLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  uidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  uidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  unitIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'unitIndex', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  unitIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'unitIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  unitIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'unitIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  unitIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'unitIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterFilterCondition>
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

extension IsarStakeEvidenceQueryObject
    on QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QFilterCondition> {}

extension IsarStakeEvidenceQueryLinks
    on QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QFilterCondition> {}

extension IsarStakeEvidenceQuerySortBy
    on QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QSortBy> {
  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByChallengeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'challengeId', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByChallengeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'challengeId', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByEvidenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceId', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByEvidenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceId', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByRecordedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByRecordedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByUnitIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByUnitIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarStakeEvidenceQuerySortThenBy
    on QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QSortThenBy> {
  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByChallengeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'challengeId', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByChallengeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'challengeId', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByEvidenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceId', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByEvidenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceId', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByRecordedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByRecordedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByUnitIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitIndex', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByUnitIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitIndex', Sort.desc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarStakeEvidenceQueryWhereDistinct
    on QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QDistinct> {
  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QDistinct>
  distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QDistinct>
  distinctByChallengeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'challengeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QDistinct>
  distinctByEvidenceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'evidenceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QDistinct>
  distinctByRecordedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recordedAtMs');
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QDistinct>
  distinctBySource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QDistinct> distinctByUid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QDistinct>
  distinctByUnitIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unitIndex');
    });
  }

  QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarStakeEvidenceQueryProperty
    on QueryBuilder<IsarStakeEvidence, IsarStakeEvidence, QQueryProperty> {
  QueryBuilder<IsarStakeEvidence, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarStakeEvidence, int, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<IsarStakeEvidence, String, QQueryOperations>
  challengeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'challengeId');
    });
  }

  QueryBuilder<IsarStakeEvidence, String, QQueryOperations>
  evidenceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'evidenceId');
    });
  }

  QueryBuilder<IsarStakeEvidence, int, QQueryOperations>
  recordedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recordedAtMs');
    });
  }

  QueryBuilder<IsarStakeEvidence, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<IsarStakeEvidence, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<IsarStakeEvidence, int, QQueryOperations> unitIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unitIndex');
    });
  }

  QueryBuilder<IsarStakeEvidence, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
