// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_points.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarPointsTxnCollection on Isar {
  IsarCollection<IsarPointsTxn> get isarPointsTxns => this.collection();
}

const IsarPointsTxnSchema = CollectionSchema(
  name: r'IsarPointsTxn',
  id: -2655136617786798919,
  properties: {
    r'amount': PropertySchema(id: 0, name: r'amount', type: IsarType.long),
    r'atMs': PropertySchema(id: 1, name: r'atMs', type: IsarType.long),
    r'refId': PropertySchema(id: 2, name: r'refId', type: IsarType.string),
    r'source': PropertySchema(id: 3, name: r'source', type: IsarType.string),
    r'txnId': PropertySchema(id: 4, name: r'txnId', type: IsarType.string),
    r'updatedAtMs': PropertySchema(
      id: 5,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarPointsTxnEstimateSize,
  serialize: _isarPointsTxnSerialize,
  deserialize: _isarPointsTxnDeserialize,
  deserializeProp: _isarPointsTxnDeserializeProp,
  idName: r'id',
  indexes: {
    r'txnId': IndexSchema(
      id: -4803046173517932941,
      name: r'txnId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'txnId',
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
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarPointsTxnGetId,
  getLinks: _isarPointsTxnGetLinks,
  attach: _isarPointsTxnAttach,
  version: '3.3.2',
);

int _isarPointsTxnEstimateSize(
  IsarPointsTxn object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.refId.length * 3;
  bytesCount += 3 + object.source.length * 3;
  bytesCount += 3 + object.txnId.length * 3;
  return bytesCount;
}

void _isarPointsTxnSerialize(
  IsarPointsTxn object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.amount);
  writer.writeLong(offsets[1], object.atMs);
  writer.writeString(offsets[2], object.refId);
  writer.writeString(offsets[3], object.source);
  writer.writeString(offsets[4], object.txnId);
  writer.writeLong(offsets[5], object.updatedAtMs);
}

IsarPointsTxn _isarPointsTxnDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarPointsTxn();
  object.amount = reader.readLong(offsets[0]);
  object.atMs = reader.readLong(offsets[1]);
  object.id = id;
  object.refId = reader.readString(offsets[2]);
  object.source = reader.readString(offsets[3]);
  object.txnId = reader.readString(offsets[4]);
  object.updatedAtMs = reader.readLong(offsets[5]);
  return object;
}

P _isarPointsTxnDeserializeProp<P>(
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarPointsTxnGetId(IsarPointsTxn object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarPointsTxnGetLinks(IsarPointsTxn object) {
  return [];
}

void _isarPointsTxnAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarPointsTxn object,
) {
  object.id = id;
}

extension IsarPointsTxnByIndex on IsarCollection<IsarPointsTxn> {
  Future<IsarPointsTxn?> getByTxnId(String txnId) {
    return getByIndex(r'txnId', [txnId]);
  }

  IsarPointsTxn? getByTxnIdSync(String txnId) {
    return getByIndexSync(r'txnId', [txnId]);
  }

  Future<bool> deleteByTxnId(String txnId) {
    return deleteByIndex(r'txnId', [txnId]);
  }

  bool deleteByTxnIdSync(String txnId) {
    return deleteByIndexSync(r'txnId', [txnId]);
  }

  Future<List<IsarPointsTxn?>> getAllByTxnId(List<String> txnIdValues) {
    final values = txnIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'txnId', values);
  }

  List<IsarPointsTxn?> getAllByTxnIdSync(List<String> txnIdValues) {
    final values = txnIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'txnId', values);
  }

  Future<int> deleteAllByTxnId(List<String> txnIdValues) {
    final values = txnIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'txnId', values);
  }

  int deleteAllByTxnIdSync(List<String> txnIdValues) {
    final values = txnIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'txnId', values);
  }

  Future<Id> putByTxnId(IsarPointsTxn object) {
    return putByIndex(r'txnId', object);
  }

  Id putByTxnIdSync(IsarPointsTxn object, {bool saveLinks = true}) {
    return putByIndexSync(r'txnId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTxnId(List<IsarPointsTxn> objects) {
    return putAllByIndex(r'txnId', objects);
  }

  List<Id> putAllByTxnIdSync(
    List<IsarPointsTxn> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'txnId', objects, saveLinks: saveLinks);
  }
}

