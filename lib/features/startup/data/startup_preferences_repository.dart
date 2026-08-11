import 'package:kami/features/startup/domain/startup_destination.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class BooleanPreferenceStore {
  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, bool value);
}

final class SharedPreferencesBooleanStore implements BooleanPreferenceStore {
  SharedPreferencesBooleanStore(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool?> readBool(String key) => _preferences.getBool(key);

  @override
  Future<void> writeBool(String key, bool value) {
    return _preferences.setBool(key, value);
  }
}

final class StartupPreferencesRepository implements StartupPreferences {
  StartupPreferencesRepository(this._store);

  factory StartupPreferencesRepository.device() {
    return StartupPreferencesRepository(
      SharedPreferencesBooleanStore(SharedPreferencesAsync()),
    );
  }

  static const guestSelectedKey = 'startup.guest_selected';
  static const guestOnboardingCompletedKey =
      'startup.guest_onboarding_completed';
  static const darkModeKey = 'appearance.dark_mode';
  static const accountOnboardingPrefix = 'startup.account_onboarding.';

  final BooleanPreferenceStore _store;

  @override
  Future<StartupDestination> readDestination() async {
    final guestSelected = await _store.readBool(guestSelectedKey) ?? false;
    if (!guestSelected) {
      return StartupDestination.accountEntry;
    }

    final onboardingCompleted =
        await _store.readBool(guestOnboardingCompletedKey) ?? false;
    return onboardingCompleted
        ? StartupDestination.returningGuest
        : StartupDestination.onboarding;
  }

  @override
  Future<void> selectGuest() async {
    await _store.writeBool(guestOnboardingCompletedKey, false);
    await _store.writeBool(guestSelectedKey, true);
  }

  @override
  Future<void> completeGuestOnboarding() async {
    await _store.writeBool(guestSelectedKey, true);
    await _store.writeBool(guestOnboardingCompletedKey, true);
  }

  @override
  Future<bool> isAccountOnboardingCompleted(String userId) async {
    return await _store.readBool('$accountOnboardingPrefix$userId') ?? false;
  }

  @override
  Future<void> completeAccountOnboarding(String userId) {
    return _store.writeBool('$accountOnboardingPrefix$userId', true);
  }

  @override
  Future<void> resetGuestEntry() async {
    await _store.writeBool(guestSelectedKey, false);
    await _store.writeBool(guestOnboardingCompletedKey, false);
  }

  @override
  Future<AppearanceMode> readAppearanceMode() async {
    final darkMode = await _store.readBool(darkModeKey) ?? false;
    return darkMode ? AppearanceMode.dark : AppearanceMode.light;
  }

  @override
  Future<void> writeAppearanceMode(AppearanceMode mode) {
    return _store.writeBool(darkModeKey, mode == AppearanceMode.dark);
  }
}
