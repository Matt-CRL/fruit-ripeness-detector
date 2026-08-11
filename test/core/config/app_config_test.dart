import 'package:flutter_test/flutter_test.dart';
import 'package:kami/core/config/app_config.dart';

void main() {
  test('missing cloud configuration preserves offline guest mode', () {
    const config = AppConfig(supabaseUrl: '', supabasePublishableKey: '');

    expect(config.cloudSyncConfigured, isFalse);
  });

  test('requires both a valid URL and a publishable key', () {
    expect(
      const AppConfig(
        supabaseUrl: 'not-a-url',
        supabasePublishableKey: 'public-key',
      ).cloudSyncConfigured,
      isFalse,
    );
    expect(
      const AppConfig(
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: '',
      ).cloudSyncConfigured,
      isFalse,
    );
    expect(
      const AppConfig(
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'public-key',
      ).cloudSyncConfigured,
      isTrue,
    );
  });
}
