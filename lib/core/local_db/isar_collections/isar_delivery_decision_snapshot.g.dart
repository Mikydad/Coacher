// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_delivery_decision_snapshot.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarDeliveryDecisionSnapshotCollection on Isar {
  IsarCollection<IsarDeliveryDecisionSnapshot>
      get isarDeliveryDecisionSnapshots => this.collection();
}

const IsarDeliveryDecisionSnapshotSchema = CollectionSchema(
  name: r'IsarDeliveryDecisionSnapshot',
  id: 1106692681267325679,
  properties: {
    r'createdAtMs': PropertySchema(
      id: 0,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'payloadJson': PropertySchema(
      id: 1,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 2,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'scopeId': PropertySchema(
      id: 3,
      name: r'scopeId',
      type: IsarType.string,
    ),
    r'snapshotId': PropertySchema(
      id: 4,
      name: r'snapshotId',
      type: IsarType.string,
    ),
    r'surface': PropertySchema(
      id: 5,
      name: r'surface',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 6,
      name: r'updatedAtMs',
      type: IsarType.long,
    )
  },
  estimateSize: _isarDeliveryDecisionSnapshotEstimateSize,
  serialize: _isarDeliveryDecisionSnapshotSerialize,
  deserialize: _isarDeliveryDecisionSnapshotDeserialize,
  deserializeProp: _isarDeliveryDecisionSnapshotDeserializeProp,
  idName: r'id',
  indexes: {
    r'snapshotId': IndexSchema(
      id: -7574188874426247601,
      name: r'snapshotId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'snapshotId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'scopeId': IndexSchema(
      id: 2528183376744017072,
      name: r'scopeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'scopeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
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
        )
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
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarDeliveryDecisionSnapshotGetId,
  getLinks: _isarDeliveryDecisionSnapshotGetLinks,
  attach: _isarDeliveryDecisionSnapshotAttach,
  version: '3.1.0+1',
);

int _isarDeliveryDecisionSnapshotEstimateSize(
  IsarDeliveryDecisionSnapshot object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.scopeId.length * 3;
  bytesCount += 3 + object.snapshotId.length * 3;
  bytesCount += 3 + object.surface.length * 3;
  return bytesCount;
}

void _isarDeliveryDecisionSnapshotSerialize(
  IsarDeliveryDecisionSnapshot object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.createdAtMs);
  writer.writeString(offsets[1], object.payloadJson);
  writer.writeLong(offsets[2], object.schemaVersion);
  writer.writeString(offsets[3], object.scopeId);
  writer.writeString(offsets[4], object.snapshotId);
  writer.writeString(offsets[5], object.surface);
  writer.writeLong(offsets[6], object.updatedAtMs);
}

IsarDeliveryDecisionSnapshot _isarDeliveryDecisionSnapshotDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarDeliveryDecisionSnapshot();
  object.createdAtMs = reader.readLong(offsets[0]);
  object.id = id;
  object.payloadJson = reader.readString(offsets[1]);
  object.schemaVersion = reader.readLong(offsets[2]);
  object.scopeId = reader.readString(offsets[3]);
  object.snapshotId = reader.readString(offsets[4]);
  object.surface = reader.readString(offsets[5]);
  object.updatedAtMs = reader.readLong(offsets[6]);
  return object;
}

P _isarDeliveryDecisionSnapshotDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
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

Id _isarDeliveryDecisionSnapshotGetId(IsarDeliveryDecisionSnapshot object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarDeliveryDecisionSnapshotGetLinks(
    IsarDeliveryDecisionSnapshot object) {
  return [];
}

void _isarDeliveryDecisionSnapshotAttach(
    IsarCollection<dynamic> col, Id id, IsarDeliveryDecisionSnapshot object) {
  object.id = id;
}

extension IsarDeliveryDecisionSnapshotByIndex
    on IsarCollection<IsarDeliveryDecisionSnapshot> {
  Future<IsarDeliveryDecisionSnapshot?> getBySnapshotId(String snapshotId) {
    return getByIndex(r'snapshotId', [snapshotId]);
  }

  IsarDeliveryDecisionSnapshot? getBySnapshotIdSync(String snapshotId) {
    return getByIndexSync(r'snapshotId', [snapshotId]);
  }

  Future<bool> deleteBySnapshotId(String snapshotId) {
    return deleteByIndex(r'snapshotId', [snapshotId]);
  }

  bool deleteBySnapshotIdSync(String snapshotId) {
    return deleteByIndexSync(r'snapshotId', [snapshotId]);
  }

  Future<List<IsarDeliveryDecisionSnapshot?>> getAllBySnapshotId(
      List<String> snapshotIdValues) {
    final values = snapshotIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'snapshotId', values);
  }

  List<IsarDeliveryDecisionSnapshot?> getAllBySnapshotIdSync(
      List<String> snapshotIdValues) {
    final values = snapshotIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'snapshotId', values);
  }

  Future<int> deleteAllBySnapshotId(List<String> snapshotIdValues) {
    final values = snapshotIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'snapshotId', values);
  }

  int deleteAllBySnapshotIdSync(List<String> snapshotIdValues) {
    final values = snapshotIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'snapshotId', values);
  }

  Future<Id> putBySnapshotId(IsarDeliveryDecisionSnapshot object) {
    return putByIndex(r'snapshotId', object);
  }

  Id putBySnapshotIdSync(IsarDeliveryDecisionSnapshot object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'snapshotId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySnapshotId(
      List<IsarDeliveryDecisionSnapshot> objects) {
    return putAllByIndex(r'snapshotId', objects);
  }

  List<Id> putAllBySnapshotIdSync(List<IsarDeliveryDecisionSnapshot> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'snapshotId', objects, saveLinks: saveLinks);
  }
}

