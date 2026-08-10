import 'package:kami/features/startup/domain/startup_destination.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';

final class FakeStartupPreferences implements StartupPreferences {
  FakeStartupPreferences({
    this.guestSelected = false,
    this.onboardingCompleted = false,
    this.failWrites = false,
    this.appearanceMode = AppearanceMode.light,
  });

  bool guestSelected;
  bool onboardingCompleted;
  bool failWrites;
  AppearanceMode appearanceMode;

  @override
  Future<StartupDestination> readDestination() async {
    if (!guestSelected) {
      return StartupDestination.accountEntry;
    }

    return onboardingCompleted
        ? StartupDestination.returningGuest
        : StartupDestination.onboarding;
  }

  @override
  Future<void> selectGuest() async {
    if (failWrites) {
      throw StateError('Preference write failed.');
    }
    guestSelected = true;
  }

  @override
  Future<void> completeGuestOnboarding() async {
    if (failWrites) {
      throw StateError('Preference write failed.');
    }
    guestSelected = true;
    onboardingCompleted = true;
  }

  @override
  Future<void> resetGuestEntry() async {
    if (failWrites) {
      throw StateError('Preference write failed.');
    }
    guestSelected = false;
    onboardingCompleted = false;
  }

  @override
  Future<AppearanceMode> readAppearanceMode() async => appearanceMode;

  @override
  Future<void> writeAppearanceMode(AppearanceMode mode) async {
    if (failWrites) {
      throw StateError('Preference write failed.');
    }
    appearanceMode = mode;
  }
}
