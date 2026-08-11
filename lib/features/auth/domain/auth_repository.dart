enum AccountAuthEvent {
  initialSession,
  signedIn,
  signedOut,
  passwordRecovery,
  tokenRefreshed,
  userUpdated,
  other,
}

final class AccountUser {
  const AccountUser({required this.id, required this.email});

  final String id;
  final String email;
}

final class AccountAuthState {
  const AccountAuthState({required this.event, this.user});

  final AccountAuthEvent event;
  final AccountUser? user;
}

final class AccountSignUpResult {
  const AccountSignUpResult({
    required this.user,
    required this.requiresEmailConfirmation,
  });

  final AccountUser user;
  final bool requiresEmailConfirmation;
}

final class AccountAuthException implements Exception {
  const AccountAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  bool get isConfigured;

  AccountUser? get currentUser;

  Stream<AccountAuthState> watchState();

  Future<AccountSignUpResult> createAccount({
    required String email,
    required String password,
  });

  Future<AccountUser> signIn({required String email, required String password});

  Future<void> requestPasswordReset(String email);

  Future<void> updateRecoveredPassword(String password);

  Future<void> reauthenticate(String password);

  Future<void> signOut({bool localOnly = false});
}
