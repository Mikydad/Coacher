// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_ai_interaction_history.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarAiInteractionHistoryCollection on Isar {
  IsarCollection<IsarAiInteractionHistory> get isarAiInteractionHistorys =>
      this.collection();
}

const IsarAiInteractionHistorySchema = CollectionSchema(
  name: r'IsarAiInteractionHistory',
  id: -5730539528741319728,
  properties: {
    r'confirmed': PropertySchema(
      id: 0,
      name: r'confirmed',
      type: IsarType.bool,
    ),
    r'executed': PropertySchema(
      id: 1,
      name: r'executed',
      type: IsarType.bool,
    ),
    r'parsedActionsJson': PropertySchema(
      id: 2,
      name: r'parsedActionsJson',
      type: IsarType.string,
    ),
    r'sessionId': PropertySchema(
      id: 3,
      name: r'sessionId',
      type: IsarType.string,
    ),
    r'timestampMs': PropertySchema(
      id: 4,
      name: r'timestampMs',
      type: IsarType.long,
    ),
    r'userInput': PropertySchema(
      id: 5,
      name: r'userInput',
      type: IsarType.string,
    )
  },
  estimateSize: _isarAiInteractionHistoryEstimateSize,
  serialize: _isarAiInteractionHistorySerialize,
  deserialize: _isarAiInteractionHistoryDeserialize,
  deserializeProp: _isarAiInteractionHistoryDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'sessionId': IndexSchema(
      id: 6949518585047923839,
      name: r'sessionId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestampMs': IndexSchema(
      id: -1672631967678536377,
      name: r'timestampMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestampMs',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarAiInteractionHistoryGetId,
  getLinks: _isarAiInteractionHistoryGetLinks,
  attach: _isarAiInteractionHistoryAttach,
  version: '3.1.0+1',
);

int _isarAiInteractionHistoryEstimateSize(
  IsarAiInteractionHistory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.parsedActionsJson.length * 3;
  bytesCount += 3 + object.sessionId.length * 3;
  bytesCount += 3 + object.userInput.length * 3;
  return bytesCount;
}

void _isarAiInteractionHistorySerialize(
  IsarAiInteractionHistory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.confirmed);
  writer.writeBool(offsets[1], object.executed);
  writer.writeString(offsets[2], object.parsedActionsJson);
  writer.writeString(offsets[3], object.sessionId);
  writer.writeLong(offsets[4], object.timestampMs);
  writer.writeString(offsets[5], object.userInput);
}

IsarAiInteractionHistory _isarAiInteractionHistoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAiInteractionHistory();
  object.confirmed = reader.readBool(offsets[0]);
  object.executed = reader.readBool(offsets[1]);
  object.isarId = id;
  object.parsedActionsJson = reader.readString(offsets[2]);
  object.sessionId = reader.readString(offsets[3]);
  object.timestampMs = reader.readLong(offsets[4]);
  object.userInput = reader.readString(offsets[5]);
  return object;
}

P _isarAiInteractionHistoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarAiInteractionHistoryGetId(IsarAiInteractionHistory object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _isarAiInteractionHistoryGetLinks(
    IsarAiInteractionHistory object) {
  return [];
}

void _isarAiInteractionHistoryAttach(
    IsarCollection<dynamic> col, Id id, IsarAiInteractionHistory object) {
  object.isarId = id;
}

extension IsarAiInteractionHistoryQueryWhereSort on QueryBuilder<
    IsarAiInteractionHistory, IsarAiInteractionHistory, QWhere> {
  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterWhere>
      anyTimestampMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestampMs'),
      );
    });
  }
}

