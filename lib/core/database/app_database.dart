import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:kami/core/persistence/persistence_codecs.dart';

part 'app_database.g.dart';

@DataClassName('BatchRow')
@TableIndex(name: 'batches_owner_idx', columns: {#ownerId})
@TableIndex(name: 'batches_updated_idx', columns: {#updatedAt})
@TableIndex(
  name: 'batches_active_page_idx',
  columns: {#deletedAt, #createdAt, #id},
)
class Batches extends Table {
  late final TextColumn id = text()();
  late final TextColumn ownerId = text().nullable()();
  late final TextColumn name = text().withLength(min: 1, max: 120)();
  late final TextColumn fruitType = text().check(
    fruitType.isIn(PersistenceCodecs.fruitCodes),
  )();
  late final DateTimeColumn createdAt = dateTime()();
  late final DateTimeColumn updatedAt = dateTime()();
  late final DateTimeColumn deletedAt = dateTime().nullable()();
  late final TextColumn syncState = text()
      .check(syncState.isIn(PersistenceCodecs.syncStateCodes))
      .withDefault(const Constant('local_only'))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(name)) > 0)',
    'CHECK (updated_at >= created_at)',
    'CHECK (deleted_at IS NULL OR deleted_at >= created_at)',
  ];
}

@DataClassName('ScanRecordRow')
@TableIndex(name: 'scan_records_owner_idx', columns: {#ownerId})
@TableIndex(name: 'scan_records_batch_idx', columns: {#batchId})
@TableIndex(name: 'scan_records_created_idx', columns: {#createdAt})
@TableIndex(name: 'scan_records_updated_idx', columns: {#updatedAt})
@TableIndex(
  name: 'scan_records_active_page_idx',
  columns: {#deletedAt, #createdAt, #id},
)
@TableIndex(
  name: 'scan_records_batch_page_idx',
  columns: {#batchId, #deletedAt, #createdAt, #id},
)
class ScanRecords extends Table {
  late final TextColumn id = text()();
  late final TextColumn ownerId = text().nullable()();
  late final TextColumn batchId = text().nullable().references(
    Batches,
    #id,
    onDelete: KeyAction.noAction,
  )();
  late final TextColumn fruitType = text().check(
    fruitType.isIn(PersistenceCodecs.fruitCodes),
  )();
  late final TextColumn ripenessStage = text().check(
    ripenessStage.isIn(PersistenceCodecs.ripenessCodes),
  )();
  late final RealColumn modelConfidence = real().check(
    modelConfidence.isBetweenValues(0, 1),
  )();
  late final TextColumn modelVersion = text().withLength(min: 1, max: 120)();
  late final TextColumn resultOrigin = text()
      .check(resultOrigin.isIn(PersistenceCodecs.resultOriginCodes))
      .withDefault(const Constant('demo'))();
  late final TextColumn shelfLifeStatus = text().check(
    shelfLifeStatus.isIn(const {
      PersistenceCodecs.shelfLifeAvailable,
      PersistenceCodecs.shelfLifeUnavailable,
    }),
  )();
  late final IntColumn shelfLifeMinimum = integer().nullable()();
  late final IntColumn shelfLifeMaximum = integer().nullable()();
  late final TextColumn shelfLifeUnit = text().nullable()();
  late final TextColumn shelfLifeGuidance = text().nullable()();
  late final TextColumn shelfLifeReason = text().nullable()();
  late final TextColumn shelfLifeEvidenceVersion = text()();
  late final TextColumn localImageRelativePath = text().nullable()();
  late final TextColumn remoteImageKey = text().nullable()();
  late final DateTimeColumn createdAt = dateTime()();
  late final DateTimeColumn updatedAt = dateTime()();
  late final DateTimeColumn deletedAt = dateTime().nullable()();
  late final TextColumn syncState = text()
      .check(syncState.isIn(PersistenceCodecs.syncStateCodes))
      .withDefault(const Constant('local_only'))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    '''CHECK (
      (shelf_life_status = 'available'
        AND shelf_life_minimum IS NOT NULL
        AND shelf_life_minimum >= 0
        AND shelf_life_maximum IS NOT NULL
        AND shelf_life_maximum >= shelf_life_minimum
        AND shelf_life_unit IS NOT NULL
        AND length(trim(shelf_life_unit)) > 0
        AND shelf_life_guidance IS NOT NULL
        AND length(trim(shelf_life_guidance)) > 0
        AND shelf_life_reason IS NULL)
      OR
      (shelf_life_status = 'unavailable'
        AND shelf_life_minimum IS NULL
        AND shelf_life_maximum IS NULL
        AND shelf_life_unit IS NULL
        AND shelf_life_guidance IS NULL
        AND shelf_life_reason IS NOT NULL
        AND length(trim(shelf_life_reason)) > 0)
    )''',
    'CHECK (length(trim(model_version)) > 0)',
    'CHECK (length(trim(shelf_life_evidence_version)) > 0)',
    '''CHECK (
      local_image_relative_path IS NULL
      OR length(trim(local_image_relative_path)) > 0
    )''',
    'CHECK (remote_image_key IS NULL OR length(trim(remote_image_key)) > 0)',
    'CHECK (updated_at >= created_at)',
    'CHECK (deleted_at IS NULL OR deleted_at >= created_at)',
  ];
}

@DataClassName('OrderRow')
@TableIndex(name: 'orders_owner_idx', columns: {#ownerId})
@TableIndex(name: 'orders_updated_idx', columns: {#updatedAt})
class Orders extends Table {
  late final TextColumn id = text()();
  late final TextColumn ownerId = text().nullable()();
  late final TextColumn batchId = text().references(
    Batches,
    #id,
    onDelete: KeyAction.noAction,
  )();
  late final TextColumn customerName = text().withLength(min: 1, max: 160)();
  late final TextColumn deliveryAddress = text().withLength(min: 1, max: 500)();
  late final DateTimeColumn deliveryDate = dateTime()();
  late final TextColumn status = text().check(
    status.isIn(PersistenceCodecs.orderStatusCodes),
  )();
  late final DateTimeColumn createdAt = dateTime()();
  late final DateTimeColumn updatedAt = dateTime()();
  late final DateTimeColumn deletedAt = dateTime().nullable()();
  late final TextColumn syncState = text()
      .check(syncState.isIn(PersistenceCodecs.syncStateCodes))
      .withDefault(const Constant('local_only'))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(customer_name)) > 0)',
    'CHECK (length(trim(delivery_address)) > 0)',
    'CHECK (updated_at >= created_at)',
    'CHECK (deleted_at IS NULL OR deleted_at >= created_at)',
  ];
}

@DataClassName('AppSettingsRow')
class AppSettings extends Table {
  late final IntColumn id = integer().withDefault(const Constant(1))();
  late final BoolColumn imageUploadConsent = boolean().nullable()();
  late final TextColumn consentVersion = text().nullable()();
  late final DateTimeColumn lastSuccessfulSyncAt = dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (id = 1)',
    '''CHECK (
      (image_upload_consent IS NULL AND consent_version IS NULL)
      OR
      (image_upload_consent IS NOT NULL
        AND consent_version IS NOT NULL
        AND length(trim(consent_version)) > 0)
    )''',
  ];
}

@DriftDatabase(tables: [Batches, ScanRecords, Orders, AppSettings])
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'kami'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(scanRecords, scanRecords.resultOrigin);
      }
      if (from >= 2 && from < 3) {
        await migrator.alterTable(TableMigration(orders));
      }
      if (from < 4) {
        final tables = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ).get();
        final tableNames = tables
            .map((row) => row.read<String>('name'))
            .toSet();
        if (tableNames.contains('batches')) {
          await customStatement(
            'CREATE INDEX IF NOT EXISTS batches_active_page_idx '
            'ON batches (deleted_at, created_at, id)',
          );
        }
        await customStatement(
          'CREATE INDEX IF NOT EXISTS scan_records_active_page_idx '
          'ON scan_records (deleted_at, created_at, id)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS scan_records_batch_page_idx '
          'ON scan_records (batch_id, deleted_at, created_at, id)',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
