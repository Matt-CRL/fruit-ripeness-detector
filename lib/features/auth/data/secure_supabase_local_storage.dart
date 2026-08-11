import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class SecureValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<bool> containsKey(String key);
}

final class FlutterSecureValueStore implements SecureValueStore {
  FlutterSecureValueStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }
}

final class SecureSupabaseLocalStorage extends LocalStorage {
  SecureSupabaseLocalStorage({SecureValueStore? store})
    : _store = store ?? FlutterSecureValueStore();

  static const sessionKey = 'kami.supabase.session';

  final SecureValueStore _store;

  @override
  Future<String?> accessToken() => _store.read(sessionKey);

  @override
  Future<bool> hasAccessToken() => _store.containsKey(sessionKey);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> persistSession(String persistSessionString) {
    return _store.write(sessionKey, persistSessionString);
  }

  @override
  Future<void> removePersistedSession() => _store.delete(sessionKey);
}
