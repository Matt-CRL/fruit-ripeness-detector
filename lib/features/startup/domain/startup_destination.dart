import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StartupDestination {
  accountEntry,
  onboarding,
  returningGuest,
  returningAccount,
}

final startupDestinationProvider = Provider<StartupDestination>((ref) {
  return StartupDestination.accountEntry;
});
