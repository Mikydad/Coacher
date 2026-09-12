// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_activity_category_rule.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarActivityCategoryRuleCollection on Isar {
  IsarCollection<IsarActivityCategoryRule> get isarActivityCategoryRules =>
      this.collection();
}

const IsarActivityCategoryRuleSchema = CollectionSchema(
  name: r'IsarActivityCategoryRule',
  id: -6545829425876680945,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'createdAtMs': PropertySchema(
      id: 1,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'normalizedText': PropertySchema(
      id: 2,
      name: r'normalizedText',
      type: IsarType.string,
    ),
    r'ruleId': PropertySchema(id: 3, name: r'ruleId', type: IsarType.string),
    r'sourceStorage': PropertySchema(
      id: 4,
      name: r'sourceStorage',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 5,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarActivityCategoryRuleEstimateSize,
  serialize: _isarActivityCategoryRuleSerialize,
  deserialize: _isarActivityCategoryRuleDeserialize,
  deserializeProp: _isarActivityCategoryRuleDeserializeProp,
  idName: r'id',
  indexes: {
    r'ruleId': IndexSchema(
      id: -7287016718321404572,
      name: r'ruleId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ruleId',
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
    r'normalizedText': IndexSchema(
      id: -8399031562658649671,
      name: r'normalizedText',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'normalizedText',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarActivityCategoryRuleGetId,
  getLinks: _isarActivityCategoryRuleGetLinks,
  attach: _isarActivityCategoryRuleAttach,
  version: '3.3.2',
);

int _isarActivityCategoryRuleEstimateSize(
  IsarActivityCategoryRule object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + object.normalizedText.length * 3;
  bytesCount += 3 + object.ruleId.length * 3;
  bytesCount += 3 + object.sourceStorage.length * 3;
  return bytesCount;
}

void _isarActivityCategoryRuleSerialize(
  IsarActivityCategoryRule object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeLong(offsets[1], object.createdAtMs);
  writer.writeString(offsets[2], object.normalizedText);
  writer.writeString(offsets[3], object.ruleId);
  writer.writeString(offsets[4], object.sourceStorage);
  writer.writeLong(offsets[5], object.updatedAtMs);
}

IsarActivityCategoryRule _isarActivityCategoryRuleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarActivityCategoryRule();
  object.category = reader.readString(offsets[0]);
  object.createdAtMs = reader.readLong(offsets[1]);
  object.id = id;
  object.normalizedText = reader.readString(offsets[2]);
  object.ruleId = reader.readString(offsets[3]);
  object.sourceStorage = reader.readString(offsets[4]);
  object.updatedAtMs = reader.readLong(offsets[5]);
  return object;
}

P _isarActivityCategoryRuleDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarActivityCategoryRuleGetId(IsarActivityCategoryRule object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarActivityCategoryRuleGetLinks(
  IsarActivityCategoryRule object,
) {
  return [];
}

void _isarActivityCategoryRuleAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarActivityCategoryRule object,
) {
  object.id = id;
}

extension IsarActivityCategoryRuleByIndex
    on IsarCollection<IsarActivityCategoryRule> {
  Future<IsarActivityCategoryRule?> getByRuleId(String ruleId) {
    return getByIndex(r'ruleId', [ruleId]);
  }

  IsarActivityCategoryRule? getByRuleIdSync(String ruleId) {
    return getByIndexSync(r'ruleId', [ruleId]);
  }

  Future<bool> deleteByRuleId(String ruleId) {
    return deleteByIndex(r'ruleId', [ruleId]);
  }

  bool deleteByRuleIdSync(String ruleId) {
    return deleteByIndexSync(r'ruleId', [ruleId]);
  }

  Future<List<IsarActivityCategoryRule?>> getAllByRuleId(
    List<String> ruleIdValues,
  ) {
    final values = ruleIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'ruleId', values);
  }

  List<IsarActivityCategoryRule?> getAllByRuleIdSync(
    List<String> ruleIdValues,
  ) {
    final values = ruleIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'ruleId', values);
  }

  Future<int> deleteAllByRuleId(List<String> ruleIdValues) {
    final values = ruleIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'ruleId', values);
  }

  int deleteAllByRuleIdSync(List<String> ruleIdValues) {
    final values = ruleIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'ruleId', values);
  }

  Future<Id> putByRuleId(IsarActivityCategoryRule object) {
    return putByIndex(r'ruleId', object);
  }

  Id putByRuleIdSync(IsarActivityCategoryRule object, {bool saveLinks = true}) {
    return putByIndexSync(r'ruleId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRuleId(List<IsarActivityCategoryRule> objects) {
    return putAllByIndex(r'ruleId', objects);
  }

  List<Id> putAllByRuleIdSync(
    List<IsarActivityCategoryRule> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'ruleId', objects, saveLinks: saveLinks);
  }

  Future<IsarActivityCategoryRule?> getByNormalizedText(String normalizedText) {
    return getByIndex(r'normalizedText', [normalizedText]);
  }

  IsarActivityCategoryRule? getByNormalizedTextSync(String normalizedText) {
    return getByIndexSync(r'normalizedText', [normalizedText]);
  }

  Future<bool> deleteByNormalizedText(String normalizedText) {
    return deleteByIndex(r'normalizedText', [normalizedText]);
  }

  bool deleteByNormalizedTextSync(String normalizedText) {
    return deleteByIndexSync(r'normalizedText', [normalizedText]);
  }

  Future<List<IsarActivityCategoryRule?>> getAllByNormalizedText(
    List<String> normalizedTextValues,
  ) {
    final values = normalizedTextValues.map((e) => [e]).toList();
    return getAllByIndex(r'normalizedText', values);
  }

  List<IsarActivityCategoryRule?> getAllByNormalizedTextSync(
    List<String> normalizedTextValues,
  ) {
    final values = normalizedTextValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'normalizedText', values);
  }

  Future<int> deleteAllByNormalizedText(List<String> normalizedTextValues) {
    final values = normalizedTextValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'normalizedText', values);
  }

  int deleteAllByNormalizedTextSync(List<String> normalizedTextValues) {
    final values = normalizedTextValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'normalizedText', values);
  }

  Future<Id> putByNormalizedText(IsarActivityCategoryRule object) {
    return putByIndex(r'normalizedText', object);
  }

  Id putByNormalizedTextSync(
    IsarActivityCategoryRule object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'normalizedText', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNormalizedText(
    List<IsarActivityCategoryRule> objects,
  ) {
    return putAllByIndex(r'normalizedText', objects);
  }

  List<Id> putAllByNormalizedTextSync(
    List<IsarActivityCategoryRule> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'normalizedText', objects, saveLinks: saveLinks);
  }
}

