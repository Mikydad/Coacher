// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_dismissed_suggestion_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarDismissedSuggestionLogCollection on Isar {
  IsarCollection<IsarDismissedSuggestionLog> get isarDismissedSuggestionLogs =>
      this.collection();
}

const IsarDismissedSuggestionLogSchema = CollectionSchema(
  name: r'IsarDismissedSuggestionLog',
  id: -4205061816515146905,
  properties: {
    r'dismissedAtMs': PropertySchema(
      id: 0,
      name: r'dismissedAtMs',
      type: IsarType.long,
    ),
    r'suggestionType': PropertySchema(
      id: 1,
      name: r'suggestionType',
      type: IsarType.string,
    )
  },
  estimateSize: _isarDismissedSuggestionLogEstimateSize,
  serialize: _isarDismissedSuggestionLogSerialize,
  deserialize: _isarDismissedSuggestionLogDeserialize,
  deserializeProp: _isarDismissedSuggestionLogDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'suggestionType': IndexSchema(
      id: -3842079562922254410,
      name: r'suggestionType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'suggestionType',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'dismissedAtMs': IndexSchema(
      id: 6740732623726247715,
      name: r'dismissedAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dismissedAtMs',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarDismissedSuggestionLogGetId,
  getLinks: _isarDismissedSuggestionLogGetLinks,
  attach: _isarDismissedSuggestionLogAttach,
  version: '3.1.0+1',
);

int _isarDismissedSuggestionLogEstimateSize(
  IsarDismissedSuggestionLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.suggestionType.length * 3;
  return bytesCount;
}

void _isarDismissedSuggestionLogSerialize(
  IsarDismissedSuggestionLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.dismissedAtMs);
  writer.writeString(offsets[1], object.suggestionType);
}

IsarDismissedSuggestionLog _isarDismissedSuggestionLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarDismissedSuggestionLog();
  object.dismissedAtMs = reader.readLong(offsets[0]);
  object.isarId = id;
  object.suggestionType = reader.readString(offsets[1]);
  return object;
}

P _isarDismissedSuggestionLogDeserializeProp<P>(
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarDismissedSuggestionLogGetId(IsarDismissedSuggestionLog object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _isarDismissedSuggestionLogGetLinks(
    IsarDismissedSuggestionLog object) {
  return [];
}

void _isarDismissedSuggestionLogAttach(
    IsarCollection<dynamic> col, Id id, IsarDismissedSuggestionLog object) {
  object.isarId = id;
}

extension IsarDismissedSuggestionLogQueryWhereSort on QueryBuilder<
    IsarDismissedSuggestionLog, IsarDismissedSuggestionLog, QWhere> {
  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhere> anyDismissedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dismissedAtMs'),
      );
    });
  }
}

extension IsarDismissedSuggestionLogQueryWhere on QueryBuilder<
    IsarDismissedSuggestionLog, IsarDismissedSuggestionLog, QWhereClause> {
  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> suggestionTypeEqualTo(String suggestionType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'suggestionType',
        value: [suggestionType],
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> suggestionTypeNotEqualTo(String suggestionType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'suggestionType',
              lower: [],
              upper: [suggestionType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'suggestionType',
              lower: [suggestionType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'suggestionType',
              lower: [suggestionType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'suggestionType',
              lower: [],
              upper: [suggestionType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> dismissedAtMsEqualTo(int dismissedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dismissedAtMs',
        value: [dismissedAtMs],
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> dismissedAtMsNotEqualTo(int dismissedAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dismissedAtMs',
              lower: [],
              upper: [dismissedAtMs],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dismissedAtMs',
              lower: [dismissedAtMs],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dismissedAtMs',
              lower: [dismissedAtMs],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dismissedAtMs',
              lower: [],
              upper: [dismissedAtMs],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> dismissedAtMsGreaterThan(
    int dismissedAtMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dismissedAtMs',
        lower: [dismissedAtMs],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> dismissedAtMsLessThan(
    int dismissedAtMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dismissedAtMs',
        lower: [],
        upper: [dismissedAtMs],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterWhereClause> dismissedAtMsBetween(
    int lowerDismissedAtMs,
    int upperDismissedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dismissedAtMs',
        lower: [lowerDismissedAtMs],
        includeLower: includeLower,
        upper: [upperDismissedAtMs],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarDismissedSuggestionLogQueryFilter on QueryBuilder<
    IsarDismissedSuggestionLog, IsarDismissedSuggestionLog, QFilterCondition> {
  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> dismissedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dismissedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> dismissedAtMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dismissedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> dismissedAtMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dismissedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> dismissedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dismissedAtMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> suggestionTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'suggestionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> suggestionTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'suggestionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> suggestionTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'suggestionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> suggestionTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'suggestionType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> suggestionTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'suggestionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> suggestionTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'suggestionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
          QAfterFilterCondition>
      suggestionTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'suggestionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
          QAfterFilterCondition>
      suggestionTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'suggestionType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> suggestionTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'suggestionType',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterFilterCondition> suggestionTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'suggestionType',
        value: '',
      ));
    });
  }
}

extension IsarDismissedSuggestionLogQueryObject on QueryBuilder<
    IsarDismissedSuggestionLog, IsarDismissedSuggestionLog, QFilterCondition> {}

extension IsarDismissedSuggestionLogQueryLinks on QueryBuilder<
    IsarDismissedSuggestionLog, IsarDismissedSuggestionLog, QFilterCondition> {}

extension IsarDismissedSuggestionLogQuerySortBy on QueryBuilder<
    IsarDismissedSuggestionLog, IsarDismissedSuggestionLog, QSortBy> {
  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterSortBy> sortByDismissedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dismissedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterSortBy> sortByDismissedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dismissedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterSortBy> sortBySuggestionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestionType', Sort.asc);
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterSortBy> sortBySuggestionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestionType', Sort.desc);
    });
  }
}

extension IsarDismissedSuggestionLogQuerySortThenBy on QueryBuilder<
    IsarDismissedSuggestionLog, IsarDismissedSuggestionLog, QSortThenBy> {
  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterSortBy> thenByDismissedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dismissedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterSortBy> thenByDismissedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dismissedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterSortBy> thenBySuggestionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestionType', Sort.asc);
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QAfterSortBy> thenBySuggestionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestionType', Sort.desc);
    });
  }
}

extension IsarDismissedSuggestionLogQueryWhereDistinct on QueryBuilder<
    IsarDismissedSuggestionLog, IsarDismissedSuggestionLog, QDistinct> {
  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QDistinct> distinctByDismissedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dismissedAtMs');
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, IsarDismissedSuggestionLog,
      QDistinct> distinctBySuggestionType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'suggestionType',
          caseSensitive: caseSensitive);
    });
  }
}

extension IsarDismissedSuggestionLogQueryProperty on QueryBuilder<
    IsarDismissedSuggestionLog, IsarDismissedSuggestionLog, QQueryProperty> {
  QueryBuilder<IsarDismissedSuggestionLog, int, QQueryOperations>
      isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, int, QQueryOperations>
      dismissedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dismissedAtMs');
    });
  }

  QueryBuilder<IsarDismissedSuggestionLog, String, QQueryOperations>
      suggestionTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'suggestionType');
    });
  }
}
