import 'dart:typed_data';

import 'package:kami/features/sync/domain/sync_models.dart';

abstract interface class SyncGateway {
  Future<DateTime> serverTimeAnchor();

  Future<PushResult> push(
    RemoteSyncRecord record, {
    required int expectedRevision,
  });

  Future<PullPage> pull({
    required SyncTable table,
    required String userId,
    required DateTime changedSince,
    required DateTime anchor,
    SyncCursor? after,
    int limit = 200,
  });

  Future<void> uploadHistoryImage({
    required String objectKey,
    required Uint8List jpegBytes,
  });

  Future<Uint8List> downloadHistoryImage(String objectKey);

  Future<void> deleteHistoryImages(Iterable<String> objectKeys);

  Future<void> deleteAccount();
}
