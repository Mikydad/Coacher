// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_delivery_history_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarDeliveryHistoryEntryCollection on Isar {
  IsarCollection<IsarDeliveryHistoryEntry> get isarDeliveryHistoryEntrys =>
      this.collection();
}

const IsarDeliveryHistoryEntrySchema = CollectionSchema(
  name: r'IsarDeliveryHistoryEntry',
  id: 5602044867943676936,
  properties: {
    r'createdAtMs': PropertySchema(
      id: 0,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'deliveredAtMs': PropertySchema(
      id: 1,
      name: r'deliveredAtMs',
      type: IsarType.long,
    ),
    r'historyId': PropertySchema(
      id: 2,
      name: r'historyId',
      type: IsarType.string,
    ),
    r'insightId': PropertySchema(
      id: 3,
      name: r'insightId',
      type: IsarType.string,
    ),
    r'payloadJson': PropertySchema(
      id: 4,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 5,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'scopeId': PropertySchema(id: 6, name: r'scopeId', type: IsarType.string),
    r'surface': PropertySchema(id: 7, name: r'surface', type: IsarType.string),
  },

  estimateSize: _isarDeliveryHistoryEntryEstimateSize,
  serialize: _isarDeliveryHistoryEntrySerialize,
  deserialize: _isarDeliveryHistoryEntryDeserialize,
  deserializeProp: _isarDeliveryHistoryEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'historyId': IndexSchema(
      id: -2299313901551835913,
      name: r'historyId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'historyId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'insightId': IndexSchema(
      id: 5818887354909674719,
      name: r'insightId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'insightId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'scopeId_surface': IndexSchema(
      id: -8882346837040826934,
      name: r'scopeId_surface',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'scopeId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'surface',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'surface': IndexSchema(
      id: 6371273999373086633,
      name: r'surface',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'surface',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'deliveredAtMs': IndexSchema(
      id: -1964071940644834908,
      name: r'deliveredAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deliveredAtMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarDeliveryHistoryEntryGetId,
  getLinks: _isarDeliveryHistoryEntryGetLinks,
  attach: _isarDeliveryHistoryEntryAttach,
  version: '3.3.2',
);

int _isarDeliveryHistoryEntryEstimateSize(
  IsarDeliveryHistoryEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.historyId.length * 3;
  bytesCount += 3 + object.insightId.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.scopeId.length * 3;
  bytesCount += 3 + object.surface.length * 3;
  return bytesCount;
}

void _isarDeliveryHistoryEntrySerialize(
  IsarDeliveryHistoryEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.createdAtMs);
  writer.writeLong(offsets[1], object.deliveredAtMs);
  writer.writeString(offsets[2], object.historyId);
  writer.writeString(offsets[3], object.insightId);
  writer.writeString(offsets[4], object.payloadJson);
  writer.writeLong(offsets[5], object.schemaVersion);
  writer.writeString(offsets[6], object.scopeId);
  writer.writeString(offsets[7], object.surface);
}

IsarDeliveryHistoryEntry _isarDeliveryHistoryEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarDeliveryHistoryEntry();
  object.createdAtMs = reader.readLong(offsets[0]);
  object.deliveredAtMs = reader.readLong(offsets[1]);
  object.historyId = reader.readString(offsets[2]);
  object.id = id;
  object.insightId = reader.readString(offsets[3]);
  object.payloadJson = reader.readString(offsets[4]);
  object.schemaVersion = reader.readLong(offsets[5]);
  object.scopeId = reader.readString(offsets[6]);
  object.surface = reader.readString(offsets[7]);
  return object;
}

P _isarDeliveryHistoryEntryDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarDeliveryHistoryEntryGetId(IsarDeliveryHistoryEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarDeliveryHistoryEntryGetLinks(
  IsarDeliveryHistoryEntry object,
) {
  return [];
}

void _isarDeliveryHistoryEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarDeliveryHistoryEntry object,
) {
  object.id = id;
}

extension IsarDeliveryHistoryEntryByIndex
    on IsarCollection<IsarDeliveryHistoryEntry> {
  Future<IsarDeliveryHistoryEntry?> getByHistoryId(String historyId) {
    return getByIndex(r'historyId', [historyId]);
  }

  IsarDeliveryHistoryEntry? getByHistoryIdSync(String historyId) {
    return getByIndexSync(r'historyId', [historyId]);
  }

  Future<bool> deleteByHistoryId(String historyId) {
    return deleteByIndex(r'historyId', [historyId]);
  }

  bool deleteByHistoryIdSync(String historyId) {
    return deleteByIndexSync(r'historyId', [historyId]);
  }

  Future<List<IsarDeliveryHistoryEntry?>> getAllByHistoryId(
    List<String> historyIdValues,
  ) {
    final values = historyIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'historyId', values);
  }

  List<IsarDeliveryHistoryEntry?> getAllByHistoryIdSync(
    List<String> historyIdValues,
  ) {
    final values = historyIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'historyId', values);
  }

  Future<int> deleteAllByHistoryId(List<String> historyIdValues) {
    final values = historyIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'historyId', values);
  }

  int deleteAllByHistoryIdSync(List<String> historyIdValues) {
    final values = historyIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'historyId', values);
  }

  Future<Id> putByHistoryId(IsarDeliveryHistoryEntry object) {
    return putByIndex(r'historyId', object);
  }

  Id putByHistoryIdSync(
    IsarDeliveryHistoryEntry object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'historyId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByHistoryId(List<IsarDeliveryHistoryEntry> objects) {
    return putAllByIndex(r'historyId', objects);
  }

  List<Id> putAllByHistoryIdSync(
    List<IsarDeliveryHistoryEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'historyId', objects, saveLinks: saveLinks);
  }
}