extension IsarAiInteractionHistoryQueryWhere on QueryBuilder<
    IsarAiInteractionHistory, IsarAiInteractionHistory, QWhereClause> {
  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
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

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterWhereClause> isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterWhereClause> isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
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

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterWhereClause> sessionIdEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionId',
        value: [sessionId],
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterWhereClause> sessionIdNotEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [sessionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionId',
              lower: [],
              upper: [sessionId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterWhereClause> timestampMsEqualTo(int timestampMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestampMs',
        value: [timestampMs],
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterWhereClause> timestampMsNotEqualTo(int timestampMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestampMs',
              lower: [],
              upper: [timestampMs],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestampMs',
              lower: [timestampMs],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestampMs',
              lower: [timestampMs],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestampMs',
              lower: [],
              upper: [timestampMs],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterWhereClause> timestampMsGreaterThan(
    int timestampMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestampMs',
        lower: [timestampMs],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterWhereClause> timestampMsLessThan(
    int timestampMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestampMs',
        lower: [],
        upper: [timestampMs],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterWhereClause> timestampMsBetween(
    int lowerTimestampMs,
    int upperTimestampMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestampMs',
        lower: [lowerTimestampMs],
        includeLower: includeLower,
        upper: [upperTimestampMs],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarAiInteractionHistoryQueryFilter on QueryBuilder<
    IsarAiInteractionHistory, IsarAiInteractionHistory, QFilterCondition> {
  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> confirmedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confirmed',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> executedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'executed',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
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

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
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

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
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

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> parsedActionsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parsedActionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> parsedActionsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parsedActionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> parsedActionsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parsedActionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> parsedActionsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parsedActionsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> parsedActionsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'parsedActionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> parsedActionsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'parsedActionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
          QAfterFilterCondition>
      parsedActionsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'parsedActionsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
          QAfterFilterCondition>
      parsedActionsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'parsedActionsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> parsedActionsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parsedActionsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> parsedActionsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'parsedActionsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> sessionIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> sessionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> sessionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> sessionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> sessionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> sessionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
          QAfterFilterCondition>
      sessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
          QAfterFilterCondition>
      sessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> sessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> sessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> timestampMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestampMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> timestampMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestampMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> timestampMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestampMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> timestampMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestampMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> userInputEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> userInputGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> userInputLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> userInputBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userInput',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> userInputStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> userInputEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
          QAfterFilterCondition>
      userInputContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userInput',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
          QAfterFilterCondition>
      userInputMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userInput',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> userInputIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userInput',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory,
      QAfterFilterCondition> userInputIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userInput',
        value: '',
      ));
    });
  }
}

extension IsarAiInteractionHistoryQueryObject on QueryBuilder<
    IsarAiInteractionHistory, IsarAiInteractionHistory, QFilterCondition> {}

extension IsarAiInteractionHistoryQueryLinks on QueryBuilder<
    IsarAiInteractionHistory, IsarAiInteractionHistory, QFilterCondition> {}

extension IsarAiInteractionHistoryQuerySortBy on QueryBuilder<
    IsarAiInteractionHistory, IsarAiInteractionHistory, QSortBy> {
  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortByConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmed', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortByConfirmedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmed', Sort.desc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortByExecuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executed', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortByExecutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executed', Sort.desc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortByParsedActionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedActionsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortByParsedActionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedActionsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortByTimestampMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestampMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortByTimestampMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestampMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortByUserInput() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userInput', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      sortByUserInputDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userInput', Sort.desc);
    });
  }
}

extension IsarAiInteractionHistoryQuerySortThenBy on QueryBuilder<
    IsarAiInteractionHistory, IsarAiInteractionHistory, QSortThenBy> {
  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmed', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByConfirmedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmed', Sort.desc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByExecuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executed', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByExecutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executed', Sort.desc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByParsedActionsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedActionsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByParsedActionsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedActionsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByTimestampMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestampMs', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByTimestampMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestampMs', Sort.desc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByUserInput() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userInput', Sort.asc);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QAfterSortBy>
      thenByUserInputDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userInput', Sort.desc);
    });
  }
}

extension IsarAiInteractionHistoryQueryWhereDistinct on QueryBuilder<
    IsarAiInteractionHistory, IsarAiInteractionHistory, QDistinct> {
  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QDistinct>
      distinctByConfirmed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confirmed');
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QDistinct>
      distinctByExecuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'executed');
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QDistinct>
      distinctByParsedActionsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parsedActionsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QDistinct>
      distinctBySessionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QDistinct>
      distinctByTimestampMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestampMs');
    });
  }

  QueryBuilder<IsarAiInteractionHistory, IsarAiInteractionHistory, QDistinct>
      distinctByUserInput({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userInput', caseSensitive: caseSensitive);
    });
  }
}

extension IsarAiInteractionHistoryQueryProperty on QueryBuilder<
    IsarAiInteractionHistory, IsarAiInteractionHistory, QQueryProperty> {
  QueryBuilder<IsarAiInteractionHistory, int, QQueryOperations>
      isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<IsarAiInteractionHistory, bool, QQueryOperations>
      confirmedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confirmed');
    });
  }

  QueryBuilder<IsarAiInteractionHistory, bool, QQueryOperations>
      executedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'executed');
    });
  }

  QueryBuilder<IsarAiInteractionHistory, String, QQueryOperations>
      parsedActionsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parsedActionsJson');
    });
  }

  QueryBuilder<IsarAiInteractionHistory, String, QQueryOperations>
      sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }

  QueryBuilder<IsarAiInteractionHistory, int, QQueryOperations>
      timestampMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestampMs');
    });
  }

  QueryBuilder<IsarAiInteractionHistory, String, QQueryOperations>
      userInputProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userInput');
    });
  }
}
