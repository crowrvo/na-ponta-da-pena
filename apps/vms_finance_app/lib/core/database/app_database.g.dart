// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalFinanceEntriesTable extends LocalFinanceEntries
    with TableInfo<$LocalFinanceEntriesTable, LocalFinanceEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFinanceEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<int> direction = GeneratedColumn<int>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountInCentsMeta = const VerificationMeta(
    'amountInCents',
  );
  @override
  late final GeneratedColumn<int> amountInCents = GeneratedColumn<int>(
    'amount_in_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 240,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    direction,
    amountInCents,
    description,
    occurredAt,
    updatedAt,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_finance_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalFinanceEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('amount_in_cents')) {
      context.handle(
        _amountInCentsMeta,
        amountInCents.isAcceptableOrUnknown(
          data['amount_in_cents']!,
          _amountInCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountInCentsMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalFinanceEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFinanceEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction'],
      )!,
      amountInCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_in_cents'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
    );
  }

  @override
  $LocalFinanceEntriesTable createAlias(String alias) {
    return $LocalFinanceEntriesTable(attachedDatabase, alias);
  }
}

class LocalFinanceEntry extends DataClass
    implements Insertable<LocalFinanceEntry> {
  final String id;
  final String householdId;
  final int direction;
  final int amountInCents;
  final String description;
  final DateTime occurredAt;
  final DateTime updatedAt;
  final String syncState;
  const LocalFinanceEntry({
    required this.id,
    required this.householdId,
    required this.direction,
    required this.amountInCents,
    required this.description,
    required this.occurredAt,
    required this.updatedAt,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['direction'] = Variable<int>(direction);
    map['amount_in_cents'] = Variable<int>(amountInCents);
    map['description'] = Variable<String>(description);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  LocalFinanceEntriesCompanion toCompanion(bool nullToAbsent) {
    return LocalFinanceEntriesCompanion(
      id: Value(id),
      householdId: Value(householdId),
      direction: Value(direction),
      amountInCents: Value(amountInCents),
      description: Value(description),
      occurredAt: Value(occurredAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
    );
  }

  factory LocalFinanceEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFinanceEntry(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      direction: serializer.fromJson<int>(json['direction']),
      amountInCents: serializer.fromJson<int>(json['amountInCents']),
      description: serializer.fromJson<String>(json['description']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'direction': serializer.toJson<int>(direction),
      'amountInCents': serializer.toJson<int>(amountInCents),
      'description': serializer.toJson<String>(description),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  LocalFinanceEntry copyWith({
    String? id,
    String? householdId,
    int? direction,
    int? amountInCents,
    String? description,
    DateTime? occurredAt,
    DateTime? updatedAt,
    String? syncState,
  }) => LocalFinanceEntry(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    direction: direction ?? this.direction,
    amountInCents: amountInCents ?? this.amountInCents,
    description: description ?? this.description,
    occurredAt: occurredAt ?? this.occurredAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
  );
  LocalFinanceEntry copyWithCompanion(LocalFinanceEntriesCompanion data) {
    return LocalFinanceEntry(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      direction: data.direction.present ? data.direction.value : this.direction,
      amountInCents: data.amountInCents.present
          ? data.amountInCents.value
          : this.amountInCents,
      description: data.description.present
          ? data.description.value
          : this.description,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFinanceEntry(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('direction: $direction, ')
          ..write('amountInCents: $amountInCents, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    householdId,
    direction,
    amountInCents,
    description,
    occurredAt,
    updatedAt,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFinanceEntry &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.direction == this.direction &&
          other.amountInCents == this.amountInCents &&
          other.description == this.description &&
          other.occurredAt == this.occurredAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState);
}

class LocalFinanceEntriesCompanion extends UpdateCompanion<LocalFinanceEntry> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<int> direction;
  final Value<int> amountInCents;
  final Value<String> description;
  final Value<DateTime> occurredAt;
  final Value<DateTime> updatedAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const LocalFinanceEntriesCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.direction = const Value.absent(),
    this.amountInCents = const Value.absent(),
    this.description = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFinanceEntriesCompanion.insert({
    required String id,
    required String householdId,
    required int direction,
    required int amountInCents,
    required String description,
    required DateTime occurredAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       direction = Value(direction),
       amountInCents = Value(amountInCents),
       description = Value(description),
       occurredAt = Value(occurredAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalFinanceEntry> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<int>? direction,
    Expression<int>? amountInCents,
    Expression<String>? description,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (direction != null) 'direction': direction,
      if (amountInCents != null) 'amount_in_cents': amountInCents,
      if (description != null) 'description': description,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFinanceEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<int>? direction,
    Value<int>? amountInCents,
    Value<String>? description,
    Value<DateTime>? occurredAt,
    Value<DateTime>? updatedAt,
    Value<String>? syncState,
    Value<int>? rowid,
  }) {
    return LocalFinanceEntriesCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      direction: direction ?? this.direction,
      amountInCents: amountInCents ?? this.amountInCents,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<int>(direction.value);
    }
    if (amountInCents.present) {
      map['amount_in_cents'] = Variable<int>(amountInCents.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFinanceEntriesCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('direction: $direction, ')
          ..write('amountInCents: $amountInCents, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    entityId,
    operation,
    payload,
    createdAt,
    attemptCount,
    nextAttemptAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  SyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxData(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }
}

class SyncOutboxData extends DataClass implements Insertable<SyncOutboxData> {
  final String operationId;
  final String entityId;
  final String operation;
  final String payload;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final String? lastError;
  const SyncOutboxData({
    required this.operationId,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.attemptCount,
    this.nextAttemptAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      operationId: Value(operationId),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      createdAt: Value(createdAt),
      attemptCount: Value(attemptCount),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxData(
      operationId: serializer.fromJson<String>(json['operationId']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncOutboxData copyWith({
    String? operationId,
    String? entityId,
    String? operation,
    String? payload,
    DateTime? createdAt,
    int? attemptCount,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncOutboxData(
    operationId: operationId ?? this.operationId,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    attemptCount: attemptCount ?? this.attemptCount,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncOutboxData copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxData(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxData(')
          ..write('operationId: $operationId, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    entityId,
    operation,
    payload,
    createdAt,
    attemptCount,
    nextAttemptAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxData &&
          other.operationId == this.operationId &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.attemptCount == this.attemptCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxData> {
  final Value<String> operationId;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> attemptCount;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncOutboxCompanion({
    this.operationId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    required String operationId,
    required String entityId,
    required String operation,
    required String payload,
    required DateTime createdAt,
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       entityId = Value(entityId),
       operation = Value(operation),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncOutboxData> custom({
    Expression<String>? operationId,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<String>? operationId,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? attemptCount,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncOutboxCompanion(
      operationId: operationId ?? this.operationId,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('operationId: $operationId, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedHouseholdsTable extends CachedHouseholds
    with TableInfo<$CachedHouseholdsTable, CachedHousehold> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedHouseholdsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refreshedAtMeta = const VerificationMeta(
    'refreshedAt',
  );
  @override
  late final GeneratedColumn<DateTime> refreshedAt = GeneratedColumn<DateTime>(
    'refreshed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, role, refreshedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_households';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedHousehold> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('refreshed_at')) {
      context.handle(
        _refreshedAtMeta,
        refreshedAt.isAcceptableOrUnknown(
          data['refreshed_at']!,
          _refreshedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refreshedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedHousehold map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedHousehold(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      refreshedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}refreshed_at'],
      )!,
    );
  }

  @override
  $CachedHouseholdsTable createAlias(String alias) {
    return $CachedHouseholdsTable(attachedDatabase, alias);
  }
}

class CachedHousehold extends DataClass implements Insertable<CachedHousehold> {
  final String id;
  final String name;
  final String role;
  final DateTime refreshedAt;
  const CachedHousehold({
    required this.id,
    required this.name,
    required this.role,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['refreshed_at'] = Variable<DateTime>(refreshedAt);
    return map;
  }

  CachedHouseholdsCompanion toCompanion(bool nullToAbsent) {
    return CachedHouseholdsCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory CachedHousehold.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedHousehold(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  CachedHousehold copyWith({
    String? id,
    String? name,
    String? role,
    DateTime? refreshedAt,
  }) => CachedHousehold(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  CachedHousehold copyWithCompanion(CachedHouseholdsCompanion data) {
    return CachedHousehold(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedHousehold(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, role, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedHousehold &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.refreshedAt == this.refreshedAt);
}

class CachedHouseholdsCompanion extends UpdateCompanion<CachedHousehold> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> role;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const CachedHouseholdsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedHouseholdsCompanion.insert({
    required String id,
    required String name,
    required String role,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       role = Value(role),
       refreshedAt = Value(refreshedAt);
  static Insertable<CachedHousehold> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<DateTime>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedHouseholdsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? role,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return CachedHouseholdsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<DateTime>(refreshedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedHouseholdsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HouseholdPreferencesTable extends HouseholdPreferences
    with TableInfo<$HouseholdPreferencesTable, HouseholdPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _activeHouseholdIdMeta = const VerificationMeta(
    'activeHouseholdId',
  );
  @override
  late final GeneratedColumn<String> activeHouseholdId =
      GeneratedColumn<String>(
        'active_household_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [id, activeHouseholdId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'household_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<HouseholdPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('active_household_id')) {
      context.handle(
        _activeHouseholdIdMeta,
        activeHouseholdId.isAcceptableOrUnknown(
          data['active_household_id']!,
          _activeHouseholdIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HouseholdPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HouseholdPreference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activeHouseholdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_household_id'],
      ),
    );
  }

  @override
  $HouseholdPreferencesTable createAlias(String alias) {
    return $HouseholdPreferencesTable(attachedDatabase, alias);
  }
}

class HouseholdPreference extends DataClass
    implements Insertable<HouseholdPreference> {
  final int id;
  final String? activeHouseholdId;
  const HouseholdPreference({required this.id, this.activeHouseholdId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || activeHouseholdId != null) {
      map['active_household_id'] = Variable<String>(activeHouseholdId);
    }
    return map;
  }

  HouseholdPreferencesCompanion toCompanion(bool nullToAbsent) {
    return HouseholdPreferencesCompanion(
      id: Value(id),
      activeHouseholdId: activeHouseholdId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeHouseholdId),
    );
  }

  factory HouseholdPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HouseholdPreference(
      id: serializer.fromJson<int>(json['id']),
      activeHouseholdId: serializer.fromJson<String?>(
        json['activeHouseholdId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activeHouseholdId': serializer.toJson<String?>(activeHouseholdId),
    };
  }

  HouseholdPreference copyWith({
    int? id,
    Value<String?> activeHouseholdId = const Value.absent(),
  }) => HouseholdPreference(
    id: id ?? this.id,
    activeHouseholdId: activeHouseholdId.present
        ? activeHouseholdId.value
        : this.activeHouseholdId,
  );
  HouseholdPreference copyWithCompanion(HouseholdPreferencesCompanion data) {
    return HouseholdPreference(
      id: data.id.present ? data.id.value : this.id,
      activeHouseholdId: data.activeHouseholdId.present
          ? data.activeHouseholdId.value
          : this.activeHouseholdId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdPreference(')
          ..write('id: $id, ')
          ..write('activeHouseholdId: $activeHouseholdId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, activeHouseholdId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HouseholdPreference &&
          other.id == this.id &&
          other.activeHouseholdId == this.activeHouseholdId);
}

class HouseholdPreferencesCompanion
    extends UpdateCompanion<HouseholdPreference> {
  final Value<int> id;
  final Value<String?> activeHouseholdId;
  const HouseholdPreferencesCompanion({
    this.id = const Value.absent(),
    this.activeHouseholdId = const Value.absent(),
  });
  HouseholdPreferencesCompanion.insert({
    this.id = const Value.absent(),
    this.activeHouseholdId = const Value.absent(),
  });
  static Insertable<HouseholdPreference> custom({
    Expression<int>? id,
    Expression<String>? activeHouseholdId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activeHouseholdId != null) 'active_household_id': activeHouseholdId,
    });
  }

  HouseholdPreferencesCompanion copyWith({
    Value<int>? id,
    Value<String?>? activeHouseholdId,
  }) {
    return HouseholdPreferencesCompanion(
      id: id ?? this.id,
      activeHouseholdId: activeHouseholdId ?? this.activeHouseholdId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activeHouseholdId.present) {
      map['active_household_id'] = Variable<String>(activeHouseholdId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('activeHouseholdId: $activeHouseholdId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalFinanceEntriesTable localFinanceEntries =
      $LocalFinanceEntriesTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final $CachedHouseholdsTable cachedHouseholds = $CachedHouseholdsTable(
    this,
  );
  late final $HouseholdPreferencesTable householdPreferences =
      $HouseholdPreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localFinanceEntries,
    syncOutbox,
    cachedHouseholds,
    householdPreferences,
  ];
}

typedef $$LocalFinanceEntriesTableCreateCompanionBuilder =
    LocalFinanceEntriesCompanion Function({
      required String id,
      required String householdId,
      required int direction,
      required int amountInCents,
      required String description,
      required DateTime occurredAt,
      required DateTime updatedAt,
      Value<String> syncState,
      Value<int> rowid,
    });
typedef $$LocalFinanceEntriesTableUpdateCompanionBuilder =
    LocalFinanceEntriesCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<int> direction,
      Value<int> amountInCents,
      Value<String> description,
      Value<DateTime> occurredAt,
      Value<DateTime> updatedAt,
      Value<String> syncState,
      Value<int> rowid,
    });

class $$LocalFinanceEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFinanceEntriesTable> {
  $$LocalFinanceEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountInCents => $composableBuilder(
    column: $table.amountInCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalFinanceEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFinanceEntriesTable> {
  $$LocalFinanceEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountInCents => $composableBuilder(
    column: $table.amountInCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalFinanceEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFinanceEntriesTable> {
  $$LocalFinanceEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get amountInCents => $composableBuilder(
    column: $table.amountInCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$LocalFinanceEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalFinanceEntriesTable,
          LocalFinanceEntry,
          $$LocalFinanceEntriesTableFilterComposer,
          $$LocalFinanceEntriesTableOrderingComposer,
          $$LocalFinanceEntriesTableAnnotationComposer,
          $$LocalFinanceEntriesTableCreateCompanionBuilder,
          $$LocalFinanceEntriesTableUpdateCompanionBuilder,
          (
            LocalFinanceEntry,
            BaseReferences<
              _$AppDatabase,
              $LocalFinanceEntriesTable,
              LocalFinanceEntry
            >,
          ),
          LocalFinanceEntry,
          PrefetchHooks Function()
        > {
  $$LocalFinanceEntriesTableTableManager(
    _$AppDatabase db,
    $LocalFinanceEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFinanceEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFinanceEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalFinanceEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<int> direction = const Value.absent(),
                Value<int> amountInCents = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFinanceEntriesCompanion(
                id: id,
                householdId: householdId,
                direction: direction,
                amountInCents: amountInCents,
                description: description,
                occurredAt: occurredAt,
                updatedAt: updatedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required int direction,
                required int amountInCents,
                required String description,
                required DateTime occurredAt,
                required DateTime updatedAt,
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalFinanceEntriesCompanion.insert(
                id: id,
                householdId: householdId,
                direction: direction,
                amountInCents: amountInCents,
                description: description,
                occurredAt: occurredAt,
                updatedAt: updatedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalFinanceEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalFinanceEntriesTable,
      LocalFinanceEntry,
      $$LocalFinanceEntriesTableFilterComposer,
      $$LocalFinanceEntriesTableOrderingComposer,
      $$LocalFinanceEntriesTableAnnotationComposer,
      $$LocalFinanceEntriesTableCreateCompanionBuilder,
      $$LocalFinanceEntriesTableUpdateCompanionBuilder,
      (
        LocalFinanceEntry,
        BaseReferences<
          _$AppDatabase,
          $LocalFinanceEntriesTable,
          LocalFinanceEntry
        >,
      ),
      LocalFinanceEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder =
    SyncOutboxCompanion Function({
      required String operationId,
      required String entityId,
      required String operation,
      required String payload,
      required DateTime createdAt,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncOutboxTableUpdateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<String> operationId,
      Value<String> entityId,
      Value<String> operation,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxTable,
          SyncOutboxData,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (
            SyncOutboxData,
            BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>,
          ),
          SyncOutboxData,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableManager(_$AppDatabase db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion(
                operationId: operationId,
                entityId: entityId,
                operation: operation,
                payload: payload,
                createdAt: createdAt,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String entityId,
                required String operation,
                required String payload,
                required DateTime createdAt,
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                operationId: operationId,
                entityId: entityId,
                operation: operation,
                payload: payload,
                createdAt: createdAt,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxTable,
      SyncOutboxData,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (
        SyncOutboxData,
        BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>,
      ),
      SyncOutboxData,
      PrefetchHooks Function()
    >;
typedef $$CachedHouseholdsTableCreateCompanionBuilder =
    CachedHouseholdsCompanion Function({
      required String id,
      required String name,
      required String role,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$CachedHouseholdsTableUpdateCompanionBuilder =
    CachedHouseholdsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> role,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$CachedHouseholdsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedHouseholdsTable> {
  $$CachedHouseholdsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedHouseholdsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedHouseholdsTable> {
  $$CachedHouseholdsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedHouseholdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedHouseholdsTable> {
  $$CachedHouseholdsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => column,
  );
}

class $$CachedHouseholdsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedHouseholdsTable,
          CachedHousehold,
          $$CachedHouseholdsTableFilterComposer,
          $$CachedHouseholdsTableOrderingComposer,
          $$CachedHouseholdsTableAnnotationComposer,
          $$CachedHouseholdsTableCreateCompanionBuilder,
          $$CachedHouseholdsTableUpdateCompanionBuilder,
          (
            CachedHousehold,
            BaseReferences<
              _$AppDatabase,
              $CachedHouseholdsTable,
              CachedHousehold
            >,
          ),
          CachedHousehold,
          PrefetchHooks Function()
        > {
  $$CachedHouseholdsTableTableManager(
    _$AppDatabase db,
    $CachedHouseholdsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedHouseholdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedHouseholdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedHouseholdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedHouseholdsCompanion(
                id: id,
                name: name,
                role: role,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String role,
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedHouseholdsCompanion.insert(
                id: id,
                name: name,
                role: role,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedHouseholdsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedHouseholdsTable,
      CachedHousehold,
      $$CachedHouseholdsTableFilterComposer,
      $$CachedHouseholdsTableOrderingComposer,
      $$CachedHouseholdsTableAnnotationComposer,
      $$CachedHouseholdsTableCreateCompanionBuilder,
      $$CachedHouseholdsTableUpdateCompanionBuilder,
      (
        CachedHousehold,
        BaseReferences<_$AppDatabase, $CachedHouseholdsTable, CachedHousehold>,
      ),
      CachedHousehold,
      PrefetchHooks Function()
    >;
typedef $$HouseholdPreferencesTableCreateCompanionBuilder =
    HouseholdPreferencesCompanion Function({
      Value<int> id,
      Value<String?> activeHouseholdId,
    });
typedef $$HouseholdPreferencesTableUpdateCompanionBuilder =
    HouseholdPreferencesCompanion Function({
      Value<int> id,
      Value<String?> activeHouseholdId,
    });

class $$HouseholdPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdPreferencesTable> {
  $$HouseholdPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeHouseholdId => $composableBuilder(
    column: $table.activeHouseholdId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HouseholdPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdPreferencesTable> {
  $$HouseholdPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeHouseholdId => $composableBuilder(
    column: $table.activeHouseholdId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HouseholdPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdPreferencesTable> {
  $$HouseholdPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activeHouseholdId => $composableBuilder(
    column: $table.activeHouseholdId,
    builder: (column) => column,
  );
}

class $$HouseholdPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HouseholdPreferencesTable,
          HouseholdPreference,
          $$HouseholdPreferencesTableFilterComposer,
          $$HouseholdPreferencesTableOrderingComposer,
          $$HouseholdPreferencesTableAnnotationComposer,
          $$HouseholdPreferencesTableCreateCompanionBuilder,
          $$HouseholdPreferencesTableUpdateCompanionBuilder,
          (
            HouseholdPreference,
            BaseReferences<
              _$AppDatabase,
              $HouseholdPreferencesTable,
              HouseholdPreference
            >,
          ),
          HouseholdPreference,
          PrefetchHooks Function()
        > {
  $$HouseholdPreferencesTableTableManager(
    _$AppDatabase db,
    $HouseholdPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdPreferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$HouseholdPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> activeHouseholdId = const Value.absent(),
              }) => HouseholdPreferencesCompanion(
                id: id,
                activeHouseholdId: activeHouseholdId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> activeHouseholdId = const Value.absent(),
              }) => HouseholdPreferencesCompanion.insert(
                id: id,
                activeHouseholdId: activeHouseholdId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HouseholdPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HouseholdPreferencesTable,
      HouseholdPreference,
      $$HouseholdPreferencesTableFilterComposer,
      $$HouseholdPreferencesTableOrderingComposer,
      $$HouseholdPreferencesTableAnnotationComposer,
      $$HouseholdPreferencesTableCreateCompanionBuilder,
      $$HouseholdPreferencesTableUpdateCompanionBuilder,
      (
        HouseholdPreference,
        BaseReferences<
          _$AppDatabase,
          $HouseholdPreferencesTable,
          HouseholdPreference
        >,
      ),
      HouseholdPreference,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalFinanceEntriesTableTableManager get localFinanceEntries =>
      $$LocalFinanceEntriesTableTableManager(_db, _db.localFinanceEntries);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  $$CachedHouseholdsTableTableManager get cachedHouseholds =>
      $$CachedHouseholdsTableTableManager(_db, _db.cachedHouseholds);
  $$HouseholdPreferencesTableTableManager get householdPreferences =>
      $$HouseholdPreferencesTableTableManager(_db, _db.householdPreferences);
}
