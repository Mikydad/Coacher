// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_reminder.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarReminderCollection on Isar {
  IsarCollection<IsarReminder> get isarReminders => this.collection();
}

const IsarReminderSchema = CollectionSchema(
  name: r'IsarReminder',
  id: -9071037972073274484,
  properties: {
    r'blockUrgencyScore': PropertySchema(
      id: 0,
      name: r'blockUrgencyScore',
      type: IsarType.long,
    ),
    r'createdAtMs': PropertySchema(
      id: 1,
      name: r'createdAtMs',
      type: IsarType.long,
    ),
    r'emergencyBypass': PropertySchema(
      id: 2,
      name: r'emergencyBypass',
      type: IsarType.bool,
    ),
    r'enabled': PropertySchema(
      id: 3,
      name: r'enabled',
      type: IsarType.bool,
    ),
    r'escalationLevel': PropertySchema(
      id: 4,
      name: r'escalationLevel',
      type: IsarType.long,
    ),
    r'lastTriggeredAtMs': PropertySchema(
      id: 5,
      name: r'lastTriggeredAtMs',
      type: IsarType.long,
    ),
    r'modeRefId': PropertySchema(
      id: 6,
      name: r'modeRefId',
      type: IsarType.string,
    ),
    r'nextPromptAtIso': PropertySchema(
      id: 7,
      name: r'nextPromptAtIso',
      type: IsarType.string,
    ),
    r'pendingAction': PropertySchema(
      id: 8,
      name: r'pendingAction',
      type: IsarType.bool,
    ),
    r'reminderId': PropertySchema(
      id: 9,
      name: r'reminderId',
      type: IsarType.string,
    ),
    r'scheduledAtIso': PropertySchema(
      id: 10,
      name: r'scheduledAtIso',
      type: IsarType.string,
    ),
    r'taskId': PropertySchema(
      id: 11,
      name: r'taskId',
      type: IsarType.string,
    ),
    r'taskTitle': PropertySchema(
      id: 12,
      name: r'taskTitle',
      type: IsarType.string,
    ),
    r'updatedAtMs': PropertySchema(
      id: 13,
      name: r'updatedAtMs',
      type: IsarType.long,
    )
  },
  estimateSize: _isarReminderEstimateSize,
  serialize: _isarReminderSerialize,
  deserialize: _isarReminderDeserialize,
  deserializeProp: _isarReminderDeserializeProp,
  idName: r'id',
  indexes: {
    r'reminderId': IndexSchema(
      id: 3675930301236523255,
      name: r'reminderId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'reminderId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'taskId': IndexSchema(
      id: -6391211041487498726,
      name: r'taskId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'taskId',
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
  getId: _isarReminderGetId,
  getLinks: _isarReminderGetLinks,
  attach: _isarReminderAttach,
  version: '3.1.0+1',
);

int _isarReminderEstimateSize(
  IsarReminder object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.modeRefId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.nextPromptAtIso;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.reminderId.length * 3;
  {
    final value = object.scheduledAtIso;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.taskId.length * 3;
  {
    final value = object.taskTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarReminderSerialize(
  IsarReminder object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.blockUrgencyScore);
  writer.writeLong(offsets[1], object.createdAtMs);
  writer.writeBool(offsets[2], object.emergencyBypass);
  writer.writeBool(offsets[3], object.enabled);
  writer.writeLong(offsets[4], object.escalationLevel);
  writer.writeLong(offsets[5], object.lastTriggeredAtMs);
  writer.writeString(offsets[6], object.modeRefId);
  writer.writeString(offsets[7], object.nextPromptAtIso);
  writer.writeBool(offsets[8], object.pendingAction);
  writer.writeString(offsets[9], object.reminderId);
  writer.writeString(offsets[10], object.scheduledAtIso);
  writer.writeString(offsets[11], object.taskId);
  writer.writeString(offsets[12], object.taskTitle);
  writer.writeLong(offsets[13], object.updatedAtMs);
}

IsarReminder _isarReminderDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarReminder();
  object.blockUrgencyScore = reader.readLong(offsets[0]);
  object.createdAtMs = reader.readLong(offsets[1]);
  object.emergencyBypass = reader.readBool(offsets[2]);
  object.enabled = reader.readBool(offsets[3]);
  object.escalationLevel = reader.readLong(offsets[4]);
  object.id = id;
  object.lastTriggeredAtMs = reader.readLongOrNull(offsets[5]);
  object.modeRefId = reader.readStringOrNull(offsets[6]);
  object.nextPromptAtIso = reader.readStringOrNull(offsets[7]);
  object.pendingAction = reader.readBool(offsets[8]);
  object.reminderId = reader.readString(offsets[9]);
  object.scheduledAtIso = reader.readStringOrNull(offsets[10]);
  object.taskId = reader.readString(offsets[11]);
  object.taskTitle = reader.readStringOrNull(offsets[12]);
  object.updatedAtMs = reader.readLong(offsets[13]);
  return object;
}

P _isarReminderDeserializeProp<P>(
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
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarReminderGetId(IsarReminder object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarReminderGetLinks(IsarReminder object) {
  return [];
}

void _isarReminderAttach(
    IsarCollection<dynamic> col, Id id, IsarReminder object) {
  object.id = id;
}

extension IsarReminderByIndex on IsarCollection<IsarReminder> {
  Future<IsarReminder?> getByReminderId(String reminderId) {
    return getByIndex(r'reminderId', [reminderId]);
  }

  IsarReminder? getByReminderIdSync(String reminderId) {
    return getByIndexSync(r'reminderId', [reminderId]);
  }

  Future<bool> deleteByReminderId(String reminderId) {
    return deleteByIndex(r'reminderId', [reminderId]);
  }

  bool deleteByReminderIdSync(String reminderId) {
    return deleteByIndexSync(r'reminderId', [reminderId]);
  }

  Future<List<IsarReminder?>> getAllByReminderId(
      List<String> reminderIdValues) {
    final values = reminderIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'reminderId', values);
  }

  List<IsarReminder?> getAllByReminderIdSync(List<String> reminderIdValues) {
    final values = reminderIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'reminderId', values);
  }

  Future<int> deleteAllByReminderId(List<String> reminderIdValues) {
    final values = reminderIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'reminderId', values);
  }

  int deleteAllByReminderIdSync(List<String> reminderIdValues) {
    final values = reminderIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'reminderId', values);
  }

  Future<Id> putByReminderId(IsarReminder object) {
    return putByIndex(r'reminderId', object);
  }

  Id putByReminderIdSync(IsarReminder object, {bool saveLinks = true}) {
    return putByIndexSync(r'reminderId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByReminderId(List<IsarReminder> objects) {
    return putAllByIndex(r'reminderId', objects);
  }

  List<Id> putAllByReminderIdSync(List<IsarReminder> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'reminderId', objects, saveLinks: saveLinks);
  }
}

extension IsarReminderQueryWhereSort
    on QueryBuilder<IsarReminder, IsarReminder, QWhere> {
  QueryBuilder<IsarReminder, IsarReminder, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhere> anyUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAtMs'),
      );
    });
  }
}

