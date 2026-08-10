import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';

final initialThemeModeProvider = Provider<ThemeMode>((ref) {
  return ThemeMode.light;
});

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<bool> setThemeMode(ThemeMode mode) async {
    final previous = state;
    state = mode;
    try {
      await ref
          .read(startupPreferencesProvider)
          .writeAppearanceMode(
            mode == ThemeMode.dark ? AppearanceMode.dark : AppearanceMode.light,
          );
      return true;
    } on Object {
      state = previous;
      return false;
    }
  }
}
