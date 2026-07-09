// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_coaching_focus.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarCoachingFocusCollection on Isar {
  IsarCollection<IsarCoachingFocus> get isarCoachingFocus => this.collection();
}

const IsarCoachingFocusSchema = CollectionSchema(
  name: r'IsarCoachingFocus',
  id: -6649502899778974055,
  properties: {
    r'activeUntilMs': PropertySchema(
      id: 0,
      name: r'activeUntilMs',
      type: IsarType.long,
    ),
    r'detectedAtMs': PropertySchema(
      id: 1,
      name: r'detectedAtMs',
      type: IsarType.long,
    ),
    r'focusId': PropertySchema(id: 2, name: r'focusId', type: IsarType.string),
    r'lifecycleState': PropertySchema(
      id: 3,
      name: r'lifecycleState',
      type: IsarType.string,
    ),
    r'payloadJson': PropertySchema(
      id: 4,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'primaryInsightId': PropertySchema(
      id: 5,
      name: r'primaryInsightId',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 6,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarCoachingFocusEstimateSize,
  serialize: _isarCoachingFocusSerialize,
  deserialize: _isarCoachingFocusDeserialize,
  deserializeProp: _isarCoachingFocusDeserializeProp,
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
        ),
      ],
    ),
    r'lifecycleState': IndexSchema(
      id: -9106322295718766577,
      name: r'lifecycleState',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lifecycleState',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'detectedAtMs': IndexSchema(
      id: 2550094987385378101,
      name: r'detectedAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'detectedAtMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'activeUntilMs': IndexSchema(
      id: -8967905460609201214,
      name: r'activeUntilMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'activeUntilMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarCoachingFocusGetId,
  getLinks: _isarCoachingFocusGetLinks,
  attach: _isarCoachingFocusAttach,
  version: '3.3.2',
);

int _isarCoachingFocusEstimateSize(
  IsarCoachingFocus object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.focusId.length * 3;
  bytesCount += 3 + object.lifecycleState.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.primaryInsightId.length * 3;
  return bytesCount;
}

void _isarCoachingFocusSerialize(
  IsarCoachingFocus object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.activeUntilMs);
  writer.writeLong(offsets[1], object.detectedAtMs);
  writer.writeString(offsets[2], object.focusId);
  writer.writeString(offsets[3], object.lifecycleState);
  writer.writeString(offsets[4], object.payloadJson);
  writer.writeString(offsets[5], object.primaryInsightId);
  writer.writeLong(offsets[6], object.schemaVersion);
}

IsarCoachingFocus _isarCoachingFocusDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarCoachingFocus();
  object.activeUntilMs = reader.readLong(offsets[0]);
  object.detectedAtMs = reader.readLong(offsets[1]);
  object.focusId = reader.readString(offsets[2]);
  object.id = id;
  object.lifecycleState = reader.readString(offsets[3]);
  object.payloadJson = reader.readString(offsets[4]);
  object.primaryInsightId = reader.readString(offsets[5]);
  object.schemaVersion = reader.readLong(offsets[6]);
  return object;
}

P _isarCoachingFocusDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarCoachingFocusGetId(IsarCoachingFocus object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarCoachingFocusGetLinks(
  IsarCoachingFocus object,
) {
  return [];
}

void _isarCoachingFocusAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarCoachingFocus object,
) {
  object.id = id;
}

extension IsarCoachingFocusByIndex on IsarCollection<IsarCoachingFocus> {
  Future<IsarCoachingFocus?> getByFocusId(String focusId) {
    return getByIndex(r'focusId', [focusId]);
  }

  IsarCoachingFocus? getByFocusIdSync(String focusId) {
    return getByIndexSync(r'focusId', [focusId]);
  }

  Future<bool> deleteByFocusId(String focusId) {
    return deleteByIndex(r'focusId', [focusId]);
  }

  bool deleteByFocusIdSync(String focusId) {
    return deleteByIndexSync(r'focusId', [focusId]);
  }

