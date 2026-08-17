import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:kami/core/supabase/supabase_client_provider.dart';
import 'package:kami/features/auth/data/device_account_link_store.dart';

enum WorkspaceLinkEligibility {
  eligible,
  localAlreadyLinked,
  accountLinkedElsewhere,
  workspaceLinked,
  pendingRelease,
  unavailable,
}

enum WorkspaceLinkResult {
  linked,
  localAlreadyLinked,
  accountLinkedElsewhere,
  workspaceLinked,
  unavailable,
}

final class OfflineWorkspaceLinkService {
  const OfflineWorkspaceLinkService(this._client, this._store);

  final SupabaseClient? _client;
  final DeviceAccountLinkStore _store;

  Future<WorkspaceLinkEligibility> checkEligibility(String accountId) async {
    if (await _store.hasPendingRelease()) {
      return WorkspaceLinkEligibility.pendingRelease;
    }
    final client = _client;
    if (client == null) return WorkspaceLinkEligibility.unavailable;
    try {
      return _eligibilityFromStatus(await _readRemoteStatus(client));
    } on Object {
      return WorkspaceLinkEligibility.unavailable;
    }
  }

  Future<WorkspaceLinkResult> link(String accountId) async {
    final client = _client;
    if (client == null) return WorkspaceLinkResult.unavailable;
    if (await _store.hasPendingRelease()) {
      return WorkspaceLinkResult.unavailable;
    }
    try {
      final workspaceId = await _store.readOrCreateWorkspaceId();
      final installationId = await _store.readOrCreateInstallationId();
      final token = await _store.readRevocationToken() ?? const Uuid().v4();
      final raw = await client.rpc(
        'claim_offline_workspace_link',
        params: {
          'p_workspace_id': workspaceId,
          'p_installation_id': installationId,
          'p_revocation_token': token,
        },
      );
      final status = _statusFromResponse(raw);
      switch (status) {
        case 'linked':
          await _store.writeRevocationToken(token);
          return WorkspaceLinkResult.linked;
        case 'local_already_linked':
          // A legacy installation may already be registered without a local
          // token. The authenticated release RPC remains available, but do
          // not overwrite secure storage with a token that the registry did
          // not issue for this workspace.
          return WorkspaceLinkResult.linked;
        case 'linked_elsewhere':
          return WorkspaceLinkResult.accountLinkedElsewhere;
        case 'workspace_linked':
          return WorkspaceLinkResult.workspaceLinked;
        default:
          return WorkspaceLinkResult.unavailable;
      }
    } on Object {
      return WorkspaceLinkResult.unavailable;
    }
  }

  Future<bool> release({required bool authenticated}) async {
    final client = _client;
    if (client == null) {
      await _store.setPendingRelease(true);
      return false;
    }
    try {
      final workspaceId = await _store.readOrCreateWorkspaceId();
      final token = await _store.readRevocationToken();
      final raw = authenticated
          ? await client.rpc(
              'release_offline_workspace_link',
              params: {'p_workspace_id': workspaceId},
            )
          : token == null
          ? false
          : await client.rpc(
              'release_offline_workspace_link_with_token',
              params: {
                'p_workspace_id': workspaceId,
                'p_revocation_token': token,
              },
            );
      final released =
          _boolFromResponse(raw) == true ||
          _statusFromResponse(raw) == 'released';
      // An authenticated release returning false means this account has no
      // registry row for this workspace. If there is no secure token either,
      // there is nothing left to release (for example, an older installation
      // that was never registered), so do not strand the workspace in a
      // permanent pending state.
      final noRemoteLink =
          authenticated && _boolFromResponse(raw) == false && token == null;
      if (released || noRemoteLink) {
        await _store.clearRevocationToken();
        await _store.setPendingRelease(false);
      } else {
        await _store.setPendingRelease(true);
      }
      return released;
    } on Object {
      await _store.setPendingRelease(true);
      return false;
    }
  }

  Future<bool> retryPendingRelease({bool authenticated = false}) async {
    if (!await _store.hasPendingRelease()) return true;
    if (!authenticated) {
      if (await release(authenticated: false)) return true;
      return _clearPendingIfWorkspaceIsUnregistered();
    }

    // Prefer the current authenticated owner, then fall back to the secure
    // token. The fallback handles a Guest release that is retried after a
    // different account signs in; it never exposes the prior account ID.
    if (await release(authenticated: true)) return true;
    if (await release(authenticated: false)) return true;
    return _clearPendingIfWorkspaceIsUnregistered();
  }

  Future<void> advanceWorkspaceGeneration() async {
    await _store.advanceWorkspaceGeneration();
  }

  /// Clears a stale local pending-release marker only after the authenticated
  /// registry confirms that this workspace has no link. A failed status call
  /// keeps the marker so an offline or partial network response cannot expose
  /// a still-linked workspace.
  Future<bool> _clearPendingIfWorkspaceIsUnregistered() async {
    final client = _client;
    if (client == null) return false;
    try {
      final status = await _readRemoteStatus(client);
      if (status == 'eligible' || status == 'linked_elsewhere') {
        await _store.clearRevocationToken();
        await _store.setPendingRelease(false);
        return true;
      }
    } on Object {
      // Keep the pending marker when Supabase cannot verify ownership.
    }
    return false;
  }

  Future<String> _readRemoteStatus(SupabaseClient client) async {
    final workspaceId = await _store.readOrCreateWorkspaceId();
    final raw = await client.rpc(
      'offline_workspace_link_status',
      params: {'p_workspace_id': workspaceId},
    );
    return _statusFromResponse(raw);
  }

  static WorkspaceLinkEligibility _eligibilityFromStatus(String status) {
    return switch (status) {
      'eligible' => WorkspaceLinkEligibility.eligible,
      'local_already_linked' => WorkspaceLinkEligibility.localAlreadyLinked,
      'linked_elsewhere' => WorkspaceLinkEligibility.accountLinkedElsewhere,
      'workspace_linked' => WorkspaceLinkEligibility.workspaceLinked,
      _ => WorkspaceLinkEligibility.unavailable,
    };
  }

  static String _statusFromResponse(Object? raw) {
    if (raw is String) return raw;
    if (raw is Map) {
      final status = raw['status'];
      if (status is String) return status;
      for (final value in raw.values) {
        if (value is String) return value;
      }
    }
    if (raw is List && raw.isNotEmpty) return _statusFromResponse(raw.first);
    return '';
  }

  static bool? _boolFromResponse(Object? raw) {
    if (raw is bool) return raw;
    if (raw is Map) {
      for (final value in raw.values) {
        if (value is bool) return value;
      }
    }
    if (raw is List && raw.isNotEmpty) return _boolFromResponse(raw.first);
    return null;
  }

  static String hashRevocationToken(String token) =>
      sha256.convert(token.codeUnits).toString();
}

final offlineWorkspaceLinkServiceProvider =
    Provider<OfflineWorkspaceLinkService>(
      (ref) => OfflineWorkspaceLinkService(
        ref.watch(supabaseClientProvider),
        ref.watch(deviceAccountLinkStoreProvider),
      ),
    );
