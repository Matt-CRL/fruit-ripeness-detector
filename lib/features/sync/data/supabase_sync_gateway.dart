import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kami/features/sync/domain/sync_gateway.dart';
import 'package:kami/features/sync/domain/sync_models.dart';

final class SupabaseSyncGateway implements SyncGateway {
  const SupabaseSyncGateway(this._client);

  static const _bucket = 'scan-images';

  final SupabaseClient _client;

  @override
  Future<DateTime> serverTimeAnchor() async {
    final value = await _client.rpc('sync_anchor');
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.parse(value).toUtc();
    throw const FormatException('The synchronization anchor was invalid.');
  }

  @override
  Future<PushResult> push(
    RemoteSyncRecord record, {
    required int expectedRevision,
  }) async {
    final tableName = _tableName(record.table);
    const identityColumn = 'id';
    final payload = <String, Object?>{
      ...record.values,
      'user_id': record.userId,
      'id': record.id,
    };

    if (expectedRevision == 0) {
      try {
        final response = await _client
            .from(tableName)
            .insert(payload)
            .select()
            .single();
        return PushAccepted(_fromJson(record.table, response));
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;
        return PushConflict(
          await _fetchOne(record.table, identityColumn, record.id),
        );
      }
    }

    payload
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at')
      ..remove('revision')
      ..remove('server_changed_at');
    final response = await _client
        .from(tableName)
        .update(payload)
        .eq(identityColumn, record.id)
        .eq('revision', expectedRevision)
        .select()
        .maybeSingle();
    if (response == null) {
      return PushConflict(
        await _fetchOne(record.table, identityColumn, record.id),
      );
    }
    return PushAccepted(_fromJson(record.table, response));
  }

  @override
  Future<PullPage> pull({
    required SyncTable table,
    required String userId,
    required DateTime changedSince,
    required DateTime anchor,
    SyncCursor? after,
    int limit = 200,
  }) async {
    const identityColumn = 'id';
    var query = _client
        .from(_tableName(table))
        .select()
        .eq('user_id', userId)
        .gte('server_changed_at', changedSince.toUtc().toIso8601String())
        .lte('server_changed_at', anchor.toUtc().toIso8601String());
    if (after != null) {
      final changedAt = after.serverChangedAt.toUtc().toIso8601String();
      query = query.or(
        'server_changed_at.gt.$changedAt,and(server_changed_at.eq.$changedAt,'
        '$identityColumn.gt.${after.id})',
      );
    }
    final response = await query
        .order('server_changed_at')
        .order(identityColumn)
        .limit(limit + 1);
    final rows = List<Map<String, dynamic>>.from(response);
    final hasMore = rows.length > limit;
    if (hasMore) rows.removeLast();
    return PullPage(
      records: rows.map((row) => _fromJson(table, row)).toList(growable: false),
      hasMore: hasMore,
    );
  }

  @override
  Future<void> uploadHistoryImage({
    required String objectKey,
    required Uint8List jpegBytes,
  }) async {
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          objectKey,
          jpegBytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
  }

  @override
  Future<Uint8List> downloadHistoryImage(String objectKey) {
    return _client.storage.from(_bucket).download(objectKey);
  }

  @override
  Future<void> deleteHistoryImages(Iterable<String> objectKeys) async {
    final paths = objectKeys.toSet().toList(growable: false);
    if (paths.isEmpty) return;
    for (var offset = 0; offset < paths.length; offset += 100) {
      final end = (offset + 100).clamp(0, paths.length);
      await _client.storage.from(_bucket).remove(paths.sublist(offset, end));
    }
  }

  @override
  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Account deletion was not accepted by the server.');
    }
  }

  Future<RemoteSyncRecord> _fetchOne(
    SyncTable table,
    String identityColumn,
    String id,
  ) async {
    final response = await _client
        .from(_tableName(table))
        .select()
        .eq(identityColumn, id)
        .single();
    return _fromJson(table, response);
  }
}

String _tableName(SyncTable table) => switch (table) {
  SyncTable.batches => 'batches',
  SyncTable.scanRecords => 'scan_records',
  SyncTable.orders => 'orders',
  SyncTable.userSettings => 'user_settings',
};

RemoteSyncRecord _fromJson(SyncTable table, Map<String, dynamic> json) {
  final userId = json['user_id'] as String;
  final id = json['id'] as String;
  final revision = (json['revision'] as num).toInt();
  final changedValue = json['server_changed_at'];
  final serverChangedAt = changedValue is DateTime
      ? changedValue.toUtc()
      : DateTime.parse(changedValue as String).toUtc();
  final values = Map<String, Object?>.from(json)
    ..remove('id')
    ..remove('user_id')
    ..remove('revision')
    ..remove('server_changed_at');
  return RemoteSyncRecord(
    table: table,
    id: id,
    userId: userId,
    values: values,
    revision: revision,
    serverChangedAt: serverChangedAt,
  );
}
