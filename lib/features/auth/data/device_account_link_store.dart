import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class DeviceAccountLinkStore {
  Future<String?> readLinkedAccountId();

  Future<void> writeLinkedAccountId(String accountId);

  Future<void> clearLinkedAccountId();

  Future<void> clearLinkedAccountIdIfMatches(String accountId);
}

final class SharedPreferencesDeviceAccountLinkStore
    implements DeviceAccountLinkStore {
  SharedPreferencesDeviceAccountLinkStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'kami.linkedAccountId';
  final SharedPreferencesAsync _preferences;

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
}

final deviceAccountLinkStoreProvider = Provider<DeviceAccountLinkStore>(
  (ref) => SharedPreferencesDeviceAccountLinkStore(),
);