extension IsarActivityCategoryRuleQueryWhereSort
    on
        QueryBuilder<
          IsarActivityCategoryRule,
          IsarActivityCategoryRule,
          QWhere
        > {
  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterWhere>
  anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarActivityCategoryRuleQueryWhere
    on
        QueryBuilder<
          IsarActivityCategoryRule,
          IsarActivityCategoryRule,
          QWhereClause
        > {
  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterWhereClause
  >
  ruleIdEqualTo(String ruleId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'ruleId', value: [ruleId]),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterWhereClause
  >
  ruleIdNotEqualTo(String ruleId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ruleId',
                lower: [],
                upper: [ruleId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ruleId',
                lower: [ruleId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ruleId',
                lower: [ruleId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ruleId',
                lower: [],
                upper: [ruleId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterWhereClause
  >
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

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterWhereClause
  >
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

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterWhereClause
  >
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

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterWhereClause
  >
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

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterWhereClause
  >
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

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterWhereClause
  >
  normalizedTextEqualTo(String normalizedText) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'normalizedText',
          value: [normalizedText],
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterWhereClause
  >
  normalizedTextNotEqualTo(String normalizedText) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'normalizedText',
                lower: [],
                upper: [normalizedText],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'normalizedText',
                lower: [normalizedText],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'normalizedText',
                lower: [normalizedText],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'normalizedText',
                lower: [],
                upper: [normalizedText],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarActivityCategoryRuleQueryFilter
    on
        QueryBuilder<
          IsarActivityCategoryRule,
          IsarActivityCategoryRule,
          QFilterCondition
        > {
  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  categoryEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  categoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  categoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'category',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  normalizedTextEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'normalizedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  normalizedTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'normalizedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  normalizedTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'normalizedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  normalizedTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'normalizedText',
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  normalizedTextStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'normalizedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  normalizedTextEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'normalizedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  normalizedTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'normalizedText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  normalizedTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'normalizedText',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  normalizedTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'normalizedText', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  normalizedTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'normalizedText', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  ruleIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ruleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  ruleIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ruleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  ruleIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ruleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  ruleIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ruleId',
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  ruleIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ruleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  ruleIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ruleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  ruleIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ruleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  ruleIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ruleId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  ruleIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ruleId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  ruleIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ruleId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  sourceStorageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  sourceStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  sourceStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  sourceStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceStorage',
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  sourceStorageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  sourceStorageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  sourceStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  sourceStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceStorage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  sourceStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceStorage', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
    QAfterFilterCondition
  >
  sourceStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceStorage', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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
    IsarActivityCategoryRule,
    IsarActivityCategoryRule,
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

extension IsarActivityCategoryRuleQueryObject
    on
        QueryBuilder<
          IsarActivityCategoryRule,
          IsarActivityCategoryRule,
          QFilterCondition
        > {}

extension IsarActivityCategoryRuleQueryLinks
    on
        QueryBuilder<
          IsarActivityCategoryRule,
          IsarActivityCategoryRule,
          QFilterCondition
        > {}

extension IsarActivityCategoryRuleQuerySortBy
    on
        QueryBuilder<
          IsarActivityCategoryRule,
          IsarActivityCategoryRule,
          QSortBy
        > {
  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortByNormalizedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedText', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortByNormalizedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedText', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortByRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortByRuleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortBySourceStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortBySourceStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarActivityCategoryRuleQuerySortThenBy
    on
        QueryBuilder<
          IsarActivityCategoryRule,
          IsarActivityCategoryRule,
          QSortThenBy
        > {
  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenByNormalizedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedText', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenByNormalizedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedText', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenByRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenByRuleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenBySourceStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenBySourceStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarActivityCategoryRuleQueryWhereDistinct
    on
        QueryBuilder<
          IsarActivityCategoryRule,
          IsarActivityCategoryRule,
          QDistinct
        > {
  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QDistinct>
  distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QDistinct>
  distinctByNormalizedText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'normalizedText',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QDistinct>
  distinctByRuleId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ruleId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QDistinct>
  distinctBySourceStorage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceStorage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarActivityCategoryRule, IsarActivityCategoryRule, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarActivityCategoryRuleQueryProperty
    on
        QueryBuilder<
          IsarActivityCategoryRule,
          IsarActivityCategoryRule,
          QQueryProperty
        > {
  QueryBuilder<IsarActivityCategoryRule, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarActivityCategoryRule, String, QQueryOperations>
  categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<IsarActivityCategoryRule, int, QQueryOperations>
  createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarActivityCategoryRule, String, QQueryOperations>
  normalizedTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'normalizedText');
    });
  }

  QueryBuilder<IsarActivityCategoryRule, String, QQueryOperations>
  ruleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ruleId');
    });
  }

  QueryBuilder<IsarActivityCategoryRule, String, QQueryOperations>
  sourceStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceStorage');
    });
  }

  QueryBuilder<IsarActivityCategoryRule, int, QQueryOperations>
  updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
