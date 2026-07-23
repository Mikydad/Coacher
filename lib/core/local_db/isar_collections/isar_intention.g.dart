// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_intention.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarIntentionCollection on Isar {
  IsarCollection<IsarIntention> get isarIntentions => this.collection();
}

const IsarIntentionSchema = CollectionSchema(
  name: r'IsarIntention',
  id: 1733782570448883981,
  properties: {
    r'active': PropertySchema(id: 0, name: r'active', type: IsarType.bool),
    r'activityTags': PropertySchema(
      id: 1,
      name: r'activityTags',
      type: IsarType.stringList,
    ),
    r'aiHintsJson': PropertySchema(
      id: 2,
      name: r'aiHintsJson',
      type: IsarType.string,
    ),
    r'anchorEntityId': PropertySchema(
      id: 3,
      name: r'anchorEntityId',
      type: IsarType.string,
    ),
    r'completedAtMs': PropertySchema(
      id: 4,
      name: r'completedAtMs',
      type: IsarType.long,
    ),
    r'createdAtMs': PropertySchema(
      id: 5,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'dependsOnText': PropertySchema(
      id: 6,
      name: r'dependsOnText',
      type: IsarType.string,
    ),
    r'estimatedMinutes': PropertySchema(
      id: 7,
      name: r'estimatedMinutes',
      type: IsarType.long,
    ),
    r'importanceStorage': PropertySchema(
      id: 8,
      name: r'importanceStorage',
      type: IsarType.string,
    ),
    r'intentionId': PropertySchema(
      id: 9,
      name: r'intentionId',
      type: IsarType.string,
    ),
    r'locationHintText': PropertySchema(
      id: 10,
      name: r'locationHintText',
      type: IsarType.string,
    ),
    r'nudgeCount': PropertySchema(
      id: 11,
      name: r'nudgeCount',
      type: IsarType.long,
    ),
    r'personId': PropertySchema(
      id: 12,
      name: r'personId',
      type: IsarType.string,
    ),
    r'pinnedAtMs': PropertySchema(
      id: 13,
      name: r'pinnedAtMs',
      type: IsarType.long,
    ),
    r'rawUtterance': PropertySchema(
      id: 14,
      name: r'rawUtterance',
      type: IsarType.string,
    ),
    r'snoozeCount': PropertySchema(
      id: 15,
      name: r'snoozeCount',
      type: IsarType.long,
    ),
    r'statusStorage': PropertySchema(
      id: 16,
      name: r'statusStorage',
      type: IsarType.string,
    ),
    r'title': PropertySchema(id: 17, name: r'title', type: IsarType.string),
    r'updatedAtMs': PropertySchema(
      id: 18,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
    r'windowEndMs': PropertySchema(
      id: 19,
      name: r'windowEndMs',
      type: IsarType.long,
    ),
    r'windowStartMs': PropertySchema(
      id: 20,
      name: r'windowStartMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarIntentionEstimateSize,
  serialize: _isarIntentionSerialize,
  deserialize: _isarIntentionDeserialize,
  deserializeProp: _isarIntentionDeserializeProp,
  idName: r'id',
  indexes: {
    r'intentionId': IndexSchema(
      id: 4865538607370353671,
      name: r'intentionId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'intentionId',
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
    r'statusStorage': IndexSchema(
      id: 2590634662480333716,
      name: r'statusStorage',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'statusStorage',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarIntentionGetId,
  getLinks: _isarIntentionGetLinks,
  attach: _isarIntentionAttach,
  version: '3.3.2',
);

int _isarIntentionEstimateSize(
  IsarIntention object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activityTags.length * 3;
  {
    for (var i = 0; i < object.activityTags.length; i++) {
      final value = object.activityTags[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.aiHintsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.anchorEntityId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dependsOnText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.importanceStorage.length * 3;
  bytesCount += 3 + object.intentionId.length * 3;
  {
    final value = object.locationHintText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.personId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.rawUtterance.length * 3;
  bytesCount += 3 + object.statusStorage.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _isarIntentionSerialize(
  IsarIntention object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.active);
  writer.writeStringList(offsets[1], object.activityTags);
  writer.writeString(offsets[2], object.aiHintsJson);
  writer.writeString(offsets[3], object.anchorEntityId);
  writer.writeLong(offsets[4], object.completedAtMs);
  writer.writeLong(offsets[5], object.createdAtMs);
  writer.writeString(offsets[6], object.dependsOnText);
  writer.writeLong(offsets[7], object.estimatedMinutes);
  writer.writeString(offsets[8], object.importanceStorage);
  writer.writeString(offsets[9], object.intentionId);
  writer.writeString(offsets[10], object.locationHintText);
  writer.writeLong(offsets[11], object.nudgeCount);
  writer.writeString(offsets[12], object.personId);
  writer.writeLong(offsets[13], object.pinnedAtMs);
  writer.writeString(offsets[14], object.rawUtterance);
  writer.writeLong(offsets[15], object.snoozeCount);
  writer.writeString(offsets[16], object.statusStorage);
  writer.writeString(offsets[17], object.title);
  writer.writeLong(offsets[18], object.updatedAtMs);
  writer.writeLong(offsets[19], object.windowEndMs);
  writer.writeLong(offsets[20], object.windowStartMs);
}

IsarIntention _isarIntentionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarIntention();
  object.active = reader.readBool(offsets[0]);
  object.activityTags = reader.readStringList(offsets[1]) ?? [];
  object.aiHintsJson = reader.readStringOrNull(offsets[2]);
  object.anchorEntityId = reader.readStringOrNull(offsets[3]);
  object.completedAtMs = reader.readLongOrNull(offsets[4]);
  object.createdAtMs = reader.readLong(offsets[5]);
  object.dependsOnText = reader.readStringOrNull(offsets[6]);
  object.estimatedMinutes = reader.readLong(offsets[7]);
  object.id = id;
  object.importanceStorage = reader.readString(offsets[8]);
  object.intentionId = reader.readString(offsets[9]);
  object.locationHintText = reader.readStringOrNull(offsets[10]);
  object.nudgeCount = reader.readLong(offsets[11]);
  object.personId = reader.readStringOrNull(offsets[12]);
  object.pinnedAtMs = reader.readLongOrNull(offsets[13]);
  object.rawUtterance = reader.readString(offsets[14]);
  object.snoozeCount = reader.readLong(offsets[15]);
  object.statusStorage = reader.readString(offsets[16]);
  object.title = reader.readString(offsets[17]);
  object.updatedAtMs = reader.readLong(offsets[18]);
  object.windowEndMs = reader.readLong(offsets[19]);
  object.windowStartMs = reader.readLong(offsets[20]);
  return object;
}

P _isarIntentionDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readLong(offset)) as P;
    case 19:
      return (reader.readLong(offset)) as P;
    case 20:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarIntentionGetId(IsarIntention object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarIntentionGetLinks(IsarIntention object) {
  return [];
}

void _isarIntentionAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarIntention object,
) {
  object.id = id;
}

extension IsarIntentionByIndex on IsarCollection<IsarIntention> {
  Future<IsarIntention?> getByIntentionId(String intentionId) {
    return getByIndex(r'intentionId', [intentionId]);
  }

  IsarIntention? getByIntentionIdSync(String intentionId) {
    return getByIndexSync(r'intentionId', [intentionId]);
  }

  Future<bool> deleteByIntentionId(String intentionId) {
    return deleteByIndex(r'intentionId', [intentionId]);
  }

  bool deleteByIntentionIdSync(String intentionId) {
    return deleteByIndexSync(r'intentionId', [intentionId]);
  }

  Future<List<IsarIntention?>> getAllByIntentionId(
    List<String> intentionIdValues,
  ) {
    final values = intentionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'intentionId', values);
  }

  List<IsarIntention?> getAllByIntentionIdSync(List<String> intentionIdValues) {
    final values = intentionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'intentionId', values);
  }

  Future<int> deleteAllByIntentionId(List<String> intentionIdValues) {
    final values = intentionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'intentionId', values);
  }

  int deleteAllByIntentionIdSync(List<String> intentionIdValues) {
    final values = intentionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'intentionId', values);
  }

  Future<Id> putByIntentionId(IsarIntention object) {
    return putByIndex(r'intentionId', object);
  }

  Id putByIntentionIdSync(IsarIntention object, {bool saveLinks = true}) {
    return putByIndexSync(r'intentionId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByIntentionId(List<IsarIntention> objects) {
    return putAllByIndex(r'intentionId', objects);
  }

  List<Id> putAllByIntentionIdSync(
    List<IsarIntention> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'intentionId', objects, saveLinks: saveLinks);
  }
}

extension IsarIntentionQueryWhereSort
    on QueryBuilder<IsarIntention, IsarIntention, QWhere> {
  QueryBuilder<IsarIntention, IsarIntention, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhere> anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarIntentionQueryWhere
    on QueryBuilder<IsarIntention, IsarIntention, QWhereClause> {
  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause>
  intentionIdEqualTo(String intentionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'intentionId',
          value: [intentionId],
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause>
  intentionIdNotEqualTo(String intentionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intentionId',
                lower: [],
                upper: [intentionId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intentionId',
                lower: [intentionId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intentionId',
                lower: [intentionId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intentionId',
                lower: [],
                upper: [intentionId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause>
  statusStorageEqualTo(String statusStorage) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'statusStorage',
          value: [statusStorage],
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterWhereClause>
  statusStorageNotEqualTo(String statusStorage) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusStorage',
                lower: [],
                upper: [statusStorage],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusStorage',
                lower: [statusStorage],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusStorage',
                lower: [statusStorage],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'statusStorage',
                lower: [],
                upper: [statusStorage],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarIntentionQueryFilter
    on QueryBuilder<IsarIntention, IsarIntention, QFilterCondition> {
  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'active', value: value),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'activityTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'activityTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'activityTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'activityTags',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'activityTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'activityTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'activityTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'activityTags',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'activityTags', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'activityTags', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'activityTags', length, true, length, true);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'activityTags', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'activityTags', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'activityTags', 0, true, length, include);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'activityTags', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  activityTagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activityTags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'aiHintsJson'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'aiHintsJson'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'aiHintsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'aiHintsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'aiHintsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'aiHintsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'aiHintsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'aiHintsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'aiHintsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'aiHintsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'aiHintsJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  aiHintsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'aiHintsJson', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'anchorEntityId'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'anchorEntityId'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'anchorEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'anchorEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'anchorEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'anchorEntityId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'anchorEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'anchorEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'anchorEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'anchorEntityId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'anchorEntityId', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  anchorEntityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'anchorEntityId', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  completedAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'completedAtMs'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  completedAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'completedAtMs'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  completedAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'completedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  completedAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'completedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  completedAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'completedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  completedAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'completedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'dependsOnText'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'dependsOnText'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dependsOnText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dependsOnText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dependsOnText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dependsOnText',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dependsOnText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dependsOnText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dependsOnText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dependsOnText',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dependsOnText', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  dependsOnTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dependsOnText', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  estimatedMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'estimatedMinutes', value: value),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  estimatedMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'estimatedMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  estimatedMinutesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'estimatedMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  estimatedMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'estimatedMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  importanceStorageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'importanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  importanceStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'importanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  importanceStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'importanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  importanceStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'importanceStorage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  importanceStorageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'importanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  importanceStorageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'importanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  importanceStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'importanceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  importanceStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'importanceStorage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  importanceStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'importanceStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  importanceStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'importanceStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  intentionIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  intentionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  intentionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  intentionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'intentionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  intentionIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  intentionIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  intentionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'intentionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  intentionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'intentionId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  intentionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'intentionId', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  intentionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'intentionId', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'locationHintText'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'locationHintText'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'locationHintText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'locationHintText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'locationHintText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'locationHintText',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'locationHintText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'locationHintText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'locationHintText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'locationHintText',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'locationHintText', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  locationHintTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'locationHintText', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  nudgeCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nudgeCount', value: value),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  nudgeCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nudgeCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  nudgeCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nudgeCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  nudgeCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nudgeCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  personIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'personId'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  personIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'personId'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  personIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'personId', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  personIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'personId', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  pinnedAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'pinnedAtMs'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  pinnedAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'pinnedAtMs'),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  pinnedAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pinnedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  pinnedAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pinnedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  pinnedAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pinnedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  pinnedAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pinnedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  rawUtteranceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rawUtterance',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  rawUtteranceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rawUtterance',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  rawUtteranceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rawUtterance',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  rawUtteranceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rawUtterance',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  rawUtteranceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rawUtterance',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  rawUtteranceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rawUtterance',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  rawUtteranceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rawUtterance',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  rawUtteranceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rawUtterance',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  rawUtteranceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rawUtterance', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  rawUtteranceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rawUtterance', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  snoozeCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'snoozeCount', value: value),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  snoozeCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'snoozeCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  snoozeCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'snoozeCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  snoozeCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'snoozeCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  statusStorageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  statusStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  statusStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  statusStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'statusStorage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  statusStorageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  statusStorageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  statusStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'statusStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  statusStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'statusStorage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  statusStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'statusStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  statusStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'statusStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
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

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  windowEndMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'windowEndMs', value: value),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  windowEndMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'windowEndMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  windowEndMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'windowEndMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  windowEndMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'windowEndMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  windowStartMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'windowStartMs', value: value),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  windowStartMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'windowStartMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  windowStartMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'windowStartMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterFilterCondition>
  windowStartMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'windowStartMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarIntentionQueryObject
    on QueryBuilder<IsarIntention, IsarIntention, QFilterCondition> {}

extension IsarIntentionQueryLinks
    on QueryBuilder<IsarIntention, IsarIntention, QFilterCondition> {}

extension IsarIntentionQuerySortBy
    on QueryBuilder<IsarIntention, IsarIntention, QSortBy> {
  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByAiHintsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiHintsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByAiHintsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiHintsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByAnchorEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anchorEntityId', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByAnchorEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anchorEntityId', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByCompletedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByCompletedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByDependsOnText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dependsOnText', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByDependsOnTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dependsOnText', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByEstimatedMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedMinutes', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByEstimatedMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedMinutes', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByImportanceStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByImportanceStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByIntentionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intentionId', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByIntentionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intentionId', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByLocationHintText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationHintText', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByLocationHintTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationHintText', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByNudgeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nudgeCount', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByNudgeCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nudgeCount', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByPersonId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByPersonIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByPinnedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinnedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByPinnedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinnedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByRawUtterance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawUtterance', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByRawUtteranceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawUtterance', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortBySnoozeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozeCount', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortBySnoozeCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozeCount', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByStatusStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByStatusStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> sortByWindowEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEndMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByWindowEndMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEndMs', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByWindowStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowStartMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  sortByWindowStartMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowStartMs', Sort.desc);
    });
  }
}

extension IsarIntentionQuerySortThenBy
    on QueryBuilder<IsarIntention, IsarIntention, QSortThenBy> {
  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByAiHintsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiHintsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByAiHintsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiHintsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByAnchorEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anchorEntityId', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByAnchorEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anchorEntityId', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByCompletedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByCompletedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByDependsOnText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dependsOnText', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByDependsOnTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dependsOnText', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByEstimatedMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedMinutes', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByEstimatedMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedMinutes', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByImportanceStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByImportanceStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByIntentionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intentionId', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByIntentionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intentionId', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByLocationHintText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationHintText', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByLocationHintTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locationHintText', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByNudgeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nudgeCount', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByNudgeCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nudgeCount', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByPersonId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByPersonIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personId', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByPinnedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinnedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByPinnedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pinnedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByRawUtterance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawUtterance', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByRawUtteranceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawUtterance', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenBySnoozeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozeCount', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenBySnoozeCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snoozeCount', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByStatusStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByStatusStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy> thenByWindowEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEndMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByWindowEndMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEndMs', Sort.desc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByWindowStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowStartMs', Sort.asc);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QAfterSortBy>
  thenByWindowStartMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowStartMs', Sort.desc);
    });
  }
}

