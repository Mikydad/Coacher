// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_activity_event.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarActivityEventCollection on Isar {
  IsarCollection<IsarActivityEvent> get isarActivityEvents => this.collection();
}

const IsarActivityEventSchema = CollectionSchema(
  name: r'IsarActivityEvent',
  id: 5003301248034269662,
  properties: {
    r'active': PropertySchema(id: 0, name: r'active', type: IsarType.bool),
    r'category': PropertySchema(
      id: 1,
      name: r'category',
      type: IsarType.string,
    ),
    r'createdAtMs': PropertySchema(
      id: 2,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'dateKey': PropertySchema(id: 3, name: r'dateKey', type: IsarType.string),
    r'endedAtMs': PropertySchema(
      id: 4,
      name: r'endedAtMs',
      type: IsarType.long,
    ),
    r'eventId': PropertySchema(id: 5, name: r'eventId', type: IsarType.string),
    r'intendedMinutes': PropertySchema(
      id: 6,
      name: r'intendedMinutes',
      type: IsarType.long,
    ),
    r'sourceEntityId': PropertySchema(
      id: 7,
      name: r'sourceEntityId',
      type: IsarType.string,
    ),
    r'sourceStorage': PropertySchema(
      id: 8,
      name: r'sourceStorage',
      type: IsarType.string,
    ),
    r'startedAtMs': PropertySchema(
      id: 9,
      name: r'startedAtMs',
      type: IsarType.long,
    ),
    r'text': PropertySchema(id: 10, name: r'text', type: IsarType.string),
    r'updatedAtMs': PropertySchema(
      id: 11,
      name: r'updatedAtMs',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarActivityEventEstimateSize,
  serialize: _isarActivityEventSerialize,
  deserialize: _isarActivityEventDeserialize,
  deserializeProp: _isarActivityEventDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventId': IndexSchema(
      id: -2707901133518603130,
      name: r'eventId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventId',
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
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'startedAtMs': IndexSchema(
      id: -5913036781737194802,
      name: r'startedAtMs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'startedAtMs',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarActivityEventGetId,
  getLinks: _isarActivityEventGetLinks,
  attach: _isarActivityEventAttach,
  version: '3.3.2',
);

int _isarActivityEventEstimateSize(
  IsarActivityEvent object,
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
  bytesCount += 3 + object.dateKey.length * 3;
  bytesCount += 3 + object.eventId.length * 3;
  {
    final value = object.sourceEntityId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sourceStorage.length * 3;
  bytesCount += 3 + object.text.length * 3;
  return bytesCount;
}

void _isarActivityEventSerialize(
  IsarActivityEvent object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.active);
  writer.writeString(offsets[1], object.category);
  writer.writeLong(offsets[2], object.createdAtMs);
  writer.writeString(offsets[3], object.dateKey);
  writer.writeLong(offsets[4], object.endedAtMs);
  writer.writeString(offsets[5], object.eventId);
  writer.writeLong(offsets[6], object.intendedMinutes);
  writer.writeString(offsets[7], object.sourceEntityId);
  writer.writeString(offsets[8], object.sourceStorage);
  writer.writeLong(offsets[9], object.startedAtMs);
  writer.writeString(offsets[10], object.text);
  writer.writeLong(offsets[11], object.updatedAtMs);
}

IsarActivityEvent _isarActivityEventDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarActivityEvent();
  object.active = reader.readBool(offsets[0]);
  object.category = reader.readStringOrNull(offsets[1]);
  object.createdAtMs = reader.readLong(offsets[2]);
  object.dateKey = reader.readString(offsets[3]);
  object.endedAtMs = reader.readLongOrNull(offsets[4]);
  object.eventId = reader.readString(offsets[5]);
  object.id = id;
  object.intendedMinutes = reader.readLongOrNull(offsets[6]);
  object.sourceEntityId = reader.readStringOrNull(offsets[7]);
  object.sourceStorage = reader.readString(offsets[8]);
  object.startedAtMs = reader.readLong(offsets[9]);
  object.text = reader.readString(offsets[10]);
  object.updatedAtMs = reader.readLong(offsets[11]);
  return object;
}

P _isarActivityEventDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarActivityEventGetId(IsarActivityEvent object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarActivityEventGetLinks(
  IsarActivityEvent object,
) {
  return [];
}

void _isarActivityEventAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarActivityEvent object,
) {
  object.id = id;
}

extension IsarActivityEventByIndex on IsarCollection<IsarActivityEvent> {
  Future<IsarActivityEvent?> getByEventId(String eventId) {
    return getByIndex(r'eventId', [eventId]);
  }

  IsarActivityEvent? getByEventIdSync(String eventId) {
    return getByIndexSync(r'eventId', [eventId]);
  }

  Future<bool> deleteByEventId(String eventId) {
    return deleteByIndex(r'eventId', [eventId]);
  }

  bool deleteByEventIdSync(String eventId) {
    return deleteByIndexSync(r'eventId', [eventId]);
  }

  Future<List<IsarActivityEvent?>> getAllByEventId(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventId', values);
  }

  List<IsarActivityEvent?> getAllByEventIdSync(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'eventId', values);
  }

  Future<int> deleteAllByEventId(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'eventId', values);
  }

  int deleteAllByEventIdSync(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'eventId', values);
  }

  Future<Id> putByEventId(IsarActivityEvent object) {
    return putByIndex(r'eventId', object);
  }

  Id putByEventIdSync(IsarActivityEvent object, {bool saveLinks = true}) {
    return putByIndexSync(r'eventId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventId(List<IsarActivityEvent> objects) {
    return putAllByIndex(r'eventId', objects);
  }

  List<Id> putAllByEventIdSync(
    List<IsarActivityEvent> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'eventId', objects, saveLinks: saveLinks);
  }
}

