import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/app/router/app_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/theme/app_theme.dart';
import 'package:kami/app/theme/theme_mode_controller.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/auth/domain/auth_repository.dart';
import 'package:kami/features/sync/application/sync_coordinator.dart';
import 'package:kami/features/sync/domain/sync_models.dart';

class KamiApp extends ConsumerStatefulWidget {
  const KamiApp({super.key});

  @override
  ConsumerState<KamiApp> createState() => _KamiAppState();
}

class _KamiAppState extends ConsumerState<KamiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(syncCoordinatorProvider).syncNow(SyncTrigger.startup));
    });
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

    ref.listen(accountAuthStateProvider, (previous, next) {
      next.whenData((state) {
        if (state.event == AccountAuthEvent.passwordRecovery) {
          router.go(AppRoutes.resetPassword);
        }
      });
    });
    ref.listen(localSyncPendingProvider, (previous, next) {
      if (next.value == true && previous?.value != true) {
        unawaited(
          ref.read(syncCoordinatorProvider).syncNow(SyncTrigger.localWrite),
        );
      }
    });

    return MaterialApp.router(
      title: 'Kami',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
