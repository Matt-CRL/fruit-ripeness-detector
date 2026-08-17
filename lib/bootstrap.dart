import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/app/kami_app.dart';
import 'package:kami/app/theme/theme_mode_controller.dart';
import 'package:kami/core/config/app_config.dart';
import 'package:kami/core/supabase/supabase_client_provider.dart';
import 'package:kami/features/auth/data/secure_supabase_local_storage.dart';
import 'package:kami/features/auth/data/device_account_link_store.dart';
import 'package:kami/features/startup/data/startup_preferences_repository.dart';
import 'package:kami/features/startup/domain/startup_destination.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  final preferences = StartupPreferencesRepository.device();
  final deviceLinkStore = SharedPreferencesDeviceAccountLinkStore();
  String? initialLinkedAccountId;
  try {
    initialLinkedAccountId = await deviceLinkStore.readLinkedAccountId();
  } on Object {
    // A missing preference must not prevent offline guest use.
  }
  final appConfig = AppConfig.fromEnvironment();
  SupabaseClient? supabaseClient;
  if (appConfig.cloudSyncConfigured) {
    try {
      await Supabase.initialize(
        url: appConfig.supabaseUrl,
        publishableKey: appConfig.supabasePublishableKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureSupabaseLocalStorage(),
        ),
      );
      supabaseClient = Supabase.instance.client;
    } on Object {
      // Cloud initialization must never prevent complete offline guest use.
    }
  }

  var destination = StartupDestination.accountEntry;
  var themeMode = ThemeMode.light;
  try {
    final account = supabaseClient?.auth.currentUser;
    if (account != null) {
      final completed = await preferences.isAccountOnboardingCompleted(
        account.id,
      );
      destination = completed
          ? StartupDestination.returningAccount
          : StartupDestination.onboarding;
    } else {
      destination = await preferences.readDestination();
    }
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
        appConfigProvider.overrideWithValue(appConfig),
        supabaseClientProvider.overrideWithValue(supabaseClient),
        deviceAccountLinkStoreProvider.overrideWithValue(deviceLinkStore),
        initialLinkedAccountIdProvider.overrideWithValue(
          initialLinkedAccountId,
        ),
      ],
      child: const KamiApp(),
    ),
  );
}
