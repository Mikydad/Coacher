// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_deleted_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarDeletedEntityCollection on Isar {
  IsarCollection<IsarDeletedEntity> get isarDeletedEntitys => this.collection();
}

const IsarDeletedEntitySchema = CollectionSchema(
  name: r'IsarDeletedEntity',
  id: -7929943490149331751,
  properties: {
    r'deletedAtMs': PropertySchema(
      id: 0,
      name: r'deletedAtMs',
      type: IsarType.long,
    ),
    r'entityId': PropertySchema(
      id: 1,
      name: r'entityId',
      type: IsarType.string,
    ),
    r'entityKey': PropertySchema(
      id: 2,
      name: r'entityKey',
      type: IsarType.string,
    ),
    r'entityType': PropertySchema(
      id: 3,
      name: r'entityType',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 4,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarDeletedEntityEstimateSize,
  serialize: _isarDeletedEntitySerialize,
  deserialize: _isarDeletedEntityDeserialize,
  deserializeProp: _isarDeletedEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'entityKey': IndexSchema(
      id: -9036825346649120373,
      name: r'entityKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entityKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'entityType': IndexSchema(
      id: -5109706325448941117,
      name: r'entityType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entityType',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'deletedAtMs': IndexSchema(
      id: 3246995699978773283,
      name: r'deletedAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deletedAtMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarDeletedEntityGetId,
  getLinks: _isarDeletedEntityGetLinks,
  attach: _isarDeletedEntityAttach,
  version: '3.3.2',
);

int _isarDeletedEntityEstimateSize(
  IsarDeletedEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.entityId.length * 3;
  bytesCount += 3 + object.entityKey.length * 3;
  bytesCount += 3 + object.entityType.length * 3;
  return bytesCount;
}

void _isarDeletedEntitySerialize(
  IsarDeletedEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.deletedAtMs);
  writer.writeString(offsets[1], object.entityId);
  writer.writeString(offsets[2], object.entityKey);
  writer.writeString(offsets[3], object.entityType);
  writer.writeLong(offsets[4], object.updatedAtMs);
}

IsarDeletedEntity _isarDeletedEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarDeletedEntity();
  object.deletedAtMs = reader.readLong(offsets[0]);
  object.entityId = reader.readString(offsets[1]);
  object.entityKey = reader.readString(offsets[2]);
  object.entityType = reader.readString(offsets[3]);
  object.id = id;
  object.updatedAtMs = reader.readLong(offsets[4]);
  return object;
}

P _isarDeletedEntityDeserializeProp<P>(
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
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarDeletedEntityGetId(IsarDeletedEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarDeletedEntityGetLinks(
  IsarDeletedEntity object,
) {
  return [];
}

void _isarDeletedEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarDeletedEntity object,
) {
  object.id = id;
}

extension IsarDeletedEntityByIndex on IsarCollection<IsarDeletedEntity> {
  Future<IsarDeletedEntity?> getByEntityKey(String entityKey) {
    return getByIndex(r'entityKey', [entityKey]);
  }

  IsarDeletedEntity? getByEntityKeySync(String entityKey) {
    return getByIndexSync(r'entityKey', [entityKey]);
  }

  Future<bool> deleteByEntityKey(String entityKey) {
    return deleteByIndex(r'entityKey', [entityKey]);
  }

  bool deleteByEntityKeySync(String entityKey) {
    return deleteByIndexSync(r'entityKey', [entityKey]);
  }

  Future<List<IsarDeletedEntity?>> getAllByEntityKey(
    List<String> entityKeyValues,
  ) {
    final values = entityKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'entityKey', values);
  }

  List<IsarDeletedEntity?> getAllByEntityKeySync(List<String> entityKeyValues) {
    final values = entityKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'entityKey', values);
  }

  Future<int> deleteAllByEntityKey(List<String> entityKeyValues) {
    final values = entityKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'entityKey', values);
  }

  int deleteAllByEntityKeySync(List<String> entityKeyValues) {
    final values = entityKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'entityKey', values);
  }

  Future<Id> putByEntityKey(IsarDeletedEntity object) {
    return putByIndex(r'entityKey', object);
  }

  Id putByEntityKeySync(IsarDeletedEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'entityKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEntityKey(List<IsarDeletedEntity> objects) {
    return putAllByIndex(r'entityKey', objects);
  }

  List<Id> putAllByEntityKeySync(
    List<IsarDeletedEntity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'entityKey', objects, saveLinks: saveLinks);
  }
}

