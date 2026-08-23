import 'package:kami/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  static const callbackUrl = 'ph.fruitripeness.kami://auth-callback';

  final SupabaseClient _client;

  @override
  bool get isConfigured => true;

  @override
  AccountUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Future<AccountSignUpResult> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{'display_name': displayName.trim()},
        emailRedirectTo: callbackUrl,
      );
      // Supabase may return an obfuscated user instead of an AuthException
      // when email enumeration protection is enabled. Existing email signups
      // have an empty identities list, so surface the actionable conflict
      // rather than showing the normal verification-success dialog.
      final rawUser = response.user;
      final identities = rawUser?.identities;
      if (identities != null && identities.isEmpty) {
        throw const AccountAuthException(
          'This email is already used. Try signing in or use a different email.',
        );
      }
      final user = _mapUser(rawUser);
      if (user == null) {
        throw const AccountAuthException(
          'Account creation could not be completed. Please try again.',
        );
      }
      return AccountSignUpResult(
        user: user,
        requiresEmailConfirmation: response.session == null,
      );
    } on AccountAuthException {
      rethrow;
    } on AuthException catch (error) {
      throw AccountAuthException(_safeMessage(error));
    } on Object {
      throw const AccountAuthException(
        'Account creation could not be completed. Check your connection and try again.',
      );
    }
  }

  @override
  Future<AccountUser> updateDisplayName(String displayName) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: <String, dynamic>{'display_name': displayName.trim()}),
      );
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AccountAuthException(
          'The display name could not be updated. Please try again.',
        );
      }
      return user;
    } on AccountAuthException {
      rethrow;
    } on AuthException catch (error) {
      throw AccountAuthException(_safeMessage(error));
    } on Object {
      throw const AccountAuthException(
        'The display name could not be updated. Check your connection and try again.',
      );
    }
  }

  @override
  Future<AccountUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AccountAuthException(
          'Sign in could not be completed. Please try again.',
        );
      }
      return user;
    } on AccountAuthException {
      rethrow;
    } on AuthException {
      throw const AccountAuthException(
        'The email or password is incorrect, or the account is not ready yet.',
      );
    } on Object {
      throw const AccountAuthException(
        'Sign in could not be completed. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: callbackUrl,
      );
    } on AuthException {
      // The UI intentionally presents the same response for every address.
    } on Object {
      throw const AccountAuthException(
        'The recovery request could not be sent. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> updateRecoveredPassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (error) {
      throw AccountAuthException(_safeMessage(error));
    } on Object {
      throw const AccountAuthException(
        'The password could not be updated. Please request a new recovery link.',
      );
    }
  }

  @override
  Future<void> reauthenticate(String password) async {
    final email = currentUser?.email;
    if (email == null) {
      throw const AccountAuthException('Please sign in again.');
    }
    await signIn(email: email, password: password);
  }

  @override
  Future<void> signOut({bool localOnly = false}) async {
    try {
      await _client.auth.signOut(
        scope: localOnly ? SignOutScope.local : SignOutScope.global,
      );
    } on Object {
      throw const AccountAuthException(
        'Sign out could not be completed. Please try again.',
      );
    }
  }

  @override
  Stream<AccountAuthState> watchState() {
    return _client.auth.onAuthStateChange.map((state) {
      return AccountAuthState(
        event: switch (state.event) {
          AuthChangeEvent.initialSession => AccountAuthEvent.initialSession,
          AuthChangeEvent.signedIn => AccountAuthEvent.signedIn,
          AuthChangeEvent.signedOut => AccountAuthEvent.signedOut,
          AuthChangeEvent.passwordRecovery => AccountAuthEvent.passwordRecovery,
          AuthChangeEvent.tokenRefreshed => AccountAuthEvent.tokenRefreshed,
          AuthChangeEvent.userUpdated => AccountAuthEvent.userUpdated,
          _ => AccountAuthEvent.other,
        },
        user: _mapUser(state.session?.user),
      );
    });
  }

  static AccountUser? _mapUser(User? user) {
    final email = user?.email?.trim();
    if (user == null || email == null || email.isEmpty) return null;
    final rawDisplayName = user.userMetadata?['display_name'];
    final displayName = rawDisplayName is String && rawDisplayName.trim().isNotEmpty
        ? rawDisplayName.trim()
        : null;
    return AccountUser(id: user.id, email: email, displayName: displayName);
  }

  static String _safeMessage(AuthException error) {
    final message = error.message.toLowerCase();
    final code = error.code?.toLowerCase();
    if (code == 'email_exists' ||
        code == 'user_already_exists' ||
        code == 'identity_already_exists' ||
        message.contains('already registered') ||
        message.contains('already exists')) {
      return 'This email is already used. Try signing in or use a different email.';
    }
    if (message.contains('password')) {
      return 'Use at least 8 characters with uppercase, lowercase, and a number.';
    }
    if (message.contains('rate') || message.contains('too many')) {
      return 'Too many attempts were made. Please wait and try again.';
    }
    return 'The account request could not be completed. Please try again.';
  }
}

final class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository();

  @override
  bool get isConfigured => false;

  @override
  AccountUser? get currentUser => null;

  @override
  Future<AccountSignUpResult> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) => Future.error(_unavailable);

  @override
  Future<AccountUser> updateDisplayName(String displayName) =>
      Future.error(_unavailable);

  @override
  Future<void> reauthenticate(String password) => Future.error(_unavailable);

  @override
  Future<void> requestPasswordReset(String email) => Future.error(_unavailable);

  @override
  Future<AccountUser> signIn({
    required String email,
    required String password,
  }) => Future.error(_unavailable);

  @override
  Future<void> signOut({bool localOnly = false}) async {}

  @override
  Future<void> updateRecoveredPassword(String password) {
    return Future.error(_unavailable);
  }

  @override
  Stream<AccountAuthState> watchState() => const Stream.empty();

  static const _unavailable = AccountAuthException(
    'Online accounts are not configured in this build.',
  );
}
