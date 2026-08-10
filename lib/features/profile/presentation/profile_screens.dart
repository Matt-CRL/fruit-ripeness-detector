import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/main_shell.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/theme/theme_mode_controller.dart';
import 'package:kami/features/startup/domain/startup_preferences.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isReturningToSignIn = false;

  Future<void> _returnToSignIn() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Return to sign in?'),
          content: const Text(
            'You will leave guest mode and return to account options. If you '
            'continue as a guest again, onboarding will start from the first '
            'slide. Saved local data will not be deleted.',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 64),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text(
                        'Stay as guest',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 64),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Sign in', textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isReturningToSignIn = true);
    try {
      await ref.read(startupPreferencesProvider).resetGuestEntry();
      if (mounted) {
        context.go(AppRoutes.accountChoice);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest mode could not be closed. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReturningToSignIn = false);
      }
    }
  }

  Future<void> _setDarkMode(bool enabled) async {
    final saved = await ref
        .read(themeModeProvider.notifier)
        .setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appearance could not be saved. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          32 + mainNavigationContentBottomInset(context),
        ),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person_outline,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guest mode',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text('Works locally without an account or internet.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  color: colorScheme.primary,
                ),
              ),
              title: Text(
                themeMode == ThemeMode.dark ? 'Dark mode' : 'Light mode',
              ),
              subtitle: Text(
                themeMode == ThemeMode.dark
                    ? 'Dark colors are active'
                    : 'Light colors are active',
              ),
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: _setDarkMode,
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? colorScheme.onPrimary
                      : colorScheme.primary;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest;
                }),
                trackOutlineColor: WidgetStatePropertyAll(colorScheme.outline),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Guest session', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'You can return to account options without deleting '
                    'local data.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isReturningToSignIn ? null : _returnToSignIn,
                    icon: _isReturningToSignIn
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: const Text('Return to sign in'),
                  ),
                ],
              ),
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            Text(
              'Developer preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.rule_folder_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                title: const Text('Shelf-life sample previews'),
                subtitle: const Text('View all nine saved-result examples'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.shelfLifePreview),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
