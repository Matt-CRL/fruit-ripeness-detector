import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/database/app_database_provider.dart';
import 'package:kami/core/persistence/entity_id_generator.dart';
import 'package:kami/core/persistence/image_sync_state.dart';
import 'package:kami/features/auth/application/current_owner_provider.dart';
import 'package:kami/features/history/data/app_private_retained_scan_image_store.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/retained_scan_image_store.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/scan_record_repository.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/sync/data/local_sync_store.dart';

typedef ReplaceAssessmentUtcNow = DateTime Function();

final replaceSavedScanAssessmentUseCaseProvider =
    Provider<ReplaceSavedScanAssessmentUseCase>((ref) {
      return ReplaceSavedScanAssessmentUseCase(
        ref.watch(scanRecordRepositoryProvider),
        ref.watch(retainedScanImageStoreProvider),
        ref.watch(entityIdGeneratorProvider),
        ref.watch(replaceAssessmentUtcNowProvider),
        ref.watch(currentOwnerIdProvider),
        () async {
          final ownerId = ref.read(currentOwnerIdProvider);
          if (ownerId == null) return false;
          return (await ref.read(localSyncStoreProvider).readSettings(ownerId))
                  .imageUploadConsent ==
              true;
        },
      );
    });

final replaceAssessmentUtcNowProvider = Provider<ReplaceAssessmentUtcNow>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

final class ReplaceSavedScanAssessmentUseCase {
  const ReplaceSavedScanAssessmentUseCase(
    this._repository,
    this._imageStore,
    this._idGenerator,
    this._utcNow,
    this._ownerId,
    this._photoConsent,
  );

  final ScanRecordRepository _repository;
  final RetainedScanImageStore _imageStore;
  final EntityIdGenerator _idGenerator;
  final ReplaceAssessmentUtcNow _utcNow;
  final String? _ownerId;
  final Future<bool> Function() _photoConsent;

  Future<SavedScanRecord> execute({
    required SavedScanRecord record,
    required ScanPreview preview,
    required RipenessUpdateSource updateSource,
  }) async {
    if (record.resultOrigin == ResultOrigin.demo) {
      throw const ReplaceSavedScanAssessmentException(
        'Demo records cannot be rescanned.',
      );
    }
    if (preview.classification.requiresRetake ||
        preview.classification.origin != ResultOrigin.onDeviceModel) {
      throw const ReplaceSavedScanAssessmentException(
        'This scan is not clear enough to update the saved assessment.',
      );
    }
    if (preview.classification.fruit != record.fruit) {
      throw const ReplaceSavedScanAssessmentException(
        'The rescan detected a different fruit type.',
      );
    }

    RetainedScanImage? replacement;
    try {
      replacement = await _imageStore.retain(
        sourcePath: preview.image.path,
        scanId: _idGenerator.nextId(),
      );
      final hasConsent = _ownerId != null && await _photoConsent();
      final updated = await _repository.replaceAssessment(
        scanId: record.id,
        fruit: record.fruit,
        ripeness: preview.classification.ripeness,
        modelConfidence: preview.classification.modelConfidence,
        modelVersion: preview.classification.modelVersion,
        resultOrigin: preview.classification.origin,
        shelfLife: preview.shelfLife,
        localImageRelativePath: replacement.relativePath,
        imageSyncState: hasConsent
            ? ImageSyncState.pendingUpload
            : ImageSyncState.localOnly,
        updateSource: updateSource,
        updatedAt: _utcNow(),
        expectedUpdatedAt: record.updatedAt,
      );
      final previousPath = record.localImageRelativePath;
      if (previousPath != null && previousPath != replacement.relativePath) {
        try {
          await _imageStore.remove(previousPath);
        } on Object {
          // The updated record already points to the replacement image. A
          // failed cleanup leaves only an orphaned private file.
        }
      }
      return updated;
    } on ReplaceSavedScanAssessmentException {
      rethrow;
    } on Object {
      if (replacement != null) {
        try {
          await _imageStore.remove(replacement.relativePath);
        } on Object {
          // Preserve the original assessment even if cleanup also fails.
        }
      }
      throw const ReplaceSavedScanAssessmentException(
        'Chami could not update the saved assessment. The previous assessment '
        'was kept.',
      );
    }
  }
}

final class ReplaceSavedScanAssessmentException implements Exception {
  const ReplaceSavedScanAssessmentException(this.message);

  final String message;

  @override
  String toString() => 'ReplaceSavedScanAssessmentException: $message';
}