extension IsarDeliveryDecisionSnapshotQueryWhereSort on QueryBuilder<
    IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot, QWhere> {
  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhere> anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarDeliveryDecisionSnapshotQueryWhere on QueryBuilder<
    IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot, QWhereClause> {
  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> snapshotIdEqualTo(String snapshotId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'snapshotId',
        value: [snapshotId],
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> snapshotIdNotEqualTo(String snapshotId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'snapshotId',
              lower: [],
              upper: [snapshotId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'snapshotId',
              lower: [snapshotId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'snapshotId',
              lower: [snapshotId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'snapshotId',
              lower: [],
              upper: [snapshotId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> scopeIdEqualTo(String scopeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'scopeId',
        value: [scopeId],
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> scopeIdNotEqualTo(String scopeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeId',
              lower: [],
              upper: [scopeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeId',
              lower: [scopeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeId',
              lower: [scopeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scopeId',
              lower: [],
              upper: [scopeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> surfaceEqualTo(String surface) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'surface',
        value: [surface],
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> surfaceNotEqualTo(String surface) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surface',
              lower: [],
              upper: [surface],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surface',
              lower: [surface],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surface',
              lower: [surface],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surface',
              lower: [],
              upper: [surface],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> updatedAtMsEqualTo(int updatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAtMs',
        value: [updatedAtMs],
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> updatedAtMsNotEqualTo(int updatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAtMs',
              lower: [],
              upper: [updatedAtMs],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAtMs',
              lower: [updatedAtMs],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAtMs',
              lower: [updatedAtMs],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAtMs',
              lower: [],
              upper: [updatedAtMs],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> updatedAtMsGreaterThan(
    int updatedAtMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAtMs',
        lower: [updatedAtMs],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> updatedAtMsLessThan(
    int updatedAtMs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAtMs',
        lower: [],
        upper: [updatedAtMs],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterWhereClause> updatedAtMsBetween(
    int lowerUpdatedAtMs,
    int upperUpdatedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAtMs',
        lower: [lowerUpdatedAtMs],
        includeLower: includeLower,
        upper: [upperUpdatedAtMs],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarDeliveryDecisionSnapshotQueryFilter on QueryBuilder<
    IsarDeliveryDecisionSnapshot,
    IsarDeliveryDecisionSnapshot,
    QFilterCondition> {
  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> createdAtMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> createdAtMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> createdAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAtMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> scopeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> scopeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> scopeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> scopeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scopeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> scopeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> scopeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
          QAfterFilterCondition>
      scopeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scopeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
          QAfterFilterCondition>
      scopeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scopeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> scopeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scopeId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> scopeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scopeId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> snapshotIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'snapshotId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> snapshotIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'snapshotId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> snapshotIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'snapshotId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> snapshotIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'snapshotId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> snapshotIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'snapshotId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> snapshotIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'snapshotId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
          QAfterFilterCondition>
      snapshotIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'snapshotId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
          QAfterFilterCondition>
      snapshotIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'snapshotId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> snapshotIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'snapshotId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> snapshotIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'snapshotId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> surfaceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surface',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> surfaceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'surface',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> surfaceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'surface',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> surfaceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'surface',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> surfaceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'surface',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> surfaceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'surface',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
          QAfterFilterCondition>
      surfaceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'surface',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
          QAfterFilterCondition>
      surfaceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'surface',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> surfaceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surface',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> surfaceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'surface',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterFilterCondition> updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
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

extension IsarDeliveryDecisionSnapshotQueryObject on QueryBuilder<
    IsarDeliveryDecisionSnapshot,
    IsarDeliveryDecisionSnapshot,
    QFilterCondition> {}

extension IsarDeliveryDecisionSnapshotQueryLinks on QueryBuilder<
    IsarDeliveryDecisionSnapshot,
    IsarDeliveryDecisionSnapshot,
    QFilterCondition> {}

extension IsarDeliveryDecisionSnapshotQuerySortBy on QueryBuilder<
    IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot, QSortBy> {
  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortByScopeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortByScopeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortBySnapshotId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortBySnapshotIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortBySurface() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surface', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortBySurfaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surface', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarDeliveryDecisionSnapshotQuerySortThenBy on QueryBuilder<
    IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot, QSortThenBy> {
  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenByScopeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenByScopeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scopeId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenBySnapshotId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenBySnapshotIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenBySurface() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surface', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenBySurfaceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surface', Sort.desc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QAfterSortBy> thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarDeliveryDecisionSnapshotQueryWhereDistinct on QueryBuilder<
    IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot, QDistinct> {
  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QDistinct> distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QDistinct> distinctByPayloadJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QDistinct> distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QDistinct> distinctByScopeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scopeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QDistinct> distinctBySnapshotId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'snapshotId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QDistinct> distinctBySurface({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surface', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, IsarDeliveryDecisionSnapshot,
      QDistinct> distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarDeliveryDecisionSnapshotQueryProperty on QueryBuilder<
    IsarDeliveryDecisionSnapshot,
    IsarDeliveryDecisionSnapshot,
    QQueryProperty> {
  QueryBuilder<IsarDeliveryDecisionSnapshot, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, int, QQueryOperations>
      createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, String, QQueryOperations>
      payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, int, QQueryOperations>
      schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, String, QQueryOperations>
      scopeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scopeId');
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, String, QQueryOperations>
      snapshotIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snapshotId');
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, String, QQueryOperations>
      surfaceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surface');
    });
  }

  QueryBuilder<IsarDeliveryDecisionSnapshot, int, QQueryOperations>
      updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
