import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/startup/data/startup_preferences_repository.dart';
import 'package:kami/features/startup/domain/startup_destination.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';

void main() {
  test('fresh preferences open account entry', () async {
    final repository = StartupPreferencesRepository(
      FakeBooleanPreferenceStore(),
    );

    expect(await repository.readDestination(), StartupDestination.accountEntry);
  });

  test(
    'selected guest with incomplete onboarding resumes onboarding',
    () async {
      final store = FakeBooleanPreferenceStore();
      final repository = StartupPreferencesRepository(store);

      await repository.selectGuest();

      expect(await repository.readDestination(), StartupDestination.onboarding);
    },
  );

  test('completed guest onboarding restores Home destination', () async {
    final store = FakeBooleanPreferenceStore();
    final repository = StartupPreferencesRepository(store);

    await repository.completeGuestOnboarding();

    expect(
      await repository.readDestination(),
      StartupDestination.returningGuest,
    );
  });

  test(
    'reset guest entry returns to account choice and requires onboarding',
    () async {
      final store = FakeBooleanPreferenceStore();
      final repository = StartupPreferencesRepository(store);

      await repository.completeGuestOnboarding();
      await repository.resetGuestEntry();

      expect(
        await repository.readDestination(),
        StartupDestination.accountEntry,
      );

      await repository.selectGuest();

      expect(await repository.readDestination(), StartupDestination.onboarding);
    },
  );

  test('appearance mode persists locally', () async {
    final store = FakeBooleanPreferenceStore();
    final repository = StartupPreferencesRepository(store);

    expect(await repository.readAppearanceMode(), AppearanceMode.light);

    await repository.writeAppearanceMode(AppearanceMode.dark);

    expect(await repository.readAppearanceMode(), AppearanceMode.dark);
  });
}

final class FakeBooleanPreferenceStore implements BooleanPreferenceStore {
  final Map<String, bool> _values = {};

  @override
  Future<bool?> readBool(String key) async => _values[key];

  @override
  Future<void> writeBool(String key, bool value) async {
    _values[key] = value;
  }
}
