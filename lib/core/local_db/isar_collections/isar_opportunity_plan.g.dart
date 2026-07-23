// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_opportunity_plan.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarOpportunityPlanCollection on Isar {
  IsarCollection<IsarOpportunityPlan> get isarOpportunityPlans =>
      this.collection();
}

const IsarOpportunityPlanSchema = CollectionSchema(
  name: r'IsarOpportunityPlan',
  id: -4947842511870375156,
  properties: {
    r'computedAtMs': PropertySchema(
      id: 0,
      name: r'computedAtMs',
      type: IsarType.long,
    ),
    r'inputsHash': PropertySchema(
      id: 1,
      name: r'inputsHash',
      type: IsarType.string,
    ),
    r'intentionId': PropertySchema(
      id: 2,
      name: r'intentionId',
      type: IsarType.string,
    ),
    r'slotsJson': PropertySchema(
      id: 3,
      name: r'slotsJson',
      type: IsarType.string,
    ),
  },

  estimateSize: _isarOpportunityPlanEstimateSize,
  serialize: _isarOpportunityPlanSerialize,
  deserialize: _isarOpportunityPlanDeserialize,
  deserializeProp: _isarOpportunityPlanDeserializeProp,
  idName: r'id',
  indexes: {
    r'intentionId': IndexSchema(
      id: 4865538607370353671,
      name: r'intentionId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'intentionId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarOpportunityPlanGetId,
  getLinks: _isarOpportunityPlanGetLinks,
  attach: _isarOpportunityPlanAttach,
  version: '3.3.2',
);

int _isarOpportunityPlanEstimateSize(
  IsarOpportunityPlan object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.inputsHash.length * 3;
  bytesCount += 3 + object.intentionId.length * 3;
  bytesCount += 3 + object.slotsJson.length * 3;
  return bytesCount;
}

void _isarOpportunityPlanSerialize(
  IsarOpportunityPlan object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.computedAtMs);
  writer.writeString(offsets[1], object.inputsHash);
  writer.writeString(offsets[2], object.intentionId);
  writer.writeString(offsets[3], object.slotsJson);
}

IsarOpportunityPlan _isarOpportunityPlanDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarOpportunityPlan();
  object.computedAtMs = reader.readLong(offsets[0]);
  object.id = id;
  object.inputsHash = reader.readString(offsets[1]);
  object.intentionId = reader.readString(offsets[2]);
  object.slotsJson = reader.readString(offsets[3]);
  return object;
}

P _isarOpportunityPlanDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarOpportunityPlanGetId(IsarOpportunityPlan object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarOpportunityPlanGetLinks(
  IsarOpportunityPlan object,
) {
  return [];
}

void _isarOpportunityPlanAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarOpportunityPlan object,
) {
  object.id = id;
}

extension IsarOpportunityPlanByIndex on IsarCollection<IsarOpportunityPlan> {
  Future<IsarOpportunityPlan?> getByIntentionId(String intentionId) {
    return getByIndex(r'intentionId', [intentionId]);
  }

  IsarOpportunityPlan? getByIntentionIdSync(String intentionId) {
    return getByIndexSync(r'intentionId', [intentionId]);
  }

  Future<bool> deleteByIntentionId(String intentionId) {
    return deleteByIndex(r'intentionId', [intentionId]);
  }

  bool deleteByIntentionIdSync(String intentionId) {
    return deleteByIndexSync(r'intentionId', [intentionId]);
  }

  Future<List<IsarOpportunityPlan?>> getAllByIntentionId(
    List<String> intentionIdValues,
  ) {
    final values = intentionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'intentionId', values);
  }

  List<IsarOpportunityPlan?> getAllByIntentionIdSync(
    List<String> intentionIdValues,
  ) {
    final values = intentionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'intentionId', values);
  }

  Future<int> deleteAllByIntentionId(List<String> intentionIdValues) {
    final values = intentionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'intentionId', values);
  }

  int deleteAllByIntentionIdSync(List<String> intentionIdValues) {
    final values = intentionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'intentionId', values);
  }

  Future<Id> putByIntentionId(IsarOpportunityPlan object) {
    return putByIndex(r'intentionId', object);
  }

  Id putByIntentionIdSync(IsarOpportunityPlan object, {bool saveLinks = true}) {
    return putByIndexSync(r'intentionId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByIntentionId(List<IsarOpportunityPlan> objects) {
    return putAllByIndex(r'intentionId', objects);
  }

  List<Id> putAllByIntentionIdSync(
    List<IsarOpportunityPlan> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'intentionId', objects, saveLinks: saveLinks);
  }
}

