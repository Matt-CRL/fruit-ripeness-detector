import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/auth/application/auth_providers.dart';

/// The account that owns new local domain records.
///
/// A null owner is deliberate guest mode. Authentication state changes
/// invalidate this provider, so newly created records immediately use the
/// signed-in account without making local writes wait for the network.
final currentOwnerIdProvider = Provider<String?>((ref) {
  return ref.watch(currentAccountProvider)?.id;
});