  Future<List<IsarCoachingFocus?>> getAllByFocusId(List<String> focusIdValues) {
    final values = focusIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'focusId', values);
  }

  List<IsarCoachingFocus?> getAllByFocusIdSync(List<String> focusIdValues) {
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

  Future<Id> putByFocusId(IsarCoachingFocus object) {
    return putByIndex(r'focusId', object);
  }

  Id putByFocusIdSync(IsarCoachingFocus object, {bool saveLinks = true}) {
    return putByIndexSync(r'focusId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFocusId(List<IsarCoachingFocus> objects) {
    return putAllByIndex(r'focusId', objects);
  }

  List<Id> putAllByFocusIdSync(
    List<IsarCoachingFocus> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'focusId', objects, saveLinks: saveLinks);
  }
}

extension IsarCoachingFocusQueryWhereSort
    on QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QWhere> {
  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhere>
  anyDetectedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'detectedAtMs'),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhere>
  anyActiveUntilMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'activeUntilMs'),
      );
    });
  }
}

extension IsarCoachingFocusQueryWhere
    on QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QWhereClause> {
  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  focusIdEqualTo(String focusId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'focusId', value: [focusId]),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  focusIdNotEqualTo(String focusId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'focusId',
                lower: [],
                upper: [focusId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'focusId',
                lower: [focusId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'focusId',
                lower: [focusId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'focusId',
                lower: [],
                upper: [focusId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  lifecycleStateEqualTo(String lifecycleState) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'lifecycleState',
          value: [lifecycleState],
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  lifecycleStateNotEqualTo(String lifecycleState) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lifecycleState',
                lower: [],
                upper: [lifecycleState],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lifecycleState',
                lower: [lifecycleState],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lifecycleState',
                lower: [lifecycleState],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lifecycleState',
                lower: [],
                upper: [lifecycleState],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  detectedAtMsEqualTo(int detectedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'detectedAtMs',
          value: [detectedAtMs],
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  detectedAtMsNotEqualTo(int detectedAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'detectedAtMs',
                lower: [],
                upper: [detectedAtMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'detectedAtMs',
                lower: [detectedAtMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'detectedAtMs',
                lower: [detectedAtMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'detectedAtMs',
                lower: [],
                upper: [detectedAtMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  detectedAtMsGreaterThan(int detectedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'detectedAtMs',
          lower: [detectedAtMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  detectedAtMsLessThan(int detectedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'detectedAtMs',
          lower: [],
          upper: [detectedAtMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  detectedAtMsBetween(
    int lowerDetectedAtMs,
    int upperDetectedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'detectedAtMs',
          lower: [lowerDetectedAtMs],
          includeLower: includeLower,
          upper: [upperDetectedAtMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  activeUntilMsEqualTo(int activeUntilMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'activeUntilMs',
          value: [activeUntilMs],
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  activeUntilMsNotEqualTo(int activeUntilMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'activeUntilMs',
                lower: [],
                upper: [activeUntilMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'activeUntilMs',
                lower: [activeUntilMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'activeUntilMs',
                lower: [activeUntilMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'activeUntilMs',
                lower: [],
                upper: [activeUntilMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  activeUntilMsGreaterThan(int activeUntilMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'activeUntilMs',
          lower: [activeUntilMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  activeUntilMsLessThan(int activeUntilMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'activeUntilMs',
          lower: [],
          upper: [activeUntilMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterWhereClause>
  activeUntilMsBetween(
    int lowerActiveUntilMs,
    int upperActiveUntilMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'activeUntilMs',
          lower: [lowerActiveUntilMs],
          includeLower: includeLower,
          upper: [upperActiveUntilMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarCoachingFocusQueryFilter
    on QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QFilterCondition> {
  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  activeUntilMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'activeUntilMs', value: value),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  activeUntilMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'activeUntilMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  activeUntilMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'activeUntilMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  activeUntilMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'activeUntilMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  detectedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'detectedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  detectedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'detectedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  detectedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'detectedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  detectedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'detectedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  focusIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'focusId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  focusIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'focusId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  focusIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'focusId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  focusIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'focusId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  focusIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'focusId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  focusIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'focusId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  focusIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'focusId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  focusIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'focusId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  focusIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'focusId', value: ''),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  focusIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'focusId', value: ''),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  lifecycleStateEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lifecycleState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  lifecycleStateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lifecycleState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  lifecycleStateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lifecycleState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  lifecycleStateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lifecycleState',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  lifecycleStateStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lifecycleState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  lifecycleStateEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lifecycleState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  lifecycleStateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lifecycleState',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  lifecycleStateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lifecycleState',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  lifecycleStateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lifecycleState', value: ''),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  lifecycleStateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lifecycleState', value: ''),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  primaryInsightIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'primaryInsightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  primaryInsightIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'primaryInsightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  primaryInsightIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'primaryInsightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  primaryInsightIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'primaryInsightId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  primaryInsightIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'primaryInsightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  primaryInsightIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'primaryInsightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  primaryInsightIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'primaryInsightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  primaryInsightIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'primaryInsightId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  primaryInsightIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'primaryInsightId', value: ''),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  primaryInsightIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'primaryInsightId', value: ''),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
  schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schemaVersion', value: value),
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterFilterCondition>
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
}

extension IsarCoachingFocusQueryObject
    on QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QFilterCondition> {}

extension IsarCoachingFocusQueryLinks
    on QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QFilterCondition> {}

extension IsarCoachingFocusQuerySortBy
    on QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QSortBy> {
  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByActiveUntilMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeUntilMs', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByActiveUntilMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeUntilMs', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByDetectedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByDetectedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByFocusId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusId', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByFocusIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusId', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByLifecycleState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lifecycleState', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByLifecycleStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lifecycleState', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByPrimaryInsightId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryInsightId', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortByPrimaryInsightIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryInsightId', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }
}

extension IsarCoachingFocusQuerySortThenBy
    on QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QSortThenBy> {
  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByActiveUntilMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeUntilMs', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByActiveUntilMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeUntilMs', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByDetectedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByDetectedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByFocusId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusId', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByFocusIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'focusId', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByLifecycleState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lifecycleState', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByLifecycleStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lifecycleState', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByPrimaryInsightId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryInsightId', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenByPrimaryInsightIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryInsightId', Sort.desc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QAfterSortBy>
  thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }
}

extension IsarCoachingFocusQueryWhereDistinct
    on QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QDistinct> {
  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QDistinct>
  distinctByActiveUntilMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activeUntilMs');
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QDistinct>
  distinctByDetectedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'detectedAtMs');
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QDistinct>
  distinctByFocusId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'focusId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QDistinct>
  distinctByLifecycleState({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lifecycleState',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QDistinct>
  distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QDistinct>
  distinctByPrimaryInsightId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'primaryInsightId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QDistinct>
  distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }
}

extension IsarCoachingFocusQueryProperty
    on QueryBuilder<IsarCoachingFocus, IsarCoachingFocus, QQueryProperty> {
  QueryBuilder<IsarCoachingFocus, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarCoachingFocus, int, QQueryOperations>
  activeUntilMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activeUntilMs');
    });
  }

  QueryBuilder<IsarCoachingFocus, int, QQueryOperations>
  detectedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'detectedAtMs');
    });
  }

  QueryBuilder<IsarCoachingFocus, String, QQueryOperations> focusIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'focusId');
    });
  }

  QueryBuilder<IsarCoachingFocus, String, QQueryOperations>
  lifecycleStateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lifecycleState');
    });
  }

  QueryBuilder<IsarCoachingFocus, String, QQueryOperations>
  payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<IsarCoachingFocus, String, QQueryOperations>
  primaryInsightIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'primaryInsightId');
    });
  }

  QueryBuilder<IsarCoachingFocus, int, QQueryOperations>
  schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }
}
