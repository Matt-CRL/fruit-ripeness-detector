import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/auth/application/restored_session_startup.dart';
import 'package:kami/features/auth/domain/auth_repository.dart';

void main() {
  const account = AccountUser(
    id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    email: 'test@example.com',
  );

  test('runs startup once when a saved account is restored', () async {
    final handled = <AccountUser>[];
    final startup = RestoredSessionStartup((account) async {
      handled.add(account);
    });

    await startup.handle(
      const AccountAuthState(event: AccountAuthEvent.initialSession),
    );
    await startup.handle(
      const AccountAuthState(
        event: AccountAuthEvent.initialSession,
        user: account,
      ),
    );
    await startup.handle(
      const AccountAuthState(
        event: AccountAuthEvent.tokenRefreshed,
        user: account,
      ),
    );
    await startup.handle(
      const AccountAuthState(
        event: AccountAuthEvent.initialSession,
        user: account,
      ),
    );

    expect(handled, [account]);
  });
}
