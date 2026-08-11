import 'package:kami/core/persistence/local_sync_state.dart';

enum SyncTrigger { signIn, startup, resume, localWrite, refresh, manualRetry }

enum SyncStatus { idle, syncing, upToDate, failed, conflict }

enum SyncTable { batches, scanRecords, orders, userSettings }

final class SyncRunResult {
  const SyncRunResult({
    required this.status,
    required this.pushed,
    required this.pulled,
    required this.conflicts,
    this.completedAt,
    this.errorCode,
  });

  const SyncRunResult.notConfigured()
    : status = SyncStatus.idle,
      pushed = 0,
      pulled = 0,
      conflicts = 0,
      completedAt = null,
      errorCode = 'cloud_not_configured';

  final SyncStatus status;
  final int pushed;
  final int pulled;
  final int conflicts;
  final DateTime? completedAt;
  final String? errorCode;
}

final class SyncStatusSnapshot {
  const SyncStatusSnapshot({
    this.status = SyncStatus.idle,
    this.lastSuccessfulSyncAt,
    this.errorCode,
    this.conflictCount = 0,
  });

  final SyncStatus status;
  final DateTime? lastSuccessfulSyncAt;
  final String? errorCode;
  final int conflictCount;

  SyncStatusSnapshot copyWith({
    SyncStatus? status,
    DateTime? lastSuccessfulSyncAt,
    bool clearLastSuccessfulSyncAt = false,
    String? errorCode,
    bool clearErrorCode = false,
    int? conflictCount,
  }) {
    return SyncStatusSnapshot(
      status: status ?? this.status,
      lastSuccessfulSyncAt: clearLastSuccessfulSyncAt
          ? null
          : lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      errorCode: clearErrorCode ? null : errorCode ?? this.errorCode,
      conflictCount: conflictCount ?? this.conflictCount,
    );
  }
}

final class SyncCursor {
  const SyncCursor({required this.serverChangedAt, required this.id});

  final DateTime serverChangedAt;
  final String id;
}

final class RemoteSyncRecord {
  const RemoteSyncRecord({
    required this.table,
    required this.id,
    required this.userId,
    required this.values,
    required this.revision,
    required this.serverChangedAt,
  });

  final SyncTable table;
  final String id;
  final String userId;
  final Map<String, Object?> values;
  final int revision;
  final DateTime serverChangedAt;
}

sealed class PushResult {
  const PushResult();
}

final class PushAccepted extends PushResult {
  const PushAccepted(this.record);

  final RemoteSyncRecord record;
}

final class PushConflict extends PushResult {
  const PushConflict(this.remote);

  final RemoteSyncRecord remote;
}

final class PullPage {
  const PullPage({required this.records, required this.hasMore});

  final List<RemoteSyncRecord> records;
  final bool hasMore;
}

final class LocalSyncSettings {
  const LocalSyncSettings({
    this.imageUploadConsent,
    this.consentVersion,
    this.lastSuccessfulSyncAt,
    this.lastSyncAttemptAt,
    this.syncCursorAt,
    this.lastSyncErrorCode,
    this.remoteRevision = 0,
    this.syncState = LocalSyncState.localOnly,
  });

  final bool? imageUploadConsent;
  final String? consentVersion;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? lastSyncAttemptAt;
  final DateTime? syncCursorAt;
  final String? lastSyncErrorCode;
  final int remoteRevision;
  final LocalSyncState syncState;
}

enum LocalApplyResult { applied, ignoredAsDuplicate, replacedPendingConflict }
