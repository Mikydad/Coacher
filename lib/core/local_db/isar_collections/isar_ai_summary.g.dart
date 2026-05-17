// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_ai_summary.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarAiSummaryCollection on Isar {
  IsarCollection<IsarAiSummary> get isarAiSummarys => this.collection();
}

const IsarAiSummarySchema = CollectionSchema(
  name: r'IsarAiSummary',
  id: 8563880722318575337,
  properties: {
    r'focusId': PropertySchema(
      id: 0,
      name: r'focusId',
      type: IsarType.string,
    ),
    r'generatedAtMs': PropertySchema(
      id: 1,
      name: r'generatedAtMs',
      type: IsarType.long,
    ),
    r'isFallback': PropertySchema(
      id: 2,
      name: r'isFallback',
      type: IsarType.bool,
    ),
    r'payloadJson': PropertySchema(
      id: 3,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'promptVersion': PropertySchema(
      id: 4,
      name: r'promptVersion',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 5,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'summaryType': PropertySchema(
      id: 6,
      name: r'summaryType',
      type: IsarType.string,
    )
  },
  estimateSize: _isarAiSummaryEstimateSize,
  serialize: _isarAiSummarySerialize,
  deserialize: _isarAiSummaryDeserialize,
  deserializeProp: _isarAiSummaryDeserializeProp,
  idName: r'id',
  indexes: {
    r'focusId': IndexSchema(
      id: 3508210846612319627,
      name: r'focusId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'focusId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'summaryType': IndexSchema(
      id: 6721209222574675719,
      name: r'summaryType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'summaryType',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'isFallback': IndexSchema(
      id: -1367417756829658562,
      name: r'isFallback',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isFallback',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'generatedAtMs': IndexSchema(
      id: 175890871767624139,
      name: r'generatedAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'generatedAtMs',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarAiSummaryGetId,
  getLinks: _isarAiSummaryGetLinks,
  attach: _isarAiSummaryAttach,
  version: '3.1.0+1',
);

int _isarAiSummaryEstimateSize(
  IsarAiSummary object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.focusId.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.promptVersion.length * 3;
  bytesCount += 3 + object.summaryType.length * 3;
  return bytesCount;
}

void _isarAiSummarySerialize(
  IsarAiSummary object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.focusId);
  writer.writeLong(offsets[1], object.generatedAtMs);
  writer.writeBool(offsets[2], object.isFallback);
  writer.writeString(offsets[3], object.payloadJson);
  writer.writeString(offsets[4], object.promptVersion);
  writer.writeLong(offsets[5], object.schemaVersion);
  writer.writeString(offsets[6], object.summaryType);
}

IsarAiSummary _isarAiSummaryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAiSummary();
  object.focusId = reader.readString(offsets[0]);
  object.generatedAtMs = reader.readLong(offsets[1]);
  object.id = id;
  object.isFallback = reader.readBool(offsets[2]);
  object.payloadJson = reader.readString(offsets[3]);
  object.promptVersion = reader.readString(offsets[4]);
  object.schemaVersion = reader.readLong(offsets[5]);
  object.summaryType = reader.readString(offsets[6]);
  return object;
}

P _isarAiSummaryDeserializeProp<P>(
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
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarAiSummaryGetId(IsarAiSummary object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarAiSummaryGetLinks(IsarAiSummary object) {
  return [];
}

void _isarAiSummaryAttach(
    IsarCollection<dynamic> col, Id id, IsarAiSummary object) {
  object.id = id;
}

extension IsarAiSummaryByIndex on IsarCollection<IsarAiSummary> {
  Future<IsarAiSummary?> getByFocusId(String focusId) {
    return getByIndex(r'focusId', [focusId]);
  }

  IsarAiSummary? getByFocusIdSync(String focusId) {
    return getByIndexSync(r'focusId', [focusId]);
  }

  Future<bool> deleteByFocusId(String focusId) {
    return deleteByIndex(r'focusId', [focusId]);
  }

  bool deleteByFocusIdSync(String focusId) {
    return deleteByIndexSync(r'focusId', [focusId]);
  }

  Future<List<IsarAiSummary?>> getAllByFocusId(List<String> focusIdValues) {
    final values = focusIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'focusId', values);
  }

  List<IsarAiSummary?> getAllByFocusIdSync(List<String> focusIdValues) {
    final values = focusIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'focusId', values);
  }

  Future<int> deleteAllByFocusId(List<String> focusIdValues) {
    final values = focusIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'focusId', values);
  }

  int deleteAllByFocusIdSync(List<String> focusIdValues) {
    final values = focusIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'focusId', values);
  }

  Future<Id> putByFocusId(IsarAiSummary object) {
    return putByIndex(r'focusId', object);
  }

  Id putByFocusIdSync(IsarAiSummary object, {bool saveLinks = true}) {
    return putByIndexSync(r'focusId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFocusId(List<IsarAiSummary> objects) {
    return putAllByIndex(r'focusId', objects);
  }

  List<Id> putAllByFocusIdSync(List<IsarAiSummary> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'focusId', objects, saveLinks: saveLinks);
  }
}

extension IsarAiSummaryQueryWhereSort
    on QueryBuilder<IsarAiSummary, IsarAiSummary, QWhere> {
  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhere> anyIsFallback() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isFallback'),
      );
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhere> anyGeneratedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'generatedAtMs'),
      );
    });
  }
}