extension IsarDeliveryHistoryEntryQueryWhereSort
    on
        QueryBuilder<
          IsarDeliveryHistoryEntry,
          IsarDeliveryHistoryEntry,
          QWhere
        > {
  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterWhere>
  anyDeliveredAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'deliveredAtMs'),
      );
    });
  }
}

extension IsarDeliveryHistoryEntryQueryWhere
    on
        QueryBuilder<
          IsarDeliveryHistoryEntry,
          IsarDeliveryHistoryEntry,
          QWhereClause
        > {
  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  historyIdEqualTo(String historyId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'historyId', value: [historyId]),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  historyIdNotEqualTo(String historyId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'historyId',
                lower: [],
                upper: [historyId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'historyId',
                lower: [historyId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'historyId',
                lower: [historyId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'historyId',
                lower: [],
                upper: [historyId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  insightIdEqualTo(String insightId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'insightId', value: [insightId]),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  insightIdNotEqualTo(String insightId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'insightId',
                lower: [],
                upper: [insightId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'insightId',
                lower: [insightId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'insightId',
                lower: [insightId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'insightId',
                lower: [],
                upper: [insightId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  scopeIdEqualToAnySurface(String scopeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'scopeId_surface',
          value: [scopeId],
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  scopeIdNotEqualToAnySurface(String scopeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scopeId_surface',
                lower: [],
                upper: [scopeId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scopeId_surface',
                lower: [scopeId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scopeId_surface',
                lower: [scopeId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scopeId_surface',
                lower: [],
                upper: [scopeId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  scopeIdSurfaceEqualTo(String scopeId, String surface) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'scopeId_surface',
          value: [scopeId, surface],
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  scopeIdEqualToSurfaceNotEqualTo(String scopeId, String surface) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scopeId_surface',
                lower: [scopeId],
                upper: [scopeId, surface],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scopeId_surface',
                lower: [scopeId, surface],
                includeLower: false,
                upper: [scopeId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scopeId_surface',
                lower: [scopeId, surface],
                includeLower: false,
                upper: [scopeId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'scopeId_surface',
                lower: [scopeId],
                upper: [scopeId, surface],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  surfaceEqualTo(String surface) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'surface', value: [surface]),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  surfaceNotEqualTo(String surface) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'surface',
                lower: [],
                upper: [surface],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'surface',
                lower: [surface],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'surface',
                lower: [surface],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'surface',
                lower: [],
                upper: [surface],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  deliveredAtMsEqualTo(int deliveredAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'deliveredAtMs',
          value: [deliveredAtMs],
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  deliveredAtMsNotEqualTo(int deliveredAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deliveredAtMs',
                lower: [],
                upper: [deliveredAtMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deliveredAtMs',
                lower: [deliveredAtMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deliveredAtMs',
                lower: [deliveredAtMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deliveredAtMs',
                lower: [],
                upper: [deliveredAtMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  deliveredAtMsGreaterThan(int deliveredAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deliveredAtMs',
          lower: [deliveredAtMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  deliveredAtMsLessThan(int deliveredAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deliveredAtMs',
          lower: [],
          upper: [deliveredAtMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterWhereClause
  >
  deliveredAtMsBetween(
    int lowerDeliveredAtMs,
    int upperDeliveredAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deliveredAtMs',
          lower: [lowerDeliveredAtMs],
          includeLower: includeLower,
          upper: [upperDeliveredAtMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarDeliveryHistoryEntryQueryFilter
    on
        QueryBuilder<
          IsarDeliveryHistoryEntry,
          IsarDeliveryHistoryEntry,
          QFilterCondition
        > {
  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  deliveredAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deliveredAtMs', value: value),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  deliveredAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deliveredAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  deliveredAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deliveredAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  deliveredAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deliveredAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  historyIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'historyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  historyIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'historyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  historyIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'historyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  historyIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'historyId',
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  historyIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'historyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  historyIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'historyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  historyIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'historyId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  historyIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'historyId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  historyIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'historyId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  historyIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'historyId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  insightIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  insightIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  insightIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  insightIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'insightId',
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  insightIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  insightIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  insightIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'insightId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  insightIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'insightId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  insightIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'insightId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  insightIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'insightId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schemaVersion', value: value),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  scopeIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'scopeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  scopeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'scopeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  scopeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'scopeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  scopeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'scopeId',
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  scopeIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'scopeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  scopeIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'scopeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  scopeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'scopeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  scopeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'scopeId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  scopeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'scopeId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  scopeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'scopeId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  surfaceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'surface',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  surfaceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'surface',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  surfaceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'surface',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  surfaceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'surface',
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
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  surfaceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'surface',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  surfaceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'surface',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  surfaceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'surface',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  surfaceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'surface',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  surfaceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'surface', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarDeliveryHistoryEntry,
    IsarDeliveryHistoryEntry,
    QAfterFilterCondition
  >
  surfaceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'surface', value: ''),
      );
    });
  }
}

extension IsarDeliveryHistoryEntryQueryObject
    on
        QueryBuilder<
          IsarDeliveryHistoryEntry,
          IsarDeliveryHistoryEntry,
          QFilterCondition
        > {}

extension IsarDeliveryHistoryEntryQueryLinks
    on
        QueryBuilder<
          IsarDeliveryHistoryEntry,
          IsarDeliveryHistoryEntry,
          QFilterCondition
        > {}

extension IsarDeliveryHistoryEntryQuerySortBy
    on
        QueryBuilder<
          IsarDeliveryHistoryEntry,
          IsarDeliveryHistoryEntry,
          QSortBy
        > {
  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByDeliveredAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByDeliveredAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByHistoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'historyId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByHistoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'historyId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByInsightId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByInsightIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByScopeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortByScopeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortBySurface() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surface', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  sortBySurfaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surface', Sort.desc);
    });
  }
}

extension IsarDeliveryHistoryEntryQuerySortThenBy
    on
        QueryBuilder<
          IsarDeliveryHistoryEntry,
          IsarDeliveryHistoryEntry,
          QSortThenBy
        > {
  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByDeliveredAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByDeliveredAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByHistoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'historyId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByHistoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'historyId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByInsightId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByInsightIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'insightId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByScopeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenByScopeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenBySurface() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surface', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QAfterSortBy>
  thenBySurfaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surface', Sort.desc);
    });
  }
}

extension IsarDeliveryHistoryEntryQueryWhereDistinct
    on
        QueryBuilder<
          IsarDeliveryHistoryEntry,
          IsarDeliveryHistoryEntry,
          QDistinct
        > {
  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QDistinct>
  distinctByDeliveredAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deliveredAtMs');
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QDistinct>
  distinctByHistoryId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'historyId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QDistinct>
  distinctByInsightId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'insightId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QDistinct>
  distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QDistinct>
  distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QDistinct>
  distinctByScopeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scopeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, IsarDeliveryHistoryEntry, QDistinct>
  distinctBySurface({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surface', caseSensitive: caseSensitive);
    });
  }
}

extension IsarDeliveryHistoryEntryQueryProperty
    on
        QueryBuilder<
          IsarDeliveryHistoryEntry,
          IsarDeliveryHistoryEntry,
          QQueryProperty
        > {
  QueryBuilder<IsarDeliveryHistoryEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, int, QQueryOperations>
  createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, int, QQueryOperations>
  deliveredAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deliveredAtMs');
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, String, QQueryOperations>
  historyIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'historyId');
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, String, QQueryOperations>
  insightIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'insightId');
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, String, QQueryOperations>
  payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, int, QQueryOperations>
  schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, String, QQueryOperations>
  scopeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scopeId');
    });
  }

  QueryBuilder<IsarDeliveryHistoryEntry, String, QQueryOperations>
  surfaceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surface');
    });
  }
}
