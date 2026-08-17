import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/auth/application/auth_providers.dart';
import 'package:kami/features/auth/data/device_account_link_store.dart';

/// Compatibility alias for the owner of new local domain records.
///
/// A null owner is deliberate unlinked Guest mode. Authentication state
/// changes invalidate this provider, so records immediately switch between
/// the authenticated account and the persistent linked workspace without
/// making local writes wait for the network.
final currentOwnerIdProvider = Provider<String?>((ref) {
  return ref.watch(localWorkspaceOwnerIdProvider);
});

/// The account currently authenticated with Supabase, if any.
final authenticatedAccountIdProvider = Provider<String?>((ref) {
  return ref.watch(currentAccountProvider)?.id;
});

/// Owner used for local domain reads and writes.
///
/// An authenticated account takes precedence for the duration of its session.
/// When signed out, the persistent linked account owns the offline workspace;
/// a null value remains the deliberate unlinked guest workspace.
final localWorkspaceOwnerIdProvider = Provider<String?>((ref) {
  return ref.watch(authenticatedAccountIdProvider) ??
      ref.watch(deviceLinkedAccountIdProvider);
});