extension IsarDeletedEntityQueryWhereSort
    on QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QWhere> {
  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhere>
  anyDeletedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'deletedAtMs'),
      );
    });
  }
}

extension IsarDeletedEntityQueryWhere
    on QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QWhereClause> {
  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
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

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
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

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  entityKeyEqualTo(String entityKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entityKey', value: [entityKey]),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  entityKeyNotEqualTo(String entityKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKey',
                lower: [],
                upper: [entityKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKey',
                lower: [entityKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKey',
                lower: [entityKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKey',
                lower: [],
                upper: [entityKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  entityTypeEqualTo(String entityType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entityType', value: [entityType]),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  entityTypeNotEqualTo(String entityType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityType',
                lower: [],
                upper: [entityType],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityType',
                lower: [entityType],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityType',
                lower: [entityType],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityType',
                lower: [],
                upper: [entityType],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  deletedAtMsEqualTo(int deletedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'deletedAtMs',
          value: [deletedAtMs],
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  deletedAtMsNotEqualTo(int deletedAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAtMs',
                lower: [],
                upper: [deletedAtMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAtMs',
                lower: [deletedAtMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAtMs',
                lower: [deletedAtMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAtMs',
                lower: [],
                upper: [deletedAtMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  deletedAtMsGreaterThan(int deletedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAtMs',
          lower: [deletedAtMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  deletedAtMsLessThan(int deletedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAtMs',
          lower: [],
          upper: [deletedAtMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterWhereClause>
  deletedAtMsBetween(
    int lowerDeletedAtMs,
    int upperDeletedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAtMs',
          lower: [lowerDeletedAtMs],
          includeLower: includeLower,
          upper: [upperDeletedAtMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarDeletedEntityQueryFilter
    on QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QFilterCondition> {
  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  deletedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deletedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  deletedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deletedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  deletedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deletedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  deletedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deletedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entityId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityId', value: ''),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entityId', value: ''),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entityKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entityKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entityType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityType', value: ''),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  entityTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entityType', value: ''),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
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

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
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

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
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

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
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

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
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

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterFilterCondition>
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

extension IsarDeletedEntityQueryObject
    on QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QFilterCondition> {}

extension IsarDeletedEntityQueryLinks
    on QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QFilterCondition> {}

extension IsarDeletedEntityQuerySortBy
    on QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QSortBy> {
  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  sortByDeletedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  sortByDeletedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  sortByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  sortByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  sortByEntityKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKey', Sort.asc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  sortByEntityKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKey', Sort.desc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  sortByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  sortByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarDeletedEntityQuerySortThenBy
    on QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QSortThenBy> {
  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  thenByDeletedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  thenByDeletedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  thenByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  thenByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  thenByEntityKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKey', Sort.asc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  thenByEntityKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKey', Sort.desc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  thenByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  thenByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarDeletedEntityQueryWhereDistinct
    on QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QDistinct> {
  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QDistinct>
  distinctByDeletedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAtMs');
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QDistinct>
  distinctByEntityId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QDistinct>
  distinctByEntityKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QDistinct>
  distinctByEntityType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarDeletedEntityQueryProperty
    on QueryBuilder<IsarDeletedEntity, IsarDeletedEntity, QQueryProperty> {
  QueryBuilder<IsarDeletedEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarDeletedEntity, int, QQueryOperations> deletedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAtMs');
    });
  }

  QueryBuilder<IsarDeletedEntity, String, QQueryOperations> entityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityId');
    });
  }

  QueryBuilder<IsarDeletedEntity, String, QQueryOperations>
  entityKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityKey');
    });
  }

  QueryBuilder<IsarDeletedEntity, String, QQueryOperations>
  entityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityType');
    });
  }

  QueryBuilder<IsarDeletedEntity, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