extension IsarOpportunityPlanQueryWhereSort
    on QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QWhere> {
  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarOpportunityPlanQueryWhere
    on QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QWhereClause> {
  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterWhereClause>
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

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterWhereClause>
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

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterWhereClause>
  intentionIdEqualTo(String intentionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'intentionId',
          value: [intentionId],
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterWhereClause>
  intentionIdNotEqualTo(String intentionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intentionId',
                lower: [],
                upper: [intentionId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intentionId',
                lower: [intentionId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intentionId',
                lower: [intentionId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intentionId',
                lower: [],
                upper: [intentionId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarOpportunityPlanQueryFilter
    on
        QueryBuilder<
          IsarOpportunityPlan,
          IsarOpportunityPlan,
          QFilterCondition
        > {
  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  computedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'computedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  computedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'computedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  computedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'computedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  computedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'computedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
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

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  inputsHashEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'inputsHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  inputsHashGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'inputsHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  inputsHashLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'inputsHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  inputsHashBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'inputsHash',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  inputsHashStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'inputsHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  inputsHashEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'inputsHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  inputsHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'inputsHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  inputsHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'inputsHash',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  inputsHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'inputsHash', value: ''),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  inputsHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'inputsHash', value: ''),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  intentionIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  intentionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  intentionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  intentionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'intentionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  intentionIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  intentionIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  intentionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  intentionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'intentionId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  intentionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'intentionId', value: ''),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  intentionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'intentionId', value: ''),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  slotsJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'slotsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  slotsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'slotsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  slotsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'slotsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  slotsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'slotsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  slotsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'slotsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  slotsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'slotsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  slotsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'slotsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  slotsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'slotsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  slotsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'slotsJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterFilterCondition>
  slotsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'slotsJson', value: ''),
      );
    });
  }
}

extension IsarOpportunityPlanQueryObject
    on
        QueryBuilder<
          IsarOpportunityPlan,
          IsarOpportunityPlan,
          QFilterCondition
        > {}

extension IsarOpportunityPlanQueryLinks
    on
        QueryBuilder<
          IsarOpportunityPlan,
          IsarOpportunityPlan,
          QFilterCondition
        > {}

extension IsarOpportunityPlanQuerySortBy
    on QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QSortBy> {
  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  sortByComputedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  sortByComputedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  sortByInputsHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputsHash', Sort.asc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  sortByInputsHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputsHash', Sort.desc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  sortByIntentionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intentionId', Sort.asc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  sortByIntentionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intentionId', Sort.desc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  sortBySlotsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slotsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  sortBySlotsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slotsJson', Sort.desc);
    });
  }
}

extension IsarOpportunityPlanQuerySortThenBy
    on QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QSortThenBy> {
  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  thenByComputedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  thenByComputedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  thenByInputsHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputsHash', Sort.asc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  thenByInputsHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputsHash', Sort.desc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  thenByIntentionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intentionId', Sort.asc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  thenByIntentionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intentionId', Sort.desc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  thenBySlotsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slotsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QAfterSortBy>
  thenBySlotsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slotsJson', Sort.desc);
    });
  }
}

extension IsarOpportunityPlanQueryWhereDistinct
    on QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QDistinct> {
  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QDistinct>
  distinctByComputedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'computedAtMs');
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QDistinct>
  distinctByInputsHash({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inputsHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QDistinct>
  distinctByIntentionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intentionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QDistinct>
  distinctBySlotsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'slotsJson', caseSensitive: caseSensitive);
    });
  }
}

extension IsarOpportunityPlanQueryProperty
    on QueryBuilder<IsarOpportunityPlan, IsarOpportunityPlan, QQueryProperty> {
  QueryBuilder<IsarOpportunityPlan, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarOpportunityPlan, int, QQueryOperations>
  computedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'computedAtMs');
    });
  }

  QueryBuilder<IsarOpportunityPlan, String, QQueryOperations>
  inputsHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inputsHash');
    });
  }

  QueryBuilder<IsarOpportunityPlan, String, QQueryOperations>
  intentionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intentionId');
    });
  }

  QueryBuilder<IsarOpportunityPlan, String, QQueryOperations>
  slotsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'slotsJson');
    });
  }
}
