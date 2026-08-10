import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/app/kami_app.dart';
import 'package:kami/app/theme/theme_mode_controller.dart';
import 'package:kami/features/startup/data/startup_preferences_repository.dart';
import 'package:kami/features/startup/domain/startup_destination.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = StartupPreferencesRepository.device();
  var destination = StartupDestination.accountEntry;
  var themeMode = ThemeMode.light;
  try {
    destination = await preferences.readDestination();
    final appearance = await preferences.readAppearanceMode();
    themeMode = appearance == AppearanceMode.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  } on Object {
    // A preference read must never prevent local application entry.
  }

  runApp(
    ProviderScope(
      overrides: [
        startupPreferencesProvider.overrideWithValue(preferences),
        startupDestinationProvider.overrideWithValue(destination),
        initialThemeModeProvider.overrideWithValue(themeMode),
      ],
      child: const KamiApp(),
    ),
  );
}
