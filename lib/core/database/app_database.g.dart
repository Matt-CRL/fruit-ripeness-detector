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
  static const VerificationMeta _remoteRevisionMeta = const VerificationMeta(
    'remoteRevision',
  );
  @override
  late final GeneratedColumn<int> remoteRevision = GeneratedColumn<int>(
    'remote_revision',
    aliasedName,
    false,
    check: () => ComparableExpr(remoteRevision).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    remoteRevision,
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
    if (data.containsKey('remote_revision')) {
      context.handle(
        _remoteRevisionMeta,
        remoteRevision.isAcceptableOrUnknown(
          data['remote_revision']!,
          _remoteRevisionMeta,
        ),
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
      remoteRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_revision'],
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
  final int remoteRevision;
  const BatchRow({
    required this.id,
    this.ownerId,
    required this.name,
    required this.fruitType,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncState,
    required this.remoteRevision,
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
    map['remote_revision'] = Variable<int>(remoteRevision);
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
      remoteRevision: Value(remoteRevision),
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
      remoteRevision: serializer.fromJson<int>(json['remoteRevision']),
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
      'remoteRevision': serializer.toJson<int>(remoteRevision),
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
    int? remoteRevision,
  }) => BatchRow(
    id: id ?? this.id,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    name: name ?? this.name,
    fruitType: fruitType ?? this.fruitType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncState: syncState ?? this.syncState,
    remoteRevision: remoteRevision ?? this.remoteRevision,
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
      remoteRevision: data.remoteRevision.present
          ? data.remoteRevision.value
          : this.remoteRevision,
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
          ..write('syncState: $syncState, ')
          ..write('remoteRevision: $remoteRevision')
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
    remoteRevision,
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
          other.syncState == this.syncState &&
          other.remoteRevision == this.remoteRevision);
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
  final Value<int> remoteRevision;
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
    this.remoteRevision = const Value.absent(),
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
    this.remoteRevision = const Value.absent(),
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
    Expression<int>? remoteRevision,
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
      if (remoteRevision != null) 'remote_revision': remoteRevision,
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
    Value<int>? remoteRevision,
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
      remoteRevision: remoteRevision ?? this.remoteRevision,
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
    if (remoteRevision.present) {
      map['remote_revision'] = Variable<int>(remoteRevision.value);
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
          ..write('remoteRevision: $remoteRevision, ')
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
  static const VerificationMeta _remoteRevisionMeta = const VerificationMeta(
    'remoteRevision',
  );
  @override
  late final GeneratedColumn<int> remoteRevision = GeneratedColumn<int>(
    'remote_revision',
    aliasedName,
    false,
    check: () => ComparableExpr(remoteRevision).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _imageSyncStateMeta = const VerificationMeta(
    'imageSyncState',
  );
  @override
  late final GeneratedColumn<String> imageSyncState = GeneratedColumn<String>(
    'image_sync_state',
    aliasedName,
    false,
    check: () => imageSyncState.isIn(PersistenceCodecs.imageSyncStateCodes),
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
    remoteRevision,
    imageSyncState,
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
    if (data.containsKey('remote_revision')) {
      context.handle(
        _remoteRevisionMeta,
        remoteRevision.isAcceptableOrUnknown(
          data['remote_revision']!,
          _remoteRevisionMeta,
        ),
      );
    }
    if (data.containsKey('image_sync_state')) {
      context.handle(
        _imageSyncStateMeta,
        imageSyncState.isAcceptableOrUnknown(
          data['image_sync_state']!,
          _imageSyncStateMeta,
        ),
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
      remoteRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_revision'],
      )!,
      imageSyncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_sync_state'],
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
  final int remoteRevision;
  final String imageSyncState;
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
    required this.remoteRevision,
    required this.imageSyncState,
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
    map['remote_revision'] = Variable<int>(remoteRevision);
    map['image_sync_state'] = Variable<String>(imageSyncState);
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
      remoteRevision: Value(remoteRevision),
      imageSyncState: Value(imageSyncState),
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
      remoteRevision: serializer.fromJson<int>(json['remoteRevision']),
      imageSyncState: serializer.fromJson<String>(json['imageSyncState']),
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
      'remoteRevision': serializer.toJson<int>(remoteRevision),
      'imageSyncState': serializer.toJson<String>(imageSyncState),
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
    int? remoteRevision,
    String? imageSyncState,
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
    remoteRevision: remoteRevision ?? this.remoteRevision,
    imageSyncState: imageSyncState ?? this.imageSyncState,
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
      remoteRevision: data.remoteRevision.present
          ? data.remoteRevision.value
          : this.remoteRevision,
      imageSyncState: data.imageSyncState.present
          ? data.imageSyncState.value
          : this.imageSyncState,
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
          ..write('syncState: $syncState, ')
          ..write('remoteRevision: $remoteRevision, ')
          ..write('imageSyncState: $imageSyncState')
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
    remoteRevision,
    imageSyncState,
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
          other.syncState == this.syncState &&
          other.remoteRevision == this.remoteRevision &&
          other.imageSyncState == this.imageSyncState);
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
  final Value<int> remoteRevision;
  final Value<String> imageSyncState;
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
    this.remoteRevision = const Value.absent(),
    this.imageSyncState = const Value.absent(),
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
    this.remoteRevision = const Value.absent(),
    this.imageSyncState = const Value.absent(),
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
    Expression<int>? remoteRevision,
    Expression<String>? imageSyncState,
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
      if (remoteRevision != null) 'remote_revision': remoteRevision,
      if (imageSyncState != null) 'image_sync_state': imageSyncState,
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
    Value<int>? remoteRevision,
    Value<String>? imageSyncState,
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
      remoteRevision: remoteRevision ?? this.remoteRevision,
      imageSyncState: imageSyncState ?? this.imageSyncState,
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
    if (remoteRevision.present) {
      map['remote_revision'] = Variable<int>(remoteRevision.value);
    }
    if (imageSyncState.present) {
      map['image_sync_state'] = Variable<String>(imageSyncState.value);
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
          ..write('remoteRevision: $remoteRevision, ')
          ..write('imageSyncState: $imageSyncState, ')
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
  static const VerificationMeta _remoteRevisionMeta = const VerificationMeta(
    'remoteRevision',
  );
  @override
  late final GeneratedColumn<int> remoteRevision = GeneratedColumn<int>(
    'remote_revision',
    aliasedName,
    false,
    check: () => ComparableExpr(remoteRevision).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    remoteRevision,
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
    if (data.containsKey('remote_revision')) {
      context.handle(
        _remoteRevisionMeta,
        remoteRevision.isAcceptableOrUnknown(
          data['remote_revision']!,
          _remoteRevisionMeta,
        ),
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
      remoteRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_revision'],
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
  final int remoteRevision;
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
    required this.remoteRevision,
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
    map['remote_revision'] = Variable<int>(remoteRevision);
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
      remoteRevision: Value(remoteRevision),
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
      remoteRevision: serializer.fromJson<int>(json['remoteRevision']),
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
      'remoteRevision': serializer.toJson<int>(remoteRevision),
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
    int? remoteRevision,
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
    remoteRevision: remoteRevision ?? this.remoteRevision,
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
      remoteRevision: data.remoteRevision.present
          ? data.remoteRevision.value
          : this.remoteRevision,
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
          ..write('syncState: $syncState, ')
          ..write('remoteRevision: $remoteRevision')
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
    remoteRevision,
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
          other.syncState == this.syncState &&
          other.remoteRevision == this.remoteRevision);
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
  final Value<int> remoteRevision;
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
    this.remoteRevision = const Value.absent(),
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
    this.remoteRevision = const Value.absent(),
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
    Expression<int>? remoteRevision,
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
      if (remoteRevision != null) 'remote_revision': remoteRevision,
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
    Value<int>? remoteRevision,
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
      remoteRevision: remoteRevision ?? this.remoteRevision,
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
    if (remoteRevision.present) {
      map['remote_revision'] = Variable<int>(remoteRevision.value);
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
          ..write('remoteRevision: $remoteRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountSyncSettingsTable extends AccountSyncSettings
    with TableInfo<$AccountSyncSettingsTable, AccountSyncSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountSyncSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _lastSyncAttemptAtMeta = const VerificationMeta(
    'lastSyncAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttemptAt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncCursorAtMeta = const VerificationMeta(
    'syncCursorAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncCursorAt = GeneratedColumn<DateTime>(
    'sync_cursor_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncErrorCodeMeta = const VerificationMeta(
    'lastSyncErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastSyncErrorCode =
      GeneratedColumn<String>(
        'last_sync_error_code',
        aliasedName,
        true,
        type: DriftSqlType.string,
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
  static const VerificationMeta _remoteRevisionMeta = const VerificationMeta(
    'remoteRevision',
  );
  @override
  late final GeneratedColumn<int> remoteRevision = GeneratedColumn<int>(
    'remote_revision',
    aliasedName,
    false,
    check: () => ComparableExpr(remoteRevision).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    imageUploadConsent,
    consentVersion,
    lastSuccessfulSyncAt,
    lastSyncAttemptAt,
    syncCursorAt,
    lastSyncErrorCode,
    syncState,
    remoteRevision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_sync_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountSyncSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
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
    if (data.containsKey('last_sync_attempt_at')) {
      context.handle(
        _lastSyncAttemptAtMeta,
        lastSyncAttemptAt.isAcceptableOrUnknown(
          data['last_sync_attempt_at']!,
          _lastSyncAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_cursor_at')) {
      context.handle(
        _syncCursorAtMeta,
        syncCursorAt.isAcceptableOrUnknown(
          data['sync_cursor_at']!,
          _syncCursorAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error_code')) {
      context.handle(
        _lastSyncErrorCodeMeta,
        lastSyncErrorCode.isAcceptableOrUnknown(
          data['last_sync_error_code']!,
          _lastSyncErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('remote_revision')) {
      context.handle(
        _remoteRevisionMeta,
        remoteRevision.isAcceptableOrUnknown(
          data['remote_revision']!,
          _remoteRevisionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId};
  @override
  AccountSyncSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountSyncSettingsRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
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
      lastSyncAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt_at'],
      ),
      syncCursorAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sync_cursor_at'],
      ),
      lastSyncErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error_code'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      remoteRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_revision'],
      )!,
    );
  }

  @override
  $AccountSyncSettingsTable createAlias(String alias) {
    return $AccountSyncSettingsTable(attachedDatabase, alias);
  }
}

class AccountSyncSettingsRow extends DataClass
    implements Insertable<AccountSyncSettingsRow> {
  final String ownerId;
  final bool? imageUploadConsent;
  final String? consentVersion;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? lastSyncAttemptAt;
  final DateTime? syncCursorAt;
  final String? lastSyncErrorCode;
  final String syncState;
  final int remoteRevision;
  const AccountSyncSettingsRow({
    required this.ownerId,
    this.imageUploadConsent,
    this.consentVersion,
    this.lastSuccessfulSyncAt,
    this.lastSyncAttemptAt,
    this.syncCursorAt,
    this.lastSyncErrorCode,
    required this.syncState,
    required this.remoteRevision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || imageUploadConsent != null) {
      map['image_upload_consent'] = Variable<bool>(imageUploadConsent);
    }
    if (!nullToAbsent || consentVersion != null) {
      map['consent_version'] = Variable<String>(consentVersion);
    }
    if (!nullToAbsent || lastSuccessfulSyncAt != null) {
      map['last_successful_sync_at'] = Variable<DateTime>(lastSuccessfulSyncAt);
    }
    if (!nullToAbsent || lastSyncAttemptAt != null) {
      map['last_sync_attempt_at'] = Variable<DateTime>(lastSyncAttemptAt);
    }
    if (!nullToAbsent || syncCursorAt != null) {
      map['sync_cursor_at'] = Variable<DateTime>(syncCursorAt);
    }
    if (!nullToAbsent || lastSyncErrorCode != null) {
      map['last_sync_error_code'] = Variable<String>(lastSyncErrorCode);
    }
    map['sync_state'] = Variable<String>(syncState);
    map['remote_revision'] = Variable<int>(remoteRevision);
    return map;
  }

  AccountSyncSettingsCompanion toCompanion(bool nullToAbsent) {
    return AccountSyncSettingsCompanion(
      ownerId: Value(ownerId),
      imageUploadConsent: imageUploadConsent == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUploadConsent),
      consentVersion: consentVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(consentVersion),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessfulSyncAt),
      lastSyncAttemptAt: lastSyncAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttemptAt),
      syncCursorAt: syncCursorAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncCursorAt),
      lastSyncErrorCode: lastSyncErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncErrorCode),
      syncState: Value(syncState),
      remoteRevision: Value(remoteRevision),
    );
  }

  factory AccountSyncSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountSyncSettingsRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      imageUploadConsent: serializer.fromJson<bool?>(
        json['imageUploadConsent'],
      ),
      consentVersion: serializer.fromJson<String?>(json['consentVersion']),
      lastSuccessfulSyncAt: serializer.fromJson<DateTime?>(
        json['lastSuccessfulSyncAt'],
      ),
      lastSyncAttemptAt: serializer.fromJson<DateTime?>(
        json['lastSyncAttemptAt'],
      ),
      syncCursorAt: serializer.fromJson<DateTime?>(json['syncCursorAt']),
      lastSyncErrorCode: serializer.fromJson<String?>(
        json['lastSyncErrorCode'],
      ),
      syncState: serializer.fromJson<String>(json['syncState']),
      remoteRevision: serializer.fromJson<int>(json['remoteRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'imageUploadConsent': serializer.toJson<bool?>(imageUploadConsent),
      'consentVersion': serializer.toJson<String?>(consentVersion),
      'lastSuccessfulSyncAt': serializer.toJson<DateTime?>(
        lastSuccessfulSyncAt,
      ),
      'lastSyncAttemptAt': serializer.toJson<DateTime?>(lastSyncAttemptAt),
      'syncCursorAt': serializer.toJson<DateTime?>(syncCursorAt),
      'lastSyncErrorCode': serializer.toJson<String?>(lastSyncErrorCode),
      'syncState': serializer.toJson<String>(syncState),
      'remoteRevision': serializer.toJson<int>(remoteRevision),
    };
  }

  AccountSyncSettingsRow copyWith({
    String? ownerId,
    Value<bool?> imageUploadConsent = const Value.absent(),
    Value<String?> consentVersion = const Value.absent(),
    Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
    Value<DateTime?> lastSyncAttemptAt = const Value.absent(),
    Value<DateTime?> syncCursorAt = const Value.absent(),
    Value<String?> lastSyncErrorCode = const Value.absent(),
    String? syncState,
    int? remoteRevision,
  }) => AccountSyncSettingsRow(
    ownerId: ownerId ?? this.ownerId,
    imageUploadConsent: imageUploadConsent.present
        ? imageUploadConsent.value
        : this.imageUploadConsent,
    consentVersion: consentVersion.present
        ? consentVersion.value
        : this.consentVersion,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt.present
        ? lastSuccessfulSyncAt.value
        : this.lastSuccessfulSyncAt,
    lastSyncAttemptAt: lastSyncAttemptAt.present
        ? lastSyncAttemptAt.value
        : this.lastSyncAttemptAt,
    syncCursorAt: syncCursorAt.present ? syncCursorAt.value : this.syncCursorAt,
    lastSyncErrorCode: lastSyncErrorCode.present
        ? lastSyncErrorCode.value
        : this.lastSyncErrorCode,
    syncState: syncState ?? this.syncState,
    remoteRevision: remoteRevision ?? this.remoteRevision,
  );
  AccountSyncSettingsRow copyWithCompanion(AccountSyncSettingsCompanion data) {
    return AccountSyncSettingsRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      imageUploadConsent: data.imageUploadConsent.present
          ? data.imageUploadConsent.value
          : this.imageUploadConsent,
      consentVersion: data.consentVersion.present
          ? data.consentVersion.value
          : this.consentVersion,
      lastSuccessfulSyncAt: data.lastSuccessfulSyncAt.present
          ? data.lastSuccessfulSyncAt.value
          : this.lastSuccessfulSyncAt,
      lastSyncAttemptAt: data.lastSyncAttemptAt.present
          ? data.lastSyncAttemptAt.value
          : this.lastSyncAttemptAt,
      syncCursorAt: data.syncCursorAt.present
          ? data.syncCursorAt.value
          : this.syncCursorAt,
      lastSyncErrorCode: data.lastSyncErrorCode.present
          ? data.lastSyncErrorCode.value
          : this.lastSyncErrorCode,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      remoteRevision: data.remoteRevision.present
          ? data.remoteRevision.value
          : this.remoteRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountSyncSettingsRow(')
          ..write('ownerId: $ownerId, ')
          ..write('imageUploadConsent: $imageUploadConsent, ')
          ..write('consentVersion: $consentVersion, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('lastSyncAttemptAt: $lastSyncAttemptAt, ')
          ..write('syncCursorAt: $syncCursorAt, ')
          ..write('lastSyncErrorCode: $lastSyncErrorCode, ')
          ..write('syncState: $syncState, ')
          ..write('remoteRevision: $remoteRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    imageUploadConsent,
    consentVersion,
    lastSuccessfulSyncAt,
    lastSyncAttemptAt,
    syncCursorAt,
    lastSyncErrorCode,
    syncState,
    remoteRevision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountSyncSettingsRow &&
          other.ownerId == this.ownerId &&
          other.imageUploadConsent == this.imageUploadConsent &&
          other.consentVersion == this.consentVersion &&
          other.lastSuccessfulSyncAt == this.lastSuccessfulSyncAt &&
          other.lastSyncAttemptAt == this.lastSyncAttemptAt &&
          other.syncCursorAt == this.syncCursorAt &&
          other.lastSyncErrorCode == this.lastSyncErrorCode &&
          other.syncState == this.syncState &&
          other.remoteRevision == this.remoteRevision);
}

class AccountSyncSettingsCompanion
    extends UpdateCompanion<AccountSyncSettingsRow> {
  final Value<String> ownerId;
  final Value<bool?> imageUploadConsent;
  final Value<String?> consentVersion;
  final Value<DateTime?> lastSuccessfulSyncAt;
  final Value<DateTime?> lastSyncAttemptAt;
  final Value<DateTime?> syncCursorAt;
  final Value<String?> lastSyncErrorCode;
  final Value<String> syncState;
  final Value<int> remoteRevision;
  final Value<int> rowid;
  const AccountSyncSettingsCompanion({
    this.ownerId = const Value.absent(),
    this.imageUploadConsent = const Value.absent(),
    this.consentVersion = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.lastSyncAttemptAt = const Value.absent(),
    this.syncCursorAt = const Value.absent(),
    this.lastSyncErrorCode = const Value.absent(),
    this.syncState = const Value.absent(),
    this.remoteRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountSyncSettingsCompanion.insert({
    required String ownerId,
    this.imageUploadConsent = const Value.absent(),
    this.consentVersion = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.lastSyncAttemptAt = const Value.absent(),
    this.syncCursorAt = const Value.absent(),
    this.lastSyncErrorCode = const Value.absent(),
    this.syncState = const Value.absent(),
    this.remoteRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId);
  static Insertable<AccountSyncSettingsRow> custom({
    Expression<String>? ownerId,
    Expression<bool>? imageUploadConsent,
    Expression<String>? consentVersion,
    Expression<DateTime>? lastSuccessfulSyncAt,
    Expression<DateTime>? lastSyncAttemptAt,
    Expression<DateTime>? syncCursorAt,
    Expression<String>? lastSyncErrorCode,
    Expression<String>? syncState,
    Expression<int>? remoteRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (imageUploadConsent != null)
        'image_upload_consent': imageUploadConsent,
      if (consentVersion != null) 'consent_version': consentVersion,
      if (lastSuccessfulSyncAt != null)
        'last_successful_sync_at': lastSuccessfulSyncAt,
      if (lastSyncAttemptAt != null) 'last_sync_attempt_at': lastSyncAttemptAt,
      if (syncCursorAt != null) 'sync_cursor_at': syncCursorAt,
      if (lastSyncErrorCode != null) 'last_sync_error_code': lastSyncErrorCode,
      if (syncState != null) 'sync_state': syncState,
      if (remoteRevision != null) 'remote_revision': remoteRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountSyncSettingsCompanion copyWith({
    Value<String>? ownerId,
    Value<bool?>? imageUploadConsent,
    Value<String?>? consentVersion,
    Value<DateTime?>? lastSuccessfulSyncAt,
    Value<DateTime?>? lastSyncAttemptAt,
    Value<DateTime?>? syncCursorAt,
    Value<String?>? lastSyncErrorCode,
    Value<String>? syncState,
    Value<int>? remoteRevision,
    Value<int>? rowid,
  }) {
    return AccountSyncSettingsCompanion(
      ownerId: ownerId ?? this.ownerId,
      imageUploadConsent: imageUploadConsent ?? this.imageUploadConsent,
      consentVersion: consentVersion ?? this.consentVersion,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      lastSyncAttemptAt: lastSyncAttemptAt ?? this.lastSyncAttemptAt,
      syncCursorAt: syncCursorAt ?? this.syncCursorAt,
      lastSyncErrorCode: lastSyncErrorCode ?? this.lastSyncErrorCode,
      syncState: syncState ?? this.syncState,
      remoteRevision: remoteRevision ?? this.remoteRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
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
    if (lastSyncAttemptAt.present) {
      map['last_sync_attempt_at'] = Variable<DateTime>(lastSyncAttemptAt.value);
    }
    if (syncCursorAt.present) {
      map['sync_cursor_at'] = Variable<DateTime>(syncCursorAt.value);
    }
    if (lastSyncErrorCode.present) {
      map['last_sync_error_code'] = Variable<String>(lastSyncErrorCode.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (remoteRevision.present) {
      map['remote_revision'] = Variable<int>(remoteRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountSyncSettingsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('imageUploadConsent: $imageUploadConsent, ')
          ..write('consentVersion: $consentVersion, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('lastSyncAttemptAt: $lastSyncAttemptAt, ')
          ..write('syncCursorAt: $syncCursorAt, ')
          ..write('lastSyncErrorCode: $lastSyncErrorCode, ')
          ..write('syncState: $syncState, ')
          ..write('remoteRevision: $remoteRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineWorkspaceStatesTable extends OfflineWorkspaceStates
    with TableInfo<$OfflineWorkspaceStatesTable, OfflineWorkspaceStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineWorkspaceStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installationIdMeta = const VerificationMeta(
    'installationId',
  );
  @override
  late final GeneratedColumn<String> installationId = GeneratedColumn<String>(
    'installation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generationMeta = const VerificationMeta(
    'generation',
  );
  @override
  late final GeneratedColumn<int> generation = GeneratedColumn<int>(
    'generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pendingReleaseMeta = const VerificationMeta(
    'pendingRelease',
  );
  @override
  late final GeneratedColumn<bool> pendingRelease = GeneratedColumn<bool>(
    'pending_release',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_release" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    installationId,
    generation,
    pendingRelease,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_workspace_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineWorkspaceStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('installation_id')) {
      context.handle(
        _installationIdMeta,
        installationId.isAcceptableOrUnknown(
          data['installation_id']!,
          _installationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installationIdMeta);
    }
    if (data.containsKey('generation')) {
      context.handle(
        _generationMeta,
        generation.isAcceptableOrUnknown(data['generation']!, _generationMeta),
      );
    }
    if (data.containsKey('pending_release')) {
      context.handle(
        _pendingReleaseMeta,
        pendingRelease.isAcceptableOrUnknown(
          data['pending_release']!,
          _pendingReleaseMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineWorkspaceStateRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineWorkspaceStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      installationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}installation_id'],
      )!,
      generation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generation'],
      )!,
      pendingRelease: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_release'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OfflineWorkspaceStatesTable createAlias(String alias) {
    return $OfflineWorkspaceStatesTable(attachedDatabase, alias);
  }
}

class OfflineWorkspaceStateRow extends DataClass
    implements Insertable<OfflineWorkspaceStateRow> {
  final String id;
  final String workspaceId;
  final String installationId;
  final int generation;
  final bool pendingRelease;
  final DateTime updatedAt;
  const OfflineWorkspaceStateRow({
    required this.id,
    required this.workspaceId,
    required this.installationId,
    required this.generation,
    required this.pendingRelease,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['installation_id'] = Variable<String>(installationId);
    map['generation'] = Variable<int>(generation);
    map['pending_release'] = Variable<bool>(pendingRelease);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OfflineWorkspaceStatesCompanion toCompanion(bool nullToAbsent) {
    return OfflineWorkspaceStatesCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      installationId: Value(installationId),
      generation: Value(generation),
      pendingRelease: Value(pendingRelease),
      updatedAt: Value(updatedAt),
    );
  }

  factory OfflineWorkspaceStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineWorkspaceStateRow(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      installationId: serializer.fromJson<String>(json['installationId']),
      generation: serializer.fromJson<int>(json['generation']),
      pendingRelease: serializer.fromJson<bool>(json['pendingRelease']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'installationId': serializer.toJson<String>(installationId),
      'generation': serializer.toJson<int>(generation),
      'pendingRelease': serializer.toJson<bool>(pendingRelease),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OfflineWorkspaceStateRow copyWith({
    String? id,
    String? workspaceId,
    String? installationId,
    int? generation,
    bool? pendingRelease,
    DateTime? updatedAt,
  }) => OfflineWorkspaceStateRow(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    installationId: installationId ?? this.installationId,
    generation: generation ?? this.generation,
    pendingRelease: pendingRelease ?? this.pendingRelease,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OfflineWorkspaceStateRow copyWithCompanion(
    OfflineWorkspaceStatesCompanion data,
  ) {
    return OfflineWorkspaceStateRow(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      installationId: data.installationId.present
          ? data.installationId.value
          : this.installationId,
      generation: data.generation.present
          ? data.generation.value
          : this.generation,
      pendingRelease: data.pendingRelease.present
          ? data.pendingRelease.value
          : this.pendingRelease,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineWorkspaceStateRow(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('installationId: $installationId, ')
          ..write('generation: $generation, ')
          ..write('pendingRelease: $pendingRelease, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    installationId,
    generation,
    pendingRelease,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineWorkspaceStateRow &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.installationId == this.installationId &&
          other.generation == this.generation &&
          other.pendingRelease == this.pendingRelease &&
          other.updatedAt == this.updatedAt);
}

class OfflineWorkspaceStatesCompanion
    extends UpdateCompanion<OfflineWorkspaceStateRow> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> installationId;
  final Value<int> generation;
  final Value<bool> pendingRelease;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OfflineWorkspaceStatesCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.installationId = const Value.absent(),
    this.generation = const Value.absent(),
    this.pendingRelease = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineWorkspaceStatesCompanion.insert({
    required String id,
    required String workspaceId,
    required String installationId,
    this.generation = const Value.absent(),
    this.pendingRelease = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       installationId = Value(installationId),
       updatedAt = Value(updatedAt);
  static Insertable<OfflineWorkspaceStateRow> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? installationId,
    Expression<int>? generation,
    Expression<bool>? pendingRelease,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (installationId != null) 'installation_id': installationId,
      if (generation != null) 'generation': generation,
      if (pendingRelease != null) 'pending_release': pendingRelease,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineWorkspaceStatesCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? installationId,
    Value<int>? generation,
    Value<bool>? pendingRelease,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OfflineWorkspaceStatesCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      installationId: installationId ?? this.installationId,
      generation: generation ?? this.generation,
      pendingRelease: pendingRelease ?? this.pendingRelease,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (installationId.present) {
      map['installation_id'] = Variable<String>(installationId.value);
    }
    if (generation.present) {
      map['generation'] = Variable<int>(generation.value);
    }
    if (pendingRelease.present) {
      map['pending_release'] = Variable<bool>(pendingRelease.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineWorkspaceStatesCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('installationId: $installationId, ')
          ..write('generation: $generation, ')
          ..write('pendingRelease: $pendingRelease, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DetachedEntityOriginsTable extends DetachedEntityOrigins
    with TableInfo<$DetachedEntityOriginsTable, DetachedEntityOriginRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DetachedEntityOriginsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generationMeta = const VerificationMeta(
    'generation',
  );
  @override
  late final GeneratedColumn<int> generation = GeneratedColumn<int>(
    'generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _guestEntityIdMeta = const VerificationMeta(
    'guestEntityId',
  );
  @override
  late final GeneratedColumn<String> guestEntityId = GeneratedColumn<String>(
    'guest_entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalOwnerIdMeta = const VerificationMeta(
    'originalOwnerId',
  );
  @override
  late final GeneratedColumn<String> originalOwnerId = GeneratedColumn<String>(
    'original_owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalEntityIdMeta = const VerificationMeta(
    'originalEntityId',
  );
  @override
  late final GeneratedColumn<String> originalEntityId = GeneratedColumn<String>(
    'original_entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalRemoteRevisionMeta =
      const VerificationMeta('originalRemoteRevision');
  @override
  late final GeneratedColumn<int> originalRemoteRevision = GeneratedColumn<int>(
    'original_remote_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detachedAtMeta = const VerificationMeta(
    'detachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detachedAt = GeneratedColumn<DateTime>(
    'detached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    generation,
    entityType,
    guestEntityId,
    originalOwnerId,
    originalEntityId,
    originalRemoteRevision,
    detachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'detached_entity_origins';
  @override
  VerificationContext validateIntegrity(
    Insertable<DetachedEntityOriginRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('generation')) {
      context.handle(
        _generationMeta,
        generation.isAcceptableOrUnknown(data['generation']!, _generationMeta),
      );
    } else if (isInserting) {
      context.missing(_generationMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('guest_entity_id')) {
      context.handle(
        _guestEntityIdMeta,
        guestEntityId.isAcceptableOrUnknown(
          data['guest_entity_id']!,
          _guestEntityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_guestEntityIdMeta);
    }
    if (data.containsKey('original_owner_id')) {
      context.handle(
        _originalOwnerIdMeta,
        originalOwnerId.isAcceptableOrUnknown(
          data['original_owner_id']!,
          _originalOwnerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalOwnerIdMeta);
    }
    if (data.containsKey('original_entity_id')) {
      context.handle(
        _originalEntityIdMeta,
        originalEntityId.isAcceptableOrUnknown(
          data['original_entity_id']!,
          _originalEntityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalEntityIdMeta);
    }
    if (data.containsKey('original_remote_revision')) {
      context.handle(
        _originalRemoteRevisionMeta,
        originalRemoteRevision.isAcceptableOrUnknown(
          data['original_remote_revision']!,
          _originalRemoteRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalRemoteRevisionMeta);
    }
    if (data.containsKey('detached_at')) {
      context.handle(
        _detachedAtMeta,
        detachedAt.isAcceptableOrUnknown(data['detached_at']!, _detachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_detachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DetachedEntityOriginRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DetachedEntityOriginRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      generation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generation'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      guestEntityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guest_entity_id'],
      )!,
      originalOwnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_owner_id'],
      )!,
      originalEntityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_entity_id'],
      )!,
      originalRemoteRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_remote_revision'],
      )!,
      detachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detached_at'],
      )!,
    );
  }

  @override
  $DetachedEntityOriginsTable createAlias(String alias) {
    return $DetachedEntityOriginsTable(attachedDatabase, alias);
  }
}

class DetachedEntityOriginRow extends DataClass
    implements Insertable<DetachedEntityOriginRow> {
  final String id;
  final String workspaceId;
  final int generation;
  final String entityType;
  final String guestEntityId;
  final String originalOwnerId;
  final String originalEntityId;
  final int originalRemoteRevision;
  final DateTime detachedAt;
  const DetachedEntityOriginRow({
    required this.id,
    required this.workspaceId,
    required this.generation,
    required this.entityType,
    required this.guestEntityId,
    required this.originalOwnerId,
    required this.originalEntityId,
    required this.originalRemoteRevision,
    required this.detachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['generation'] = Variable<int>(generation);
    map['entity_type'] = Variable<String>(entityType);
    map['guest_entity_id'] = Variable<String>(guestEntityId);
    map['original_owner_id'] = Variable<String>(originalOwnerId);
    map['original_entity_id'] = Variable<String>(originalEntityId);
    map['original_remote_revision'] = Variable<int>(originalRemoteRevision);
    map['detached_at'] = Variable<DateTime>(detachedAt);
    return map;
  }

  DetachedEntityOriginsCompanion toCompanion(bool nullToAbsent) {
    return DetachedEntityOriginsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      generation: Value(generation),
      entityType: Value(entityType),
      guestEntityId: Value(guestEntityId),
      originalOwnerId: Value(originalOwnerId),
      originalEntityId: Value(originalEntityId),
      originalRemoteRevision: Value(originalRemoteRevision),
      detachedAt: Value(detachedAt),
    );
  }

  factory DetachedEntityOriginRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DetachedEntityOriginRow(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      generation: serializer.fromJson<int>(json['generation']),
      entityType: serializer.fromJson<String>(json['entityType']),
      guestEntityId: serializer.fromJson<String>(json['guestEntityId']),
      originalOwnerId: serializer.fromJson<String>(json['originalOwnerId']),
      originalEntityId: serializer.fromJson<String>(json['originalEntityId']),
      originalRemoteRevision: serializer.fromJson<int>(
        json['originalRemoteRevision'],
      ),
      detachedAt: serializer.fromJson<DateTime>(json['detachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'generation': serializer.toJson<int>(generation),
      'entityType': serializer.toJson<String>(entityType),
      'guestEntityId': serializer.toJson<String>(guestEntityId),
      'originalOwnerId': serializer.toJson<String>(originalOwnerId),
      'originalEntityId': serializer.toJson<String>(originalEntityId),
      'originalRemoteRevision': serializer.toJson<int>(originalRemoteRevision),
      'detachedAt': serializer.toJson<DateTime>(detachedAt),
    };
  }

  DetachedEntityOriginRow copyWith({
    String? id,
    String? workspaceId,
    int? generation,
    String? entityType,
    String? guestEntityId,
    String? originalOwnerId,
    String? originalEntityId,
    int? originalRemoteRevision,
    DateTime? detachedAt,
  }) => DetachedEntityOriginRow(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    generation: generation ?? this.generation,
    entityType: entityType ?? this.entityType,
    guestEntityId: guestEntityId ?? this.guestEntityId,
    originalOwnerId: originalOwnerId ?? this.originalOwnerId,
    originalEntityId: originalEntityId ?? this.originalEntityId,
    originalRemoteRevision:
        originalRemoteRevision ?? this.originalRemoteRevision,
    detachedAt: detachedAt ?? this.detachedAt,
  );
  DetachedEntityOriginRow copyWithCompanion(
    DetachedEntityOriginsCompanion data,
  ) {
    return DetachedEntityOriginRow(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      generation: data.generation.present
          ? data.generation.value
          : this.generation,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      guestEntityId: data.guestEntityId.present
          ? data.guestEntityId.value
          : this.guestEntityId,
      originalOwnerId: data.originalOwnerId.present
          ? data.originalOwnerId.value
          : this.originalOwnerId,
      originalEntityId: data.originalEntityId.present
          ? data.originalEntityId.value
          : this.originalEntityId,
      originalRemoteRevision: data.originalRemoteRevision.present
          ? data.originalRemoteRevision.value
          : this.originalRemoteRevision,
      detachedAt: data.detachedAt.present
          ? data.detachedAt.value
          : this.detachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DetachedEntityOriginRow(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('generation: $generation, ')
          ..write('entityType: $entityType, ')
          ..write('guestEntityId: $guestEntityId, ')
          ..write('originalOwnerId: $originalOwnerId, ')
          ..write('originalEntityId: $originalEntityId, ')
          ..write('originalRemoteRevision: $originalRemoteRevision, ')
          ..write('detachedAt: $detachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    generation,
    entityType,
    guestEntityId,
    originalOwnerId,
    originalEntityId,
    originalRemoteRevision,
    detachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DetachedEntityOriginRow &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.generation == this.generation &&
          other.entityType == this.entityType &&
          other.guestEntityId == this.guestEntityId &&
          other.originalOwnerId == this.originalOwnerId &&
          other.originalEntityId == this.originalEntityId &&
          other.originalRemoteRevision == this.originalRemoteRevision &&
          other.detachedAt == this.detachedAt);
}

class DetachedEntityOriginsCompanion
    extends UpdateCompanion<DetachedEntityOriginRow> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<int> generation;
  final Value<String> entityType;
  final Value<String> guestEntityId;
  final Value<String> originalOwnerId;
  final Value<String> originalEntityId;
  final Value<int> originalRemoteRevision;
  final Value<DateTime> detachedAt;
  final Value<int> rowid;
  const DetachedEntityOriginsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.generation = const Value.absent(),
    this.entityType = const Value.absent(),
    this.guestEntityId = const Value.absent(),
    this.originalOwnerId = const Value.absent(),
    this.originalEntityId = const Value.absent(),
    this.originalRemoteRevision = const Value.absent(),
    this.detachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DetachedEntityOriginsCompanion.insert({
    required String id,
    required String workspaceId,
    required int generation,
    required String entityType,
    required String guestEntityId,
    required String originalOwnerId,
    required String originalEntityId,
    required int originalRemoteRevision,
    required DateTime detachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       generation = Value(generation),
       entityType = Value(entityType),
       guestEntityId = Value(guestEntityId),
       originalOwnerId = Value(originalOwnerId),
       originalEntityId = Value(originalEntityId),
       originalRemoteRevision = Value(originalRemoteRevision),
       detachedAt = Value(detachedAt);
  static Insertable<DetachedEntityOriginRow> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<int>? generation,
    Expression<String>? entityType,
    Expression<String>? guestEntityId,
    Expression<String>? originalOwnerId,
    Expression<String>? originalEntityId,
    Expression<int>? originalRemoteRevision,
    Expression<DateTime>? detachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (generation != null) 'generation': generation,
      if (entityType != null) 'entity_type': entityType,
      if (guestEntityId != null) 'guest_entity_id': guestEntityId,
      if (originalOwnerId != null) 'original_owner_id': originalOwnerId,
      if (originalEntityId != null) 'original_entity_id': originalEntityId,
      if (originalRemoteRevision != null)
        'original_remote_revision': originalRemoteRevision,
      if (detachedAt != null) 'detached_at': detachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DetachedEntityOriginsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<int>? generation,
    Value<String>? entityType,
    Value<String>? guestEntityId,
    Value<String>? originalOwnerId,
    Value<String>? originalEntityId,
    Value<int>? originalRemoteRevision,
    Value<DateTime>? detachedAt,
    Value<int>? rowid,
  }) {
    return DetachedEntityOriginsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      generation: generation ?? this.generation,
      entityType: entityType ?? this.entityType,
      guestEntityId: guestEntityId ?? this.guestEntityId,
      originalOwnerId: originalOwnerId ?? this.originalOwnerId,
      originalEntityId: originalEntityId ?? this.originalEntityId,
      originalRemoteRevision:
          originalRemoteRevision ?? this.originalRemoteRevision,
      detachedAt: detachedAt ?? this.detachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (generation.present) {
      map['generation'] = Variable<int>(generation.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (guestEntityId.present) {
      map['guest_entity_id'] = Variable<String>(guestEntityId.value);
    }
    if (originalOwnerId.present) {
      map['original_owner_id'] = Variable<String>(originalOwnerId.value);
    }
    if (originalEntityId.present) {
      map['original_entity_id'] = Variable<String>(originalEntityId.value);
    }
    if (originalRemoteRevision.present) {
      map['original_remote_revision'] = Variable<int>(
        originalRemoteRevision.value,
      );
    }
    if (detachedAt.present) {
      map['detached_at'] = Variable<DateTime>(detachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DetachedEntityOriginsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('generation: $generation, ')
          ..write('entityType: $entityType, ')
          ..write('guestEntityId: $guestEntityId, ')
          ..write('originalOwnerId: $originalOwnerId, ')
          ..write('originalEntityId: $originalEntityId, ')
          ..write('originalRemoteRevision: $originalRemoteRevision, ')
          ..write('detachedAt: $detachedAt, ')
          ..write('rowid: $rowid')
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
  late final $AccountSyncSettingsTable accountSyncSettings =
      $AccountSyncSettingsTable(this);
  late final $OfflineWorkspaceStatesTable offlineWorkspaceStates =
      $OfflineWorkspaceStatesTable(this);
  late final $DetachedEntityOriginsTable detachedEntityOrigins =
      $DetachedEntityOriginsTable(this);
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
  late final Index detachedEntityOriginsWorkspaceIdx = Index(
    'detached_entity_origins_workspace_idx',
    'CREATE INDEX detached_entity_origins_workspace_idx ON detached_entity_origins (workspace_id, generation)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    batches,
    scanRecords,
    orders,
    accountSyncSettings,
    offlineWorkspaceStates,
    detachedEntityOrigins,
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
    detachedEntityOriginsWorkspaceIdx,
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
      Value<int> remoteRevision,
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
      Value<int> remoteRevision,
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

  ColumnFilters<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
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

  ColumnOrderings<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
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

  GeneratedColumn<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => column,
  );

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
                Value<int> remoteRevision = const Value.absent(),
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
                remoteRevision: remoteRevision,
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
                Value<int> remoteRevision = const Value.absent(),
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
                remoteRevision: remoteRevision,
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
      Value<int> remoteRevision,
      Value<String> imageSyncState,
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
      Value<int> remoteRevision,
      Value<String> imageSyncState,
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

  ColumnFilters<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageSyncState => $composableBuilder(
    column: $table.imageSyncState,
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

  ColumnOrderings<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageSyncState => $composableBuilder(
    column: $table.imageSyncState,
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

  GeneratedColumn<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageSyncState => $composableBuilder(
    column: $table.imageSyncState,
    builder: (column) => column,
  );

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
                Value<int> remoteRevision = const Value.absent(),
                Value<String> imageSyncState = const Value.absent(),
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
                remoteRevision: remoteRevision,
                imageSyncState: imageSyncState,
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
                Value<int> remoteRevision = const Value.absent(),
                Value<String> imageSyncState = const Value.absent(),
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
                remoteRevision: remoteRevision,
                imageSyncState: imageSyncState,
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
      Value<int> remoteRevision,
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
      Value<int> remoteRevision,
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

  ColumnFilters<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
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

  ColumnOrderings<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
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

  GeneratedColumn<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => column,
  );

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
                Value<int> remoteRevision = const Value.absent(),
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
                remoteRevision: remoteRevision,
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
                Value<int> remoteRevision = const Value.absent(),
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
                remoteRevision: remoteRevision,
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
typedef $$AccountSyncSettingsTableCreateCompanionBuilder =
    AccountSyncSettingsCompanion Function({
      required String ownerId,
      Value<bool?> imageUploadConsent,
      Value<String?> consentVersion,
      Value<DateTime?> lastSuccessfulSyncAt,
      Value<DateTime?> lastSyncAttemptAt,
      Value<DateTime?> syncCursorAt,
      Value<String?> lastSyncErrorCode,
      Value<String> syncState,
      Value<int> remoteRevision,
      Value<int> rowid,
    });
typedef $$AccountSyncSettingsTableUpdateCompanionBuilder =
    AccountSyncSettingsCompanion Function({
      Value<String> ownerId,
      Value<bool?> imageUploadConsent,
      Value<String?> consentVersion,
      Value<DateTime?> lastSuccessfulSyncAt,
      Value<DateTime?> lastSyncAttemptAt,
      Value<DateTime?> syncCursorAt,
      Value<String?> lastSyncErrorCode,
      Value<String> syncState,
      Value<int> remoteRevision,
      Value<int> rowid,
    });

class $$AccountSyncSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountSyncSettingsTable> {
  $$AccountSyncSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
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

  ColumnFilters<DateTime> get lastSyncAttemptAt => $composableBuilder(
    column: $table.lastSyncAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncCursorAt => $composableBuilder(
    column: $table.syncCursorAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncErrorCode => $composableBuilder(
    column: $table.lastSyncErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountSyncSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountSyncSettingsTable> {
  $$AccountSyncSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
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

  ColumnOrderings<DateTime> get lastSyncAttemptAt => $composableBuilder(
    column: $table.lastSyncAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncCursorAt => $composableBuilder(
    column: $table.syncCursorAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncErrorCode => $composableBuilder(
    column: $table.lastSyncErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountSyncSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountSyncSettingsTable> {
  $$AccountSyncSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

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

  GeneratedColumn<DateTime> get lastSyncAttemptAt => $composableBuilder(
    column: $table.lastSyncAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncCursorAt => $composableBuilder(
    column: $table.syncCursorAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncErrorCode => $composableBuilder(
    column: $table.lastSyncErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => column,
  );
}

class $$AccountSyncSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountSyncSettingsTable,
          AccountSyncSettingsRow,
          $$AccountSyncSettingsTableFilterComposer,
          $$AccountSyncSettingsTableOrderingComposer,
          $$AccountSyncSettingsTableAnnotationComposer,
          $$AccountSyncSettingsTableCreateCompanionBuilder,
          $$AccountSyncSettingsTableUpdateCompanionBuilder,
          (
            AccountSyncSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $AccountSyncSettingsTable,
              AccountSyncSettingsRow
            >,
          ),
          AccountSyncSettingsRow,
          PrefetchHooks Function()
        > {
  $$AccountSyncSettingsTableTableManager(
    _$AppDatabase db,
    $AccountSyncSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountSyncSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountSyncSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AccountSyncSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<bool?> imageUploadConsent = const Value.absent(),
                Value<String?> consentVersion = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                Value<DateTime?> lastSyncAttemptAt = const Value.absent(),
                Value<DateTime?> syncCursorAt = const Value.absent(),
                Value<String?> lastSyncErrorCode = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> remoteRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountSyncSettingsCompanion(
                ownerId: ownerId,
                imageUploadConsent: imageUploadConsent,
                consentVersion: consentVersion,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                lastSyncAttemptAt: lastSyncAttemptAt,
                syncCursorAt: syncCursorAt,
                lastSyncErrorCode: lastSyncErrorCode,
                syncState: syncState,
                remoteRevision: remoteRevision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                Value<bool?> imageUploadConsent = const Value.absent(),
                Value<String?> consentVersion = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                Value<DateTime?> lastSyncAttemptAt = const Value.absent(),
                Value<DateTime?> syncCursorAt = const Value.absent(),
                Value<String?> lastSyncErrorCode = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> remoteRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountSyncSettingsCompanion.insert(
                ownerId: ownerId,
                imageUploadConsent: imageUploadConsent,
                consentVersion: consentVersion,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                lastSyncAttemptAt: lastSyncAttemptAt,
                syncCursorAt: syncCursorAt,
                lastSyncErrorCode: lastSyncErrorCode,
                syncState: syncState,
                remoteRevision: remoteRevision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountSyncSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountSyncSettingsTable,
      AccountSyncSettingsRow,
      $$AccountSyncSettingsTableFilterComposer,
      $$AccountSyncSettingsTableOrderingComposer,
      $$AccountSyncSettingsTableAnnotationComposer,
      $$AccountSyncSettingsTableCreateCompanionBuilder,
      $$AccountSyncSettingsTableUpdateCompanionBuilder,
      (
        AccountSyncSettingsRow,
        BaseReferences<
          _$AppDatabase,
          $AccountSyncSettingsTable,
          AccountSyncSettingsRow
        >,
      ),
      AccountSyncSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$OfflineWorkspaceStatesTableCreateCompanionBuilder =
    OfflineWorkspaceStatesCompanion Function({
      required String id,
      required String workspaceId,
      required String installationId,
      Value<int> generation,
      Value<bool> pendingRelease,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$OfflineWorkspaceStatesTableUpdateCompanionBuilder =
    OfflineWorkspaceStatesCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> installationId,
      Value<int> generation,
      Value<bool> pendingRelease,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$OfflineWorkspaceStatesTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineWorkspaceStatesTable> {
  $$OfflineWorkspaceStatesTableFilterComposer({
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

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingRelease => $composableBuilder(
    column: $table.pendingRelease,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineWorkspaceStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineWorkspaceStatesTable> {
  $$OfflineWorkspaceStatesTableOrderingComposer({
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

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingRelease => $composableBuilder(
    column: $table.pendingRelease,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineWorkspaceStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineWorkspaceStatesTable> {
  $$OfflineWorkspaceStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pendingRelease => $composableBuilder(
    column: $table.pendingRelease,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OfflineWorkspaceStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineWorkspaceStatesTable,
          OfflineWorkspaceStateRow,
          $$OfflineWorkspaceStatesTableFilterComposer,
          $$OfflineWorkspaceStatesTableOrderingComposer,
          $$OfflineWorkspaceStatesTableAnnotationComposer,
          $$OfflineWorkspaceStatesTableCreateCompanionBuilder,
          $$OfflineWorkspaceStatesTableUpdateCompanionBuilder,
          (
            OfflineWorkspaceStateRow,
            BaseReferences<
              _$AppDatabase,
              $OfflineWorkspaceStatesTable,
              OfflineWorkspaceStateRow
            >,
          ),
          OfflineWorkspaceStateRow,
          PrefetchHooks Function()
        > {
  $$OfflineWorkspaceStatesTableTableManager(
    _$AppDatabase db,
    $OfflineWorkspaceStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineWorkspaceStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$OfflineWorkspaceStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OfflineWorkspaceStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> installationId = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<bool> pendingRelease = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineWorkspaceStatesCompanion(
                id: id,
                workspaceId: workspaceId,
                installationId: installationId,
                generation: generation,
                pendingRelease: pendingRelease,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String installationId,
                Value<int> generation = const Value.absent(),
                Value<bool> pendingRelease = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OfflineWorkspaceStatesCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                installationId: installationId,
                generation: generation,
                pendingRelease: pendingRelease,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineWorkspaceStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineWorkspaceStatesTable,
      OfflineWorkspaceStateRow,
      $$OfflineWorkspaceStatesTableFilterComposer,
      $$OfflineWorkspaceStatesTableOrderingComposer,
      $$OfflineWorkspaceStatesTableAnnotationComposer,
      $$OfflineWorkspaceStatesTableCreateCompanionBuilder,
      $$OfflineWorkspaceStatesTableUpdateCompanionBuilder,
      (
        OfflineWorkspaceStateRow,
        BaseReferences<
          _$AppDatabase,
          $OfflineWorkspaceStatesTable,
          OfflineWorkspaceStateRow
        >,
      ),
      OfflineWorkspaceStateRow,
      PrefetchHooks Function()
    >;
typedef $$DetachedEntityOriginsTableCreateCompanionBuilder =
    DetachedEntityOriginsCompanion Function({
      required String id,
      required String workspaceId,
      required int generation,
      required String entityType,
      required String guestEntityId,
      required String originalOwnerId,
      required String originalEntityId,
      required int originalRemoteRevision,
      required DateTime detachedAt,
      Value<int> rowid,
    });
typedef $$DetachedEntityOriginsTableUpdateCompanionBuilder =
    DetachedEntityOriginsCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<int> generation,
      Value<String> entityType,
      Value<String> guestEntityId,
      Value<String> originalOwnerId,
      Value<String> originalEntityId,
      Value<int> originalRemoteRevision,
      Value<DateTime> detachedAt,
      Value<int> rowid,
    });

class $$DetachedEntityOriginsTableFilterComposer
    extends Composer<_$AppDatabase, $DetachedEntityOriginsTable> {
  $$DetachedEntityOriginsTableFilterComposer({
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

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guestEntityId => $composableBuilder(
    column: $table.guestEntityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalOwnerId => $composableBuilder(
    column: $table.originalOwnerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalEntityId => $composableBuilder(
    column: $table.originalEntityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalRemoteRevision => $composableBuilder(
    column: $table.originalRemoteRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detachedAt => $composableBuilder(
    column: $table.detachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DetachedEntityOriginsTableOrderingComposer
    extends Composer<_$AppDatabase, $DetachedEntityOriginsTable> {
  $$DetachedEntityOriginsTableOrderingComposer({
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

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guestEntityId => $composableBuilder(
    column: $table.guestEntityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalOwnerId => $composableBuilder(
    column: $table.originalOwnerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalEntityId => $composableBuilder(
    column: $table.originalEntityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalRemoteRevision => $composableBuilder(
    column: $table.originalRemoteRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detachedAt => $composableBuilder(
    column: $table.detachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DetachedEntityOriginsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DetachedEntityOriginsTable> {
  $$DetachedEntityOriginsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get guestEntityId => $composableBuilder(
    column: $table.guestEntityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalOwnerId => $composableBuilder(
    column: $table.originalOwnerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalEntityId => $composableBuilder(
    column: $table.originalEntityId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalRemoteRevision => $composableBuilder(
    column: $table.originalRemoteRevision,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get detachedAt => $composableBuilder(
    column: $table.detachedAt,
    builder: (column) => column,
  );
}

class $$DetachedEntityOriginsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DetachedEntityOriginsTable,
          DetachedEntityOriginRow,
          $$DetachedEntityOriginsTableFilterComposer,
          $$DetachedEntityOriginsTableOrderingComposer,
          $$DetachedEntityOriginsTableAnnotationComposer,
          $$DetachedEntityOriginsTableCreateCompanionBuilder,
          $$DetachedEntityOriginsTableUpdateCompanionBuilder,
          (
            DetachedEntityOriginRow,
            BaseReferences<
              _$AppDatabase,
              $DetachedEntityOriginsTable,
              DetachedEntityOriginRow
            >,
          ),
          DetachedEntityOriginRow,
          PrefetchHooks Function()
        > {
  $$DetachedEntityOriginsTableTableManager(
    _$AppDatabase db,
    $DetachedEntityOriginsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DetachedEntityOriginsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DetachedEntityOriginsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DetachedEntityOriginsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> guestEntityId = const Value.absent(),
                Value<String> originalOwnerId = const Value.absent(),
                Value<String> originalEntityId = const Value.absent(),
                Value<int> originalRemoteRevision = const Value.absent(),
                Value<DateTime> detachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DetachedEntityOriginsCompanion(
                id: id,
                workspaceId: workspaceId,
                generation: generation,
                entityType: entityType,
                guestEntityId: guestEntityId,
                originalOwnerId: originalOwnerId,
                originalEntityId: originalEntityId,
                originalRemoteRevision: originalRemoteRevision,
                detachedAt: detachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required int generation,
                required String entityType,
                required String guestEntityId,
                required String originalOwnerId,
                required String originalEntityId,
                required int originalRemoteRevision,
                required DateTime detachedAt,
                Value<int> rowid = const Value.absent(),
              }) => DetachedEntityOriginsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                generation: generation,
                entityType: entityType,
                guestEntityId: guestEntityId,
                originalOwnerId: originalOwnerId,
                originalEntityId: originalEntityId,
                originalRemoteRevision: originalRemoteRevision,
                detachedAt: detachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DetachedEntityOriginsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DetachedEntityOriginsTable,
      DetachedEntityOriginRow,
      $$DetachedEntityOriginsTableFilterComposer,
      $$DetachedEntityOriginsTableOrderingComposer,
      $$DetachedEntityOriginsTableAnnotationComposer,
      $$DetachedEntityOriginsTableCreateCompanionBuilder,
      $$DetachedEntityOriginsTableUpdateCompanionBuilder,
      (
        DetachedEntityOriginRow,
        BaseReferences<
          _$AppDatabase,
          $DetachedEntityOriginsTable,
          DetachedEntityOriginRow
        >,
      ),
      DetachedEntityOriginRow,
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
  $$AccountSyncSettingsTableTableManager get accountSyncSettings =>
      $$AccountSyncSettingsTableTableManager(_db, _db.accountSyncSettings);
  $$OfflineWorkspaceStatesTableTableManager get offlineWorkspaceStates =>
      $$OfflineWorkspaceStatesTableTableManager(
        _db,
        _db.offlineWorkspaceStates,
      );
  $$DetachedEntityOriginsTableTableManager get detachedEntityOrigins =>
      $$DetachedEntityOriginsTableTableManager(_db, _db.detachedEntityOrigins);
}
