import 'package:kami/features/auth/domain/auth_repository.dart';

/// Runs account startup work exactly once when Supabase restores a saved session.
///
/// The initial session event arrives asynchronously, after the first Flutter
/// frame. Keeping this separate prevents startup checks from running before an
/// authenticated account is available.
final class RestoredSessionStartup {
  RestoredSessionStartup(this._onRestoredAccount);

  final Future<void> Function(AccountUser account) _onRestoredAccount;
  var _handled = false;

  Future<void> handle(AccountAuthState state) async {
    final account = state.user;
    if (_handled ||
        state.event != AccountAuthEvent.initialSession ||
        account == null) {
      return;
    }
    _handled = true;
    await _onRestoredAccount(account);
  }
}
