import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/auth/data/secure_supabase_local_storage.dart';

void main() {
  test(
    'persists and removes only the encrypted Supabase session value',
    () async {
      final values = FakeSecureValueStore();
      final storage = SecureSupabaseLocalStorage(store: values);

      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);

      await storage.persistSession('synthetic-session-json');
      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), 'synthetic-session-json');
      expect(values.values.keys, [SecureSupabaseLocalStorage.sessionKey]);

      await storage.removePersistedSession();
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
    },
  );
}

final class FakeSecureValueStore implements SecureValueStore {
  final Map<String, String> values = {};

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