extension IsarAiSummaryQueryWhere
    on QueryBuilder<IsarAiSummary, IsarAiSummary, QWhereClause> {
  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause> focusIdEqualTo(
      String focusId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'focusId',
        value: [focusId],
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause>
      focusIdNotEqualTo(String focusId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'focusId',
              lower: [],
              upper: [focusId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'focusId',
              lower: [focusId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'focusId',
              lower: [focusId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'focusId',
              lower: [],
              upper: [focusId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause>
      summaryTypeEqualTo(String summaryType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'summaryType',
        value: [summaryType],
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause>
      summaryTypeNotEqualTo(String summaryType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'summaryType',
              lower: [],
              upper: [summaryType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'summaryType',
              lower: [summaryType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'summaryType',
              lower: [summaryType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'summaryType',
              lower: [],
              upper: [summaryType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause>
      isFallbackEqualTo(bool isFallback) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isFallback',
        value: [isFallback],
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause>
      isFallbackNotEqualTo(bool isFallback) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFallback',
              lower: [],
              upper: [isFallback],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFallback',
              lower: [isFallback],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFallback',
              lower: [isFallback],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFallback',
              lower: [],
              upper: [isFallback],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause>
      generatedAtMsEqualTo(int generatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'generatedAtMs',
        value: [generatedAtMs],
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause>
      generatedAtMsNotEqualTo(int generatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generatedAtMs',
              lower: [],
              upper: [generatedAtMs],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generatedAtMs',
              lower: [generatedAtMs],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generatedAtMs',
              lower: [generatedAtMs],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'generatedAtMs',
              lower: [],
              upper: [generatedAtMs],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause>
      generatedAtMsGreaterThan(
    int generatedAtMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'generatedAtMs',
        lower: [generatedAtMs],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause>
      generatedAtMsLessThan(
    int generatedAtMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'generatedAtMs',
        lower: [],
        upper: [generatedAtMs],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterWhereClause>
      generatedAtMsBetween(
    int lowerGeneratedAtMs,
    int upperGeneratedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'generatedAtMs',
        lower: [lowerGeneratedAtMs],
        includeLower: includeLower,
        upper: [upperGeneratedAtMs],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarAiSummaryQueryFilter
    on QueryBuilder<IsarAiSummary, IsarAiSummary, QFilterCondition> {
  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      focusIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'focusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      focusIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'focusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      focusIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'focusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      focusIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'focusId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      focusIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'focusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      focusIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'focusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      focusIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'focusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      focusIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'focusId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      focusIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'focusId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      focusIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'focusId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      generatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'generatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      generatedAtMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'generatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      generatedAtMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'generatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      generatedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'generatedAtMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      isFallbackEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFallback',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      payloadJsonEqualTo(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      payloadJsonGreaterThan(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      payloadJsonLessThan(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      payloadJsonBetween(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      payloadJsonStartsWith(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      payloadJsonEndsWith(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payloadJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      promptVersionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      promptVersionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'promptVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      promptVersionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'promptVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      promptVersionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'promptVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      promptVersionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'promptVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      promptVersionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'promptVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      promptVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'promptVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      promptVersionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'promptVersion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      promptVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'promptVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      promptVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'promptVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      schemaVersionGreaterThan(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      schemaVersionLessThan(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      schemaVersionBetween(
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

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      summaryTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'summaryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      summaryTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'summaryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      summaryTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'summaryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      summaryTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'summaryType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      summaryTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'summaryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      summaryTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'summaryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      summaryTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'summaryType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      summaryTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'summaryType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      summaryTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'summaryType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterFilterCondition>
      summaryTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'summaryType',
        value: '',
      ));
    });
  }
}

extension IsarAiSummaryQueryObject
    on QueryBuilder<IsarAiSummary, IsarAiSummary, QFilterCondition> {}

extension IsarAiSummaryQueryLinks
    on QueryBuilder<IsarAiSummary, IsarAiSummary, QFilterCondition> {}

extension IsarAiSummaryQuerySortBy
    on QueryBuilder<IsarAiSummary, IsarAiSummary, QSortBy> {
  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> sortByFocusId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusId', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> sortByFocusIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusId', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      sortByGeneratedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      sortByGeneratedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> sortByIsFallback() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFallback', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      sortByIsFallbackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFallback', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      sortByPromptVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      sortByPromptVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> sortBySummaryType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summaryType', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      sortBySummaryTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summaryType', Sort.desc);
    });
  }
}

extension IsarAiSummaryQuerySortThenBy
    on QueryBuilder<IsarAiSummary, IsarAiSummary, QSortThenBy> {
  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> thenByFocusId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusId', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> thenByFocusIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusId', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      thenByGeneratedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      thenByGeneratedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> thenByIsFallback() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFallback', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      thenByIsFallbackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFallback', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      thenByPromptVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      thenByPromptVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'promptVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy> thenBySummaryType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summaryType', Sort.asc);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QAfterSortBy>
      thenBySummaryTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summaryType', Sort.desc);
    });
  }
}

extension IsarAiSummaryQueryWhereDistinct
    on QueryBuilder<IsarAiSummary, IsarAiSummary, QDistinct> {
  QueryBuilder<IsarAiSummary, IsarAiSummary, QDistinct> distinctByFocusId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'focusId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QDistinct>
      distinctByGeneratedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'generatedAtMs');
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QDistinct> distinctByIsFallback() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFallback');
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QDistinct> distinctByPayloadJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QDistinct> distinctByPromptVersion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'promptVersion',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QDistinct>
      distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<IsarAiSummary, IsarAiSummary, QDistinct> distinctBySummaryType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'summaryType', caseSensitive: caseSensitive);
    });
  }
}

extension IsarAiSummaryQueryProperty
    on QueryBuilder<IsarAiSummary, IsarAiSummary, QQueryProperty> {
  QueryBuilder<IsarAiSummary, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarAiSummary, String, QQueryOperations> focusIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'focusId');
    });
  }

  QueryBuilder<IsarAiSummary, int, QQueryOperations> generatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'generatedAtMs');
    });
  }

  QueryBuilder<IsarAiSummary, bool, QQueryOperations> isFallbackProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFallback');
    });
  }

  QueryBuilder<IsarAiSummary, String, QQueryOperations> payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<IsarAiSummary, String, QQueryOperations>
      promptVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'promptVersion');
    });
  }

  QueryBuilder<IsarAiSummary, int, QQueryOperations> schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<IsarAiSummary, String, QQueryOperations> summaryTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'summaryType');
    });
  }
}