extension IsarIntentionQueryWhereDistinct
    on QueryBuilder<IsarIntention, IsarIntention, QDistinct> {
  QueryBuilder<IsarIntention, IsarIntention, QDistinct> distinctByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'active');
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByActivityTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activityTags');
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct> distinctByAiHintsJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiHintsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByAnchorEntityId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'anchorEntityId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByCompletedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAtMs');
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByDependsOnText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'dependsOnText',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByEstimatedMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estimatedMinutes');
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByImportanceStorage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'importanceStorage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct> distinctByIntentionId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intentionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByLocationHintText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'locationHintText',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct> distinctByNudgeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nudgeCount');
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct> distinctByPersonId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct> distinctByPinnedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pinnedAtMs');
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct> distinctByRawUtterance({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawUtterance', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctBySnoozeCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'snoozeCount');
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByStatusStorage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'statusStorage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByWindowEndMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'windowEndMs');
    });
  }

  QueryBuilder<IsarIntention, IsarIntention, QDistinct>
  distinctByWindowStartMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'windowStartMs');
    });
  }
}

extension IsarIntentionQueryProperty
    on QueryBuilder<IsarIntention, IsarIntention, QQueryProperty> {
  QueryBuilder<IsarIntention, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarIntention, bool, QQueryOperations> activeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'active');
    });
  }

  QueryBuilder<IsarIntention, List<String>, QQueryOperations>
  activityTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activityTags');
    });
  }

  QueryBuilder<IsarIntention, String?, QQueryOperations> aiHintsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiHintsJson');
    });
  }

  QueryBuilder<IsarIntention, String?, QQueryOperations>
  anchorEntityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'anchorEntityId');
    });
  }

  QueryBuilder<IsarIntention, int?, QQueryOperations> completedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAtMs');
    });
  }

  QueryBuilder<IsarIntention, int, QQueryOperations> createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarIntention, String?, QQueryOperations>
  dependsOnTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dependsOnText');
    });
  }

  QueryBuilder<IsarIntention, int, QQueryOperations>
  estimatedMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estimatedMinutes');
    });
  }

  QueryBuilder<IsarIntention, String, QQueryOperations>
  importanceStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'importanceStorage');
    });
  }

  QueryBuilder<IsarIntention, String, QQueryOperations> intentionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intentionId');
    });
  }

  QueryBuilder<IsarIntention, String?, QQueryOperations>
  locationHintTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'locationHintText');
    });
  }

  QueryBuilder<IsarIntention, int, QQueryOperations> nudgeCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nudgeCount');
    });
  }

  QueryBuilder<IsarIntention, String?, QQueryOperations> personIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personId');
    });
  }

  QueryBuilder<IsarIntention, int?, QQueryOperations> pinnedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pinnedAtMs');
    });
  }

  QueryBuilder<IsarIntention, String, QQueryOperations> rawUtteranceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawUtterance');
    });
  }

  QueryBuilder<IsarIntention, int, QQueryOperations> snoozeCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snoozeCount');
    });
  }

  QueryBuilder<IsarIntention, String, QQueryOperations>
  statusStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statusStorage');
    });
  }

  QueryBuilder<IsarIntention, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<IsarIntention, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }

  QueryBuilder<IsarIntention, int, QQueryOperations> windowEndMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'windowEndMs');
    });
  }

  QueryBuilder<IsarIntention, int, QQueryOperations> windowStartMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'windowStartMs');
    });
  }
}