extension IsarPointsTxnQueryWhereSort
    on QueryBuilder<IsarPointsTxn, IsarPointsTxn, QWhere> {
  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhere> anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarPointsTxnQueryWhere
    on QueryBuilder<IsarPointsTxn, IsarPointsTxn, QWhereClause> {
  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause> txnIdEqualTo(
    String txnId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'txnId', value: [txnId]),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause> txnIdNotEqualTo(
    String txnId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'txnId',
                lower: [],
                upper: [txnId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'txnId',
                lower: [txnId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'txnId',
                lower: [txnId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'txnId',
                lower: [],
                upper: [txnId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause>
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

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause>
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

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause>
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

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause>
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

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterWhereClause>
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
}

extension IsarPointsTxnQueryFilter
    on QueryBuilder<IsarPointsTxn, IsarPointsTxn, QFilterCondition> {
  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  amountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'amount', value: value),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  amountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'amount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  amountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'amount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  amountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'amount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition> atMsEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'atMs', value: value),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  atMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'atMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  atMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'atMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition> atMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'atMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
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

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  refIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'refId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  refIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'refId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  refIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'refId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  refIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'refId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  refIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'refId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  refIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'refId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  refIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'refId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  refIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'refId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  refIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'refId', value: ''),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  refIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'refId', value: ''),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  sourceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  sourceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  sourceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'source',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  txnIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'txnId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  txnIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'txnId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  txnIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'txnId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  txnIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'txnId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  txnIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'txnId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  txnIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'txnId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  txnIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'txnId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  txnIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'txnId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  txnIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'txnId', value: ''),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  txnIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'txnId', value: ''),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
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

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
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

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterFilterCondition>
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

extension IsarPointsTxnQueryObject
    on QueryBuilder<IsarPointsTxn, IsarPointsTxn, QFilterCondition> {}

extension IsarPointsTxnQueryLinks
    on QueryBuilder<IsarPointsTxn, IsarPointsTxn, QFilterCondition> {}

extension IsarPointsTxnQuerySortBy
    on QueryBuilder<IsarPointsTxn, IsarPointsTxn, QSortBy> {
  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> sortByAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'atMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> sortByAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'atMs', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> sortByRefId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refId', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> sortByRefIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refId', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> sortByTxnId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txnId', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> sortByTxnIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txnId', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarPointsTxnQuerySortThenBy
    on QueryBuilder<IsarPointsTxn, IsarPointsTxn, QSortThenBy> {
  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenByAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'atMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenByAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'atMs', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenByRefId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refId', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenByRefIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refId', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenByTxnId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txnId', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenByTxnIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txnId', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy> thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarPointsTxnQueryWhereDistinct
    on QueryBuilder<IsarPointsTxn, IsarPointsTxn, QDistinct> {
  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QDistinct> distinctByAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'atMs');
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QDistinct> distinctByRefId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'refId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QDistinct> distinctBySource({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QDistinct> distinctByTxnId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'txnId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPointsTxn, IsarPointsTxn, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarPointsTxnQueryProperty
    on QueryBuilder<IsarPointsTxn, IsarPointsTxn, QQueryProperty> {
  QueryBuilder<IsarPointsTxn, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarPointsTxn, int, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<IsarPointsTxn, int, QQueryOperations> atMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'atMs');
    });
  }

  QueryBuilder<IsarPointsTxn, String, QQueryOperations> refIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'refId');
    });
  }

  QueryBuilder<IsarPointsTxn, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<IsarPointsTxn, String, QQueryOperations> txnIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'txnId');
    });
  }

  QueryBuilder<IsarPointsTxn, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarPointsBalanceCollection on Isar {
  IsarCollection<IsarPointsBalance> get isarPointsBalances => this.collection();
}

