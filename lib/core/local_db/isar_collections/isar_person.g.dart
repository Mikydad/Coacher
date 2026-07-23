// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_person.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarPersonCollection on Isar {
  IsarCollection<IsarPerson> get isarPersons => this.collection();
}

const IsarPersonSchema = CollectionSchema(
  name: r'IsarPerson',
  id: 1332677496781125861,
  properties: {
    r'active': PropertySchema(id: 0, name: r'active', type: IsarType.bool),
    r'aliases': PropertySchema(
      id: 1,
      name: r'aliases',
      type: IsarType.stringList,
    ),
    r'createdAtMs': PropertySchema(
      id: 2,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'displayName': PropertySchema(
      id: 3,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'kindStorage': PropertySchema(
      id: 4,
      name: r'kindStorage',
      type: IsarType.string,
    ),
    r'lastInteractionAtMs': PropertySchema(
      id: 5,
      name: r'lastInteractionAtMs',
      type: IsarType.long,
    ),
    r'notesJson': PropertySchema(
      id: 6,
      name: r'notesJson',
      type: IsarType.string,
    ),
    r'personId': PropertySchema(
      id: 7,
      name: r'personId',
      type: IsarType.string,
    ),
    r'provenanceStorage': PropertySchema(
      id: 8,
      name: r'provenanceStorage',
      type: IsarType.string,
    ),
    r'relationship': PropertySchema(
      id: 9,
      name: r'relationship',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 10,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarPersonEstimateSize,
  serialize: _isarPersonSerialize,
  deserialize: _isarPersonDeserialize,
  deserializeProp: _isarPersonDeserializeProp,
  idName: r'id',
  indexes: {
    r'personId': IndexSchema(
      id: 750717629518044662,
      name: r'personId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'personId',
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
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarPersonGetId,
  getLinks: _isarPersonGetLinks,
  attach: _isarPersonAttach,
  version: '3.3.2',
);

int _isarPersonEstimateSize(
  IsarPerson object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.aliases.length * 3;
  {
    for (var i = 0; i < object.aliases.length; i++) {
      final value = object.aliases[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.displayName.length * 3;
  bytesCount += 3 + object.kindStorage.length * 3;
  {
    final value = object.notesJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.personId.length * 3;
  bytesCount += 3 + object.provenanceStorage.length * 3;
  {
    final value = object.relationship;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarPersonSerialize(
  IsarPerson object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.active);
  writer.writeStringList(offsets[1], object.aliases);
  writer.writeLong(offsets[2], object.createdAtMs);
  writer.writeString(offsets[3], object.displayName);
  writer.writeString(offsets[4], object.kindStorage);
  writer.writeLong(offsets[5], object.lastInteractionAtMs);
  writer.writeString(offsets[6], object.notesJson);
  writer.writeString(offsets[7], object.personId);
  writer.writeString(offsets[8], object.provenanceStorage);
  writer.writeString(offsets[9], object.relationship);
  writer.writeLong(offsets[10], object.updatedAtMs);
}

IsarPerson _isarPersonDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarPerson();
  object.active = reader.readBool(offsets[0]);
  object.aliases = reader.readStringList(offsets[1]) ?? [];
  object.createdAtMs = reader.readLong(offsets[2]);
  object.displayName = reader.readString(offsets[3]);
  object.id = id;
  object.kindStorage = reader.readString(offsets[4]);
  object.lastInteractionAtMs = reader.readLongOrNull(offsets[5]);
  object.notesJson = reader.readStringOrNull(offsets[6]);
  object.personId = reader.readString(offsets[7]);
  object.provenanceStorage = reader.readString(offsets[8]);
  object.relationship = reader.readStringOrNull(offsets[9]);
  object.updatedAtMs = reader.readLong(offsets[10]);
  return object;
}

P _isarPersonDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarPersonGetId(IsarPerson object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarPersonGetLinks(IsarPerson object) {
  return [];
}

void _isarPersonAttach(IsarCollection<dynamic> col, Id id, IsarPerson object) {
  object.id = id;
}

extension IsarPersonByIndex on IsarCollection<IsarPerson> {
  Future<IsarPerson?> getByPersonId(String personId) {
    return getByIndex(r'personId', [personId]);
  }

  IsarPerson? getByPersonIdSync(String personId) {
    return getByIndexSync(r'personId', [personId]);
  }

  Future<bool> deleteByPersonId(String personId) {
    return deleteByIndex(r'personId', [personId]);
  }

  bool deleteByPersonIdSync(String personId) {
    return deleteByIndexSync(r'personId', [personId]);
  }

  Future<List<IsarPerson?>> getAllByPersonId(List<String> personIdValues) {
    final values = personIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'personId', values);
  }

  List<IsarPerson?> getAllByPersonIdSync(List<String> personIdValues) {
    final values = personIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'personId', values);
  }

  Future<int> deleteAllByPersonId(List<String> personIdValues) {
    final values = personIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'personId', values);
  }

  int deleteAllByPersonIdSync(List<String> personIdValues) {
    final values = personIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'personId', values);
  }

  Future<Id> putByPersonId(IsarPerson object) {
    return putByIndex(r'personId', object);
  }

  Id putByPersonIdSync(IsarPerson object, {bool saveLinks = true}) {
    return putByIndexSync(r'personId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPersonId(List<IsarPerson> objects) {
    return putAllByIndex(r'personId', objects);
  }

  List<Id> putAllByPersonIdSync(
    List<IsarPerson> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'personId', objects, saveLinks: saveLinks);
  }
}

extension IsarPersonQueryWhereSort
    on QueryBuilder<IsarPerson, IsarPerson, QWhere> {
  QueryBuilder<IsarPerson, IsarPerson, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhere> anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarPersonQueryWhere
    on QueryBuilder<IsarPerson, IsarPerson, QWhereClause> {
  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> personIdEqualTo(
    String personId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'personId', value: [personId]),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> personIdNotEqualTo(
    String personId,
  ) {
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> updatedAtMsEqualTo(
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> updatedAtMsNotEqualTo(
    int updatedAtMs,
  ) {
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> updatedAtMsLessThan(
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> updatedAtMsBetween(
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> kindStorageEqualTo(
    String kindStorage,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'kindStorage',
          value: [kindStorage],
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterWhereClause> kindStorageNotEqualTo(
    String kindStorage,
  ) {
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
}

extension IsarPersonQueryFilter
    on QueryBuilder<IsarPerson, IsarPerson, QFilterCondition> {
  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> activeEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'active', value: value),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'aliases',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'aliases',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'aliases',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'aliases', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'aliases', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'aliases', length, true, length, true);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> aliasesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'aliases', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'aliases', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'aliases', 0, true, length, include);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'aliases', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  aliasesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aliases',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  displayNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'displayName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  displayNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  displayNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'displayName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'displayName', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'displayName', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  kindStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kindStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  kindStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'kindStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  lastInteractionAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastInteractionAtMs'),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  lastInteractionAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastInteractionAtMs'),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  lastInteractionAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastInteractionAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  lastInteractionAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastInteractionAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  lastInteractionAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastInteractionAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  lastInteractionAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastInteractionAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  notesJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notesJson'),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  notesJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notesJson'),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> notesJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'notesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  notesJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> notesJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> notesJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notesJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  notesJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'notesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> notesJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'notesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> notesJsonContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'notesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> notesJsonMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'notesJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  notesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notesJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  notesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notesJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> personIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  personIdGreaterThan(
    String value, {
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> personIdLessThan(
    String value, {
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> personIdBetween(
    String lower,
    String upper, {
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> personIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> personIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition> personIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  personIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'personId', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  personIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'personId', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  provenanceStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'provenanceStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  provenanceStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'provenanceStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'relationship'),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'relationship'),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'relationship',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'relationship',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'relationship',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'relationship',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'relationship',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'relationship',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'relationship',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'relationship',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'relationship', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  relationshipIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'relationship', value: ''),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

  QueryBuilder<IsarPerson, IsarPerson, QAfterFilterCondition>
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

extension IsarPersonQueryObject
    on QueryBuilder<IsarPerson, IsarPerson, QFilterCondition> {}

extension IsarPersonQueryLinks
    on QueryBuilder<IsarPerson, IsarPerson, QFilterCondition> {}

extension IsarPersonQuerySortBy
    on QueryBuilder<IsarPerson, IsarPerson, QSortBy> {
  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByKindStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByKindStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy>
  sortByLastInteractionAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastInteractionAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy>
  sortByLastInteractionAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastInteractionAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByNotesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notesJson', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByNotesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notesJson', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByPersonId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByPersonIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByProvenanceStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenanceStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy>
  sortByProvenanceStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenanceStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByRelationship() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationship', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByRelationshipDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationship', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarPersonQuerySortThenBy
    on QueryBuilder<IsarPerson, IsarPerson, QSortThenBy> {
  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByKindStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByKindStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kindStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy>
  thenByLastInteractionAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastInteractionAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy>
  thenByLastInteractionAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastInteractionAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByNotesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notesJson', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByNotesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notesJson', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByPersonId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByPersonIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByProvenanceStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenanceStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy>
  thenByProvenanceStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provenanceStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByRelationship() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationship', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByRelationshipDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relationship', Sort.desc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QAfterSortBy> thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarPersonQueryWhereDistinct
    on QueryBuilder<IsarPerson, IsarPerson, QDistinct> {
  QueryBuilder<IsarPerson, IsarPerson, QDistinct> distinctByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'active');
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QDistinct> distinctByAliases() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aliases');
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QDistinct> distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QDistinct> distinctByDisplayName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QDistinct> distinctByKindStorage({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kindStorage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QDistinct>
  distinctByLastInteractionAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastInteractionAtMs');
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QDistinct> distinctByNotesJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notesJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QDistinct> distinctByPersonId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QDistinct> distinctByProvenanceStorage({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'provenanceStorage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QDistinct> distinctByRelationship({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relationship', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarPerson, IsarPerson, QDistinct> distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarPersonQueryProperty
    on QueryBuilder<IsarPerson, IsarPerson, QQueryProperty> {
  QueryBuilder<IsarPerson, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarPerson, bool, QQueryOperations> activeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'active');
    });
  }

  QueryBuilder<IsarPerson, List<String>, QQueryOperations> aliasesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aliases');
    });
  }

  QueryBuilder<IsarPerson, int, QQueryOperations> createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarPerson, String, QQueryOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<IsarPerson, String, QQueryOperations> kindStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kindStorage');
    });
  }

  QueryBuilder<IsarPerson, int?, QQueryOperations>
  lastInteractionAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastInteractionAtMs');
    });
  }

  QueryBuilder<IsarPerson, String?, QQueryOperations> notesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notesJson');
    });
  }

  QueryBuilder<IsarPerson, String, QQueryOperations> personIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personId');
    });
  }

  QueryBuilder<IsarPerson, String, QQueryOperations>
  provenanceStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'provenanceStorage');
    });
  }

  QueryBuilder<IsarPerson, String?, QQueryOperations> relationshipProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relationship');
    });
  }

  QueryBuilder<IsarPerson, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
