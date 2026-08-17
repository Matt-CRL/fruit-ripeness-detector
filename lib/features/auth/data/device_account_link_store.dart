import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:kami/features/auth/data/secure_supabase_local_storage.dart';

abstract interface class DeviceAccountLinkStore {
  Future<String?> readLinkedAccountId();

  Future<void> writeLinkedAccountId(String accountId);

  Future<void> clearLinkedAccountId();

  Future<void> clearLinkedAccountIdIfMatches(String accountId);

  Future<bool> hasAskedToLink(String accountId);

  Future<void> markAskedToLink(String accountId);

  Future<String> readOrCreateWorkspaceId();

  Future<String> readOrCreateInstallationId();

  Future<int> readWorkspaceGeneration();

  Future<int> advanceWorkspaceGeneration();

  Future<void> writeRevocationToken(String token);

  Future<String?> readRevocationToken();

  Future<void> clearRevocationToken();

  Future<bool> hasPendingRelease();

  Future<void> setPendingRelease(bool pending);
}

final class SharedPreferencesDeviceAccountLinkStore
    implements DeviceAccountLinkStore {
  SharedPreferencesDeviceAccountLinkStore([
    SharedPreferencesAsync? preferences,
    SecureValueStore? secureStore,
  ]) : _preferences = preferences ?? SharedPreferencesAsync(),
       _secureStore = secureStore ?? FlutterSecureValueStore();

  static const _key = 'kami.linkedAccountId';
  static const _promptedKey = 'kami.offlineLinkPromptedAccountIds';
  static const _workspaceKey = 'kami.offlineWorkspaceId';
  static const _installationKey = 'kami.offlineInstallationId';
  static const _generationKey = 'kami.offlineWorkspaceGeneration';
  static const _pendingReleaseKey = 'kami.offlineLinkPendingRelease';
  final SharedPreferencesAsync _preferences;
  final SecureValueStore _secureStore;
  static const _secureRevocationKey = 'kami.offlineLinkRevocationToken';

  @override
  Future<String?> readLinkedAccountId() => _preferences.getString(_key);

  @override
  Future<void> writeLinkedAccountId(String accountId) =>
      _preferences.setString(_key, accountId);

  @override
  Future<void> clearLinkedAccountId() => _preferences.remove(_key);

  @override
  Future<void> clearLinkedAccountIdIfMatches(String accountId) async {
    if (await readLinkedAccountId() == accountId) {
      await clearLinkedAccountId();
    }
  }

  @override
  Future<bool> hasAskedToLink(String accountId) async {
    final ids = await _preferences.getStringList(_promptedKey) ?? const [];
    final generation = await readWorkspaceGeneration();
    return ids.contains('$generation:$accountId');
  }

  @override
  Future<void> markAskedToLink(String accountId) async {
    final ids = {
      ...await _preferences.getStringList(_promptedKey) ?? const <String>[],
    };
    final generation = await readWorkspaceGeneration();
    ids.add('$generation:$accountId');
    await _preferences.setStringList(_promptedKey, ids.toList(growable: false));
  }

  @override
  Future<String> readOrCreateWorkspaceId() async {
    final existing = await _preferences.getString(_workspaceKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final value = const Uuid().v4();
    await _preferences.setString(_workspaceKey, value);
    return value;
  }

  @override
  Future<String> readOrCreateInstallationId() async {
    final existing = await _preferences.getString(_installationKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final value = const Uuid().v4();
    await _preferences.setString(_installationKey, value);
    return value;
  }

  @override
  Future<int> readWorkspaceGeneration() async =>
      await _preferences.getInt(_generationKey) ?? 0;

  @override
  Future<int> advanceWorkspaceGeneration() async {
    final generation = (await readWorkspaceGeneration()) + 1;
    await _preferences.setInt(_generationKey, generation);
    return generation;
  }

  @override
  Future<void> writeRevocationToken(String token) =>
      _secureStore.write(_secureRevocationKey, token);

  @override
  Future<String?> readRevocationToken() =>
      _secureStore.read(_secureRevocationKey);

  @override
  Future<void> clearRevocationToken() =>
      _secureStore.delete(_secureRevocationKey);

  @override
  Future<bool> hasPendingRelease() async =>
      await _preferences.getBool(_pendingReleaseKey) ?? false;

  @override
  Future<void> setPendingRelease(bool pending) async {
    if (pending) {
      await _preferences.setBool(_pendingReleaseKey, true);
    } else {
      await _preferences.remove(_pendingReleaseKey);
    }
  }
}

final deviceAccountLinkStoreProvider = Provider<DeviceAccountLinkStore>(
  (ref) => SharedPreferencesDeviceAccountLinkStore(),
);

/// The linked offline workspace owner, hydrated once during bootstrap.
///
/// Keeping this in Riverpod makes the local owner switch immediately when an
/// account is linked or unlinked without requiring a process restart.
final initialLinkedAccountIdProvider = Provider<String?>((ref) => null);

final deviceLinkedAccountIdProvider =
    NotifierProvider<DeviceLinkedAccountIdController, String?>(
      DeviceLinkedAccountIdController.new,
    );

final class DeviceLinkedAccountIdController extends Notifier<String?> {
  @override
  String? build() => ref.watch(initialLinkedAccountIdProvider);

  Future<void> link(String accountId) async {
    await ref
        .read(deviceAccountLinkStoreProvider)
        .writeLinkedAccountId(accountId);
    state = accountId;
  }

  Future<void> clear() async {
    await ref.read(deviceAccountLinkStoreProvider).clearLinkedAccountId();
    state = null;
  }

  Future<void> clearIfMatches(String accountId) async {
    if (state != accountId) return;
    await ref
        .read(deviceAccountLinkStoreProvider)
        .clearLinkedAccountIdIfMatches(accountId);
    state = null;
  }
}
