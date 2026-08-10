import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'startup_destination.dart';

enum AppearanceMode { light, dark }

abstract interface class StartupPreferences {
  Future<StartupDestination> readDestination();

  Future<void> selectGuest();

  Future<void> completeGuestOnboarding();

  Future<void> resetGuestEntry();

  Future<AppearanceMode> readAppearanceMode();

  Future<void> writeAppearanceMode(AppearanceMode mode);
}

final startupPreferencesProvider = Provider<StartupPreferences>((ref) {
  throw StateError('StartupPreferences was not initialized.');
});
