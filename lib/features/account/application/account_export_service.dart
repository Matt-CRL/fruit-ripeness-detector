import 'dart:convert';
import 'dart:io';

import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/auth/application/current_owner_provider.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/domain/retained_scan_image_store.dart';
import 'package:kami/features/sync/application/sync_coordinator.dart';
import 'package:kami/features/sync/data/local_sync_store.dart';
import 'package:kami/features/sync/domain/sync_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final accountExportServiceProvider = Provider<AccountExportService>((ref) {
  return AccountExportService(
    ref.watch(localSyncStoreProvider),
    ref.watch(syncCoordinatorProvider),
    ref.watch(retainedScanImageStoreProvider),
    ref.watch(currentOwnerIdProvider),
    getTemporaryDirectory,
    const PluginExportShareGateway(),
  );
});

typedef TemporaryDirectoryResolver = Future<Directory> Function();

abstract interface class ExportShareGateway {
  Future<void> shareZip(String path);
}

final class PluginExportShareGateway implements ExportShareGateway {
  const PluginExportShareGateway();

  @override
  Future<void> shareZip(String path) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/zip')],
        title: 'Kami account export',
        subject: 'Kami account export',
      ),
    );
  }
}

final class AccountExportService {
  const AccountExportService(
    this._local,
    this._sync,
    this._images,
    this._userId,
    this._temporaryDirectory,
    this._share,
  );

  final LocalSyncStore _local;
  final SyncCoordinator _sync;
  final RetainedScanImageStore _images;
  final String? _userId;
  final TemporaryDirectoryResolver _temporaryDirectory;
  final ExportShareGateway _share;

  Future<AccountExportResult> exportAndShare() async {
    final userId = _userId;
    if (userId == null) {
      throw const AccountExportException('Sign in before exporting data.');
    }
    final syncResult = await _sync.syncNow(SyncTrigger.manualRetry);
    if (syncResult.status == SyncStatus.failed ||
        syncResult.status == SyncStatus.idle) {
      throw const AccountExportException(
        'Kami could not synchronize all account data. Retry the export when '
        'you are online.',
      );
    }

    var data = await _local.readAccountData(userId);
    for (final scan in data.scans) {
      if (scan.localImageRelativePath == null && scan.remoteImageKey != null) {
        await _sync.downloadRemoteImage(scan.id);
      }
    }
    data = await _local.readAccountData(userId);

    final root = await _temporaryDirectory();
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final workspace = Directory(
      '${root.path}${Platform.pathSeparator}kami-export-$stamp',
    );
    final content = Directory(
      '${workspace.path}${Platform.pathSeparator}content',
    );
    final photos = Directory('${content.path}${Platform.pathSeparator}photos');
    final zip = File(
      '${workspace.path}${Platform.pathSeparator}kami-account-export.zip',
    );
    final missingPhotos = <String>[];
    try {
      await photos.create(recursive: true);
      for (final scan in data.scans) {
        final relativePath = scan.localImageRelativePath;
        if (relativePath == null) {
          if (scan.remoteImageKey != null) missingPhotos.add(scan.id);
          continue;
        }
        final source = File(await _images.resolvePath(relativePath));
        if (!await source.exists()) {
          missingPhotos.add(scan.id);
          continue;
        }
        await source.copy(
          '${photos.path}${Platform.pathSeparator}${scan.id}.jpg',
        );
      }

      final exportedAt = DateTime.now().toUtc();
      final manifest = <String, Object?>{
        'manifest_version': 1,
        'exported_at': exportedAt.toIso8601String(),
        'account_id': userId,
        'consent': {
          'photo_upload': data.settings.imageUploadConsent,
          'version': data.settings.consentVersion,
        },
        'missing_photo_scan_ids': missingPhotos,
        'batches': [
          for (final row in data.batches)
            {
              'id': row.id,
              'name': row.name,
              'fruit_type': row.fruitType,
              'created_at': row.createdAt.toUtc().toIso8601String(),
              'updated_at': row.updatedAt.toUtc().toIso8601String(),
              'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
              'revision': row.remoteRevision,
            },
        ],
        'scans': [
          for (final row in data.scans)
            {
              'id': row.id,
              'batch_id': row.batchId,
              'fruit_type': row.fruitType,
              'ripeness_stage': row.ripenessStage,
              'model_confidence': row.modelConfidence,
              'model_version': row.modelVersion,
              'result_origin': row.resultOrigin,
              'shelf_life_status': row.shelfLifeStatus,
              'shelf_life_minimum': row.shelfLifeMinimum,
              'shelf_life_maximum': row.shelfLifeMaximum,
              'shelf_life_unit': row.shelfLifeUnit,
              'shelf_life_guidance': row.shelfLifeGuidance,
              'shelf_life_reason': row.shelfLifeReason,
              'shelf_life_evidence_version': row.shelfLifeEvidenceVersion,
              'history_photo': row.localImageRelativePath == null
                  ? null
                  : 'photos/${row.id}.jpg',
              'created_at': row.createdAt.toUtc().toIso8601String(),
              'updated_at': row.updatedAt.toUtc().toIso8601String(),
              'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
              'revision': row.remoteRevision,
            },
        ],
        'orders': [
          for (final row in data.orders)
            {
              'id': row.id,
              'batch_id': row.batchId,
              'customer_name': row.customerName,
              'delivery_address': row.deliveryAddress,
              'delivery_date': row.deliveryDate.toUtc().toIso8601String(),
              'status': row.status,
              'created_at': row.createdAt.toUtc().toIso8601String(),
              'updated_at': row.updatedAt.toUtc().toIso8601String(),
              'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
              'revision': row.remoteRevision,
            },
        ],
      };
      await File(
        '${content.path}${Platform.pathSeparator}manifest.json',
      ).writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifest),
        flush: true,
      );
      await ZipFile.createFromDirectory(
        sourceDir: content,
        zipFile: zip,
        includeBaseDirectory: false,
      );
      await _share.shareZip(zip.path);
      return AccountExportResult(
        exportedAt: exportedAt,
        scanCount: data.scans.length,
        missingPhotoCount: missingPhotos.length,
      );
    } on AccountExportException {
      rethrow;
    } on Object {
      throw const AccountExportException(
        'Kami could not create or share the account export.',
      );
    } finally {
      if (await workspace.exists()) {
        await workspace.delete(recursive: true);
      }
    }
  }
}

final class AccountExportResult {
  const AccountExportResult({
    required this.exportedAt,
    required this.scanCount,
    required this.missingPhotoCount,
  });

  final DateTime exportedAt;
  final int scanCount;
  final int missingPhotoCount;
}

final class AccountExportException implements Exception {
  const AccountExportException(this.message);

  final String message;
}