extension IsarReminderQueryWhere
    on QueryBuilder<IsarReminder, IsarReminder, QWhereClause> {
  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause> reminderIdEqualTo(
      String reminderId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'reminderId',
        value: [reminderId],
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause>
      reminderIdNotEqualTo(String reminderId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'reminderId',
              lower: [],
              upper: [reminderId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'reminderId',
              lower: [reminderId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'reminderId',
              lower: [reminderId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'reminderId',
              lower: [],
              upper: [reminderId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause> taskIdEqualTo(
      String taskId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'taskId',
        value: [taskId],
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause> taskIdNotEqualTo(
      String taskId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taskId',
              lower: [],
              upper: [taskId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taskId',
              lower: [taskId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taskId',
              lower: [taskId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taskId',
              lower: [],
              upper: [taskId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause>
      updatedAtMsEqualTo(int updatedAtMs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAtMs',
        value: [updatedAtMs],
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause>
      updatedAtMsNotEqualTo(int updatedAtMs) {
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause>
      updatedAtMsGreaterThan(
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause>
      updatedAtMsLessThan(
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterWhereClause>
      updatedAtMsBetween(
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

extension IsarReminderQueryFilter
    on QueryBuilder<IsarReminder, IsarReminder, QFilterCondition> {
  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      blockUrgencyScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockUrgencyScore',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      blockUrgencyScoreGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blockUrgencyScore',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      blockUrgencyScoreLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blockUrgencyScore',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      blockUrgencyScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blockUrgencyScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      createdAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      createdAtMsGreaterThan(
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      createdAtMsLessThan(
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      createdAtMsBetween(
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      emergencyBypassEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emergencyBypass',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      enabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enabled',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      escalationLevelEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'escalationLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      escalationLevelGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'escalationLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      escalationLevelLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'escalationLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      escalationLevelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'escalationLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      lastTriggeredAtMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastTriggeredAtMs',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      lastTriggeredAtMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastTriggeredAtMs',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      lastTriggeredAtMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastTriggeredAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      lastTriggeredAtMsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastTriggeredAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      lastTriggeredAtMsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastTriggeredAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      lastTriggeredAtMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastTriggeredAtMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'modeRefId',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'modeRefId',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modeRefId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modeRefId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modeRefId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modeRefId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      modeRefIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modeRefId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nextPromptAtIso',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nextPromptAtIso',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextPromptAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextPromptAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextPromptAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextPromptAtIso',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nextPromptAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nextPromptAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nextPromptAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nextPromptAtIso',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextPromptAtIso',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      nextPromptAtIsoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nextPromptAtIso',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      pendingActionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingAction',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      reminderIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reminderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      reminderIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reminderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      reminderIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reminderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      reminderIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reminderId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      reminderIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reminderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      reminderIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reminderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      reminderIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reminderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      reminderIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reminderId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      reminderIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reminderId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      reminderIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reminderId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scheduledAtIso',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scheduledAtIso',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledAtIso',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scheduledAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scheduledAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scheduledAtIso',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scheduledAtIso',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledAtIso',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      scheduledAtIsoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scheduledAtIso',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition> taskIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition> taskIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taskId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'taskId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition> taskIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'taskId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'taskId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'taskTitle',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'taskTitle',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taskTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taskTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taskTitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'taskTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'taskTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'taskTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'taskTitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      taskTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'taskTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      updatedAtMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAtMs',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      updatedAtMsGreaterThan(
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      updatedAtMsLessThan(
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

  QueryBuilder<IsarReminder, IsarReminder, QAfterFilterCondition>
      updatedAtMsBetween(
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

extension IsarReminderQueryObject
    on QueryBuilder<IsarReminder, IsarReminder, QFilterCondition> {}

extension IsarReminderQueryLinks
    on QueryBuilder<IsarReminder, IsarReminder, QFilterCondition> {}

extension IsarReminderQuerySortBy
    on QueryBuilder<IsarReminder, IsarReminder, QSortBy> {
  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByBlockUrgencyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockUrgencyScore', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByBlockUrgencyScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockUrgencyScore', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByEmergencyBypass() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emergencyBypass', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByEmergencyBypassDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emergencyBypass', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByEscalationLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'escalationLevel', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByEscalationLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'escalationLevel', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByLastTriggeredAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTriggeredAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByLastTriggeredAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTriggeredAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByModeRefId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByModeRefIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByNextPromptAtIso() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextPromptAtIso', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByNextPromptAtIsoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextPromptAtIso', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByPendingAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAction', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByPendingActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAction', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByReminderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByReminderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByScheduledAtIso() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAtIso', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByScheduledAtIsoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAtIso', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByTaskTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByTaskTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> sortByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      sortByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarReminderQuerySortThenBy
    on QueryBuilder<IsarReminder, IsarReminder, QSortThenBy> {
  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByBlockUrgencyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockUrgencyScore', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByBlockUrgencyScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockUrgencyScore', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByCreatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByEmergencyBypass() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emergencyBypass', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByEmergencyBypassDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emergencyBypass', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByEscalationLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'escalationLevel', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByEscalationLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'escalationLevel', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByLastTriggeredAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTriggeredAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByLastTriggeredAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTriggeredAtMs', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByModeRefId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByModeRefIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modeRefId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByNextPromptAtIso() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextPromptAtIso', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByNextPromptAtIsoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextPromptAtIso', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByPendingAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAction', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByPendingActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingAction', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByReminderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByReminderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reminderId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByScheduledAtIso() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAtIso', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByScheduledAtIsoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAtIso', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByTaskTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByTaskTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy> thenByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.asc);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QAfterSortBy>
      thenByUpdatedAtMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMs', Sort.desc);
    });
  }
}

extension IsarReminderQueryWhereDistinct
    on QueryBuilder<IsarReminder, IsarReminder, QDistinct> {
  QueryBuilder<IsarReminder, IsarReminder, QDistinct>
      distinctByBlockUrgencyScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockUrgencyScore');
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct> distinctByCreatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMs');
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct>
      distinctByEmergencyBypass() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'emergencyBypass');
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct> distinctByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enabled');
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct>
      distinctByEscalationLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'escalationLevel');
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct>
      distinctByLastTriggeredAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastTriggeredAtMs');
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct> distinctByModeRefId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modeRefId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct> distinctByNextPromptAtIso(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextPromptAtIso',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct>
      distinctByPendingAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingAction');
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct> distinctByReminderId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reminderId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct> distinctByScheduledAtIso(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledAtIso',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct> distinctByTaskId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taskId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct> distinctByTaskTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taskTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarReminder, IsarReminder, QDistinct> distinctByUpdatedAtMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMs');
    });
  }
}

extension IsarReminderQueryProperty
    on QueryBuilder<IsarReminder, IsarReminder, QQueryProperty> {
  QueryBuilder<IsarReminder, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarReminder, int, QQueryOperations>
      blockUrgencyScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockUrgencyScore');
    });
  }

  QueryBuilder<IsarReminder, int, QQueryOperations> createdAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMs');
    });
  }

  QueryBuilder<IsarReminder, bool, QQueryOperations> emergencyBypassProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'emergencyBypass');
    });
  }

  QueryBuilder<IsarReminder, bool, QQueryOperations> enabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enabled');
    });
  }

  QueryBuilder<IsarReminder, int, QQueryOperations> escalationLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'escalationLevel');
    });
  }

  QueryBuilder<IsarReminder, int?, QQueryOperations>
      lastTriggeredAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastTriggeredAtMs');
    });
  }

  QueryBuilder<IsarReminder, String?, QQueryOperations> modeRefIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modeRefId');
    });
  }

  QueryBuilder<IsarReminder, String?, QQueryOperations>
      nextPromptAtIsoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextPromptAtIso');
    });
  }

  QueryBuilder<IsarReminder, bool, QQueryOperations> pendingActionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingAction');
    });
  }

  QueryBuilder<IsarReminder, String, QQueryOperations> reminderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderId');
    });
  }

  QueryBuilder<IsarReminder, String?, QQueryOperations>
      scheduledAtIsoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledAtIso');
    });
  }

  QueryBuilder<IsarReminder, String, QQueryOperations> taskIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taskId');
    });
  }

  QueryBuilder<IsarReminder, String?, QQueryOperations> taskTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taskTitle');
    });
  }

  QueryBuilder<IsarReminder, int, QQueryOperations> updatedAtMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMs');
    });
  }
}
