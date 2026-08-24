import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/router/main_shell.dart';
import 'package:kami/features/auth/presentation/auth_screens.dart';
import 'package:kami/features/batches/presentation/add_to_batch_screen.dart';
import 'package:kami/features/batches/presentation/add_scans_to_batch_screen.dart';
import 'package:kami/features/batches/presentation/batch_screens.dart';
import 'package:kami/features/batches/presentation/move_scan_screen.dart';
import 'package:kami/features/history/presentation/history_screen.dart';
import 'package:kami/features/history/presentation/saved_scan_detail_screen.dart';
import 'package:kami/features/home/presentation/home_screen.dart';
import 'package:kami/features/onboarding/presentation/onboarding_screens.dart';
import 'package:kami/features/orders/presentation/order_screen.dart';
import 'package:kami/features/profile/presentation/profile_screens.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/live_scan_screen.dart';
import 'package:kami/features/scan/presentation/scan_method_screen.dart';
import 'package:kami/features/scan/presentation/scan_screens.dart';
import 'package:kami/features/scan/presentation/shelf_life_preview_screen.dart';
import 'package:kami/features/startup/domain/startup_destination.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final startupDestination = ref.watch(startupDestinationProvider);

  final router = GoRouter(
    initialLocation: AppRoutes.root,
    redirect: (context, state) {
      if (state.matchedLocation != AppRoutes.root) {
        return null;
      }

      return switch (startupDestination) {
        StartupDestination.accountEntry => AppRoutes.accountChoice,
        StartupDestination.onboarding => AppRoutes.onboarding,
        StartupDestination.returningGuest => AppRoutes.home,
        StartupDestination.returningAccount => AppRoutes.home,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => OnboardingScreen(
          openedFromAccountChoice:
              state.uri.queryParameters['from'] == 'account-choice',
        ),
      ),
      GoRoute(
        path: AppRoutes.accountChoice,
        builder: (context, state) => const AccountChoiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/auth-callback',
        redirect: (context, state) => AppRoutes.resetPassword,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.batches,
                builder: (context, state) => const BatchesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':scanId',
                    builder: (context, state) => SavedScanDetailScreen(
                      scanId: state.pathParameters['scanId']!,
                      openedFromHistory: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.batchCreate,
        builder: (context, state) =>
            BatchCreateScreen(scanId: state.uri.queryParameters['scanId']),
      ),
      GoRoute(
        path: AppRoutes.batchCreateForScans,
        builder: (context, state) {
          final scanIds = state.extra is List<String>
              ? List<String>.from(state.extra! as List<String>)
              : const <String>[];
          return BatchCreateScreen(scanIds: scanIds);
        },
      ),
      GoRoute(
        path: '/batches/:batchId',
        builder: (context, state) {
          return BatchDetailsScreen(batchId: state.pathParameters['batchId']!);
        },
      ),
      GoRoute(
        path: '/batches/:batchId/scans',
        builder: (context, state) {
          return BatchScansScreen(batchId: state.pathParameters['batchId']!);
        },
      ),
      GoRoute(
        path: '/batches/:batchId/add-scans',
        builder: (context, state) {
          return AddScansToBatchScreen(
            batchId: state.pathParameters['batchId']!,
          );
        },
      ),
      GoRoute(
        path: '/batches/:batchId/order',
        builder: (context, state) {
          return OrderScreen(batchId: state.pathParameters['batchId']!);
        },
      ),
      GoRoute(
        path: AppRoutes.addMultipleScansToBatch,
        builder: (context, state) {
          final scanIds = state.extra is List<String>
              ? List<String>.from(state.extra! as List<String>)
              : const <String>[];
          return AddMultipleScansToBatchScreen(scanIds: scanIds);
        },
      ),
      GoRoute(
        path: AppRoutes.moveMultipleScansToBatch,
        builder: (context, state) {
          final scanIds = state.extra is List<String>
              ? List<String>.from(state.extra! as List<String>)
              : const <String>[];
          return MoveScansToBatchScreen(scanIds: scanIds);
        },
      ),
      GoRoute(
        path: '/saved-scans/:scanId',
        builder: (context, state) {
          return SavedScanDetailScreen(
            scanId: state.pathParameters['scanId']!,
            openedFromAddScans:
                state.uri.queryParameters['context'] == 'add-scans',
            addToBatchId: state.uri.queryParameters['batchId'],
            openedFromBatchScans:
                state.uri.queryParameters['context'] == 'batch-scans',
          );
        },
      ),
      GoRoute(
        path: '/saved-scans/:scanId/add-to-batch',
        builder: (context, state) {
          return AddToBatchScreen(scanId: state.pathParameters['scanId']!);
        },
      ),
      GoRoute(
        path: '/saved-scans/:scanId/move-to-batch',
        builder: (context, state) {
          return MoveScanScreen(scanId: state.pathParameters['scanId']!);
        },
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) => ScanMethodScreen(
          fromRescan: state.extra == true,
        ),
      ),
      GoRoute(
        path: AppRoutes.shelfLifePreview,
        builder: (context, state) => const ShelfLifePreviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.scanLive,
        builder: (context, state) => const LiveScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.scanUpload,
        builder: (context, state) => ScanScreen(
          openedFromRescan: state.extra == true,
        ),
      ),
      GoRoute(
        path: AppRoutes.scanResult,
        builder: (context, state) {
          final preview = state.extra;
          return ScanResultScreen(
            preview: preview is ScanPreview ? preview : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.scanRetake,
        builder: (context, state) {
          final preview = state.extra;
          return LowConfidenceResultScreen(
            preview: preview is LowConfidencePreview ? preview : null,
          );
        },
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Chami could not open this page.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    },
  );

  ref.onDispose(router.dispose);
  return router;
});
