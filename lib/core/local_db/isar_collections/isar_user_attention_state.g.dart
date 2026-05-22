// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_user_attention_state.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarUserAttentionStateCollection on Isar {
  IsarCollection<IsarUserAttentionState> get isarUserAttentionStates =>
      this.collection();
}

const IsarUserAttentionStateSchema = CollectionSchema(
  name: r'IsarUserAttentionState',
  id: 3269574096215485165,
  properties: {
    r'activeOverride': PropertySchema(
      id: 0,
      name: r'activeOverride',
      type: IsarType.string,
    ),
    r'manuallyMuted': PropertySchema(
      id: 1,
      name: r'manuallyMuted',
      type: IsarType.bool,
    ),
    r'payloadJson': PropertySchema(
      id: 2,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 3,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'stateId': PropertySchema(
      id: 4,
      name: r'stateId',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 5,
      name: r'updatedAtMs',
      type: IsarType.long,
    )
  },
  estimateSize: _isarUserAttentionStateEstimateSize,
  serialize: _isarUserAttentionStateSerialize,
  deserialize: _isarUserAttentionStateDeserialize,
  deserializeProp: _isarUserAttentionStateDeserializeProp,
  idName: r'id',
  indexes: {
    r'stateId': IndexSchema(
      id: -1428154555284842722,
      name: r'stateId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'stateId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'activeOverride': IndexSchema(
      id: -8593269105968990230,
      name: r'activeOverride',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'activeOverride',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarUserAttentionStateGetId,
  getLinks: _isarUserAttentionStateGetLinks,
  attach: _isarUserAttentionStateAttach,
  version: '3.1.0+1',
);

int _isarUserAttentionStateEstimateSize(
  IsarUserAttentionState object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activeOverride.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.stateId.length * 3;
  return bytesCount;
}

void _isarUserAttentionStateSerialize(
  IsarUserAttentionState object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.activeOverride);
  writer.writeBool(offsets[1], object.manuallyMuted);
  writer.writeString(offsets[2], object.payloadJson);
  writer.writeLong(offsets[3], object.schemaVersion);
  writer.writeString(offsets[4], object.stateId);
  writer.writeLong(offsets[5], object.updatedAtMs);
}

IsarUserAttentionState _isarUserAttentionStateDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarUserAttentionState();
  object.activeOverride = reader.readString(offsets[0]);
  object.id = id;
  object.manuallyMuted = reader.readBool(offsets[1]);
  object.payloadJson = reader.readString(offsets[2]);
  object.schemaVersion = reader.readLong(offsets[3]);
  object.stateId = reader.readString(offsets[4]);
  object.updatedAtMs = reader.readLong(offsets[5]);
  return object;
}

P _isarUserAttentionStateDeserializeProp<P>(
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

Id _isarUserAttentionStateGetId(IsarUserAttentionState object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarUserAttentionStateGetLinks(
    IsarUserAttentionState object) {
  return [];
}

void _isarUserAttentionStateAttach(
    IsarCollection<dynamic> col, Id id, IsarUserAttentionState object) {
  object.id = id;
}

extension IsarUserAttentionStateByIndex
    on IsarCollection<IsarUserAttentionState> {
  Future<IsarUserAttentionState?> getByStateId(String stateId) {
    return getByIndex(r'stateId', [stateId]);
  }

  IsarUserAttentionState? getByStateIdSync(String stateId) {
    return getByIndexSync(r'stateId', [stateId]);
  }

  Future<bool> deleteByStateId(String stateId) {
    return deleteByIndex(r'stateId', [stateId]);
  }

  bool deleteByStateIdSync(String stateId) {
    return deleteByIndexSync(r'stateId', [stateId]);
  }

  Future<List<IsarUserAttentionState?>> getAllByStateId(
      List<String> stateIdValues) {
    final values = stateIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'stateId', values);
  }

  List<IsarUserAttentionState?> getAllByStateIdSync(
      List<String> stateIdValues) {
    final values = stateIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'stateId', values);
  }

  Future<int> deleteAllByStateId(List<String> stateIdValues) {
    final values = stateIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'stateId', values);
  }

  int deleteAllByStateIdSync(List<String> stateIdValues) {
    final values = stateIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'stateId', values);
  }

  Future<Id> putByStateId(IsarUserAttentionState object) {
    return putByIndex(r'stateId', object);
  }

  Id putByStateIdSync(IsarUserAttentionState object, {bool saveLinks = true}) {
    return putByIndexSync(r'stateId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByStateId(List<IsarUserAttentionState> objects) {
    return putAllByIndex(r'stateId', objects);
  }

  List<Id> putAllByStateIdSync(List<IsarUserAttentionState> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'stateId', objects, saveLinks: saveLinks);
  }
}

