import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/core/supabase/supabase_client_provider.dart';
import 'package:kami/features/auth/data/supabase_auth_repository.dart';
import 'package:kami/features/auth/domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnavailableAuthRepository()
      : SupabaseAuthRepository(client);
});

final accountAuthStateProvider = StreamProvider<AccountAuthState>((ref) {
  return ref.watch(authRepositoryProvider).watchState();
});

final currentAccountProvider = Provider<AccountUser?>((ref) {
  ref.watch(accountAuthStateProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});
