// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BatchesTable extends Batches with TableInfo<$BatchesTable, BatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _fruitTypeMeta = const VerificationMeta(
    'fruitType',
  );
  @override
  late final GeneratedColumn<String> fruitType = GeneratedColumn<String>(
    'fruit_type',
    aliasedName,
    false,
    check: () => fruitType.isIn(PersistenceCodecs.fruitCodes),
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    check: () => syncState.isIn(PersistenceCodecs.syncStateCodes),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_only'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    name,
    fruitType,
    createdAt,
    updatedAt,
    deletedAt,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('fruit_type')) {
      context.handle(
        _fruitTypeMeta,
        fruitType.isAcceptableOrUnknown(data['fruit_type']!, _fruitTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fruitTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
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
  BatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fruitType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fruit_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
    );
  }

  @override
  $BatchesTable createAlias(String alias) {
    return $BatchesTable(attachedDatabase, alias);
  }
}

class BatchRow extends DataClass implements Insertable<BatchRow> {
  final String id;
  final String? ownerId;
  final String name;
  final String fruitType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncState;
  const BatchRow({
    required this.id,
    this.ownerId,
    required this.name,
    required this.fruitType,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    map['name'] = Variable<String>(name);
    map['fruit_type'] = Variable<String>(fruitType);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  BatchesCompanion toCompanion(bool nullToAbsent) {
    return BatchesCompanion(
      id: Value(id),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      name: Value(name),
      fruitType: Value(fruitType),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncState: Value(syncState),
    );
  }

  factory BatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      name: serializer.fromJson<String>(json['name']),
      fruitType: serializer.fromJson<String>(json['fruitType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String?>(ownerId),
      'name': serializer.toJson<String>(name),
      'fruitType': serializer.toJson<String>(fruitType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  BatchRow copyWith({
    String? id,
    Value<String?> ownerId = const Value.absent(),
    String? name,
    String? fruitType,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncState,
  }) => BatchRow(
    id: id ?? this.id,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    name: name ?? this.name,
    fruitType: fruitType ?? this.fruitType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncState: syncState ?? this.syncState,
  );
  BatchRow copyWithCompanion(BatchesCompanion data) {
    return BatchRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      name: data.name.present ? data.name.value : this.name,
      fruitType: data.fruitType.present ? data.fruitType.value : this.fruitType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('fruitType: $fruitType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    name,
    fruitType,
    createdAt,
    updatedAt,
    deletedAt,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.fruitType == this.fruitType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncState == this.syncState);
}

class BatchesCompanion extends UpdateCompanion<BatchRow> {
  final Value<String> id;
  final Value<String?> ownerId;
  final Value<String> name;
  final Value<String> fruitType;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const BatchesCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.fruitType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BatchesCompanion.insert({
    required String id,
    this.ownerId = const Value.absent(),
    required String name,
    required String fruitType,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       fruitType = Value(fruitType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BatchRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<String>? fruitType,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (fruitType != null) 'fruit_type': fruitType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BatchesCompanion copyWith({
    Value<String>? id,
    Value<String?>? ownerId,
    Value<String>? name,
    Value<String>? fruitType,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncState,
    Value<int>? rowid,
  }) {
    return BatchesCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      fruitType: fruitType ?? this.fruitType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fruitType.present) {
      map['fruit_type'] = Variable<String>(fruitType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
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
    return (StringBuffer('BatchesCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('fruitType: $fruitType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScanRecordsTable extends ScanRecords
    with TableInfo<$ScanRecordsTable, ScanRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES batches (id) ON DELETE NO ACTION',
    ),
  );
  static const VerificationMeta _fruitTypeMeta = const VerificationMeta(
    'fruitType',
  );
  @override
  late final GeneratedColumn<String> fruitType = GeneratedColumn<String>(
    'fruit_type',
    aliasedName,
    false,
    check: () => fruitType.isIn(PersistenceCodecs.fruitCodes),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ripenessStageMeta = const VerificationMeta(
    'ripenessStage',
  );
  @override
  late final GeneratedColumn<String> ripenessStage = GeneratedColumn<String>(
    'ripeness_stage',
    aliasedName,
    false,
    check: () => ripenessStage.isIn(PersistenceCodecs.ripenessCodes),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelConfidenceMeta = const VerificationMeta(
    'modelConfidence',
  );
  @override
  late final GeneratedColumn<double> modelConfidence = GeneratedColumn<double>(
    'model_confidence',
    aliasedName,
    false,
    check: () => ComparableExpr(modelConfidence).isBetweenValues(0, 1),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultOriginMeta = const VerificationMeta(
    'resultOrigin',
  );
  @override
  late final GeneratedColumn<String> resultOrigin = GeneratedColumn<String>(
    'result_origin',
    aliasedName,
    false,
    check: () => resultOrigin.isIn(PersistenceCodecs.resultOriginCodes),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('demo'),
  );
  static const VerificationMeta _shelfLifeStatusMeta = const VerificationMeta(
    'shelfLifeStatus',
  );
  @override
  late final GeneratedColumn<String> shelfLifeStatus = GeneratedColumn<String>(
    'shelf_life_status',
    aliasedName,
    false,
    check: () => shelfLifeStatus.isIn(const {
      PersistenceCodecs.shelfLifeAvailable,
      PersistenceCodecs.shelfLifeUnavailable,
    }),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shelfLifeMinimumMeta = const VerificationMeta(
    'shelfLifeMinimum',
  );
  @override
  late final GeneratedColumn<int> shelfLifeMinimum = GeneratedColumn<int>(
    'shelf_life_minimum',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shelfLifeMaximumMeta = const VerificationMeta(
    'shelfLifeMaximum',
  );
  @override
  late final GeneratedColumn<int> shelfLifeMaximum = GeneratedColumn<int>(
    'shelf_life_maximum',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shelfLifeUnitMeta = const VerificationMeta(
    'shelfLifeUnit',
  );
  @override
  late final GeneratedColumn<String> shelfLifeUnit = GeneratedColumn<String>(
    'shelf_life_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shelfLifeGuidanceMeta = const VerificationMeta(
    'shelfLifeGuidance',
  );
  @override
  late final GeneratedColumn<String> shelfLifeGuidance =
      GeneratedColumn<String>(
        'shelf_life_guidance',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _shelfLifeReasonMeta = const VerificationMeta(
    'shelfLifeReason',
  );
  @override
  late final GeneratedColumn<String> shelfLifeReason = GeneratedColumn<String>(
    'shelf_life_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shelfLifeEvidenceVersionMeta =
      const VerificationMeta('shelfLifeEvidenceVersion');
  @override
  late final GeneratedColumn<String> shelfLifeEvidenceVersion =
      GeneratedColumn<String>(
        'shelf_life_evidence_version',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _localImageRelativePathMeta =
      const VerificationMeta('localImageRelativePath');
  @override
  late final GeneratedColumn<String> localImageRelativePath =
      GeneratedColumn<String>(
        'local_image_relative_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _remoteImageKeyMeta = const VerificationMeta(
    'remoteImageKey',
  );
  @override
  late final GeneratedColumn<String> remoteImageKey = GeneratedColumn<String>(
    'remote_image_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    check: () => syncState.isIn(PersistenceCodecs.syncStateCodes),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_only'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    batchId,
    fruitType,
    ripenessStage,
    modelConfidence,
    modelVersion,
    resultOrigin,
    shelfLifeStatus,
    shelfLifeMinimum,
    shelfLifeMaximum,
    shelfLifeUnit,
    shelfLifeGuidance,
    shelfLifeReason,
    shelfLifeEvidenceVersion,
    localImageRelativePath,
    remoteImageKey,
    createdAt,
    updatedAt,
    deletedAt,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    if (data.containsKey('fruit_type')) {
      context.handle(
        _fruitTypeMeta,
        fruitType.isAcceptableOrUnknown(data['fruit_type']!, _fruitTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fruitTypeMeta);
    }
    if (data.containsKey('ripeness_stage')) {
      context.handle(
        _ripenessStageMeta,
        ripenessStage.isAcceptableOrUnknown(
          data['ripeness_stage']!,
          _ripenessStageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ripenessStageMeta);
    }
    if (data.containsKey('model_confidence')) {
      context.handle(
        _modelConfidenceMeta,
        modelConfidence.isAcceptableOrUnknown(
          data['model_confidence']!,
          _modelConfidenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelConfidenceMeta);
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelVersionMeta);
    }
    if (data.containsKey('result_origin')) {
      context.handle(
        _resultOriginMeta,
        resultOrigin.isAcceptableOrUnknown(
          data['result_origin']!,
          _resultOriginMeta,
        ),
      );
    }
    if (data.containsKey('shelf_life_status')) {
      context.handle(
        _shelfLifeStatusMeta,
        shelfLifeStatus.isAcceptableOrUnknown(
          data['shelf_life_status']!,
          _shelfLifeStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shelfLifeStatusMeta);
    }
    if (data.containsKey('shelf_life_minimum')) {
      context.handle(
        _shelfLifeMinimumMeta,
        shelfLifeMinimum.isAcceptableOrUnknown(
          data['shelf_life_minimum']!,
          _shelfLifeMinimumMeta,
        ),
      );
    }
    if (data.containsKey('shelf_life_maximum')) {
      context.handle(
        _shelfLifeMaximumMeta,
        shelfLifeMaximum.isAcceptableOrUnknown(
          data['shelf_life_maximum']!,
          _shelfLifeMaximumMeta,
        ),
      );
    }
    if (data.containsKey('shelf_life_unit')) {
      context.handle(
        _shelfLifeUnitMeta,
        shelfLifeUnit.isAcceptableOrUnknown(
          data['shelf_life_unit']!,
          _shelfLifeUnitMeta,
        ),
      );
    }
    if (data.containsKey('shelf_life_guidance')) {
      context.handle(
        _shelfLifeGuidanceMeta,
        shelfLifeGuidance.isAcceptableOrUnknown(
          data['shelf_life_guidance']!,
          _shelfLifeGuidanceMeta,
        ),
      );
    }
    if (data.containsKey('shelf_life_reason')) {
      context.handle(
        _shelfLifeReasonMeta,
        shelfLifeReason.isAcceptableOrUnknown(
          data['shelf_life_reason']!,
          _shelfLifeReasonMeta,
        ),
      );
    }
    if (data.containsKey('shelf_life_evidence_version')) {
      context.handle(
        _shelfLifeEvidenceVersionMeta,
        shelfLifeEvidenceVersion.isAcceptableOrUnknown(
          data['shelf_life_evidence_version']!,
          _shelfLifeEvidenceVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shelfLifeEvidenceVersionMeta);
    }
    if (data.containsKey('local_image_relative_path')) {
      context.handle(
        _localImageRelativePathMeta,
        localImageRelativePath.isAcceptableOrUnknown(
          data['local_image_relative_path']!,
          _localImageRelativePathMeta,
        ),
      );
    }
    if (data.containsKey('remote_image_key')) {
      context.handle(
        _remoteImageKeyMeta,
        remoteImageKey.isAcceptableOrUnknown(
          data['remote_image_key']!,
          _remoteImageKeyMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
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
  ScanRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
      fruitType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fruit_type'],
      )!,
      ripenessStage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ripeness_stage'],
      )!,
      modelConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}model_confidence'],
      )!,
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      )!,
      resultOrigin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_origin'],
      )!,
      shelfLifeStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shelf_life_status'],
      )!,
      shelfLifeMinimum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shelf_life_minimum'],
      ),
      shelfLifeMaximum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shelf_life_maximum'],
      ),
      shelfLifeUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shelf_life_unit'],
      ),
      shelfLifeGuidance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shelf_life_guidance'],
      ),
      shelfLifeReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shelf_life_reason'],
      ),
      shelfLifeEvidenceVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shelf_life_evidence_version'],
      )!,
      localImageRelativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_image_relative_path'],
      ),
      remoteImageKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_image_key'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
    );
  }

  @override
  $ScanRecordsTable createAlias(String alias) {
    return $ScanRecordsTable(attachedDatabase, alias);
  }
}

class ScanRecordRow extends DataClass implements Insertable<ScanRecordRow> {
  final String id;
  final String? ownerId;
  final String? batchId;
  final String fruitType;
  final String ripenessStage;
  final double modelConfidence;
  final String modelVersion;
  final String resultOrigin;
  final String shelfLifeStatus;
  final int? shelfLifeMinimum;
  final int? shelfLifeMaximum;
  final String? shelfLifeUnit;
  final String? shelfLifeGuidance;
  final String? shelfLifeReason;
  final String shelfLifeEvidenceVersion;
  final String? localImageRelativePath;
  final String? remoteImageKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncState;
  const ScanRecordRow({
    required this.id,
    this.ownerId,
    this.batchId,
    required this.fruitType,
    required this.ripenessStage,
    required this.modelConfidence,
    required this.modelVersion,
    required this.resultOrigin,
    required this.shelfLifeStatus,
    this.shelfLifeMinimum,
    this.shelfLifeMaximum,
    this.shelfLifeUnit,
    this.shelfLifeGuidance,
    this.shelfLifeReason,
    required this.shelfLifeEvidenceVersion,
    this.localImageRelativePath,
    this.remoteImageKey,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    map['fruit_type'] = Variable<String>(fruitType);
    map['ripeness_stage'] = Variable<String>(ripenessStage);
    map['model_confidence'] = Variable<double>(modelConfidence);
    map['model_version'] = Variable<String>(modelVersion);
    map['result_origin'] = Variable<String>(resultOrigin);
    map['shelf_life_status'] = Variable<String>(shelfLifeStatus);
    if (!nullToAbsent || shelfLifeMinimum != null) {
      map['shelf_life_minimum'] = Variable<int>(shelfLifeMinimum);
    }
    if (!nullToAbsent || shelfLifeMaximum != null) {
      map['shelf_life_maximum'] = Variable<int>(shelfLifeMaximum);
    }
    if (!nullToAbsent || shelfLifeUnit != null) {
      map['shelf_life_unit'] = Variable<String>(shelfLifeUnit);
    }
    if (!nullToAbsent || shelfLifeGuidance != null) {
      map['shelf_life_guidance'] = Variable<String>(shelfLifeGuidance);
    }
    if (!nullToAbsent || shelfLifeReason != null) {
      map['shelf_life_reason'] = Variable<String>(shelfLifeReason);
    }
    map['shelf_life_evidence_version'] = Variable<String>(
      shelfLifeEvidenceVersion,
    );
    if (!nullToAbsent || localImageRelativePath != null) {
      map['local_image_relative_path'] = Variable<String>(
        localImageRelativePath,
      );
    }
    if (!nullToAbsent || remoteImageKey != null) {
      map['remote_image_key'] = Variable<String>(remoteImageKey);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  ScanRecordsCompanion toCompanion(bool nullToAbsent) {
    return ScanRecordsCompanion(
      id: Value(id),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      fruitType: Value(fruitType),
      ripenessStage: Value(ripenessStage),
      modelConfidence: Value(modelConfidence),
      modelVersion: Value(modelVersion),
      resultOrigin: Value(resultOrigin),
      shelfLifeStatus: Value(shelfLifeStatus),
      shelfLifeMinimum: shelfLifeMinimum == null && nullToAbsent
          ? const Value.absent()
          : Value(shelfLifeMinimum),
      shelfLifeMaximum: shelfLifeMaximum == null && nullToAbsent
          ? const Value.absent()
          : Value(shelfLifeMaximum),
      shelfLifeUnit: shelfLifeUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(shelfLifeUnit),
      shelfLifeGuidance: shelfLifeGuidance == null && nullToAbsent
          ? const Value.absent()
          : Value(shelfLifeGuidance),
      shelfLifeReason: shelfLifeReason == null && nullToAbsent
          ? const Value.absent()
          : Value(shelfLifeReason),
      shelfLifeEvidenceVersion: Value(shelfLifeEvidenceVersion),
      localImageRelativePath: localImageRelativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localImageRelativePath),
      remoteImageKey: remoteImageKey == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteImageKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncState: Value(syncState),
    );
  }

  factory ScanRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanRecordRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      batchId: serializer.fromJson<String?>(json['batchId']),
      fruitType: serializer.fromJson<String>(json['fruitType']),
      ripenessStage: serializer.fromJson<String>(json['ripenessStage']),
      modelConfidence: serializer.fromJson<double>(json['modelConfidence']),
      modelVersion: serializer.fromJson<String>(json['modelVersion']),
      resultOrigin: serializer.fromJson<String>(json['resultOrigin']),
      shelfLifeStatus: serializer.fromJson<String>(json['shelfLifeStatus']),
      shelfLifeMinimum: serializer.fromJson<int?>(json['shelfLifeMinimum']),
      shelfLifeMaximum: serializer.fromJson<int?>(json['shelfLifeMaximum']),
      shelfLifeUnit: serializer.fromJson<String?>(json['shelfLifeUnit']),
      shelfLifeGuidance: serializer.fromJson<String?>(
        json['shelfLifeGuidance'],
      ),
      shelfLifeReason: serializer.fromJson<String?>(json['shelfLifeReason']),
      shelfLifeEvidenceVersion: serializer.fromJson<String>(
        json['shelfLifeEvidenceVersion'],
      ),
      localImageRelativePath: serializer.fromJson<String?>(
        json['localImageRelativePath'],
      ),
      remoteImageKey: serializer.fromJson<String?>(json['remoteImageKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String?>(ownerId),
      'batchId': serializer.toJson<String?>(batchId),
      'fruitType': serializer.toJson<String>(fruitType),
      'ripenessStage': serializer.toJson<String>(ripenessStage),
      'modelConfidence': serializer.toJson<double>(modelConfidence),
      'modelVersion': serializer.toJson<String>(modelVersion),
      'resultOrigin': serializer.toJson<String>(resultOrigin),
      'shelfLifeStatus': serializer.toJson<String>(shelfLifeStatus),
      'shelfLifeMinimum': serializer.toJson<int?>(shelfLifeMinimum),
      'shelfLifeMaximum': serializer.toJson<int?>(shelfLifeMaximum),
      'shelfLifeUnit': serializer.toJson<String?>(shelfLifeUnit),
      'shelfLifeGuidance': serializer.toJson<String?>(shelfLifeGuidance),
      'shelfLifeReason': serializer.toJson<String?>(shelfLifeReason),
      'shelfLifeEvidenceVersion': serializer.toJson<String>(
        shelfLifeEvidenceVersion,
      ),
      'localImageRelativePath': serializer.toJson<String?>(
        localImageRelativePath,
      ),
      'remoteImageKey': serializer.toJson<String?>(remoteImageKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  ScanRecordRow copyWith({
    String? id,
    Value<String?> ownerId = const Value.absent(),
    Value<String?> batchId = const Value.absent(),
    String? fruitType,
    String? ripenessStage,
    double? modelConfidence,
    String? modelVersion,
    String? resultOrigin,
    String? shelfLifeStatus,
    Value<int?> shelfLifeMinimum = const Value.absent(),
    Value<int?> shelfLifeMaximum = const Value.absent(),
    Value<String?> shelfLifeUnit = const Value.absent(),
    Value<String?> shelfLifeGuidance = const Value.absent(),
    Value<String?> shelfLifeReason = const Value.absent(),
    String? shelfLifeEvidenceVersion,
    Value<String?> localImageRelativePath = const Value.absent(),
    Value<String?> remoteImageKey = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncState,
  }) => ScanRecordRow(
    id: id ?? this.id,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    batchId: batchId.present ? batchId.value : this.batchId,
    fruitType: fruitType ?? this.fruitType,
    ripenessStage: ripenessStage ?? this.ripenessStage,
    modelConfidence: modelConfidence ?? this.modelConfidence,
    modelVersion: modelVersion ?? this.modelVersion,
    resultOrigin: resultOrigin ?? this.resultOrigin,
    shelfLifeStatus: shelfLifeStatus ?? this.shelfLifeStatus,
    shelfLifeMinimum: shelfLifeMinimum.present
        ? shelfLifeMinimum.value
        : this.shelfLifeMinimum,
    shelfLifeMaximum: shelfLifeMaximum.present
        ? shelfLifeMaximum.value
        : this.shelfLifeMaximum,
    shelfLifeUnit: shelfLifeUnit.present
        ? shelfLifeUnit.value
        : this.shelfLifeUnit,
    shelfLifeGuidance: shelfLifeGuidance.present
        ? shelfLifeGuidance.value
        : this.shelfLifeGuidance,
    shelfLifeReason: shelfLifeReason.present
        ? shelfLifeReason.value
        : this.shelfLifeReason,
    shelfLifeEvidenceVersion:
        shelfLifeEvidenceVersion ?? this.shelfLifeEvidenceVersion,
    localImageRelativePath: localImageRelativePath.present
        ? localImageRelativePath.value
        : this.localImageRelativePath,
    remoteImageKey: remoteImageKey.present
        ? remoteImageKey.value
        : this.remoteImageKey,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncState: syncState ?? this.syncState,
  );
  ScanRecordRow copyWithCompanion(ScanRecordsCompanion data) {
    return ScanRecordRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      fruitType: data.fruitType.present ? data.fruitType.value : this.fruitType,
      ripenessStage: data.ripenessStage.present
          ? data.ripenessStage.value
          : this.ripenessStage,
      modelConfidence: data.modelConfidence.present
          ? data.modelConfidence.value
          : this.modelConfidence,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      resultOrigin: data.resultOrigin.present
          ? data.resultOrigin.value
          : this.resultOrigin,
      shelfLifeStatus: data.shelfLifeStatus.present
          ? data.shelfLifeStatus.value
          : this.shelfLifeStatus,
      shelfLifeMinimum: data.shelfLifeMinimum.present
          ? data.shelfLifeMinimum.value
          : this.shelfLifeMinimum,
      shelfLifeMaximum: data.shelfLifeMaximum.present
          ? data.shelfLifeMaximum.value
          : this.shelfLifeMaximum,
      shelfLifeUnit: data.shelfLifeUnit.present
          ? data.shelfLifeUnit.value
          : this.shelfLifeUnit,
      shelfLifeGuidance: data.shelfLifeGuidance.present
          ? data.shelfLifeGuidance.value
          : this.shelfLifeGuidance,
      shelfLifeReason: data.shelfLifeReason.present
          ? data.shelfLifeReason.value
          : this.shelfLifeReason,
      shelfLifeEvidenceVersion: data.shelfLifeEvidenceVersion.present
          ? data.shelfLifeEvidenceVersion.value
          : this.shelfLifeEvidenceVersion,
      localImageRelativePath: data.localImageRelativePath.present
          ? data.localImageRelativePath.value
          : this.localImageRelativePath,
      remoteImageKey: data.remoteImageKey.present
          ? data.remoteImageKey.value
          : this.remoteImageKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanRecordRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('batchId: $batchId, ')
          ..write('fruitType: $fruitType, ')
          ..write('ripenessStage: $ripenessStage, ')
          ..write('modelConfidence: $modelConfidence, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('resultOrigin: $resultOrigin, ')
          ..write('shelfLifeStatus: $shelfLifeStatus, ')
          ..write('shelfLifeMinimum: $shelfLifeMinimum, ')
          ..write('shelfLifeMaximum: $shelfLifeMaximum, ')
          ..write('shelfLifeUnit: $shelfLifeUnit, ')
          ..write('shelfLifeGuidance: $shelfLifeGuidance, ')
          ..write('shelfLifeReason: $shelfLifeReason, ')
          ..write('shelfLifeEvidenceVersion: $shelfLifeEvidenceVersion, ')
          ..write('localImageRelativePath: $localImageRelativePath, ')
          ..write('remoteImageKey: $remoteImageKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    ownerId,
    batchId,
    fruitType,
    ripenessStage,
    modelConfidence,
    modelVersion,
    resultOrigin,
    shelfLifeStatus,
    shelfLifeMinimum,
    shelfLifeMaximum,
    shelfLifeUnit,
    shelfLifeGuidance,
    shelfLifeReason,
    shelfLifeEvidenceVersion,
    localImageRelativePath,
    remoteImageKey,
    createdAt,
    updatedAt,
    deletedAt,
    syncState,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanRecordRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.batchId == this.batchId &&
          other.fruitType == this.fruitType &&
          other.ripenessStage == this.ripenessStage &&
          other.modelConfidence == this.modelConfidence &&
          other.modelVersion == this.modelVersion &&
          other.resultOrigin == this.resultOrigin &&
          other.shelfLifeStatus == this.shelfLifeStatus &&
          other.shelfLifeMinimum == this.shelfLifeMinimum &&
          other.shelfLifeMaximum == this.shelfLifeMaximum &&
          other.shelfLifeUnit == this.shelfLifeUnit &&
          other.shelfLifeGuidance == this.shelfLifeGuidance &&
          other.shelfLifeReason == this.shelfLifeReason &&
          other.shelfLifeEvidenceVersion == this.shelfLifeEvidenceVersion &&
          other.localImageRelativePath == this.localImageRelativePath &&
          other.remoteImageKey == this.remoteImageKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncState == this.syncState);
}

class ScanRecordsCompanion extends UpdateCompanion<ScanRecordRow> {
  final Value<String> id;
  final Value<String?> ownerId;
  final Value<String?> batchId;
  final Value<String> fruitType;
  final Value<String> ripenessStage;
  final Value<double> modelConfidence;
  final Value<String> modelVersion;
  final Value<String> resultOrigin;
  final Value<String> shelfLifeStatus;
  final Value<int?> shelfLifeMinimum;
  final Value<int?> shelfLifeMaximum;
  final Value<String?> shelfLifeUnit;
  final Value<String?> shelfLifeGuidance;
  final Value<String?> shelfLifeReason;
  final Value<String> shelfLifeEvidenceVersion;
  final Value<String?> localImageRelativePath;
  final Value<String?> remoteImageKey;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const ScanRecordsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.fruitType = const Value.absent(),
    this.ripenessStage = const Value.absent(),
    this.modelConfidence = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.resultOrigin = const Value.absent(),
    this.shelfLifeStatus = const Value.absent(),
    this.shelfLifeMinimum = const Value.absent(),
    this.shelfLifeMaximum = const Value.absent(),
    this.shelfLifeUnit = const Value.absent(),
    this.shelfLifeGuidance = const Value.absent(),
    this.shelfLifeReason = const Value.absent(),
    this.shelfLifeEvidenceVersion = const Value.absent(),
    this.localImageRelativePath = const Value.absent(),
    this.remoteImageKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScanRecordsCompanion.insert({
    required String id,
    this.ownerId = const Value.absent(),
    this.batchId = const Value.absent(),
    required String fruitType,
    required String ripenessStage,
    required double modelConfidence,
    required String modelVersion,
    this.resultOrigin = const Value.absent(),
    required String shelfLifeStatus,
    this.shelfLifeMinimum = const Value.absent(),
    this.shelfLifeMaximum = const Value.absent(),
    this.shelfLifeUnit = const Value.absent(),
    this.shelfLifeGuidance = const Value.absent(),
    this.shelfLifeReason = const Value.absent(),
    required String shelfLifeEvidenceVersion,
    this.localImageRelativePath = const Value.absent(),
    this.remoteImageKey = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fruitType = Value(fruitType),
       ripenessStage = Value(ripenessStage),
       modelConfidence = Value(modelConfidence),
       modelVersion = Value(modelVersion),
       shelfLifeStatus = Value(shelfLifeStatus),
       shelfLifeEvidenceVersion = Value(shelfLifeEvidenceVersion),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ScanRecordRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? batchId,
    Expression<String>? fruitType,
    Expression<String>? ripenessStage,
    Expression<double>? modelConfidence,
    Expression<String>? modelVersion,
    Expression<String>? resultOrigin,
    Expression<String>? shelfLifeStatus,
    Expression<int>? shelfLifeMinimum,
    Expression<int>? shelfLifeMaximum,
    Expression<String>? shelfLifeUnit,
    Expression<String>? shelfLifeGuidance,
    Expression<String>? shelfLifeReason,
    Expression<String>? shelfLifeEvidenceVersion,
    Expression<String>? localImageRelativePath,
    Expression<String>? remoteImageKey,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (batchId != null) 'batch_id': batchId,
      if (fruitType != null) 'fruit_type': fruitType,
      if (ripenessStage != null) 'ripeness_stage': ripenessStage,
      if (modelConfidence != null) 'model_confidence': modelConfidence,
      if (modelVersion != null) 'model_version': modelVersion,
      if (resultOrigin != null) 'result_origin': resultOrigin,
      if (shelfLifeStatus != null) 'shelf_life_status': shelfLifeStatus,
      if (shelfLifeMinimum != null) 'shelf_life_minimum': shelfLifeMinimum,
      if (shelfLifeMaximum != null) 'shelf_life_maximum': shelfLifeMaximum,
      if (shelfLifeUnit != null) 'shelf_life_unit': shelfLifeUnit,
      if (shelfLifeGuidance != null) 'shelf_life_guidance': shelfLifeGuidance,
      if (shelfLifeReason != null) 'shelf_life_reason': shelfLifeReason,
      if (shelfLifeEvidenceVersion != null)
        'shelf_life_evidence_version': shelfLifeEvidenceVersion,
      if (localImageRelativePath != null)
        'local_image_relative_path': localImageRelativePath,
      if (remoteImageKey != null) 'remote_image_key': remoteImageKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScanRecordsCompanion copyWith({
    Value<String>? id,
    Value<String?>? ownerId,
    Value<String?>? batchId,
    Value<String>? fruitType,
    Value<String>? ripenessStage,
    Value<double>? modelConfidence,
    Value<String>? modelVersion,
    Value<String>? resultOrigin,
    Value<String>? shelfLifeStatus,
    Value<int?>? shelfLifeMinimum,
    Value<int?>? shelfLifeMaximum,
    Value<String?>? shelfLifeUnit,
    Value<String?>? shelfLifeGuidance,
    Value<String?>? shelfLifeReason,
    Value<String>? shelfLifeEvidenceVersion,
    Value<String?>? localImageRelativePath,
    Value<String?>? remoteImageKey,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncState,
    Value<int>? rowid,
  }) {
    return ScanRecordsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      batchId: batchId ?? this.batchId,
      fruitType: fruitType ?? this.fruitType,
      ripenessStage: ripenessStage ?? this.ripenessStage,
      modelConfidence: modelConfidence ?? this.modelConfidence,
      modelVersion: modelVersion ?? this.modelVersion,
      resultOrigin: resultOrigin ?? this.resultOrigin,
      shelfLifeStatus: shelfLifeStatus ?? this.shelfLifeStatus,
      shelfLifeMinimum: shelfLifeMinimum ?? this.shelfLifeMinimum,
      shelfLifeMaximum: shelfLifeMaximum ?? this.shelfLifeMaximum,
      shelfLifeUnit: shelfLifeUnit ?? this.shelfLifeUnit,
      shelfLifeGuidance: shelfLifeGuidance ?? this.shelfLifeGuidance,
      shelfLifeReason: shelfLifeReason ?? this.shelfLifeReason,
      shelfLifeEvidenceVersion:
          shelfLifeEvidenceVersion ?? this.shelfLifeEvidenceVersion,
      localImageRelativePath:
          localImageRelativePath ?? this.localImageRelativePath,
      remoteImageKey: remoteImageKey ?? this.remoteImageKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (fruitType.present) {
      map['fruit_type'] = Variable<String>(fruitType.value);
    }
    if (ripenessStage.present) {
      map['ripeness_stage'] = Variable<String>(ripenessStage.value);
    }
    if (modelConfidence.present) {
      map['model_confidence'] = Variable<double>(modelConfidence.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (resultOrigin.present) {
      map['result_origin'] = Variable<String>(resultOrigin.value);
    }
    if (shelfLifeStatus.present) {
      map['shelf_life_status'] = Variable<String>(shelfLifeStatus.value);
    }
    if (shelfLifeMinimum.present) {
      map['shelf_life_minimum'] = Variable<int>(shelfLifeMinimum.value);
    }
    if (shelfLifeMaximum.present) {
      map['shelf_life_maximum'] = Variable<int>(shelfLifeMaximum.value);
    }
    if (shelfLifeUnit.present) {
      map['shelf_life_unit'] = Variable<String>(shelfLifeUnit.value);
    }
    if (shelfLifeGuidance.present) {
      map['shelf_life_guidance'] = Variable<String>(shelfLifeGuidance.value);
    }
    if (shelfLifeReason.present) {
      map['shelf_life_reason'] = Variable<String>(shelfLifeReason.value);
    }
    if (shelfLifeEvidenceVersion.present) {
      map['shelf_life_evidence_version'] = Variable<String>(
        shelfLifeEvidenceVersion.value,
      );
    }
    if (localImageRelativePath.present) {
      map['local_image_relative_path'] = Variable<String>(
        localImageRelativePath.value,
      );
    }
    if (remoteImageKey.present) {
      map['remote_image_key'] = Variable<String>(remoteImageKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
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
    return (StringBuffer('ScanRecordsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('batchId: $batchId, ')
          ..write('fruitType: $fruitType, ')
          ..write('ripenessStage: $ripenessStage, ')
          ..write('modelConfidence: $modelConfidence, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('resultOrigin: $resultOrigin, ')
          ..write('shelfLifeStatus: $shelfLifeStatus, ')
          ..write('shelfLifeMinimum: $shelfLifeMinimum, ')
          ..write('shelfLifeMaximum: $shelfLifeMaximum, ')
          ..write('shelfLifeUnit: $shelfLifeUnit, ')
          ..write('shelfLifeGuidance: $shelfLifeGuidance, ')
          ..write('shelfLifeReason: $shelfLifeReason, ')
          ..write('shelfLifeEvidenceVersion: $shelfLifeEvidenceVersion, ')
          ..write('localImageRelativePath: $localImageRelativePath, ')
          ..write('remoteImageKey: $remoteImageKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, OrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES batches (id) ON DELETE NO ACTION',
    ),
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryAddressMeta = const VerificationMeta(
    'deliveryAddress',
  );
  @override
  late final GeneratedColumn<String> deliveryAddress = GeneratedColumn<String>(
    'delivery_address',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryDateMeta = const VerificationMeta(
    'deliveryDate',
  );
  @override
  late final GeneratedColumn<DateTime> deliveryDate = GeneratedColumn<DateTime>(
    'delivery_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(PersistenceCodecs.orderStatusCodes),
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    check: () => syncState.isIn(PersistenceCodecs.syncStateCodes),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_only'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    batchId,
    customerName,
    deliveryAddress,
    deliveryDate,
    status,
    createdAt,
    updatedAt,
    deletedAt,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('delivery_address')) {
      context.handle(
        _deliveryAddressMeta,
        deliveryAddress.isAcceptableOrUnknown(
          data['delivery_address']!,
          _deliveryAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryAddressMeta);
    }
    if (data.containsKey('delivery_date')) {
      context.handle(
        _deliveryDateMeta,
        deliveryDate.isAcceptableOrUnknown(
          data['delivery_date']!,
          _deliveryDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
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
  OrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      deliveryAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_address'],
      )!,
      deliveryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}delivery_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class OrderRow extends DataClass implements Insertable<OrderRow> {
  final String id;
  final String? ownerId;
  final String batchId;
  final String customerName;
  final String deliveryAddress;
  final DateTime deliveryDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncState;
  const OrderRow({
    required this.id,
    this.ownerId,
    required this.batchId,
    required this.customerName,
    required this.deliveryAddress,
    required this.deliveryDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    map['batch_id'] = Variable<String>(batchId);
    map['customer_name'] = Variable<String>(customerName);
    map['delivery_address'] = Variable<String>(deliveryAddress);
    map['delivery_date'] = Variable<DateTime>(deliveryDate);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      batchId: Value(batchId),
      customerName: Value(customerName),
      deliveryAddress: Value(deliveryAddress),
      deliveryDate: Value(deliveryDate),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncState: Value(syncState),
    );
  }

  factory OrderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      batchId: serializer.fromJson<String>(json['batchId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      deliveryAddress: serializer.fromJson<String>(json['deliveryAddress']),
      deliveryDate: serializer.fromJson<DateTime>(json['deliveryDate']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String?>(ownerId),
      'batchId': serializer.toJson<String>(batchId),
      'customerName': serializer.toJson<String>(customerName),
      'deliveryAddress': serializer.toJson<String>(deliveryAddress),
      'deliveryDate': serializer.toJson<DateTime>(deliveryDate),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  OrderRow copyWith({
    String? id,
    Value<String?> ownerId = const Value.absent(),
    String? batchId,
    String? customerName,
    String? deliveryAddress,
    DateTime? deliveryDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncState,
  }) => OrderRow(
    id: id ?? this.id,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    batchId: batchId ?? this.batchId,
    customerName: customerName ?? this.customerName,
    deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    deliveryDate: deliveryDate ?? this.deliveryDate,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncState: syncState ?? this.syncState,
  );
  OrderRow copyWithCompanion(OrdersCompanion data) {
    return OrderRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      deliveryAddress: data.deliveryAddress.present
          ? data.deliveryAddress.value
          : this.deliveryAddress,
      deliveryDate: data.deliveryDate.present
          ? data.deliveryDate.value
          : this.deliveryDate,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('batchId: $batchId, ')
          ..write('customerName: $customerName, ')
          ..write('deliveryAddress: $deliveryAddress, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    batchId,
    customerName,
    deliveryAddress,
    deliveryDate,
    status,
    createdAt,
    updatedAt,
    deletedAt,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.batchId == this.batchId &&
          other.customerName == this.customerName &&
          other.deliveryAddress == this.deliveryAddress &&
          other.deliveryDate == this.deliveryDate &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncState == this.syncState);
}

class OrdersCompanion extends UpdateCompanion<OrderRow> {
  final Value<String> id;
  final Value<String?> ownerId;
  final Value<String> batchId;
  final Value<String> customerName;
  final Value<String> deliveryAddress;
  final Value<DateTime> deliveryDate;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.deliveryAddress = const Value.absent(),
    this.deliveryDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    this.ownerId = const Value.absent(),
    required String batchId,
    required String customerName,
    required String deliveryAddress,
    required DateTime deliveryDate,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       batchId = Value(batchId),
       customerName = Value(customerName),
       deliveryAddress = Value(deliveryAddress),
       deliveryDate = Value(deliveryDate),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OrderRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? batchId,
    Expression<String>? customerName,
    Expression<String>? deliveryAddress,
    Expression<DateTime>? deliveryDate,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (batchId != null) 'batch_id': batchId,
      if (customerName != null) 'customer_name': customerName,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith({
    Value<String>? id,
    Value<String?>? ownerId,
    Value<String>? batchId,
    Value<String>? customerName,
    Value<String>? deliveryAddress,
    Value<DateTime>? deliveryDate,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncState,
    Value<int>? rowid,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      batchId: batchId ?? this.batchId,
      customerName: customerName ?? this.customerName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (deliveryAddress.present) {
      map['delivery_address'] = Variable<String>(deliveryAddress.value);
    }
    if (deliveryDate.present) {
      map['delivery_date'] = Variable<DateTime>(deliveryDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
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
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('batchId: $batchId, ')
          ..write('customerName: $customerName, ')
          ..write('deliveryAddress: $deliveryAddress, ')
          ..write('deliveryDate: $deliveryDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _imageUploadConsentMeta =
      const VerificationMeta('imageUploadConsent');
  @override
  late final GeneratedColumn<bool> imageUploadConsent = GeneratedColumn<bool>(
    'image_upload_consent',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("image_upload_consent" IN (0, 1))',
    ),
  );
  static const VerificationMeta _consentVersionMeta = const VerificationMeta(
    'consentVersion',
  );
  @override
  late final GeneratedColumn<String> consentVersion = GeneratedColumn<String>(
    'consent_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSuccessfulSyncAtMeta =
      const VerificationMeta('lastSuccessfulSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessfulSyncAt =
      GeneratedColumn<DateTime>(
        'last_successful_sync_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    imageUploadConsent,
    consentVersion,
    lastSuccessfulSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('image_upload_consent')) {
      context.handle(
        _imageUploadConsentMeta,
        imageUploadConsent.isAcceptableOrUnknown(
          data['image_upload_consent']!,
          _imageUploadConsentMeta,
        ),
      );
    }
    if (data.containsKey('consent_version')) {
      context.handle(
        _consentVersionMeta,
        consentVersion.isAcceptableOrUnknown(
          data['consent_version']!,
          _consentVersionMeta,
        ),
      );
    }
    if (data.containsKey('last_successful_sync_at')) {
      context.handle(
        _lastSuccessfulSyncAtMeta,
        lastSuccessfulSyncAt.isAcceptableOrUnknown(
          data['last_successful_sync_at']!,
          _lastSuccessfulSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      imageUploadConsent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}image_upload_consent'],
      ),
      consentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consent_version'],
      ),
      lastSuccessfulSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_successful_sync_at'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final bool? imageUploadConsent;
  final String? consentVersion;
  final DateTime? lastSuccessfulSyncAt;
  const AppSettingsRow({
    required this.id,
    this.imageUploadConsent,
    this.consentVersion,
    this.lastSuccessfulSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || imageUploadConsent != null) {
      map['image_upload_consent'] = Variable<bool>(imageUploadConsent);
    }
    if (!nullToAbsent || consentVersion != null) {
      map['consent_version'] = Variable<String>(consentVersion);
    }
    if (!nullToAbsent || lastSuccessfulSyncAt != null) {
      map['last_successful_sync_at'] = Variable<DateTime>(lastSuccessfulSyncAt);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      imageUploadConsent: imageUploadConsent == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUploadConsent),
      consentVersion: consentVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(consentVersion),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessfulSyncAt),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      imageUploadConsent: serializer.fromJson<bool?>(
        json['imageUploadConsent'],
      ),
      consentVersion: serializer.fromJson<String?>(json['consentVersion']),
      lastSuccessfulSyncAt: serializer.fromJson<DateTime?>(
        json['lastSuccessfulSyncAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'imageUploadConsent': serializer.toJson<bool?>(imageUploadConsent),
      'consentVersion': serializer.toJson<String?>(consentVersion),
      'lastSuccessfulSyncAt': serializer.toJson<DateTime?>(
        lastSuccessfulSyncAt,
      ),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    Value<bool?> imageUploadConsent = const Value.absent(),
    Value<String?> consentVersion = const Value.absent(),
    Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
  }) => AppSettingsRow(
    id: id ?? this.id,
    imageUploadConsent: imageUploadConsent.present
        ? imageUploadConsent.value
        : this.imageUploadConsent,
    consentVersion: consentVersion.present
        ? consentVersion.value
        : this.consentVersion,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt.present
        ? lastSuccessfulSyncAt.value
        : this.lastSuccessfulSyncAt,
  );
  AppSettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      imageUploadConsent: data.imageUploadConsent.present
          ? data.imageUploadConsent.value
          : this.imageUploadConsent,
      consentVersion: data.consentVersion.present
          ? data.consentVersion.value
          : this.consentVersion,
      lastSuccessfulSyncAt: data.lastSuccessfulSyncAt.present
          ? data.lastSuccessfulSyncAt.value
          : this.lastSuccessfulSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('imageUploadConsent: $imageUploadConsent, ')
          ..write('consentVersion: $consentVersion, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, imageUploadConsent, consentVersion, lastSuccessfulSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.imageUploadConsent == this.imageUploadConsent &&
          other.consentVersion == this.consentVersion &&
          other.lastSuccessfulSyncAt == this.lastSuccessfulSyncAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<bool?> imageUploadConsent;
  final Value<String?> consentVersion;
  final Value<DateTime?> lastSuccessfulSyncAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.imageUploadConsent = const Value.absent(),
    this.consentVersion = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.imageUploadConsent = const Value.absent(),
    this.consentVersion = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
  });
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? imageUploadConsent,
    Expression<String>? consentVersion,
    Expression<DateTime>? lastSuccessfulSyncAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imageUploadConsent != null)
        'image_upload_consent': imageUploadConsent,
      if (consentVersion != null) 'consent_version': consentVersion,
      if (lastSuccessfulSyncAt != null)
        'last_successful_sync_at': lastSuccessfulSyncAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool?>? imageUploadConsent,
    Value<String?>? consentVersion,
    Value<DateTime?>? lastSuccessfulSyncAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      imageUploadConsent: imageUploadConsent ?? this.imageUploadConsent,
      consentVersion: consentVersion ?? this.consentVersion,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (imageUploadConsent.present) {
      map['image_upload_consent'] = Variable<bool>(imageUploadConsent.value);
    }
    if (consentVersion.present) {
      map['consent_version'] = Variable<String>(consentVersion.value);
    }
    if (lastSuccessfulSyncAt.present) {
      map['last_successful_sync_at'] = Variable<DateTime>(
        lastSuccessfulSyncAt.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('imageUploadConsent: $imageUploadConsent, ')
          ..write('consentVersion: $consentVersion, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BatchesTable batches = $BatchesTable(this);
  late final $ScanRecordsTable scanRecords = $ScanRecordsTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final Index batchesOwnerIdx = Index(
    'batches_owner_idx',
    'CREATE INDEX batches_owner_idx ON batches (owner_id)',
  );
  late final Index batchesUpdatedIdx = Index(
    'batches_updated_idx',
    'CREATE INDEX batches_updated_idx ON batches (updated_at)',
  );
  late final Index batchesActivePageIdx = Index(
    'batches_active_page_idx',
    'CREATE INDEX batches_active_page_idx ON batches (deleted_at, created_at, id)',
  );
  late final Index scanRecordsOwnerIdx = Index(
    'scan_records_owner_idx',
    'CREATE INDEX scan_records_owner_idx ON scan_records (owner_id)',
  );
  late final Index scanRecordsBatchIdx = Index(
    'scan_records_batch_idx',
    'CREATE INDEX scan_records_batch_idx ON scan_records (batch_id)',
  );
  late final Index scanRecordsCreatedIdx = Index(
    'scan_records_created_idx',
    'CREATE INDEX scan_records_created_idx ON scan_records (created_at)',
  );
  late final Index scanRecordsUpdatedIdx = Index(
    'scan_records_updated_idx',
    'CREATE INDEX scan_records_updated_idx ON scan_records (updated_at)',
  );
  late final Index scanRecordsActivePageIdx = Index(
    'scan_records_active_page_idx',
    'CREATE INDEX scan_records_active_page_idx ON scan_records (deleted_at, created_at, id)',
  );
  late final Index scanRecordsBatchPageIdx = Index(
    'scan_records_batch_page_idx',
    'CREATE INDEX scan_records_batch_page_idx ON scan_records (batch_id, deleted_at, created_at, id)',
  );
  late final Index ordersOwnerIdx = Index(
    'orders_owner_idx',
    'CREATE INDEX orders_owner_idx ON orders (owner_id)',
  );
  late final Index ordersUpdatedIdx = Index(
    'orders_updated_idx',
    'CREATE INDEX orders_updated_idx ON orders (updated_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    batches,
    scanRecords,
    orders,
    appSettings,
    batchesOwnerIdx,
    batchesUpdatedIdx,
    batchesActivePageIdx,
    scanRecordsOwnerIdx,
    scanRecordsBatchIdx,
    scanRecordsCreatedIdx,
    scanRecordsUpdatedIdx,
    scanRecordsActivePageIdx,
    scanRecordsBatchPageIdx,
    ordersOwnerIdx,
    ordersUpdatedIdx,
  ];
}

typedef $$BatchesTableCreateCompanionBuilder =
    BatchesCompanion Function({
      required String id,
      Value<String?> ownerId,
      required String name,
      required String fruitType,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncState,
      Value<int> rowid,
    });
typedef $$BatchesTableUpdateCompanionBuilder =
    BatchesCompanion Function({
      Value<String> id,
      Value<String?> ownerId,
      Value<String> name,
      Value<String> fruitType,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncState,
      Value<int> rowid,
    });

final class $$BatchesTableReferences
    extends BaseReferences<_$AppDatabase, $BatchesTable, BatchRow> {
  $$BatchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScanRecordsTable, List<ScanRecordRow>>
  _scanRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scanRecords,
    aliasName: 'batches__id__scan_records__batch_id',
  );

  $$ScanRecordsTableProcessedTableManager get scanRecordsRefs {
    final manager = $$ScanRecordsTableTableManager(
      $_db,
      $_db.scanRecords,
    ).filter((f) => f.batchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scanRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OrdersTable, List<OrderRow>> _ordersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.orders,
    aliasName: 'batches__id__orders__batch_id',
  );

  $$OrdersTableProcessedTableManager get ordersRefs {
    final manager = $$OrdersTableTableManager(
      $_db,
      $_db.orders,
    ).filter((f) => f.batchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BatchesTableFilterComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableFilterComposer({
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

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fruitType => $composableBuilder(
    column: $table.fruitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> scanRecordsRefs(
    Expression<bool> Function($$ScanRecordsTableFilterComposer f) f,
  ) {
    final $$ScanRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanRecords,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanRecordsTableFilterComposer(
            $db: $db,
            $table: $db.scanRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ordersRefs(
    Expression<bool> Function($$OrdersTableFilterComposer f) f,
  ) {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableFilterComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableOrderingComposer({
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

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fruitType => $composableBuilder(
    column: $table.fruitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get fruitType =>
      $composableBuilder(column: $table.fruitType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  Expression<T> scanRecordsRefs<T extends Object>(
    Expression<T> Function($$ScanRecordsTableAnnotationComposer a) f,
  ) {
    final $$ScanRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanRecords,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.scanRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ordersRefs<T extends Object>(
    Expression<T> Function($$OrdersTableAnnotationComposer a) f,
  ) {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchesTable,
          BatchRow,
          $$BatchesTableFilterComposer,
          $$BatchesTableOrderingComposer,
          $$BatchesTableAnnotationComposer,
          $$BatchesTableCreateCompanionBuilder,
          $$BatchesTableUpdateCompanionBuilder,
          (BatchRow, $$BatchesTableReferences),
          BatchRow,
          PrefetchHooks Function({bool scanRecordsRefs, bool ordersRefs})
        > {
  $$BatchesTableTableManager(_$AppDatabase db, $BatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> fruitType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchesCompanion(
                id: id,
                ownerId: ownerId,
                name: name,
                fruitType: fruitType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> ownerId = const Value.absent(),
                required String name,
                required String fruitType,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchesCompanion.insert(
                id: id,
                ownerId: ownerId,
                name: name,
                fruitType: fruitType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({scanRecordsRefs = false, ordersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scanRecordsRefs) db.scanRecords,
                    if (ordersRefs) db.orders,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scanRecordsRefs)
                        await $_getPrefetchedData<
                          BatchRow,
                          $BatchesTable,
                          ScanRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$BatchesTableReferences
                              ._scanRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).scanRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.batchId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ordersRefs)
                        await $_getPrefetchedData<
                          BatchRow,
                          $BatchesTable,
                          OrderRow
                        >(
                          currentTable: table,
                          referencedTable: $$BatchesTableReferences
                              ._ordersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).ordersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.batchId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchesTable,
      BatchRow,
      $$BatchesTableFilterComposer,
      $$BatchesTableOrderingComposer,
      $$BatchesTableAnnotationComposer,
      $$BatchesTableCreateCompanionBuilder,
      $$BatchesTableUpdateCompanionBuilder,
      (BatchRow, $$BatchesTableReferences),
      BatchRow,
      PrefetchHooks Function({bool scanRecordsRefs, bool ordersRefs})
    >;
typedef $$ScanRecordsTableCreateCompanionBuilder =
    ScanRecordsCompanion Function({
      required String id,
      Value<String?> ownerId,
      Value<String?> batchId,
      required String fruitType,
      required String ripenessStage,
      required double modelConfidence,
      required String modelVersion,
      Value<String> resultOrigin,
      required String shelfLifeStatus,
      Value<int?> shelfLifeMinimum,
      Value<int?> shelfLifeMaximum,
      Value<String?> shelfLifeUnit,
      Value<String?> shelfLifeGuidance,
      Value<String?> shelfLifeReason,
      required String shelfLifeEvidenceVersion,
      Value<String?> localImageRelativePath,
      Value<String?> remoteImageKey,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncState,
      Value<int> rowid,
    });
typedef $$ScanRecordsTableUpdateCompanionBuilder =
    ScanRecordsCompanion Function({
      Value<String> id,
      Value<String?> ownerId,
      Value<String?> batchId,
      Value<String> fruitType,
      Value<String> ripenessStage,
      Value<double> modelConfidence,
      Value<String> modelVersion,
      Value<String> resultOrigin,
      Value<String> shelfLifeStatus,
      Value<int?> shelfLifeMinimum,
      Value<int?> shelfLifeMaximum,
      Value<String?> shelfLifeUnit,
      Value<String?> shelfLifeGuidance,
      Value<String?> shelfLifeReason,
      Value<String> shelfLifeEvidenceVersion,
      Value<String?> localImageRelativePath,
      Value<String?> remoteImageKey,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncState,
      Value<int> rowid,
    });

final class $$ScanRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $ScanRecordsTable, ScanRecordRow> {
  $$ScanRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BatchesTable _batchIdTable(_$AppDatabase db) =>
      db.batches.createAlias('scan_records__batch_id__batches__id');

  $$BatchesTableProcessedTableManager? get batchId {
    final $_column = $_itemColumn<String>('batch_id');
    if ($_column == null) return null;
    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScanRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ScanRecordsTable> {
  $$ScanRecordsTableFilterComposer({
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

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fruitType => $composableBuilder(
    column: $table.fruitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ripenessStage => $composableBuilder(
    column: $table.ripenessStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get modelConfidence => $composableBuilder(
    column: $table.modelConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultOrigin => $composableBuilder(
    column: $table.resultOrigin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shelfLifeStatus => $composableBuilder(
    column: $table.shelfLifeStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shelfLifeMinimum => $composableBuilder(
    column: $table.shelfLifeMinimum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shelfLifeMaximum => $composableBuilder(
    column: $table.shelfLifeMaximum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shelfLifeUnit => $composableBuilder(
    column: $table.shelfLifeUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shelfLifeGuidance => $composableBuilder(
    column: $table.shelfLifeGuidance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shelfLifeReason => $composableBuilder(
    column: $table.shelfLifeReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shelfLifeEvidenceVersion => $composableBuilder(
    column: $table.shelfLifeEvidenceVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localImageRelativePath => $composableBuilder(
    column: $table.localImageRelativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteImageKey => $composableBuilder(
    column: $table.remoteImageKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  $$BatchesTableFilterComposer get batchId {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanRecordsTable> {
  $$ScanRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fruitType => $composableBuilder(
    column: $table.fruitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ripenessStage => $composableBuilder(
    column: $table.ripenessStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get modelConfidence => $composableBuilder(
    column: $table.modelConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultOrigin => $composableBuilder(
    column: $table.resultOrigin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shelfLifeStatus => $composableBuilder(
    column: $table.shelfLifeStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shelfLifeMinimum => $composableBuilder(
    column: $table.shelfLifeMinimum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shelfLifeMaximum => $composableBuilder(
    column: $table.shelfLifeMaximum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shelfLifeUnit => $composableBuilder(
    column: $table.shelfLifeUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shelfLifeGuidance => $composableBuilder(
    column: $table.shelfLifeGuidance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shelfLifeReason => $composableBuilder(
    column: $table.shelfLifeReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shelfLifeEvidenceVersion => $composableBuilder(
    column: $table.shelfLifeEvidenceVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localImageRelativePath => $composableBuilder(
    column: $table.localImageRelativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteImageKey => $composableBuilder(
    column: $table.remoteImageKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  $$BatchesTableOrderingComposer get batchId {
    final $$BatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableOrderingComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanRecordsTable> {
  $$ScanRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get fruitType =>
      $composableBuilder(column: $table.fruitType, builder: (column) => column);

  GeneratedColumn<String> get ripenessStage => $composableBuilder(
    column: $table.ripenessStage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get modelConfidence => $composableBuilder(
    column: $table.modelConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultOrigin => $composableBuilder(
    column: $table.resultOrigin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shelfLifeStatus => $composableBuilder(
    column: $table.shelfLifeStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shelfLifeMinimum => $composableBuilder(
    column: $table.shelfLifeMinimum,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shelfLifeMaximum => $composableBuilder(
    column: $table.shelfLifeMaximum,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shelfLifeUnit => $composableBuilder(
    column: $table.shelfLifeUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shelfLifeGuidance => $composableBuilder(
    column: $table.shelfLifeGuidance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shelfLifeReason => $composableBuilder(
    column: $table.shelfLifeReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shelfLifeEvidenceVersion => $composableBuilder(
    column: $table.shelfLifeEvidenceVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localImageRelativePath => $composableBuilder(
    column: $table.localImageRelativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteImageKey => $composableBuilder(
    column: $table.remoteImageKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  $$BatchesTableAnnotationComposer get batchId {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanRecordsTable,
          ScanRecordRow,
          $$ScanRecordsTableFilterComposer,
          $$ScanRecordsTableOrderingComposer,
          $$ScanRecordsTableAnnotationComposer,
          $$ScanRecordsTableCreateCompanionBuilder,
          $$ScanRecordsTableUpdateCompanionBuilder,
          (ScanRecordRow, $$ScanRecordsTableReferences),
          ScanRecordRow,
          PrefetchHooks Function({bool batchId})
        > {
  $$ScanRecordsTableTableManager(_$AppDatabase db, $ScanRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<String> fruitType = const Value.absent(),
                Value<String> ripenessStage = const Value.absent(),
                Value<double> modelConfidence = const Value.absent(),
                Value<String> modelVersion = const Value.absent(),
                Value<String> resultOrigin = const Value.absent(),
                Value<String> shelfLifeStatus = const Value.absent(),
                Value<int?> shelfLifeMinimum = const Value.absent(),
                Value<int?> shelfLifeMaximum = const Value.absent(),
                Value<String?> shelfLifeUnit = const Value.absent(),
                Value<String?> shelfLifeGuidance = const Value.absent(),
                Value<String?> shelfLifeReason = const Value.absent(),
                Value<String> shelfLifeEvidenceVersion = const Value.absent(),
                Value<String?> localImageRelativePath = const Value.absent(),
                Value<String?> remoteImageKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanRecordsCompanion(
                id: id,
                ownerId: ownerId,
                batchId: batchId,
                fruitType: fruitType,
                ripenessStage: ripenessStage,
                modelConfidence: modelConfidence,
                modelVersion: modelVersion,
                resultOrigin: resultOrigin,
                shelfLifeStatus: shelfLifeStatus,
                shelfLifeMinimum: shelfLifeMinimum,
                shelfLifeMaximum: shelfLifeMaximum,
                shelfLifeUnit: shelfLifeUnit,
                shelfLifeGuidance: shelfLifeGuidance,
                shelfLifeReason: shelfLifeReason,
                shelfLifeEvidenceVersion: shelfLifeEvidenceVersion,
                localImageRelativePath: localImageRelativePath,
                remoteImageKey: remoteImageKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> ownerId = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                required String fruitType,
                required String ripenessStage,
                required double modelConfidence,
                required String modelVersion,
                Value<String> resultOrigin = const Value.absent(),
                required String shelfLifeStatus,
                Value<int?> shelfLifeMinimum = const Value.absent(),
                Value<int?> shelfLifeMaximum = const Value.absent(),
                Value<String?> shelfLifeUnit = const Value.absent(),
                Value<String?> shelfLifeGuidance = const Value.absent(),
                Value<String?> shelfLifeReason = const Value.absent(),
                required String shelfLifeEvidenceVersion,
                Value<String?> localImageRelativePath = const Value.absent(),
                Value<String?> remoteImageKey = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanRecordsCompanion.insert(
                id: id,
                ownerId: ownerId,
                batchId: batchId,
                fruitType: fruitType,
                ripenessStage: ripenessStage,
                modelConfidence: modelConfidence,
                modelVersion: modelVersion,
                resultOrigin: resultOrigin,
                shelfLifeStatus: shelfLifeStatus,
                shelfLifeMinimum: shelfLifeMinimum,
                shelfLifeMaximum: shelfLifeMaximum,
                shelfLifeUnit: shelfLifeUnit,
                shelfLifeGuidance: shelfLifeGuidance,
                shelfLifeReason: shelfLifeReason,
                shelfLifeEvidenceVersion: shelfLifeEvidenceVersion,
                localImageRelativePath: localImageRelativePath,
                remoteImageKey: remoteImageKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScanRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({batchId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (batchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.batchId,
                                referencedTable: $$ScanRecordsTableReferences
                                    ._batchIdTable(db),
                                referencedColumn: $$ScanRecordsTableReferences
                                    ._batchIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScanRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanRecordsTable,
      ScanRecordRow,
      $$ScanRecordsTableFilterComposer,
      $$ScanRecordsTableOrderingComposer,
      $$ScanRecordsTableAnnotationComposer,
      $$ScanRecordsTableCreateCompanionBuilder,
      $$ScanRecordsTableUpdateCompanionBuilder,
      (ScanRecordRow, $$ScanRecordsTableReferences),
      ScanRecordRow,
      PrefetchHooks Function({bool batchId})
    >;
typedef $$OrdersTableCreateCompanionBuilder =
    OrdersCompanion Function({
      required String id,
      Value<String?> ownerId,
      required String batchId,
      required String customerName,
      required String deliveryAddress,
      required DateTime deliveryDate,
      required String status,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncState,
      Value<int> rowid,
    });
typedef $$OrdersTableUpdateCompanionBuilder =
    OrdersCompanion Function({
      Value<String> id,
      Value<String?> ownerId,
      Value<String> batchId,
      Value<String> customerName,
      Value<String> deliveryAddress,
      Value<DateTime> deliveryDate,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncState,
      Value<int> rowid,
    });

final class $$OrdersTableReferences
    extends BaseReferences<_$AppDatabase, $OrdersTable, OrderRow> {
  $$OrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BatchesTable _batchIdTable(_$AppDatabase db) =>
      db.batches.createAlias('orders__batch_id__batches__id');

  $$BatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<String>('batch_id')!;

    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
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

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryAddress => $composableBuilder(
    column: $table.deliveryAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  $$BatchesTableFilterComposer get batchId {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
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

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryAddress => $composableBuilder(
    column: $table.deliveryAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  $$BatchesTableOrderingComposer get batchId {
    final $$BatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableOrderingComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryAddress => $composableBuilder(
    column: $table.deliveryAddress,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deliveryDate => $composableBuilder(
    column: $table.deliveryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  $$BatchesTableAnnotationComposer get batchId {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTable,
          OrderRow,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (OrderRow, $$OrdersTableReferences),
          OrderRow,
          PrefetchHooks Function({bool batchId})
        > {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> deliveryAddress = const Value.absent(),
                Value<DateTime> deliveryDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                ownerId: ownerId,
                batchId: batchId,
                customerName: customerName,
                deliveryAddress: deliveryAddress,
                deliveryDate: deliveryDate,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> ownerId = const Value.absent(),
                required String batchId,
                required String customerName,
                required String deliveryAddress,
                required DateTime deliveryDate,
                required String status,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                ownerId: ownerId,
                batchId: batchId,
                customerName: customerName,
                deliveryAddress: deliveryAddress,
                deliveryDate: deliveryDate,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$OrdersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({batchId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (batchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.batchId,
                                referencedTable: $$OrdersTableReferences
                                    ._batchIdTable(db),
                                referencedColumn: $$OrdersTableReferences
                                    ._batchIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTable,
      OrderRow,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (OrderRow, $$OrdersTableReferences),
      OrderRow,
      PrefetchHooks Function({bool batchId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool?> imageUploadConsent,
      Value<String?> consentVersion,
      Value<DateTime?> lastSuccessfulSyncAt,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool?> imageUploadConsent,
      Value<String?> consentVersion,
      Value<DateTime?> lastSuccessfulSyncAt,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<bool> get imageUploadConsent => $composableBuilder(
    column: $table.imageUploadConsent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consentVersion => $composableBuilder(
    column: $table.consentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<bool> get imageUploadConsent => $composableBuilder(
    column: $table.imageUploadConsent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consentVersion => $composableBuilder(
    column: $table.consentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get imageUploadConsent => $composableBuilder(
    column: $table.imageUploadConsent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get consentVersion => $composableBuilder(
    column: $table.consentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingsRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool?> imageUploadConsent = const Value.absent(),
                Value<String?> consentVersion = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                imageUploadConsent: imageUploadConsent,
                consentVersion: consentVersion,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool?> imageUploadConsent = const Value.absent(),
                Value<String?> consentVersion = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                imageUploadConsent: imageUploadConsent,
                consentVersion: consentVersion,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingsRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BatchesTableTableManager get batches =>
      $$BatchesTableTableManager(_db, _db.batches);
  $$ScanRecordsTableTableManager get scanRecords =>
      $$ScanRecordsTableTableManager(_db, _db.scanRecords);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
