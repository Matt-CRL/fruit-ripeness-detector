import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/app/router/app_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/theme/app_theme.dart';
import 'package:kami/app/theme/theme_mode_controller.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/auth/application/restored_session_startup.dart';
import 'package:kami/features/auth/domain/auth_repository.dart';
import 'package:kami/features/auth/presentation/development_photo_consent_dialog.dart';
import 'package:kami/features/sync/application/sync_coordinator.dart';
import 'package:kami/features/sync/data/local_sync_store.dart';
import 'package:kami/features/sync/domain/sync_models.dart';

class KamiApp extends ConsumerStatefulWidget {
  const KamiApp({super.key});

  @override
  ConsumerState<KamiApp> createState() => _KamiAppState();
}

class _KamiAppState extends ConsumerState<KamiApp> with WidgetsBindingObserver {
  late final RestoredSessionStartup _restoredSessionStartup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoredSessionStartup = RestoredSessionStartup(_startInitialSync);
    ref.listenManual(
      accountAuthStateProvider,
      _onAuthState,
      fireImmediately: true,
    );
  }

  void _onAuthState(
    AsyncValue<AccountAuthState>? previous,
    AsyncValue<AccountAuthState> next,
  ) {
    next.whenData((state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_restoredSessionStartup.handle(state));
        if (state.event == AccountAuthEvent.passwordRecovery) {
          ref.read(appRouterProvider).go(AppRoutes.resetPassword);
        }
      });
    });
  }

  Future<void> _startInitialSync(AccountUser account) async {
    final localSync = ref.read(localSyncStoreProvider);
    final consent = await localSync.photoConsentForAccount(account.id);
    if (consent == null && mounted) {
      final dialogContext = ref
          .read(appRouterProvider)
          .routerDelegate
          .navigatorKey
          .currentContext;
      if (dialogContext == null) return;
      final chosen = await requestDevelopmentPhotoConsent(dialogContext);
      if (chosen != null) {
        await localSync.setImageUploadConsent(
          ownerId: account.id,
          consent: chosen,
          authenticated: true,
        );
      }
    }
    if (mounted) {
      unawaited(ref.read(syncCoordinatorProvider).syncNow(SyncTrigger.startup));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(syncCoordinatorProvider).syncNow(SyncTrigger.resume));
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.listen(localSyncPendingProvider, (previous, next) {
      if (next.value == true && previous?.value != true) {
        unawaited(
          ref.read(syncCoordinatorProvider).syncNow(SyncTrigger.localWrite),
        );
      }
    });

    return MaterialApp.router(
      title: 'Chami',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
