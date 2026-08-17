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
  late final IntColumn remoteRevision = integer()
      .check(remoteRevision.isBiggerOrEqualValue(0))
      .withDefault(const Constant(0))();

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
  late final IntColumn remoteRevision = integer()
      .check(remoteRevision.isBiggerOrEqualValue(0))
      .withDefault(const Constant(0))();
  late final TextColumn imageSyncState = text()
      .check(imageSyncState.isIn(PersistenceCodecs.imageSyncStateCodes))
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
  late final IntColumn remoteRevision = integer()
      .check(remoteRevision.isBiggerOrEqualValue(0))
      .withDefault(const Constant(0))();

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

@DataClassName('AccountSyncSettingsRow')
class AccountSyncSettings extends Table {
  late final TextColumn ownerId = text()();
  late final BoolColumn imageUploadConsent = boolean().nullable()();
  late final TextColumn consentVersion = text().nullable()();
  late final DateTimeColumn lastSuccessfulSyncAt = dateTime().nullable()();
  late final DateTimeColumn lastSyncAttemptAt = dateTime().nullable()();
  late final DateTimeColumn syncCursorAt = dateTime().nullable()();
  late final TextColumn lastSyncErrorCode = text().nullable()();
  late final TextColumn syncState = text()
      .check(syncState.isIn(PersistenceCodecs.syncStateCodes))
      .withDefault(const Constant('local_only'))();
  late final IntColumn remoteRevision = integer()
      .check(remoteRevision.isBiggerOrEqualValue(0))
      .withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {ownerId};

  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(owner_id)) > 0)',
    '''CHECK (
      (image_upload_consent IS NULL AND consent_version IS NULL)
      OR
      (image_upload_consent IS NOT NULL
        AND length(trim(consent_version)) > 0)
    )''',
  ];
}

@DataClassName('OfflineWorkspaceStateRow')
class OfflineWorkspaceStates extends Table {
  late final TextColumn id = text()();
  late final TextColumn workspaceId = text()();
  late final TextColumn installationId = text()();
  late final IntColumn generation = integer().withDefault(const Constant(0))();
  late final BoolColumn pendingRelease = boolean().withDefault(
    const Constant(false),
  )();
  late final DateTimeColumn updatedAt = dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DetachedEntityOriginRow')
@TableIndex(
  name: 'detached_entity_origins_workspace_idx',
  columns: {#workspaceId, #generation},
)
class DetachedEntityOrigins extends Table {
  late final TextColumn id = text()();
  late final TextColumn workspaceId = text()();
  late final IntColumn generation = integer()();
  late final TextColumn entityType = text()();
  late final TextColumn guestEntityId = text()();
  late final TextColumn originalOwnerId = text()();
  late final TextColumn originalEntityId = text()();
  late final IntColumn originalRemoteRevision = integer()();
  late final DateTimeColumn detachedAt = dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Batches,
    ScanRecords,
    Orders,
    AccountSyncSettings,
    OfflineWorkspaceStates,
    DetachedEntityOrigins,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'kami'));

  @override
  int get schemaVersion => 8;

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
      if (from < 5) {
        final tables = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ).get();
        final tableNames = tables
            .map((row) => row.read<String>('name'))
            .toSet();
        if (tableNames.contains('batches')) {
          await migrator.addColumn(batches, batches.remoteRevision);
        }
        if (tableNames.contains('scan_records')) {
          await migrator.addColumn(scanRecords, scanRecords.remoteRevision);
          await migrator.addColumn(scanRecords, scanRecords.imageSyncState);
        }
        if (tableNames.contains('orders')) {
          await migrator.addColumn(orders, orders.remoteRevision);
        }
        if (tableNames.contains('app_settings')) {
          await customStatement(
            'ALTER TABLE app_settings ADD COLUMN last_sync_attempt_at INTEGER',
          );
          await customStatement(
            'ALTER TABLE app_settings ADD COLUMN sync_cursor_at INTEGER',
          );
          await customStatement(
            'ALTER TABLE app_settings ADD COLUMN last_sync_error_code TEXT',
          );
          await customStatement(
            "ALTER TABLE app_settings ADD COLUMN sync_state TEXT NOT NULL DEFAULT 'local_only'",
          );
          await customStatement(
            'ALTER TABLE app_settings ADD COLUMN remote_revision INTEGER NOT NULL DEFAULT 0',
          );
        }
      }
      if (from < 6) {
        final tables = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ).get();
        final tableNames = tables
            .map((row) => row.read<String>('name'))
            .toSet();
        if (tableNames.contains('app_settings')) {
          await customStatement(
            'ALTER TABLE app_settings ADD COLUMN consent_account_id TEXT',
          );
        }
      }
      if (from < 7) {
        await migrator.createTable(accountSyncSettings);
        final tables = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ).get();
        final tableNames = tables
            .map((row) => row.read<String>('name'))
            .toSet();
        if (tableNames.contains('app_settings')) {
          final legacy = await customSelect('''
            SELECT consent_account_id
            FROM app_settings
            WHERE id = 1
            ''').getSingleOrNull();
          final legacyOwner = legacy?.data['consent_account_id'];
          if (legacyOwner is String && legacyOwner.trim().isNotEmpty) {
            await customStatement('''
              INSERT INTO account_sync_settings (
                owner_id, image_upload_consent, consent_version,
                last_successful_sync_at, last_sync_attempt_at, sync_cursor_at,
                last_sync_error_code, sync_state, remote_revision
              )
              SELECT consent_account_id, image_upload_consent, consent_version,
                     last_successful_sync_at, last_sync_attempt_at,
                     sync_cursor_at, last_sync_error_code, sync_state,
                     remote_revision
              FROM app_settings
              WHERE id = 1 AND consent_account_id IS NOT NULL
              ''');
          }
          await customStatement('DROP TABLE app_settings');
        }
      }
      if (from < 8) {
        await migrator.createTable(offlineWorkspaceStates);
        await migrator.createTable(detachedEntityOrigins);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