extension IsarActivityEventQueryWhereSort
    on QueryBuilder<IsarActivityEvent, IsarActivityEvent, QWhere> {
  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhere>
  anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhere>
  anyStartedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'startedAtMs'),
      );
    });
  }
}

extension IsarActivityEventQueryWhere
    on QueryBuilder<IsarActivityEvent, IsarActivityEvent, QWhereClause> {
  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  eventIdEqualTo(String eventId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'eventId', value: [eventId]),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  eventIdNotEqualTo(String eventId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [],
                upper: [eventId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [eventId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [eventId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [],
                upper: [eventId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  dateKeyEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dateKey', value: [dateKey]),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  dateKeyNotEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [],
                upper: [dateKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [dateKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [dateKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateKey',
                lower: [],
                upper: [dateKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  startedAtMsEqualTo(int startedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'startedAtMs',
          value: [startedAtMs],
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  startedAtMsNotEqualTo(int startedAtMs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startedAtMs',
                lower: [],
                upper: [startedAtMs],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startedAtMs',
                lower: [startedAtMs],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startedAtMs',
                lower: [startedAtMs],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'startedAtMs',
                lower: [],
                upper: [startedAtMs],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  startedAtMsGreaterThan(int startedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startedAtMs',
          lower: [startedAtMs],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  startedAtMsLessThan(int startedAtMs, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startedAtMs',
          lower: [],
          upper: [startedAtMs],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterWhereClause>
  startedAtMsBetween(
    int lowerStartedAtMs,
    int upperStartedAtMs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'startedAtMs',
          lower: [lowerStartedAtMs],
          includeLower: includeLower,
          upper: [upperStartedAtMs],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarActivityEventQueryFilter
    on QueryBuilder<IsarActivityEvent, IsarActivityEvent, QFilterCondition> {
  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  activeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'active', value: value),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'category'),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'category'),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  categoryEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  categoryBetween(
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  categoryMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  dateKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  dateKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  dateKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dateKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dateKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dateKey', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  endedAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'endedAtMs'),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  endedAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'endedAtMs'),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  endedAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  endedAtMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  endedAtMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  endedAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  eventIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  eventIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  eventIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  eventIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eventId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  eventIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  eventIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  eventIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  eventIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'eventId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  eventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventId', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  eventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventId', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  intendedMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'intendedMinutes'),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  intendedMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'intendedMinutes'),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  intendedMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'intendedMinutes', value: value),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  intendedMinutesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'intendedMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  intendedMinutesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'intendedMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  intendedMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'intendedMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceEntityId'),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceEntityId'),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceEntityId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceEntityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceEntityId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceEntityId', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceEntityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceEntityId', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceStorageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceStorageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceStorageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceStorageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceStorage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceStorageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceStorageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceStorageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceStorage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceStorageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceStorage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceStorageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  sourceStorageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceStorage', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  startedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  startedAtMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  startedAtMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startedAtMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  startedAtMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startedAtMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  textEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
  updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMs', value: value),
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterFilterCondition>
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

extension IsarActivityEventQueryObject
    on QueryBuilder<IsarActivityEvent, IsarActivityEvent, QFilterCondition> {}

extension IsarActivityEventQueryLinks
    on QueryBuilder<IsarActivityEvent, IsarActivityEvent, QFilterCondition> {}

extension IsarActivityEventQuerySortBy
    on QueryBuilder<IsarActivityEvent, IsarActivityEvent, QSortBy> {
  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByEndedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByEndedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByIntendedMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intendedMinutes', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByIntendedMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intendedMinutes', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortBySourceEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceEntityId', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortBySourceEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceEntityId', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortBySourceStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortBySourceStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByStartedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByStartedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarActivityEventQuerySortThenBy
    on QueryBuilder<IsarActivityEvent, IsarActivityEvent, QSortThenBy> {
  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByEndedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByEndedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByIntendedMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intendedMinutes', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByIntendedMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intendedMinutes', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenBySourceEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceEntityId', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenBySourceEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceEntityId', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenBySourceStorage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceStorage', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenBySourceStorageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceStorage', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByStartedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByStartedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QAfterSortBy>
  thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarActivityEventQueryWhereDistinct
    on QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct> {
  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct>
  distinctByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'active');
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct>
  distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct>
  distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct>
  distinctByDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct>
  distinctByEndedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endedAtMs');
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct>
  distinctByEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct>
  distinctByIntendedMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intendedMinutes');
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct>
  distinctBySourceEntityId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceEntityId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct>
  distinctBySourceStorage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceStorage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct>
  distinctByStartedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAtMs');
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct> distinctByText({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarActivityEvent, IsarActivityEvent, QDistinct>
  distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarActivityEventQueryProperty
    on QueryBuilder<IsarActivityEvent, IsarActivityEvent, QQueryProperty> {
  QueryBuilder<IsarActivityEvent, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarActivityEvent, bool, QQueryOperations> activeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'active');
    });
  }

  QueryBuilder<IsarActivityEvent, String?, QQueryOperations>
  categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<IsarActivityEvent, int, QQueryOperations> createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarActivityEvent, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<IsarActivityEvent, int?, QQueryOperations> endedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endedAtMs');
    });
  }

  QueryBuilder<IsarActivityEvent, String, QQueryOperations> eventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventId');
    });
  }

  QueryBuilder<IsarActivityEvent, int?, QQueryOperations>
  intendedMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intendedMinutes');
    });
  }

  QueryBuilder<IsarActivityEvent, String?, QQueryOperations>
  sourceEntityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceEntityId');
    });
  }

  QueryBuilder<IsarActivityEvent, String, QQueryOperations>
  sourceStorageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceStorage');
    });
  }

  QueryBuilder<IsarActivityEvent, int, QQueryOperations> startedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAtMs');
    });
  }

  QueryBuilder<IsarActivityEvent, String, QQueryOperations> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }

  QueryBuilder<IsarActivityEvent, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