const IsarPointsBalanceSchema = CollectionSchema(
  name: r'IsarPointsBalance',
  id: 35736518382135438,
  properties: {
    r'balance': PropertySchema(id: 0, name: r'balance', type: IsarType.long),
    r'uid': PropertySchema(id: 1, name: r'uid', type: IsarType.string),
    r'updatedAtMs': PropertySchema(
      id: 2,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarPointsBalanceEstimateSize,
  serialize: _isarPointsBalanceSerialize,
  deserialize: _isarPointsBalanceDeserialize,
  deserializeProp: _isarPointsBalanceDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uid',
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
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarPointsBalanceGetId,
  getLinks: _isarPointsBalanceGetLinks,
  attach: _isarPointsBalanceAttach,
  version: '3.3.2',
);

int _isarPointsBalanceEstimateSize(
  IsarPointsBalance object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _isarPointsBalanceSerialize(
  IsarPointsBalance object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.balance);
  writer.writeString(offsets[1], object.uid);
  writer.writeLong(offsets[2], object.updatedAtMs);
}

IsarPointsBalance _isarPointsBalanceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarPointsBalance();
  object.balance = reader.readLong(offsets[0]);
  object.id = id;
  object.uid = reader.readString(offsets[1]);
  object.updatedAtMs = reader.readLong(offsets[2]);
  return object;
}

P _isarPointsBalanceDeserializeProp<P>(
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarPointsBalanceGetId(IsarPointsBalance object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarPointsBalanceGetLinks(
  IsarPointsBalance object,
) {
  return [];
}

void _isarPointsBalanceAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarPointsBalance object,
) {
  object.id = id;
}

extension IsarPointsBalanceByIndex on IsarCollection<IsarPointsBalance> {
  Future<IsarPointsBalance?> getByUid(String uid) {
    return getByIndex(r'uid', [uid]);
  }

  IsarPointsBalance? getByUidSync(String uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<IsarPointsBalance?>> getAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<IsarPointsBalance?> getAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(IsarPointsBalance object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(IsarPointsBalance object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<IsarPointsBalance> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(
    List<IsarPointsBalance> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension IsarPointsBalanceQueryWhereSort
    on QueryBuilder<IsarPointsBalance, IsarPointsBalance, QWhere> {
  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhere>
  anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarPointsBalanceQueryWhere
    on QueryBuilder<IsarPointsBalance, IsarPointsBalance, QWhereClause> {
  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
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

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
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

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
  uidEqualTo(String uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uid', value: [uid]),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
  uidNotEqualTo(String uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [uid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uid',
                lower: [],
                upper: [uid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
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

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
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

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
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

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
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

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterWhereClause>
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
}

extension IsarPointsBalanceQueryFilter
    on QueryBuilder<IsarPointsBalance, IsarPointsBalance, QFilterCondition> {
  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  balanceEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'balance', value: value),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  balanceGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'balance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  balanceLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'balance',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  balanceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'balance',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
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

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
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

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
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

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  uidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  uidLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  uidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  uidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uid', value: ''),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
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

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
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

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterFilterCondition>
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

extension IsarPointsBalanceQueryObject
    on QueryBuilder<IsarPointsBalance, IsarPointsBalance, QFilterCondition> {}

extension IsarPointsBalanceQueryLinks
    on QueryBuilder<IsarPointsBalance, IsarPointsBalance, QFilterCondition> {}

extension IsarPointsBalanceQuerySortBy
    on QueryBuilder<IsarPointsBalance, IsarPointsBalance, QSortBy> {
  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy>
  sortByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy>
  sortByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy>
  sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarPointsBalanceQuerySortThenBy
    on QueryBuilder<IsarPointsBalance, IsarPointsBalance, QSortThenBy> {
  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy>
  thenByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy>
  thenByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy>
  thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarPointsBalanceQueryWhereDistinct
    on QueryBuilder<IsarPointsBalance, IsarPointsBalance, QDistinct> {
  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QDistinct>
  distinctByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balance');
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QDistinct> distinctByUid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPointsBalance, IsarPointsBalance, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarPointsBalanceQueryProperty
    on QueryBuilder<IsarPointsBalance, IsarPointsBalance, QQueryProperty> {
  QueryBuilder<IsarPointsBalance, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarPointsBalance, int, QQueryOperations> balanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balance');
    });
  }

  QueryBuilder<IsarPointsBalance, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<IsarPointsBalance, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarCharityCollection on Isar {
  IsarCollection<IsarCharity> get isarCharitys => this.collection();
}

const IsarCharitySchema = CollectionSchema(
  name: r'IsarCharity',
  id: 411749416068935415,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'charityId': PropertySchema(
      id: 1,
      name: r'charityId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(id: 2, name: r'name', type: IsarType.string),
    r'updatedAtMs': PropertySchema(
      id: 3,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarCharityEstimateSize,
  serialize: _isarCharitySerialize,
  deserialize: _isarCharityDeserialize,
  deserializeProp: _isarCharityDeserializeProp,
  idName: r'id',
  indexes: {
    r'charityId': IndexSchema(
      id: 7529366351752218294,
      name: r'charityId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'charityId',
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
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarCharityGetId,
  getLinks: _isarCharityGetLinks,
  attach: _isarCharityAttach,
  version: '3.3.2',
);

int _isarCharityEstimateSize(
  IsarCharity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.charityId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _isarCharitySerialize(
  IsarCharity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeString(offsets[1], object.charityId);
  writer.writeString(offsets[2], object.name);
  writer.writeLong(offsets[3], object.updatedAtMs);
}

IsarCharity _isarCharityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarCharity();
  object.category = reader.readStringOrNull(offsets[0]);
  object.charityId = reader.readString(offsets[1]);
  object.id = id;
  object.name = reader.readString(offsets[2]);
  object.updatedAtMs = reader.readLong(offsets[3]);
  return object;
}

P _isarCharityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarCharityGetId(IsarCharity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarCharityGetLinks(IsarCharity object) {
  return [];
}

void _isarCharityAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarCharity object,
) {
  object.id = id;
}

extension IsarCharityByIndex on IsarCollection<IsarCharity> {
  Future<IsarCharity?> getByCharityId(String charityId) {
    return getByIndex(r'charityId', [charityId]);
  }

  IsarCharity? getByCharityIdSync(String charityId) {
    return getByIndexSync(r'charityId', [charityId]);
  }

  Future<bool> deleteByCharityId(String charityId) {
    return deleteByIndex(r'charityId', [charityId]);
  }

  bool deleteByCharityIdSync(String charityId) {
    return deleteByIndexSync(r'charityId', [charityId]);
  }

  Future<List<IsarCharity?>> getAllByCharityId(List<String> charityIdValues) {
    final values = charityIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'charityId', values);
  }

  List<IsarCharity?> getAllByCharityIdSync(List<String> charityIdValues) {
    final values = charityIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'charityId', values);
  }

  Future<int> deleteAllByCharityId(List<String> charityIdValues) {
    final values = charityIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'charityId', values);
  }

  int deleteAllByCharityIdSync(List<String> charityIdValues) {
    final values = charityIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'charityId', values);
  }

  Future<Id> putByCharityId(IsarCharity object) {
    return putByIndex(r'charityId', object);
  }

  Id putByCharityIdSync(IsarCharity object, {bool saveLinks = true}) {
    return putByIndexSync(r'charityId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCharityId(List<IsarCharity> objects) {
    return putAllByIndex(r'charityId', objects);
  }

  List<Id> putAllByCharityIdSync(
    List<IsarCharity> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'charityId', objects, saveLinks: saveLinks);
  }
}

extension IsarCharityQueryWhereSort
    on QueryBuilder<IsarCharity, IsarCharity, QWhere> {
  QueryBuilder<IsarCharity, IsarCharity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhere> anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarCharityQueryWhere
    on QueryBuilder<IsarCharity, IsarCharity, QWhereClause> {
  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause> charityIdEqualTo(
    String charityId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'charityId', value: [charityId]),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause> charityIdNotEqualTo(
    String charityId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'charityId',
                lower: [],
                upper: [charityId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'charityId',
                lower: [charityId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'charityId',
                lower: [charityId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'charityId',
                lower: [],
                upper: [charityId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause> updatedAtMsEqualTo(
    int updatedAtMs,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'updatedAtMs',
          value: [updatedAtMs],
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause>
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause>
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause> updatedAtMsLessThan(
    int updatedAtMs, {
    bool include = false,
  }) {
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterWhereClause> updatedAtMsBetween(
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
}

extension IsarCharityQueryFilter
    on QueryBuilder<IsarCharity, IsarCharity, QFilterCondition> {
  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'category'),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'category'),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> categoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  categoryGreaterThan(
    String? value, {
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  categoryLessThan(
    String? value, {
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> categoryBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> categoryMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  charityIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'charityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  charityIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'charityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  charityIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'charityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  charityIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'charityId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  charityIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'charityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  charityIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'charityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  charityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'charityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  charityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'charityId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  charityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'charityId', value: ''),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  charityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'charityId', value: ''),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> nameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
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

  QueryBuilder<IsarCharity, IsarCharity, QAfterFilterCondition>
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

extension IsarCharityQueryObject
    on QueryBuilder<IsarCharity, IsarCharity, QFilterCondition> {}

extension IsarCharityQueryLinks
    on QueryBuilder<IsarCharity, IsarCharity, QFilterCondition> {}

extension IsarCharityQuerySortBy
    on QueryBuilder<IsarCharity, IsarCharity, QSortBy> {
  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> sortByCharityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'charityId', Sort.asc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> sortByCharityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'charityId', Sort.desc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarCharityQuerySortThenBy
    on QueryBuilder<IsarCharity, IsarCharity, QSortThenBy> {
  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> thenByCharityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'charityId', Sort.asc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> thenByCharityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'charityId', Sort.desc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QAfterSortBy> thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarCharityQueryWhereDistinct
    on QueryBuilder<IsarCharity, IsarCharity, QDistinct> {
  QueryBuilder<IsarCharity, IsarCharity, QDistinct> distinctByCategory({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QDistinct> distinctByCharityId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'charityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarCharity, IsarCharity, QDistinct> distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarCharityQueryProperty
    on QueryBuilder<IsarCharity, IsarCharity, QQueryProperty> {
  QueryBuilder<IsarCharity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarCharity, String?, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<IsarCharity, String, QQueryOperations> charityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'charityId');
    });
  }

  QueryBuilder<IsarCharity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<IsarCharity, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
