// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_memory_fact.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarMemoryFactCollection on Isar {
  IsarCollection<IsarMemoryFact> get isarMemoryFacts => this.collection();
}

const IsarMemoryFactSchema = CollectionSchema(
  name: r'IsarMemoryFact',
  id: 7704996538720287127,
  properties: {
    r'active': PropertySchema(id: 0, name: r'active', type: IsarType.bool),
    r'confidence': PropertySchema(
      id: 1,
      name: r'confidence',
      type: IsarType.double,
    ),
    r'content': PropertySchema(id: 2, name: r'content', type: IsarType.string),
    r'contradictionCount': PropertySchema(
      id: 3,
      name: r'contradictionCount',
      type: IsarType.long,
    ),
    r'createdAtMs': PropertySchema(
      id: 4,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'factId': PropertySchema(id: 5, name: r'factId', type: IsarType.string),
    r'kindStorage': PropertySchema(
      id: 6,
      name: r'kindStorage',
      type: IsarType.string,
    ),
    r'lastReferencedAtMs': PropertySchema(
      id: 7,
      name: r'lastReferencedAtMs',
      type: IsarType.long,
    ),
    r'personId': PropertySchema(
      id: 8,
      name: r'personId',
      type: IsarType.string,
    ),
    r'provenanceStorage': PropertySchema(
      id: 9,
      name: r'provenanceStorage',
      type: IsarType.string,
    ),
    r'sourceQuote': PropertySchema(
      id: 10,
      name: r'sourceQuote',
      type: IsarType.string,
    ),
    r'sourceSessionId': PropertySchema(
      id: 11,
      name: r'sourceSessionId',
      type: IsarType.string,
    ),
    r'structuredJson': PropertySchema(
      id: 12,
      name: r'structuredJson',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 13,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarMemoryFactEstimateSize,
  serialize: _isarMemoryFactSerialize,
  deserialize: _isarMemoryFactDeserialize,
  deserializeProp: _isarMemoryFactDeserializeProp,
  idName: r'id',
  indexes: {
    r'factId': IndexSchema(
      id: 1055152942328501907,
      name: r'factId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'factId',
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
    r'kindStorage': IndexSchema(
      id: -2795039491387898507,
      name: r'kindStorage',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'kindStorage',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'personId': IndexSchema(
      id: 750717629518044662,
      name: r'personId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'personId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarMemoryFactGetId,
  getLinks: _isarMemoryFactGetLinks,
  attach: _isarMemoryFactAttach,
  version: '3.3.2',
);

int _isarMemoryFactEstimateSize(
  IsarMemoryFact object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.factId.length * 3;
  bytesCount += 3 + object.kindStorage.length * 3;
  {
    final value = object.personId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.provenanceStorage.length * 3;
  {
    final value = object.sourceQuote;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sourceSessionId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.structuredJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarMemoryFactSerialize(
  IsarMemoryFact object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.active);
  writer.writeDouble(offsets[1], object.confidence);
  writer.writeString(offsets[2], object.content);
  writer.writeLong(offsets[3], object.contradictionCount);
  writer.writeLong(offsets[4], object.createdAtMs);
  writer.writeString(offsets[5], object.factId);
  writer.writeString(offsets[6], object.kindStorage);
  writer.writeLong(offsets[7], object.lastReferencedAtMs);
  writer.writeString(offsets[8], object.personId);
  writer.writeString(offsets[9], object.provenanceStorage);
  writer.writeString(offsets[10], object.sourceQuote);
  writer.writeString(offsets[11], object.sourceSessionId);
  writer.writeString(offsets[12], object.structuredJson);
  writer.writeLong(offsets[13], object.updatedAtMs);
}

IsarMemoryFact _isarMemoryFactDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarMemoryFact();
  object.active = reader.readBool(offsets[0]);
  object.confidence = reader.readDouble(offsets[1]);
  object.content = reader.readString(offsets[2]);
  object.contradictionCount = reader.readLong(offsets[3]);
  object.createdAtMs = reader.readLong(offsets[4]);
  object.factId = reader.readString(offsets[5]);
  object.id = id;
  object.kindStorage = reader.readString(offsets[6]);
  object.lastReferencedAtMs = reader.readLongOrNull(offsets[7]);
  object.personId = reader.readStringOrNull(offsets[8]);
  object.provenanceStorage = reader.readString(offsets[9]);
  object.sourceQuote = reader.readStringOrNull(offsets[10]);
  object.sourceSessionId = reader.readStringOrNull(offsets[11]);
  object.structuredJson = reader.readStringOrNull(offsets[12]);
  object.updatedAtMs = reader.readLong(offsets[13]);
  return object;
}

P _isarMemoryFactDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarMemoryFactGetId(IsarMemoryFact object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarMemoryFactGetLinks(IsarMemoryFact object) {
  return [];
}

void _isarMemoryFactAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarMemoryFact object,
) {
  object.id = id;
}

extension IsarMemoryFactByIndex on IsarCollection<IsarMemoryFact> {
  Future<IsarMemoryFact?> getByFactId(String factId) {
    return getByIndex(r'factId', [factId]);
  }

  IsarMemoryFact? getByFactIdSync(String factId) {
    return getByIndexSync(r'factId', [factId]);
  }

  Future<bool> deleteByFactId(String factId) {
    return deleteByIndex(r'factId', [factId]);
  }

  bool deleteByFactIdSync(String factId) {
    return deleteByIndexSync(r'factId', [factId]);
  }

  Future<List<IsarMemoryFact?>> getAllByFactId(List<String> factIdValues) {
    final values = factIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'factId', values);
  }

  List<IsarMemoryFact?> getAllByFactIdSync(List<String> factIdValues) {
    final values = factIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'factId', values);
  }

  Future<int> deleteAllByFactId(List<String> factIdValues) {
    final values = factIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'factId', values);
  }

  int deleteAllByFactIdSync(List<String> factIdValues) {
    final values = factIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'factId', values);
  }

  Future<Id> putByFactId(IsarMemoryFact object) {
    return putByIndex(r'factId', object);
  }

  Id putByFactIdSync(IsarMemoryFact object, {bool saveLinks = true}) {
    return putByIndexSync(r'factId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFactId(List<IsarMemoryFact> objects) {
    return putAllByIndex(r'factId', objects);
  }

  List<Id> putAllByFactIdSync(
    List<IsarMemoryFact> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'factId', objects, saveLinks: saveLinks);
  }
}

extension IsarMemoryFactQueryWhereSort
    on QueryBuilder<IsarMemoryFact, IsarMemoryFact, QWhere> {
  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhere> anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarMemoryFactQueryWhere
    on QueryBuilder<IsarMemoryFact, IsarMemoryFact, QWhereClause> {
  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause> factIdEqualTo(
    String factId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'factId', value: [factId]),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
  factIdNotEqualTo(String factId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'factId',
                lower: [],
                upper: [factId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'factId',
                lower: [factId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'factId',
                lower: [factId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'factId',
                lower: [],
                upper: [factId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
  kindStorageEqualTo(String kindStorage) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'kindStorage',
          value: [kindStorage],
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
  kindStorageNotEqualTo(String kindStorage) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'kindStorage',
                lower: [],
                upper: [kindStorage],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'kindStorage',
                lower: [kindStorage],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'kindStorage',
                lower: [kindStorage],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'kindStorage',
                lower: [],
                upper: [kindStorage],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
  personIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'personId', value: [null]),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
  personIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'personId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
  personIdEqualTo(String? personId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'personId', value: [personId]),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterWhereClause>
  personIdNotEqualTo(String? personId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personId',
                lower: [],
                upper: [personId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personId',
                lower: [personId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personId',
                lower: [personId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personId',
                lower: [],
                upper: [personId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarMemoryFactQueryFilter
    on QueryBuilder<IsarMemoryFact, IsarMemoryFact, QFilterCondition> {
  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  activeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'active', value: value),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  confidenceEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'confidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  confidenceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'confidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  confidenceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'confidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  confidenceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'confidence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contentEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'content',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contentStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contentEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'content',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contradictionCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contradictionCount', value: value),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contradictionCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contradictionCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contradictionCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contradictionCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  contradictionCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contradictionCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  factIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'factId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  factIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'factId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  factIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'factId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  factIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'factId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  factIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'factId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  factIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'factId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  factIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'factId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  factIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'factId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  factIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'factId', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  factIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'factId', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  kindStorageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'kindStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  kindStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kindStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  kindStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kindStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  kindStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kindStorage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  kindStorageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'kindStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  kindStorageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'kindStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  kindStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'kindStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  kindStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'kindStorage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  kindStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kindStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  kindStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'kindStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  lastReferencedAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastReferencedAtMs'),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  lastReferencedAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastReferencedAtMs'),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  lastReferencedAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastReferencedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  lastReferencedAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastReferencedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  lastReferencedAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastReferencedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  lastReferencedAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastReferencedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'personId'),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'personId'),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'personId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'personId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'personId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'personId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'personId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'personId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'personId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'personId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'personId', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  personIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'personId', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  provenanceStorageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'provenanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  provenanceStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'provenanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  provenanceStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'provenanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  provenanceStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'provenanceStorage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  provenanceStorageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'provenanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  provenanceStorageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'provenanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  provenanceStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'provenanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  provenanceStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'provenanceStorage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  provenanceStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'provenanceStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  provenanceStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'provenanceStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceQuote'),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceQuote'),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceQuote',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceQuote',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceQuote',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceQuote',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceQuote',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceQuote',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceQuote',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceQuote',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceQuote', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceQuoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceQuote', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceSessionId'),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceSessionId'),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceSessionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceSessionId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceSessionId', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  sourceSessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceSessionId', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'structuredJson'),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'structuredJson'),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'structuredJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'structuredJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'structuredJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'structuredJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'structuredJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'structuredJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'structuredJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'structuredJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'structuredJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  structuredJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'structuredJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
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

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterFilterCondition>
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

extension IsarMemoryFactQueryObject
    on QueryBuilder<IsarMemoryFact, IsarMemoryFact, QFilterCondition> {}

extension IsarMemoryFactQueryLinks
    on QueryBuilder<IsarMemoryFact, IsarMemoryFact, QFilterCondition> {}

extension IsarMemoryFactQuerySortBy
    on QueryBuilder<IsarMemoryFact, IsarMemoryFact, QSortBy> {
  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy> sortByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByContradictionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contradictionCount', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByContradictionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contradictionCount', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy> sortByFactId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'factId', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByFactIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'factId', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByKindStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByKindStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByLastReferencedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReferencedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByLastReferencedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReferencedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy> sortByPersonId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByPersonIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByProvenanceStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenanceStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByProvenanceStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenanceStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortBySourceQuote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceQuote', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortBySourceQuoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceQuote', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortBySourceSessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceSessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortBySourceSessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceSessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByStructuredJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'structuredJson', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByStructuredJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'structuredJson', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarMemoryFactQuerySortThenBy
    on QueryBuilder<IsarMemoryFact, IsarMemoryFact, QSortThenBy> {
  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy> thenByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidence', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByContradictionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contradictionCount', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByContradictionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contradictionCount', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy> thenByFactId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'factId', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByFactIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'factId', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByKindStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByKindStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByLastReferencedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReferencedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByLastReferencedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReferencedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy> thenByPersonId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByPersonIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByProvenanceStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenanceStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByProvenanceStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenanceStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenBySourceQuote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceQuote', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenBySourceQuoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceQuote', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenBySourceSessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceSessionId', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenBySourceSessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceSessionId', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByStructuredJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'structuredJson', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByStructuredJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'structuredJson', Sort.desc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarMemoryFactQueryWhereDistinct
    on QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct> {
  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct> distinctByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'active');
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct>
  distinctByConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confidence');
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct> distinctByContent({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct>
  distinctByContradictionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contradictionCount');
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct> distinctByFactId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'factId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct>
  distinctByKindStorage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kindStorage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct>
  distinctByLastReferencedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastReferencedAtMs');
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct> distinctByPersonId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct>
  distinctByProvenanceStorage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'provenanceStorage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct>
  distinctBySourceQuote({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceQuote', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct>
  distinctBySourceSessionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceSessionId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct>
  distinctByStructuredJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'structuredJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarMemoryFact, IsarMemoryFact, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarMemoryFactQueryProperty
    on QueryBuilder<IsarMemoryFact, IsarMemoryFact, QQueryProperty> {
  QueryBuilder<IsarMemoryFact, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarMemoryFact, bool, QQueryOperations> activeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'active');
    });
  }

  QueryBuilder<IsarMemoryFact, double, QQueryOperations> confidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confidence');
    });
  }

  QueryBuilder<IsarMemoryFact, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<IsarMemoryFact, int, QQueryOperations>
  contradictionCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contradictionCount');
    });
  }

  QueryBuilder<IsarMemoryFact, int, QQueryOperations> createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarMemoryFact, String, QQueryOperations> factIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'factId');
    });
  }

  QueryBuilder<IsarMemoryFact, String, QQueryOperations> kindStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kindStorage');
    });
  }

  QueryBuilder<IsarMemoryFact, int?, QQueryOperations>
  lastReferencedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastReferencedAtMs');
    });
  }

  QueryBuilder<IsarMemoryFact, String?, QQueryOperations> personIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personId');
    });
  }

  QueryBuilder<IsarMemoryFact, String, QQueryOperations>
  provenanceStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'provenanceStorage');
    });
  }

  QueryBuilder<IsarMemoryFact, String?, QQueryOperations>
  sourceQuoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceQuote');
    });
  }

  QueryBuilder<IsarMemoryFact, String?, QQueryOperations>
  sourceSessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceSessionId');
    });
  }

  QueryBuilder<IsarMemoryFact, String?, QQueryOperations>
  structuredJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'structuredJson');
    });
  }

  QueryBuilder<IsarMemoryFact, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