extension IsarUserAttentionStateQueryWhereSort
    on QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QWhere> {
  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarUserAttentionStateQueryWhere on QueryBuilder<
    IsarUserAttentionState, IsarUserAttentionState, QWhereClause> {
  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterWhereClause> stateIdEqualTo(String stateId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'stateId',
        value: [stateId],
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterWhereClause> stateIdNotEqualTo(String stateId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'stateId',
              lower: [],
              upper: [stateId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'stateId',
              lower: [stateId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'stateId',
              lower: [stateId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'stateId',
              lower: [],
              upper: [stateId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterWhereClause> activeOverrideEqualTo(String activeOverride) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'activeOverride',
        value: [activeOverride],
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterWhereClause> activeOverrideNotEqualTo(String activeOverride) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activeOverride',
              lower: [],
              upper: [activeOverride],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activeOverride',
              lower: [activeOverride],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activeOverride',
              lower: [activeOverride],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activeOverride',
              lower: [],
              upper: [activeOverride],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarUserAttentionStateQueryFilter on QueryBuilder<
    IsarUserAttentionState, IsarUserAttentionState, QFilterCondition> {
  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> activeOverrideEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activeOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> activeOverrideGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activeOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> activeOverrideLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activeOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> activeOverrideBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activeOverride',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> activeOverrideStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'activeOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> activeOverrideEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'activeOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
          QAfterFilterCondition>
      activeOverrideContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'activeOverride',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
          QAfterFilterCondition>
      activeOverrideMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'activeOverride',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> activeOverrideIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activeOverride',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> activeOverrideIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'activeOverride',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> manuallyMutedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'manuallyMuted',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> payloadJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> payloadJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> payloadJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> payloadJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payloadJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> payloadJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> payloadJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
          QAfterFilterCondition>
      payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
          QAfterFilterCondition>
      payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payloadJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> schemaVersionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> schemaVersionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> schemaVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'schemaVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> stateIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> stateIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> stateIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> stateIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stateId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> stateIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> stateIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
          QAfterFilterCondition>
      stateIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
          QAfterFilterCondition>
      stateIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stateId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> stateIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stateId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> stateIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stateId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> updatedAtMsGreaterThan(
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

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> updatedAtMsLessThan(
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

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState,
      QAfterFilterCondition> updatedAtMsBetween(
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

extension IsarUserAttentionStateQueryObject on QueryBuilder<
    IsarUserAttentionState, IsarUserAttentionState, QFilterCondition> {}

extension IsarUserAttentionStateQueryLinks on QueryBuilder<
    IsarUserAttentionState, IsarUserAttentionState, QFilterCondition> {}

extension IsarUserAttentionStateQuerySortBy
    on QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QSortBy> {
  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortByActiveOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeOverride', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortByActiveOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeOverride', Sort.desc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortByManuallyMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manuallyMuted', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortByManuallyMutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manuallyMuted', Sort.desc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortByStateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stateId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortByStateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stateId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarUserAttentionStateQuerySortThenBy on QueryBuilder<
    IsarUserAttentionState, IsarUserAttentionState, QSortThenBy> {
  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenByActiveOverride() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeOverride', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenByActiveOverrideDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeOverride', Sort.desc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenByManuallyMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manuallyMuted', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenByManuallyMutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manuallyMuted', Sort.desc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenByStateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stateId', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenByStateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stateId', Sort.desc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QAfterSortBy>
      thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarUserAttentionStateQueryWhereDistinct
    on QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QDistinct> {
  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QDistinct>
      distinctByActiveOverride({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activeOverride',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QDistinct>
      distinctByManuallyMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'manuallyMuted');
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QDistinct>
      distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QDistinct>
      distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QDistinct>
      distinctByStateId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stateId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarUserAttentionState, IsarUserAttentionState, QDistinct>
      distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarUserAttentionStateQueryProperty on QueryBuilder<
    IsarUserAttentionState, IsarUserAttentionState, QQueryProperty> {
  QueryBuilder<IsarUserAttentionState, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarUserAttentionState, String, QQueryOperations>
      activeOverrideProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activeOverride');
    });
  }

  QueryBuilder<IsarUserAttentionState, bool, QQueryOperations>
      manuallyMutedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manuallyMuted');
    });
  }

  QueryBuilder<IsarUserAttentionState, String, QQueryOperations>
      payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<IsarUserAttentionState, int, QQueryOperations>
      schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<IsarUserAttentionState, String, QQueryOperations>
      stateIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stateId');
    });
  }

  QueryBuilder<IsarUserAttentionState, int, QQueryOperations>
      updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
